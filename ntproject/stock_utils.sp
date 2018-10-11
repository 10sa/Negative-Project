enum ArmorType
{
	ArmorType_Kevlar 			= 0,
	ArmorType_HelmetKevlar 		= 1,
	ArmorType_Assaultsuit		= 2,
	ArmorType_HeavyAssaultsuit	= 3
}

stock float LevelFloatAddCalc(float value, float add)
{
	return value + (add * (iGameLevel - 1));
}

stock int LevelIntMultipleCalc(int value, float mul)
{
	return value + RoundFloat(value * mul * (iGameLevel - 1));
}

stock float LevelFloatMultipleCalc(float value, float mul)
{
	return value + (value * mul * (iGameLevel - 1));
}

stock void DebugMsg(char[] format, any ...)
{
	int length = strlen(format) + 256;
	char[] cFormat = new char[length];
	VFormat(cFormat, length, format, 2);
	
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i) && hPlayerTempData[i] != INVALID_HANDLE && hPlayerTempData[i].GetNum("iDebug", false))
			PrintToConsole(i, cFormat);
	}
}

stock int FloatMulCalc(int value, float mul, int level)
{
	return (value + RoundFloat(value * mul * level));
}

stock int FloatAddCalc(int value, float mul, int level)
{
	return (value + RoundFloat(value * mul)) * level;
}

stock float NumberToPercent(int num)
{
	return num * 0.001;
}

stock void DrawBlankPage(Menu menu, char[] key, char[] text, int drawType, int blackLine = 5)
{
	menu.AddItem(key, text, drawType);
	
	for(int i = 0; i < blackLine; i++)
		menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);
}

stock KeyValues CreateKeyValuesEx(char[] filePath, char[] tableName)
{
	char dataPath[DataPathBufferLength];
	CreateDataPath(dataPath, sizeof(dataPath), filePath);
	
	KeyValues hData = CreateKeyValues(filePath);
	hData.ImportFromFile(dataPath);
	
	return hData;
}

stock void SetClientArmor(int client, int armor, int armorType = 0)
{
	// 아머는 1byte 값이라서 255 이상 넣어봤자 임.
	if (armor > 255)
		armor = 255;
		
	SetEntProp(client, Prop_Send, "m_ArmorValue", armor);
	
	switch(armorType)
	{
		case ArmorType_HelmetKevlar:
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		case ArmorType_Assaultsuit:
			GivePlayerItem(client, "item_assaultsuit");
		case ArmorType_HeavyAssaultsuit:
			GivePlayerItem(client, "item_heavyassaultsuit");
	}
}

stock void SetAimByPosition(int client, float targetPos[3])
{
	float clientPos[3];
	float punchAngle[3];
	float clientToTargetAngle[3];
	
	GetClientEyePosition(client, clientPos);
	MakeVectorFromPoints(clientPos, targetPos, clientToTargetAngle);
	GetVectorAngles(clientToTargetAngle, clientToTargetAngle);
	
	GetEntPropVector(client, Prop_Send, "m_aimPunchAngle", punchAngle);
	punchAngle[2] = 0.0;
	ScaleVector(punchAngle, 2.0);
	SubtractVectors(clientToTargetAngle, punchAngle, clientToTargetAngle);
	
	TeleportEntity(client, NULL_VECTOR, clientToTargetAngle, NULL_VECTOR);
}

stock void SetWeaponClip(int weapon, int clip)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
}

stock void SetWeaponAmmo(int weapon, int ammo)
{
	// SetEntProp(client, Prop_Send, "m_iAmmo", 0, NULL_ARG, ammoType); 필요 없어보임.
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
}

stock void SetTeamName(int team, char[] teamName)
{
	int teamNumber = GetRealTeamID(team);
	char command[128];
	
	Format(command, sizeof(command), "mp_teamname_%d \"\"", teamNumber, teamName);
	ServerCommand(command);
	Format(command, sizeof(command), "mp_teamname_%d %s", teamNumber, teamName);
	ServerCommand(command);
}

stock int GetWeaponClip(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iClip1");
}


stock int GetRealTeamID(int team)
{
	return team == CS_TEAM_CT ? 1 : 2;
}

