/datum/caste_datum/queen
	caste_name = "Queen"
	upgrade_name = "Young"
	tier = 0
	upgrade = 0

	melee_damage_lower = XENO_DAMAGE_MEDIUMLOW
	melee_damage_upper = XENO_DAMAGE_MEDIUMHIGH
	max_health = XENO_HEALTH_ULTRAHIGH
	plasma_gain = XENO_PLASMA_GAIN_HIGH
	plasma_max = XENO_PLASMA_VERYHIGH
	xeno_explosion_resistance = XENO_GIGA_EXPLOSIVE_ARMOR
	armor_deflection = XENO_MEDIUM_ARMOR
	armor_hardiness_mult = XENO_ARMOR_FACTOR_VERYHIGH
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_SLOW
	speed_mod = XENO_SPEED_MOD_LARGE

	tacklemin = 4
	tacklemax = 5
	tackle_chance = 40
	is_intelligent = 1
	evolution_allowed = FALSE
	fire_immune = 1
	aura_strength = 2 //The Queen's aura is strong and stays so, and gets devastating late game. Climbs by 1 to 5
	caste_desc = "The biggest and baddest xeno. The Queen controls the hive and plants eggs"
	spit_delay = 35
	spit_types = list(/datum/ammo/xeno/toxin/queen, /datum/ammo/xeno/acid/medium)
	can_hold_facehuggers = 0
	can_hold_eggs = CAN_HOLD_ONE_HAND
	can_denest_hosts = 1
	acid_level = 2
	weed_level = 3

	minimum_playtimes = list(
		FACTION_XENOMORPH = HOURS_9
	)

/datum/caste_datum/queen/mature
	upgrade_name = "Mature"
	caste_desc = "The biggest and baddest xeno. The Queen controls the hive and plants eggs."
	upgrade = 1

	spit_delay = 30
	tackle_chance = 45
	aura_strength = 3

/datum/caste_datum/queen/elder
	upgrade_name = "Elder"
	caste_desc = "The biggest and baddest xeno. The Empress controls multiple hives and planets."
	upgrade = 2

	spit_delay = 25
	tackle_chance = 50
	aura_strength = 4
	tacklemin = 5
	tacklemax = 6

/datum/caste_datum/queen/ancient
	upgrade_name = "Ancient"
	caste_desc = "The most perfect Xeno form imaginable."
	upgrade = 3

	spit_delay = 20
	tackle_chance = 55
	aura_strength = 5
	tacklemin = 6
	tacklemax = 7

/datum/caste_datum/queen/primordial
	upgrade_name = "Primordial"
	caste_desc = "Natural selection's masterwork, each brush stroke of genetics, deadly, each trait, glorious, every detail, minutely crafted. The perfect being, the perfect queen."
	upgrade = 4

	spit_delay = 10
	tackle_chance = 65
	aura_strength = 6
	tacklemin = 6
	tacklemax = 7

/proc/update_living_queens() // needed to update when you change a queen to a different hive
	outer_loop:
		for(var/datum/hive_status/hive in hive_datum)
			if(hive.living_xeno_queen)
				if(hive.living_xeno_queen.hivenumber == hive.hivenumber)
					continue
			for(var/mob/living/carbon/Xenomorph/Queen/Q in living_mob_list)
				if(Q.hivenumber == hive.hivenumber)
					hive.living_xeno_queen = Q
					xeno_message(SPAN_XENOANNOUNCE("A new Queen has risen to lead the Hive! Rejoice!"),3,hive.hivenumber)
					continue outer_loop
			hive.living_xeno_queen = null


