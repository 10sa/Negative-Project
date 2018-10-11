public void NTProject_BotSkillHandlerInit()
{
	hBotSkillData = CreateKeyValuesEx("game_data/bot_skill_list.txt", "bot_skill_list");
	hBotSkillData.SetString(SkillDataFunctionFormat, BotSkillFunction);
	hBotSkillData.SetString(SkillDataNotifyPrefix, SkillNotifyBotPrefix);
	
	LoadSkillKeyValues(hBotSkillData);
}

public void BotSkillHandler_PlayerDeath(int vicitm, int attacker, int assister)
{
	DataPack data = CreateDataPack();
	data.WriteCell(vicitm);
	data.WriteCell(attacker);

	CallPlayerSkills(attacker, hBotData[attacker], BotSkillDataCallType_PlayerKill, data);
}

public void BotSkillHandler_PlayerSpawn(int client)
{
	DataPack data = CreateDataPack();
	data.WriteCell(client);
	
	CallPlayerSkills(client, hBotData[client], SkillDataCalltype_Spawn, data);
}

public void BotSkillHandler_PlayerAttack(int vicitm, int attacker, float &damage)
{
	DataPack data = CreateDataPack();
	data.WriteCell(vicitm);
	data.WriteCell(attacker);
	
	CallPlayerSkills(attacker, hBotData[attacker], SkillDataCalltype_Attack, data, damage);
}

public void BotSkillHandler_BlindFlash(int client)
{
	DataPack data = CreateDataPack();
	data.WriteCell(client);
	
	CallPlayerSkills(client, hBotData[client], SkillDataCalltype_FlashBlind, data);
}

public void BotSkillFunction_Rampage(DataPack data, int skillLevel, any &extraData)
{
	if (!IsWarmup())
	{
		int vicitm = data.ReadCell();
		int attacker = data.ReadCell();
		
		KeyValues attackerSkillKv = GetBotSkillKv(attacker, "Rampage");
		char clientName[NameBufferLength];
		char skillEffect[64] = "\x02[";
		char formatBuffer[32];
		
		GetClientName(attacker, clientName, sizeof(clientName));
		
		attackerSkillKv.GotoFirstSubKey(false);
		do
		{
			char sectionName[64];
			attackerSkillKv.GetSectionName(sectionName, sizeof(sectionName));
			
			if (StrEqual(sectionName, "iRegenHp"))
			{
				int regenHp = attackerSkillKv.GetNum(NULL_STRING, 0);
				
				if (regenHp > 0)
				{
					Format(formatBuffer, sizeof(formatBuffer), "\x07+%d Hp", regenHp);
					StrCat(skillEffect, sizeof(skillEffect), formatBuffer);
					SetEntityHealth(attacker, GetClientHealth(attacker) + regenHp);
				}
			}
			else if (StrEqual(sectionName, "fAddSpeed"))
			{
				float addSpeed = attackerSkillKv.GetFloat(NULL_STRING, 0.0);
				
				Format(formatBuffer, sizeof(formatBuffer), "\x07 +%.0f％ Speed", addSpeed);
				StrCat(skillEffect, sizeof(skillEffect), formatBuffer);
				AddClientMovespeed(attacker, addSpeed);
			}
		}
		while(attackerSkillKv.GotoNextKey(false))
		
		if (strlen(skillEffect) < 3)
			skillEffect = NULL_STRING;
		else
			StrCat(skillEffect, sizeof(skillEffect), "\x02]");
			
		PrintToChatAll(" \x02[Killing]\x01 \x08%s\x01 님이 \x02학살\x01 중입니다! %s", clientName, skillEffect);
		CloseHandle(attackerSkillKv);
	}
}

