methodmap Entity __nullable__ {
	public Entity(int entityIndex)
	{
		return view_as<Entity>(entityIndex);
	}
	
	public int GetEntity()
	{
		return view_as<int>(this);
	}
	
	public void SetProperty(const char[] name, int value)
	{
		SetEntProp(this.GetEntity(), Prop_Send, name, value);
	}
	
	public void SetDataProperty(const char[] name, int value)
	{
		SetEntProp(this.GetEntity(), Prop_Data, name, value);
	}
	
	public float SetPropertyFloat(const char[] name, float value)
	{
		SetEntPropFloat(this.GetEntity(), Prop_Send, name, value);
	}
	
	public void SetPropertyEnt(const char[] name, int value)
	{
		SetEntPropEnt(this.GetEntity(), Prop_Send, name, value);
	}
	
	public bool IsValidEntity()
	{
		return IsValidEntity(this.GetEntity()) && IsValidEdict(this.GetEntity());
	}
	
	public int GetProperty(const char[] name)
	{
		return GetEntProp(this.GetEntity(), Prop_Send, name);
	}
	
	public float GetPropertyFloat(const char[] name)
	{
		return GetEntPropFloat(this.GetEntity(), Prop_Send, name);
	}
	
	public int GetDataProperty(const char[] name)
	{
		return GetEntProp(this.GetEntity(), Prop_Data, name);
	}
	
	public void GetPropertyVector(const char[] name, float vector[3])
	{
		GetEntPropVector(this.GetEntity(), Prop_Send, name, vector);
	}
	
	public Entity GetPropertyEnt(const char[] name)
	{
		return view_as<Entity>(GetEntPropEnt(this.GetEntity(), Prop_Send, name));
	}
	
	public bool DispatchKeyValue(const char[] keyName, const char[] value)
	{
		return DispatchKeyValue(this.GetEntity(), keyName, value);
	}
	
	public bool DispatchSpawn()
	{
		return DispatchSpawn(this.GetEntity());
	}
	
	public void TeleportEntity(const float origin[3], const float angles[3], const float velocity[3])
	{
		TeleportEntity(this.GetEntity(), origin, angles, velocity);
	}
	
	public bool AcceptEntityInput(const char[] input, int activator=-1, int caller=-1, int outputid=0)
	{
		return AcceptEntityInput(this.GetEntity(), input, activator, caller, outputid);
	}
	
	public int GetOwner()
	{
		if (HasEntProp(this.GetEntity(), Prop_Send, "m_hOwner"))
			return GetEntPropEnt(this.GetEntity(), Prop_Send, "m_hOwner");
		else
			return INVALID_INDEX;
	}
	
	public void GetClass(char[] buffer, int length)
	{
		GetEntityClassname(this.GetEntity(), buffer, length);
	}
};