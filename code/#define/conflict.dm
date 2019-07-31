//Grab levels
#define GRAB_PASSIVE	0
#define GRAB_AGGRESSIVE	1
#define GRAB_NECK		2
#define GRAB_KILL		3

//Ammo defines for gun/projectile related things.
#define AMMO_EXPLOSIVE 			1
#define AMMO_XENO_ACID 			2
#define AMMO_XENO_TOX			4
#define AMMO_ENERGY 			8
#define AMMO_ROCKET				16
#define AMMO_SNIPER				32
#define AMMO_INCENDIARY			64
#define AMMO_ANTISTRUCT         128 // Primarily for railgun but can be implemented for other projectiles that are for antitank and antistructure (wall/machine)
#define AMMO_SKIPS_HUMANS		256
#define AMMO_SKIPS_ALIENS 		512
#define AMMO_IS_SILENCED 		1024 //Unused right now.
#define AMMO_IGNORE_ARMOR		2048
#define AMMO_IGNORE_RESIST		4096
#define AMMO_BALLISTIC			8192
#define AMMO_IGNORE_COVER		16384
#define AMMO_SCANS_NEARBY		32768 //ammo that is scanning stuff nearby - VERY resource intensive
#define AMMO_STOPPED_BY_COVER	65536

//Gun defines for gun related thing. More in the projectile folder.
#define GUN_CAN_POINTBLANK		1
#define GUN_TRIGGER_SAFETY		2
#define GUN_UNUSUAL_DESIGN		4
#define GUN_SILENCED			8
#define GUN_AUTOMATIC			16
#define GUN_INTERNAL_MAG		32
#define GUN_AUTO_EJECTOR		64
#define GUN_AMMO_COUNTER		128
#define GUN_BURST_ON			256
#define GUN_BURST_FIRING		512
#define GUN_FLASHLIGHT_ON		1024
#define GUN_WY_RESTRICTED		2048
#define GUN_SPECIALIST			4096
#define GUN_WIELDED_FIRING_ONLY	8192
#define GUN_HAS_FULL_AUTO		16384
#define GUN_FULL_AUTO_ON		32768
#define GUN_ONE_HAND_WIELDED    65536 //removes one-hand accuracy penalty

//Gun attachable related flags.
#define ATTACH_REMOVABLE	1
#define ATTACH_ACTIVATION	2
#define ATTACH_PROJECTILE	4 //for attachments that fire bullets
#define ATTACH_RELOADABLE	8
#define ATTACH_WEAPON		16 //is a weapon that fires stuff

//Ammo magazine defines, for flags_magazine
#define AMMUNITION_REFILLABLE	1
#define AMMUNITION_HANDFUL		2

//Slowdown from various armors.
#define SHOES_SLOWDOWN -1.0			// How much shoes slow you down by default. Negative values speed you up

#define SLOWDOWN_ARMOR_VERY_LIGHT	0.20
#define SLOWDOWN_ARMOR_LIGHT		0.35
#define SLOWDOWN_ARMOR_MEDIUM		0.55
#define SLOWDOWN_ARMOR_HEAVY		1
#define SLOWDOWN_ARMOR_HEAVIER		1.10
#define SLOWDOWN_ARMOR_VERY_HEAVY	1.15

#define SLOWDOWN_ADS_SHOTGUN		0.75
#define SLOWDOWN_ADS_RIFLE			0.75 //anything below that doesn't change anything.
#define SLOWDOWN_ADS_SCOPE			1
#define SLOWDOWN_ADS_INCINERATOR	1.75
#define SLOWDOWN_ADS_SPECIALIST		1.75
#define SLOWDOWN_ADS_SUPERWEAPON	2.75

//Wield delays, in milliseconds. 10 is 1 second
#define WIELD_DELAY_VERY_FAST		2
#define WIELD_DELAY_FAST			4
#define WIELD_DELAY_NORMAL			6
#define WIELD_DELAY_SLOW			8
#define WIELD_DELAY_VERY_SLOW		10
#define WIELD_DELAY_HORRIBLE		12

//Explosion level thresholds. Upper bounds
#define EXPLOSION_THRESHOLD_LOW		100
#define EXPLOSION_THRESHOLD_MLOW	150
#define EXPLOSION_THRESHOLD_MEDIUM	200
#define EXPLOSION_THRESHOLD_HIGH	300

#define EXPLOSION_THRESHOLD_GIB		200 //how much it takes to gib a mob
#define EXPLOSION_PRONE_MULTIPLIER	0.5 //prone mobs recieve less damage from explosions

//Explosion damage multipliers for different objects
#define EXPLOSION_DAMAGE_MULTIPLIER_AIRLOCK     2.5
#define EXPLOSION_DAMAGE_MULTIPLIER_WALL		5
#define EXPLOSION_DAMAGE_MULTIPLIER_WINDOW		10

//Projectile block probabilities for different types of cover
#define PROJECTILE_COVERAGE_LOW			35
#define PROJECTILE_COVERAGE_MEDIUM		60
#define PROJECTILE_COVERAGE_HIGH		85
//=================================================

#define FALLOFF_PER_TILE 0.01 //1 % per 1 tile per 1 normalcy
#define FALLOFF_DISTANCE_POWER 1.4

#define ARMOR_MELEE 1
#define ARMOR_BULLET 2
#define ARMOR_LASER 4
#define ARMOR_ENERGY 8
#define ARMOR_BOMB 16
#define ARMOR_BIO 32
#define ARMOR_RAD 64
#define ARMOR_INTERNALDAMAGE 128

#define ARMOR_SHARP_INTERNAL_PENETRATION 10

// Related to damage that ANTISTRUCT ammo types deal to structures
#define ANTISTRUCT_DMG_MULT_BARRICADES 1.45
#define ANTISTRUCT_DMG_MULT_WALL 2.5
#define ANTISTRUCT_DMG_MULT_TANK 1.5

// human armor
#define CLOTHING_ARMOR_NONE 0
#define CLOTHING_ARMOR_LOW 10
#define CLOTHING_ARMOR_MEDIUMLOW 15
#define CLOTHING_ARMOR_MEDIUM 20
#define CLOTHING_ARMOR_MEDIUMHIGH 25
#define CLOTHING_ARMOR_HIGH 30
#define CLOTHING_ARMOR_HIGHPLUS 35
#define CLOTHING_ARMOR_VERYHIGH 40
#define CLOTHING_ARMOR_ULTRAHIGH 50
#define CLOTHING_ARMOR_HARDCORE 100

//OB timings
#define OB_TRAVEL_TIMING 12 SECONDS
#define OB_CRASHING_DOWN 1 SECONDS