stock int GetCloserAndSeeableClient(int client, float &distance = 0.0)
{
	int closerClient = 0;
	float lastShortDistance = -1.0
	
	if (IsValidClient(client))
	{
		for(int i = 1; i < MAXPLAYERS; i++)
		{
			if (IsValidClient(i) && i != client && !IsSameTeam(client, i))
			{
				float targetDistance = GetClientToTargetDistance(client, i);
				
				if ((distance <= 0.0 || distance > targetDistance) && IsSeeableTarget(client, i))
				{
					if (lastShortDistance > targetDistance || lastShortDistance == -1.0)
					{
						lastShortDistance = targetDistance;
						closerClient = i;
					}
				}
			}
		}
	}
	
	return closerClient;
}

stock bool IsSeeableTarget(int client, int target)
{
	float targetPos[3] = 0.0;
	float clientPos[3] = 0.0;
	
	GetClientEyePosition(client, clientPos);
	GetClientEyePosition(target, targetPos);
	
	Handle tracer = TR_TraceRayFilterEx(clientPos, targetPos, MASK_SOLID, RayType_EndPoint, StockUtils_TraceCallback, client);
	bool isSeeable = TR_DidHit(tracer) && TR_GetEntityIndex(tracer) == target

	CloseHandle(tracer);	
	if (isSeeable)
		return true;
	else
		return false;
}

// Private Function. //
public bool StockUtils_TraceCallback(int entity, int mask, int client)
{
	// 닿은 부분이 클라이언트여야 하며, 발생지와 타겟이 같지 않으며, 같은 팀이 아닌 경우.
	return IsValidClient(entity) && entity != client && !IsSameTeam(entity, client);
}

stock int GetClientByEvent(Event event)
{
	return GetClientOfUserId(event.GetInt("userid"));
}

stock int GetEntityOwner(int entity)
{
	if (IsValidEdict(entity) && HasEntProp(entity, Prop_Send, "m_hOwner"))
		return GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	else
		return -1;
}

stock int GetClientByName(char[] name)
{
	char buffer[NameBufferLength];
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i))
		{
			GetClientName(i, buffer, sizeof(buffer));
			if (StrEqual(buffer, name))
				return i;
		}
	}
	
	// Search Failure. //
	return -1;
}

stock int GetClientActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock void GetClientActiveWeaponClass(int client, char[] buffer, int length)
{
	int activeWeapon = GetClientActiveWeapon(client);
	if (IsValidEntity(activeWeapon))
		GetWeaponClassEx(activeWeapon, buffer, length);
	else
		strcopy(buffer, length, NULL_STRING);
}

// :(
stock void GetWeaponClassEx(int weapon, char[] buffer, int length)
{
	strcopy(buffer, length, NULL_STRING);
	
	if (IsValidEntity(weapon))
	{
		GetEntityClassname(weapon, buffer, length);
		
		if (StrEqual(buffer, "weapon_m4a1"))
		{
			if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 60)
				strcopy(buffer, length, "weapon_m4a1_silencer");
		}
		else if (StrEqual(buffer, "weapon_degale"))
		{
			if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 64)
				strcopy(buffer, length, "weapon_revolver");
		}
		else if (StrEqual(buffer, "weapon_hkp2000"))
		{
			if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 61)
				strcopy(buffer, length, "weapon_usp_silencer");
		}
		else if (StrEqual(buffer, "weapon_p250"))
		{
			if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 63)
				strcopy(buffer, length, "weapon_cz75a");
		}
	}
}

stock int GetWeaponDefaultAmmo(char[] class)
{
	char buffer[ClassBufferLength];
	Format(buffer, sizeof(buffer), WeaponDataDefaultAmmo, class);
	
	return hWeaponData.GetNum(buffer, -1);
}

stock void GetClientAccountID(char[] buffer, int length, int client)
{
	int accountID;
	
	accountID = GetSteamAccountID(client);
	IntToString(accountID, buffer, length);
}

stock int GetClientObserverTarget(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
}

