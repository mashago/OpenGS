
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "logger.h"
#include "luaclient.h"

LuaClient* LuaClient::Instance()
{
	static LuaClient *instance = new LuaClient();
	return instance;
}

LuaClient::LuaClient()
{
}

LuaClient::~LuaClient()
{
}

void LuaClient::HandleNewConnection(int64_t mailboxId, int32_t connType)
{
	// do nothing
}

void LuaClient::HandleStdin(const char *buffer)
{
	lua_getglobal(m_L, "ccall_stdin_handler");
	lua_pushstring(m_L, buffer);
	lua_call(m_L, 1, 0);
}

