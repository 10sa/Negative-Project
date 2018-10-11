#define NameBufferLength 		128
#define ClassBufferLength 		64
#define DataPathBufferLength	256

#define DefaultBotMinLevel		1
#define DefaultBotMaxLevel		6

#define DefaultBotAmount		15
#define MaxUserCount			10
#define MaxPlayersCount			64

#define SoundTrackVersion		"th06_v1"

#define BotDefaultHp			100
#define BotDefaultBonusHp 		0.0

#define BotDefaultAp			100
#define BotDefaultBonusAp		0.0

#define BotDefaultExp			10
#define BotDefaultBonusExp		0.1

#define BotDefaultCash			5
#define BotDefaultBonusCash		0.1

#define BotDefaultFireRate		1.0
#define BotDefaultBonusFireRate 0.0

// 봇 공격 틱 딜레이 (4틱 마다 1번씩 공격을 갱신)
#define BotKnifeAttackTick		4
#define BotKnifeAttackDistance	90.0

// 너무 빠르면 버그 생김. (0.45로 제한) //
#define BotLimitFireRate		0.45

#define BotDefaultMs 			0.0
#define BotDefaultBonusMs 		0.0

#define BotDefaultViewAngle		90.0
#define BotDefaultReactionTime	1.0

#define BotDefaultArmorType		0
#define BotDefaultSpawn			true

#define DefaultPath				"addons/sourcemod/data/nt/%s"
#define PlayerDataPath 			"addons/sourcemod/data/nt/player_data/%s.txt"
#define MapDataPath				"map_data/%s.txt"
#define BotTeamDataPath			"bot_data/bot_teams/%s.txt"

#define SoundDefaultPath		"projectalpha/%d"

#define Map_de					"de_"
#define Map_cs					"cs_"

#define DefaultTObject 			"C4를 설치하여 폭파하거나 모든 적을 섬멸"
#define DefaultCTObject 		"인질을 구출하거나 모든 적을 섬멸"

#define DefaultUserTeamName 	"Negative Project"
#define CashName				"CS"
#define NULL_ARG				_

#define REAL_TEAM_CT			2
#define REAL_TEAM_T				1

// Kv Key //
#define DefaultKey				"default"

#define BotDataDamageKv			"kDamage"
#define BotDataDamageKvDamage	"iDamage"
#define BotDataDamageKvAttacker	"iAttacker"
#define BotDataGunBot			"bIsGunBot"
#define BotDataNamed			"bIsNamed"
#define BotDataViewAngle		"fViewAngle"
#define BotDataReactionTime		"fReactionTime"
#define BotDataReactionWait		"fReactionWait"

#define BotDataHp				"iHp"
#define BotDataAp				"iAp"
#define BotDataExp				"iExp"
#define BotDataCash				"iCash"
#define BotDataMs				"fMs"
#define BotDataFireRate			"fFireRate"

#define BotDataLevelHpBonus		"fLevelHpBonus"
#define BotDataLevelApBonus		"fLevelApBonus"
#define BotDataLevelMsBonus		"fLevelMsBonus"
#define BotDataLevelExpBonus	"fLevelExpBonus"
#define BotDataLevelCashBonus	"fLevelCashBonus"
#define BotDataLevelFireRateBonus	"fLevelFireRateBonus"

#define BotDataRealFireRate		"fRealFireRate"
#define BotDataRealHp			"iRealHp"
#define BotDataRealAp			"iRealAp"
#define BotDataRealExp			"iRealExp"
#define BotDataRealCash			"iRealCash"
#define BotDataRealMs			"fRealMs"
#define BotDataArmorType		"iArmorType"
#define BotDataClanTag			"sClanTag"
#define BotDataLevelWeapons		"LevelWeapons"
#define BotDataUseWeapon		"sUseWeapon"
#define BotDataInfAmmo			"bInfAmmo"
#define BotDataRunTick			"iRunTick"
#define BotDataExtendSound		"kSounds"
#define BotDataUniqueID			"sUniqueID"
#define BotDataModel			"sModel"
#define BotDataRamdomModels		"kRamdomModels"
#define BotDataMaxRamdomModels	"iMaxRamdomValue"

#define BotDataColorKv			"kColor"
#define BotDataColorRed			"iRed"
#define BotDataColorGreen		"iGreen"
#define BotDataColorBlue		"iBlue"
#define BotDataColorAlpha		"iAlpha"

#define BotNameFormat			"\"Zombie %d\""

#define PlayerDataLevel			"iLevel"
#define PlayerDataExp			"iExp"
#define PlayerDataCash			"iCash"
#define PlayerDataSkillPoint	"iSkillPoint"
#define PlayerDataStetPoint		"iStetPoint"
#define PlayerDataAttributeKv	"kAttribute"
#define PlayerDataAttributeHealth	"iHealth"
#define PlayerDataAttributePower	"iPower"
#define PlayerDataAttributeSpeed	"iSpeed"
#define PlayerDataSkillKv			"kSkills"
#define PlayerDataSkillUseSp	"iUseSkillPoint"
#define PlayerDataSkillUseCash	"iUseCash"
#define PlayerDataSkillLevel	"iSkillLevel"
#define PlayerDataInventoryKv	"kInventory"
#define PlayerDataEquipmentKv	"kEquipment"
#define PlayerDataEquipmentClass	"sClassName"
#define PlayerDataEquipmentItemData	"kItemData"

#define PlayerDataSettings	"kSettings"

#define PlayerTempDataDamageLog	"iDamageLog"
#define PlayerTempDataMaxHealth	"iMaxHealth"

#define ExpTableStartExp		"iStartExp"

