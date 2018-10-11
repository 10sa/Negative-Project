public void NTProject_BotControlInit()
{
	BotControl_LoadBotList();	
	iBotCount = 0;
}

public void BotControl_LoadBotList()
{
	char filePath[128];
	CreateDataPath(filePath, sizeof(filePath), "bot_data/bot_profile");
	DirectoryListing list = OpenDirectory(filePath);
	
	if (hBotProfile != INVALID_HANDLE)
		CloseHandle(hBotProfile);
		
	hBotProfile = CreateKeyValues("bot_list");
	
	char filePathBuffer[256];
	char botName[128];
	
	while(list.GetNext(filePathBuffer, sizeof(filePathBuffer)))
	{
		if (StrContains(filePathBuffer, ".txt") != -1)
		{
			LogAction(0, -1, "[Notify] Load \"%s\" bot template...", filePathBuffer);
			
			Format(filePathBuffer, sizeof(filePathBuffer), "bot_data/bot_profile/%s", filePathBuffer);
			KeyValues botProfile = CreateKeyValuesEx(filePathBuffer, "temp_bot");
			
			botProfile.GetSectionName(botName, sizeof(botName));
			
			if (!hBotProfile.JumpToKey(botName, false))
			{
				hBotProfile.JumpToKey(botName, true);
				hBotProfile.Import(botProfile);
			}
			else
				LogError("[Error] \"%s\" Botprofile dup alert!", filePathBuffer);
				
			hBotProfile.Rewind();
			CloseHandle(botProfile);
		}
	}
}

public void BotControl_PlayerDeath(int attacker, int assister)
{
	if (assister > 0 && IsClientInGame(assister) && IsFakeClient(assister))
	{
		CS_SetClientContributionScore(assister, hBotData[assister].GetNum(BotDataRealExp) - 2);
		CS_SetClientAssists(assister, hBotData[assister].GetNum(BotDataRealCash));
	}
	
	if (attacker > 0 && IsClientInGame(attacker) && IsFakeClient(attacker))
		CS_SetClientContributionScore(attacker, hBotData[attacker].GetNum(BotDataRealExp) - 2);
		
}

public void BotControl_BotDeath(int client, int attacker)
{
	char clientName[NameBufferLength];
	char attackerName[NameBufferLength];
	
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(attacker, attackerName, sizeof(attackerName));
	
	if (!IsWarmup() && GetEnemyTeam() == GetClientTeam(client))
	{
		if (IsGunBot(client))
			PrintToChatAll(" \x04[Boss Kill] \x08%s\x01 님이 \x08%s\x01 보스를 퇴치하였습니다.", attackerName, clientName);
		else if (IsNamedBot(client))
			PrintToChatAll(" \x04[Named Kill] \x08%s\x01 님이 \x08%s\x01 네임드 몹을 퇴치하였습니다.", attackerName, clientName);
	}
}

public void BotControl_BotHurt(int victim, int attacker, int damage, int hitGroup)
{
	char attackerName[NameBufferLength];
	char victimName[NameBufferLength];
	
	
	if (IsFakeClient(victim) && IsValidClient(attacker) && hBotData[victim].GetNum(BotDataGunBot, false))
		LookAtHead(victim, attacker);
		
	if (IsValidClient(attacker))
	{
		hBotData[victim].JumpToKey(BotDataDamageKv, true);
		GetClientName(attacker, attackerName, sizeof(attackerName));
		GetClientName(victim, victimName, sizeof(victimName));
		
		hBotData[victim].JumpToKey(attackerName, true);
		
		// Post Hook 임, 데미지 입고 난 뒤의 체력이므로 주의할 것.
		int dataDamage = hBotData[victim].GetNum(BotDataDamageKvDamage, 0);
		int hp = GetEntProp(victim, Prop_Send, "m_iHealth"); // GetEntityHealth 쓰지 말것, 뭔가 이상함.

		// 음수값인 경우에만 그냥 데미지를 더함.
		if (hp >= 0)
			dataDamage += damage;
		else // 입는 데미지가 남은 체력 이상인 경우, 체력 이상의 값을 뺌.
			dataDamage += damage + hp;
			
		hBotData[victim].SetNum(BotDataDamageKvDamage, dataDamage);
		hBotData[victim].SetNum(BotDataDamageKvAttacker, attacker);
		
		hBotData[victim].Rewind();
	}
}

