
public NTProject_ItemHadnlerInit()
{
	LoadEquipmentSlots();
	LoadItemClasses();
}

void LoadEquipmentSlots()
{
	if (hEquipmentSlotData != INVALID_HANDLE)
		CloseHandle(hEquipmentSlotData);
		
	hEquipmentSlotData = CreateKeyValuesEx("game_data/equipment_slots.txt", "equipment_slots");
}

void LoadItemClasses()
{
	char filePath[128];
	char filePathBuffer[128];
	
	CreateDataPath(filePath, sizeof(filePath), "item_data");
	DirectoryListing list = OpenDirectory(filePath);
	
	if (hItemClassData != INVALID_HANDLE)
		CloseHandle(hItemClassData);
		
	hItemClassData = CreateKeyValues("item_data");
	LogAction(0, -1, "[Notify] Load item data...");
	while(list.GetNext(filePathBuffer, sizeof(filePathBuffer)))
	{
		if (StrContains(filePathBuffer, ".txt") != -1)
		{
			LogAction(0, -1, "[Notify] Load \"%s\" file...", filePathBuffer);
			
			Format(filePathBuffer, sizeof(filePathBuffer), "item_data/%s", filePathBuffer);
			KeyValues tmpKv = CreateKeyValuesEx(filePathBuffer, "tmp");
			
			if (IsValidItem(tmpKv, filePathBuffer))
			{
				char itemName[64];	
				tmpKv.GetString(ItemDataName, itemName, sizeof(itemName), NULL_STRING);
	
				hItemClassData.JumpToKey(itemName, true);
				hItemClassData.Import(tmpKv);
				hItemClassData.Rewind();
				
				LogAction(0, -1, "[Notify] \"%s\" File load success. [%s]", filePathBuffer, itemName);
			}
			
			CloseHandle(tmpKv);
		}
	}
}

// 인자는 해당 아이템의 데이터임.
public void ItemFunction_DamageAdd(int client, DataPack data, any &extraData)
{
	
}

stock KeyValues GetItemClass(char[] itemClass)
{
	KeyValues tmpKv = null;
	if (hItemClassData.JumpToKey(itemClass, false))
	{
		tmpKv = CreateKeyValues("item");
		tmpKv.Import(hItemClassData);
		
		hItemClassData.Rewind();
	}
	
	return tmpKv;
}

stock void GetItemDesc(char[] buffer, int length, char[] itemClass, KeyValues itemData)
{
	KeyValues itemKv = GetItemClass(itemClass);
	char formatBuf[16];
	char dataBuffer[64];
	int descItem = itemKv.GetNum(ItemDataDescFormatItem, 0);
	
	if (itemKv != INVALID_HANDLE)
	{
		itemKv.GetString(ItemDataDesc, buffer, length, NULL_STRING);
		if (!StrEqual(buffer, NULL_STRING))
		{
			itemData.GotoFirstSubKey(false);
			
			for (int i = 1; i <= descItem; i++)
			{
				KvDataTypes type = itemData.GetDataType(NULL_STRING);
				Format(formatBuf, sizeof(formatBuf), "{%d}", i);
				
				if (type == KvData_Int)
					IntToString(itemData.GetNum(NULL_STRING), dataBuffer, sizeof(dataBuffer));
				else if (type == KvData_Float)
					Format(dataBuffer, sizeof(dataBuffer), "%.2f％", itemData.GetFloat(NULL_STRING));
				else if (type == KvData_String)
					itemData.GetString(NULL_STRING, dataBuffer, sizeof(dataBuffer));
				
				ReplaceString(buffer, length, formatBuf, dataBuffer);
			}
		}
		
		CloseHandle(itemKv);
	}
}

stock KeyValues GetClientInventoryItemData(int client, char[] itemClass, int itemIndex)
{
	KeyValues itemKv = null;
	char numBuf[3];
	IntToString(itemIndex, numBuf, sizeof(numBuf));
	
	hPlayerData[client].JumpToKey(PlayerDataInventoryKv, true);
	
	if (hPlayerData[client].JumpToKey(itemClass) && hPlayerData[client].JumpToKey(numBuf))
	{
		itemKv = CreateKeyValues(itemClass);
		itemKv.Import(hPlayerData[client]);
	}
	
	hPlayerData[client].Rewind();
	return itemKv;
}

