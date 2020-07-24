#pragma semicolon 1

#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "1.0"
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <discord_notification>
#include <SteamWorks>
#pragma newdecls required

ConVar Discord_WebHook = null;
ConVar Discord_RetrieveMessages = null;
ConVar Discord_DisplayAuth = null;
ConVar Discord_KillNotif = null;
ConVar Discord_Embed = null;

public Plugin myinfo = 
{
	name = "[Discord] Discord Notifications",
	author = PLUGIN_AUTHOR,
	description = "Send notification when hooks called.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=326190"
};

public void OnPluginStart()
{
	LoadTranslations("discord_notification.phrases");
	
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	AddCommandListener(Say, "say");
	
	Discord_WebHook = CreateConVar("discord_webhook", "<WEBHOOK_URL_HERE>", "Default webhook URL for sending logs.");
	Discord_RetrieveMessages = CreateConVar("discord_messages", "1", "1 = Enabled / 0 = Disabled retrieves the players messages on discord.");
	Discord_DisplayAuth = CreateConVar("discord_auth", "1", "1 = Enabled / 0 = Disabled retrieves the players steamid and ip on discord.");
	Discord_KillNotif = CreateConVar("discord_killedby", "1", "1 = Enabled / 0 = Disabled retrieves the killer and the victim of a kill.");
	Discord_Embed = CreateConVar("discord_embed", "1", "1 = Send embed's notifications / 0 = Send normal notification.");
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
		
		char webhook[128];
		Discord_WebHook.GetString(webhook, sizeof(webhook));
		
		char killername[64];
		GetClientName(killer, killername, sizeof(killername));
		
		char victimname[64];
		GetClientName(client, victimname, sizeof(victimname));
											
		SendToDiscord("%T", "Kill", LANG_SERVER, killername, victimname, weapon);
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
	
	SendToDiscord("%T", "MapStart", LANG_SERVER, map);		
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
				
				SendToDiscord("[%s]: %s", strName, arg);
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
		
		char hostname[64];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		
		char ip[64];
		GetClientIP(client, ip, sizeof(ip), true);
		
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
		
		if(!StrEqual(steamid, "BOT"))
		{		
			if(GetConVarBool(Discord_DisplayAuth) == true)			
				SendToDiscord("%T", "Offline_Auth", LANG_SERVER, clientName, ip, steamid, hostname);	
			else
				SendToDiscord("%T", "Offline_NoAuth", LANG_SERVER, clientName, hostname);
		}		
	}
 
	return Plugin_Handled;
}

public Action OnClientPreAdminCheck(int client)
{
	if(client != 0)
	{
		char clientName[33];
		GetClientName(client, clientName, sizeof(clientName));
			
		char hostname[64];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		
		char ip[64];
		GetClientIP(client, ip, sizeof(ip), true);
		
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
		
		if(!StrEqual(steamid, "BOT"))
		{			
			if(GetConVarBool(Discord_DisplayAuth) == true)
				SendToDiscord("%T", "Join_Auth", LANG_SERVER, clientName, ip, steamid, hostname);			
			else
				SendToDiscord("%T", "Join_NoAuth", LANG_SERVER, clientName, hostname);
		}	
	}
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source)
{
	char clientName[33];
	GetClientName(client, clientName, sizeof(clientName));
			
	SendToDiscord("%T", "OnBan", LANG_SERVER, clientName, time, reason);	
}

public Action OnRemoveBan(const char[] identity, int flags, const char[] command, any source)
{
	char type[16];
	if(StrContains(identity, "STEAM_") != -1)
		Format(type, sizeof(type), "SteamID(%N)", identity);								
	else
		Format(type, sizeof(type), "IP(%s)", identity);

	SendToDiscord("%T", "SB_OnBanRemoved", LANG_SERVER, type);
}	

public void BaseComm_OnClientMute(int client, bool muteState)
{
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	if(muteState)
		SendToDiscord("%T", "Mute", LANG_SERVER, name);	
	else
		SendToDiscord("%T", "UnMute", LANG_SERVER, name);		
}

public void BaseComm_OnClientGag(int client, bool gagState)
{
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	if(gagState)
		SendToDiscord("%T", "Gag", LANG_SERVER, name);
	else
		SendToDiscord("%T", "UnGag", LANG_SERVER, name);				
}

bool IsClientValid(int client, bool bAlive = false) 
{
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}

void SendToDiscord(char[] message, any ...)
{	
	char webhook[128];
	Discord_WebHook.GetString(webhook, sizeof(webhook));
	
	char hostname[64];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	
	char packedMessage[PLATFORM_MAX_PATH];
	VFormat(packedMessage, sizeof(packedMessage), message, 2);
	
	
	if(GetConVarBool(Discord_Embed) == true)
	{
		char map[64];
		GetCurrentMap(map, sizeof(map));
		if (StrContains(map, "workshop") != -1) {
			char mapPart[3][64];
			ExplodeString(map, "/", mapPart, 3, 64);
			strcopy(map, sizeof(map), mapPart[2]);
		}
		
		char mapJPG[256];
		Format(mapJPG, sizeof(mapJPG), "https://image.gametracker.com/images/maps/160x120/csgo/%s.jpg", map);
		
		int maxslots = GetMaxHumanPlayers();	
		int nbPlayers = 0;	
	    LoopClients(i)
	        nbPlayers++;
	
	    char sPlayers[24];
	    Format(sPlayers, sizeof(sPlayers), "%d/%d", nbPlayers, maxslots);
		
		DiscordWebHook hook = new DiscordWebHook(webhook);
		hook.SlackMode = true;
		
		hook.SetUsername("Discord Notification");
		
		MessageEmbed Embed = new MessageEmbed();
		
		Embed.SetColor("#00fd29");
		Embed.SetTitle(hostname);
		Embed.SetURL("https://forums.alliedmods.net/showthread.php?t=326190");
		Embed.AddField("Map", map, true);
		Embed.AddField("Players", sPlayers, true);
		Embed.AddField("Message", packedMessage, false);
		Embed.SetFooter("Discord Notifications - By Benito");
		Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
		Embed.SetImage(mapJPG);
		Embed.SetTimestamp("2020-07-22T22:00:00.000Z");
		
		hook.Embed(Embed);
		
		hook.Send();
		delete hook;
	}	
	else
	{
		DiscordWebHook hook = new DiscordWebHook(webhook);
		hook.SlackMode = true;
		hook.SetUsername("Discord Notification");
		hook.SetContent(packedMessage);
		hook.Send();
		delete hook;
	}	
}