public void BotControl_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, BotControl_OnTakeDamage);
	SDKHook(client, SDKHook_WeaponDrop, BotControl_BotWeaponDropBlock);
	SDKHook(client, SDKHook_Think, BotControl_BotThink);
	SDKHook(client, SDKHook_ThinkPost, BotControl_BotThink);
	
	iBotCount++;
}

public void BotControl_OnClientDisconnect(int client)
{
	iBotCount--;
}

public void BotControl_BotSpawnPost(int client)
{
	InitBot(client);
}

public Action BotControl_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3])
{
	float changeDamage = damage;
	
	// 봇은 자기 자신에 의한 공격 	데미지를 입지 않음.
	if (victim == attacker)
		return Plugin_Handled;
	
	if (IsValidClient(attacker))
	{
		if (!IsFakeClient(attacker))
		{
			char weaponClass[ClassBufferLength];
			
			if (IsValidEntity(weapon))
				GetWeaponClassEx(weapon, weaponClass, sizeof(weaponClass));
			else
				GetEdictClassname(inflictor, weaponClass, sizeof(weaponClass))
			
			if (StrEqual(weaponClass, "weapon_knife"))
				changeDamage = SetKnifeDamage(damage);
			else
				changeDamage = SetWeaponDamage(weaponClass, changeDamage, damageType);
			
			// 스킬 데미지 처리
			Skills_PlayerAttack(attacker, victim, changeDamage, weaponClass);
			
			// 스텟 데미지 처리
			changeDamage = StetHandler_CalcPlayerDamage(attacker, changeDamage);
		}
		else
			BotSkillHandler_PlayerAttack(victim, attacker, changeDamage);
	}
	
	if (IsGunBot(victim))
	{
		if (damageType & DMG_BURN || damageType & DMG_FALL || damageType & DMG_BLAST)
			changeDamage = 0.0;
	}
	
	if (changeDamage != damage)
	{
		damage = changeDamage;
		return Plugin_Changed;
	}
	else
		return Plugin_Continue;
}

public void BotControl_BotTeamSpawn()
{
	char enemyTeamName[64];
	char lastEnemyTeamName[64];
	
	char friendTeamName[64];
	char lastFriendTeamName[64];

	hMapData.GetString(MapDataSelectEnemyTeam, enemyTeamName, sizeof(enemyTeamName), NULL_STRING);
	hMapData.GetString(MapDataLastEnemyTeamName, lastEnemyTeamName, sizeof(lastEnemyTeamName), NULL_STRING);
	
	hMapData.GetString(MapDataSelectFriendTeam, friendTeamName, sizeof(friendTeamName), NULL_STRING);
	hMapData.GetString(MapDataLastFriendTeamName, lastFriendTeamName, sizeof(lastFriendTeamName), NULL_STRING);
	
	if (StrEqual(enemyTeamName, NULL_STRING))
		LogError("[Error] Enemy Team Name is Null! [Select Name : %s / Last Name : %s]", enemyTeamName, lastEnemyTeamName);
		
	if (StrEqual(friendTeamName, NULL_STRING))
		LogError("[Error] Friend Team Name is Null! [Select Name : %s / Last Name : %s]", friendTeamName, lastFriendTeamName);

	if (!StrEqual(enemyTeamName, lastEnemyTeamName))
		BotTeamSpawn(hMapData.GetNum(MapDataEnemyTeam, CS_TEAM_CT), TeamDataEnemyTeam, enemyTeamName, MapDataLastEnemyTeamName);
		
	if (!StrEqual(friendTeamName, lastFriendTeamName))
		BotTeamSpawn(hMapData.GetNum(MapDataUserTeam, CS_TEAM_T), TeamDataFriendTeam, friendTeamName, MapDataLastFriendTeamName);
}

