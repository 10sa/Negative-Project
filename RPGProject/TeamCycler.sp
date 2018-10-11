#include "RPGProject/Models/TeamProfile.sp"

int currentTeamIndex = 0;

methodmap TeamCycler __nullable__ {
	public TeamCycler()
	{
		return view_as<TeamCycler>(EMPTY_INSTANCE);
	}
	
	public void LoadData()
	{
		DirectoryListing dirList = OpenDirectory("addons/sourcemod/data/rpg/team_profile");
		if (dirList != INVALID_HANDLE)
		{
			char profileName[128];
			while(dirList.GetNext(profileName, sizeof(profileName)))
			{
				if (StrContains(profileName, ".kv", true) != -1)
				{
					char pathBuffer[256];
					char teamName[128];
					KeyValues profile = new KeyValues("temp");
					
					Format(pathBuffer, sizeof(pathBuffer), "addons/sourcemod/data/rpg/team_profile/%s", profileName);
					profile.ImportFromFile(pathBuffer);
					profile.GetSectionName(teamName, sizeof(teamName));
				
					RPG_LogMessage("Load Team Profile... [%s / %s]", profileName, teamName);
					
					if (!IsExistsTeam(teamName))
					{
						TeamProfile profileInstance = new TeamProfile(profile);
						RPG_LogMessage("Load Success. [%s / %s] / Index : %d", profileName, teamName, profileInstance);
					}
					else
						RPG_LogMessage("Already Defined Team! [%s / %s]", profileName, teamName);
				}
			}
		}
	}

	public void CreateTeamCycle()
	{
		manager.DeleteDataSet(TeamDataSet);
		ArrayList teamList = new ArrayList(TeamProfileCount);
		KeyValues teamCycle = manager.CreateDataSet(TeamDataSet);
		
		for (int i = 0; i < TeamProfileCount; i++)
		{
			TeamProfile profile = view_as<TeamProfile>(i);
			if (profile.IsSelectable() && profile.GetTeamType() == TEAM_ENEMY)
				teamList.Push(i);
		}
		
		SortADTArray(teamList, Sort_Random, Sort_Integer);
		
		char numBuf[4];
		for (int i = 0; i < teamList.Length; i++)
		{
			IntToString(i, numBuf, sizeof(numBuf));
			teamCycle.SetNum(numBuf, teamList.Get(i));
		}
		
		teamCycle.ExportToFile("addons/sourcemod/data/rpg/log/team_cycle.kv"); // For Debuging
		
		RPG_LogMessage("Created Team Cycle.")
	}
};

TeamCycler teamCycler;

// Params
// DataPack []
public KeyValues GetEnemyTeamBots(DataPack params)
{
	KeyValues teamCycle = manager.GetDataSet(TeamDataSet);
	char numBuf[4];
		
	if (teamCycle == INVALID_HANDLE)
	{
		teamCycler.CreateTeamCycle();
		teamCycle = manager.GetDataSet(TeamDataSet);
	}
	
	IntToString(currentTeamIndex, numBuf, sizeof(numBuf));
	int teamIndex = teamCycle.GetNum(numBuf, INVALID_INDEX);
	if (teamIndex == INVALID_INDEX)
	{
		teamCycler.CreateTeamCycle();
		currentTeamIndex = 1;
		teamIndex = manager.GetDataSet(TeamDataSet).GetNum("0", INVALID_INDEX);
	}
	else
	{
		currentTeamIndex++;
	}

	TeamProfile profile = view_as<TeamProfile>(teamIndex);
	if (teamIndex != INVALID_INDEX)
		return profile.GetTeamBots()
	else
		return null;
}

// Params
// DataPack []
public KeyValues GetFriendlyTeamBots(DataPack params)
{
	KeyValues teamCycle = manager.GetDataSet(TeamDataSet);
	char numBuf[4];
	
	IntToString(currentTeamIndex - 1, numBuf, sizeof(numBuf));
	int teamIndex = teamCycle.GetNum(numBuf, INVALID_INDEX);
	char friendlyTeamName[128];
	
	TeamProfile enemyTeam = view_as<TeamProfile>(teamIndex);
	enemyTeam.GetFriendlyTeam(friendlyTeamName, sizeof(friendlyTeamName));
	
	if (!StrEqual(friendlyTeamName, NULL_STRING))
	{
		int profileIndex = GetTeamByName(friendlyTeamName);
		if (profileIndex != INVALID_INDEX)
		{
			TeamProfile friendlyTeam = view_as<TeamProfile>(profileIndex);
			if (friendlyTeam.GetTeamType() != TEAM_FRIENDLY)
				RPG_LogMessage("[Warning] Selected Enemy Team is Not Friendly Team Type! [%s]", friendlyTeamName);
				
			return friendlyTeam.GetTeamBots();
		}
	}
	
	return null;
}