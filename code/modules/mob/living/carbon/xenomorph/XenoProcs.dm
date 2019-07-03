//Xenomorph General Procs And Functions - Colonial Marines
//LAST EDIT: APOPHIS 22MAY16


//Send a message to all xenos. Mostly used in the deathgasp display
/proc/xeno_message(var/message = null, var/size = 3, var/hivenumber = XENO_HIVE_NORMAL)
	if(!message)
		return

	if(ticker && ticker.mode && ticker.mode.xenomorphs.len) //Send to only xenos in our gamemode list. This is faster than scanning all mobs
		for(var/datum/mind/L in ticker.mode.xenomorphs)
			var/mob/living/carbon/Xenomorph/M = L.current
			if(M && istype(M) && !M.stat && M.client && hivenumber == M.hivenumber) //Only living and connected xenos
				to_chat(M, SPAN_XENODANGER("<font size=[size]> [message]</font>"))

//Adds stuff to your "Status" pane -- Specific castes can have their own, like carrier hugger count
//Those are dealt with in their caste files.
/mob/living/carbon/Xenomorph/Stat()
	if (!..())
		return 0

	stat("Time:","[worldtime2text()]")

	stat("Plasma:", "[round(plasma_stored)]/[round(plasma_max)]")

	if(caste_name == "Bloody Larva" || caste_name == "Predalien Larva")
		stat("Evolve Progress:", "[round(amount_grown)]/[max_grown]")
	else if(!hive.living_xeno_queen)
		stat("Evolve Progress:", "NO QUEEN")
	else if(!hive.living_xeno_queen.ovipositor && !caste_name == "Queen")
		stat("Evolve Progress:", "NO OVIPOSITOR")
	else if(caste.evolution_allowed)
		stat("Evolve Progress:", "[round(evolution_stored)]/[evolution_threshold]")

	if(upgrade != -1 && upgrade < 3) //upgrade possible
		stat("Upgrade Progress:", "[round(upgrade_stored)]/[upgrade_threshold]")

	if(mutators.remaining_points > 0)
		stat("Mutator Points:", "[mutators.remaining_points]")
	if(isXenoQueenLeadingHive(src) && hive.mutators.remaining_points > 0)
		stat("Hive Mutator Points:", "[hive.mutators.remaining_points]")

	stat("")
	//Very weak <= 1.0, weak <= 2.0, no modifier 2-3, strong <= 3.5, very strong <= 4.5
	var/msg_holder = "-"

	if(frenzy_aura)
		switch(frenzy_aura)
			if(-INFINITY to 1.0) msg_holder = "Very Weak"
			if(1.1 to 2.0) msg_holder = "Weak"
			if(2.1 to 2.9) msg_holder = "Moderate"
			if(3.0 to 3.9) msg_holder = "Strong"
			if(4.0 to INFINITY) msg_holder = "Very Strong"
	stat("Frenzy:", "[msg_holder]")
	msg_holder = "-"

	if(warding_aura)
		switch(warding_aura)
			if(-INFINITY to 1.0) msg_holder = "Very Weak"
			if(1.1 to 2.0) msg_holder = "Weak"
			if(2.1 to 2.9) msg_holder = "Moderate"
			if(3.0 to 3.9) msg_holder = "Strong"
			if(4.0 to INFINITY) msg_holder = "Very Strong"
	stat("Warding:", "[msg_holder]")
	msg_holder = "-"

	if(recovery_aura)
		switch(recovery_aura)
			if(-INFINITY to 1.0) msg_holder = "Very Weak"
			if(1.1 to 2.0) msg_holder = "Weak"
			if(2.1 to 2.9) msg_holder = "Moderate"
			if(3.0 to 3.9) msg_holder = "Strong"
			if(4.0 to INFINITY) msg_holder = "Very Strong"
	stat("Recovery:", "[msg_holder]")

	stat(null,"")

	if(!hive.living_xeno_queen)
		stat("Queen's Location:", "NO QUEEN")
	else if(!(caste_name == "Queen"))
		stat("Queen's Location:", "[hive.living_xeno_queen.loc.loc.name]")

	if(hive.slashing_allowed == 1)
		stat("Slashing:", "PERMITTED")
	else if(hive.slashing_allowed == 2)
		stat("Slashing:", "LIMITED")
	else
		stat("Slashing:", "FORBIDDEN")

	if(!hive.hive_orders)
		stat("Hive Orders:", "-")
	else
		stat("Hive Orders:", "[hive.hive_orders]")

	stat("")
	return 1