/mob/living/carbon/Xenomorph/Queen
	caste_name = "Queen"
	name = "Queen"
	desc = "A huge, looming alien creature. The biggest and the baddest."
	icon = 'icons/mob/xenos/xenomorph_64x64.dmi'
	icon_size = 64
	var/icon_body = 'icons/mob/xenos/xenomorph_64x64.dmi'
	var/icon_ovi = 'icons/mob/xenos/Ovipositor.dmi'
	icon_state = "Queen Walking"
	plasma_types = list(PLASMA_ROYAL,PLASMA_CHITIN,PLASMA_PHEROMONE,PLASMA_NEUROTOXIN)
	attacktext = "bites"
	attack_sound = null
	friendly = "nuzzles"
	wall_smash = 0
	amount_grown = 0
	max_grown = 10
	pixel_x = -16
	old_x = -16
	mob_size = MOB_SIZE_BIG
	drag_delay = 6 //pulling a big dead xeno is hard
	tier = 0 //Queen doesn't count towards population limit.
	hive_pos = XENO_QUEEN

	var/map_view = 0
	var/breathing_counter = 0
	var/ovipositor = FALSE //whether the Queen is attached to an ovipositor
	var/ovipositor_cooldown = 0
	var/queen_ability_cooldown = 0
	var/egg_amount = 0 //amount of eggs inside the queen
	var/last_larva_time = 0
	var/screech_sound_effect = 'sound/voice/alien_queen_screech.ogg' //the noise the Queen makes when she screeches. Done this way for VV purposes.
	var/egg_planting_range = 3 // in ovipositor queen can plant egg up to this amount of tiles away from her position

	tileoffset = 0
	viewsize = 12

	actions = list(
		/datum/action/xeno_action/xeno_resting,
		/datum/action/xeno_action/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/plant_weeds,
		/datum/action/xeno_action/choose_resin,
		/datum/action/xeno_action/activable/secrete_resin,
		/datum/action/xeno_action/grow_ovipositor,
		/datum/action/xeno_action/activable/screech,
		/datum/action/xeno_action/activable/corrosive_acid,
		/datum/action/xeno_action/emit_pheromones,
		/datum/action/xeno_action/activable/gut,
		/datum/action/xeno_action/psychic_whisper,
		/datum/action/xeno_action/shift_spits,
		/datum/action/xeno_action/activable/xeno_spit,
		)

	inherent_verbs = list(
		/mob/living/carbon/Xenomorph/proc/claw_toggle,
		/mob/living/carbon/Xenomorph/Queen/proc/set_orders,
		/mob/living/carbon/Xenomorph/Queen/proc/hive_Message
		)

	var/list/mobile_abilities = list(
		/datum/action/xeno_action/xeno_resting,
		/datum/action/xeno_action/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/plant_weeds,
		/datum/action/xeno_action/choose_resin,
		/datum/action/xeno_action/activable/secrete_resin,
		/datum/action/xeno_action/grow_ovipositor,
		/datum/action/xeno_action/activable/screech,
		/datum/action/xeno_action/activable/corrosive_acid,
		/datum/action/xeno_action/emit_pheromones,
		/datum/action/xeno_action/activable/gut,
		/datum/action/xeno_action/psychic_whisper,
		/datum/action/xeno_action/shift_spits,
		/datum/action/xeno_action/activable/xeno_spit,
			)
	mutation_type = QUEEN_NORMAL

/* Resolve this line once structures are resolved.
/mob/living/carbon/Xenomorph/Queen/can_destroy_special()
	return TRUE
*/

/mob/living/carbon/Xenomorph/Queen/Corrupted
	hivenumber = XENO_HIVE_CORRUPTED

/mob/living/carbon/Xenomorph/Queen/Alpha
	hivenumber = XENO_HIVE_ALPHA

/mob/living/carbon/Xenomorph/Queen/Beta
	hivenumber = XENO_HIVE_BETA

/mob/living/carbon/Xenomorph/Queen/Zeta
	hivenumber = XENO_HIVE_ZETA

/mob/living/carbon/Xenomorph/Queen/New()
	..()
	if(z != ADMIN_Z_LEVEL)//so admins can safely spawn Queens in Thunderdome for tests.
		xeno_message(SPAN_XENOANNOUNCE("A new Queen has risen to lead the Hive! Rejoice!"),3,hivenumber)
	playsound(loc, 'sound/voice/alien_queen_command.ogg', 75, 0)

/mob/living/carbon/Xenomorph/Queen/Dispose()
	if(observed_xeno)
		set_queen_overwatch(observed_xeno, TRUE)
	if(hive && hive.living_xeno_queen == src)
		hive.set_living_xeno_queen(null)
	return ..()

/mob/living/carbon/Xenomorph/Queen/proc/can_spawn_larva()
	return loc.z == 1 && hive_datum[hivenumber].stored_larva

