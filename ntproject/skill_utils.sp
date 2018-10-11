stock int LoadSkillKeyValues(KeyValues kv)
{
	KeyValues tKv = CreateKeyValues("Skill_Temp");
	char calltype[64];
	char skillName[64];
	char notifyPrefix[64];
	char functionFormat[64];
	
	kv.GetString(SkillDataNotifyPrefix, notifyPrefix, sizeof(notifyPrefix), SkillNotifyDefaultPrefix)
	kv.GetString(SkillDataFunctionFormat, functionFormat, sizeof(functionFormat), SkillFunctionFormat)
	
	kv.GotoFirstSubKey();
	do
	{
		kv.GetSectionName(skillName, sizeof(skillName));
		
		if (IsValidSkill(kv, functionFormat))
		{
			kv.GetString(SkillDataCallType, calltype, sizeof(calltype), NULL_STRING);
			
			tKv.JumpToKey(calltype, true);
			tKv.JumpToKey(skillName, true);
			
			// 가르키고 있는 스킬 데이터를 콜타입에 따라 분류 //
			tKv.Import(kv);
			tKv.Rewind();
			
			LogAction(0, 0, "[Notify] Skill Load Success. [<%s> Skill : %s]", notifyPrefix, skillName);
		}
	}
	while(kv.GotoNextKey())
	kv.Rewind();
	
	tKv.GotoFirstSubKey();
	do
	{
		tKv.GetSectionName(calltype, sizeof(calltype));
		
		kv.JumpToKey(calltype, true);
		kv.Import(tKv);
		kv.Rewind();
	}
	while(tKv.GotoNextKey())
	
	kv.Rewind();
	CloseHandle(tKv);
}

stock bool GetSkillCallInfo(KeyValues skillData, char[] name, char[] calltype, Function &call = INVALID_FUNCTION, char[] buffer, int length)
{
	char sectionBuffer[128];
	char functionName[128];
	char functionFormat[128];
	
	KeyValues hTmp = CreateKeyValues("tmpKv");
	skillData.Rewind();
	hTmp.Import(skillData);
	
	if (hTmp.JumpToKey(calltype, false))
	{
		hTmp.GotoFirstSubKey();
		do
		{
			hTmp.GetSectionName(sectionBuffer, sizeof(sectionBuffer));
			if (StrEqual(sectionBuffer, name))
			{
				hTmp.GetString(SkillDataCallType, buffer, length);
				hTmp.GetString(SkillDataFunction, functionName, sizeof(functionName));
				skillData.GetString(SkillDataFunctionFormat, functionFormat, sizeof(functionFormat), SkillFunctionFormat);
				
				CreateSkillFunctionPath(functionName, sizeof(functionName), functionName, functionFormat);
				call = GetFunctionByName(INVALID_HANDLE, functionName);
				
				return true;
			}
			
		}
		while(hTmp.GotoNextKey())
	}
	
	CloseHandle(hTmp);
	skillData.Rewind();
	return false;
}

void CreateSkillFunctionPath(char[] buffer, int length, char[] name, char[] format = SkillFunctionFormat)
{
	Format(buffer, length, format, name);
}


stock void CallPlayerSkills(int client, KeyValues kv, char[] functionType, DataPack data, any &extraData = INVALID_HANDLE)
{
	KeyValues skillDataKv;
	KeyValues clientKv = CreateKeyValues("tmpKv");
	
	clientKv.Import(kv);
	
	if (IsFakeClient(client))
		skillDataKv = hBotSkillData;
	else
		skillDataKv = hSkillData;
		
	if (clientKv.JumpToKey(PlayerDataSkillKv, false))
	{
		char skillName[64];
		char calltype[64];

		clientKv.GotoFirstSubKey();
		do
		{
			Function skillFunc;
			clientKv.GetSectionName(skillName, sizeof(skillName));
			
			if (GetSkillCallInfo(skillDataKv, skillName, functionType, skillFunc, calltype, sizeof(calltype)))
			{
				char sectionName[32];
				int skillLevel = clientKv.GetNum(PlayerDataSkillLevel, 0);
				clientKv.GetSectionName(sectionName, sizeof(sectionName));
				
				if (skillLevel > 0 || IsFakeClient(client))
				{
					data.Reset();
					
					Call_StartFunction(INVALID_HANDLE, skillFunc);
					Call_PushCell(data);
					Call_PushCell(skillLevel);
					Call_PushCellRef(extraData);
					Call_Finish();
					
					data.Reset();
				}
			}
		}
		while(clientKv.GotoNextKey())
	}
	
	CloseHandle(clientKv);
	CloseHandle(data);
}

stock bool IsValidSkill(KeyValues kv, char[] functionFormat = SkillFunctionFormat)
{
	char functionName[64];
	char calltype[64];
	char skillName[32];
	
	kv.GetString(SkillDataFunction, functionName, sizeof(functionName), NULL_STRING);
	kv.GetString(SkillDataCallType, calltype, sizeof(calltype), NULL_STRING);
	kv.GetSectionName(skillName, sizeof(skillName));
	
	CreateSkillFunctionPath(functionName, sizeof(functionName), functionName, functionFormat);
	
	if (StrEqual(functionName, NULL_STRING))
		LogError("[Error] Skill no has Function! [Skill : %s]", skillName);
	else if (StrEqual(calltype, NULL_STRING))
		LogError("[Error] Skill no has Calltype! [Skill : %s]", skillName);
	else if (GetFunctionByName(INVALID_HANDLE, functionName) == INVALID_FUNCTION)
		LogError("[Error] Skill has undefined function name! [Skill : %s, Function Name : %s]", skillName, functionName);
	else
		return true;
	
	return false;
}