public Action BotControl_BotWeaponDropBlock(int client, int weapon)
{
	if (IsValidEntity(weapon))
	{
		char weaponClass[ClassBufferLength];
		char botWeapon[ClassBufferLength];
	
		GetWeaponClassEx(weapon, weaponClass, sizeof(weaponClass));
		hBotData[client].GetString(BotDataUseWeapon, botWeapon, sizeof(botWeapon));
		
		if (StrEqual(weaponClass, botWeapon) || StrEqual(weaponClass, "weapon_knife"))
			return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void BotControl_BotThink(int client)
{
	// ZP 에서 가져옴.
	float move_vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", move_vel);
	
	if (move_vel[2] < 0.0)
	{
		float speed = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
		if (FloatCompare(speed, 0.0) != 0 && speed > 0.0)
			SetEntityGravity(client, 1.0 / speed);
	}
	
	int weapon = GetClientActiveWeapon(client);
	if (IsValidEntity(weapon))
	{
		float fireRate = hBotData[client].GetFloat(BotDataRealFireRate, BotDefaultFireRate);
		float nextFire = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");

		if (fireRate < BotLimitFireRate)
			fireRate = BotLimitFireRate;
			
		nextFire -= GetGameTime();
		nextFire *= fireRate;
		nextFire += GetGameTime();
			
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nextFire);
	}
}

void BotTeamSpawn(int team, char[] teamType, char[] teamName, char[] saveSection)
{
	char teamDataPath[64];

	// 봇의 2중 스폰 방지
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsValidClient(i) && IsFakeClient(i) && GetClientTeam(i) == team)
		{
			char botName[NameBufferLength];
			char command[64];
			
			Format(command, sizeof(command), "bot_kick \"%s\"", botName);
			ServerCommand(command);
		}
	}
		
	if (GetTeamDataByTeamPath(teamType, teamName, teamDataPath, sizeof(teamDataPath)))
	{
		char botName[64];
		KeyValues teamList = CreateKeyValuesEx(teamDataPath, teamName);
		
		if (teamList.GotoFirstSubKey())
		{
			do
			{
				teamList.GetSectionName(botName, sizeof(botName));
				CreateBot(botName, team);
			}
			while(teamList.GotoNextKey())
			
			teamList.Rewind();
			if(teamList.GetNum(TeamListDefaultBot, true) && team != hMapData.GetNum(MapDataUserTeam, CS_TEAM_T))
				SpawnNormalBots();

			hMapData.SetString(saveSection, teamName);
		}
		else
			LogError("[Error] Team Data Load Failure!");
			
		CloseHandle(teamList);
	}
	else
		LogError("[Error] Team Data Path Not Found.");
}

public void BotControl_BotJump(int client)
{
	float gravityValue = 0.5;
	float speed = GetClientMovespeed(client);
	
	SetEntityGravity(client, gravityValue / speed);
}

public void BotControl_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsValidClient(client))
	{
		char weaponClass[ClassBufferLength];	
		int clientWeapon = GetClientActiveWeapon(client);
		GetClientActiveWeaponClass(client, weaponClass, sizeof(weaponClass));
		
		// 봇들은 걷지 않게
		buttons &= ~IN_SPEED;
		
		SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
		if (IsValidEntity(clientWeapon))
			SetEntPropFloat(clientWeapon, Prop_Send, "m_fAccuracyPenalty", 0.0);
		
		if (hBotData[client].GetNum(BotDataGunBot, false))	// 만약 건봇이라면.
			AimbotRoutine(client, buttons);
		else if (StrEqual(weaponClass, "weapon_knife"))	// 칼을 든 상태라면. (이론적으로 건봇도 칼을 쓸순 있지만, 이 경우는 상정하지 않는다.)
			KnifeBotRoutine(client, buttons);
	}
}