/mob/living/carbon/Xenomorph/Queen/proc/spawn_buried_larva(var/client/xeno_candidate)
	if(ovipositor && !is_mob_incapacitated(TRUE))
		if(hive_datum[hivenumber].stored_larva && xeno_candidate)
			var/mob/living/carbon/Xenomorph/Larva/new_xeno = new /mob/living/carbon/Xenomorph/Larva(loc)
			new_xeno.visible_message(SPAN_XENODANGER("A larva suddenly burrows out of the ground!"),
			SPAN_XENODANGER("You burrow out of the ground and awaken from your slumber. For the Hive!"))
			new_xeno << sound('sound/effects/xeno_newlarva.ogg')
			if(!ticker.mode.transfer_xeno(xeno_candidate, new_xeno))
				qdel(new_xeno)
				return

			to_chat(new_xeno, SPAN_XENOANNOUNCE("You are a xenomorph larva awakened from slumber!"))
			new_xeno << sound('sound/effects/xeno_newlarva.ogg')

			hive_datum[hivenumber].stored_larva--
			hive.hive_ui.update_burrowed_larva()



/mob/living/carbon/Xenomorph/Queen/Life()
	..()

	if(stat != DEAD)
		if(map_view)
			src << browse_rsc(xeno_mapview_overlay, "xeno_minimap.png")

		if(++breathing_counter >= rand(12, 17)) //Increase the breathing variable each tick. Play it at random intervals.
			playsound(loc, pick('sound/voice/alien_queen_breath1.ogg', 'sound/voice/alien_queen_breath2.ogg'), 15, 1, 4)
			breathing_counter = 0 //Reset the counter

		if(observed_xeno)
			if(observed_xeno.stat == DEAD || observed_xeno.disposed)
				set_queen_overwatch(observed_xeno, TRUE)

		if(ovipositor && !is_mob_incapacitated(TRUE))
			egg_amount += 0.07 * mutators.egg_laying_multiplier //one egg approximately every 30 seconds
			if(egg_amount >= 1)
				if(isturf(loc))
					var/turf/T = loc
					if(T.contents.len <= 25) //so we don't end up with a million object on that turf.
						egg_amount--
						var/obj/item/xeno_egg/newegg = new /obj/item/xeno_egg(loc)
						newegg.hivenumber = hivenumber

		for(var/mob/living/carbon/Xenomorph/Larva/L in range(1))
			if(!L.ckey)
				visible_message(SPAN_XENODANGER("[L] quickly burrows into the ground."))
				hive_datum[hivenumber].stored_larva++
				hive.hive_ui.update_burrowed_larva()
				qdel(L)

		if((last_larva_time + 30 SECONDS) < world.time) // every minute
			last_larva_time = world.time
			var/list/players_with_xeno_pref = get_alien_candidates()
			if(players_with_xeno_pref && players_with_xeno_pref.len && can_spawn_larva())
				spawn_buried_larva(pick(players_with_xeno_pref))

		// Update vitals for all xenos in the Queen's hive
		if(hive)
			hive.hive_ui.update_xeno_vitals()

/mob/living/carbon/Xenomorph/Queen/Stat()
	..()
	var/stored_larvae = hive_datum[hivenumber].stored_larva
	var/xeno_leader_num = hive?.queen_leader_limit - hive?.open_xeno_leader_positions.len

	stat("Burrowed Larvae:", "[stored_larvae]")
	stat("Leaders:", "[xeno_leader_num] / [hive?.queen_leader_limit]")
	return 1

//Custom bump for crushers. This overwrites normal bumpcode from carbon.dm
/mob/living/carbon/Xenomorph/Queen/Collide(atom/A)
	set waitfor = 0
	
	if(stat || !istype(A) || A == src)
		return FALSE

	if(now_pushing)
		return FALSE//Just a plain ol turf, let's return.

	var/turf/T = get_step(src, dir)
	if(!T || !get_step_to(src, T)) //If it still exists, try to push it.
		return ..()

	lastturf = null //Reset this so we can properly continue with momentum.
	return TRUE

/mob/living/carbon/Xenomorph/Queen/proc/set_orders()
	set category = "Alien"
	set name = "Set Hive Orders (50)"
	set desc = "Give some specific orders to the hive. They can see this on the status pane."

	if(!check_state())
		return
	if(!check_plasma(50))
		return
	if(last_special > world.time)
		return
	plasma_stored -= 50
	var/txt = copytext(sanitize(input("Set the hive's orders to what? Leave blank to clear it.", "Hive Orders","")), 1, MAX_MESSAGE_LEN)

	if(txt)
		xeno_message("<B>The Queen's will overwhelms your instincts...</B>",3,hivenumber)
		xeno_message("<B>\""+txt+"\"</B>",3,hivenumber)
		hive.hive_orders = txt
		log_hiveorder("[usr.name] ([usr.ckey]) has set the Hive Order to: [txt]")
	else
		hive.hive_orders = ""

	last_special = world.time + 150

