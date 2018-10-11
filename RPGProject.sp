#include <sourcemod>
#include <functions>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <sorting>
#include <entity>

#include "RPGProject/GlobalDefines.sp"
#include "RPGProject/GameManager.sp"

#include "RPGProject/Models/Entity.sp"
#include "RPGProject/Models/Player.sp"
#include "RPGProject/Models/Bot.sp"
#include "RPGProject/Models/Weapon.sp"

#include "RPGProject/Utils.sp"

#include "RPGProject/PlayerControl.sp"
#include "RPGProject/BotControl.sp"
#include "RPGProject/WeaponControl.sp"
#include "RPGProject/MapControl.sp"
#include "RPGProject/RoundControl.sp"
#include "RPGProject/TeamCycler.sp"
#include "RPGProject/ConfigControl.sp"
#include "RPGProject/AdminCommands.sp"
#include "RPGProject/EconomicControl.sp"
#include "RPGProject/SkillControl.sp"
#include "RPGProject/MenuControl.sp"


// 이슈
// KeyValues나 StringMap 반환하는 함수에는 주석으로 구조를 써둘것.
// MapChange 시 누수가 발생하는거 같진 않음, 일단은 계속 감시할 것
// GameManager.RunFunction() 함수 사용할때 호출될 대상 함수는 반드시 public 으로 선언되어야 함
// Event 같은 경우는 그 파일에서 후크 걸어서 해결하되 Forward 같은 경우는 여기에서 객체 메소드를 호출할 것.

// Cvar : bot_profile_db <- 정상작동 안함.

// Need To do
// Friendly team spawn implements // [TOK], Require Default Friendly Team.
// Player exp, cash implements // [TOK], Require Improve Reward Texts.
// Game Cash Reward // [OK] Require Improve.

// To do list //
// Menu System
// Inventory system
// Dataloader (Model, Sounds)
// Soundtrack
// More enemy teams
// Map Data (Spawn Point, Object Prefix, Team Prefix, Others...)
// Boss raid level (level 8)

public void OnPluginStart()
{
	Initiailize();
	LoadDatas();
}

public void OnClientPutInServer(int client)
{
	// Pre
	skillControl.ClientPutInServer(client);
	playerControl.ClientPutInServer(client);
	
	if (IsFakeClient(client))
		botControl.BotPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	playerControl.ClientDisconnected(client);
}

public void OnMapStart()
{
	mapControl.OnMapStart();
}

public void OnEntityCreated(int entity, const char[] class)
{
	if (StrContains(class, "weapon_") != -1)
		SDKHook(entity, SDKHook_SpawnPost, OnWeaponCreatedPre);
}

public void OnWeaponCreatedPre(int weapon)
{
	weapon = EntRefToEntIndex(weapon);
	RequestFrame(OnWeaponCreatedPost, weapon);
}

public void OnWeaponCreatedPost(int weapon)
{
	weaponControl.WeaponCreated(weapon);
}

public Action CS_OnBuyCommand(int client, const char[] weaponClass)
{
	if (IsFakeClient(client))
		return botControl.OnBotBuyCommand(client, weaponClass);
	else
		return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client))
		botControl.OnBotRunCmd(client, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);

	weaponControl.OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);
	return Plugin_Changed;
}

void Initiailize()
{
	RPG_LogMessage("Initiailize...");
	manager = new GameManager();
	manager.CreateDataSet(TemplateDataSet); // 범용적으로 사용.
	
	weaponControl = new WeaponControl();
	roundControl = new RoundControl();
	mapControl = new MapControl();
	botControl = new BotControl();
	teamCycler = new TeamCycler();
	configControl = new ConfigControl();
	adminCommands = new AdminCommands();
	playerControl = new PlayerControl();
	economicControl = new EconomicControl();
	skillControl = new SkillControl();
	
	RPG_LogMessage("Initiailize Done!");
}

void LoadDatas()
{
	RPG_LogMessage("Data Load...");
	teamCycler.LoadData();
	botControl.LoadData();
	weaponControl.LoadData();
	skillControl.LoadData();
	configControl.Run();
	
	RPG_LogMessage("Data Load Done!");
}