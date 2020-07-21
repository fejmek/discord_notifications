#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <discord>
#tryinclude <sourcebanspp>

ConVar Discord_WebHook = null;
ConVar Discord_RetrieveMessages = null;

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
	AddCommandListener(Say, "say");
	
	Discord_WebHook = CreateConVar("discord_webhook", "log", "Default webhook for sending logs.");
	Discord_RetrieveMessages = CreateConVar("discord_messages", "1", "1 = Enabled / 0 = Disabled retrieves the players messages on discord.");
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

public Action Say(int client, char[] Cmd, int args)
{
	if(client > 0)
	{
		if(IsClientValid(client))
		{
			char arg[256];
			GetCmdArgString(arg, sizeof(arg));
			StripQuotes(arg);
			TrimString(arg);	
			
			if(GetConVarBool(Discord_RetrieveMessages) == true)
			{			
				char strName[32];
				GetClientName(client, strName, sizeof(strName));
				
				char webhook[64];
				GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
						
				Discord_SendMessage(webhook, arg);			
			}					
		}
	}
	
	return Plugin_Handled;
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
		
		char ip[64];
		GetClientIP(client, ip, sizeof(ip), true);
		
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
		
		char translate[64];
		Format(translate, sizeof(translate), "%T", "Offline", LANG_SERVER, clientName, ip, steamid, hostname);		
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
		
		char ip[64];
		GetClientIP(client, ip, sizeof(ip), true);
		
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
		
		char translate[64];
		Format(translate, sizeof(translate), "%T", "Join", LANG_SERVER, clientName, ip, steamid, hostname);		
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

public void SBPP_OnBanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason)
{
	char webhook[64];
	GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
		
	char translate[64];
	Format(translate, sizeof(translate), "%T", "SB_OnBan", LANG_SERVER, iTarget, iAdmin, iTime, sReason);		
	Discord_SendMessage(webhook, translate);
}	

public void SBPP_OnReportPlayer(int iReporter, int iTarget, const char[] sReason)
{
	char webhook[64];
	GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
		
	char translate[64];
	Format(translate, sizeof(translate), "%T", "SB_OnReport", LANG_SERVER, iTarget, iReporter, sReason);		
	Discord_SendMessage(webhook, translate);
}	

public Action OnRemoveBan(const char[] identity, int flags, const char[] command, any source)
{
	char webhook[64];
	GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
	
	char type[16], translate[64];
	if(StrContains(identity, "STEAM_") != -1)
	{
		Format(type, sizeof(type), "SteamID(%N)", identity);							
		Format(translate, sizeof(translate), "%T", "SB_OnBanRemoved", LANG_SERVER, type);		
	}	
	else
	{
		Format(type, sizeof(type), "IP(%s)", identity);
		Format(translate, sizeof(translate), "%T", "SB_OnBanRemoved", LANG_SERVER, type);
	}			
	
	Discord_SendMessage(webhook, translate);	
}	

bool IsClientValid(int client, bool bAlive = false) 
{
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}