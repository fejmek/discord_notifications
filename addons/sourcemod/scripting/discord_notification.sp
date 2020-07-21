#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <discord>

ConVar Discord_WebHook = null;

public Plugin myinfo = 
{
	name = "[Discord] Discord Notifications",
	author = PLUGIN_AUTHOR,
	description = "Send notification when hooks called.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public void OnPluginStart()
{
	LoadTranslations("discord_notification.phrases");
	
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	
	Discord_WebHook = CreateConVar("discord_webhook", "log", "Default webhook for sending logs");
	AutoExecConfig(true, "discord_notification");
}

public void OnMapEnd()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	if (StrContains(map, "workshop") != -1) {
		char mapPart[3][64];
		ExplodeString(map, "/", mapPart, 3, 64);
		strcopy(map, sizeof(map), mapPart[2]);
	}
	
	char webhook[64];
	GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
	
	char translate[64];
	Format(translate, sizeof(translate), "%T", "MapStart", LANG_SERVER, map);		
	Discord_SendMessage(webhook, translate);
}

public Action OnPlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsClientValid(client))
	{
		char clientName[33];
		GetClientName(client, clientName, sizeof(clientName));
		
		char webhook[64];
		GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
		
		char hostname[64];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		
		char translate[64];
		Format(translate, sizeof(translate), "%T", "Offline", LANG_SERVER, clientName, hostname);		
		Discord_SendMessage(webhook, translate);
	}
 
	return Plugin_Handled;
}

public Action OnClientPreAdminCheck(int client)
{
	if(client != 0)
	{
		char clientName[33];
		GetClientName(client, clientName, sizeof(clientName));
			
		char webhook[64];
		GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
		
		char hostname[64];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		
		char translate[64];
		Format(translate, sizeof(translate), "%T", "Join", LANG_SERVER, clientName, hostname);		
		Discord_SendMessage(webhook, translate);
	}
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source)
{
	char clientName[33];
	GetClientName(client, clientName, sizeof(clientName));
			
	char webhook[64];
	GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
		
	char translate[64];
	Format(translate, sizeof(translate), "%T", "OnBan", LANG_SERVER, clientName, time, reason);		
	Discord_SendMessage(webhook, translate);
}	

bool IsClientValid(int client, bool bAlive = false) 
{
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}