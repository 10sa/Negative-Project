public void NTProject_AdminCommandsInit()
{
	RegAdminCmd("nt_create_sp", AdminCommand_CreateSpawnPoints, ADMFLAG_ROOT, "Create a spawnpoint.");
	RegAdminCmd("nt_reload_botprofile",AdminCommand_LoadBotProfile, ADMFLAG_ROOT, "Reload Botprofile Kv.");
	RegAdminCmd("nt_reload_mapdata", AdminCommand_LoadMapData, ADMFLAG_ROOT, "Reload Map Kv.")
	RegAdminCmd("nt_reload_teamdata", AdminCommand_LoadTeamData, ADMFLAG_ROOT, "Reload Team Kv.");
	RegAdminCmd("nt_reload_weapon", AdminCommand_LoadWeaponDamage, ADMFLAG_ROOT, "Reload Weapon Kv.");
	RegAdminCmd("nt_debug_enable", AdminCommand_EnableDebug, ADMFLAG_ROOT, "Set Debug Mode.");
	RegAdminCmd("nt_debug_disable", AdminCommand_DisableDebug, ADMFLAG_ROOT, "Remove Debug Mode.");
	RegAdminCmd("nt_setgamelevel", AdminCommand_SetGameLevel, ADMFLAG_ROOT, "Set Game Level");
	RegAdminCmd("nt_reload_skills", AdminCommand_LoadSkillData, ADMFLAG_ROOT, "Reload Skill Kv.");
	RegAdminCmd("nt_test_classname", AdminCommand_TestClassName, ADMFLAG_ROOT, "Test.");
	RegAdminCmd("nt_play_sound", AdminCommand_TestSoundPlay, ADMFLAG_ROOT, "Test.");
	RegAdminCmd("nt_sound_cache", AdminCommand_SoundPrecache, ADMFLAG_ROOT, "Test.");
	RegAdminCmd("nt_test",	AdminCommand_TestCommand, ADMFLAG_ROOT, "Test.");
	RegAdminCmd("nt_giveexp", AdminCommand_GivePlayerExp, ADMFLAG_ROOT, "Admin Command!");
	RegServerCmd("bot_add", AdminCommand_BotAddCommand, "??");
	RegServerCmd("bot_add_ct", AdminCommand_BotAddCommand, "??");
	RegServerCmd("bot_add_t", AdminCommand_BotAddCommand, "??");
}

public Action AdminCommand_TestCommand(int client, int args)
{
	PlayerFreeze(client, 5.0);
	PrintToChat(client, "You're Freezed!");
	
	return Plugin_Handled;
}

public Action AdminCommand_GivePlayerExp(int client, int args)
{
	if (args > 1)
	{
		char clientName[128];
		char buffer[64];
		
		GetCmdArg(1, clientName, sizeof(clientName));
		GetCmdArg(2, buffer, sizeof(buffer));
		
		int target = GetClientByName(clientName);
		int exp = StringToInt(buffer);

		if (!IsFakeClient(target))
		{
			PlayerDataManager_GiveExp(target, exp);
			PrintToChat(client, " \x04[Admin]\x01 해당 플레이어에게 \x08%d\x01 경험치가 지급되었습니다.", exp);
		}
	}
	
	return Plugin_Handled;
}

public Action AdminCommand_BotAddCommand(int args)
{
	char client_name[128];
	char theargs[128];
	
	GetCmdArg(1, theargs, sizeof(theargs));
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (!IsValidClient(i) || IsFakeClient(i))
			continue;
		
		GetClientName(i, client_name, sizeof(client_name));
		if (StrEqual(theargs, client_name))
		{
			KickClient(i, "미안하지만 같은 존재를 서로 만나게 할 수는 없어, 다른 존재로 와.");
			break;
		}
	}
	
	return Plugin_Continue;
}

public Action AdminCommand_TestClassName(int client, int args)
{
	char buffer[256];
	
	int weapon = GetClientActiveWeapon(client);
	GetWeaponClassEx(weapon, buffer, sizeof(buffer));
	PrintToConsole(client, "%s", buffer);
}

public Action AdminCommand_TestSoundPlay(int client, int args)
{
	char path[128];
	GetCmdArg(1, path, sizeof(path));
	
	EmitSoundToAllAny(path, client, SNDCHAN_STATIC);
}

