#define MaximumKeepGameLevel 3 // 재시작 시 3레벨 이상일 수 없음.

#define EnemyTeam "EmenyTeam"
#define FriendlyTeam "FriendlyTeam"

// Params
// DataPack[]
public int GetEnemyTeamRegion(DataPack params)
{
	KeyValues mapData = manager.GetDataSet(MapDataSet);
	return mapData.GetNum(EnemyTeam);
}

// Params
// DataPack[]
public int GetFriendlyTeamRegion(DataPack params)
{
	return GetEnemyTeamRegion(null) == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT;
}

methodmap MapControl __nullable__ {

	public MapControl()
	{
		manager.CreateDataSet(MapDataSet);
		return view_as<MapControl>(EMPTY_INSTANCE);
	}
	
	public void SetMapTeam() // 이름 바꿔볼 것
	{
		char mapName[64];
		KeyValues mapData = manager.GetDataSet(MapDataSet);
		
		GetCurrentMap(mapName, sizeof(mapName));
		if (StrContains(mapName, "cs_", false) != -1)
		{
			mapData.SetNum(EnemyTeam, CS_TEAM_T);
			mapData.SetNum(FriendlyTeam, CS_TEAM_CT);
		}
		else
		{
			mapData.SetNum(EnemyTeam, CS_TEAM_CT);
			mapData.SetNum(FriendlyTeam, CS_TEAM_T);
		}
	}
	
	public void SpawnTeamBots(KeyValues bots, int teamType)
	{
		char teamName[128];
		char botName[128];
		char botProfile[128];
		
		bots.GetSectionName(teamName, sizeof(teamName));
		bots.GotoFirstSubKey(false);
		do
		{
			bots.GetSectionName(botName, sizeof(botProfile));
			bots.GetString(NULL_STRING, botProfile, sizeof(botProfile));
			
			DataPack params = new DataPack();
			params.WriteString(botName);
			params.WriteString(botProfile);
			params.WriteCell(teamType); // 아군 봇 스폰시킬땐 변경해야 됨
			
			manager.RunFunction("CreateBot", NULL_ARG, params);
		}
		while(bots.GotoNextKey(false))
		
		bots.Rewind();
	}
	
	public void CreateTeams()
	{
		bool isSuccess;
		KeyValues enemyTeamProfile = manager.RunFunction("GetEnemyTeamBots", isSuccess); // manager 에서 GetEnemyTeam 메소드를 구현하고 호출할 것.
		char teamName[128];
		
		if (isSuccess)
		{
			this.SpawnTeamBots(enemyTeamProfile, GetEnemyTeamRegion(null));
			enemyTeamProfile.GetSectionName(teamName, sizeof(teamName));
			ServerCommand("mp_teamname_%d \"%s\"", (GetEnemyTeamRegion(null) == CS_TEAM_CT ? 1 : 2), teamName);
			RPG_LogMessage("Enemy Team Loaded. [%s]", teamName);
		}
		
		KeyValues friendlyTeamProfile = manager.RunFunction("GetFriendlyTeamBots", isSuccess);
		if (isSuccess && friendlyTeamProfile != null)
		{
			this.SpawnTeamBots(friendlyTeamProfile, GetFriendlyTeamRegion(null));
			friendlyTeamProfile.GetSectionName(teamName, sizeof(teamName));
			RPG_LogMessage("Friendly Team Loaded. [%s]", teamName);
		}
		
		ServerCommand("mp_teamname_%d \"%s\"", (GetEnemyTeamRegion(null) == CS_TEAM_CT ? 2 : 1), NegativeProject);
	}
	
	public void OnMapStart()
	{
		ServerCommand("bot_kick"); // 필요 없는 봇들 제거
		
		// 게임 레벨 재설정
		if (MaximumKeepGameLevel < manager.GetGameLevel())
			manager.SetGameLevel(MaximumKeepGameLevel);
		
		this.SetMapTeam();
		this.CreateTeams();
		manager.ResetGameRound();
	}
};

MapControl mapControl;