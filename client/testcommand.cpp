
#include <arpa/inet.h>
#include <string.h>
#include "testcommand.h"
#include "pluto.h"
#include "common.h"


std::string TestCommand::Pack() 
{
	int msgLen = MSGLEN_HEAD + MSGLEN_MSGID + m_data.size();
	char *buffer = new char[msgLen];

	char *ptr = buffer;
	*(uint32_t *)ptr = htonl(msgLen);
	ptr += MSGLEN_HEAD;
	*(uint32_t *)ptr = htonl(MSGID_TYPE::CLIENT_TEST);
	ptr += MSGLEN_MSGID;

	memcpy(ptr, m_data.c_str(), m_data.size());

	std::string msg(buffer, msgLen);

	delete []buffer;

	return msg;
}