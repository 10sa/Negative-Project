public void NTProject_StetHandlerInit()
{
	
}

public float StetHandler_CalcPlayerDamage(int client, float damage)
{
	if (hPlayerData[client].JumpToKey(PlayerDataAttributeKv, false))
	{
		float power = 1.0;
		power += hPlayerData[client].GetNum(PlayerDataAttributePower, 0) * 0.005;
		
		DebugMsg("Player : %d, Stet Dmg Calc : %f -> %f", client, damage, damage * power);
		damage = damage * power;
		
		hPlayerData[client].Rewind();
	}
	
	return damage;
}

Menu CreateStetMenu(int client)
{
	Menu stetMenu = CreateMenu(StetMenuHandler);
	
	stetMenu.SetTitle("◇ 스텟 > Stet Point : %d", GetClientStetPoint(client));
	
	CreateStetList(stetMenu, client);
	stetMenu.ExitBackButton = true;
	return stetMenu;
}

public void StetHandler_DisplayStetMenu(int client)
{
	CreateStetMenu(client).Display(client, MENU_TIME_FOREVER);
}

public int GetPlayerStet(int client, char[] stetKey)
{
	int value = 0;
	
	if (hPlayerData[client].JumpToKey(PlayerDataAttributeKv, false))
	{
		value = hPlayerData[client].GetNum(stetKey, 0);
		hPlayerData[client].Rewind();
	}
	
	return value;
}

void CreateStetList(Menu menu, int client)
{
	char itemBuffer[256];
	int drawType = GetClientStetPoint(client) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	
	if (hPlayerData[client].JumpToKey(PlayerDataAttributeKv, false))
	{
		Format(itemBuffer, sizeof(itemBuffer), "체력 : %d Hp (+%d Hp ▲)\n - 체력을 영구적으로 향상시킵니다.", (hPlayerData[client].GetNum(PlayerDataAttributeHealth, 0) * StetAddHealth + PlayerDefaultHp), StetAddHealth)
		DrawBlankPage(menu, StetMenuHealth, itemBuffer, drawType, 1);
		
		Format(itemBuffer, sizeof(itemBuffer), "힘 : %.2f ％ (+%.2f ％ ▲)\n - 데미지를 영구적으로 향상시킵니다.", (hPlayerData[client].GetNum(PlayerDataAttributePower, 0) * StetAddPower + PlayerDataDefaultPower), StetAddPower)
		DrawBlankPage(menu, StetMenuPower, itemBuffer, drawType, 1);
		
		Format(itemBuffer, sizeof(itemBuffer), "민첩 : %.2f ％ (+%.2f ％ ▲)\n - 속도를 영구적으로 향상시킵니다.", (hPlayerData[client].GetNum(PlayerDataAttributeSpeed, 0) * StetAddSpeed + PlayerDefaultSpeed), StetAddSpeed)
		DrawBlankPage(menu, StetMenuSpeed, itemBuffer, drawType, 1);
		
		hPlayerData[client].Rewind();
	}
	else
		LogError("[%d] Create Stet Menu Failure!", client);
}

int StetMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char key[32];
			menu.GetItem(choice, key, sizeof(key));
			
			if (StrEqual(key, StetMenuHealth))
				PlayerStetAdd(client, PlayerDataAttributeHealth, 1);
			else if (StrEqual(key, StetMenuPower))
				PlayerStetAdd(client, PlayerDataAttributePower, 1);
			else if (StrEqual(key, StetMenuSpeed))
				PlayerStetAdd(client, PlayerDataAttributeSpeed, 1);
				
			CreateStetMenu(client).Display(client, MENU_TIME_FOREVER);
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

void PlayerStetAdd(int client, char[] stetKey, int addValue)
{
	int stetPoint = GetClientStetPoint(client);
	
	if (hPlayerData[client].JumpToKey(PlayerDataAttributeKv, false) && stetPoint > 0)
	{
		hPlayerData[client].SetNum(stetKey, hPlayerData[client].GetNum(stetKey, 0) + addValue);
		hPlayerData[client].Rewind();
		hPlayerData[client].SetNum(PlayerDataStetPoint, stetPoint - 1);
		
		PlayerDataManager_SavePlayerData(client);
	}
	else
		LogError("[%d] Client Attribute Not Created.", client);
}