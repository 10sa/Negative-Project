#define Player_SaveVars "_SaveData_"
#define Player_SteamID "_SteamID_"

#define Player_SaveVar_Exp "iExp"
#define Player_SaveVar_Cash "iCash"

StringMap PlayerData[MAXPLAYERS];

methodmap Player < Entity {

	public Player(int client)
	{
		StringMap clientMap = new StringMap();
		clientMap.SetValue(Player_SaveVars, new KeyValues("Player_Data")); // 저장용 Kv
		clientMap.SetValue(Player_SteamID, GetSteamAccountID(client)); // FakeClient 는 0으로 처리하는지 모르겠음
		
		PlayerData[client] = clientMap;
		
		return view_as<Player>(client);
	}
	
	public any GetMember(const char[] name, any def=0)
	{
		any member;
		if (PlayerData[this].GetValue(name, member))
			return member;
		else
			return def;
	}
	
	public int GetSteamAccountID()
	{
		return this.GetMember(Player_SteamID);
	}

	public KeyValues GetSaveVars()
	{
		return this.GetMember(Player_SaveVars);
	}
	
	public any GetSaveVar(const char[] name, any def)
	{
		return this.GetSaveVars().GetNum(name, def);
	}
	
	public bool IsValid()
	{
		if (this.IsValidEntity() && this.GetEntity() > 0)
		{
			int entity = this.GetEntity();
			
			return IsClientInGame(entity) && entity > 0;
		}
		else
			return false;
	}
	
	public bool IsAlive()
	{
		return IsPlayerAlive(this.GetEntity());
	}
	
	public bool IsBot() {
		if (this.IsValid())
			return IsFakeClient(this.GetEntity());
		else
			return false;
	}
	
	public void GetArrayMember(const char[] name, any[] value, int length)
	{
		PlayerData[this].GetArray(name, value, length);
	}
	
	public void GetStringMember(const char[] name, char[] value, int length)
	{
		PlayerData[this].GetString(name, value, length);
	}
	
	public KeyValues GetProfile()
	{
		if (this.IsBot())
			return view_as<KeyValues>(this.GetMember(BotProfile));
		else
			return view_as<KeyValues>(this.GetSaveVars());
	}
	
	public KeyValues GetSkill(const char[] skillName)
	{
		KeyValues profile = this.GetProfile();
		
		if (profile.JumpToKey(Profile_Skills))
		{
			if (profile.JumpToKey(skillName))
			{
				KeyValues skillData = new KeyValues("");
				skillData.Import(profile);
				
				profile.Rewind();
				return skillData;
			}
		}
		
		profile.Rewind();
		return null;
	}
	
	public KeyValues GetSkills()
	{
		KeyValues profile = this.GetProfile();
		KeyValues skillData = new KeyValues("");
		
		if (profile.JumpToKey(Profile_Skills))
		{
			skillData.Import(profile);
			profile.Rewind();
		}
		
		return skillData;
	}
	
	public void SetMember(const char[] name, any value)
	{
		PlayerData[this].SetValue(name, value);
	}
	
	public void SetArrayMember(const char[] name, any[] value, int length)
	{
		PlayerData[this].SetArray(name, value, length); // 길이 정보는 저장하지 않음.
	}
	
	public void SetStringMember(const char[] name, char[] value)
	{
		PlayerData[this].SetString(name, value);
	}
	
	public void SetSaveVar(const char[] name, any value)
	{
		this.GetSaveVars().SetNum(name, value);
	}
	
	public void SetSaveString(const char[] name, char[] value)
	{
		this.GetSaveVars().SetString(name, value);
	}
	
	public bool SetPlayerProp(const char[] name, any value)
	{
		if (HasEntProp(this.GetEntity(), Prop_Send, name))
			SetEntProp(this.GetEntity(), Prop_Send, name, value);
		else
			return false;
			
		return true;
	}
	
	public bool SetPlayerPropFloat(const char[] name, float value)
	{
		if (HasEntProp(this.GetEntity(), Prop_Send, name))
			SetEntPropFloat(this.GetEntity(), Prop_Send, name, value);
		else
			return false;
			
		return true;
	}
	
	public void SetRenderColor(int[] color)
	{
		SetEntityRenderColor(this.GetEntity(), color[0], color[1], color[2], 255);
	}
	
	public bool Save()
	{
		char path[256];
		Format(path, sizeof(path), "addons/sourcemod/data/rpg/players/%d.db", this.GetMember(Player_SteamID));
		return this.GetSaveVars().ExportToFile(path);
	}
	
	public bool Load()
	{
		char path[256];
		Format(path, sizeof(path), "addons/sourcemod/data/rpg/players/%d.db", this.GetMember(Player_SteamID));
		return this.GetSaveVars().ImportFromFile(path);
	}
	
	public void Dispose(bool isSave = false)
	{
		if (isSave)
			this.Save();
			
		CloseHandle(PlayerData[this]);
	}
	
	public void GetName(char[] buffer, int length)
	{
		GetClientName(this.GetEntity(), buffer, length);
	}
	
	public void GetClientAbsOrigin(float vec[3])
	{
		GetClientAbsOrigin(this.GetEntity(), vec);
	}
	
	public int GetClientTeam()
	{
		return GetClientTeam(this.GetEntity());
	}

	public Entity GetActiveWeapon()
	{
		return this.GetPropertyEnt("m_hActiveWeapon");
	}
	
	property int Health {
		public get() {
			return GetClientHealth(this.GetEntity());
		}
		
		public set(int value) {
			SetEntityHealth(this.GetEntity(), value);
		}
	}
	
	property int Team {
		public get() {
			return GetClientTeam(this.GetEntity());
		}
	}
	
	property float Movespeed {
		public get() {
			return this.GetPropertyFloat("m_flLaggedMovementValue");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_flLaggedMovementValue", value);
		}
	}
	
	property float NextAttack {
		public get() {
			return this.GetPropertyFloat("m_flNextAttack");
		}
		
		public set(float value) {
			this.SetPropertyFloat("m_flNextAttack", value);
		}
	}
	
	property Entity ViewModel {
		public get() {
			return this.GetPropertyEnt("m_hViewModel");
		}
		
		public set(Entity value) {
			this.SetPropertyEnt("m_hViewModel", value.GetEntity())
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
	
	property float ViewModelPlaybackRate {
		public get() {
			return this.ViewModel.GetPropertyFloat("m_flPlaybackRate");
		}
		
		public set(float value) {
			this.ViewModel.SetPropertyFloat("m_flPlaybackRate", value);
		}
	}
	
	property int Money {
		public get() {
			return this.GetProperty("m_iAccount");
		}
		
		public set(int value) {
			return this.SetProperty("m_iAccount", value);
		}
	}
	
	public void ResetViewModel()
	{
		this.ViewModelPlaybackRate = 1.0;
	}
	
	public void GiveExp(int exp)
	{
		if (exp > 0)
		{
			int playerExp = this.GetSaveVar(Player_SaveVar_Exp, 0) + exp;
			this.SetSaveVar(Player_SaveVar_Exp, playerExp);
		}
	}
	
	public void GiveCash(int cash)
	{
		if (cash > 0)
		{
			int playerCash = this.GetSaveVar(Player_SaveVar_Cash, 0) + cash;
			this.SetSaveVar(Player_SaveVar_Cash, playerCash);
		}
	}
	
	public void TakeExp(int exp)
	{
		if (exp > 0)
		{
			int playerExp = this.GetSaveVar(Player_SaveVar_Exp, 0) - exp;
			this.SetSaveVar(Player_SaveVar_Exp, playerExp);
		}
	}
	
	public void TakeCash(int cash)
	{
		if (cash > 0)
		{
			int playerCash = this.GetSaveVar(Player_SaveVar_Cash, 0) - cash;
			this.SetSaveVar(Player_SaveVar_Cash, playerCash);
		}
	}
	
	public bool IsSameTeam(Player player)
	{
		return player.Team == this.Team ? true : false;
	}
};