//A simple handler for checking your state. Used in pretty much all the procs.
/mob/living/carbon/Xenomorph/proc/check_state(var/whilelying = 0)
	if(!whilelying)
		if(is_mob_incapacitated() || lying || buckled)
			to_chat(src, SPAN_WARNING("You cannot do this in your current state."))
			return 0
	else
		if(is_mob_incapacitated() || buckled)
			to_chat(src, SPAN_WARNING("You cannot do this in your current state."))
			return 0
	return 1

//Checks your plasma levels and gives a handy message.
/mob/living/carbon/Xenomorph/proc/check_plasma(value)
	if(stat)
		to_chat(src, SPAN_WARNING("You cannot do this in your current state."))
		return 0

	if(value)
		if(plasma_stored < value)
			if(caste.is_robotic)
				to_chat(src, SPAN_WARNING("Beep. You do not have enough plasma to do this. You require [value] plasma but have only [plasma_stored] stored."))
			else
				to_chat(src, SPAN_WARNING("You do not have enough plasma to do this. You require [value] plasma but have only [plasma_stored] stored."))
			return 0
	return 1

/mob/living/carbon/Xenomorph/proc/use_plasma(value)
	plasma_stored = max(plasma_stored - value, 0)
	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()

/mob/living/carbon/Xenomorph/proc/gain_plasma(value)
	plasma_stored = min(plasma_stored + value, plasma_max)
	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()

/mob/living/carbon/Xenomorph/proc/gain_health(value)
	if(bruteloss == 0 && fireloss == 0)
		return

	if(bruteloss < value)
		value -= bruteloss
		bruteloss = 0
		if(fireloss < value)
			fireloss = 0
		else
			fireloss -= value
	else
		bruteloss -= value

	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()




//Strip all inherent xeno verbs from your caste. Used in evolution.
/mob/living/carbon/Xenomorph/proc/remove_inherent_verbs()
	if(inherent_verbs)
		for(var/verb_path in inherent_verbs)
			verbs -= verb_path

//Add all your inherent caste verbs and procs. Used in evolution.
/mob/living/carbon/Xenomorph/proc/add_inherent_verbs()
	if(inherent_verbs)
		for(var/verb_path in inherent_verbs)
			verbs |= verb_path


//Adds or removes a delay to movement based on your caste. If speed = 0 then it shouldn't do much.
//Runners are -2, -4 is BLINDLINGLY FAST, +2 is fat-level
/mob/living/carbon/Xenomorph/movement_delay()
	. = ..()

	. += ability_speed_modifier

	if(frenzy_aura)
		. -= (frenzy_aura * 0.05)

	if(agility)
		. += caste.agility_speed_increase

	if(is_charging)
		if(legcuffed)
			is_charging = 0
			stop_momentum()
			to_chat(src, SPAN_XENODANGER("You can't charge with that thing on your leg!"))
		else
			. -= charge_speed
			charge_timer = 2
			if(charge_speed == 0)
				charge_dir = dir
				handle_momentum()
			else
				if(last_move_dir != dir) //Have we changed direction?
					stop_momentum() //This should disallow rapid turn bumps
				else
					handle_momentum()

	if(weedwalking_activated)
		if(locate(/obj/effect/alien/weeds) in loc)
			. -= 1.5

	if(locate(/obj/effect/alien/weeds) in loc)
		. *= 0.95
	if(locate(/obj/effect/alien/resin/sticky/fast) in loc)
		. *= 0.8

	. *= speed_multiplier


/mob/living/carbon/Xenomorph/show_inv(mob/user)
	return


