int 		iGameLevel							= -1;
int 		iRound								= -1;
int			iBotCount							= -1;
int			iRoundStatus						= 1;
// int			iPlayerCount						= -1; // 아마도 사용 안할듯.

// Player Data
KeyValues 	hPlayerData[MAXPLAYERS]				= null;
KeyValues	hPlayerTempData[MAXPLAYERS]			= null;
KeyValues	hExpTable							= null;
KeyValues	hPlayerDataTemplate;

// Map Data
KeyValues	hMapData							= null;
KeyValues	hTeamData							= null;

// Bots
KeyValues 	hBotData[MAXPLAYERS]				= null;
KeyValues	hBotProfile							= null;

// Game Data
KeyValues	hWeaponData							= null;
KeyValues	hSkillData							= null;
KeyValues 	hBotSkillData						= null;
KeyValues	hSettingsData						= null;
KeyValues	hItemClassData						= null;
KeyValues	hEquipmentSlotData					= null;
KeyValues	hServerTips							= null;

char	sPlayingMusic[128];