
public void NTProject_DataLoaderInit()
{
	DataLoader_BotModelsLoad();
}

public void DataLoader_BotModelsLoad()
{
	LoadKvModels(hBotProfile);
}

public void DataLoader_LoadPrecacheSounds()
{
	LogAction(0, -1, "[Notify] Precache sound loading...")
	KeyValues soundKv = CreateKeyValuesEx("game_data/precache_sounds.txt", "precache_sounds");
	if (soundKv != INVALID_HANDLE && soundKv.GotoFirstSubKey(false))
	{
		char pathBuffer[128];
		do
		{
			soundKv.GetSectionName(pathBuffer, sizeof(pathBuffer));
			PrecacheSoundAny(pathBuffer);
			
			LogAction(0, -1, "[Notify] %s Sound precached.", pathBuffer);
		}
		while (soundKv.GotoNextKey(false))
	}
	
	CloseHandle(soundKv);
}

void LoadKvModels(KeyValues kv)
{
	kv.GotoFirstSubKey();
	do
	{
		char pathBuffer[128];
		
		kv.GetString(BotDataModel, pathBuffer, sizeof(pathBuffer), NULL_STRING);
		LoadModels(pathBuffer);
		
		KeyValues tempKv = CreateKeyValues("tmp_kv");
		tempKv.Import(kv);
		
		if (tempKv.JumpToKey(BotDataRamdomModels))
		{	
			if (tempKv.GotoFirstSubKey(false))
			{
				do
				{
					tempKv.GetString(NULL_STRING, pathBuffer, sizeof(pathBuffer));
					LoadModels(pathBuffer);
				}
				while (tempKv.GotoNextKey(false))
			}
		}
		
		CloseHandle(tempKv);
	}
	while(kv.GotoNextKey())
	
	kv.Rewind();
}

public void DataLoader_OnMapStartPost()
{
	char teamInfoPath[128];
	char clientName[64];
	char teamName[64];
	
	GetActiveTeamPath(MapDataEnemyTeamInfo, teamName, sizeof(teamName));
	GetActiveTeamDataPath(MapDataEnemyTeamInfo, teamInfoPath, sizeof(teamInfoPath));
	KeyValues teamKv = CreateKeyValuesEx(teamInfoPath, "tmp");

	teamKv.GotoFirstSubKey();
	do
	{
		teamKv.GetSectionName(clientName, sizeof(clientName));
		
		if (hBotProfile.JumpToKey(clientName, false))
		{
			char uniqueID[64];
			char pathBuffer[128];
			char modelPath[128];
			
			hBotProfile.GetString(BotDataUniqueID, uniqueID, sizeof(uniqueID));
			hBotProfile.GetString(BotDataModel, modelPath, sizeof(modelPath), NULL_STRING);
			
			if (hBotProfile.JumpToKey(BotDataExtendSound, false))
			{
				hBotProfile.GotoFirstSubKey(false);
				do
				{
					hBotProfile.GetString(NULL_STRING, pathBuffer, sizeof(pathBuffer), NULL_STRING);
					LoadBotSoundFile(uniqueID, pathBuffer);
				}
				while(hBotProfile.GotoNextKey(false))
			}
			
			hBotProfile.Rewind();
			
			LoadBotSoundFile(uniqueID, "flashbang_blind.mp3", false);
		}
	}
	while(teamKv.GotoNextKey())
	
	CloseHandle(teamKv);
	LoadKvModels(hBotProfile);
	LoadSoundTrack(teamName);
	DataLoader_LoadPrecacheSounds();
}

char soundtrackItems[][] = {
	"warmup",
	"mapchange"
}

stock void LoadSoundTrack(char[] teamName)
{
	KeyValues tempKv = CreateKeyValues("sound_track");
	char pathBuffer[128];
	char numBuf[3];
	
	LogAction(0, -1, "[Notify] Loading %s's Soundtrack", teamName);
	
	for (int i = 0; i < sizeof(soundtrackItems); i++)
	{
		Format(pathBuffer, sizeof(pathBuffer), "bot_team_soundtrack/%s/%s/%s.mp3", SoundTrackVersion, teamName, soundtrackItems[i]);
		if (!SoundFileLoad(pathBuffer, true))
		{
			Format(pathBuffer, sizeof(pathBuffer), "bot_team_soundtrack/%s/%s/%s.mp3", SoundTrackVersion, DefaultKey, soundtrackItems[i]);
			SoundFileLoad(pathBuffer);
		}
		
		CreateSoundPath(pathBuffer, sizeof(pathBuffer), pathBuffer);
		tempKv.SetString(soundtrackItems[i], pathBuffer);
	}
	
	for (int i = 1; i <= 9; i++)
	{
		char fileName[64];
		
		Format(fileName, sizeof(fileName), "round_%d.mp3", i);
		Format(pathBuffer, sizeof(pathBuffer), "bot_team_soundtrack/%s/%s/%s", SoundTrackVersion, teamName, fileName);
		if (!SoundFileLoad(pathBuffer, true))
		{
			Format(pathBuffer, sizeof(pathBuffer), "bot_team_soundtrack/%s/%s/%s", SoundTrackVersion, DefaultKey, fileName);
			SoundFileLoad(pathBuffer);
		}
		
		IntToString(i, numBuf, sizeof(numBuf));
		CreateSoundPath(pathBuffer, sizeof(pathBuffer), pathBuffer);
		tempKv.SetString(numBuf, pathBuffer);
	}
	
	hMapData.JumpToKey(MapDataMapSounds, true);
	hMapData.Import(tempKv);
	hMapData.Rewind();
	
	CloseHandle(tempKv);
}

