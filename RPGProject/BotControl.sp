#define BotProfile_Template	"bot_template"

// Params
// DataPack [string, string, int]
public bool CreateBot(DataPack params)
{
	char command[256];
	char botName[128];
	char botProfile[128];
	int botTeam;
	
	params.ReadString(botName, sizeof(botName));
	params.ReadString(botProfile, sizeof(botProfile));
	botTeam = params.ReadCell();
	
	if (botTeam == CS_TEAM_CT)
		Format(command, sizeof(command), "bot_add_ct \"%s\"", botName);
	else
		Format(command, sizeof(command), "bot_add_t \"%s\"", botName);
		
	// Spawn Bot
	ServerCommand(command);
	KeyValues dataSet = manager.GetDataSet(BotDataSet);
	
	dataSet.SetString(botName, botProfile); // 프로파일 캐싱. (PutIn 됬을 때 Player Member에 저장됨.)
	RPG_LogMessage("\"%s\" is created. [%s]", botName, botProfile);
}

methodmap BotControl __nullable__ {
	
	public void SetScoreboardValue(int client)
	{
		Bot bot = view_as<Bot>(client);
		CS_SetClientContributionScore(client, bot.GetDropExp());
		CS_SetClientAssists(client, bot.GetDropCash());
	}
	
	public KeyValues GetBotProfile(const char[] botName, const char[] profileName)
	{
		KeyValues botTemplate = manager.GetDataSet(TemplateDataSet);
		KeyValues profiles = manager.GetDataSet(BotProfileDataSet);
		KeyValues profile = new KeyValues(botName);
		
		// Default Template Import
		botTemplate.JumpToKey(BotProfile_Template, false); // Template 중 BotProfile Template로 점프 한 뒤에 Import->Rewind
		profile.Import(botTemplate);
		botTemplate.Rewind();
		
		if (profiles.JumpToKey(botName, false))
		{
			profiles.JumpToKey(BotProfile_DefaultProfile, true); // 해당 봇의 기본 Profile Import
			profile.Import(profiles);
			
			profiles.GoBack();
					
			profiles.JumpToKey(profileName, true); // 해당 봇에 지정된 Profile Import
			profile.Import(profiles);
		}
		
		profiles.Rewind(); // 포지션 원래대로
		return profile;
	}
	
	public BotControl()
	{
		manager.CreateDataSet(BotDataSet);
		manager.CreateDataSet(BotProfileDataSet);
		HookEventEx("player_spawn", BotSpawn, EventHookMode_Post);
		HookEventEx("bomb_planted", BotSpawn, EventHookMode_Post);
		HookEventEx("weapon_fire", BotWeaponFire, EventHookMode_Post);
		HookEventEx("player_hurt", BotHurt, EventHookMode_Post);
		HookEventEx("player_death", BotDeath, EventHookMode_Post);
		HookEventEx("player_death", BotKill, EventHookMode_Post);
		
		return view_as<BotControl>(EMPTY_INSTANCE);
	}
	
	public void BotPutInServer(int client)
	{
		char botName[128];
		char botProfile[128];
		
		GetClientName(client, botName, sizeof(botName));
		KeyValues dataSet = manager.GetDataSet(BotDataSet);
		Player player = GetPlayer(client);
		
		dataSet.GetString(botName, botProfile, sizeof(botProfile), BotProfile_DefaultProfile);
		dataSet.DeleteKey(botName); // 캐싱된 BotProfile 삭제
		
		KeyValues profile = this.GetBotProfile(botName, botProfile);
		player.SetMember(BotProfile, profile);
		
		// Bot Hook 걸어야 됨 (Spawn 에 걸면 걸린 만큼 호출되니까 여따 걸어야 됨)
		SDKHook(client, SDKHook_WeaponDrop, BotWeaponDrop);
		SDKHook(client, SDKHook_WeaponCanUse, BotWeaponCanUse);
		SDKHook(client, SDKHook_OnTakeDamage, BotOnTakeDamage);
		SDKHook(client, SDKHook_PostThinkPost, BotThink);
		
		this.SetScoreboardValue(client);
	}

	public bool ImportProifle(KeyValues profile)
	{
		KeyValues botProfiles = manager.GetDataSet(BotProfileDataSet);
		char profileName[128];
		bool returnValue = false;
		
		profile.GetSectionName(profileName, sizeof(profileName));
		if (!botProfiles.JumpToKey(profileName))
		{
			botProfiles.JumpToKey(profileName, true);
			botProfiles.Import(profile);

			returnValue = true;
		}
		
		botProfiles.Rewind();
		return returnValue;
	}
	
	public void LoadData()
	{
		DirectoryListing dirList = OpenDirectory("addons/sourcemod/data/rpg/bot_profile");
		
		if (dirList != INVALID_HANDLE)
		{
			char profileName[128];
			while(dirList.GetNext(profileName, sizeof(profileName)))
			{
				if (StrContains(profileName, ".bp", true) != -1)
				{
					char pathBuffer[256];
					KeyValues profile = new KeyValues("temp");
					
					Format(pathBuffer, sizeof(pathBuffer), "addons/sourcemod/data/rpg/bot_profile/%s", profileName);
					profile.ImportFromFile(pathBuffer);
				
					RPG_LogMessage("Load Bot Profile... [%s]", profileName);
					if (!this.ImportProifle(profile))
						RPG_LogMessage("Duplicate Bot Define! [%s / %s]", profileName, pathBuffer);
					else
						RPG_LogMessage("Load Success! [%s]", profileName);
						
					CloseHandle(profile);
				}
			}
		}
		
		KeyValues templates = manager.GetDataSet(TemplateDataSet);
		templates.JumpToKey(BotProfile_Template, true);
		templates.ImportFromFile("addons/sourcemod/data/rpg/templates/bot.template");
		
		templates.Rewind();
	}

	public Action OnBotBuyCommand(int client, const char[] weaponClass)
	{
		return Plugin_Handled;
	}
	
	public void DoAimbot(int client, int &buttons)
	{
		Bot bot = view_as<Bot>(client);
		
		int closerClient = GetCloserAndSeeableClient(client, NULL_ARG, bot.GetAimbotViewAngle());
		Weapon weapon = new Weapon(bot.GetActiveWeapon().GetEntity());

		if (IsDefusing(client))
			closerClient = GetCloserAndSeeableClient(client, NULL_ARG, 360.0);
			
		if (IsValidClient(closerClient))
		{
			float reaction = bot.GetMember("Bot_Reaction_Wait", 0.0);
			float botReactionTime = bot.GetAimbotReactionTime();							
			if (GetGameTime() >= reaction + botReactionTime)
			{
				LookAtHead(client, closerClient);
				if (weapon.IsValidEntity() && !(buttons & IN_ATTACK) && GetGameTime() >= weapon.NextPrimaryAttack && weapon.Clip > 0)
					buttons |= IN_ATTACK;
			}
			else
				bot.SetMember("Bot_Reaction_Wait", GetGameTime());
		}
		else // 타게팅 실패.
			bot.SetMember("Bot_Reaction_Wait", 0.0);
	}
	
	public void OnBotRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
	{
		Bot bot = view_as<Bot>(client);
		
		if (bot.IsValid() && bot.IsAlive())
		{
			Weapon botWeapon = new Weapon(bot.GetActiveWeapon().GetEntity());
			
			if (botWeapon.IsValidEntity())
				botWeapon.AccuracyPenalty = bot.GetAccuracy();
			
			buttons &= ~IN_SPEED;
			if (bot.IsGunbot())
				this.DoAimbot(client, buttons);
		}
	}
};