/mob/living/carbon/Xenomorph/Queen/proc/hive_Message()
	set category = "Alien"
	set name = "Word of the Queen (50)"
	set desc = "Send a message to all aliens in the hive that is big and visible"
	if(!check_plasma(50))
		return
	plasma_stored -= 50
	if(health <= 0)
		to_chat(src, SPAN_WARNING("You can't do that while unconcious."))
		return 0
	var/input = stripped_multiline_input(src, "This message will be broadcast throughout the hive.", "Word of the Queen", "")
	if(!input)
		return

	xeno_announcement(input, hivenumber)

	log_admin("[key_name_admin(src)] has created a Word of the Queen report: [input]")


/mob/living/carbon/Xenomorph/proc/claw_toggle()
	set name = "Permit/Disallow Slashing"
	set desc = "Allows you to permit the hive to harm."
	set category = "Alien"

	if(stat)
		to_chat(src, SPAN_WARNING("You can't do that now."))
		return

	if(!hive)
		to_chat(src, SPAN_WARNING("You can't do that now."))
		CRASH("[src] attempted to toggle slashing without a linked hive")

	if(pslash_delay)
		to_chat(src, SPAN_WARNING("You must wait a bit before you can toggle this again."))
		return

	pslash_delay = TRUE
	add_timer(CALLBACK(src, /mob/living/carbon/Xenomorph/proc/do_claw_toggle_cooldown), SECONDS_30)

	var/choice = input("Choose which level of slashing hosts to permit to your hive.","Harming") as null|anything in list("Allowed", "Restricted - Less Damage", "Forbidden")

	if(choice == "Allowed")
		to_chat(src, SPAN_XENONOTICE("You allow slashing."))
		xeno_message("The Queen has <b>permitted</b> the harming of hosts! Go hog wild!")
		hive.slashing_allowed = 1
	else if(choice == "Restricted - Less Damage")
		to_chat(src, SPAN_XENONOTICE("You restrict slashing."))
		xeno_message("The Queen has <b>restricted</b> the harming of hosts. You will only slash when hurt.")
		hive.slashing_allowed = 2
	else if(choice == "Forbidden")
		to_chat(src, SPAN_XENONOTICE("You forbid slashing entirely."))
		xeno_message("The Queen has <b>forbidden</b> the harming of hosts. You can no longer slash your enemies.")
		hive.slashing_allowed = 0

/mob/living/carbon/Xenomorph/proc/do_claw_toggle_cooldown()
	pslash_delay = FALSE

/mob/living/carbon/Xenomorph/Queen/proc/queen_screech()
	if(!check_state())
		return

	if(has_screeched)
		to_chat(src, SPAN_WARNING("You are not ready to screech again."))
		return

	if(!check_plasma(250))
		return

	//screech is so powerful it kills huggers in our hands
	if(istype(r_hand, /obj/item/clothing/mask/facehugger))
		var/obj/item/clothing/mask/facehugger/FH = r_hand
		if(FH.stat != DEAD)
			FH.Die()

	if(istype(l_hand, /obj/item/clothing/mask/facehugger))
		var/obj/item/clothing/mask/facehugger/FH = l_hand
		if(FH.stat != DEAD)
			FH.Die()

	has_screeched = 1
	use_plasma(250)
	spawn(500)
		has_screeched = 0
		to_chat(src, SPAN_WARNING("You feel your throat muscles vibrate. You are ready to screech again."))
		for(var/Z in actions)
			var/datum/action/A = Z
			A.update_button_icon()
	playsound(loc, screech_sound_effect, 75, 0, status = 0)
	visible_message(SPAN_XENOHIGHDANGER("[src] emits an ear-splitting guttural roar!"))
	create_shriekwave() //Adds the visual effect. Wom wom wom
	//stop_momentum(charge_dir) //Screech kills a charge

	for(var/mob/M in view())
		if(M && M.client)
			if(isXeno(M))
				shake_camera(M, 10, 1)
			else
				shake_camera(M, 30, 1) //50 deciseconds, SORRY 5 seconds was way too long. 3 seconds now

	for(var/mob/living/carbon/human/M in oview(7, src))
		if(istype(M.wear_ear, /obj/item/clothing/ears/earmuffs))
			continue
		M.scream_stun_timeout = SECONDS_20
		var/dist = get_dist(src,M)
		if(dist <= 4)
			to_chat(M, SPAN_DANGER("An ear-splitting guttural roar shakes the ground beneath your feet!"))
			M.stunned += 4 //Seems the effect lasts between 3-8 seconds.
			M.KnockDown(4)
			if(!M.ear_deaf)
				M.ear_deaf += 8 //Deafens them temporarily
		else if(dist >= 5 && dist < 7)
			M.stunned += 3
			to_chat(M, SPAN_DANGER("The roar shakes your body to the core, freezing you in place!"))

