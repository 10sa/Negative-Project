public void NTProject_HooksInit()
{
	HookEventEx("round_freeze_end", Hooks_RoundFreezeEndPost, EventHookMode_Post);
	HookEventEx("weapon_fire", Hooks_WeaponFirePostEvent, EventHookMode_Post);
	HookEventEx("player_spawn", Hooks_PlayerSpawnPost, EventHookMode_Post);
	HookEventEx("player_death", Hooks_PlayerDeathPost, EventHookMode_Post);
	HookEventEx("round_start", Hooks_RoundStartPost, EventHookMode_Post);
	HookEventEx("round_end", Hooks_RoundEndPost, EventHookMode_Post);
	HookEventEx("round_end", Hooks_RoundEndPre, EventHookMode_Pre);
	HookEventEx("player_blind", Hooks_PlayerBlindFlashbang, EventHookMode_Post);
	HookEventEx("bot_takeover", Hooks_BotTakeOver, EventHookMode_Pre);
	HookEvent("player_jump", Hooks_PlayerJump, EventHookMode_Pre);
	HookEvent("player_hurt", Hooks_PlayerHurt);
	
	RegConsoleCmd("say", Hooks_SayHook);
	RegConsoleCmd("say_team", Hooks_SayHook);
	
	AddCommandListener(Hooks_JoinTeam, "jointeam");
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessagesHook, true);
	
	Hooks_LoadWeaponDamageData();
}

public void Hooks_OnCSWeaponDrop(int client, int weapon)
{
	if (IsWarmup())
		CreateTimer(5.0, WarmupWeaponDeleteTimer, weapon, TIMER_FLAG_NO_MAPCHANGE);
}

public Action WarmupWeaponDeleteTimer(Handle timer, int weapon)
{
	if (!IsValidClient(GetEntityOwner(weapon)))
		RemoveEdict(weapon);
		
	return Plugin_Stop;
}

public Action Hooks_RoundFreezeEndPost(Event event, const char[] name, bool dontBroadcast)
{
	RoundControl_RoundFreezeEnd();
}

public Action Hooks_RoundEndPre(Event event, const char[] name, bool dontBroadcast)
{
	RoundControl_RoundEndPre();
}

public Action Hooks_BotTakeOver(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Stop;
}

public Action Hooks_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientByEvent(event);
	
	if (IsValidClient(client))
	{
		if (IsFakeClient(client))
			BotControl_BotJump(client);
	}
	
	return Plugin_Continue;
}

public void Hooks_WeaponSpawned(int entity)
{
	// 1프레임 넘긴 뒤 하는듯?
	entity = EntRefToEntIndex(entity);
	RequestFrame(WeaponCreated, entity);
}

public Action Hooks_JoinTeam(int client, char[] command, int args)
{
	int team;
	char teamName[3];
	GetCmdArg(1, teamName, sizeof(teamName));
	team = StringToInt(teamName);
	
	if (team == CS_TEAM_SPECTATOR && IsAdmin(client))
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	else
		ChangeClientTeam(client, hMapData.GetNum(MapDataUserTeam, CS_TEAM_T));
	
	return Plugin_Handled;
}

public Action Hooks_PlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientByEvent(event);
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	
	if(IsValidClient(attacker) || IsValidClient(assister))
	{
		BotControl_PlayerDeath(attacker, assister); // 봇이 킬을 했거나, 도움을 줬을 경우
		
		if (IsFakeClient(attacker))
			BotSkillHandler_PlayerDeath(client, attacker, assister);
	}
	
	if (IsFakeClient(client)) // 죽은 대상이 봇인 경우 (처리를 봇으로 넘기지 않는 이유는 경험치 지급은 플레이어 데이터 관할임.)
	{
		BotControl_BotDeath(client, attacker);
		PlayerDataControl_BotDeath(client, attacker);
	}
}

public Action Hooks_PlayerSpawnPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientByEvent(event);
	
	if (IsFakeClient(client))
	{
		BotControl_BotSpawnPost(client);
		BotSkillHandler_PlayerSpawn(client);
	}
	else
		PlayerControl_PlayerSpawn(client);
}