//This deals with "throwing" xenos -- ravagers, hunters, and runners in particular. Everyone else defaults to normal
//Pounce, charge both use throw_at, so we need extra code to do stuff rather than just push people aside.
/mob/living/carbon/Xenomorph/throw_impact(atom/hit_atom, speed)
	set waitfor = 0

	if(!caste.charge_type || stat || (!throwing && used_pounce)) //No charge type, unconscious or dead, or not throwing but used pounce.
		..() //Do the parent instead.
		r_FAL

	if(isobj(hit_atom)) //Deal with smacking into dense objects. This overwrites normal throw code.
		var/obj/O = hit_atom
		if(!O.density) r_FAL//Not a dense object? Doesn't matter then, pass over it.
		if(!O.anchored) step(O, dir) //Not anchored? Knock the object back a bit. Ie. canisters.

		switch(caste.charge_type) //Determine how to handle it depending on charge type.
			if(1 to 2)
				if(!istype(O, /obj/structure/table) && !istype(O, /obj/structure/rack))
					O.hitby(src, speed) //This resets throwing.
			if(3 to 4)
				if(istype(O, /obj/structure/table) || istype(O, /obj/structure/rack))
					var/obj/structure/S = O
					visible_message(SPAN_DANGER("[src] plows straight through [S]!"), null, null, 5)
					S.destroy() //We want to continue moving, so we do not reset throwing.
				else O.hitby(src, speed) //This resets throwing.
		r_TRU

	if(ismob(hit_atom)) //Hit a mob! This overwrites normal throw code.
		var/mob/living/carbon/M = hit_atom
		if(!M.stat && !isXeno(M))
			switch(caste.charge_type)
				if(1 to 2)
					if(ishuman(M) && M.dir in reverse_nearby_direction(dir))
						var/mob/living/carbon/human/H = M
						if(H.check_shields(15, "the pounce")) //Human shield block.
							KnockDown(3)
							throwing = FALSE //Reset throwing manually.
							r_FAL

						if(isYautja(H))
							if(H.check_shields(0, "the pounce", 1))
								visible_message(SPAN_DANGER("[H] blocks the pounce of [src] with the combistick!"),
												SPAN_XENODANGER("[H] blocks your pouncing form with the combistick!"), null, 5)
								KnockDown(5)
								throwing = FALSE
								r_FAL
							else if(prob(75)) //Body slam the fuck out of xenos jumping at your front.
								visible_message(SPAN_DANGER("[H] body slams [src]!"),
												SPAN_XENODANGER("[H] body slams you!"), null, 5)
								KnockDown(4)
								throwing = FALSE
								r_FAL

					visible_message(SPAN_DANGER("[src] pounces on [M]!"),
									SPAN_XENODANGER("You pounce on [M]!"), null, 5)
					M.KnockDown(caste.charge_type == 1 ? 1 : 3)
					step_to(src, M)
					canmove = FALSE
					frozen = TRUE
					if(pounce_slash)
						M.attack_alien(src)
					if(!caste.is_robotic) playsound(loc, rand(0, 100) < 95 ? 'sound/voice/alien_pounce.ogg' : 'sound/voice/alien_pounce2.ogg', 25, 1)
					spawn(caste.charge_type == 1 ? 5 : 15)
						frozen = FALSE
						update_canmove()

				if(3) //Ravagers get a free attack if they charge into someone. This will tackle if disarm is set instead.
					var/primordial_bonus = 0
					if(upgrade == 4)
						primordial_bonus = 1
					var/extra_dam = min(melee_damage_lower, rand(melee_damage_lower, melee_damage_upper) / (4 - upgrade + primordial_bonus)) //About 12.5 to 80 extra damage depending on upgrade level.
					M.attack_alien(src,  extra_dam) //Ancients deal about twice as much damage on a charge as a regular slash.
					M.KnockDown(2)

				if(4) //Predalien.
					M.attack_alien(src) //Free hit/grab/tackle. Does not weaken, and it's just a regular slash if they choose to do that.

		throwing = FALSE //Resert throwing since something was hit.
		r_TRU

	..() //Do the parent otherwise, for turfs.

//Bleuugh
/mob/living/carbon/Xenomorph/proc/empty_gut()
	if(stomach_contents.len)
		for(var/atom/movable/S in stomach_contents)
			stomach_contents.Remove(S)
			S.acid_damage = 0 //Reset the acid damage
			S.forceMove(get_true_turf(src))

	if(contents.len) //Get rid of anything that may be stuck inside us as well
		for(var/atom/movable/A in contents)
			A.forceMove(get_true_turf(src))

/mob/living/carbon/Xenomorph/proc/toggle_nightvision()
	if(see_invisible == SEE_INVISIBLE_MINIMUM)
		see_invisible = SEE_INVISIBLE_LEVEL_TWO //Turn it off.
		see_in_dark = 4
		sight |= SEE_MOBS
	else
		see_invisible = SEE_INVISIBLE_MINIMUM
		see_in_dark = 8
		sight |= SEE_MOBS