stock float GetClientToTargetDistance(int client, int target)
{
	float clientPos[3];
	float targetPos[3];
	
	GetClientAbsOrigin(client, clientPos);
	GetClientAbsOrigin(target, targetPos);
	
	return GetVectorDistance(clientPos, targetPos);
}

stock void LookAtHead(int client, int target)
{
	float targetPos[3];
	GetClientEyePosition(target, targetPos);
	targetPos[2] -= 5;
	
	SetAimByPosition(client, targetPos);
}

stock void AddClientMovespeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") + (speed / 100.0)));
}

stock void SetClientMovespeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}

stock float GetClientMovespeed(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
}

stock bool AddClientHealth(int client, int health)
{
	int maxHealth;
	int clientHealth = GetClientHealth(client);
	
	if (IsFakeClient(client))
		maxHealth = GetBotMaxHealth(client);
	else
		maxHealth = GetClientMaxHealth(client);
	
	if (maxHealth > clientHealth)
	{
		int regenHealth = clientHealth + health;
		if (regenHealth > maxHealth)
			regenHealth = maxHealth;
			
		SetEntityHealth(client, regenHealth);
		return true;
	}
	else
		return false;
}

stock void CreateDataPath(char[] buffer, int length, char[] subPath)
{
	Format(buffer, length, DefaultPath, subPath);
}

stock void RemoveClientWeapons(int client, int count = 4)
{
	for(int i = 0; i < count; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		
		while(weapon > 0)
		{
			RemovePlayerItem(client, weapon);
			weapon = GetPlayerWeaponSlot(client, i);
		}
	}
}

stock int GetMaxRound()
{
	ConVar cv = FindConVar("mp_maxrounds");
	int value = cv.IntValue;
	
	CloseHandle(cv);
	return value;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client >= MAXPLAYERS)
		return false;
	
	return IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsAdmin(int client)
{
	return GetUserFlagBits(client) == ADMFLAG_ROOT;
}
stock int IsSameTeam(int client, int target)
{
	return GetClientTeam(client) == GetClientTeam(target) ? true : false;
}

stock bool IsWarmup()
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return true;
	else
		return false;
}

stock bool IsDefusing(int client)
{
	return (GetEntProp(client, Prop_Send, "m_bIsDefusing") % 2 == 1);
}

stock bool IsThrowWeapon(char[] class)
{
	if (StrEqual(class, "weapon_smokegrenade") ||
		StrEqual(class, "weapon_incgrenade") ||
		StrEqual(class, "weapon_molotov") ||
		StrEqual(class, "weapon_tagrenade") ||
		StrEqual(class, "weapon_hegrenade") ||
		StrEqual(class, "weapon_decoy") || 
		StrEqual(class, "weapon_flashbang"))
	{
		return true;
	}
	else
		return false;
}

