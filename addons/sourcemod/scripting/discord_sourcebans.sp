#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Benito"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <discord>
#include <sourcebanspp>

public Plugin myinfo = 
{
	name = "[Discord] Discord SourceBans",
	author = PLUGIN_AUTHOR,
	description = "Send notification when sourcebans hooks called.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public void OnPluginStart()
{
	LoadTranslations("discord_notification.phrases");
}

public void SBPP_OnBanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason)
{
	char webhook[64];
	GetConVarString(FindConVar("discord_webhook"), webhook, sizeof(webhook));
		
	char translate[128];
	Format(translate, sizeof(translate), "%T", "SB_OnBan", LANG_SERVER, iTarget, iAdmin, iTime, sReason);		
	Discord_SendMessage(webhook, translate);
}	

public void SBPP_OnReportPlayer(int iReporter, int iTarget, const char[] sReason)
{
	char webhook[64];
	GetConVarString(FindConVar("discord_webhook"), webhook, sizeof(webhook));
		
	char translate[64];
	Format(translate, sizeof(translate), "%T", "SB_OnReport", LANG_SERVER, iTarget, iReporter, sReason);		
	Discord_SendMessage(webhook, translate);
}	