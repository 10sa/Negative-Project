#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <sdktools_functions>
#include <emitsoundany>

#include "ntproject/global_defines.sp"
#include "ntproject/global_variables.sp"
#include "ntproject/player_data_manager.sp"
#include "ntproject/hooks.sp"
#include "ntproject/stock_utils.sp"
#include "ntproject/bot_control.sp"
#include "ntproject/worker_routines.sp"
#include "ntproject/round_control.sp"
#include "ntproject/map_control.sp"
#include "ntproject/admin_commands.sp"
#include "ntproject/user_commands.sp"
#include "ntproject/stet_handler.sp"
#include "ntproject/skill_handler.sp"
#include "ntproject/menu_control.sp"
#include "ntproject/player_control.sp"
#include "ntproject/bot_skill_handler.sp"
#include "ntproject/skill_utils.sp"
#include "ntproject/data_loader.sp"
#include "ntproject/setting_handler.sp"
#include "ntproject/item_handler.sp"
#include "ntproject/item_menu_handler.sp"



// 봇 생성은 반드시 bot_control.CreateBot 함수를 사용 할 것 //

// Zeisen ZatsuneMiku <- 작동 안됨

public Plugin myinfo = {
	name = "NT Project",
	author = "Negative",
	description = "(ToT)",
	version = "0.1",
	url = ""
};

public void OnPluginStart()
{	
	// Subroutine initializing. //
	NTProject_HooksInit();
	NTProject_PlayerDataManagerInit();
	NTProject_BotControlInit();
	NTProject_MapControlInit();
	NTProject_WorkersRotuineInit();
	NTProject_AdminCommandsInit();
	NTProject_UserCommandsInit();
	NTProject_StetHandlerInit();
	NTProject_SkillHandlerInit();
	NTProject_BotSkillHandlerInit();
	NTProject_DataLoaderInit();
	NTProject_SettingHandlerInit();
	NTProject_ItemHadnlerInit();
	NTProject_RoundControlInit();
	
	RemoveConVarFlag("mp_friendlyfire", FCVAR_NOTIFY);

	PrintToServer("[NT Project] Project Initialized.");
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		BotControl_OnClientPutInServer(client);
	else
	{
		PlayerDataManager_OnClientPutInServer(client);
		PlayerControl_OnClientPutInServer(client);
	}
}

public void OnClientDisconnect(int client)
{	
	if (IsFakeClient(client))
		BotControl_OnClientDisconnect(client);
	else
		PlayerDataManager_PlayerDisconnect(client);
}

public void OnConfigsExecuted()
{
	ServerCommand("mp_limitteams 0");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("bot_allow_grenades 1");
	ServerCommand("bot_difficulty 3");
}

// Pre임, SDKHook 걸어서 SpawnPost로 완전히 소환 된 뒤 작업할 것.
public void OnEntityCreated(int entity, const char[] className)
{
	if (StrContains(className, "weapon_") != -1)
		SDKHook(entity, SDKHook_SpawnPost, Hooks_WeaponSpawned);
}

public void OnMapStart()
{
	// Pre
	MapControl_OnMapStart();
	RoundControl_OnMapStart();
	
	// Post
	DataLoader_OnMapStartPost();
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if(IsFakeClient(client))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	Hooks_OnCSWeaponDrop(client, weapon);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client))
		BotControl_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);
	else
		PlayerControl_OnPlayerRunCmd(client, buttons);
		
	// 봇이건 유저건 이동속도가 0.0인 경우 점프 불가능
	if (GetClientMovespeed(client) <= 0.0)
		buttons &= ~IN_JUMP;
		
	return Plugin_Changed;
}

public void OnMapEnd()
{
	MapControl_OnMapEnd();
}