BotControl botControl;

public void BotSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsFakeClient(client))
	{
		Bot bot = view_as<Bot>(client);
		SetEntityHealth(bot.GetEntity(), bot.GetMaxHealth());
		
		char botWeapon[128];
		bot.GetWeapon(botWeapon, sizeof(botWeapon));

		RemoveWeapons(client);
		GivePlayerItem(client, botWeapon);
		FakeClientCommand(client, "use %s", botWeapon);
		
		int color[3];
		bot.GetColor(color);
		bot.SetRenderColor(color);
		
		botControl.SetScoreboardValue(client);
	}
}

public void BotPlantBomb(Event event, const char[] name, bool dontBroadcast)
{
	Bot bot = view_as<Bot>(GetClientOfUserId(event.GetInt("userid")));
	if (bot.IsBot())
	{
		char botWeapon[128];
		bot.GetWeapon(botWeapon, sizeof(botWeapon));
		
		FakeClientCommand(bot.GetEntity(), "use %s", botWeapon);
	}
}

public Action BotWeaponCanUse(int client, int weaponEntity)
{
	Bot bot = view_as<Bot>(client);
	Weapon weapon = new Weapon(weaponEntity);
	char weaponClass[128];
	char botWeapon[128];
			
	bot.GetWeapon(botWeapon, sizeof(botWeapon));
	weapon.GetWeaponClass(weaponClass, sizeof(weaponClass));
	
	if (StrEqual(botWeapon, weaponClass) || StrEqual(weaponClass, "weapon_c4") || StrEqual(botWeapon, NULL_STRING) || StrEqual(weaponClass, "weapon_knife"))
		return Plugin_Continue;
	else
		return Plugin_Handled;
}

