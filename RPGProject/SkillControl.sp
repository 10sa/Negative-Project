
int gLazerSplit;
int gHalo;

methodmap SkillControl __nullable__ {
	public SkillControl() {
		gLazerSplit = PrecacheModel("materials/sprites/laserbeam.vmt");
		gHalo = PrecacheModel("sprites/halo01.vmt");
		
		manager.CreateDataSet(SkillDataSet);
		HookEvent("player_death", SkillControl_PlayerKill);
		HookEvent("player_death", SkillControl_PlayerDeath);
		HookEvent("player_blind", SkillControl_PlayerBlind);
		
		return view_as<SkillControl>(EMPTY_INSTANCE);
	}
	
	public void ClientPutInServer(int client)
	{
		SDKHook(client, SDKHook_OnTakeDamage, SkillControl_PlayerAttack);
	}
	
	public void Import(KeyValues skill, const char[] path)
	{
		KeyValues skills = manager.GetDataSet(SkillDataSet);
		char skillName[128];
		
		skill.GetSectionName(skillName, sizeof(skillName));
		if (!skills.JumpToKey(skillName))
		{
			char skillFunction[256];
			Format(skillFunction, sizeof(skillFunction), "SkillFunction_%s", skillName);
			
			if (GetFunctionByName(INVALID_HANDLE, skillFunction) == INVALID_FUNCTION)
				RPG_LogMessage("Undefined Function! [%s]", skillName);
			else
			{
				skills.JumpToKey(skillName, true);
				skills.Import(skill);
				
				RPG_LogMessage("Skill Load Success! [%s]", skillName);
			}
		}
		else
			RPG_LogMessage("Duplicate Skills Define! [%s / %s]", skillName, path);
		
		skills.Rewind();
	}
	
	public void LoadData()
	{
		DirectoryListing dirList = OpenDirectory("addons/sourcemod/data/rpg/skills");
		
		if (dirList != INVALID_HANDLE)
		{
			char skillName[128];
			while(dirList.GetNext(skillName, sizeof(skillName)))
			{
				if (StrContains(skillName, ".skill", true) != -1)
				{
					char pathBuffer[256];
					KeyValues skill = new KeyValues("temp");
					
					Format(pathBuffer, sizeof(pathBuffer), "addons/sourcemod/data/rpg/skills/%s", skillName);
					skill.ImportFromFile(pathBuffer);
				
					RPG_LogMessage("Load Skill... [%s]", skillName);
					this.Import(skill, pathBuffer)
						
					CloseHandle(skill);
				}
			}
		}
	}
	
	public void RunSkill(Player player, const char[] skillName, KeyValues params)
	{
		char skillFunction[256];
		Format(skillFunction, sizeof(skillFunction), "SkillFunction_%s", skillName);
			
		Call_StartFunction(INVALID_HANDLE, GetFunctionByName(INVALID_HANDLE, skillFunction));
		Call_PushCell(player);
		Call_PushCell(params);
		Call_Finish();
	}
	
	public void GetCalltypeBySkillName(const char[] skillName, char[] calltype, int length)
	{
		KeyValues skills = manager.GetDataSet(SkillDataSet);
		if (skills.JumpToKey(skillName))
		{
			skills.GetString(Skill_Calltype, calltype, length, NULL_STRING);
			skills.Rewind();
		}
	}
	
	public void RunPlayerSkills(Player player, const char[] calltype, KeyValues params)
	{
		if (player.IsValid())
		{
			KeyValues skills = player.GetSkills();
		
			if (skills.GotoFirstSubKey())
			{
				char skillName[128];
				char skillCalltype[128];
				
				do
				{
					skills.GetSectionName(skillName, sizeof(skillName));
					this.GetCalltypeBySkillName(skillName, skillCalltype, sizeof(skillCalltype));

					if (StrEqual(skillCalltype, calltype))
						this.RunSkill(player, skillName, params);
				}
				while (skills.GotoNextKey())
			}
			
			delete skills;
		}
	}
}

SkillControl skillControl;

public Action SkillControl_PlayerAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	Player player = GetPlayer(attacker);
	
	if (player.IsValid())
	{
		KeyValues params = new KeyValues("");
		params.SetNum("victim", victim);
		params.SetNum("attacker", attacker);
		params.SetNum("inflictor", inflictor);
		params.SetFloat("damage", damage);
		params.SetNum("damagetype", damagetype);
		
		skillControl.RunPlayerSkills(GetPlayer(attacker), "player_attack", params);
		
		attacker = params.GetNum("attacker");
		inflictor = params.GetNum("inflictor");
		damage = params.GetFloat("damage");
		damagetype = params.GetNum("damagetype");
		
		delete params;
		return Plugin_Changed;
	}
	else
		return Plugin_Continue;
}

public Action SkillControl_PlayerKill(Event event, const char[] name, bool dontBroadcast)
{
	KeyValues params = new KeyValues("");
	params.SetNum("victim", GetClientOfUserId(event.GetInt("userid")));
	params.SetNum("assister", GetClientOfUserId(event.GetInt("assister")));
	
	skillControl.RunPlayerSkills(GetPlayer(GetClientOfUserId(event.GetInt("attacker"))), "player_kill", params);
	delete params;
}

public Action SkillControl_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	KeyValues params = new KeyValues("");
	params.SetNum("attacker", GetClientOfUserId(event.GetInt("attacker")));
	params.SetNum("assister", GetClientOfUserId(event.GetInt("assister")));
	
	skillControl.RunPlayerSkills(GetPlayer(GetClientOfUserId(event.GetInt("userid"))), "player_death", params);
	delete params;
}

public Action SkillControl_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	skillControl.RunPlayerSkills(GetPlayer(GetClientOfUserId(event.GetInt("userid"))), "player_blind", null);
}

