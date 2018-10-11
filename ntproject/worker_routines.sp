public void NTProject_WorkersRotuineInit()
{
	CreateTimer(0.5, Worker_PlayerHudDrawRoutine, NULL_ARG, TIMER_REPEAT);
	CreateTimer(2.0, Worker_ServerMaxplayerSetter, NULL_ARG, TIMER_REPEAT);
}

public Action Worker_PlayerHudDrawRoutine(Handle worker)
{
	for (int client = 1; client < MAXPLAYERS; client++)
	{
		if (hPlayerData[client] != INVALID_HANDLE && IsClientInGame(client) && !IsFakeClient(client))
		{
			int hudColor[4] = { 255, 255, 255, 255 };
			int level = GetClientLevel(client);
			int exp = GetClientExp(client)
			int nextExp = GetClientNextExp(client);
			int stetPoint = GetClientStetPoint(client);
			int skillPoint = GetClientSkillPoint(client);

			SetHudTextParamsEx(-1.0, 0.07, 2.0, hudColor, hudColor, 0, 1.0, 0.1, 0.1);
			ShowHudText(client, 0, "Level.%d　|　%d/%d Exp\n\n%d Stet Point\n%d Skill Point", level, exp, nextExp, stetPoint, skillPoint);
		}
	}
	
	return Plugin_Continue;
}

public Action Worker_ResetPlayerAttackDamage(Handle timer, int client)
{
	hPlayerTempData[client].SetNum(PlayerTempDataDamageLog, 0);
}

public Action Worker_ServerMaxplayerSetter(Handle timer)
{
	ServerCommand("sv_visiblemaxplayers %d", MaxUserCount + iBotCount);
	ServerCommand("sm_reserved_slots %d", MaxPlayersCount - MaxUserCount - iBotCount);
	
	return Plugin_Continue;
}