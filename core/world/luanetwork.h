#pragma once

extern "C"
{
#include <stdint.h>
}

class Pluto;
class LuaWorld;

class LuaNetwork
{
public:
	LuaNetwork(LuaWorld *world);
	~LuaNetwork();

	void SetRecvPluto(Pluto *pu);
	Pluto *GetRecvPluto();
	Pluto *GetSendPluto();

	int64_t ConnectTo(const char* ip, unsigned int port); // return mailboxId or negative
	bool SyncConnectTo(int64_t session_id, const char* ip, unsigned int port); // return mailboxId or negative
	bool Send(int64_t mailboxId);
	bool Transfer(int64_t mailboxId);

	void CloseMailbox(int64_t mailboxId);

	bool HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len);
	bool Listen(const char* ip, unsigned int port, int64_t session_id);

private:

	Pluto *m_recvPluto;
	Pluto *m_sendPluto;
	LuaWorld *m_world;
};