//Random bite attack. Procs more often on downed people. Returns 0 if the check fails.
//Does a LOT of damage.
/mob/living/carbon/Xenomorph/proc/bite_attack(var/mob/living/carbon/human/M, var/damage)

	if(last_rng_attack + caste.rng_min_interval >= world.time) // too soon
		return

	last_rng_attack = world.time

	var/datum/limb/affecting
	affecting = M.get_limb(ran_zone("head", 50))
	if(!affecting) //No head? Just get a random one
		affecting = M.get_limb(ran_zone(null, 0))
	if(!affecting) //Still nothing??
		affecting = M.get_limb("chest") //Gotta have a torso?!

	flick_attack_overlay(M, "slash") //TODO: Special bite attack overlay ?
	playsound(loc, "alien_bite", 25)
	visible_message(SPAN_DANGER("\The [M] is viciously shredded by \the [src]'s sharp teeth!"), \
	SPAN_DANGER("You viciously rend \the [M] with your teeth!"), null, 5)
	M.attack_log += text("\[[time_stamp()]\] <font color='red'>bit [src.name] ([src.ckey])</font>")
	attack_log += text("\[[time_stamp()]\] <font color='orange'>was bitten by [M.name] ([M.ckey])</font>")

	var/armor_block = getarmor(affecting, ARMOR_MELEE)
	var/n_damage = armor_damage_reduction(config.marine_melee, damage, armor_block, 10)
	M.apply_damage(n_damage, BRUTE, affecting, 0, sharp = 1) //This should slicey dicey
	M.updatehealth()

//Tail stab. Checked during a slash, after the above.
//Deals a monstrous amount of damage based on how long it's been charging, but charging it drains plasma.
//Toggle is in XenoPowers.dm.
/mob/living/carbon/Xenomorph/proc/tail_attack(mob/living/carbon/human/M, var/damage)

	if(last_rng_attack + caste.rng_min_interval >= world.time) // too soon
		return

	last_rng_attack = world.time

	var/datum/limb/affecting
	affecting = M.get_limb(ran_zone(zone_selected, 75))
	if(!affecting) //No organ, just get a random one
		affecting = M.get_limb(ran_zone(null, 0))
	if(!affecting) //Still nothing??
		affecting = M.get_limb("chest") // Gotta have a torso?!

	flick_attack_overlay(M, "tail")
	playsound(M.loc, 'sound/weapons/alien_tail_attack.ogg', 25, 1) //Stolen from Yautja! Owned!
	visible_message(SPAN_DANGER("\The [M] is suddenly impaled by \the [src]'s sharp tail!"), \
	SPAN_DANGER("You violently impale \the [M] with your tail!"), null, 5)
	M.attack_log += text("\[[time_stamp()]\] <font color='red'>tail-stabbed [M.name] ([M.ckey])</font>")
	attack_log += text("\[[time_stamp()]\] <font color='orange'>was tail-stabbed by [src.name] ([src.ckey])</font>")

	var/armor_block = getarmor(affecting, ARMOR_MELEE)
	var/n_damage = armor_damage_reduction(config.marine_melee, damage, armor_block, 40)
	M.apply_damage(n_damage, BRUTE, affecting, 0, sharp = 1, edge = 1) //This should slicey dicey
	M.updatehealth()

/mob/living/carbon/Xenomorph/proc/regurgitate(mob/living/victim, var/stunned = 1)
	if(stomach_contents.len)
		if(victim)
			stomach_contents.Remove(victim)
			victim.acid_damage = 0
			victim.forceMove(get_true_turf(loc))

			visible_message(SPAN_XENOWARNING("\The [src] hurls out the contents of their stomach!"), \
			SPAN_XENOWARNING("You hurl out the contents of your stomach!"), null, 5)
			playsound(get_true_location(src.loc), 'sound/voice/alien_drool2.ogg', 50, 1)

			if(!stunned)
				victim.SetStunned(0)
				victim.SetKnockeddown(0)
	else
		to_chat(src, SPAN_WARNING("There's nothing in your belly that needs regurgitating."))

