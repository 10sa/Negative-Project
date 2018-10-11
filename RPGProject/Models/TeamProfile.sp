#define MaxTeamProfiles 64

int TeamProfileCount = 0;
KeyValues TeamProfileData[MaxTeamProfiles]; // 이 배열은 마지막 요소가 아닌 이상은 변경할 수 없음.

#define TeamProfile_IsSelectable "bIsSelectable" // TeamCycler에 의해서 선택될수 있는지에 대한 값
#define TeamProfile_TeamType	"bIsEnemy" // 팀 타입에 대한 값
#define TeamProfile_EnemyTeam	"sFriendlyTeam" // 아군 팀 봇 강제 설정
#define TeamProfile_SpawnDefaultBots "bSpawnDefaultBots" // 기본 봇을 소환하는지?

char profileReservedKeywords[][] = {
	TeamProfile_IsSelectable,
	TeamProfile_TeamType,
	TeamProfile_EnemyTeam,
	TeamProfile_SpawnDefaultBots
};

methodmap TeamProfile __nullable__ {
	// Constructor 
	public TeamProfile(KeyValues teamProfile)
	{
		if (TeamProfileCount < MaxTeamProfiles)
		{
			TeamProfileData[TeamProfileCount] = teamProfile;
			TeamProfileCount++;
			
			return view_as<TeamProfile>(TeamProfileCount - 1);
		}
		else
			return view_as<TeamProfile>(INVALID_INDEX);
	}
	
	public KeyValues GetData()
	{
		return TeamProfileData[this];
	}
	
	// Desc
	// TeamProfile를 해제함.
	public void Dispose()
	{
		if (view_as<int>(this) == TeamProfileCount - 1)
		{
			CloseHandle(TeamProfileData[this]);
			TeamProfileCount--;
		}
		else
			RPG_LogMessage("[Error] Try Delete Defined Profiles!");
	}
	
	// Desc
	// TeamProfile에 정의된 팀 이름을 가져옴.
	public void GetTeamName(char[] buffer, int length)
	{
		KeyValues data = this.GetData();
		data.GetSectionName(buffer, length);
	}
	
	// Desc
	// TeamCycler에 의하여 선택될 수 있는지에 대한 여부를 가져옴.
	public bool IsSelectable()
	{
		return view_as<bool>(TeamProfileData[this].GetNum(TeamProfile_IsSelectable, true));
	}
	
	public bool SpawnDefaultBots()
	{
		return view_as<bool>(TeamProfileData[this].GetNum(TeamProfile_SpawnDefaultBots, true));
	}
	
	// 이 팀에 정의된 아군 팀을 가져옴. (적군 팀에만 해당됨)
	public void GetFriendlyTeam(char[] buffer, int length)
	{
		KeyValues data = this.GetData();
		data.GetString(TeamProfile_EnemyTeam, buffer, length, NULL_STRING);
	}
	
	public bool GetTeamType()
	{
		return view_as<bool>(this.GetData().GetNum(TeamProfile_TeamType, TEAM_ENEMY));
	}
	
	// Private
	public bool IsKeyword(const char[] keyword)
	{
		for(int i = 0; i < sizeof(profileReservedKeywords); i++)
		{
			if (StrEqual(keyword, profileReservedKeywords[i]))
				return true;
		}
		
		return false;
	}

	// Structure
	// "BotName" : "BotProfile"
	public KeyValues GetTeamBots()
	{
		char teamName[128];
		this.GetTeamName(teamName, sizeof(teamName));
		
		KeyValues bots = new KeyValues(teamName);
		bots.Import(this.GetData());
		
		for (int i = 0; i < sizeof(profileReservedKeywords); i++)
		{
			if (bots.JumpToKey(profileReservedKeywords[i], false))
			{
				bots.DeleteThis();
				bots.Rewind();
			}
		}
		
		return bots;
	}
};

stock bool IsExistsTeam(const char[] teamName)
{
	char profileName[128];
	for (int i = 0; i < TeamProfileCount; i++)
	{
		TeamProfile profile = view_as<TeamProfile>(i);
		profile.GetTeamName(profileName, sizeof(profileName));
		if (StrEqual(teamName, profileName))
			return true;
	}
	
	return false;
}

stock int GetTeamByName(const char[] teamName)
{
	char profileName[128];
	for (int i = 0; i < TeamProfileCount; i++)
	{
		TeamProfile profile = view_as<TeamProfile>(i);
		profile.GetTeamName(profileName, sizeof(profileName));
		if (StrEqual(teamName, profileName))
			return i;
	}
	
	return INVALID_INDEX;
}