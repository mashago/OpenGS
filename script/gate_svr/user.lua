local net_mgr = require "net.net_mgr"
local server_mgr = require "server.server_mgr"
local Log = require "log.logger"
local g_funcs = require "global.global_funcs"
local class = require "util.class"

local msg_def = require "global.net_msg_def"
local global_define = require "global.global_define"
local MAILBOX_ID_NIL = global_define.MAILBOX_ID_NIL
local MID = msg_def.MID

local User = class()

function User:ctor(user_id, role_id, scene_id, token)
	self._user_id = user_id
	self._role_id = role_id
	self._scene_id = scene_id
	self._token = token

	self._scene_server_id = 0
	self._mailbox_id = MAILBOX_ID_NIL
end

function User:is_online()
	return self._mailbox_id ~= MAILBOX_ID_NIL
end

function User:send_msg(msg_id, msg)
	if self._mailbox_id == MAILBOX_ID_NIL then
		Log.warn("User:send_msg mailbox_id nil msg_id=%s", g_funcs.get_msg_name(msg_id))
		return false
	end
	return net_mgr:send_msg(self._mailbox_id, msg_id, msg)
end

function User:transfer_msg()
	return net_mgr:transfer_msg(self._mailbox_id)
end

function User:offline()
	-- clear mailbox_id
	-- send to scene server

	self._mailbox_id = MAILBOX_ID_NIL

	local scene_server_info = server_mgr:get_server_by_id(self._scene_server_id)
	if not scene_server_info then
		Log.err("User:disconnect: scene server not exists scene_id=%d", self._scene_server_id)
		return
	end
	local msg = { }
	scene_server_info:send_msg_ext(MID.s2s_gate_role_disconnect, self._role_id, msg)
end

return User