/mob/living/carbon/Xenomorph/proc/zoom_in()
	if(stat || resting)
		if(is_zoomed)
			is_zoomed = 0
			zoom_out()
			return
		return
	if(is_zoomed)
		return
	if(!client)
		return
	zoom_turf = get_turf(src)
	is_zoomed = 1
	client.change_view(viewsize)
	var/viewoffset = 32 * tileoffset
	switch(dir)
		if(NORTH)
			client.pixel_x = 0
			client.pixel_y = viewoffset
		if(SOUTH)
			client.pixel_x = 0
			client.pixel_y = -viewoffset
		if(EAST)
			client.pixel_x = viewoffset
			client.pixel_y = 0
		if(WEST)
			client.pixel_x = -viewoffset
			client.pixel_y = 0

/mob/living/carbon/Xenomorph/proc/zoom_out()
	if(!client)
		return
	client.change_view(world.view)
	client.pixel_x = 0
	client.pixel_y = 0
	is_zoomed = 0
	zoom_turf = null

/mob/living/carbon/Xenomorph/proc/check_alien_construction(var/turf/current_turf)
	var/has_obstacle
	for(var/obj/O in current_turf)
		if(istype(O, /obj/item/clothing/mask/facehugger))
			to_chat(src, SPAN_WARNING("There is a little one here already. Best move it."))
			return
		if(istype(O, /obj/effect/alien/egg))
			to_chat(src, SPAN_WARNING("There's already an egg."))
			return
		if(istype(O, /obj/structure/mineral_door) || istype(O, /obj/effect/alien/resin))
			has_obstacle = TRUE
			break
		if(istype(O, /obj/structure/ladder))
			has_obstacle = TRUE
			break
		if(istype(O, /obj/structure/bed))
			if(istype(O, /obj/structure/bed/chair/dropship/passenger))
				var/obj/structure/bed/chair/dropship/passenger/P = O
				if(P.chair_state != DROPSHIP_CHAIR_BROKEN)
					has_obstacle = TRUE
					break
			else
				has_obstacle = TRUE
				break

		if(O.density && !(O.flags_atom & ON_BORDER))
			has_obstacle = TRUE
			break

	if(current_turf.density || has_obstacle)
		to_chat(src, SPAN_WARNING("There's something built here already."))
		return

	return 1

/mob/living/carbon/Xenomorph/drop_held_item()
	var/obj/item/clothing/mask/facehugger/F = get_active_hand()
	if(istype(F))
		if(locate(/turf/closed/wall/resin) in loc)
			to_chat(src, SPAN_WARNING("You decide not to drop [F] after all."))
			return

	. = ..()


//This is depricated. Use handle_collision() for all future speed changes. ~Bmc777
/mob/living/carbon/Xenomorph/proc/stop_momentum(direction)
	if(!lastturf) r_FAL //Not charging.
	if(charge_speed > charge_speed_buildup * charge_turfs_to_charge) //Message now happens without a stun condition
		visible_message(SPAN_DANGER("[src] skids to a halt!"),
		SPAN_XENOWARNING("You skid to a halt."), null, 5)
	last_charge_move = 0 //Always reset last charge tally
	charge_speed = 0
	charge_roar = 0
	lastturf = null
	flags_pass = 0
	update_icons()

//Why the elerloving fuck was this a Crusher only proc ? AND WHY IS IT NOT CAST ON THE RECEIVING ATOM ? AAAAAAA
/mob/living/carbon/Xenomorph/proc/diagonal_step(atom/movable/A, direction)
	if(!A) r_FAL
	switch(direction)
		if(EAST, WEST) step(A, pick(NORTH,SOUTH))
		if(NORTH,SOUTH) step(A, pick(EAST,WEST))