public Action AdminCommand_SoundPrecache(int client, int args)
{
	char path[128];
	GetCmdArg(1, path, sizeof(path));
	
	PrecacheSoundAny(path);
}


public Action AdminCommand_LoadSkillData(int client, int args)
{
	SkillHandler_LoadSkillData();
	PrintToChat(client, "Skill 리스트를 로드했습니다.");
	
	return Plugin_Handled;
}

public Action AdminCommand_SetGameLevel(int client, int args)
{
	char numBuf[8];
	GetCmdArg(1, numBuf, sizeof(numBuf));
	
	iGameLevel = StringToInt(numBuf);
	PrintToChatAll("[Admin] 게임 레벨이 %d 레벨로 설정되었습니다.", iGameLevel);
	
	return Plugin_Handled;
}

public Action AdminCommand_EnableDebug(int client, int args)
{
	hPlayerTempData[client].SetNum("iDebug", true);
	
	return Plugin_Handled;
}

public Action AdminCommand_DisableDebug(int client, int args)
{
	hPlayerTempData[client].SetNum("iDebug", false);
	
	return Plugin_Handled;
}

public Action AdminCommand_LoadWeaponDamage(int client, int args)
{
	Hooks_LoadWeaponDamageData();
	
	PrintToChat(client, "Weapon Damage 리스트를 로드했습니다.");
	return Plugin_Handled;
}

public Action AdminCommand_LoadTeamData(int client, int args)
{
	MapControl_LoadTeamData();
	
	PrintToChat(client, "Team Data 리스트를 로드했습니다.");
	return Plugin_Handled;
}

public Action AdminCommand_LoadMapData(int client, int args)
{
	MapControl_LoadMapData();
	
	PrintToChat(client, "Map Data 리스트를 로드했습니다.");
	return Plugin_Handled;
}

public Action AdminCommand_LoadBotProfile(int client, int args)
{
	BotControl_LoadBotList();
	
	PrintToChat(client, "Bot Profile 리스트를 로드했습니다.");
	return Plugin_Handled;
}

public Action AdminCommand_CreateSpawnPoints(int client, int args)
{
	KeyValues hOrignalMapData;
	float spawnpointPos[3];
	int team;
	
	char clientName[NameBufferLength];
	char numBuf[3];
	char teamStr[2];
	char buffer[32];
	char mapDataPath[64];
	char mapName[32];
	
	hMapData.GetSectionName(mapName, sizeof(mapName));
	hMapData.GetString(MapDataMapDataPath, mapDataPath, sizeof(mapDataPath));
	
	hOrignalMapData = CreateKeyValues(mapName);
	hOrignalMapData.ImportFromFile(mapDataPath);
	hOrignalMapData.JumpToKey(MapDataMapSpawnPoints, true);
	
	GetClientName(client, clientName, sizeof(clientName));
	GetClientAbsOrigin(client, spawnpointPos);
	
	GetCmdArg(1, buffer, sizeof(buffer))
	team = StringToInt(buffer);
	
	if (team != 1 && team != 2)
		PrintToChat(client, "Bad Team.");
	else
	{
		IntToString(team, teamStr, sizeof(teamStr));
		hOrignalMapData.JumpToKey(teamStr, true);
		
		GetClientAbsOrigin(client, spawnpointPos);
	
		int insertPos = 1;
		
		if (hOrignalMapData.GotoFirstSubKey())
		{
			insertPos++;
			
			for( ; hOrignalMapData.GotoNextKey(); insertPos++) { }
			hOrignalMapData.Rewind();
		}
		
		IntToString(insertPos, numBuf, sizeof(numBuf));
		hOrignalMapData.JumpToKey(MapDataMapSpawnPoints);
		hOrignalMapData.JumpToKey(teamStr);
		hOrignalMapData.JumpToKey(numBuf, true);

		hOrignalMapData.SetVector(MapDataMapSpawnPointPos, spawnpointPos);
		hOrignalMapData.SetString(MapDataMapSpawnPointCreater, clientName);
		
		PrintToChat(client, "스폰 포인트 생성 완료.");
	}
	
	hOrignalMapData.Rewind();
	hOrignalMapData.ExportToFile(mapDataPath);
	CloseHandle(hOrignalMapData);
	
	return Plugin_Handled;
}