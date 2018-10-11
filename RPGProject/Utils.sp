stock void RPG_LogMessage(const char[] format, any ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	LogMessage("[RPG] %s", buffer);
}


stock bool IsReadableAny(DataPack data)
{
	if (data != INVALID_HANDLE)
	{
		if (data.IsReadable(1)) // 1Byte 라도 읽을 수 있다면
			return true;
	}
	
	return false;
}

stock void RemoveWeapons(int client, int count = 4)
{
	for(int i = 0; i < count; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		while (IsValidEntity(weapon) && IsValidEdict(weapon))
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
			
			weapon = GetPlayerWeaponSlot(client, i);
		}	
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

stock int GetCloserAndSeeableClient(int client, float &distance = 0.0, float angle=0.0)
{
	int closerClient = 0;
	float lastShortDistance = -1.0
	
	if (IsValidClient(client))
	{
		for(int i = 1; i <= MAXPLAYERS; i++)
		{
			if (IsValidClient(i) && i != client && !IsSameTeam(client, i))
			{
				float targetDistance = GetClientToTargetDistance(client, i);
				
				if ((distance <= 0.0 || distance > targetDistance) && IsSeeableTarget(client, i) && IsTargetInSightRange(client, i, angle))
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
	
	Handle tracer = TR_TraceRayFilterEx(clientPos, targetPos, MASK_VISIBLE_AND_NPCS, RayType_EndPoint, StockUtils_TraceCallback, client);
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

stock bool IsValidClient(int client)
{
	if (client <= 0 || client >= MAXPLAYERS)
		return false;
	
	return IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock int IsSameTeam(int client, int target)
{
	return GetClientTeam(client) == GetClientTeam(target) ? true : false;
}

stock float GetClientToTargetDistance(int client, int target)
{
	float clientPos[3];
	float targetPos[3];
	
	GetClientAbsOrigin(client, clientPos);
	GetClientAbsOrigin(target, targetPos);
	
	return GetVectorDistance(clientPos, targetPos);
}

stock bool IsDefusing(int client)
{
	return (GetEntProp(client, Prop_Send, "m_bIsDefusing") % 2 == 1);
}

stock bool IsAdmin(int client)
{
	return GetUserFlagBits(client) == ADMFLAG_ROOT;
}

stock int GetWeaponClip(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

stock void SetWeaponClip(int weapon, int clip)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
}

stock bool IsWarmup()
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return true;
	else
		return false;
}

stock void LookAtHead(int client, int target)
{
	float targetPos[3];
	GetClientEyePosition(target, targetPos);
	targetPos[2] -= 5;
	
	SetAimByPosition(client, targetPos);
}

stock int GetEntityOwner(int entity)
{
	if (IsValidEdict(entity) && HasEntProp(entity, Prop_Send, "m_hOwner"))
		return GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	else
		return -1;
}

stock int GetClientObserverTarget(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
}


// ZP 에서 가져옴.
stock CreateExplosion(int client, float pos[3], int damage, int radius, bool teamkill = false, char[] classname = "env_explosion", char[] sound = "none")
{
	Player player = view_as<Player>(client);
	if (teamkill)
		SetConVarInt(FindConVar("mp_friendlyfire"), 1, true, true);
		
	Entity entity = view_as<Entity>(CreateEntityByName("env_explosion"));
	entity.SetDataProperty("m_iMagnitude", damage);
	entity.SetDataProperty("m_iRadiusOverride", radius);

	entity.SetDataProperty("m_iTeamNum", teamkill ? 1 : player.GetClientTeam());
	entity.SetPropertyEnt("m_hOwnerEntity", player.GetEntity());
	entity.DispatchSpawn();
	
	pos[2] -= 30.0;
	entity.TeleportEntity(pos, NULL_VECTOR, NULL_VECTOR);
	pos[2] += 30.0;
	
	entity.AcceptEntityInput("Explode");
	
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