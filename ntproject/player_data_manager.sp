// 여기 포워드들의 client 값은 절대로 fakeclient 일수 없음에 유의.

public void NTProject_PlayerDataManagerInit()
{	
	hExpTable = CreateKeyValuesEx("game_data/exp_table.txt", "exp_table");
	hPlayerDataTemplate = CreateKeyValuesEx("game_data/player_data_template.txt", "player_data_template");
}

public void PlayerDataControl_BotDeath(int client, int killer)
{
	char attackerName[NameBufferLength];
	char section[32];
	hBotData[client].GetSectionName(section, sizeof(section));
	
	int botHp = hBotData[client].GetNum("iRealHp", BotDefaultHp);
	int botExp = hBotData[client].GetNum("iRealExp", BotDefaultExp);
	int botCash = hBotData[client].GetNum("iRealCash", BotDefaultCash);

	for(int i = 0; i < MAXPLAYERS; i++)
	{
		hBotData[client].JumpToKey("kDamage");
		
		if (IsValidClient(i) && !IsFakeClient(i) && !IsWarmup())
		{
			GetClientName(i, attackerName, sizeof(attackerName));
			if (hBotData[client].JumpToKey(attackerName))
			{
				int damage = hBotData[client].GetNum("iDamage", 0);
				float damagePercent = damage / (botHp * 100.0);
				
				int gainExp = RoundFloat(botExp * damagePercent * 100);
				int gainCash = RoundFloat(botCash * damagePercent * 100);

				if (gainExp > 0 || gainCash > 0)
				{
					PlayerDataManager_GiveExp(i, gainExp);
					PlayerDataManager_GiveCash(i, gainCash);
					
					if (i == killer)
					{	
						if(gainExp > 0 && gainCash > 0)
							PrintToChat(i, " \x04[Kill Reward] \x01적을 사살하여 %d 만큼의 경험치와 %d 만큼의 %s 을(를) 획득하였습니다.", gainExp, gainCash, CashName);
						else if (gainExp > 0)
							PrintToChat(i, " \x04[Kill Reward] \x01적을 사살하여 %d 만큼의 경험치를 획득하였습니다.", gainExp);
						else if (gainCash > 0)
							PrintToChat(i, " \x04[Kill Reward] \x01적을 사살하여 %d 만큼의 %s 획득하였습니다.", gainCash, CashName);
					}
					else
					{
						if(gainExp > 0 && gainCash > 0)
							PrintToChat(i, " \x04[Assist Reward] \x01적 사살에 도움을 주어 %d 만큼의 경험치와 %d 만큼의 %s 을(를) 획득하였습니다.", gainExp, gainCash, CashName);
						else if (gainExp > 0)
							PrintToChat(i, " \x04[Assist Reward] \x01적 사살에 도움을 주어 %d 만큼의 경험치를 획득하였습니다.", gainExp);
						else if (gainCash > 0)
							PrintToChat(i, " \x04[Assist Reward] \x01적 사살에 도움을 주어 %d 만큼의 %s 획득하였습니다.", gainCash, CashName);
					}
					
					CS_SetClientContributionScore(i, CS_GetClientContributionScore(i) - 2 + gainExp);
				}
			}
		}
		
		hBotData[client].Rewind();
	}
	
	hBotData[client].Rewind();
}

public void PlayerDataManager_GiveExp(int client, int exp)
{
	int clientExp = GetClientExp(client) + exp;
	int orignalLevel = GetClientLevel(client);
	int clientLevel = orignalLevel;
	int nextExp = GetClientPointNextExp(client, clientLevel);
	
	if (exp > 0)
	{
		while(nextExp <= clientExp)
		{
			clientExp -= nextExp;
			clientLevel++;
			nextExp = GetClientPointNextExp(client, clientLevel);
		}
	}

	SetClientLevel(client, clientLevel);
	SetClientExp(client, clientExp);
	GiveLevelUpReward(client, clientLevel - orignalLevel);
	PlayerDataManager_SavePlayerData(client);
}

public void PlayerDataManager_GiveCash(int client, int cash)
{
	int clientCash = GetClientCash(client);
	SetClientCash(client, clientCash + cash);
	
	PlayerDataManager_SavePlayerData(client);
}

