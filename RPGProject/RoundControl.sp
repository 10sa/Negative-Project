methodmap RoundControl __nullable__ {
	
	public RoundControl()
	{
		HookEvent("round_start", RoundStart);
		HookEvent("round_end", RoundEnd);
		HookEvent("round_freeze_end", RoundEndFreeze);
		
		return view_as<RoundControl>(EMPTY_INSTANCE);
	}
};

RoundControl roundControl;

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsWarmup())
	{
		int gameLevel = manager.GetGameLevel();
		int round = manager.GetGameRound();
		
		PrintToChatAll(" \x04[Game Level] \x01Lv. %d", gameLevel);
		PrintToChatAll(" \x04[Game Round] \x01%d Round", round);
		// PrintToChatAll(" \x04[Game Objective] \x01%s", mapObject);
		
		manager.SetRoundStatus(RoundStatus_Freeze);
	}
	else
		manager.SetRoundStatus(RoundStatus_Warmup);
}

public Action RoundEndFreeze(Event event, const char[] name, bool dontBroadcast)
{
	manager.SetRoundStatus(RoundStatus_Run);
}
	
public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	int friendlyTeam = manager.RunFunction("GetFriendlyTeamRegion");
	int gameLevel = manager.GetGameLevel();

	if (winner == friendlyTeam)
	{
		PrintToChatAll(" \x04[Round Win] \x01Game Level : \x04Lv. %d -> Lv. %d", gameLevel, gameLevel + 1);
		manager.AddGameLevel();
	}
	else
	{
		if (gameLevel == MinimunGameLevel)
			PrintToChatAll(" \x02[Round Lose] \x01Game Level : \x04Lv. %d", gameLevel);
		else
			PrintToChatAll(" \x02[Round Lose] \x01Game Level : \x04Lv. %d -> Lv. %d", gameLevel, gameLevel - 1);
			
		manager.AddGameLevel(-1);
	}
	
	if (!IsWarmup())
		manager.AddGameRound();
}