stock bool IsEquipableItem(char[] itemClass)
{
	KeyValues tempKv = CreateKeyValues("temp");
	bool isSuccess = false;
	tempKv.Import(hItemClassData);
	
	if (tempKv.JumpToKey(itemClass))
	{
		bool isEquipable = tempKv.GetNum(ItemDataEquipable, false) ? true : false;
		char itemEquipSlot[64];
		char itemEquipSlotName[64];
	
		GetItemEquipmentSlot(itemClass, itemEquipSlot, sizeof(itemEquipSlot));
		hEquipmentSlotData.GetString(itemEquipSlot, itemEquipSlotName, sizeof(itemEquipSlotName), NULL_STRING);
		
		if (!StrEqual(itemEquipSlotName, NULL_STRING) && isEquipable)
			isSuccess = true;
	}

	CloseHandle(tempKv);
	return isSuccess;
}

stock bool EquipItem(int client, char[] itemClass, int itemIndex)
{
	KeyValues itemKv = GetClientInventoryItemData(client, itemClass, itemIndex);
	bool isSuccess = false;

	if (hPlayerData[client].JumpToKey(PlayerDataEquipmentKv, true))
	{
		char equipSlot[64];
		GetItemEquipmentSlot(itemClass, equipSlot, sizeof(equipSlot));
		
		if (!hPlayerData[client].JumpToKey(equipSlot, false))
		{
			hPlayerData[client].JumpToKey(equipSlot, true);
			hPlayerData[client].SetString(PlayerDataEquipmentClass, itemClass);
			
			hPlayerData[client].JumpToKey(ItemDataEquipItemData, true);
			hPlayerData[client].Import(itemKv);
			hPlayerData[client].Rewind();
			
			isSuccess = true;
			DeleteInventoryItem(client, itemClass, itemIndex);
		}
	}
	
	hPlayerData[client].Rewind();
	CloseHandle(itemKv);
	return isSuccess;
}

stock bool UnequipItem(int client, char[] slot)
{
	char itemClass[128];
	char numBuf[3];
	KeyValues itemData = GetEquipedItemData(client, slot, itemClass, sizeof(itemClass));
	
	hPlayerData[client].JumpToKey(PlayerDataInventoryKv, true);
	hPlayerData[client].JumpToKey(itemClass, true);
	
	int itemCount = hPlayerData[client].GetNum(ItemDataItemCount, 0);
	IntToString(itemCount + 1, numBuf, sizeof(numBuf));
	hPlayerData[client].SetNum(ItemDataItemCount, itemCount + 1);
	
	hPlayerData[client].JumpToKey(numBuf, true);
	hPlayerData[client].Import(itemData);
	
	hPlayerData[client].Rewind();
	
	hPlayerData[client].JumpToKey(PlayerDataEquipmentKv, false);
	hPlayerData[client].JumpToKey(slot);
	hPlayerData[client].DeleteThis();
	hPlayerData[client].Rewind();
	
	PlayerDataManager_SavePlayerData(client);
	CloseHandle(itemData);
}

stock bool IsEquipedItemSlot(int client, char[] slot)
{
	bool isSuccess = false;
	hPlayerData[client].JumpToKey(PlayerDataEquipmentKv, true)
	
	if (hPlayerData[client].JumpToKey(slot, false))
		isSuccess = true;
	
	hPlayerData[client].Rewind();
	return isSuccess;
}

stock KeyValues GetEquipedItemData(int client, char[] slot, char[] itemName, int length)
{
	KeyValues itemDataKv = null;
	strcopy(itemName, length, NULL_STRING);
	
	if (IsEquipedItemSlot(client, slot))
	{
		if (hPlayerData[client].JumpToKey(PlayerDataEquipmentKv, false) && hPlayerData[client].JumpToKey(slot))
		{
			hPlayerData[client].GetString(PlayerDataEquipmentClass, itemName, length, NULL_STRING);
			hPlayerData[client].JumpToKey(PlayerDataEquipmentItemData, true);
			
			itemDataKv = CreateKeyValues("tmp");
			itemDataKv.Import(hPlayerData[client]);
		}
	}
	
	hPlayerData[client].Rewind();
	return itemDataKv;
}