public void SkillFunction_DamagePrefix(Player player, KeyValues params)
{
	params.Rewind();
	KeyValues skill = player.GetSkill("DamagePrefix");
	
	params.SetFloat("damage", skill.GetFloat("fDamage"));
	delete skill;
}

public void SkillFunction_KillExplosion(Player player, KeyValues params)
{
	if (!IsWarmup())
	{
		params.Rewind();
		
		KeyValues skill = player.GetSkill("KillExplosion");
		int damage = skill.GetNum("iDamage", 0);
		int radius = skill.GetNum("iRadius", 0);
		int victim = params.GetNum("victim");
		bool teamKill = skill.GetNum("bTeamKill", false) ? true : false;
	
		if (damage > 0 && radius > 0)
			CreateExplosionTarget(player.GetEntity(), victim, damage, radius, teamKill);
			
		delete skill;
	}
}

public void SkillFunction_KillingSpare(Player player, KeyValues params)
{
	params.Rewind();
	KeyValues skill = player.GetSkill("KillingSpare");

	char clientName[128];
	char skillEffect[64] = "\x02[";
	char formatBuffer[32];
		
	player.GetName(clientName, sizeof(clientName));
		
	if (skill.GotoFirstSubKey(false))
	{
		do
		{
			char sectionName[64];
			skill.GetSectionName(sectionName, sizeof(sectionName));
				
			if (StrEqual(sectionName, "iRegenHp"))
			{
				int regenHp = skill.GetNum(NULL_STRING, 0);
				
				if (regenHp > 0)
				{
					Format(formatBuffer, sizeof(formatBuffer), "\x07+%d Hp", regenHp);
					StrCat(skillEffect, sizeof(skillEffect), formatBuffer);
					player.Health += regenHp;
				}
			}
			else if (StrEqual(sectionName, "fSpeedBonus"))
			{
				float addSpeed = skill.GetFloat(NULL_STRING, 0.0);
				Format(formatBuffer, sizeof(formatBuffer), "\x07 +%.0f％ Speed", addSpeed * 100);
				StrCat(skillEffect, sizeof(skillEffect), formatBuffer);
				player.Movespeed = player.Movespeed * (1.0 + addSpeed);
			}
		}
		while(skill.GotoNextKey(false))
	}
	
	
	if (strlen(skillEffect) < 3)
		skillEffect = NULL_STRING;
	else
		StrCat(skillEffect, sizeof(skillEffect), "\x02]");
			
	PrintToChatAll(" \x02[Killing Spare]\x01 \x08%s\x01 님이 \x02학살\x01 중입니다! %s", clientName, skillEffect);
	delete skill;
}

public void SkillFunction_FlashReflection(Player player, KeyValues params)
{
	float cooltime = player.GetMember("Flashbang_Reflection_Cooltime", 0.0);
	if (GetGameTime() >= cooltime) // 만약 쿨타임이 시간보다 작다면
	{
		char clientName[128];
		player.GetName(clientName, sizeof(clientName));
		
		PrintToChatAll(" \x04[Flash Reflection] \x08%s\x01 가 \x06섬광탄 반사\x01를 사용!", clientName);
		for (int i = 1; i <= MAXPLAYERS; i++)
		{
			Player vicitm = GetPlayer(i);
			if (vicitm.IsValid() && !vicitm.IsSameTeam(player))
			{
				CreateThrowEffectTarget(player.GetEntity(), "flashbang_projectile", vicitm.GetEntity());
				vicitm.SetPropertyFloat("m_flFlashDuration", 5.0);
			}
		}
		
		player.SetPropertyFloat("m_flFlashMaxAlpha", 0.0);
		player.SetPropertyFloat("m_flFlashDuration", 0.0);
		
		player.SetMember("Flashbang_Reflection_Cooltime", GetGameTime() + 1.0);
	}
}

public void SkillFunction_SelfDetonation(Player player, KeyValues params)
{
	if (!IsWarmup())
	{
		KeyValues skill = player.GetSkill("SelfDetonation");	
		float playerPos[3];
		char playerName[128];
		player.GetClientAbsOrigin(playerPos);
		player.GetName(playerName, sizeof(playerName));
		
		PrintToChatAll(" \x04[Self-Detonation]\x02 %s\x01 가 자폭을 시도합니다.", playerName);
		if (skill.JumpToKey("Color"))
		{
			int ringColor[4];
			
			ringColor[0] = skill.GetNum("r", 0);
			ringColor[1] = skill.GetNum("g", 0);
			ringColor[2] = skill.GetNum("b", 0);
			ringColor[3] = skill.GetNum("a", 255);
			
			skill.Rewind();
			
			playerPos[2] -= 60.0;
			TE_SetupBeamRingPoint(playerPos, 0.0, 500.0, gLazerSplit, gHalo, 0, 255, 3.0, 3.0, 0.0, {255, 0, 125, 255}, 2, 0);
			TE_SendToAll();
				
			TE_SetupBeamRingPoint(playerPos, 0.0, 1000.0, gLazerSplit, gHalo, 0, 255, 3.0, 3.0, 0.0, {255, 0, 125, 255}, 2, 0);
			TE_SendToAll();
			playerPos[2] += 60.0;
		}
		
		CreateTimer(skill.GetFloat("fDelay"), SelfDetonationTimer, player);
		delete skill;
	}
}

public Action SelfDetonationTimer(Handle timer, Player player)
{
	KeyValues skill = player.GetSkill("SelfDetonation");
	CreateExplosionTarget(player.GetEntity(), player.GetEntity(), skill.GetNum("iDamage"), skill.GetNum("iRadius"), view_as<bool>(skill.GetNum("bIsTeamKill")));
}