stock void LoadBotSoundFile(char[] uniqueID, char[] fileName, bool notDefineError = false)
{
	char pathBuffer[128];
	
	CreateBotSoundDataPath(pathBuffer, sizeof(pathBuffer), uniqueID, fileName);
	SoundFileLoad(pathBuffer, notDefineError);
}

stock bool SoundFileLoad(char[] filePath, bool notDefineError = false)
{
	//sound\projectalpha\bot_team_soundtrack\v1\default
	char pathBuffer[128];
	CreateSoundPath(pathBuffer, sizeof(pathBuffer), filePath);
	
	Format(pathBuffer, sizeof(pathBuffer), "sound/%s", pathBuffer);
	LogAction(0, -1, "[Notify] Try sound loading... [%s]", pathBuffer);
	
	if (FileExists(pathBuffer))
	{
		AddFileToDownloadsTable(pathBuffer);
		
		Format(pathBuffer, sizeof(pathBuffer), "projectalpha/%s", filePath);
		PrecacheSoundAny(pathBuffer);
		
		LogAction(0, -1, "[Notify] Sound Load Success. [%s]", filePath);
		
		return true;
	}
	else if (!notDefineError)
		LogError("[Error] Undefined sound path! [%s]", filePath);
	else
		LogAction(0, -1, "[Notify] \"%s\" Not Found.", filePath);
		
	return false;
}

char itemFormatList[][] = { ".dx80.vtx", ".dx90.vtx", ".phy", ".sw.vtx", ".vvd" };

stock void LoadModels(char[] path)
{
	if (!StrEqual(path, NULL_STRING))
	{
		char pathBuffer[128];
		char extraPath[128];
		
		CreateModelPath(pathBuffer, sizeof(pathBuffer), path);
		LogAction(0, -1, "[Notify] Try model loading... %s", path);
		
		if (FileExists(pathBuffer))
		{
			AddFileToDownloadsTable(pathBuffer);
			PrecacheModel(pathBuffer);

			LogAction(0, -1, "[Notify] Model load success. [%s]", pathBuffer);
		}
		else
			LogError("[Error] Undefined model path! [%s]", pathBuffer);
			
		for (int i = 0; i < sizeof(itemFormatList); i++)
		{
			strcopy(extraPath, sizeof(extraPath), pathBuffer);
			ReplaceString(extraPath, sizeof(extraPath), ".mdl", itemFormatList[i], false);
			
			LogAction(0, -1, "[Notify] Model subfile searching... [%s]", extraPath);
			
			if (FileExists(extraPath))
			{
				AddFileToDownloadsTable(extraPath);
				PrecacheModel(extraPath);

				LogAction(0, -1, "[Notify] Model sub file load success. [%s]", extraPath);
			}
			else
				LogAction(0, -1, "[Notify] \"%s\" Not Found.", extraPath);
		}
	}
}

stock void CreateModelPath(char[] buffer, int length, char[] filePath)
{
	Format(buffer, length, "models/%s", filePath);
}

stock void CreateSoundPath(char[] buffer, int length, char[] filePath)
{
	Format(buffer, length, "projectalpha/%s", filePath);
}

stock void CreateBotSoundDataPath(char[] buffer, int length, char[] uniqueID, char[] fileName)
{
	Format(buffer, length, "bot_sound/%s/%s/%s", SoundTrackVersion, uniqueID, fileName);
}

stock void CreateBotSoundPath(char[] buffer, int length, char[] uniqueID, char[] fileName)
{
	Format(buffer, length, "projectalpha/bot_sound/%s/%s/%s", SoundTrackVersion, uniqueID, fileName);
}