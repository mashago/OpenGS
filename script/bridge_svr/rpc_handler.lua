

function register_rpc_handler()

	local call_func_map = RpcMgr._all_call_func

	call_func_map.bridge_create_role = function(data)
		
		Log.debug("bridge_create_role: data=%s", Util.TableToString(data))

		local server = ServiceClient.get_server_by_type(ServerType.ROUTER)
		if not server then
			Log.err("bridge_create_role no router server")
			return {result = ServerErrorCode.RPC_FAIL}
		end

		local status, result = RpcMgr.call(server, "router_create_role", data)
		if not status then
			Log.err("bridge_create_role rpc call fail")
			return {result = ServerErrorCode.RPC_FAIL}
		end

		Log.debug("bridge_create_role: callback result=%s", Util.TableToString(result))

		return result
	end

	call_func_map.bridge_rpc_test = function(data)
		
		Log.debug("bridge_rpc_test: data=%s", Util.TableToString(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "2"
		sum = sum + 1

		-- rpc to router
		local server = ServiceClient.get_server_by_type(ServerType.ROUTER)
		if not server then
			Log.err("bridge_rpc_test no router server")
			return {result = ServerErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		local status, result = RpcMgr.call(server, "router_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("bridge_rpc_test rpc call fail")
			return {result = ServerErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		Log.debug("bridge_rpc_test: callback result=%s", Util.TableToString(result))
		buff = result.buff
		sum = result.sum

		-- rpc to scene
		local server = ServiceClient.get_server_by_type(ServerType.SCENE)
		if not server then
			Log.err("bridge_rpc_test no scene server")
			return {result = ServerErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		local status, result = RpcMgr.call(server, "scene_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("bridge_rpc_test rpc call fail")
			return {result = ServerErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		Log.debug("bridge_rpc_test: callback result=%s", Util.TableToString(result))
		buff = result.buff
		sum = result.sum

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

end