// Twilight Sparkle's Functions. (http://cafe.naver.com/sourcemulti/58997) - Thanks!
stock bool IsTargetInSightRange(int client, int target, float angle = 90.0, float distance = 0.0, bool heightcheck = true, bool negativeangle = false)
{	
	float clientpos[3];
	float targetpos[3];
	float anglevector[3];
	float targetvector[3];
	float resultangle;
	float resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
		
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle / 2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

stock void PlayerHeal(int client, int target, int &buttons, bool isNotify = true)
{
	int clientHealthShot = GetClientActiveWeapon(client);
	int healthShotAmmo = GetEntProp(clientHealthShot, Prop_Send, "m_iPrimaryReserveAmmoCount");
	
	if (IsValidClient(client) && IsValidClient(target) && healthShotAmmo > 0)
	{
		float distance = GetClientToTargetDistance(client, target);
		if (distance <= HealthTargetRange)
		{
			int clientHealth = GetClientHealth(target);
			int clientMaxHealth = GetClientMaxHealth(target);
			int healAmount = 50;
			
			if (clientHealth < clientMaxHealth)
			{
				AddClientHealth(target, healAmount);
				
				if (healthShotAmmo > 1)
					SetEntProp(clientHealthShot, Prop_Send, "m_iPrimaryReserveAmmoCount", healthShotAmmo - 1);
				else
				{
					ClientCommand(client, "lastinv");
					RemovePlayerItem(client, clientHealthShot);
					RemoveEdict(clientHealthShot);
				}
				
				if (isNotify)
				{
					if (client != target)
					{
						char nameBuffer[NameBufferLength];
						GetClientName(target, nameBuffer, sizeof(nameBuffer));
						PrintToChat(client, " \x04[Heal] \x08%s\x01 유저를 \x04%d Hp\x01 만큼 치료하였습니다.", nameBuffer, healAmount);
						
						GetClientName(client, nameBuffer, sizeof(nameBuffer));
						PrintToChat(target, " \x04[Heal] \x08%s\x01 유저가 당신을 치료하여 주었습니다. \x04[%dHp +]", nameBuffer, healAmount);
					}
				}
				
				EmitSoundToAllAnyEx("items/healthshot_prepare_01.wav", .soundType = "sfx", .entity = client);
				EmitSoundToAllAnyEx("items/healthshot_success_01.wav", .soundType = "sfx", .entity = target);
			}
		}
	}
	
	buttons &= ~IN_ATTACK;
	buttons &= ~IN_ATTACK2;
}

stock void PlayerFreeze(int client, float time, bool notifySound = false)
{
	if (IsClientInGame(client))
	{
		int clientOrignalColor[4];
		DataPack data;
		CreateDataTimer(time, UnFreezeTimer, data, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		
		GetEntityRenderColorEx(client, clientOrignalColor);
		data.WriteCell(client);
		for (int i = 0; i < 4; i++)
			data.WriteCell(clientOrignalColor[i]);
		
		SetEntityRenderColor(client, 50, 50, 225, 100);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
}

public Action UnFreezeTimer(Handle timer, DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	
	if (IsClientInGame(client))
	{
		int clientOrignalColor[4];
		for (int i = 0; i < 4; i++)
			clientOrignalColor[i] = data.ReadCell();
			
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColorEx(client, clientOrignalColor);
	}
		
	return Plugin_Stop;
}

stock float GetRandomFloatValue(int chance, float minValue, float maxValue, bool isNegative = false, float rate = 2.0, float round = 10.0)
{
	float result = 0.0;
	
	if (minValue != 0.0 && maxValue != 0.0)
	{
		result = minValue;
		int count = RoundFloat((maxValue - minValue) / rate);
		float maxAddValue = (maxValue - minValue) / count;

		for (int i = 0; i < count; i++)
		{
			int randomValue = GetRandomInt(0, 100);
			if (randomValue <= chance)
				result += maxAddValue;
			else
				result += GetRandomFloat(0.0, maxAddValue);
				
			SetRandomSeed(randomValue);
		}
		
		result *= round;
		result = RoundFloat(result) / round;
	}
	
	return result;
}

stock bool GetEntityRenderColorEx(int entity, int color[4])
{
	if (IsValidEntity(entity))
	{
		int r, g, b, a;
		GetEntityRenderColor(entity, r, g, b, a);
		
		color[0] = r;
		color[1] = g;
		color[2] = b;
		color[3] = a;
		
		return true;
	}
	else
		return false;
}

stock bool SetEntityRenderColorEx(int entity, int color[4])
{
	if (IsValidEntity(entity))
	{
		SetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);
		return true;
	}
	else
		return false;
}

stock void EmitSoundToAllAnyEx(char[] filePath, int channel = SNDCHAN_STATIC, char[] soundType = "music", int entity = SOUND_FROM_PLAYER, int level = SNDLEVEL_NONE)
{
	int soundFlag = SND_NOFLAGS;
	if (IsValidSound(filePath))
	{
		if (StrEqual(soundType, "music"))
		{
			soundFlag = SND_CHANGEVOL;
			strcopy(sPlayingMusic, sizeof(sPlayingMusic), filePath);
		}
				
		for(int i = 1; i < MAXPLAYERS; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && hPlayerData[i] != INVALID_HANDLE)
			{
				float volume = GetSettingValueFloat(i, "fVolume", 1.0);
				
				if (!IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_iObserverMode") == 4)
					volume *= 2.0;
			
				if (volume > 1.0) volume = 1.0;

				EmitSoundToClientAny(i, filePath, entity, channel, level, soundFlag, volume);
			}
		}
	}
}

stock void EmitSoundToClientAnyEx(int client, char[] filePath, int channel = SNDCHAN_STATIC, char[] soundType = "music", int entity = SOUND_FROM_PLAYER, int level = SNDLEVEL_NONE)
{
	if (IsValidSound(filePath) && IsClientInGame(client))
	{
		float volume = GetSettingValueFloat(client, "fVolume", 0.75);
		int soundFlag = SND_NOFLAGS;
			
		if (StrEqual(soundType, "music"))
			soundFlag = SND_CHANGEVOL;
				
		if (!IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
				volume *= 2.0;
				
		if (volume > 1.0) volume = 1.0;
		
		EmitSoundToClientAny(client, filePath, entity, channel, level, soundFlag, volume);
	}
}

stock bool IsValidSound(char[] filePath, bool dontAttachPrefix = false)
{
	char buffer[256];
	if (!dontAttachPrefix)
		Format(buffer, sizeof(buffer), "sound/%s", filePath);
	else
		strcopy(buffer, sizeof(buffer), filePath);
		
	return FileExists(buffer);
}

stock void StopSoundToAll(char[] filePath, int channel = SNDCHAN_STATIC, char[] soundType = "music")
{
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i))
			StopSoundAny(i, channel, filePath);
	}
	strcopy(sPlayingMusic, sizeof(sPlayingMusic), NULL_STRING);
}


