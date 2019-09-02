/datum/caste_datum/runner
	caste_name = "Runner"
	upgrade_name = "Young"
	caste_desc = "A fast, four-legged terror, but weak in sustained combat."
	tier = 1
	upgrade = 0
	melee_damage_lower = XENO_DAMAGE_LOW
	melee_damage_upper = XENO_DAMAGE_LOWPLUS
	plasma_gain = XENO_PLASMA_GAIN_LOW
	plasma_max = XENO_PLASMA_LOWMEDIUM
	armor_deflection = XENO_NO_ARMOR
	max_health = XENO_HEALTH_LOWMEDIUM
	armor_hardiness_mult = XENO_ARMOR_FACTOR_LOW
	evasion = XENO_EVASION_HIGH
	speed = XENO_SPEED_SANICFAST
	speed_mod = XENO_SPEED_MOD_LARGE
	charge_type = 1 //Pounce - Runner
	attack_delay = -4
	evolves_to = list("Lurker")
	deevolves_to = "Larva"
	pounce_delay = 35
	xeno_explosion_resistance = XENO_LOW_EXPLOSIVE_ARMOR

/datum/caste_datum/runner/mature
	upgrade_name = "Mature"
	caste_desc = "A fast, four-legged terror, but weak in sustained combat. It looks a little more dangerous."
	upgrade = 1

/datum/caste_datum/runner/elder
	upgrade_name = "Elder"
	caste_desc = "A fast, four-legged terror, but weak in sustained combat. It looks pretty strong."
	upgrade = 2
	tacklemin = 3
	tacklemax = 4
	tackle_chance = 40
	pounce_delay = 30

/datum/caste_datum/runner/ancient
	upgrade_name = "Ancient"
	caste_desc = "Not what you want to run into in a dark alley. It looks fucking deadly."
	upgrade = 3
	tacklemin = 3
	tacklemax = 4
	tackle_chance = 45
	pounce_delay = 25

/mob/living/carbon/Xenomorph/Runner
	caste_name = "Runner"
	name = "Runner"
	desc = "A small red alien that looks like it could run fairly quickly..."
	icon = 'icons/mob/xenos/xenomorph_64x64.dmi' //They are now like, 2x1 or something
	icon_state = "Runner Walking"
	plasma_types = list(PLASMA_CATECHOLAMINE)
	flags_pass = PASSTABLE
	tier = 1
	pixel_x = -16  //Needed for 2x2
	old_x = -16
	pull_speed = -1
	viewsize = 8 // runner scouting, can look 3 tiles (2 offset + 1 increased size) ahead when stationary
	tileoffset = 2

	actions = list(
		/datum/action/xeno_action/xeno_resting,
		/datum/action/xeno_action/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/xenohide,
		/datum/action/xeno_action/activable/pounce,
		/datum/action/xeno_action/toggle_long_range/runner,
		)
	inherent_verbs = list(
		/mob/living/carbon/Xenomorph/proc/vent_crawl,
		)
	mutation_type = RUNNER_NORMAL