public Action BotControl_WeaponUseBlock(int client, int weapon)
{
	char class[ClassBufferLength];
	GetWeaponClassEx(weapon, class, ClassBufferLength);
	
	if(hBotData[client] != INVALID_HANDLE)
	{
		char useWeaponClass[ClassBufferLength];		
		hBotData[client].GetString(BotDataUseWeapon, useWeaponClass, ClassBufferLength, NULL_STRING);
		
		// C4는 예외적으로 들수 있음.
		if (StrEqual(useWeaponClass, class) || StrEqual(class, "weapon_c4") || StrEqual(useWeaponClass, NULL_STRING))
			return Plugin_Continue;
		else
			return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void BotControl_BotBlind(int client)
{
	char uniqueID[64];
	char pathBuffer[128];
	
	BotSkillHandler_BlindFlash(client);
	GetBotUniqueID(client, uniqueID, sizeof(uniqueID));
	if (!StrEqual(uniqueID, NULL_STRING))
	{
		CreateBotSoundPath(pathBuffer, sizeof(pathBuffer), uniqueID, "flashbang_blind.mp3");
		EmitSoundToAllAnyEx(pathBuffer, .soundType = "sfx", .entity = client);
	}
}

void KnifeBotRoutine(int client, int &buttons)
{
	int botRunTick = hBotData[client].GetNum(BotDataRunTick, 0);
	if (botRunTick >= BotKnifeAttackTick)
	{
		// ZP 에서 가져옴.
		float clientEyeAngle[3];
		int target = GetClientAimTarget(client, true);
			
		GetClientEyeAngles(client, clientEyeAngle);
			
		// 조건을 잘 모르겠음, Zeisen 님에게 물어볼 수 있다면 물어볼 것.
		if (clientEyeAngle[0] < -55.0)
		{
			if (!(buttons & IN_JUMP) && GetEntityMoveType(client) != MOVETYPE_LADDER)
				buttons |= IN_JUMP;
		}
		
		if (IsValidClient(target) && IsSeeableTarget(client, target) && !IsSameTeam(client, target))
		{
			float clientPos[3];
			float targetPos[3];
				
			GetClientAbsOrigin(client, clientPos);
			GetClientAbsOrigin(target, targetPos);
				
			float distance = GetVectorDistance(clientPos, targetPos);
			if (distance <= BotKnifeAttackDistance)	// 타겟과 클라이언트 간의 거리 비교, 원본에는 40 이상인 경우에도 포함되어 있는데, 기능을 모르므로 범위만 체크.
			{
				if (!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
					buttons |= IN_ATTACK;
			}
		}

		// Reset Tick.
		hBotData[client].SetNum(BotDataRunTick, 0);
	}
		
	hBotData[client].SetNum(BotDataRunTick, botRunTick + 1);
}

void AimbotRoutine(int client, int &buttons)
{
	int closerClient = GetCloserAndSeeableClient(client);
	
	if (IsValidClient(closerClient))
	{
		bool isSeeable = IsTargetInSightRange(client, closerClient, hBotData[client].GetFloat(BotDataViewAngle, BotDefaultViewAngle));
				
		// 해체중일땐 사방을 다 봄
		if (IsDefusing(client))
			isSeeable = true;
			
		if (IsValidClient(closerClient) && isSeeable)
		{
			float reaction = hBotData[client].GetFloat(BotDataReactionWait, 0.0);
			float botReactionTime = hBotData[client].GetFloat(BotDataReactionTime, BotDefaultReactionTime);
			int weapon = GetClientActiveWeapon(client);
				
			if (GetGameTime() >= reaction + botReactionTime)
			{
				int clientWeapon = GetClientActiveWeapon(client);
				
				LookAtHead(client, closerClient);
				if (IsValidEntity(clientWeapon) && !(buttons & IN_ATTACK) && GetGameTime() >= GetEntPropFloat(clientWeapon, Prop_Send, "m_flNextPrimaryAttack") && GetWeaponClip(weapon) > 0)
					buttons |= IN_ATTACK;
			}
			else
				hBotData[client].SetFloat(BotDataReactionWait, GetGameTime());
		}
		else // 타게팅 실패.
			hBotData[client].SetFloat(BotDataReactionWait, 0.0);
	}
}

// 캐싱 필요할 듯.
void InitBot(int client)
{
	// 참조용 변수, 실제로 값이 재할당되지 않고, 핸들이 부여됨.
	char clientName[NameBufferLength];
	GetClientName(client, clientName, sizeof(clientName));
	
	// 핸들이 있는 경우 닫아줌
	if(hBotData[client] != INVALID_HANDLE)
	{
		SDKHook(client, SDKHook_WeaponCanUse, BotControl_WeaponUseBlock);
		CloseHandle(hBotData[client]);
	}
	
	// 봇 데이터 핸들을 hBotData[client] 핸들로 복사해 둠. (후일에 변경될 수 있으므로)
	hBotData[client] = CreateKeyValues(clientName);
	
	if (hBotProfile.JumpToKey(clientName, false))
	{
		hBotProfile.JumpToKey(clientName);
		hBotData[client].Import(hBotProfile);
		hBotData[client].SetNum(BotDataNamed, true);
	}
	else
	{
		if (hBotProfile.JumpToKey("default", false))
		{
			hBotData[client].Import(hBotProfile);
			int maxValue = hBotProfile.GetNum(BotDataMaxRamdomModels, 0);
			
			if (maxValue > 0)
			{
				int randomModels = GetRandomInt(1, maxValue);
				char numBuf[3];
				
				IntToString(randomModels, numBuf, sizeof(numBuf));
				if (hBotProfile.JumpToKey(BotDataRamdomModels, false))
				{
					char modelPath[128];
					hBotProfile.GetString(numBuf, modelPath, sizeof(modelPath));
					hBotData[client].SetString(BotDataModel, modelPath);
				}
			}
		}
	}
	
	hBotProfile.Rewind();
		
	// 테이블로 편성해서 코드를 줄여 볼 것. //
	int hp = hBotData[client].GetNum(BotDataHp, BotDefaultHp);
	int ap = hBotData[client].GetNum(BotDataAp, BotDefaultAp);
	int exp = hBotData[client].GetNum(BotDataExp, BotDefaultExp);
	int cash = hBotData[client].GetNum(BotDataCash, BotDefaultCash);
	float ms = hBotData[client].GetFloat(BotDataMs, BotDefaultMs);
	float fireRate = hBotData[client].GetFloat(BotDataFireRate, BotDefaultFireRate);
	char model[128]; hBotData[client].GetString(BotDataModel, model, sizeof(model), NULL_STRING);
	
	hp = LevelIntMultipleCalc(hp, hBotData[client].GetFloat(BotDataLevelHpBonus, BotDefaultBonusHp));
	ap = LevelIntMultipleCalc(ap, hBotData[client].GetFloat(BotDataLevelApBonus, BotDefaultBonusAp));
	ms = LevelFloatAddCalc(ms, hBotData[client].GetFloat(BotDataLevelMsBonus, BotDefaultBonusMs));
	exp = LevelIntMultipleCalc(exp, hBotData[client].GetFloat(BotDataLevelExpBonus, BotDefaultBonusExp));
	cash = LevelIntMultipleCalc(cash, hBotData[client].GetFloat(BotDataLevelCashBonus, BotDefaultBonusCash));
	fireRate = LevelFloatMultipleCalc(fireRate, hBotData[client].GetFloat(BotDataLevelFireRateBonus, BotDefaultBonusFireRate) * -1);

	hBotData[client].SetFloat(BotDataRealFireRate, fireRate);
	hBotData[client].SetNum(BotDataRealHp, hp);
	hBotData[client].SetNum(BotDataRealAp, ap);
	hBotData[client].SetNum(BotDataRealExp, exp);
	hBotData[client].SetNum(BotDataRealCash, cash);
	hBotData[client].SetFloat(BotDataRealMs, ms);
	
	// 색상 설정.
	if (hBotData[client].JumpToKey(BotDataColorKv, false))
	{
		int r, g, b, a;
		r = hBotData[client].GetNum(BotDataColorRed, 0);
		g = hBotData[client].GetNum(BotDataColorGreen, 0);
		b = hBotData[client].GetNum(BotDataColorBlue, 0);
		a = hBotData[client].GetNum(BotDataColorAlpha, 255);
		
		SetEntityRenderColor(client, r, g, b, a);
		hBotData[client].Rewind();
	}

	// 모델 설정
	if (!StrEqual(model, NULL_STRING))
	{
		char modelPath[128];
		
		CreateModelPath(modelPath, sizeof(modelPath), model);
		
		if (FileExists(modelPath))
			SetEntityModel(client, modelPath);
		else
			LogError("[Error] \"%s\" Bot has undefined model path!", clientName);
	}
	
	SetEntProp(client, Prop_Send, "m_iHealth", hp)
	SetClientArmor(client, ap, hBotData[client].GetNum(BotDataArmorType, BotDefaultArmorType));
	AddClientMovespeed(client, ms);
	
	char tagBuffer[16];
	hBotData[client].GetString(BotDataClanTag, tagBuffer, sizeof(tagBuffer), "");
	CS_SetClientClanTag(client, tagBuffer);
	CS_SetClientContributionScore(client, exp); 
	CS_SetClientAssists(client, cash);
	
	RemoveClientWeapons(client);

	hBotData[client].ExportToFile("debug/botprofiledebug.txt");
	BotGiveWeapon(client, hBotData[client]);
		
	hBotData[client].Rewind();
}

void BotGiveWeapon(int client, KeyValues hData)
{
	char numBuf[3];
	char weaponClass[ClassBufferLength];

	if (hData.JumpToKey(BotDataLevelWeapons, false))
	{
		for(int i = iGameLevel; i >= 1; i--)
		{
			IntToString(i, numBuf, sizeof(numBuf));
			hData.GetString(numBuf, weaponClass, sizeof(weaponClass), NULL_STRING);
						
			if (!StrEqual(weaponClass, NULL_STRING))
			{
				GivePlayerItem(client, weaponClass);
				FakeClientCommand(client, "use %s", weaponClass);
				hData.Rewind();
				
				hData.SetString(BotDataUseWeapon, weaponClass);
			}
		}
		
		hData.Rewind();
	}
}

void CreateBot(char[] name, int botTeam)
{
	char buffer[NameBufferLength];
	
	if (botTeam == CS_TEAM_T)
		Format(buffer, NameBufferLength, "bot_add_t \"%s\"", name);
	else if (botTeam == CS_TEAM_CT)
		Format(buffer, NameBufferLength, "bot_add_ct \"%s\"", name);
	else
	{
		LogError("Bad Bot Team.");
		return;
	}
	
	ServerCommand(buffer);
}

void SpawnNormalBots()
{
	char commandFormat[64];
	char runCommand[64];
	
	if (hMapData.GetNum(MapDataEnemyTeam) == CS_TEAM_CT)
		commandFormat = "bot_add_ct ";
	else
		commandFormat = "bot_add_t ";
		
	StrCat(commandFormat, sizeof(commandFormat), BotNameFormat);
			
	for (int i = 0; i < DefaultBotAmount; i++)
	{
		Format(runCommand, sizeof(runCommand), commandFormat, i + 1);
		ServerCommand(runCommand);
	}
}

stock void CreateBotTeamDataPath(char[] buffer, int length, char[] fileName)
{
	Format(buffer, length, BotTeamDataPath, fileName);
}

stock int GetBotMaxHealth(int client)
{
	return hBotData[client].GetNum(BotDataRealHp);
}

stock bool IsNamedBot(int client)
{
	return hBotData[client].GetNum(BotDataNamed, false) ? true : false;
}

stock bool IsGunBot(int client)
{
	return hBotData[client].GetNum(BotDataGunBot, false) ? true : false;
}

stock void GetBotUniqueID(int client, char[] buffer, int length)
{
	hBotData[client].GetString(BotDataUniqueID, buffer, length, NULL_STRING);
}