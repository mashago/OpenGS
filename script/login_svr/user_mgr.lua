
local class = require "util.class"
local UserMgr = class()

function UserMgr:ctor()
	self._all_user_map = {} -- {[user_id]=[User], }
	self._mailbox_user_map = {} -- {[mailbox_id]=[User], }
end

function UserMgr:add_user(user)

	if self._all_user_map[user._user_id] then
		-- duplicate login
		return false
	end

	if self._mailbox_user_map[user._mailbox_id] then
		-- duplicate login
		return false
	end

	self._all_user_map[user._user_id] = user
	self._mailbox_user_map[user._mailbox_id] = user
	return true
end

function UserMgr:get_user_by_mailbox(mailbox_id)
	return self._mailbox_user_map[mailbox_id]
end

function UserMgr:get_user_by_id(user_id)
	return self._all_user_map[user_id]
end

function UserMgr:del_user(user)
	self._all_user_map[user._user_id] = nil
	self._mailbox_user_map[user._mailbox_id] = nil
	user._is_online = false
end

function UserMgr:change_user_mailbox(user, mailbox_id)
	self._mailbox_user_map[user._mailbox_id] = nil
	user._mailbox_id = mailbox_id
	self._mailbox_user_map[user._mailbox_id] = user
end

return UserMgr