/mob/living/carbon/Xenomorph/Queen/proc/queen_gut(atom/A)

	if(!iscarbon(A))
		return

	var/mob/living/carbon/victim = A

	if(get_dist(src, victim) > 1)
		return

	if(!check_state())
		return

	if(last_special > world.time)
		return

	if(isSynth(victim))
		var/datum/limb/head/synthhead = victim.get_limb("head")
		if(synthhead.status & LIMB_DESTROYED)
			return

	if(locate(/obj/item/alien_embryo) in victim) //Maybe they ate it??
		var/mob/living/carbon/human/H = victim
		if(H.status_flags & XENO_HOST)
			if(victim.stat != DEAD) //Not dead yet.
				to_chat(src, SPAN_XENOWARNING("The host and child are still alive!"))
				return
			else if(istype(H) && ( world.time <= H.timeofdeath + H.revive_grace_period )) //Dead, but the host can still hatch, possibly.
				to_chat(src, SPAN_XENOWARNING("The child may still hatch! Not yet!"))
				return

	if(isXeno(victim))
		var/mob/living/carbon/Xenomorph/xeno = victim
		if(hivenumber == xeno.hivenumber)
			to_chat(src, SPAN_WARNING("You can't bring yourself to harm a fellow sister to this magnitude."))
			return

	var/turf/cur_loc = victim.loc
	if(!istype(cur_loc))
		return

	if(action_busy)
		return

	if(!check_plasma(200))
		return
	use_plasma(200)
	last_special = world.time + 50

	visible_message(SPAN_XENOWARNING("[src] begins slowly lifting [victim] into the air."), \
	SPAN_XENOWARNING("You begin focusing your anger as you slowly lift [victim] into the air."))
	if(do_after(src, 80, INTERRUPT_ALL, BUSY_ICON_HOSTILE, victim))
		if(!victim)
			return
		if(victim.loc != cur_loc)
			return
		visible_message(SPAN_XENODANGER("[src] viciously smashes and wrenches [victim] apart!"), \
		SPAN_XENODANGER("You suddenly unleash pure anger on [victim], instantly wrenching \him apart!"))
		emote("roar")
		attack_log += text("\[[time_stamp()]\] <font color='red'>gibbed [victim.name] ([victim.ckey])</font>")
		victim.attack_log += text("\[[time_stamp()]\] <font color='orange'>was gibbed by [name] ([ckey])</font>")
		victim.gib(initial(name)) //Splut
		stop_pulling()

/mob/living/carbon/Xenomorph/Queen/proc/mount_ovipositor()
	if(ovipositor)
		return //sanity check
	ovipositor = TRUE

	for(var/datum/action/A in actions)
		qdel(A)

	var/list/immobile_abilities = list(
		/datum/action/xeno_action/regurgitate,
		/datum/action/xeno_action/remove_eggsac,
		/datum/action/xeno_action/activable/screech,
		/datum/action/xeno_action/emit_pheromones,
		/datum/action/xeno_action/psychic_whisper,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/toggle_queen_zoom,
		/datum/action/xeno_action/set_xeno_lead,
		/datum/action/xeno_action/queen_heal,
		/datum/action/xeno_action/queen_give_plasma,
		/datum/action/xeno_action/queen_order,
		/datum/action/xeno_action/deevolve,
		/datum/action/xeno_action/show_minimap,
		/datum/action/xeno_action/banish,
		/datum/action/xeno_action/readmit,
	)

	for(var/path in immobile_abilities)
		var/datum/action/xeno_action/A = new path()
		A.give_action(src)

	anchored = TRUE
	resting = FALSE
	update_canmove()
	update_icons()

	if(hive)
		var/turf/T = get_turf(src)
		hive.set_hive_location(T)

	for(var/mob/living/carbon/Xenomorph/L in hive.xeno_leader_list)
		L.handle_xeno_leader_pheromones()

	xeno_message(SPAN_XENOANNOUNCE("The Queen has grown an ovipositor, evolution progress resumed."), 3, hivenumber)

