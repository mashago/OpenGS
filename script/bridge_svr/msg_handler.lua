
local Log = require "log.logger"
local Util = require "util.util"
local g_msg_handler = require "global.msg_handler"
local ErrorCode = require "global.error_code"

function g_msg_handler.s2s_register_area_ret(data, mailbox_id, msg_id)
	Log.debug("s2s_register_area_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("s2s_register_area_ret: register fail %d", data.result)
		return
	end
end

