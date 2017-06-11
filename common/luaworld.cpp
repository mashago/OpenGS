
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "logger.h"
#include "luaworld.h"
#include "mailbox.h"
#include "luanetworkreg.h"
#include "luanetwork.h"
#include "luatimerreg.h"

LuaWorld* LuaWorld::Instance()
{
	static LuaWorld *instance = new LuaWorld();
	return instance;
}

LuaWorld::LuaWorld() : m_L(nullptr)
{
}

LuaWorld::~LuaWorld()
{
}

bool LuaWorld::Init(int server_id, int server_type, const char *entry_file)
{
	LuaNetwork::Instance()->SetNetService(m_net);

	m_L = luaL_newstate();
	if (!m_L)
	{
		return false;
	}

	// register lib
	const luaL_Reg lua_reg_libs[] = 
	{
		{ "base", luaopen_base },
		{ LUA_TABLIBNAME, luaopen_table },
		{ LUA_IOLIBNAME, luaopen_io },
		{ LUA_OSLIBNAME, luaopen_os },
		{ LUA_BITLIBNAME, luaopen_bit32 },
		{ LUA_COLIBNAME, luaopen_coroutine },
		{ LUA_MATHLIBNAME, luaopen_math },
		{ LUA_DBLIBNAME, luaopen_debug },
		{ LUA_LOADLIBNAME, luaopen_package },
		{ LUA_STRLIBNAME, luaopen_string },
		{ "LuaNetwork", luaopen_luanetwork },
		{ NULL, NULL },
	};

	for (const luaL_Reg *libptr = lua_reg_libs; libptr->func; ++libptr)
	{
		luaL_requiref(m_L, libptr->name, libptr->func, 1);
		lua_pop(m_L, 1);
	}

	// register timer function
	reg_timer_funcs(m_L);

	// set global params
	lua_pushinteger(m_L, server_id);
	lua_setglobal(m_L, "g_server_id");
	lua_pushinteger(m_L, server_type);
	lua_setglobal(m_L, "g_server_type");
	lua_pushstring(m_L, entry_file);
	lua_setglobal(m_L, "g_entry_file");

	if (luaL_dofile(m_L, "../script/main.lua"))
	{
		const char * msg = lua_tostring(m_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}

	return true;
}

int LuaWorld::HandlePluto(Pluto &u)
{
	Mailbox *pmb = u.GetMailbox();
	int mailboxId = pmb->GetMailboxId();
	int msgId = u.ReadMsgId();

	HandleMsg(mailboxId, msgId, u);

	return 0;
}

void LuaWorld::HandleMsg(int mailboxId, int msgId, Pluto &u)
{
	LuaNetwork::Instance()->SetRecvPluto(&u);
	lua_getglobal(m_L, "ccall_recv_msg_handler");
	lua_pushinteger(m_L, mailboxId);
	lua_pushinteger(m_L, msgId);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleDisconnect(Mailbox *pmb)
{
	LOG_DEBUG("mailboxId=%d", pmb->GetMailboxId());
}

void LuaWorld::HandleConnectToSuccess(Mailbox *pmb)
{
	LOG_DEBUG("mailboxId=%d", pmb->GetMailboxId());

	lua_getglobal(m_L, "ccall_connect_to_success_handler");
	lua_pushinteger(m_L, pmb->GetMailboxId());
	lua_call(m_L, 1, 0);
}

void LuaWorld::HandleNewConnection(Mailbox *pmb)
{
	LOG_DEBUG("mailboxId=%d", pmb->GetMailboxId());
}

void LuaWorld::HandleTimer(void *arg)
{
	int64_t timer_index = (int64_t)arg;
	// LOG_DEBUG("timer_index=%ld", timer_index);

	LuaWorld *pInstance = Instance();
	lua_getglobal(pInstance->m_L, "ccall_timer_handler");
	lua_pushinteger(pInstance->m_L, timer_index);
	lua_call(pInstance->m_L, 1, 0);
}

