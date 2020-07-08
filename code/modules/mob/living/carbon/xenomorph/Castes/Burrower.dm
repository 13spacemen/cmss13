//burrower is COMBAT support
/datum/caste_datum/burrower
	caste_name = "Burrower"
	tier = 2

	melee_damage_lower = XENO_DAMAGE_TIER_2
	melee_damage_upper = XENO_DAMAGE_TIER_3
	max_health = XENO_HEALTH_TIER_5
	plasma_gain = XENO_PLASMA_GAIN_HIGH
	plasma_max = XENO_PLASMA_TIER_4
	crystal_max = XENO_CRYSTAL_LOW
	xeno_explosion_resistance = XENO_HEAVY_EXPLOSIVE_ARMOR
	armor_deflection = XENO_ARMOR_TIER_3
	armor_hardiness_mult = XENO_ARMOR_FACTOR_VERYHIGH
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_4

	deevolves_to = "Drone"
	caste_desc = "A digger and trapper."
	acid_level = 2
	weed_level = 1
	evolution_allowed = FALSE
	tacklemin = 4
	tacklemax = 5
	tackle_chance = 50
	burrow_cooldown = 20
	tunnel_cooldown = 70
	widen_cooldown = 70
	tremor_cooldown = 450

/mob/living/carbon/Xenomorph/Burrower
	caste_name = "Burrower"
	name = "Burrower"
	desc = "A beefy, alien with sharp claws."
	icon = 'icons/mob/xenos/burrower.dmi'
	icon_size = 64
	icon_state = "Burrower Walking"
	layer = MOB_LAYER
	plasma_stored = 100
	plasma_types = list(PLASMA_PURPLE)
	pixel_x = -12
	old_x = -12
	tier = 2
	actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/onclick/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/place_construction,
		/datum/action/xeno_action/onclick/plant_weeds,
		/datum/action/xeno_action/activable/corrosive_acid,
		/datum/action/xeno_action/activable/burrow,
		/datum/action/xeno_action/onclick/build_tunnel,
		/datum/action/xeno_action/onclick/place_trap
		)
	inherent_verbs = list(
		/mob/living/carbon/Xenomorph/proc/vent_crawl,
		/mob/living/carbon/Xenomorph/proc/rename_tunnel,
		)
	mutation_type = BURROWER_NORMAL

/mob/living/carbon/Xenomorph/Burrower/New()
	. = ..()
	sight |= SEE_TURFS

/mob/living/carbon/Xenomorph/Burrower/update_canmove()
	. = ..()
	if(burrow)
		density = FALSE
		canmove = FALSE
		return canmove

/mob/living/carbon/Xenomorph/Burrower/ex_act(severity)
	if(burrow)
		return
	..()

/mob/living/carbon/Xenomorph/Burrower/attack_hand()
	if(burrow)
		return
	..()

/mob/living/carbon/Xenomorph/Burrower/attackby()
	if(burrow)
		return
	..()

/mob/living/carbon/Xenomorph/Burrower/get_projectile_hit_chance()
	. = ..()
	if(burrow)
		return 0

/mob/living/carbon/Xenomorph/Burrower/update_icons()
	if (stat == DEAD)
		icon_state = "[mutation_type] Burrower Dead"
	else if (lying)
		if ((resting || sleeping) && (!knocked_down && !knocked_out && health > 0))
			icon_state = "[mutation_type] Burrower Sleeping"
		else
			icon_state = "[mutation_type] Burrower Knocked Down"
	else if (burrow)
		icon_state = "[mutation_type] Burrower Burrowed"
	else
		icon_state = "[mutation_type] Burrower Running"

	update_fire() //the fire overlay depends on the xeno's stance, so we must update it.
