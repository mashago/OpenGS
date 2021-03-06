
local server_mgr = require "server.server_mgr"
local Log = require "log.logger"
local Env = require "env"
local global_define = require "global.global_define"
local ServerType = global_define.ServerType

function g_net_event_server_disconnect(server_id)
	local server_info = server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.MASTER then
		-- save all role
		Env.role_mgr:force_save_all_role()
	end
end

function g_net_event_client_msg(msg_handler, data, mailbox_id, msg_id, ext)

	local role_id = ext
	local role = Env.role_mgr:get_role_by_id(role_id)
	if not role then
		Log.warn("g_net_event_client_msg: role nil msg_id=%d", msg_id)
		return
	end

	return msg_handler(role, data, mailbox_id, msg_id)
end
