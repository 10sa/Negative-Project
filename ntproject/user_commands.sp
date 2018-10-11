public void NTProject_UserCommandsInit()
{
	RegConsoleCmd("stet", UserCommand_ShowStatus, "Show a user's status.");
	RegConsoleCmd("ㄴㅅㄷㅅ", UserCommand_ShowStatus, "Show a user's status.");
	RegConsoleCmd("menu", UserCommand_ShowMainMenu, "Display a main menu.");
	RegConsoleCmd("autobuy", UserCommand_ShowMainMenu, "Display a main menu.");
}

public Action UserCommand_ShowStatus(int client, int args)
{
	char clientName[NameBufferLength];
	GetClientName(client, clientName, sizeof(clientName));
	
	int clientLevel = GetClientLevel(client);
	int clientExp = GetClientExp(client);
	int clientNextExp = GetClientNextExp(client);
	int clientCash = GetClientCash(client);
	
	int clientSkillPoint = GetClientSkillPoint(client);
	int clientStetPoint = GetClientStetPoint(client);

	PrintToChatAll("%s's Status - \x04[Lv. %d] \x05[Exp : %d / %d] \x0A[%s : %d] \x08[Stet Point : %d] \x09[Skill Point : %d]", 
		clientName, clientLevel, clientExp, clientNextExp, CashName, clientCash, clientStetPoint, clientSkillPoint);
	
	return Plugin_Handled;
}

public Action UserCommand_ShowMainMenu(int client, int args)
{
	MenuControl_DisplayMainMenu(client);
	
	return Plugin_Handled;
}