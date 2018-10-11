
methodmap Weapon < Entity {

	public Weapon(int entity)
	{
		return view_as<Weapon>(entity);
	}
	
	public void GetWeaponClass(char[] buffer, int length)
	{
		int entity = this.GetEntity();
		strcopy(buffer, length, NULL_STRING);
		
		GetEntityClassname(entity, buffer, length);
		if (StrEqual(buffer, "weapon_degale"))
		{
			if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 64)
				strcopy(buffer, length, "weapon_revolver");
		}
		else if (StrEqual(buffer, "weapon_p250"))
		{
			if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 63)
				strcopy(buffer, length, "weapon_cz75a");
		}
		else if (StrEqual(buffer, "weapon_hkp2000"))
		{
			if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 61)
				strcopy(buffer, length, "weapon_usp_silencer");
		}
		else if (StrEqual(buffer, "weapon_m4a1"))
		{
			if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 60)
				strcopy(buffer, length, "weapon_m4a1_silencer");
		}
	}
	
	public bool IsShotgun()
	{
		char className[128];
		this.GetWeaponClass(className, sizeof(className));
		if (StrEqual(className, "weapon_nova") || StrEqual(className, "weapon_xm1014") || StrEqual(className, "weapon_sawedoff"))
			return true;
		else
			return false;
	}
	
	public bool IsValidWeapon()
	{
		if (this.IsValidEntity())
		{
			char classname[128];
			this.GetWeaponClass(classname, sizeof(classname));
			
			if (StrContains(classname, "weapon_") != -1)
				return true;
		}
		
		return false;
	}
	
	public int GetAmmo()
	{
		return this.GetProperty("m_iPrimaryReserveAmmoCount");
	}
	
	public void SetAmmo(int ammo)
	{
		this.SetProperty("m_iPrimaryReserveAmmoCount", ammo);
	}
	
	property float NextPrimaryAttack {
		public get() {
			return this.GetPropertyFloat("m_flNextPrimaryAttack");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_flNextPrimaryAttack", value);
		}
	}
	
	property float NextSecondaryAttack {
		public get() {
			return this.GetPropertyFloat("m_flNextSecondaryAttack");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_flNextSecondaryAttack", value);
		}
	}
	
	property float TimeWeaponIdle {
		public get() {
			return this.GetPropertyFloat("m_flTimeWeaponIdle");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_flTimeWeaponIdle", value);
		}
	}
	
	property float PlaybackRate {
		public get() {
			return this.GetPropertyFloat("m_flPlaybackRate");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_flPlaybackRate", value);
		}
	}
	
	property bool IsReload {
		public get() {
			return view_as<bool>(this.GetDataProperty("m_bInReload"));
		}
		
		public set(bool value) {
			this.SetDataProperty("m_bInReload", value);
		}
	}
	
	property int Clip {
		public get() {
			return this.GetProperty("m_iClip1");
		}
		
		public set(int value) {
			this.SetProperty("m_iClip1", value);
		}
	}
	
	property int Ammo {
		public get() {
			return this.GetProperty("m_iPrimaryReserveAmmoCount");
		}
		
		public set(int value) {
			this.SetProperty("m_iPrimaryReserveAmmoCount", value);
		}
	}
	
	property int ReloadState {
		public get() {
			return this.GetProperty("m_reloadState");
		}
		
		public set(int value) {
			return this.SetProperty("m_reloadState", value);
		}
	}
	
	property float AccuracyPenalty {
		public get() {
			return this.GetPropertyFloat("m_fAccuracyPenalty");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_fAccuracyPenalty", value);
		}
	}
	
	public int GetDefaultAmmo()
	{
		KeyValues weaponData = manager.GetDataSet(WeaponDataSet);
		char weaponClass[128];
		char buffer[256];
		
		this.GetWeaponClass(weaponClass, sizeof(weaponClass));
		Format(buffer, sizeof(buffer), "%s_ammo", weaponClass);
		
		return weaponData.GetNum(buffer, INVALID_INDEX);
	}
	
	public int GetClipSize()
	{
		KeyValues weaponData = manager.GetDataSet(WeaponDataSet);
		char weaponClass[128];
		char buffer[256];
		
		this.GetWeaponClass(weaponClass, sizeof(weaponClass));
		Format(buffer, sizeof(buffer), "%s_clip", weaponClass);
		
		return weaponData.GetNum(buffer, INVALID_INDEX);
	}
	
	public void SetDefaultValues()
	{
		int defaultAmmo = this.GetDefaultAmmo();
		int defaultClip = this.GetClipSize();
		
		if (defaultAmmo != INVALID_INDEX)
			this.SetAmmo(defaultAmmo);
			
		if (defaultClip != INVALID_INDEX)
			this.Clip = defaultClip;
	}
};