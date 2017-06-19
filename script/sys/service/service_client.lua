
ServiceClient = {}

-- all connect-to service server
-- {service_info, service_info, ...}
ServiceClient._all_service_server = {} 

-- all server map
-- {server_id = server_info, ...}
ServiceClient._all_server_map = {}

-- {server_type = {server_id, server_id, ...}
ServiceClient._type_server_map = {}

-- {scene_id = {server_id, server_id, ...}
ServiceClient._scene_server_map = {}

ServiceClient._is_connect_timer_running = false
ServiceClient._connect_interval_ms = 2000

function ServiceClient.is_service_server(mailbox_id)
	for _, service_info in pairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			return true
		end
	end
	return false
end

function ServiceClient.add_connect_service(ip, port, desc)
	local service_info = 
	{
		-- _server_id = 0, 
		-- _server_type = 0, 
		_ip = ip, 
		_port = port, 
		-- _desc = desc, 
		_mailbox_id = -1,
		-- _is_registed = false,
		_is_connecting = false,
		_is_connected = false,
		_last_connect_time = 0,
		_server_list = {}, -- {server_id1, server_id2}
	}
	table.insert(ServiceClient._all_service_server, service_info)
end

function ServiceClient.create_connect_timer()

	local function timer_cb(arg)
		Log.debug("ServiceClient timer_cb")
		-- Log.debug("handle_client_test: ServiceClient._all_service_server=%s", tableToString(ServiceClient._all_service_server))
		local now_time = os.time()
		
		local is_all_connected = true
		for _, service_info in ipairs(ServiceClient._all_service_server) do
			if not service_info._is_connected then
				is_all_connected = false
				if not service_info._is_connecting then
					Log.debug("connect to ip=%s port=%d", service_info._ip, service_info._port)
					local ret, mailbox_id = g_network:connect_to(service_info._ip, service_info._port)
					-- Log.debug("ret=%s mailbox_id=%d", ret and "true" or "false", mailbox_id)
					if ret then
						service_info._mailbox_id = mailbox_id
						service_info._is_connecting = true
						service_info._last_connect_time = now_time
					else
						Log.warn("******* connect to fail ip=%s port=%d", service_info._ip, service_info._port)
					end
				else
					Log.debug("connecting mailbox_id=%d ip=%s port=%d", service_info._mailbox_id, service_info._ip, service_info._port)
					if now_time - service_info._last_connect_time > 5 then
						-- connect time too long, close this connect
						Log.warn("!!!!!!! connecting timeout mailbox_id=%d ip=%s port=%d", service_info._mailbox_id, service_info._ip, service_info._port)
						g_network:close_mailbox(service_info._mailbox_id) -- will cause luaworld:HandleDisconnect
						service_info._mailbox_id = -1
						service_info._is_connecting = false
					end
				end
			end
		end
		if is_all_connected then
			Log.debug("******* all connect *******")
			Timer.del_timer(ServiceClient._connect_timer_index)
			ServiceClient._is_connect_timer_running = false
		end
	end

	ServiceClient._is_connect_timer_running = true
	ServiceClient._connect_timer_index = Timer.add_timer(ServiceClient._connect_interval_ms, timer_cb, 0, true)
end

function ServiceClient.remove_server(mailbox_id, server_id)
	local server_info = ServiceClient._all_server_map[server_id]
	for i=#server_info._service_mailbox_list, 1, -1 do
		if server_info._service_mailbox_list[i] == mailbox_id then
			table.remove(server_info._service_mailbox_list, i)
		end
	end
	
	if #server_info._service_mailbox_list > 0 then
		-- still has service connect to this server, do nothing
		return
	end

	-- no more service connect to this server
	-- remove this server in type_server_map
	local type_server_list = ServiceClient._type_server_map[server_info._server_type] or {}
	for i=#type_server_list, 1, -1 do
		if type_server_list[i] == server_id then
			table.remove(type_server_list, i)
		end
	end

	-- remove this server in scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		local scene_server_list = ServiceClient._scene_server_map[scene_id]
		for i=#scene_server_list, 1, -1 do
			table.remove(scene_server_list, i)
		end
	end

	-- remove this server in all_server_map
	ServiceClient._all_server_map[server_id] = nil
end

function ServiceClient.service_server_disconnect(mailbox_id)
	Log.info("ServiceClient.service_server_disconnect mailbox_id=%d", mailbox_id)

	for _, service_info in ipairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			-- set disconnect
			service_info._mailbox_id = -1
			service_info._is_connecting = false
			service_info._is_connected = false

			for _, server_id in ipairs(service_info._server_list) do
				ServiceClient.remove_server(mailbox_id, server_id)
			end
			service_info._server_list = {}

			break
		end
	end

	if ServiceClient._is_connect_timer_running then
		-- do nothing, connect timer will do reconnect
		-- Log.debug("connect timer is running")
		return
	end

	-- connect timer already close, start it
	ServiceClient.create_connect_timer()

	ServiceClient.print()
end

function ServiceClient.connect_to_success(mailbox_id)
	for _, service_info in ipairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then

			service_info._is_connecting = false
			service_info._is_connected = true

			-- send register msg
			local msg = {}
			msg[1] = ServerConfig._server_id
			msg[2] = ServerConfig._server_type
			msg[3] = ServerConfig._single_scene_list
			msg[4] = ServerConfig._from_to_scene_list
			Net.send_msg(mailbox_id, MID.REGISTER_SERVER_REQ, table.unpack(msg))

			break
		end
	end
	ServiceClient.print()
end

-- for client
function ServiceClient.add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	for _, service_info in ipairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			table.insert(service_info._server_list, server_id)
			break
		end
	end

	local server_info = ServiceClient._all_server_map[server_id]
	if server_info then
		-- if exists in all_server_map, means add by other router, just update service_mailbox_list
		for k, v in ipairs(server_info._service_mailbox_list) do
			if v == mailbox_id then
				Log.err("ServiceClient.service_add_connect_server add duplicate mailbox_id=%d server_id=%d", mailbox_id, server_id)
				return
			end
		end
		table.insert(server_info._service_mailbox_list, mailbox_id)
		return
	end

	-- init server_info
	server_info = {}
	server_info._server_id = server_id
	server_info._server_type = server_type
	server_info._service_mailbox_list = {mailbox_id}
	server_info._scene_list = {}
	for _, scene_id in ipairs(single_scene_list) do
		table.insert(server_info._scene_list, scene_id)
	end
	for i=1, #from_to_scene_list-1, 2 do
		local from = from_to_scene_list[i]
		local to = from_to_scene_list[i+1]
		for scene_id=from, to do
			table.insert(server_info._scene_list, scene_id)
		end
	end
	-- Log.debug("server_info._scene_list=%s", tableToString(server_info._scene_list))

	-- add into all_server_map
	ServiceClient._all_server_map[server_info._server_id] = server_info
	
	-- add into type_server_map
	ServiceClient._type_server_map[server_type] = ServiceClient._type_server_map[server_type] or {}
	table.insert(ServiceClient._type_server_map[server_type], server_id)

	-- add into scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		ServiceClient._scene_server_map[scene_id] = ServiceClient._scene_server_map[scene_id] or {}
		table.insert(ServiceClient._scene_server_map[scene_id], server_id)
	end

	ServiceClient.print()
end

function ServiceClient.print()
	Log.info("*********ServiceClient********")
	Log.info("ServiceClient._all_service_server=%s", tableToString(ServiceClient._all_service_server))
	Log.info("ServiceClient._all_server_map=%s", tableToString(ServiceClient._all_server_map))
	Log.info("ServiceClient._type_server_map=%s", tableToString(ServiceClient._type_server_map))
	Log.info("ServiceClient._scene_server_map=%s", tableToString(ServiceClient._scene_server_map))
	Log.info("******************************")
end

return ServiceClient