// ZP 에서 가져옴.
stock CreateExplosion(int client, float pos[3], int damage, int radius, bool teamkill = false, char[] classname = "env_explosion", char[] sound = "none")
{
	int ent = CreateEntityByName("env_explosion");
	if (teamkill)
		SetConVarInt(FindConVar("mp_friendlyfire"), 1, true, true);

	SetEntProp(ent, Prop_Data, "m_iMagnitude", damage);
	SetEntProp(ent, Prop_Data, "m_iRadiusOverride", radius);
	DispatchKeyValue(ent, "classname", classname);

	DispatchSpawn(ent);
	ActivateEntity(ent);

	if (!teamkill) SetEntProp(ent, Prop_Data, "m_iTeamNum", GetClientTeam(client));
	else SetEntProp(ent, Prop_Data, "m_iTeamNum", 1);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client); // Owner of explosion
	pos[2] += 30.0;
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent, "explode");
	AcceptEntityInput(ent, "kill");
	
	if (!StrEqual(sound, "none"))
		EmitSoundToAllAny(sound, SOUND_FROM_WORLD, SNDCHAN_STATIC, .origin=pos);
	
	if (teamkill)
		SetConVarInt(FindConVar("mp_friendlyfire"), 0, true, true);
}

stock void CreateExplosionTarget(int client, int target, int damage, int radius, bool teamkill = false, char[] classname = "env_explosion", char[] sound = "none")
{
	float pos[3];
	GetClientAbsOrigin(target, pos);
	
	CreateExplosion(client, pos, damage, radius, teamkill, classname, sound)
}

stock void CreateThrowEffect(int client, char[] class, float pos[3])
{
	int entity = CreateEntityByName(class); 
	if (entity != INVALID_ENT_REFERENCE)
	{
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Send, "m_hThrower", client);
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.5);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(entity, Prop_Send, "m_bIsLive", 1);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		
		DispatchSpawn(entity);
		ActivateEntity(entity); 
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);
		SetEntProp(entity, Prop_Data, "m_takedamage", 2);
		SetEntProp(entity, Prop_Data, "m_iHealth", 1);
		SDKHooks_TakeDamage(entity, 0, 0, 100.0);
	}
}

stock void CreateThrowEffectTarget(int client, char[] class, int target)
{
	float pos[3];
	GetClientEyePosition(target, pos);
	
	CreateThrowEffect(client, class, pos);
}
	
stock void RemoveConVarFlag(char[] name, int flags)
{
	ConVar cvar = null;
	if ((cvar = FindConVar(name)) != null)
		cvar.Flags &= ~flags;
}