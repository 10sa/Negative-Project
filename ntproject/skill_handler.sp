public void NTProject_SkillHandlerInit()
{
	SkillHandler_LoadSkillData();
	LoadSkillKeyValues(hSkillData);
}

public void SkillHandler_LoadSkillData()
{
	hSkillData = CreateKeyValuesEx("game_data/skill_list.txt", "skill_list");
	hSkillData.SetString(SkillDataFunctionFormat, SkillFunctionFormat);
	hSkillData.SetString(SkillDataNotifyPrefix, SkillNotifyUserPrefix);
}

Menu CreateSkillMenu(int client)
{
	Menu skillMenu = CreateMenu(SkillMenuHandler);
	skillMenu.SetTitle("◇ 스킬 > Skill Point : %d", GetClientSkillPoint(client));
	
	CreateSkillMenuItems(skillMenu, client);
	
	skillMenu.ExitBackButton = true;
	return skillMenu;
}

public void SkillHandler_DisplaySkillMenu(int client)
{
	CreateSkillMenu(client).Display(client, MENU_TIME_FOREVER);
}

void CreateSkillMenuItems(Menu menu, int client)
{
	char skillName[64];
	char skillDesc[64];
	char skillTitle[128];

	hSkillData.Rewind();
	
	KeyValues tempKv = CreateKeyValues("tmp");
	tempKv.Import(hSkillData);
	
	tempKv.GotoFirstSubKey();
	do
	{
		tempKv.GetSectionName(skillName, sizeof(skillName));
		if (StrContains(skillName, "_") == -1)
		{
			int clientSkillLevel = GetClientSkillLevel(client, skillName);
			int skillMaxLevel = tempKv.GetNum(SkillDataMaxLevel, 0);
			int skillSpCost = GetSkillSpCost(client, skillName);
			int skillCashCost = GetSkillCashCost(client, skillName);
			int skillReqLevel = GetSkillRequestLevel(client, skillName);
			
			int drawType = IsUpgradeableEx(client, skillName, skillMaxLevel, skillCashCost, skillSpCost, skillReqLevel) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
			
			tempKv.GetString(SkillDataDesc, skillDesc, sizeof(skillDesc), NULL_STRING);
			
			if (skillMaxLevel == clientSkillLevel)
				Format(skillTitle, sizeof(skillTitle), "%s [%d/%d]\n - %s", skillName, clientSkillLevel, skillMaxLevel, skillDesc);
			else
				Format(skillTitle, sizeof(skillTitle), "%s [%d/%d] - SP : %d | %s : %d | Lv : %d\n - %s", 
					skillName, clientSkillLevel, skillMaxLevel, skillSpCost, CashName, skillCashCost, skillReqLevel, skillDesc);
				
			DrawBlankPage(menu, skillName, skillTitle, drawType, 1);
		}
	}
	while(tempKv.GotoNextKey())
	
	CloseHandle(tempKv);
}

stock bool IsUpgradeableEx(int client, char[] skillName, int skillMaxLevel, int skillCashCost, int skillSpCost, int skillReqLevel)
{
	int clientSkillLevel = GetClientSkillLevel(client, skillName);
	int clientSp = GetClientSkillPoint(client);
	int clientLevel = GetClientLevel(client);
	int clientCash = GetClientCash(client);
	
	if (skillSpCost <= clientSp && skillMaxLevel > clientSkillLevel && skillCashCost <= clientCash && skillReqLevel <= clientLevel)
		return true;
	else
		return false;
}

stock bool IsUpgradeable(int client, char[] skillName)
{
	int skillMaxLevel = GetSkillMaxLevel(skillName);
	int spCost = GetSkillSpCost(client, skillName);
	int cashCost = GetSkillCashCost(client, skillName);
	int reqLevel = GetSkillRequestLevel(client, skillName);
		
	if (IsUpgradeableEx(client, skillName, skillMaxLevel, cashCost, spCost, reqLevel))
		return true;
	else
		return false;
}

// 플레이어가 스폰되었을 때
public void Skills_PlayerSpawn(int client)
{
	
}

// 플레이어가 데미지를 주었을 때
public void Skills_PlayerAttack(int client, int vicitm, float &damage, char[] weaponName)
{
	DataPack data = CreateDataPack();
	data.WriteCell(client);
	data.WriteCell(vicitm);
	data.WriteString(weaponName);
	
	CallPlayerSkills(client, hPlayerData[client], SkillDataCalltype_Attack, data, damage);
}

