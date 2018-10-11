public void NTProject_MapControlInit()
{
	MapControl_LoadTeamData();
}

public void MapControl_LoadTeamData()
{
	if (hTeamData != INVALID_HANDLE)
		CloseHandle(hTeamData);
		
	hTeamData = CreateKeyValuesEx("bot_data/bot_team_list.txt", "teamlist");
}

public void MapControl_OnMapEnd()
{
	// 맵 종료로 더이상 맵 kv가 필요하지 않으므로 닫음
	CloseHandle(hMapData);
}

public void MapControl_OnMapStart()
{
	MapControl_LoadMapData();
	CreateSpawnPoints();
}

public void MapControl_LoadMapData()
{
	char mapName[64];
	char mapDataPath[256];
	
	GetCurrentMap(mapName, sizeof(mapName));
	GetMapDataPath(mapDataPath, sizeof(mapDataPath), mapName);
	
	hMapData = CreateKeyValuesEx(mapDataPath, mapName);
	hMapData.SetString(MapDataMapDataPath, mapDataPath);
	
	if (StrContains(mapName, Map_de) != -1)
	{
		hMapData.SetNum(MapDataUserTeam, CS_TEAM_T);
		hMapData.SetNum(MapDataEnemyTeam, CS_TEAM_CT);
	}
	else
	{
		hMapData.SetNum(MapDataUserTeam, CS_TEAM_CT);
		hMapData.SetNum(MapDataEnemyTeam, CS_TEAM_T);
	}
		
	iGameLevel = hMapData.GetNum(MapDataMinGameLevel, DefaultBotMinLevel);
	
	LoadTeamData(TeamDataEnemyTeam, TeamDataLastEnemyTeamName, MapDataEnemyTeamInfo);
	LoadTeamData(TeamDataFriendTeam, TeamDataLastFriendTeamName, MapDataFriendTeamInfo);
}

void LoadTeamData(char[] team, char[] lastTeam, char[] infoTeam)
{
	char lastTeamName[64];
	hTeamData.GetString(lastTeam, lastTeamName, sizeof(lastTeamName), NULL_STRING);
	
	if (hTeamData.JumpToKey(team, false))
	{
		char selectTeamName[64];
		char teamFilePath[64];
		
		if (StrEqual(lastTeamName, NULL_STRING) || !hTeamData.JumpToKey(lastTeamName, false))
			hTeamData.GotoFirstSubKey();
			
		for (int i = 0; i < 2; i++)
		{
			do
			{
				bool isSelectable = hTeamData.GetNum(TeamDataIsSelectableTeam, false) ? true : false;
				hTeamData.GetString(TeamDataPath, teamFilePath, sizeof(teamFilePath), NULL_STRING);
				hTeamData.GetSectionName(selectTeamName, sizeof(selectTeamName));
				
				if (!StrEqual(selectTeamName, lastTeamName) && isSelectable)
					break;
			}
			while(hTeamData.GotoNextKey())
			
			if (!StrEqual(selectTeamName, lastTeamName))
				break;
			else
			{
				hTeamData.Rewind();
				hTeamData.JumpToKey(team, false);
				hTeamData.GotoFirstSubKey();
			}
		}
		
		hTeamData.Rewind();
		
		hMapData.JumpToKey(infoTeam, true);
		hMapData.SetString(MapDataTeamName, selectTeamName);
		hMapData.SetString(MapDataTeamDataPath, teamFilePath);
		hTeamData.SetString(lastTeam, selectTeamName);
		
		hMapData.Rewind();
		
		LogAction(0, -1, "[Notify] %s Team selected. [Prev : %s]", selectTeamName, lastTeamName);
	}
}

// 스폰포인트는 다시 생성하면 안됨, 맵 꼬일수도 있음.
void CreateSpawnPoints()
{
	if (hMapData.JumpToKey(MapDataMapSpawnPoints))
	{
		CreateTeamSpawnPoint(REAL_TEAM_CT);
		CreateTeamSpawnPoint(REAL_TEAM_T);
	}
}

void CreateTeamSpawnPoint(int team)
{
	char numBuf[2];
	char entityName[32];
	float posBuf[3];
	
	IntToString(team, numBuf, sizeof(numBuf));
	// CT
	if (team == REAL_TEAM_CT)
		entityName = "info_player_counterterrorist";
	else if (team == REAL_TEAM_T)
		entityName = "info_player_terrorist";
	else
	{
		LogError("[Error] Wrong Team.");
		return;
	}
		
	if (hMapData.JumpToKey(numBuf) && hMapData.GotoFirstSubKey())
	{
		do
		{
			hMapData.GetVector(MapDataMapSpawnPointPos, posBuf);
			int spawnpoint = CreateEntityByName(entityName);
			if (DispatchSpawn(spawnpoint))
				TeleportEntity(spawnpoint, posBuf, NULL_VECTOR, NULL_VECTOR);
			else // 냅두면 누수 일어나는지는 확인되지 않음. (설령 일어난다 한들 그리 크게 영향을 끼치진 않을듯.)
				LogError("[Error] Spawnpoint Create Failure!");
		}
		while (hMapData.GotoNextKey())
	}
	
	hMapData.Rewind();
}

stock int GetEnemyTeam()
{
	return hMapData.GetNum(MapDataEnemyTeam, CS_TEAM_CT);
}

stock int GetHumanTeam()
{
	return hMapData.GetNum(MapDataUserTeam, CS_TEAM_T);
}

stock bool GetActiveTeamDataPath(char[] teamType, char[] buffer, int length)
{
	if (GetActiveTeamPath(teamType, buffer, length))
	{
		CreateBotTeamDataPath(buffer, length, buffer);
		return true;
	}
	else
		return false;
}

stock bool GetActiveTeamPath(char[] teamType, char[] buffer, int length)
{
	if (hMapData.JumpToKey(teamType))
	{
		hMapData.GetString(MapDataTeamDataPath, buffer, length, NULL_STRING);
		hMapData.Rewind();

		return true;
	}
	else
		return false;
}

stock bool GetTeamDataByTeamPath(char[] teamType, char[] teamName, char[] buffer, int length)
{
	if (hTeamData.JumpToKey(teamType) && hTeamData.JumpToKey(teamName))
	{
		hTeamData.GetString(TeamDataPath, buffer, length, NULL_STRING);
		hTeamData.Rewind();
		
		CreateBotTeamDataPath(buffer, length, buffer);
		return true;
	}
	
	hTeamData.Rewind();
	
	return false;
}

stock bool GetMapSound(char[] key, char[] buffer, int length)
{
	if (hMapData.JumpToKey(MapDataMapSounds, false))
	{
		hMapData.GetString(key, buffer, length, NULL_STRING);
		hMapData.Rewind();
		
		if (!StrEqual(buffer, NULL_STRING))
			return true;
	}
	
	return false;
}

void GetMapDataPath(char[] buffer, int length, char[] mapName)
{
	Format(buffer, length, MapDataPath, mapName);
}