public void PlayerDataManager_OnClientPutInServer(int client)
{
	// 플레이어 데이터에 저장되지 않는 임시용 Kv. //
	hPlayerTempData[client] = CreateKeyValues("tmp_data");
	
	LoadPlayerData(client);
}

public void PlayerDataManager_PlayerDisconnect(int client)
{
	if (hPlayerData[client] != INVALID_HANDLE)
	{
		PlayerDataManager_SavePlayerData(client);
		CloseHandle(hPlayerData[client]);
	}
	
	if (hPlayerTempData[client] != INVALID_HANDLE)
		CloseHandle(hPlayerTempData[client]);
}

public void PlayerDataManager_SavePlayerData(int client)
{
	if (IsClientConnected(client) && !IsFakeClient(client) && hPlayerData[client] != INVALID_HANDLE)
	{
		char buffer[256];
		GetPlayerDataPath(buffer, 256, client);
		hPlayerData[client].Rewind();
		
		if (!hPlayerData[client].ExportToFile(buffer))
			PrintToServer("[ERROR] [%s] Player Data Save Failure !!! [%s]", client, buffer);
	}	
}

void GetPlayerDataPath(char[] buffer, int length, int client)
{
	char accountStr[16];
	GetClientAccountID(accountStr, 16, client);
	
	Format(buffer, length, PlayerDataPath, accountStr);
}

void LoadPlayerData(int client)
{
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		char buffer[256];
		GetPlayerDataPath(buffer, 256, client);
		
		hPlayerData[client] = CreateKeyValues("player_data");
		if (!hPlayerData[client].ImportFromFile(buffer))
			hPlayerData[client].Import(hPlayerDataTemplate);
		
		LogAction(0, client, "[%s] Player Data Loaded.", client);
	}	
}

void GiveLevelUpReward(int client, int level)
{
	if (level > 0)
	{
		hPlayerData[client].SetNum(PlayerDataStetPoint, (LevelUpStetPointAdd * level) + hPlayerData[client].GetNum(PlayerDataStetPoint, 0));
		hPlayerData[client].SetNum(PlayerDataSkillPoint, (LevelUpSkillPointAdd * level) + hPlayerData[client].GetNum(PlayerDataSkillPoint, 0));
	}
}

stock bool ResetPlayerData(int client)
{
	if (hPlayerData[client] != INVALID_HANDLE)
		CloseHandle(hPlayerData[client]);
	
	hPlayerData[client] = CreateKeyValues("player_data");
	hPlayerData[client].Import(hPlayerDataTemplate);
	
	PlayerDataManager_SavePlayerData(client);
}

stock int GetClientLevel(int client)
{
	return hPlayerData[client].GetNum(PlayerDataLevel);
}

stock int GetClientCash(int client)
{
	return hPlayerData[client].GetNum(PlayerDataCash, 0);
}

stock int GetClientExp(int client)
{
	return hPlayerData[client].GetNum(PlayerDataExp);
}

stock int GetClientNextExp(int client)
{
	return GetClientPointNextExp(client, GetClientLevel(client))
}

stock int GetClientPointNextExp(int client, int level)
{
	char numBuf[4];
	int startExp = hExpTable.GetNum(ExpTableStartExp);
	
	for(int i = level; i >= 1; i--)
	{
		IntToString(i, numBuf, sizeof(numBuf));
		float expRate = hExpTable.GetFloat(numBuf, 0.0);
		
		return FloatAddCalc(startExp, expRate, level);
	}
	
	return 0;
}

stock int GetClientStetPoint(int client)
{
	return hPlayerData[client].GetNum(PlayerDataStetPoint, 0);
}

stock void SetClientLevel(int client, int level)
{
	hPlayerData[client].SetNum(PlayerDataLevel, level);
}

stock void SetClientCash(int client, int cash)
{
	hPlayerData[client].SetNum(PlayerDataCash, cash);
}

stock void SetClientExp(int client, int exp)
{
	hPlayerData[client].SetNum(PlayerDataExp, exp);
}