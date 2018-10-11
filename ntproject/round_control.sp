public void NTProject_RoundControlInit()
{
	RoundControl_LoadServerTips();
}

public void RoundControl_OnMapStart()
{
	RoundControl_SetTeamName();
	BotControl_BotTeamSpawn();
	
	iRound = 1;
}

public void RoundControl_LoadServerTips()
{
	if (hServerTips != INVALID_HANDLE)
		CloseHandle(hServerTips);
		
	hServerTips = CreateKeyValuesEx("game_data/server_tips.txt", "server_tips");
}

public void RoundControl_RoundEndPost(Event event)
{
	int winner = event.GetInt("winner");
	
	if (winner == hMapData.GetNum(MapDataUserTeam, CS_TEAM_T))
		RoundWin();
	else
		RoundLose();
	
	if (!IsWarmup())
	{
		iRound += 1;
		
		if (GetMaxRound() + 1 == iRound)
		{
			char filePath[128];
			GetMapSound("mapchange", filePath, sizeof(filePath));
			EmitSoundToAllAnyEx(filePath);
		}
	}
}

public void RoundControl_RoundEndPre()
{
	iRoundStatus = RoundStatusEnd;
	if (!StrEqual(sPlayingMusic, NULL_STRING))
		StopSoundToAll(sPlayingMusic);
}

public void RoundControl_RoundFreezeEnd()
{
	char filePath[128];
	char numBuf[3];
	
	iRoundStatus = RoundStatusPlaying;
	IntToString(iRound, numBuf, sizeof(numBuf));
	if (!IsWarmup() && GetMapSound(numBuf, filePath, sizeof(filePath)))
		EmitSoundToAllAnyEx(filePath);
}

public void RoundControl_SetTeamName()
{
	char enemyTeamName[64];
	char friendTeamName[64];
	
	char levelNum[3];
	
	IntToString(iGameLevel, levelNum, sizeof(levelNum));
	
	// 맵에 정의된 적 팀 이름 탐색 (중복 방지 체크해서 전송 안하게 하는건?..
	if (hMapData.JumpToKey(MapDataLevelTeams, false))
	{
		// 레벨별 재정의된 팀 이름 확인
		hMapData.GetString(levelNum, enemyTeamName, sizeof(enemyTeamName), NULL_STRING);
		if(StrEqual(enemyTeamName, NULL_STRING))
			hMapData.GetString(DefaultKey, enemyTeamName, sizeof(enemyTeamName), NULL_STRING); // 맵 디폴트 팀 이름 확인
		
		hMapData.Rewind();
	}
	
	// 맵에 정의된 모든 보스 탐색 실패. (보스 순환 리스트에 따라 설정, 이 값은 MapControl 에서 옴)
	if (StrEqual(enemyTeamName, NULL_STRING))
	{
		hMapData.JumpToKey(MapDataEnemyTeamInfo, false);
		hMapData.GetString(MapDataTeamName, enemyTeamName, sizeof(enemyTeamName));
		
		hMapData.Rewind();
	}
	
	if (hMapData.JumpToKey(MapDataFriendTeamInfo, false))
	{
		hMapData.JumpToKey(MapDataFriendTeamInfo, false);
		hMapData.GetString(MapDataTeamName, friendTeamName, sizeof(friendTeamName));
	
		hMapData.Rewind();
	}
	

	SetTeamName(hMapData.GetNum(MapDataUserTeam, CS_TEAM_T), DefaultUserTeamName);
	SetTeamName(hMapData.GetNum(MapDataEnemyTeam, CS_TEAM_CT), enemyTeamName);
	
	hMapData.SetString(MapDataSelectEnemyTeam, enemyTeamName);
	hMapData.SetString(MapDataSelectFriendTeam, friendTeamName);
}

public void RoundControl_RoundStartPost()
{
	iRoundStatus = RoundStatusFreeze;
	char mapObject[256];
	char levelNum [3];
	
	// 맵 데이터 파일에 해당 라운드의 오브젝트 재정의가 있는지 확인하고, 없을 경우 디폴트 오브젝트를 탐색
	// 필요하다면 맵 로딩때 캐싱할 것
	if (hMapData.JumpToKey(MapDataMapObjectPrefix, false))
	{
		IntToString(iGameLevel, levelNum, sizeof(levelNum));
		hMapData.GetString(levelNum, mapObject, sizeof(mapObject), NULL_STRING);
		
		if (StrEqual(mapObject, NULL_STRING))
			hMapData.GetString(DefaultKey, mapObject, sizeof(mapObject), NULL_STRING);
			
		hMapData.Rewind();
	}
	
	// 탐색에 실패한 경우
	if (StrEqual(mapObject, NULL_STRING))
	{
		if(hMapData.GetNum(MapDataUserTeam) == CS_TEAM_T)
			mapObject = DefaultTObject;
		else
			mapObject = DefaultCTObject;
	}

	
	RoundControl_SetTeamName();
	BotControl_BotTeamSpawn();
	
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i))
		{
			for (int v = 0; v < CS_SLOT_KNIFE; v++)
				WeaponCreated(GetPlayerWeaponSlot(i, v));
		}
	}
	
	if (!IsWarmup())
	{
		PrintToChatAll(" \x04[Game Level] \x01Lv. %d", iGameLevel);
		PrintToChatAll(" \x04[Game Round] \x01%d Round", iRound);
		PrintToChatAll(" \x04[Game Objective] \x01%s", mapObject);
		
		int maxRandomValue = hServerTips.GetNum("iMaxCount", 0);
		if (maxRandomValue > 0)
		{
			char tip[128];
			char numBuf[3];
			
			IntToString(GetRandomInt(1, maxRandomValue), numBuf, sizeof(numBuf));
			hServerTips.GetString(numBuf, tip, sizeof(tip), NULL_STRING);
			if (!StrEqual(tip, NULL_STRING))
				PrintToChatAll(" \x04[Game Tip]\x01 %s", tip);
		}
	}
	else
	{
		char soundPath[128];
		if (GetMapSound("warmup", soundPath, sizeof(soundPath)))
			EmitSoundToAllAnyEx(soundPath);
	}
}

public void RoundWin()
{
	if (hMapData.GetNum(MapDataMaxGameLevel, DefaultBotMaxLevel) > iGameLevel)
	{
		PrintToChatAll(" \x04[Round Win] \x01Game Level : \x04Lv. %d -> Lv. %d", iGameLevel, iGameLevel + 1);
		iGameLevel++;
	}
	else
		PrintToChatAll(" \x04[Round Win] \x01Game Level : \x04Lv. %d", iGameLevel);
}

public void RoundLose()
{
	if (iGameLevel > hMapData.GetNum(MapDataMinGameLevel, DefaultBotMinLevel))
	{
		PrintToChatAll(" \x02[Round Lose] \x01Game Level : \x04Lv. %d -> Lv. %d", iGameLevel, iGameLevel - 1);
		iGameLevel--;
	}
	else
		PrintToChatAll(" \x02[Round Lose] \x01Game Level : \x04Lv. %d", iGameLevel);
}