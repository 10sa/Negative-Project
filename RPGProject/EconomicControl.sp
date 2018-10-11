
methodmap EconomicControl __nullable__{
	
	public EconomicControl() {
		HookEventEx("round_end", Economic_RoundEnd, EventHookMode_Post);
		HookEventEx("round_start", Economic_RoundStart, EventHookMode_Pre);
		HookEventEx("player_death", EconomicControl_PlayerKill, EventHookMode_Post);
	}
}

EconomicControl economicControl;

public Action Economic_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	winner = winner == 2 ? CS_TEAM_T : CS_TEAM_CT;
	
	int friendlyTeam = manager.RunFunction("GetFriendlyTeamRegion");
	
	int rewardMoney = 2000;
	if (winner == friendlyTeam)
		rewardMoney = 3000;
	
	for (int i = 1; i <= MAXPLAYERS; i++) 
	{
		Player player = GetPlayer(i);
		if (player.IsValid() && !player.IsBot())
			player.SetMember("iMoney", rewardMoney);
	}
}

public Action Economic_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		Player player = GetPlayer(i);
		if (player.IsValid() && !player.IsBot())
			player.Money += player.GetMember("iMoney");
	}
}

public Action EconomicControl_PlayerKill(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsWarmup())
	{
		Player attacker = GetPlayer(GetClientOfUserId(event.GetInt("attacker")));
		Player assister = GetPlayer(GetClientOfUserId(event.GetInt("assister")));

		if (attacker.IsValid() && !attacker.IsBot()) 
			attacker.Money += 500;
			
		if (assister.IsValid() && !assister.IsBot())
			assister.Money += 250;
	}
}