public Action BotWeaponDrop(int client, int weaponEntity)
{
	char weaponClass[128];
	Weapon weapon = new Weapon(weaponEntity);
	
	if (weapon.IsValidEntity())
	{
		weapon.GetWeaponClass(weaponClass, sizeof(weaponClass));

		if (StrEqual(weaponClass, "weapon_c4"))
			return Plugin_Continue;
		else
			return Plugin_Handled;
	}
	else
		return Plugin_Handled;
}

public Action BotWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	Bot bot = new Bot(GetClientOfUserId(event.GetInt("userid")));
	if (bot.IsBot())
	{
		Weapon weapon = new Weapon(bot.GetActiveWeapon().GetEntity());
		
		if (bot.IsInfClip())
			weapon.Clip = 255;
	}
}

public Action BotDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsFakeClient(client))
	{
		Bot bot = view_as<Bot>(client);
		Player attacker = GetPlayer(GetClientOfUserId(event.GetInt("attacker")));
		
		if (!IsWarmup())
			GiveBotDeathReward(bot, attacker);
		
		char botName[128];
		char attackerName[128];
		
		GetClientName(client, botName, sizeof(botName));
		attacker.GetName(attackerName, sizeof(attackerName));
		bot.ResetDamageLog();
		
		if (bot.IsBoss())
		{
			if (bot.IsGunbot())
				PrintToChatAll(" \x04[G-Boss Kill] \x08%s\x01 님이 \x02%s\x01 건 보스를 처치하였습니다!", attackerName, botName);
			else
				PrintToChatAll(" \x04[Boss Kill] \x08%s\x01 님이 \x02%s\x01 보스를 처치하였습니다!", attackerName, botName);
		}
	}
}

void GiveBotDeathReward(Bot bot, Player attacker)
{
	KeyValues damageLog = bot.GetDamageLogPercent();
	
	int botExp = bot.GetDropExp();
	int botCash = bot.GetDropCash();
	if (damageLog.GotoFirstSubKey(false))
	{
		do
		{
			char steamIDString[128];
			damageLog.GetSectionName(steamIDString, sizeof(steamIDString));
				
			float percent = damageLog.GetFloat(NULL_STRING, 0.0);
			int giveExp = RoundFloat(botExp * (percent / 100.0));
			int giveCash = RoundFloat(botCash * (percent / 100.0));
			int steamID = StringToInt(steamIDString);
			
			Player player = GetPlayerBySteamID(steamID);
			GiveKillReward(player.GetEntity(), giveExp, giveCash, attacker.GetEntity() == player.GetEntity() ? true : false);
		}
		while(damageLog.GotoNextKey(false))
	}
	
	bot.ResetDamageLog();
	CloseHandle(damageLog);
}

public Action BotHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int dmg_health = event.GetInt("dmg_health");
	int hitgroup = event.GetInt("hitgroup");
	
	if (IsFakeClient(victim))
	{
		Bot bot = view_as<Bot>(victim);
			
		if (IsClientInGame(attacker) && !IsFakeClient(attacker))
		{
			DrawDamageLog(victim, attacker, dmg_health, hitgroup);

			if (GetClientHealth(victim) < 0)
				dmg_health += GetClientHealth(victim);

			bot.AddDamageLog(attacker, dmg_health);
		}
	}
}

public Action BotKill(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	
	if (IsFakeClient(attacker))
		RequestFrame(BotResetScoreboard, attacker);

	if (assister > 0 && IsFakeClient(assister))
		RequestFrame(BotResetScoreboard, assister);
}

void BotResetScoreboard(int client)
{
	botControl.SetScoreboardValue(client);
}

public void BotThink(int client)
{
	Player player = GetPlayer(client);
	Weapon weapon = new Weapon(player.GetActiveWeapon().GetEntity());
	if (weapon.IsValidEntity())
	{
		Bot bot = view_as<Bot>(client);
		float fireRate = bot.GetFireRate();
		float nextFire = weapon.NextPrimaryAttack;
			
		nextFire -= GetGameTime();
		nextFire *= fireRate;
		nextFire += GetGameTime();
			
		weapon.NextPrimaryAttack = nextFire;
	}
}

public Action BotOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	if (IsFakeClient(victim))
	{
		Bot bot = view_as<Bot>(victim);
		float changedDamage = damage;
		
		if (victim == attacker || damageType & DMG_FALL)
			changedDamage = 0.0;
		
		if (bot.IsGunbot())
		{
			if (damageType & DMG_BURN || damageType & DMG_BLAST)
				changedDamage = 0.0;
		}
			
		if (changedDamage != damage)
		{
			damage = changedDamage;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}