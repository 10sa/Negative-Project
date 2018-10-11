
public void PlayerControl_PlayerSpawn(int client)
{
	int health = GetPlayerStet(client, PlayerDataAttributeHealth);
	int speed = GetPlayerStet(client, PlayerDataAttributeSpeed);
	health = PlayerDefaultHp + (health * StetAddHealth);
	
	SetEntityHealth(client, health);
	AddClientMovespeed(client, float(speed) * 0.05);
	
	hPlayerTempData[client].SetNum(PlayerTempDataMaxHealth, health);
	
	int healthShot = GivePlayerItem(client, "weapon_healthshot");
	SetEntProp(healthShot, Prop_Send, "m_iPrimaryReserveAmmoCount", 1);
}

public void PlayerControl_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDrop, PlayerControl_WeaponDropBlock);
	SDKHook(client, SDKHook_OnTakeDamage, PlayerControl_OnTakeDamage);
	
	if (!StrEqual(sPlayingMusic, NULL_STRING))		
		EmitSoundToClientAnyEx(client, sPlayingMusic);
}

public Action PlayerControl_WeaponDropBlock(int client, int weapon)
{	
	if (IsValidEntity(weapon))
	{
		char weaponClass[ClassBufferLength];
		GetWeaponClassEx(weapon, weaponClass, sizeof(weaponClass));

		if (StrEqual(weaponClass, "weapon_healthshot"))
			return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action PlayerControl_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	float changeDamage = damage;
	
	if (IsValidClient(attacker) && IsFakeClient(attacker))
		BotSkillHandler_PlayerAttack(victim, attacker, changeDamage);
		
	if (changeDamage != damage)
	{
		damage = changeDamage;
		return Plugin_Changed;
	}
	else
		return Plugin_Continue;
}

public void PlayerControl_OnPlayerRunCmd(int client, int &buttons)
{
	if (IsPlayerAlive(client))
	{
		if (!(buttons & IN_ATTACK2) || (buttons & IN_ATTACK))
		{
			if (IsActivedHealthshot(client))
			{
				int target = GetClientAimTarget(client, true);
				DrawHealthShotTargetInfo(client, target);	
			}
		}
		
		if (buttons & IN_ATTACK)
		{
			if (IsActivedHealthshot(client))
				PlayerHeal(client, client, buttons);
		}

		if (buttons & IN_ATTACK2)
		{
			if (IsActivedHealthshot(client))
			{
				int target = GetClientAimTarget(client, true);
				if (IsValidClient(target) && IsSameTeam(client, target))
					PlayerHeal(client, target, buttons);
			}
		}
	}
	else // 봇은 죽은 상태에서만 제어를 시도할수 있으므로
	{
		if (buttons & IN_USE)
		{
			int remote_bot = GetClientObserverTarget(client);
			if (IsValidClient(remote_bot) && IsFakeClient(remote_bot))
					buttons &= ~IN_USE;
		}
	}
	
	
	if (!StrEqual(sPlayingMusic, NULL_STRING) && iRoundStatus == RoundStatusPlaying)
		EmitSoundToClientAnyEx(client, sPlayingMusic);
}

stock bool IsActivedHealthshot(int client)
{
	char weaponClass[ClassBufferLength];
	GetWeaponClassEx(GetClientActiveWeapon(client), weaponClass, sizeof(weaponClass));
		
	if (StrEqual(weaponClass, "weapon_healthshot"))
		return true;
	else
		return false;
}

stock int GetClientMaxHealth(int client)
{
	if (IsFakeClient(client))
		return GetBotMaxHealth(client);
	else
		return hPlayerTempData[client].GetNum(PlayerTempDataMaxHealth);
}

void DrawHealthShotTargetInfo(int client, int target)
{	
	if (IsValidClient(client) && IsValidClient(target) && IsSameTeam(client, target))
	{
		int targetHealth = GetClientHealth(target);
		int targetMaxHealth = GetClientMaxHealth(target);
		float targetDistance = GetClientToTargetDistance(client, target);
		
		if (targetDistance <= HealthTargetRange * 2.0)
			PrintHintText(client, "<font color='#00FF00' size='20'> [%d/%d] HP", targetHealth, targetMaxHealth);
	}
}