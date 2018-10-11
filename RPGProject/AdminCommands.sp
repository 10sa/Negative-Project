methodmap AdminCommands __nullable__ {
	public AdminCommands ()
	{
		RegAdminCmd("np_test", TestCommand, ADMFLAG_ROOT);
	}
};

public Action TestCommand(int client, int args)
{
	Player player = GetPlayer(client);
	float playerPos[3];
	player.GetClientAbsOrigin(playerPos);
	
	Entity entity = view_as<Entity>(CreateEntityByName("env_explosion"));
	entity.SetDataProperty("m_iMagnitude", 2000);
	entity.SetDataProperty("m_iRadiusOverride", 44444);
	entity.SetDataProperty("m_iTeamNum", 1);
	entity.DispatchSpawn();
	entity.TeleportEntity(playerPos, NULL_VECTOR, NULL_VECTOR);
	entity.AcceptEntityInput("Explode");
	
	return Plugin_Handled;
}

AdminCommands adminCommands;