#define MapDataMapDataPath		"sMapDataPath"
#define MapDataUserTeam			"iUserTeam"
#define MapDataEnemyTeam		"iEnemyTeam"
#define MapDataTeamName			"sTeamName"
#define MapDataTeamDataPath		"sTeamPath"
#define MapDataMinGameLevel 	"iMinGameLevel"
#define MapDataMaxGameLevel		"iMaxGameLevel"
#define MapDataEnemyTeamInfo	"kEmenyTeamInfo"
#define MapDataFriendTeamInfo	"kFriendTeamInfo"
#define MapDataSelectEnemyTeam	"sSelectEnemyTeam"
#define MapDataSelectFriendTeam	"sSelectFriendTeam"
#define MapDataMapSpawnPoints	"kMapSpawnPoints"
#define MapDataMapSpawnPointPos	"vPos"
#define MapDataMapSpawnPointCreater	"sCreater"
#define MapDataLevelTeams		"LevelTeams"
#define MapDataMapObjectPrefix	"MapObjectPrefix"
#define MapDataMapSounds		"kMapSounds"

#define MapDataLastEnemyTeamName	"sLastEnemyTeamName"
#define MapDataLastFriendTeamName	"sLastFriendTeamName"

#define TeamDataEnemyTeam		"kEnemyTeam"
#define TeamDataFriendTeam		"kFriendTeam"
#define TeamDataIsSelectableTeam	"bIsSelectable"
#define TeamDataTeamName		"sTeamName"
#define TeamDataPath			"sPath"
#define TeamDataLastEnemyTeamName	"sLastEmenyTeamName"
#define TeamDataLastFriendTeamName	"sLastFriendTeamName"

#define TeamListDefaultBot		"bDefaultBots"

#define WeaponDataNormalKnifeDamage	"weapon_knife_prefix_1"
#define WeaponDataPowerKnifeDamage	"weapon_knife_prefix_2"
#define WeaponDataHeadshotDamage	"%s_headshot"
#define WeaponDataDefaultAmmo	"%s_ammo"

#define MenuControlKeyStet	"Stet"
#define MenuControlKeySkill	"Skill"
#define MenuControlKeyInventory	"Inventory"
#define MenuControlKeyEquipments	"Equipments"
#define MenuControlKeySettings	"Settings"
#define MenuControlKeyGroup		"Group"

#define StetMenuHealth	"Health"
#define StetMenuPower	"Power"
#define StetMenuSpeed	"Speed"

#define StetAddHealth	5
#define StetAddPower	0.5
#define StetAddSpeed	0.5

#define LevelUpStetPointAdd	1
#define LevelUpSkillPointAdd	10

#define PlayerDefaultHp	100
#define PlayerDefaultSpeed	100.0
#define PlayerDataDefaultPower	100.0
#define HealthTargetRange	100.0

#define SkillDataMaxLevel	"iMaxLevel"
#define SkillDataCallType	"sCalltype"
#define SkillDataFunction	"fFunction"
#define SklllDataCost	"iCost"
#define SkillDataSpCost	"iSp"
#define SkillDataLevelCost	"iLevelCashCost"
#define SkillDataDesc	"sDesc"
#define SkillDataDescEx	"sDescEx"
#define SkillDataRequest	"kRequestInfo"
#define SkillDataLevel	"iLevel"
#define SkillDataFunctionFormat "sFunctionFormat"
#define SkillDataNotifyPrefix	"sNotifyPrefix"

#define SkillNotifyDefaultPrefix	"Skills"
#define SkillNotifyUserPrefix	"User Skill"
#define SkillNotifyBotPrefix	"Bot Skill"

#define BotSkillFunction "BotSkillFunction_%s"
#define SkillFunctionFormat	"SkillFunction_%s"

#define SkillDataCalltype_Spawn	"player_spawn"
#define SkillDataCalltype_Attack	"player_attack"
#define SkillDataCalltype_WeaponBuy	"weapon_buy"
#define SkillDataCalltype_FlashBlind	"flash_blind"

#define BotSkillDataCallType_PlayerKill		"player_kill"

#define SkillLevelUp	"스킬 레벨을 올린다"

#define SettingDataMenuItem	"kSettingMenuItems"
#define SettingDataSettingKey	"sSettingKey"
#define SettingDataVarType	"iVarType"
#define SettingRefresh	"sRefresh"
#define SettingDefault	"Default"

#define ItemDataName	"sName"
#define ItemDataDesc	"sDesc"
#define ItemDataEquipable	"bIsEquipable"
#define ItemDataFormatKv	"kItemData"
#define ItemDataEquipmentSlot	"sEquipmentSlot"
#define ItemDataDescFormatItem	"iDescFormatItem"
#define ItemDataItemCount	"iItemCount"
#define ItemDataEquipItemData	"kItemData"
#define ItemDataFunction	"fFunction"
#define ItemDataCalltype	"sCalltype"
#define ItemDataCreateFormat	"kItemCreateFormat"
#define ItemDataCreateType	"iType"
#define ItemDataCraeteFloatMin	"fMin"
#define ItemDataCraeteFloatMax	"fMax"
#define ItemDataCraeteIsNegative	"bIsNegativeChance"
#define ItemDataCreateChance	"iChance"

#define ItemMenuKeyEquip	"Equip"
#define ItemMenuKeyDrop		"Drop"
#define ItemMenuKeyDropAll	"DropAll"

#define ITypeInt	1
#define ITypeFloat	2
#define ITypeString	3

#define RoundStatusPlaying	1
#define RoundStatusFreeze	2
#define RoundStatusEnd		3
