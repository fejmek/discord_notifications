#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <discord>

ConVar Discord_WebHook = null;
ConVar Discord_RetrieveMessages = null;
ConVar Discord_DisplayAuth = null;
ConVar Discord_KillNotif = null;

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
	HookEvent("player_death", OnPlayerDeath);
	AddCommandListener(Say, "say");
	
	Discord_WebHook = CreateConVar("discord_webhook", "log", "Default webhook for sending logs.");
	Discord_RetrieveMessages = CreateConVar("discord_messages", "1", "1 = Enabled / 0 = Disabled retrieves the players messages on discord.");
	Discord_DisplayAuth = CreateConVar("discord_auth", "1", "1 = Enabled / 0 = Disabled retrieves the players steamid and ip on discord.");
	Discord_KillNotif = CreateConVar("discord_killedby", "1", "1 = Enabled / 0 = Disabled retrieves the killer and the victim of a kill.");
	AutoExecConfig(true, "discord_notification");
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int killer = GetClientOfUserId(event.GetInt("attacker")); 
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));

	if(GetConVarBool(Discord_KillNotif) == true)
	{
		if (StrContains(weapon, "weapon_") != -1) 
		{
			char weaponPart[2][32];
			ExplodeString(weapon, "_", weaponPart, 2, 32);
			strcopy(weapon, sizeof(weapon), weaponPart[1]);
		}
		
		char webhook[64];
		GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
				
		char translate[128];
		Format(translate, sizeof(translate), "%T", "Kill", LANG_SERVER, killer, client, weapon);								
		Discord_SendMessage(webhook, translate);
	}			
	
	return Plugin_Continue;
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
				
				char finalMessage[128];
				Format(finalMessage, sizeof(finalMessage), "[%s]: %s", strName, arg);
				
				//CPrintToChatAll("%s: %s", strName, arg);						
				Discord_SendMessage(webhook, finalMessage);			
			}					
		}
	}
	
	return Plugin_Continue;
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
		
		char translate[128];
		if(GetConVarBool(Discord_DisplayAuth) == true)			
			Format(translate, sizeof(translate), "%T", "Offline_Auth", LANG_SERVER, clientName, ip, steamid, hostname);	
		else
			Format(translate, sizeof(translate), "%T", "Offline_NoAuth", LANG_SERVER, clientName, hostname);			
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
		
		char translate[128];
		
		if(GetConVarBool(Discord_DisplayAuth) == true)
			Format(translate, sizeof(translate), "%T", "Join_Auth", LANG_SERVER, clientName, ip, steamid, hostname);		
		else
			Format(translate, sizeof(translate), "%T", "Join_NoAuth", LANG_SERVER, clientName, hostname);				
		Discord_SendMessage(webhook, translate);
	}
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source)
{
	char clientName[33];
	GetClientName(client, clientName, sizeof(clientName));
			
	char webhook[64];
	GetConVarString(Discord_WebHook, webhook, sizeof(webhook));
		
	char translate[128];
	Format(translate, sizeof(translate), "%T", "OnBan", LANG_SERVER, clientName, time, reason);		
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