/mob/living/carbon/Xenomorph/Queen/proc/dismount_ovipositor(instant_dismount)
	set waitfor = 0
	if(!instant_dismount)
		if(observed_xeno)
			set_queen_overwatch(observed_xeno, TRUE)
		flick("ovipositor_dismount", src)
		sleep(5)
	else
		flick("ovipositor_dismount_destroyed", src)
		sleep(5)

	if(!ovipositor)
		return
	
	ovipositor = FALSE
	map_view = 0
	close_browser(src, "queenminimap")
	update_icons()
	new /obj/ovipositor(loc)

	if(observed_xeno)
		set_queen_overwatch(observed_xeno, TRUE)
	zoom_out()

	for(var/datum/action/A in actions)
		qdel(A)

	for(var/path in mobile_abilities)
		var/datum/action/xeno_action/A = new path()
		A.give_action(src)
	recalculate_actions()

	egg_amount = 0
	ovipositor_cooldown = world.time + MINUTES_5 //5 minutes
	anchored = FALSE
	update_canmove()

	for(var/mob/living/carbon/Xenomorph/L in hive.xeno_leader_list)
		L.handle_xeno_leader_pheromones()

	if(!instant_dismount)
		xeno_message(SPAN_XENOANNOUNCE("The Queen has shed her ovipositor, evolution progress paused."), 3, hivenumber)

/mob/living/carbon/Xenomorph/Queen/update_canmove()
	. = ..()
	if(ovipositor)
		lying = FALSE
		density = TRUE
		canmove = FALSE
		return canmove


/mob/living/carbon/Xenomorph/Queen/update_icons()
	icon = icon_body
	if(stat == DEAD)
		icon_state = "Queen Dead"
	else if(ovipositor)
		icon = icon_ovi
		icon_state = "Queen Ovipositor"
	else if(lying)
		if((resting || sleeping) && (!knocked_down && !knocked_out && health > 0))
			icon_state = "Queen Sleeping"
		else
			icon_state = "Queen Knocked Down"
	else
		if(m_intent == MOVE_INTENT_RUN)
			/*if(charge_speed > charge_speed_buildup * charge_turfs_to_charge) //Let it build up a bit so we're not changing icons every single turf
				icon_state = "Queen Charging"
			else*/
			icon_state = "Queen Running"
		else
			icon_state = "Queen Walking"

	update_fire() //the fire overlay depends on the xeno's stance, so we must update it.

//proc to modify which xeno, if any, the queen is observing.
/mob/living/carbon/Xenomorph/Queen/proc/set_queen_overwatch(mob/living/carbon/Xenomorph/target, stop_overwatch)
	if(stop_overwatch)
		observed_xeno = null
	else
		var/mob/living/carbon/Xenomorph/old_xeno = observed_xeno
		observed_xeno = target
		if(old_xeno)
			old_xeno.hud_set_queen_overwatch()
	if(!target.disposed) //not qdel'd
		target.hud_set_queen_overwatch()
	reset_view()


/mob/living/carbon/Xenomorph/Queen/gib(var/cause = "gibbing")
	death(cause, 1) //we need the body to show the queen's name at round end.

/mob/living/carbon/Xenomorph/Queen/proc/update_mapview(var/close = FALSE, var/force_update = FALSE)
	if(close)
		map_view = 0
		close_browser(src, "queenminimap")
		return
	map_view = 1
	if(world.time > next_map_gen)
		generate_xeno_mapview()
		next_map_gen = world.time + 6000
	if(!xeno_mapview_overlay || force_update)
		overlay_xeno_mapview(hivenumber)
	src << browse_rsc(xeno_mapview_overlay, "xeno_minimap.png")
	show_browser(src, "<img src=xeno_minimap.png>", "Queen Mind Map", "queenminimap", "size=[(map_sizes[1][1]*2)+50]x[(map_sizes[1][2]*2)+50]")
	onclose(src, "queenminimap", src)

/mob/living/carbon/Xenomorph/Queen/Topic(href, href_list)
	if (href_list["close"]) // Closing minimap properly
		map_view = 0
		close_browser(src, "queenminimap")
		return

	..()

/mob/living/carbon/Xenomorph/Queen/proc/in_egg_plant_range(var/turf/T)
	if(!ovipositor)
		return FALSE // can't range plant while not in ovi... but who the fuck cares, we can't plant anyways
	return get_dist(src, T) <= egg_planting_range
