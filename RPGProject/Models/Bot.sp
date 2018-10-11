
methodmap Bot < Player {
	
	public Bot(int entity)
	{
		return view_as<Bot>(entity);
	}
	
	public int GetMaxHealth()
	{
		KeyValues profile = this.GetProfile();

		int health = profile.GetNum(BotProfile_Health, 100);
		float healthBonus = profile.GetFloat(BotProfile_HealthBonus, 0.0);
		
		return GetLevelBonusValueInt(health, healthBonus);
	}
	
	public int GetMaxArmor()
	{
		KeyValues profile = this.GetProfile();
		
		int armor = profile.GetNum(BotProfile_Armor, 0);
		float armorBonus = profile.GetFloat(BotProfile_ArmorBonus, 0.0);
		
		return GetLevelBonusValueInt(armor, armorBonus);
	}
	
	public float GetFireRate()
	{
		KeyValues profile = this.GetProfile();
		
		return profile.GetFloat(BotProfile_FireRate, 1.0);
	}
	
	public int GetDropExp()
	{
		KeyValues profile = this.GetProfile();
		
		int exp = profile.GetNum(BotProfile_DropExp, 0);
		float expBonus = profile.GetFloat(BotProfile_DropExpBonus, 0.0);
		
		return GetLevelBonusValueInt(exp, expBonus);
	}
	
	public int GetDropCash()
	{
		KeyValues profile = this.GetProfile();
		
		int cash = profile.GetNum(BotProfile_DropCash, 0);
		float cashBonus = profile.GetFloat(BotProfile_DropCashBonus, 0.0);
		
		return GetLevelBonusValueInt(cash, cashBonus);
	}
	
	public float GetAccuracy()
	{
		KeyValues profile = this.GetProfile();
		
		float accuracy = profile.GetFloat(BotProfile_Accuracy, 1.0);
		float accuracyBonus = profile.GetFloat(BotProfile_AccuracyBonus, 0.0);
		float resultAccuracy = GetLevelBonusValueFloat(accuracy, -accuracyBonus);
		
		if (resultAccuracy < 0.0)
			resultAccuracy = 0.0;
			
		return resultAccuracy;
	}
	
	public void GetColor(int[] color)
	{
		KeyValues profile = this.GetProfile();
		color[0] = 255;
		color[1] = 255;
		color[2] = 255;
			
		if (profile.JumpToKey(BotProfile_Color))
		{
			color[0] = profile.GetNum(BotProfile_ColorR, 255);
			color[1] = profile.GetNum(BotProfile_ColorG, 255);
			color[2] = profile.GetNum(BotProfile_ColorB, 255);
		}
		
		profile.Rewind();
	}
	
	public float GetMovespeed()
	{
		KeyValues profile = this.GetProfile();
		
		float movespeed = profile.GetFloat(BotProfile_Movespeed, 1.0);
		float movespeedBonus = profile.GetFloat(BotProfile_MovespeedBonus, 0.0);
		float resultAccuracy = GetLevelBonusValueFloat(movespeed, movespeedBonus);
		
		if (resultAccuracy < 0.0)
			resultAccuracy = 0.0;
		
		return resultAccuracy;
	}
	
	public bool IsGunbot()
	{
		KeyValues profile = this.GetProfile();
		
		return view_as<bool>(profile.GetNum(BotProfile_IsGunbot, false));
	}
	
	public bool IsBot()
	{
		return IsFakeClient(this.GetEntity());
	}
	
	public bool IsBoss()
	{
		KeyValues profile = this.GetProfile();
		
		return view_as<bool>(profile.GetNum(BotProfile_IsBoss, false));
	}

	public bool IsInfClip()
	{
		KeyValues profile = this.GetProfile();
		
		return view_as<bool>(profile.GetNum(BotProfile_IsInfiClip, false));
	}
	
	public float GetAimbotViewAngle()
	{
		KeyValues profile = this.GetProfile();
		
		if (profile.JumpToKey(BotProfile_AimbotAttribute, false))
		{
			float returnValue = profile.GetFloat(BotProfile_AimbotAngle, 0.0);
			profile.Rewind();
			
			return returnValue;
		}
		else
			return 0.0;
	}
	
	public float GetAimbotReactionTime()
	{
		KeyValues profile = this.GetProfile();
		
		if (profile.JumpToKey(BotProfile_AimbotAttribute, false))
		{
			float returnValue = profile.GetFloat(BotProfile_AimbotReactionTime, 0.0);
			profile.Rewind();
			
			return returnValue;
		}
		else
			return 0.0;
	}
	
	#define BotProfile_DamageLog	"DamageLog"
	// 이 값은 SteamAccountID로 처리할 것.
	
	public void AddDamageLog(int attackerEntity, int damage)
	{
		Player attacker = GetPlayer(attackerEntity);
		int steamID = attacker.GetSteamAccountID();
		
		KeyValues profile = this.GetProfile();
		char accountID[128];
		IntToString(steamID, accountID, sizeof(accountID));
		
		profile.JumpToKey(BotProfile_DamageLog, true);
		int damageLog = profile.GetNum(accountID, 0);
		damageLog += damage;
		profile.SetNum(accountID, damageLog);
		
		profile.Rewind();
	}
	
	public KeyValues GetDamageLog()
	{
		KeyValues damageLog = new KeyValues("Temp");
		KeyValues orignalLog = this.GetProfile();
		orignalLog.JumpToKey(BotProfile_DamageLog, true);
		
		damageLog.Import(orignalLog);
		orignalLog.Rewind();
		
		return damageLog;
	}
	
	public KeyValues GetDamageLogPercent()
	{
		KeyValues damageLog = this.GetDamageLog();
		if (damageLog.GotoFirstSubKey(false))
		{
			do
			{
				int damage = damageLog.GetNum(NULL_STRING, 0);
				int maxHealth = this.GetMaxHealth();
				damageLog.SetFloat(NULL_STRING, (damage / maxHealth) * 100.0);
			}
			while(damageLog.GotoNextKey(true))
		}
		
		damageLog.Rewind();
		return damageLog;
	}
	
	public void ResetDamageLog()
	{
		KeyValues profile = this.GetProfile();
		if (profile.JumpToKey(BotProfile_DamageLog, false))
			profile.DeleteThis();
			
		profile.Rewind();
	}

	public void GetWeapon(char[] buffer, int length)
	{
		KeyValues profile = this.GetProfile();
		
		if (profile.JumpToKey(BotProfile_Weapons, false))
		{
			char numBuf[4];
			char weaponClass[128];
			
			profile.GetString(BotProfile_DefaultWeapon, buffer, length, NULL_STRING); // 기본 무기 Copy
			for(int i = manager.GetGameLevel(); i >= MinimunGameLevel; i--)
			{
				IntToString(i, numBuf, sizeof(numBuf));
				profile.GetString(numBuf, weaponClass, sizeof(weaponClass), NULL_STRING);
				
				if (!StrEqual(weaponClass, NULL_STRING))
				{
					strcopy(buffer, length, weaponClass);
					break;
				}
			}
		}
		else
			strcopy(buffer, length, "weapon_knife"); // Default Weapon
		
		profile.Rewind();
	}
};