stock void GetEquipedItemClass(int client, char[] slot, char[] itemName, int length)
{
	strcopy(itemName, length, NULL_STRING);
	
	if (IsEquipedItemSlot(client, slot))
	{
		if (hPlayerData[client].JumpToKey(PlayerDataEquipmentKv, false) && hPlayerData[client].JumpToKey(slot))
			hPlayerData[client].GetString(PlayerDataEquipmentClass, itemName, length, NULL_STRING);
	}
	
	hPlayerData[client].Rewind();
}

stock bool IsHasCalltypeEquipment(int client, char[] calltype)
{
	bool isSuccess = false;
	
	if (hPlayerData[client].JumpToKey(PlayerDataEquipmentKv, false))
	{
		if (hEquipmentSlotData.GotoFirstSubKey(false))
		{
			char slotID[64];
			char itemCalltype[64];
			
			do
			{
				hEquipmentSlotData.GetSectionName(slotID, sizeof(slotID));
				if (hPlayerData[client].JumpToKey(slotID, false))
				{
					hPlayerData[client].GetString(ItemDataCalltype, itemCalltype, sizeof(itemCalltype), NULL_STRING);
					if (StrEqual(itemCalltype, calltype))
					{
						isSuccess = true;
						break;
					}
				}
			}
			while (hEquipmentSlotData.GotoNextKey())
		}
	}
	
	hEquipmentSlotData.Rewind();
	hPlayerData[client].Rewind();
	return isSuccess;
}

// P.S : 재정렬을 시작할 위치를 넘겨줘야 함. (재정렬 이전 위치는 제거되었다고 가정)
stock void StackItem(int client, char[] itemClass, int startIndex)
{
	hPlayerData[client].JumpToKey(PlayerDataInventoryKv, true);
	if (hPlayerData[client].JumpToKey(itemClass))
	{
		int maxItems = hPlayerData[client].GetNum(ItemDataItemCount, 0);
		char numBuf[3];

		int stackPos = startIndex - 1;
		for (int i = startIndex; i - startIndex < maxItems; i++)
		{
			IntToString(i, numBuf, sizeof(numBuf));
			if (hPlayerData[client].JumpToKey(numBuf))
			{
				IntToString(stackPos, numBuf, sizeof(numBuf));
				hPlayerData[client].SetSectionName(numBuf);
				hPlayerData[client].GoBack();
				
				stackPos++;
			}
		}
	}
	
	hPlayerData[client].Rewind();
}

stock bool DeleteInventoryItem(int client, char[] itemClass, int itemIndex)
{
	bool isSuccess = false;
	
	hPlayerData[client].JumpToKey(PlayerDataInventoryKv, true);
	if (hPlayerData[client].JumpToKey(itemClass))
	{
		int itemCount = hPlayerData[client].GetNum(ItemDataItemCount, 0);
		char numBuf[3];
		
		IntToString(itemIndex, numBuf, sizeof(numBuf));
		hPlayerData[client].SetNum(ItemDataItemCount, itemCount - 1);
		
		if (hPlayerData[client].JumpToKey(numBuf) && hPlayerData[client].DeleteThis())
		{
			if (itemCount - 1 > 0)
			{
				hPlayerData[client].Rewind();
					
				StackItem(client, itemClass, itemIndex + 1);
			}
			else // 아이템이 더이상 없으므로 해당 아이템 클래스 자체를 삭제.
				hPlayerData[client].DeleteThis();
					
			isSuccess = true;
		}
	}
	else
		hPlayerData[client].Rewind();
		
	if (isSuccess)
		PlayerDataManager_SavePlayerData(client);
		
	return isSuccess;
}

stock bool AddInventoryItem(int client, KeyValues itemKv, char[] itemClass)
{
	int itemCount = GetItemCount(client, itemClass) + 1;
	char numBuf[3];
	
	IntToString(itemCount, numBuf, sizeof(numBuf));
	hPlayerData[client].JumpToKey(PlayerDataInventoryKv, true)
	hPlayerData[client].JumpToKey(itemClass, true);
	
	hPlayerData[client].SetNum(ItemDataItemCount, itemCount);
	
	hPlayerData[client].JumpToKey(numBuf, true);
	hPlayerData[client].Import(itemKv);
	
	hPlayerData[client].Rewind();
}

