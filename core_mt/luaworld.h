
#pragma once

#include <lua.hpp>
#include "world.h"
#include "pluto.h"

class LuaNetwork;
class LuaWorld : public World
{
public:
	LuaWorld();
	virtual ~LuaWorld();

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char *entry_file) override;

	virtual void HandleNewConnection(int64_t mailboxId, int32_t connType) override;
	virtual void HandleConnectToSuccess(int64_t mailboxId) override;
	virtual void HandleDisconnect(int64_t mailboxId) override;
	virtual void HandleMsg(Pluto &u) override;
	virtual void HandleConnectToRet(int64_t connIndex, int64_t mailboxId) override;

	// call from world - timermgr
	void HandleTimer(void *arg);

	// call from lua
	int64_t ConnectTo(const char* ip, unsigned int port); // return a connect index
	void SendPluto(Pluto *pu);
	void CloseMailbox(int64_t mailboxId);

	lua_State *m_L;
	LuaNetwork *m_luanetwork;
	int64_t m_connIndex;
};