/mob/living/carbon/Xenomorph/proc/handle_momentum()
	if(throwing)
		r_FAL

	if(last_charge_move && last_charge_move < world.time - 5) //If we haven't moved in the last 500 ms, break charge on next move
		stop_momentum(charge_dir)

	if(stat || pulledby || !loc || !isturf(loc))
		stop_momentum(charge_dir)
		r_FAL

	if(!is_charging)
		stop_momentum(charge_dir)
		r_FAL

	if(lastturf && (loc == lastturf || loc.z != lastturf.z)) //Check if the Crusher didn't move from his last turf, aka stopped
		stop_momentum(charge_dir)
		r_FAL

	if(dir != charge_dir || m_intent == MOVE_INTENT_WALK || istype(loc, /turf/open/gm/river))
		stop_momentum(charge_dir)
		r_FAL

	if(pulling && charge_speed > charge_speed_buildup) stop_pulling()

	if(plasma_stored > 5) plasma_stored -= round(charge_speed) //Eats up plasma the faster you go, up to 0.5 per tile at max speed
	else
		stop_momentum(charge_dir)
		r_FAL

	last_charge_move = world.time //Index the world time to the last charge move

	if(charge_speed < charge_speed_max)
		charge_speed += charge_speed_buildup //Speed increases each step taken. Caps out at 14 tiles
		if(charge_speed == charge_speed_max) //Should only fire once due to above instruction
			if(!charge_roar)
				emote("roar")
				charge_roar = 1

	noise_timer = noise_timer ? --noise_timer : 3

	if(noise_timer == 3 && charge_speed > charge_speed_buildup * charge_turfs_to_charge)
		playsound(loc, "alien_charge", 50)

	if(charge_speed > charge_speed_buildup * charge_turfs_to_charge)

		for(var/mob/living/carbon/M in loc)
			if(M.lying && !isXeno(M) && M.stat != DEAD && !(M.status_flags & XENO_HOST && istype(M.buckled, /obj/structure/bed/nest)))
				visible_message(SPAN_DANGER("[src] runs [M] over!"),
				SPAN_DANGER("You run [M] over!"), null, 5)

				M.take_overall_damage(charge_speed * 10) //Yes, times fourty. Maxes out at a sweet, square 84 damage for 2.1 max speed
				animation_flash_color(M)

		var/shake_dist = min(round(charge_speed * 5), 8)
		for(var/mob/living/carbon/M in range(shake_dist))
			if(M.client && !isXeno(M))
				shake_camera(M, 1, 1)

	lastturf = isturf(loc) && !istype(loc, /turf/open/space) ? loc : null//Set their turf, to make sure they're moving and not jumped in a locker or some shit

	update_icons()

//Welp
/mob/living/carbon/Xenomorph/proc/xeno_jitter(var/jitter_time = 25)

	set waitfor = 0

	while(jitter_time) //In ticks, so 10 ticks = 1 sec of jitter!
		set waitfor = 0
		pixel_x = old_x + rand(-3, 3)
		pixel_y = old_y + rand(-1, 1)
		sleep(1)
		jitter_time--
	//endwhile - reset the pixel offsets to zero
	pixel_x = old_x
	pixel_y = old_y

//When the Queen's pheromones are updated, or we add/remove a leader, update leader pheromones
/mob/living/carbon/Xenomorph/proc/handle_xeno_leader_pheromones()
	if(!hive)
		return
	var/mob/living/carbon/Xenomorph/Queen/Q = hive.living_xeno_queen
	if(!Q || !Q.anchored || !queen_chosen_lead || !Q.current_aura || Q.loc.z != loc.z) //We are no longer a leader, or the Queen attached to us has dropped from her ovi, disabled her pheromones or even died
		leader_aura_strength = 0
		leader_current_aura = ""
		to_chat(src, SPAN_XENOWARNING("Your pheromones wane. The Queen is no longer granting you her pheromones."))
	else
		leader_aura_strength = Q.aura_strength
		leader_current_aura = Q.current_aura
		to_chat(src, SPAN_XENOWARNING("Your pheromones have changed. The Queen has new plans for the Hive."))

/mob/living/carbon/Xenomorph/proc/nocrit(var/wowave)
	if(map_tag == MAP_WHISKEY_OUTPOST)
		if(wowave < 15)
			maxHealth = ((maxHealth+abs(crit_health))*(wowave/15)*(3/4))+((maxHealth)*1/4) //if it's wo we give xeno's less hp in lower rounds. This makes help the marines feel good.
			health	= ((health+abs(crit_health))*(wowave/15)*(3/4))+((health)*1/4) //if it's wo we give xeno's less hp in lower rounds. This makes help the marines feel good.
		else
			maxHealth = maxHealth+abs(crit_health) // From round 15 and on we give them only a slight boost
			health = health+abs(crit_health) // From round 15 and on we give them only a slight boost
	crit_health = -1 // Do not put this at 0 or xeno's will just vanish on WO due to how the garbage collector works.


