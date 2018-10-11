public void NTProject_SettingHandlerInit()
{
	hSettingsData = CreateKeyValuesEx("game_data/settings_list.txt", "setting_list");
}

public void SettingHandler_DisplaySettingMenu(int client)
{
	CreateSettingMenu().Display(client, MENU_TIME_FOREVER);
}

Menu CreateSettingMenu()
{
	Menu settingMenu = CreateMenu(SettingMenuHandler);
	settingMenu.SetTitle("◈ 설정");
	
	if (hSettingsData.GotoFirstSubKey())
	{
		do
		{
			char menuName[64];
			hSettingsData.GetSectionName(menuName, sizeof(menuName));
			settingMenu.AddItem(menuName, menuName);
		}
		while (hSettingsData.GotoNextKey())
		
		hSettingsData.Rewind();
	}
	
	
	settingMenu.ExitBackButton = true;
	return settingMenu;
}

Menu CreateSettingSubMenu(int client, char[] key)
{
	Menu subMenu = CreateMenu(SettingSubMenuHandler);
	subMenu.SetTitle(key);
	
	if (hSettingsData.JumpToKey(key, false))
	{
		char buffer[128];
		int varType = hSettingsData.GetNum(SettingDataVarType, -1);
		
		if (varType == ITypeInt)
		{
			// 작업 예정
		}
		else if (varType == ITypeFloat)
		{
			hSettingsData.GetString(SettingDataSettingKey, buffer, sizeof(buffer), NULL_STRING);
			
			float defaultValue = hSettingsData.GetFloat(SettingDefault, 0.0);
			float playerValue = GetSettingValueFloat(client, buffer, defaultValue);

			Format(buffer, sizeof(buffer), "현재 설정 값 : %.2f", playerValue);
			subMenu.AddItem("", buffer, ITEMDRAW_DISABLED);
		}
		
		if (hSettingsData.JumpToKey(SettingDataMenuItem, false))
		{
			char menuItem[64];
			hSettingsData.GotoFirstSubKey(false);
			do
			{
				hSettingsData.GetSectionName(menuItem, sizeof(menuItem));
				subMenu.AddItem(menuItem, menuItem);
			}
			while(hSettingsData.GotoNextKey(false))
		}
		
		hSettingsData.Rewind();
	}
	
	subMenu.ExitBackButton = true;
	return subMenu;
}

int SettingMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char settingName[64];
			menu.GetItem(choice, settingName, sizeof(settingName));
			
			CreateSettingSubMenu(client, settingName).Display(client, MENU_TIME_FOREVER);
		}
		else if (action == MenuAction_Cancel)
		{
			if (choice == MenuCancel_ExitBack)
				MenuControl_DisplayMainMenu(client);
		}
		else if (action == MenuAction_End)
			CloseHandle(menu);
	}
	else
		CloseHandle(menu);
}

int SettingSubMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			// TO DO: 메소드로 분리할 것.
			char settingName[64];
			menu.GetTitle(settingName, sizeof(settingName));
			
			if (hSettingsData.JumpToKey(settingName, false))
			{
				char settingKey[64];
				char refresh[64];
				int varType;
				
				hSettingsData.GetString(SettingDataSettingKey, settingKey, sizeof(settingKey), NULL_STRING);
				hSettingsData.GetString(SettingRefresh, refresh, sizeof(refresh), NULL_STRING);
				varType = hSettingsData.GetNum(SettingDataVarType, -1);

				if (hSettingsData.JumpToKey(SettingDataMenuItem, false) && hPlayerData[client].JumpToKey(PlayerDataSettings, true))
				{
					char itemName[64];
					menu.GetItem(choice, itemName, sizeof(itemName));
					
					if (varType == ITypeInt)
						hPlayerData[client].SetNum(settingKey, hSettingsData.GetNum(itemName, -1));
					else if (varType == ITypeFloat)
						hPlayerData[client].SetFloat(settingKey, hSettingsData.GetFloat(itemName, 0.0));
					else if (varType == ITypeString)
					{
						char data[128];
						hPlayerData[client].JumpToKey(PlayerDataSettings, true);
						hSettingsData.GetString(itemName, data, sizeof(data), NULL_STRING);
						hPlayerData[client].SetString(settingKey, data);
					}
							
					hPlayerData[client].Rewind();
					PlayerDataManager_SavePlayerData(client);
				}
				
				if (StrEqual(refresh, "refresh_music"))
					EmitSoundToClientAnyEx(client, sPlayingMusic);
				
				hSettingsData.Rewind();
			}
			// END //
			
			CreateSettingSubMenu(client, settingName).Display(client, MENU_TIME_FOREVER);
		}
		else if (action == MenuAction_Cancel)
		{
			if (choice == MenuCancel_ExitBack)
				MenuControl_DisplayMainMenu(client);
		}
		else if (action == MenuAction_End)
			CloseHandle(menu);
	}
	else
		CloseHandle(menu);
}

stock float GetSettingValueFloat(int client, char[] settingKey, float defaultValue = 0.0)
{
	if (hPlayerData[client] != INVALID_HANDLE && hPlayerData[client].JumpToKey(PlayerDataSettings, false))
	{
		float value = hPlayerData[client].GetFloat(settingKey, defaultValue);
		hPlayerData[client].Rewind();
		
		return value;
	}
	else
		return defaultValue
}