public Action Hooks_PlayerBlindFlashbang(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientByEvent(event);
	
	// 이 이벤트는 사망 후에도 발생하니까 살아있는지 확인해야 함.
	if (IsValidClient(client))
	{
		if (IsFakeClient(client))
			BotControl_BotBlind(client);
	}
}

void WeaponCreated(int entity)
{
	if (entity == INVALID_ENT_REFERENCE || !IsValidEdict(entity) || !IsValidEntity(entity))
		return;
	
	int weaponOwner = GetEntityOwner(entity);
	if (weaponOwner > 0)
	{
		SDKHookEx(entity, SDKHook_Reload, Hooks_PlayerReloadPre);
		SDKHookEx(entity, SDKHook_ReloadPost, Hooks_PlayerReloadPost);
	
		if (!IsFakeClient(weaponOwner))
		{
			SetWeaponDefaultAmmo(entity);
			Skills_PlayerBuyWeapon(weaponOwner, entity);
		}
	}
}

void SetWeaponDefaultAmmo(int weapon)
{
	char weaponClass[ClassBufferLength];
	GetWeaponClassEx(weapon, weaponClass, sizeof(weaponClass));
	
	int weaponDefaultAmmo = GetWeaponDefaultAmmo(weaponClass);
	if (weaponDefaultAmmo > -1)
		SetWeaponAmmo(weapon, weaponDefaultAmmo);
}

public void Hooks_LoadWeaponDamageData()
{
	if (hWeaponData != INVALID_HANDLE)
		CloseHandle(hWeaponData);
		
	hWeaponData = CreateKeyValuesEx("game_data/weapon_data_table.txt", "weapon_data_table");
}

public Action Hooks_RoundEndPost(Event event, const char[] name, bool dontBroadcast)
{
	RoundControl_RoundEndPost(event);
}

public Action Hooks_RoundStartPost(Event event, const char[] name, bool dontBroadcast)
{
	RoundControl_RoundStartPost();
}

public Action Hooks_SayHook(int client, int args)
{
	char argMsgBuffer[256]; // 버퍼를 크게 잡을 것, 유저는 항상 개발자의 상상을 뛰어넘음에 유의.
	char playerName[NameBufferLength];
	
	GetCmdArgString(argMsgBuffer, sizeof(argMsgBuffer));
	GetClientName(client, playerName, sizeof(playerName));
	StripQuotes(argMsgBuffer);
	TrimString(argMsgBuffer);
	
	if (!StrEqual(argMsgBuffer, "") && strlen(argMsgBuffer) > 0)
		PrintToChatAll(" \x04[Lv.%d] \x05%s : \x01%s ", GetClientLevel(client), playerName, argMsgBuffer);
	
	return Plugin_Handled;
}

public Action Hooks_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int dmg_health = event.GetInt("dmg_health");
	int hitgroup = event.GetInt("hitgroup");
	char weaponClass[ClassBufferLength];
	event.GetString("weapon", weaponClass, sizeof(weaponClass));
	
	if (IsFakeClient(victim))
	{
		BotControl_BotHurt(victim, attacker, dmg_health, hitgroup);
	
		if (IsValidClient(attacker) && !IsFakeClient(attacker))
			DrawHitDamageBox(victim, attacker, dmg_health, hitgroup);
	}
}

public Action Hooks_PlayerReloadPre(int weapon)
{
	int client = GetEntityOwner(weapon);
	
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		int ammo = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		
		hPlayerTempData[client].SetNum("iOrignalClip", clip);
		hPlayerTempData[client].SetNum("iOrignalAmmo", ammo);
	}
}

public void Hooks_PlayerReloadPost(int weapon, bool isSuccess)
{
	int client = GetEntityOwner(weapon);
	
	if (isSuccess && !IsFakeClient(client))
	{	
		DataPack timerData;
		CreateDataTimer(0.1, ReloadPostWait, timerData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE)
		
		timerData.WriteCell(weapon);
		timerData.WriteCell(client);
		timerData.WriteCell(hPlayerTempData[client].GetNum("iOrignalClip"));
		timerData.WriteCell(hPlayerTempData[client].GetNum("iOrignalAmmo"));
	}
}

