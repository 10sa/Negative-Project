
#define CvarConfigDataSet "Configs_Cvar"

methodmap ConfigControl __nullable__ {

	public ConfigControl()
	{
		KeyValues cvarConfig = manager.CreateDataSet(CvarConfigDataSet);
		cvarConfig.ImportFromFile("addons/sourcemod/data/rpg/configs/cvar_config.cfg");
	}
	
	public void RunCvarConfigs()
	{
		KeyValues configs = manager.GetDataSet(CvarConfigDataSet);
		
		if (configs.GotoFirstSubKey(false))
		{
			char cvarKey[128];
			char cvarValue[128];
			
			do
			{
				configs.GetSectionName(cvarKey, sizeof(cvarKey));
				configs.GetString(NULL_STRING, cvarValue, sizeof(cvarValue));
				
				ConVar cvar = FindConVar(cvarKey);
				if (cvar != INVALID_HANDLE)
				{
					cvar.SetString(cvarValue, true, false);
					RPG_LogMessage("Cvar Config Set. [\"%s\" : \"%s\"]", cvarKey, cvarValue);
				}
				else
					RPG_LogMessage("Undefined Cvar Setting! [\"%s\" : \"%s\"]", cvarKey, cvarValue);
			}
			while(configs.GotoNextKey(false))
		}
	}
	
	public void Run()
	{
		this.RunCvarConfigs();
	}
};

ConfigControl configControl;