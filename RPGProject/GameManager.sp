StringMap gameData;

// DataSet Define은 여기에 정의할 것
#define TeamDataSet	"Team_Data"
#define MapDataSet	"Map_Data"
#define BotDataSet	"Bot_Data"
#define BotProfileDataSet	"BotProfile_Data"
#define WeaponDataSet	"Weapon_Data"
#define SkillDataSet	"Skill_Data"

#define GameLevel "iGameLevel"
#define GameRound "iGameRound"
#define RoundStatus	"iRoundStatus"

methodmap GameManager __nullable__ {
	
	public any GetGameData(const char[] key, bool &isSuccess = false)
	{
		any value;
		isSuccess = gameData.GetValue(key, value);
		
		return value;
	}
	
	// 값은 음수가 될수 있음
	public void AddGameLevel(int level = 1)
	{
		int gameLevel;
		if (!gameData.GetValue(GameLevel, gameLevel))
			gameLevel = 1;

		if (MinimunGameLevel > gameLevel + level) // gameLevel + level이 1보다 작다면
			gameData.SetValue(GameLevel, 1);
		else
			gameData.SetValue(GameLevel, gameLevel + level);
	}
	
	public void SetGameLevel(int level)
	{
		if (MinimunGameLevel > level)
			gameData.SetValue(GameLevel, 0);
		else
			gameData.SetValue(GameLevel, level);
	}
	
	public int GetGameLevel()
	{
		int gameLevel;
		if (gameData.GetValue(GameLevel, gameLevel))
			return gameLevel;
		else
			return MinimunGameLevel;
	}
	
	public void AddGameRound()
	{
		int gameRound;
		if (gameData.GetValue(GameRound, gameRound))
			gameData.SetValue(GameRound, gameRound + 1);
		else
			gameData.SetValue(GameRound, 1);
	}
	
	public void ResetGameRound()
	{
		gameData.SetValue(GameRound, 1);
	}
	
	public int GetGameRound()
	{
		int gameRound;
		if (gameData.GetValue(GameRound, gameRound))
			return gameRound;
		else
			return -1;
	}
	
	public void SetRoundStatus(int status)
	{
		gameData.SetValue(RoundStatus, status);
	}
	
	public int GetRoundStatus()
	{
		int roundStatus;
		if (gameData.GetValue(RoundStatus, roundStatus))
			return roundStatus;
		else
			return RoundStatus_Unknown;
	}
	
	// Structure
	// 관리되지 않는 빈 KeyValues.
	public KeyValues CreateDataSet(const char[] name)
	{
		KeyValues dataSet = new KeyValues(name);
		
		RPG_LogMessage("Created %s DataSet.", name);
		if (gameData.SetValue(name, dataSet, false)) // 이미 정의된 경우
			return dataSet;
		else
			return null;
	}
	
	// Structure
	// 관리되지 않는 KeyValues.
	public KeyValues GetDataSet(const char[] name)
	{
		KeyValues dataSet = this.GetGameData(name);
		
		return dataSet;
	}
	
	public void DeleteDataSet(const char[] name)
	{
		KeyValues dataSet;
		if (gameData.GetValue(name, dataSet)) // 삭제할 키가 있는지 탐색
		{
			gameData.Remove(name);
			CloseHandle(dataSet);
		}
	}
	
	// 안쓸거 같은데 나중에도 안쓰면 그냥 지울것
	// No Arguments, No Returns Function Run.
	public bool RunAction(const char[] action)
	{
		Function actionHandle = GetFunctionByName(INVALID_HANDLE, action);
		if (actionHandle != INVALID_FUNCTION)
		{
			Call_StartFunction(INVALID_HANDLE, actionHandle);
			if (Call_Finish() == SP_ERROR_NONE)
				return true;
		}
		
		return false;
	}
	
	// 호출 뒤 DataPack는 자동으로 close 됨.
	public any RunFunction(const char[] functionName, bool &isSuccess = false, DataPack params = null)
	{
		Function functionHandle = GetFunctionByName(INVALID_HANDLE, functionName);
		any returnValue = 0;
		
		if (params != null)
			params.Reset();
			
		if (functionHandle != INVALID_FUNCTION)
		{
			Call_StartFunction(INVALID_HANDLE, functionHandle)
			Call_PushCell(params);
			if (Call_Finish(returnValue) == SP_ERROR_NONE)
				isSuccess = true;
		}
		
		if (params != null)
			CloseHandle(params);
		
		return returnValue;
	}
	
	public GameManager()
	{
		gameData = new StringMap();
		return view_as<GameManager>(EMPTY_INSTANCE);
	}
};

GameManager manager;

stock int GetLevelBonusValueInt(int orignal, float bonus)
{
	return (orignal + RoundToFloor(((orignal * bonus) * (manager.GetGameLevel() - MinimunGameLevel))));
}

stock float GetLevelBonusValueFloat(float orignal, float bonus)
{
	return (orignal + ((orignal * bonus) * (manager.GetGameLevel() - MinimunGameLevel)));
}