
methodmap WeaponControl __nullable__ {

	public WeaponControl()
	{
		manager.CreateDataSet(WeaponDataSet);
		HookEventEx("player_spawn", OnWeaponReset, EventHookMode_Pre);
		
		return view_as<WeaponControl>(EMPTY_INSTANCE);
	}
	
	public void WeaponCreated(int weaponEntity)
	{
		Weapon weapon = new Weapon(weaponEntity);
		if (weapon.IsValidWeapon())
		{
			SDKUnhook(weaponEntity, SDKHook_Reload, WeaponOnReload);
			SDKUnhook(weaponEntity, SDKHook_ReloadPost, WeaponOnReloadPost);
			
			SDKHook(weaponEntity, SDKHook_Reload, WeaponOnReload);
			SDKHook(weaponEntity, SDKHook_ReloadPost, WeaponOnReloadPost);

			weapon.SetDefaultValues();
		}
	}
	
	public void OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weaponEntity, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
	{
		Player player = GetPlayer(client);
		Weapon weapon = new Weapon(player.GetActiveWeapon().GetEntity());
		
		if (buttons & IN_RELOAD && weapon.IsValidEntity())
		{
			if (weapon.GetClipSize() == weapon.Clip)
				buttons &= ~IN_RELOAD;
		}
	}
	
	public void LoadData()
	{
		KeyValues weaponData = manager.GetDataSet(WeaponDataSet);
		weaponData.ImportFromFile("addons/sourcemod/data/rpg/configs/weapon_config.cfg");
	}
};

WeaponControl weaponControl;

public Action WeaponOnReload(int weaponEntity)
{
	Weapon weapon = new Weapon(weaponEntity);
	if (weapon.GetClipSize() != INVALID_INDEX && weapon.GetClipSize() == weapon.Clip)
	{
		Player player = GetPlayer(weapon.GetOwner());
		if (player.IsValid() && weapon.IsShotgun())
		{
			weapon.PlaybackRate = 1.0;
			weapon.ReloadState = 0;
			player.ResetViewModel();
		}

		return Plugin_Handled;
	}
	
	if (!weapon.IsShotgun() && weapon.Clip > 0)
	{
		weapon.Clip -= 1;
		weapon.Ammo += 1;
	}
		
	return Plugin_Continue;
}

public void WeaponOnReloadPost(int weaponEntity, bool isSuccess)
{
	Weapon weapon = new Weapon(weaponEntity);
	Player owner = GetPlayer(weapon.GetOwner());

	if (isSuccess)
	{
		float reload_time = 1.0; // Reload Speed!
		float fGameTime = GetGameTime();
			
		if (weapon.IsShotgun())
		{
			float fIdleTime = weapon.TimeWeaponIdle;
			float fIdleTimeNew = (fIdleTime - fGameTime) / reload_time + fGameTime;
			
			weapon.TimeWeaponIdle = fIdleTimeNew;

			DataPack params;
			CreateDataTimer(0.1, ShotgunReloadTimer, params, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
			params.WriteCell(weapon);
			params.WriteCell(owner);
		}
		else 
		{
			float fIdleTime = weapon.NextPrimaryAttack;
			float fIdleTimeNew = (fIdleTime - fGameTime) / reload_time + fGameTime;
			
			owner.NextAttack = fIdleTimeNew;
			owner.ViewModelPlaybackRate = reload_time;
			weapon.NextPrimaryAttack = fIdleTimeNew;
			weapon.NextSecondaryAttack = fIdleTimeNew;
			weapon.TimeWeaponIdle = fIdleTimeNew;
			weapon.PlaybackRate = reload_time;
				
			DataPack params;
			CreateDataTimer(0.1, WeaponReloadTimer, params, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
			params.WriteCell(weapon);
			params.WriteCell(weapon.Ammo);
			params.WriteCell(weapon.Clip);
		}
	}
}

public Action WeaponReloadTimer(Handle timer, DataPack params)
{
	params.Reset();
	Weapon weapon = params.ReadCell();

	if (weapon.IsValidEntity() && !weapon.IsReload)
	{
		int ammo = params.ReadCell();
		int clip = params.ReadCell();
		int clipSize = weapon.GetClipSize();
		
		if (clipSize != INVALID_INDEX)
		{
			int reloadClip = clipSize;
			if (clipSize - clip > ammo)
			{
				reloadClip = ammo;
				ammo = 0;
			}
			else
				ammo -= clipSize - clip;

			weapon.Clip = reloadClip;
			weapon.Ammo = ammo;
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action ShotgunReloadTimer(Handle timer, DataPack params)
{
	params.Reset();
	Weapon weapon = params.ReadCell();
	Player player = params.ReadCell();
	
	if (weapon.IsShotgun() && weapon.IsValidEntity())
	{		
		Player owner = GetPlayer(weapon.GetOwner());
		if (owner.IsValid() && (weapon.GetClipSize() == INVALID_INDEX || weapon.Clip < weapon.GetClipSize()))
		{
			if (weapon.ReloadState > 0)
				return Plugin_Continue;
			else
			{
				weapon.PlaybackRate = 1.0;
				if (player.IsValid())
					player.ResetViewModel();
			}
		}
		else
		{
			weapon.PlaybackRate = 1.0;
			player.ResetViewModel();
		}
	}
	
	return Plugin_Stop;
}

public Action OnWeaponReset(Event event, const char[] name, bool dontBroadcast)
{
	Player player = GetPlayer(GetClientOfUserId(event.GetInt("userid")));
	for(int i = 0; i < CS_SLOT_SECONDARY; i++)
	{
		Weapon weapon = new Weapon(GetPlayerWeaponSlot(player.GetEntity(), i));
		if (weapon.IsValidEntity())
			weapon.SetDefaultValues();
	}
}