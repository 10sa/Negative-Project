Menu CreateInventoryMenu(int client)
{
	Menu inventoryMenu = CreateMenu(InventoryMenuHandler);
	
	inventoryMenu.SetTitle("◈ 인벤토리");
	inventoryMenu.ExitBackButton = true;
	CreateClientItemList(client, inventoryMenu);
	
	return inventoryMenu;
}

void CreateClientItemList(int client, Menu menu)
{	
	if (hPlayerData[client].JumpToKey(PlayerDataInventoryKv, false))
	{
		if (hPlayerData[client].GotoFirstSubKey())
		{
			do
			{
				char itemName[64];
				int itemCount = hPlayerData[client].GetNum(ItemDataItemCount, 0);
				hPlayerData[client].GetSectionName(itemName, sizeof(itemName));
				
				// Item Access = itemName -> index (string)
				for (int i = 1; i <= itemCount; i++)
				{
					char numBuf[3];
					IntToString(i, numBuf, sizeof(numBuf));
					menu.AddItem(numBuf, itemName);
				}
			}
			while (hPlayerData[client].GotoNextKey())
		}
		
		hPlayerData[client].Rewind();
	}
	
	if (menu.ItemCount < 1)
		menu.AddItem("", "소지하고 있는 아이템이 없습니다.", ITEMDRAW_DISABLED);
}

int InventoryMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char itemKey[64];
			char itemName[64];
			menu.GetItem(choice, itemKey, sizeof(itemKey), .dispBuf = itemName, .dispBufLen = sizeof(itemName));
			
			int itemIndex = StringToInt(itemKey);
			DisplayItemExtendMenu(client, itemIndex, itemName);
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

Menu CreateEquipmentMenu(int client)
{
	Menu equipmentMenu = CreateMenu(EquipmentMenuHandler);
	
	equipmentMenu.SetTitle("◈ 장비 목록");
	if (hEquipmentSlotData.GotoFirstSubKey(false))
	{
		char slotName[64];
		char slotDisplayName[64];
		char itemClass[64];
		char formatBuffer[64];
		
		do
		{
			int drawType = ITEMDRAW_DEFAULT;
			
			hEquipmentSlotData.GetSectionName(slotName, sizeof(slotName));
			hEquipmentSlotData.GetString(NULL_STRING, slotDisplayName, sizeof(slotDisplayName));
			GetEquipedItemClass(client, slotName, itemClass, sizeof(itemClass));

			if (!StrEqual(itemClass, NULL_STRING))
				Format(formatBuffer, sizeof(formatBuffer), "%s - %s", slotDisplayName, itemClass);
			else
			{
				drawType = ITEMDRAW_DISABLED;
				Format(formatBuffer, sizeof(formatBuffer), "%s - 장착된 아이템이 없습니다.", slotDisplayName);
			}
				
			equipmentMenu.AddItem(slotName, formatBuffer, drawType);
		}
		while(hEquipmentSlotData.GotoNextKey(false))
		
		hEquipmentSlotData.Rewind();
	}
	
	equipmentMenu.ExitBackButton = true;
	return equipmentMenu;
}

int EquipmentMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char slotName[64];
			menu.GetItem(choice, slotName, sizeof(slotName));
			
			UnequipItem(client, slotName);
			ItemHandler_DisplayEquipmentMenu(client);
		}
		else if (action == MenuAction_Cancel)
		{
			if (choice == MenuCancel_ExitBack)
				MenuControl_DisplayMainMenu(client);
		}
		else if (action == MenuAction_End)
			CloseHandle(menu);
	}
}

void ItemHandler_DisplayEquipmentMenu(int client)
{
	CreateEquipmentMenu(client).Display(client, MENU_TIME_FOREVER);
}

Menu CreateItemExtendMenu(int client, int itemIndex, char[] itemName)
{
	KeyValues itemKv = GetItemClass(itemName);
	KeyValues item = GetClientInventoryItemData(client, itemName, itemIndex);
	Menu itemExtendMenu = CreateMenu(ItemExtendMenuHandler);
	char itemDesc[128];
	char numBuf[3];
	
	IntToString(itemIndex, numBuf, sizeof(numBuf));
	GetItemDesc(itemDesc, sizeof(itemDesc), itemName, item);
	itemExtendMenu.SetTitle(itemName);
	DrawBlankPage(itemExtendMenu, numBuf, itemDesc, ITEMDRAW_DISABLED, 2);
	
	if (IsEquipableItem(itemName))
		itemExtendMenu.AddItem(ItemMenuKeyEquip, "아이템을 장착한다.");
	
	itemExtendMenu.AddItem(ItemMenuKeyDrop, "아이템을 버린다.");
	
	// 구현 예정?
	// if (itemKv.JumpToKey(ItemDataFormatKv, false) && GetItemCount(client, itemName) > 1)
	//	itemExtendMenu.AddItem(ItemMenuKeyDropAll, "아이템을 모두 버린다.");
		
	CloseHandle(itemKv);
	CloseHandle(item);
	
	itemExtendMenu.ExitBackButton = true;
	return itemExtendMenu;
}

void DisplayItemExtendMenu(int client, int itemIndex, char[] itemName)
{
	CreateItemExtendMenu(client, itemIndex, itemName).Display(client, MENU_TIME_FOREVER);
}

int ItemExtendMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char itemClass[64];
			char itemIndexBuf[3];
			char choiceKey[64];
			int itemIndex;
			
			menu.GetTitle(itemClass, sizeof(itemClass));
			menu.GetItem(0, itemIndexBuf, sizeof(itemIndexBuf));
			menu.GetItem(choice, choiceKey, sizeof(choiceKey));
			itemIndex = StringToInt(itemIndexBuf);
			
			if (StrEqual(ItemMenuKeyEquip, choiceKey))
			{
				if (!EquipItem(client, itemClass, itemIndex))
					PrintToChat(client, "\x04[Notify]\x01 해당 슬롯에는 이미 장비가 장착되어 있습니다.");
					
				ItemHandler_DisplayInventory(client);
			}
			else if(StrEqual(ItemMenuKeyDrop, choiceKey))
			{
				DeleteInventoryItem(client, itemClass, itemIndex);
				ItemHandler_DisplayInventory(client);
			}
			else if(StrEqual(ItemMenuKeyDropAll, choiceKey))
			{
				
			}
		}
		else if (action == MenuAction_Cancel)
		{
			if (choice == MenuCancel_ExitBack)
				ItemHandler_DisplayInventory(client);
		}
		else if (action == MenuAction_End)
			CloseHandle(menu);
	}
	else
		CloseHandle(menu);
}

public void ItemHandler_DisplayInventory(int client)
{
	CreateInventoryMenu(client).Display(client, MENU_TIME_FOREVER);
}