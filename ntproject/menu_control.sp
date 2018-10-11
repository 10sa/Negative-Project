
public Menu CreateMainMenu()
{
	Menu menu = CreateMenu(MainMenuHandler);
	
	// 시간나면 StringTable 로 바꿀 것.
	menu.SetTitle("◇ 메뉴");
	menu.AddItem(MenuControlKeyStet, "스텟 (Stet)");
	menu.AddItem(MenuControlKeySkill, "스킬 (Skill)");
	menu.AddItem(MenuControlKeyInventory, "인벤토리 (Inventory)");
	menu.AddItem(MenuControlKeyEquipments, "장비 (Equipment)");
	menu.AddItem(MenuControlKeySettings, "설정 (Settings)");
	menu.AddItem(MenuControlKeyGroup, "서버 그룹 (Server Group)");
	
	menu.ExitButton = true;

	return menu;
}

public void MenuControl_DisplayMainMenu(int client)
{
	CreateMainMenu().Display(client, MENU_TIME_FOREVER);
}

int MainMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char key[32];
			menu.GetItem(choice, key, sizeof(key));
			
			if (StrEqual(key, MenuControlKeyStet))
				StetHandler_DisplayStetMenu(client);
			else if (StrEqual(key, MenuControlKeySkill))
				SkillHandler_DisplaySkillMenu(client);
			else if (StrEqual(key, MenuControlKeyInventory))
				ItemHandler_DisplayInventory(client);
			else if (StrEqual(key, MenuControlKeyEquipments))
				ItemHandler_DisplayEquipmentMenu(client);
			else if (StrEqual(key, MenuControlKeySettings))
				SettingHandler_DisplaySettingMenu(client);
			else if (StrEqual(key, MenuControlKeyGroup))
				ShowMOTDPanel(client, "Server Group", "http://cola-team.com/franug/webshortcuts_f.html?web=http://steamcommunity.com/groups/negativetouhouproject", MOTDPANEL_TYPE_URL);
				
		}
		else if (action == MenuAction_End)
			CloseHandle(menu);
	}
}