// 추후 클라이언트 아이템으로 확률 자체에 영향을 줄수 있으므로 클라이언트 값도 받아옴.
stock KeyValues CreateItemKv(int client, char[] itemClass)
{
	KeyValues itemDataKv = CreateKeyValues(itemClass);
	KeyValues itemKv = GetItemClass(itemClass);
	
	if (itemKv.JumpToKey("kItemCreateFormat", false) && itemKv.GotoFirstSubKey())
	{
		do
		{
			char dataName[64];
			itemKv.GetSectionName(dataName, sizeof(dataName));
			
			int dataType = itemKv.GetNum(ItemDataCreateType, -1);
			if (dataType == ITypeInt)
			{
				LogError("[Error] Unsupport Format!");
			}
			else if (dataType == ITypeFloat)
			{
				int chance = itemKv.GetNum(ItemDataCreateChance, 0);
				float min = itemKv.GetFloat(ItemDataCraeteFloatMin, 0.0);
				float max = itemKv.GetFloat(ItemDataCraeteFloatMax, 0.0);
				bool isNegative = itemKv.GetNum(ItemDataCraeteIsNegative, false) ? true : false;

				float itemData = GetRandomFloatValue(chance, min, max, isNegative);
				
				itemDataKv.SetFloat(dataName, itemData);
			}
			else
				LogError("[Error] Undefined var type!");
		}
		while(itemKv.GotoNextKey())
	}
	
	CloseHandle(itemKv);
	
	itemDataKv.Rewind();
	return itemDataKv;
}

stock void GiveItem(int client, char[] itemClass)
{
	KeyValues itemData = CreateItemKv(client, itemClass);
	AddInventoryItem(client, itemData, itemClass);
	
	PlayerDataManager_SavePlayerData(client);
	CloseHandle(itemData);
}

stock void GetItemEquipmentSlot(char[] itemClass, char[] buffer, int length)
{
	if (hItemClassData.JumpToKey(itemClass))
	{
		hItemClassData.GetString(ItemDataEquipmentSlot, buffer, length);
		hItemClassData.Rewind();
	}
	else
		strcopy(buffer, length, NULL_STRING);
}

stock int GetItemCount(int client, char[] itemClass)
{
	int itemCount = 0;
	
	hPlayerData[client].JumpToKey(PlayerDataInventoryKv, true);
	if (hPlayerData[client].JumpToKey(itemClass, false))
		itemCount = hPlayerData[client].GetNum(ItemDataItemCount, 0);
	
	hPlayerData[client].Rewind();
	return itemCount;
}

stock bool IsValidItem(KeyValues itemKv, char[] fileIdentifier)
{
	char itemName[64];	
	itemKv.GetString(ItemDataName, itemName, sizeof(itemName), NULL_STRING);
	bool isEquipable = IsEquipableItem(itemName);
	
	if (!StrEqual(itemName, NULL_STRING))
	{
		if (isEquipable)
		{
			char equipmentSlot[128];
			char itemFunction[64];
			itemKv.GetString(ItemDataEquipmentSlot, equipmentSlot, sizeof(equipmentSlot), NULL_STRING);
			itemKv.GetString(ItemDataFunction, itemFunction, sizeof(itemFunction), NULL_STRING);
			Format(itemFunction, sizeof(itemFunction), "ItemFunction_%s", itemFunction);
			
			if (StrEqual(equipmentSlot, NULL_STRING))
				LogError("[Error] \"%s\" Item no has equipment slot!", equipmentSlot);
			else if (GetFunctionByName(INVALID_HANDLE, itemFunction) == INVALID_FUNCTION)
				LogError("[Error] \"%s\" Item has undefined item function!");
			else
			{
				char slotBuffer[64];
				hEquipmentSlotData.GetString(equipmentSlot, slotBuffer, sizeof(slotBuffer), NULL_STRING);
				
				if (StrEqual(slotBuffer, NULL_STRING))
					LogError("[Error] \"%s\" Item has undefined equipment slot!", itemName);
				else
					return true;
			}
		}
		else
			return true;
	}
	else
		LogError("[Error] \"%s\" Item no has name!", fileIdentifier);
	
	return false;
}