// 플레이어가 무기를 구매 했을 때
public void Skills_PlayerBuyWeapon(int client, int weapon)
{
	DataPack data = CreateDataPack();
	data.WriteCell(client);
	data.WriteCell(weapon);
	
	CallPlayerSkills(client, hPlayerData[client], SkillDataCalltype_WeaponBuy, data);
}

// Type : weapon_buy
public void SkillFunction_AmmoPlus(DataPack data, int skillLevel, any &extraData)
{
	int client = data.ReadCell();
	int weapon = data.ReadCell();
	
	char weaponClass[ClassBufferLength];
	GetWeaponClassEx(weapon, weaponClass, sizeof(weaponClass));
	
	if (IsValidClient(client) && !IsIgnoreAmmoPlusWeapon(weaponClass))
	{
		int primaryAmmo = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
		int skillAmmo = FloatMulCalc(primaryAmmo, 0.08, skillLevel);
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", skillAmmo);
	}
}

bool IsIgnoreAmmoPlusWeapon(char[] class)
{
	if (IsThrowWeapon(class) || StrEqual(class, "weapon_healthshot") || StrEqual(class, "weapon_knife"))
		return true;
	else
		return false;
}

public void SkillFunction_HeavyFlashbang(DataPack data, int skillLevel, float &damage)
{
	data.ReadCell();
	int vicitm = data.ReadCell();
	char weaponClass[ClassBufferLength]; data.ReadString(weaponClass, sizeof(weaponClass));
	
	if (IsFakeClient(vicitm) && StrEqual(weaponClass, "flashbang_projectile") && !IsGunBot(vicitm))
		damage = skillLevel * 200.0;
}

public void SkillFunction_PointDecoy(DataPack data, int skillLevel, float &damage)
{
	data.ReadCell();
	int vicitm = data.ReadCell();
	char weaponClass[ClassBufferLength]; data.ReadString(weaponClass, sizeof(weaponClass));
	
	if (IsFakeClient(vicitm) && StrEqual(weaponClass, "decoy_projectile") && IsGunBot(vicitm))
		damage = GetClientHealth(vicitm) * 2.0;
}

int SkillMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char skillName[64];
			menu.GetItem(choice, skillName, sizeof(skillName));
			DrawExtendSkillDesc(client, skillName);
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

void DrawExtendSkillDesc(int client, char[] skillName)
{
	Menu extendSkillMenu = CreateMenu(ExtendSkillMenuHandler);
	char descBuffer[512];
	char skillDesc[128];
	char skillDescEx[128];
	
	int clientSkillLevel = GetClientSkillLevel(client, skillName);
	int skillMaxLevel = GetSkillMaxLevel(skillName);
	
	extendSkillMenu.SetTitle("◈ %s [%d/%d]", skillName, clientSkillLevel, skillMaxLevel);
	GetSkillDesc(skillName, skillDesc, sizeof(skillDesc), skillDescEx, sizeof(skillDescEx));
	Format(descBuffer, sizeof(descBuffer), "%s\n  - %s", skillDesc, skillDescEx);
	
	DrawBlankPage(extendSkillMenu, "", descBuffer, ITEMDRAW_DISABLED, 4);
	DrawBlankPage(extendSkillMenu, skillName, SkillLevelUp, ITEMDRAW_DEFAULT, 0);

	extendSkillMenu.ExitBackButton = true;
	extendSkillMenu.Display(client, MENU_TIME_FOREVER);
}

int ExtendSkillMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if (client > 0 && IsClientConnected(client) && menu != INVALID_HANDLE)
	{
		if (action == MenuAction_Select)
		{
			char skillName[64];
			menu.GetItem(choice, skillName, sizeof(skillName));
			
			if (IsUpgradeable(client, skillName))
			{
				int reqCash = GetSkillCashCost(client, skillName);
				int reqSp = GetSkillSpCost(client, skillName);
					
				SetClientCash(client, GetClientCash(client) - reqCash);
				SetClientSkillPoint(client, GetClientSkillPoint(client) - reqSp);
					
				AddClientSkillLevel(client, skillName);
				PlayerDataManager_SavePlayerData(client);
				
				if (IsUpgradeable(client, skillName))
					DrawExtendSkillDesc(client, skillName);
				else
					CreateSkillMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		else if (action == MenuAction_Cancel)
		{
			if (choice == MenuCancel_ExitBack)
				CreateSkillMenu(client).Display(client, MENU_TIME_FOREVER);
		}
	}
}

stock int GetClientSkillLevel(int client, char[] skillName)
{
	int skillLevel = 0;
	if (hPlayerData[client].JumpToKey(PlayerDataSkillKv, false) && hPlayerData[client].JumpToKey(skillName, false))
		skillLevel = hPlayerData[client].GetNum(PlayerDataSkillLevel, 0);
	
	hPlayerData[client].Rewind();
	return skillLevel;
}

stock void GetSkillDesc(char[] skillName, char[] skillDesc, int skillDescLength, char[] skillDescEx, int skillDescExLength)
{
	if (hSkillData.JumpToKey(skillName, false))
	{
		hSkillData.GetString(SkillDataDesc, skillDesc, skillDescLength, NULL_STRING);
		hSkillData.GetString(SkillDataDescEx, skillDescEx, skillDescExLength, NULL_STRING);
	}
	
	hSkillData.Rewind();
}

stock int GetSkillMaxLevel(char[] skillName)
{
	int skillLevel = 0;
	if (hSkillData.JumpToKey(skillName, false))
		skillLevel = hSkillData.GetNum(SkillDataMaxLevel, 1);
		
	hSkillData.Rewind();
	return skillLevel;
}

stock int GetSkillSpCost(int client, char[] skillName)
{
	int clientSkillLevel = GetClientSkillLevel(client, skillName);
	int cost = 10;
	
	char skillLevel[3];
	IntToString(clientSkillLevel, skillLevel, sizeof(skillLevel));
	
	if (hSkillData.JumpToKey(skillName, false) && 
		hSkillData.JumpToKey(SkillDataRequest, false) &&
		hSkillData.JumpToKey(skillLevel, false))
	{
		cost = hSkillData.GetNum(SkillDataSpCost, cost);
	}
	
	hSkillData.Rewind();
	return cost;
}

stock int GetSkillRequestLevel(int client, char[] skillName)
{
	int clientSkillLevel = GetClientSkillLevel(client, skillName);
	int level = 1;
	
	char skillLevel[3];
	IntToString(clientSkillLevel, skillLevel, sizeof(skillLevel));
	
	if (hSkillData.JumpToKey(skillName, false) && 
		hSkillData.JumpToKey(SkillDataRequest, false) &&
		hSkillData.JumpToKey(skillLevel, false))
	{
		level = hSkillData.GetNum(SkillDataLevel, level);
	}
	
	hSkillData.Rewind();
	return level;
}

stock int GetSkillCashCost(int client, char[] skillName)
{
	int clientSkillLevel = GetClientSkillLevel(client, skillName);
	int cost = 10;
	
	char skillLevel[3];
	IntToString(clientSkillLevel, skillLevel, sizeof(skillLevel));
	
	if (hSkillData.JumpToKey(skillName, false) && 
		hSkillData.JumpToKey(SkillDataRequest, false) &&
		hSkillData.JumpToKey(skillLevel, false))
	{
		cost = hSkillData.GetNum(SklllDataCost, cost);
	}
	
	hSkillData.Rewind();
	return cost;
}

stock void SetClientSkillPoint(int client, int sp)
{
	hPlayerData[client].SetNum(PlayerDataSkillPoint, sp);
}

stock int GetClientSkillPoint(int client)
{
	return hPlayerData[client].GetNum(PlayerDataSkillPoint, 0);
}

stock void AddClientSkillLevel(int client, char[] skillName)
{
	int nextSkillLevel = GetClientSkillLevel(client, skillName) + 1;
	int useSkillPoint = GetSkillSpCost(client, skillName);
	int useCash = GetSkillCashCost(client, skillName);
	
	hPlayerData[client].JumpToKey(PlayerDataSkillKv, true);
	
	hPlayerData[client].SetNum(PlayerDataSkillUseSp, useSkillPoint + hPlayerData[client].GetNum(PlayerDataSkillUseSp, 0));
	hPlayerData[client].SetNum(PlayerDataSkillUseCash, useCash + hPlayerData[client].GetNum(PlayerDataSkillUseCash, 0));
	
	hPlayerData[client].JumpToKey(skillName, true);
	hPlayerData[client].SetNum(PlayerDataSkillLevel, nextSkillLevel);
	
	hPlayerData[client].Rewind();
}