Action ReloadPostWait(Handle timer, Handle cells)
{
	ResetPack(cells);
	int weapon = ReadPackCell(cells);

	if (IsValidEntity(weapon))
	{
		if (!GetEntProp(weapon, Prop_Data, "m_bInReload"))
		{
			int owner = ReadPackCell(cells);
			int orignalClip = ReadPackCell(cells);
			int orignalAmmo = ReadPackCell(cells);
			int clip1 = GetEntProp(weapon, Prop_Send, "m_iClip1");
		
			int useAmmo = clip1 - orignalClip;
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", orignalAmmo - useAmmo);
			
			if (GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount") == orignalAmmo - useAmmo)
				return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;
		
	return Plugin_Continue;
}

float SetWeaponDamage(char[] weaponClass, float damage, int damageType)
{
	float calcDamage = damage;
	if (damageType & CS_DMG_HEADSHOT)
	{
		char headshotName[ClassBufferLength];
		Format(headshotName, sizeof(headshotName), WeaponDataHeadshotDamage, weaponClass);
		float headMulValue = hWeaponData.GetFloat(headshotName, 1.0);
		calcDamage *= headMulValue;
	}
	else
	{
		float mulValue = hWeaponData.GetFloat(weaponClass, 1.0);
		calcDamage *= mulValue;
	}
	
	return calcDamage;
}

float SetKnifeDamage(float damage)
{
	// ZP 에서 가져왔음.
	float secondaryDamage[4] = {55.0, 65.0, 153.0, 180.0};
	
	for(int i = 0; i < 4; i++)
	{
		if (secondaryDamage[i] == damage)
			return hWeaponData.GetFloat(WeaponDataPowerKnifeDamage, damage);
	}
	
	return hWeaponData.GetFloat(WeaponDataNormalKnifeDamage, damage);
}

void DrawHitDamageBox(int victim, int attacker, int dmg_health, int hitgroup)
{
	char boxMsg[256];
	int victimHealth = GetEntProp(victim, Prop_Send, "m_iHealth");
	// 샷건은 데미지가 총알 한발 한발로 적용됨
	CreateTimer(0.01, Worker_ResetPlayerAttackDamage, attacker);
	
	dmg_health += hPlayerTempData[attacker].GetNum("iDamageLog", 0);
	hPlayerTempData[attacker].SetNum("iDamageLog", dmg_health);
	
	if (GetClientArmor(victim) > 0)
		Format(boxMsg, sizeof(boxMsg), "<font color='#00FFFF' size='%d'>- %d HP</font> (%d HP)", 24, dmg_health, victimHealth);
	else
		Format(boxMsg, sizeof(boxMsg), "<font color='#FF0000' size='%d'>- %d HP</font> (%d HP)", 24, dmg_health, victimHealth);
	
	PrintHintText(attacker, boxMsg);
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i) && GetClientObserverTarget(i) == attacker)
			PrintHintText(i, boxMsg);
	}
}

public Action Hooks_WeaponFirePostEvent(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientByEvent(event);
	
	if (IsValidClient(client))
	{
		int weapon = GetClientActiveWeapon(client);
		if (IsFakeClient(client) && hBotData[client].GetNum(BotDataInfAmmo, false))
			SetWeaponClip(weapon, 235);
	}
	
	return Plugin_Continue;
}

// Zp에서 가져옴 (몇개는 집적 파싱)
public Action UserMessagesHook(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (reliable)
	{
		char params[PLATFORM_MAX_PATH];
		PbReadString(msg, "params", params, sizeof(params), 0);
		if (StrEqual(params, "#hostagerescuetime") ||
			StrEqual(params, "#SFUI_Notice_YouDroppedWeapon") ||
			StrContains(params, "#Player_Cash_Award_ExplainSuicide") != -1 ||
			StrContains(params, "Cstrike_TitlesTXT_Game_disconnected") != -1 ||
			StrContains(params, "Cstrike_TitlesTXT_Game_join") != -1 ||
			StrEqual(params, "#Cstrike_TitlesTXT_CarryingHostage") ||
			StrEqual(params, "#Cstrike_TitlesTXT_Game_teammate_attack") ||
			StrEqual(params, "#Hint_try_not_to_injure_teammates") ||
			StrEqual(params, "#Chat_SavePlayer_Saved") ||
			StrEqual(params, "#Chat_SavePlayer_Savior") ||
			StrEqual(params, "#Chat_SavePlayer_Spectator"))
			
        {
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}