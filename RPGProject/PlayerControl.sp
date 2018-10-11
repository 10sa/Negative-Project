
Player Players[MAXPLAYERS + 1]; // 0 is Server, 1 ~ 64 is Player.

stock void DrawDamageLog(int victim, int attacker, int damage, int hitgroup)
{
	Player attackerPlayer = view_as<Player>(attacker);
	int victimHealth = GetEntProp(victim, Prop_Send, "m_iHealth");
	char boxMsg[256];
	int fontSize = 24;
	
	CreateTimer(0.01, DamageLogReset, attacker);
	damage += attackerPlayer.GetMember("iHitDamageLog", 0);
	attackerPlayer.SetMember("iHitDamageLog", damage);
	
	if (hitgroup == Hitgroup_Head)
		fontSize = 30;
		
	if (GetClientArmor(victim) > 0)
		Format(boxMsg, sizeof(boxMsg), "<font color='#00FFFF' size='%d'>- %d HP</font> (%d HP)", fontSize, damage, victimHealth);
	else
		Format(boxMsg, sizeof(boxMsg), "<font color='#FF0000' size='%d'>- %d HP</font> (%d HP)", fontSize, damage, victimHealth);
	
	PrintHintText(attacker, boxMsg);
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i) && GetClientObserverTarget(i) == attacker)
			PrintHintText(i, boxMsg);
	}
}

stock void GiveKillReward(int client, int exp, int cash, bool isKilled)
{
	if (exp > 0 || cash > 0)
	{
		Player player = GetPlayer(client);
	
		char buffer[128];
		char printText[256];
		GetClientName(client, buffer, sizeof(buffer));
	
		if (isKilled)
			StrCat(printText, sizeof(printText), " \04[Kill Reward] \x01적을 사살하여 ");
		else
			StrCat(printText, sizeof(printText), " \x04[Assist Reward] \x01적 사살에 도움을 주어 ");
			
		if (exp > 0)
		{
			Format(buffer, sizeof(buffer), "[%d Exp]", exp);
			StrCat(printText, sizeof(printText), buffer);
		}
		
		if (cash > 0)
		{
			Format(buffer, sizeof(buffer), "[%d CS]", cash);
			StrCat(printText, sizeof(printText), buffer);
		}
		
		StrCat(printText, sizeof(printText), " 을(를) 획득하였습니다.");
		PrintToChat(client, printText);
		
		player.GiveExp(exp);
		player.GiveCash(cash);
		player.Save();
	}
}

public Action DamageLogReset(Handle timer, int attacker)
{
	Player attackerPlayer = view_as<Player>(attacker);
	attackerPlayer.SetMember("iHitDamageLog", 0);
}

methodmap PlayerControl __nullable__ {
	public PlayerControl()
	{
		HookEvent("player_hurt", PlayerHurt);
		AddCommandListener(PlayerOnJoinTeam, "jointeam");
		RegConsoleCmd("say", PlayerSay);
		RegConsoleCmd("say_team", PlayerSay);
	
		return view_as<PlayerControl>(EMPTY_INSTANCE);
	}
	
	public void ClientPutInServer(int client)
	{
		Players[client] = new Player(client);
	}
	
	public void ClientDisconnected(int client)
	{
		Players[client].Dispose();
	}
};

PlayerControl playerControl;

public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	
}

public Action PlayerSay(int client, int args)
{
	Player player = GetPlayer(client);
	char argMsgBuffer[256];
	char playerName[256];
	
	GetCmdArgString(argMsgBuffer, sizeof(argMsgBuffer));
	player.GetName(playerName, sizeof(playerName));
	StripQuotes(argMsgBuffer);
	TrimString(argMsgBuffer);
	
	if (!StrEqual(argMsgBuffer, "") && strlen(argMsgBuffer) > 0)
		PrintToChatAll(" \x04[Lv.%d] \x05%s : \x01%s ", 1, playerName, argMsgBuffer);
	
	return Plugin_Handled;
}

public Action PlayerOnJoinTeam(int client, char[] command, int args)
{
	char teamName[3];
	GetCmdArg(1, teamName, sizeof(teamName));
	int team = StringToInt(teamName);
	
	if (team == CS_TEAM_SPECTATOR && IsAdmin(client))
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	else
		ChangeClientTeam(client, manager.RunFunction("GetFriendlyTeamRegion"));
	
	return Plugin_Handled;
}

// Desc
// 등록된 Player 클래스를 반환.
stock Player GetPlayer(int client)
{
	if (0 < client && client <= MAXPLAYERS)
		return Players[client];
	else
		return view_as<Player>(EMPTY_INSTANCE);
}

stock Player GetPlayerBySteamID(int steamID)
{
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsClientInGame(i) && Players[i].GetSteamAccountID() == steamID)
			return Players[i];
	}
	
	return view_as<Player>(EMPTY_INSTANCE);
}