public void BotSkillFunction_HealAura(DataPack data, int skillLevel, any &extraData)
{
	if (!IsWarmup())
	{
		int client = data.ReadCell();
		
		KeyValues clientSkillKv = GetBotSkillKv(client, "HealAura");
		float delay = clientSkillKv.GetFloat("fRunDelay", 5.0);
		
		DataPack timerData;
		CreateDataTimer(delay, PlayerHealAura, timerData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
		timerData.WriteCell(client);
		timerData.WriteCell(clientSkillKv.GetNum("iRegenHp", 5));
		timerData.WriteCell(clientSkillKv.GetFloat("fRegenDistance", 500.0));
		timerData.WriteCell(clientSkillKv.GetNum("bIsSeeable", false));
		
		CloseHandle(clientSkillKv);
	}
}

public void BotSkillFunction_FlashReflection(DataPack data, int skillLevel, any &extraData)
{
	int client = data.ReadCell();
	char clientName[128];
	GetClientName(client, clientName, sizeof(clientName));
	
	PrintToChatAll(" \x04[Flash Reflection] \x08%s\x01 가 \x06섬광탄 반사\x01를 사용!", clientName);
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidClient(i) && !IsSameTeam(client, i))
		{
			CreateThrowEffectTarget(client, "flashbang_projectile", i);
			SetEntPropFloat(i, Prop_Send, "m_flFlashDuration", 5.0);
		}
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
}

public void BotSkillFunction_KillExplosion(DataPack data, int skillLevel, any &extraData)
{
	if (!IsWarmup())
	{
		int vicitm = data.ReadCell();
		int attacker = data.ReadCell();
		
		KeyValues clientSkillKv = GetBotSkillKv(attacker, "KillExplosion");
		int damage = clientSkillKv.GetNum("iDamage", 0);
		int radius = clientSkillKv.GetNum("iRadius", 0);
		bool teamKill = clientSkillKv.GetNum("bTeamKill", false) ? true : false;
	
		if (damage > 0 && radius > 0)
			CreateExplosionTarget(attacker, vicitm, damage, radius, teamKill);
			
		CloseHandle(clientSkillKv);
	}
}

public void BotSkillFunction_DamagePrefix(DataPack data, int skillLevel, float &damage)
{
	data.ReadCell();
	int client = data.ReadCell();
	
	KeyValues clientSkillKv = GetBotSkillKv(client, "DamagePrefix");
	damage = clientSkillKv.GetFloat("fDamage", damage);
	
	CloseHandle(clientSkillKv);
}

public void BotSkillFunction_FreezeExplosion(DataPack data, int skillLevel, float &extraData)
{
	if (!IsWarmup())
	{
		int vicitm = data.ReadCell();
		int attacker = data.ReadCell();
		KeyValues clientSkillKv = GetBotSkillKv(attacker, "FreezeExplosion");
		
		float vicitmPos[3];
		float aroundClientPos[3];
		float distance = clientSkillKv.GetFloat("fDistance", 100.0);
		float time = clientSkillKv.GetFloat("fFreezeTime", 1.0);
		
		GetClientAbsOrigin(vicitm, vicitmPos);
		for (int i = 1; i < MAXPLAYERS; i++)
		{
			if (IsValidClient(i) && i != attacker)
			{
				GetClientAbsOrigin(i, aroundClientPos);
				
				if (GetVectorDistance(vicitmPos, aroundClientPos) <= distance)
					PlayerFreeze(i, time);
			}
		}
	}
}

public Action PlayerHealAura(Handle timer, Handle data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	
	if (IsValidClient(client))
	{
		int regenHp = ReadPackCell(data);
		float distance = ReadPackCell(data);
		bool isSeeable = ReadPackCell(data);
		
		for (int i = 1; i < MAXPLAYERS; i++)
		{
			if (IsValidClient(i) && GetClientToTargetDistance(client, i) <= distance && IsSameTeam(client, i))
			{
				if (isSeeable)
				{
					if (IsSeeableTarget(client, i))
						AddClientHealth(i, regenHp);
				}
				else
					AddClientHealth(i, regenHp);
			}
		}
		
		return Plugin_Continue;
	}
	else
		return Plugin_Stop;
}

stock KeyValues GetBotSkillKv(int client, char[] skillName)
{
	KeyValues kv = CreateKeyValues(skillName);
	
	if (hBotData[client].JumpToKey(PlayerDataSkillKv, false) && hBotData[client].JumpToKey(skillName, false))
		kv.Import(hBotData[client]);
	
	hBotData[client].Rewind();
	return kv;
}