//Some debug variables. Toggle them to 1 in order to see the related debug messages. Helpful when testing out formulas.
#define DEBUG_HIT_CHANCE	0
#define DEBUG_HUMAN_DEFENSE	0
#define DEBUG_XENO_DEFENSE	0

//The actual bullet objects.
/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/items/weapons/projectiles.dmi'
	icon_state = "bullet"
	density = 0
	unacidable = TRUE
	anchored = 1 //You will not have me, space wind!
	flags_atom = NOINTERACT //No real need for this, but whatever. Maybe this flag will do something useful in the future.
	mouse_opacity = 0
	invisibility = 100 // We want this thing to be invisible when it drops on a turf because it will be on the user's turf. We then want to make it visible as it travels.
	layer = FLY_LAYER

	var/datum/ammo/ammo //The ammo data which holds most of the actual info.

	var/def_zone = "chest"	//So we're not getting empty strings.

	var/yo = null
	var/xo = null

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/current 		 = null
	var/atom/shot_from 	 = null // the object which shot us
	var/atom/original 	 = null // the original target clicked
	var/atom/firer 		 = null // Who shot it

	var/turf/target_turf = null
	var/turf/starting 	 = null // the projectile's starting turf

	var/turf/path[]  	 = null
	var/permutated[] 	 = null // we've passed through these atoms, don't try to hit them again

	var/damage = 0
	var/accuracy = 85 //Base projectile accuracy. Can maybe be later taken from the mob if desired.

	var/damage_falloff = 0 //how many damage point the projectile loses per tiles travelled

	var/scatter = 0

	var/distance_travelled = 0
	var/in_flight = 0

	var/projectile_override_flags = 0

	var/weapon_source
	var/weapon_source_mob

/obj/item/projectile/New(var/source, var/source_mob)
	..()
	path = list()
	permutated = list()
	weapon_source = source
	weapon_source_mob = source_mob
	if(source_mob)
		firer = source_mob

/obj/item/projectile/Dispose()
	..()
	in_flight = 0
	ammo = null
	shot_from = null
	original = null
	target_turf = null
	starting = null
	permutated = null
	path = null
	return GC_HINT_RECYCLE

/obj/item/projectile/Collided(atom/movable/AM)
	if(AM && !AM in permutated)
		scan_a_turf(AM.loc)

/obj/item/projectile/Crossed(atom/movable/AM)
	if(AM && !AM in permutated)
		scan_a_turf(get_turf(AM))


/obj/item/projectile/ex_act()
	return FALSE //We do not want anything to delete these, simply to make sure that all the bullet references are not runtiming. Otherwise, constantly need to check if the bullet exists.

/obj/item/projectile/proc/generate_bullet(ammo_datum, bonus_damage = 0, special_flags = 0)
	ammo 		= ammo_datum
	name 		= ammo.name
	icon_state 	= ammo.icon_state
	damage 		= ammo.damage + bonus_damage //Mainly for emitters.
	scatter		= ammo.scatter
	accuracy   += ammo.accuracy
	accuracy   *= rand(config.proj_variance_low-ammo.accuracy_var_low, config.proj_variance_high+ammo.accuracy_var_high) * config.proj_base_accuracy_mult//Rand only works with integers.
	damage     *= rand(config.proj_variance_low-ammo.damage_var_low, config.proj_variance_high+ammo.damage_var_high) * config.proj_base_damage_mult
	damage_falloff = ammo.damage_falloff
	projectile_override_flags = special_flags

//Target, firer, shot from. Ie the gun
/obj/item/projectile/proc/fire_at(atom/target,atom/F, atom/S, range = 30,speed = 1)
	if(!original) original = target
	if(!loc) loc = get_turf(F)
	starting = get_turf(src)
	if(starting != loc) loc = starting //Put us on the turf, if we're not.
	target_turf = get_turf(target)
	if(!target_turf || target_turf == starting) //This shouldn't happen, but it can.
		qdel(src)
		return
	firer = F
	if(F) permutated += F //Don't hit the shooter (firer)
	permutated += src //Don't try to hit self.
	shot_from = S
	in_flight = 1

	dir = get_dir(loc, target_turf)

	var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags
	if(round_statistics && ammo_flags & AMMO_BALLISTIC)
		round_statistics.total_projectiles_fired++
		if(ammo.bonus_projectiles_amount)
			round_statistics.total_projectiles_fired += ammo.bonus_projectiles_amount
	if(firer && ismob(firer))
		var/mob/M = firer
		M.track_shot(weapon_source)

	//If we have the the right kind of ammo, we can fire several projectiles at once.
	if(ammo.bonus_projectiles_amount && ammo.bonus_projectiles_type) ammo.fire_bonus_projectiles(src)

	path = getline2(starting,target_turf)

	var/change_x = target_turf.x - starting.x
	var/change_y = target_turf.y - starting.y

	var/angle = round(Get_Angle(starting,target_turf))

	var/matrix/rotate = matrix() //Change the bullet angle.
	rotate.Turn(angle)
	src.transform = rotate


	follow_flightpath(speed,change_x,change_y,range) //pyew!

/obj/item/projectile/proc/each_turf(speed = 1)
	var/new_speed = speed
	distance_travelled++
	if(invisibility && distance_travelled > 1) invisibility = 0 //Let there be light (visibility).
	if(distance_travelled == round(ammo.max_range / 2) && loc) ammo.do_at_half_range(src)
	var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags
	if(ammo_flags & AMMO_ROCKET) //Just rockets for now. Not all explosive ammo will travel like this.
		switch(speed) //Get more speed the longer it travels. Travels pretty quick at full swing.
			if(1)
				if(distance_travelled > 2) new_speed++
			if(2)
				if(distance_travelled > 8) new_speed++
	return new_speed //Need for speed.

/obj/item/projectile/proc/follow_flightpath(speed = 1, change_x, change_y, range) //Everytime we reach the end of the turf list, we slap a new one and keep going.
	set waitfor = 0

	var/dist_since_sleep = 5 //Just so we always see the bullet.

	var/turf/current_turf = get_turf(src)
	var/turf/next_turf
	var/this_iteration = 0
	in_flight = 1
	for(next_turf in path)
		if(!loc || disposed || !in_flight) return

		if(distance_travelled >= range)
			ammo.do_at_max_range(src)
			qdel(src)
			return

		var/proj_dir = get_dir(current_turf, next_turf)
		if(proj_dir & (proj_dir-1)) //diagonal direction
			if(!current_turf.Adjacent(next_turf)) //we can't reach the next turf
				ammo.on_hit_turf(current_turf,src)
				current_turf.bullet_act(src)
				in_flight = 0
				sleep(0)
				qdel(src)
				return

		if(scan_a_turf(next_turf, proj_dir)) //We hit something! Get out of all of this.
			in_flight = 0
			sleep(0)
			qdel(src)
			return

		loc = next_turf
		speed = each_turf(speed)

		this_iteration++
		if(++dist_since_sleep >= speed)
			//TO DO: Adjust flight position every time we see the projectile.
			//I wonder if I can leave sleep out and just have it stall based on adjustment proc.
			//Might still be too fast though.
			dist_since_sleep = 0
			sleep(1)

		current_turf = get_turf(src)
		if(this_iteration == path.len)
			next_turf = locate(current_turf.x + change_x, current_turf.y + change_y, current_turf.z)
			if(current_turf && next_turf)
				path = getline2(current_turf,next_turf) //Build a new flight path.
				if(path.len && src) //TODO look into this. This should always be true, but it can fail, apparently, against DCed people who fall down. Better yet, redo this.
					distance_travelled-- //because the new follow_flightpath() repeats the last step.
					follow_flightpath(speed, change_x, change_y, range) //Onwards!
				else
					qdel(src)
					return
			else //To prevent bullets from getting stuck in maps like WO.
				qdel(src)
				return

/obj/item/projectile/proc/scan_a_turf(turf/T, proj_dir)
	// Not a turf, keep moving
	if(!istype(T))
		return 0

	if(T.density) // Handle wall hit
		var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

		// If the ammo should hit the surface of the target and the next turf is dense
		// The current turf is the "surface" of the target
		if(ammo_flags & AMMO_STRIKES_SURFACE)
			// We "hit" the current turf but strike the actual blockage
			ammo.on_hit_turf(get_turf(src),src)
			T.bullet_act(src)
		else
			ammo.on_hit_turf(T,src)
			T.bullet_act(src)
		return 1

	// Firer's turf, keep moving
	if(firer && T == firer.loc)
		return 0
	var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags
	// Explosive ammo always explodes on the turf of the clicked target
	if(ammo_flags & AMMO_EXPLOSIVE && T == target_turf)
		ammo.on_hit_turf(T,src)

		if(T && T.loc)
			T.bullet_act(src)

		return 1

	if(ammo_flags & AMMO_SCANS_NEARBY && proj_dir)
		//this thing scans depending on dir
		var/cardinal_dir = get_perpen_dir(proj_dir)
		if(!cardinal_dir)
			var/d1 = proj_dir&(proj_dir-1)		// eg west		(1+8)&(8) = 8
			var/d2 = proj_dir - d1			// eg north		(1+8) - 8 = 1
			cardinal_dir = list(d1,d2)

		var/remote_detonation = 0
		var/kill_proj = 0

		for(var/ddir in cardinal_dir)
			var/dloc = get_step(T, ddir)
			var/turf/dturf = get_turf(dloc)
			for(var/atom/movable/dA in dturf)
				if(!isliving(dA))
					continue
				var/mob/living/dL = dA
				if(dL.is_dead())
					continue
				if(ammo_flags & AMMO_SKIPS_HUMANS && ishuman(dL))
					continue
				if(ammo_flags & AMMO_SKIPS_ALIENS && isXeno(dL))
					continue
				remote_detonation = 1
				kill_proj = ammo.on_near_target(T, src)
				break
			if(remote_detonation)
				break

		if(kill_proj)
			return 1

	// Empty turf, keep moving
	if(!T.contents.len)
		return 0

	for(var/atom/movable/clone/C in T) //Handle clones if there are any
		if(C.mstr)
			if(istype(C.mstr, /obj))
				if(handle_object(C.mstr)) return 1
			else if(istype(C.mstr, /mob/living))
				if(handle_mob(C.mstr)) return 1

	for(var/obj/O in T) //check objects before checking mobs, so that barricades protect
		if(handle_object(O)) return 1

	for(var/mob/living/L in T)
		if(handle_mob(L)) return 1

/obj/item/projectile/proc/handle_object(obj/O)
	// If we've already handled this atom, don't do it again
	if(O in permutated)
		return 0
	permutated += O

	var/hit_chance = O.get_projectile_hit_boolean(src)
	if( hit_chance ) // Calculated from combination of both ammo accuracy and gun accuracy
		var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

		// If the ammo should hit the surface of the target and there is an object blocking
		// The current turf is the "surface" of the target
		if(ammo_flags & AMMO_STRIKES_SURFACE)
			var/turf/T = get_turf(O)

			// We "hit" the current turf but strike the actual blockage
			ammo.on_hit_turf(get_turf(src),src)
			T.bullet_act(src)
		else
			ammo.on_hit_obj(O,src)
			if(O && O.loc)
				O.bullet_act(src)
		return 1

/obj/item/projectile/proc/handle_mob(mob/living/L)
	// If we've already handled this atom, don't do it again
	if(L in permutated)
		return 0
	permutated += L

	var/hit_chance = L.get_projectile_hit_chance(src)
	if( hit_chance ) // Calculated from combination of both ammo accuracy and gun accuracy
		var/mob_is_hit = FALSE
		var/hit_roll
		var/i = 0
		while(++i <= 2 && hit_chance > 0) // This runs twice if necessary
			hit_roll 					= rand(0, 99) //Our randomly generated roll
			if(hit_roll < 25) def_zone 	= pick(base_miss_chance)	// Still hit but now we might hit the wrong body part
			hit_chance 				   -= base_miss_chance[def_zone] // Reduce accuracy based on spot.

			switch(i)
				if(1)
					if(hit_chance > hit_roll)
						mob_is_hit = TRUE
						break //Hit
					if( hit_chance < (hit_roll - 20) )
						break //Outright miss.
					def_zone 	  = pick(base_miss_chance) //We're going to pick a new target and let this run one more time.
					hit_chance   -= 10 //If you missed once, the next go around will be harder to hit.
				if(2)
					if(hit_chance > hit_roll)
						mob_is_hit = TRUE
						break
		if(mob_is_hit)
			var/ammo_flags = ammo.flags_ammo_behavior | projectile_override_flags

			// If the ammo should hit the surface of the target and there is a mob blocking
			// The current turf is the "surface" of the target
			if(ammo_flags & AMMO_STRIKES_SURFACE)
				var/turf/T = get_turf(L)

				// We "hit" the current turf but strike the actual blockage
				ammo.on_hit_turf(get_turf(src),src)
				T.bullet_act(src)
			else if(L && L.loc && (L.bullet_act(src) != -1))
				ammo.on_hit_mob(L,src)
			return 1
		else if (!L.lying)
			animatation_displace_reset(L)
			if(ammo.sound_miss) L.playsound_local(get_turf(L), ammo.sound_miss, 75, 1)
			L.visible_message("<span class='avoidharm'>[src] misses [L]!</span>","<span class='avoidharm'>[src] narrowly misses you!</span>", null, 4)



//----------------------------------------------------------
		    	//				    	\\
			    //  HITTING THE TARGET  \\
			    //						\\
			    //						\\
//----------------------------------------------------------


/proc/get_effective_accuracy(obj/item/projectile/P)

	var/effective_accuracy = P.accuracy //We want a temporary variable so accuracy doesn't change every time the bullet misses.

	#if DEBUG_HIT_CHANCE
	to_world("<span class='debuginfo'>Base accuracy is <b>[P.accuracy]; scatter:[P.scatter]; distance:[P.distance_travelled]</b></span>")
	#endif
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if (P.distance_travelled <= P.ammo.accurate_range + rand(0, 2))
	// If bullet stays within max accurate range + random variance
		if (P.distance_travelled <= P.ammo.point_blank_range)
			//If bullet within point blank range, big accuracy buff
			effective_accuracy += 25
		else if (P.distance_travelled <= P.ammo.accurate_range_min)
			// Snipers have accuracy falloff at closer range before point blank
			effective_accuracy -= (P.ammo.accurate_range_min - P.distance_travelled) * 5
	else
		effective_accuracy -= (ammo_flags & AMMO_SNIPER) ? (P.distance_travelled * 1.5) : (P.distance_travelled * 5)
		// Snipers have a smaller falloff constant due to longer max range


	#if DEBUG_HIT_CHANCE
	to_world("<span class='debuginfo'>Final accuracy is <b>[.]</b></span>")
	#endif

	effective_accuracy = max(5, effective_accuracy) //default hit chance is at least 5%.

	if(isliving(P.firer))
		var/mob/living/shooter_living = P.firer
		effective_accuracy -= round((shooter_living.maxHealth - shooter_living.health) / 4) //Less chance to hit when injured.

	if(ishuman(P.firer))
		var/mob/living/carbon/human/shooter_human = P.firer
		if(shooter_human.marksman_aura)
			effective_accuracy += shooter_human.marksman_aura * 1.5 //Flat buff of 3 % accuracy per aura level
			effective_accuracy += P.distance_travelled * 0.35 * shooter_human.marksman_aura //Flat buff to accuracy per tile travelled

	return effective_accuracy


//objects use get_projectile_hit_boolean unlike mobs, which use get_projectile_hit_chance

/obj/proc/get_projectile_hit_boolean(obj/item/projectile/P)
	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	return TRUE


/obj/proc/calculate_cover_hit_boolean(obj/item/projectile/P, var/distance = 0) //Used by machines and structures to calculate shooting past cover
	if(istype(P.shot_from, /obj/item/hardpoint)) //anything shot from a tank gets a bonus to bypassing cover
		distance -= 3

	if(distance < 1)
		return FALSE

	//an object's "projectile_coverage" var indicates the maximum probability of blocking a projectile
	var/effective_accuracy = get_effective_accuracy(P)
	var/distance_limit = 6 //number of tiles needed to max out block probability
	var/accuracy_factor = 50 //degree to which accuracy affects probability   (if accuracy is 100, probability is unaffected. Lower accuracies will increase block chance)

	var/hitchance = min(projectile_coverage, (projectile_coverage * distance/distance_limit) + accuracy_factor * (1 - effective_accuracy/100))
	#if DEBUG_HIT_CHANCE
	to_world("<span class='debuginfo'>([src.name] as cover) Distance travelled: [distance]  |  Effective accuracy: [effective_accuracy]  |  Hit chance: [hitchance]")
	#endif

	return prob(hitchance)


/obj/structure/machinery/get_projectile_hit_boolean(obj/item/projectile/P)

	if(src == P.original && src.layer > ATMOS_DEVICE_LAYER) //clicking on the object itself hits the object
		var/hitchance = get_effective_accuracy(P)

		#if DEBUG_HIT_CHANCE
		to_world("<span class='debuginfo'>([src.name]) Distance travelled: [distance]  |  Effective accuracy: [effective_accuracy]  |  Hit chance: [hitchance]")
		#endif

		if( prob(hitchance) )
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	if(!throwpass)
		return TRUE
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ammo_flags & AMMO_IGNORE_COVER)
		return FALSE

	var/distance = P.distance_travelled


	if(flags_atom & ON_BORDER) //windoors
		if(P.dir & reverse_direction(dir))
			distance-- //no bias towards "inner" side
			if(ammo_flags & AMMO_STOPPED_BY_COVER)
				return TRUE
		else if( !(P.dir & dir) )
			return FALSE //no effect if bullet direction is perpendicular to barricade
	else
		distance--

	return calculate_cover_hit_boolean(P, distance)


/obj/structure/get_projectile_hit_boolean(obj/item/projectile/P)
	if(src == P.original && src.layer > ATMOS_DEVICE_LAYER) //clicking on the object itself hits the object
		var/hitchance = get_effective_accuracy(P)

		#if DEBUG_HIT_CHANCE
		to_world(SPAN_DEBUG("([src.name]) Distance travelled: [distance]  |  Effective accuracy: [effective_accuracy]  |  Hit chance: [hitchance]"))
		#endif

		if( prob(hitchance) )
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	if(!throwpass)
		return TRUE

	//At this point, all that's left is window frames, tables, and barricades
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ammo_flags & AMMO_IGNORE_COVER && src != P.original)
		return FALSE

	var/distance = P.distance_travelled

	if(flags_atom & ON_BORDER) //barricades, flipped tables
		if(P.dir & reverse_direction(dir))
			if(ammo_flags & AMMO_STOPPED_BY_COVER)
				return TRUE
			distance-- //no bias towards "inner" side
		else if(!(P.dir & dir))
			return FALSE //no effect if bullet direction is perpendicular to barricade

	else
		distance--
		if(climbable)
			for(var/obj/structure/S in get_turf(P))
				if(S && S.climbable && !(S.flags_atom & ON_BORDER)) //if a projectile is coming from a window frame or table, it's guaranteed to pass the next window frame/table
					return FALSE
	return calculate_cover_hit_boolean(P, distance)


/obj/item/get_projectile_hit_boolean(obj/item/projectile/P)

	if(P && src == P.original) //clicking on the object itself. Code copied from mob get_projectile_hit_chance

		var/hitchance = get_effective_accuracy(P)

		switch(w_class) //smaller items are harder to hit
			if(1)
				hitchance -= 50
			if(2)
				hitchance -= 30
			if(3)
				hitchance -= 20
			if(4)
				hitchance -= 10

		#if DEBUG_HIT_CHANCE
		to_world("<span class='debuginfo'>([src.name]) Distance travelled: [distance]  |  Effective accuracy: [effective_accuracy]  |  Hit chance: [hitchance]")
		#endif

		if( prob(hitchance) )
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection. Unless they can be destroyed.
		return FALSE

	return TRUE


/obj/vehicle/get_projectile_hit_boolean(obj/item/projectile/P)

	if(src == P.original) //clicking on the object itself hits the object
		var/hitchance = get_effective_accuracy(P)

		#if DEBUG_HIT_CHANCE
		to_world("<span class='debuginfo'>([src.name]) Distance travelled: [distance]  |  Effective accuracy: [effective_accuracy]  |  Hit chance: [hitchance]")
		#endif

		if( prob(hitchance) )
			return TRUE

	if(!density)
		return FALSE

	if(!anchored && !health) //unanchored objects offer no protection.
		return FALSE

	return TRUE


/obj/structure/window/get_projectile_hit_boolean(obj/item/projectile/P)
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ammo_flags & AMMO_ENERGY)
		return FALSE
	else if(!(flags_atom & ON_BORDER) || (P.dir & dir) || (P.dir & reverse_direction(dir)))
		return TRUE

/obj/structure/machinery/door/poddoor/railing/get_projectile_hit_boolean(obj/item/projectile/P)
	return src == P.original

/obj/effect/alien/egg/get_projectile_hit_boolean(obj/item/projectile/P)
	return src == P.original

/obj/effect/alien/resin/trap/get_projectile_hit_boolean(obj/item/projectile/P)
	return src == P.original

/obj/item/clothing/mask/facehugger/get_projectile_hit_boolean(obj/item/projectile/P)
	return src == P.original



//mobs use get_projectile_hit_chance instead of get_projectile_hit_boolean

/mob/living/proc/get_projectile_hit_chance(obj/item/projectile/P)

	if(lying && src != P.original)
		return 0
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ammo_flags & (AMMO_XENO_ACID|AMMO_XENO_TOX))
		if((status_flags & XENO_HOST) && istype(buckled, /obj/structure/bed/nest))
			return 0

	. = get_effective_accuracy(P)

	if(lying && stat) . += 15 //Bonus hit against unconscious people.

	if(isliving(P.firer))
		var/mob/living/shooter_living = P.firer
		if( !can_see(shooter_living,src) ) . -= 15 //Can't see the target (Opaque thing between shooter and target)

/mob/living/carbon/human/get_projectile_hit_chance(obj/item/projectile/P)
	. = ..()
	if(.)
		var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
		if(ammo_flags & AMMO_SKIPS_HUMANS && get_target_lock(P.ammo.iff_signal))
			return 0
		if(mobility_aura)
			. -= mobility_aura * 5
		var/mob/living/carbon/human/shooter_human = P.firer
		if(istype(shooter_human))
			if(shooter_human.faction == faction)
				var/buff_evading = 15
				if(m_intent == MOVE_INTENT_WALK)
					buff_evading += 35
				. -= buff_evading


/mob/living/carbon/Xenomorph/get_projectile_hit_chance(obj/item/projectile/P)
	. = ..()
	if(.)
		var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
		if(ammo_flags & AMMO_SKIPS_ALIENS)
			return 0
		if(mob_size == MOB_SIZE_BIG)	. += 10
		if(evasion > 0)
			. -= evasion

/mob/living/silicon/robot/drone/get_projectile_hit_chance(obj/item/projectile/P)
	return 0 // just stop them getting hit by projectiles completely


/obj/item/projectile/proc/play_damage_effect(mob/M)
	if(ammo.sound_hit) playsound(M, ammo.sound_hit, 50, 1)
	if(M.stat != DEAD) animation_flash_color(M)

//----------------------------------------------------------
				//				    \\
				//    OTHER PROCS	\\
				//					\\
				//					\\
//----------------------------------------------------------

/atom/proc/bullet_act(obj/item/projectile/P)
	return 0

/mob/dead/bullet_act(/obj/item/projectile/P)
	return 0

/mob/living/bullet_act(obj/item/projectile/P)
	if(!P) return

	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	var/damage = max(0, P.damage - round(P.distance_travelled * P.ammo.damage_falloff))
	if(P.ammo.debilitate && stat != DEAD && ( damage || (ammo_flags & AMMO_IGNORE_RESIST) ) )
		apply_effects(arglist(P.ammo.debilitate))

	if(damage)
		bullet_message(P)
		apply_damage(damage, P.ammo.damage_type, P.def_zone, 0, 0, 0, P)
		P.play_damage_effect(src)
		if(ammo_flags & AMMO_INCENDIARY)
			adjust_fire_stacks(rand(6,10))
			IgniteMob()
			emote("scream")
			to_chat(src, SPAN_HIGHDANGER("You burst into flames!! Stop drop and roll!"))
	return 1

#define DEBUG_HUMAN_DEFENSE 0
/mob/living/carbon/human/bullet_act(obj/item/projectile/P)
	if(!P) return

	flash_weak_pain()
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ismob(P.weapon_source_mob))
		var/mob/M = P.weapon_source_mob
		M.track_shot_hit(P.weapon_source, src)

	var/damage = max(0, P.damage - round(P.distance_travelled * P.ammo.damage_falloff))
	var/damage_result = damage

	//Any projectile can decloak a predator. It does defeat one free bullet though.
	if(gloves)
		var/obj/item/clothing/gloves/yautja/Y = gloves
		if(istype(Y) && Y.cloaked)
			if( ammo_flags & (AMMO_ROCKET|AMMO_ENERGY|AMMO_XENO_ACID) ) //<--- These will auto uncloak.
				Y.decloak(src) //Continue on to damage.
			else if(rand(0,100) < 20)
				Y.decloak(src)
				return //Absorb one free bullet.
			//Else we're moving on to damage.

	//Shields
	if( !(ammo_flags & AMMO_ROCKET) ) //No, you can't block rockets.
		if( P.dir == reverse_direction(dir) && check_shields(damage * 0.65, "[P]") )
			P.ammo.on_shield_block(src)
			bullet_ping(P)
			return

	var/datum/limb/organ = get_limb(check_zone(P.def_zone)) //Let's finally get what organ we actually hit.
	if(!organ) return//Nope. Gotta shoot something!

	//Run armor check. We won't bother if there is no damage being done.
	if( damage > 0 && !(ammo_flags & AMMO_IGNORE_ARMOR) )
		var/armor //Damage types don't correspond to armor types. We are thus merging them.
		switch(P.ammo.damage_type)
			if(BRUTE) armor = ammo_flags & AMMO_ROCKET ? getarmor_organ(organ, ARMOR_BOMB) : getarmor_organ(organ, ARMOR_BULLET)
			if(BURN) armor = ammo_flags & AMMO_ENERGY ? getarmor_organ(organ, ARMOR_ENERGY) : getarmor_organ(organ, ARMOR_LASER)
			if(TOX, OXY, CLONE) armor = getarmor_organ(organ, ARMOR_BIO)
			else armor = getarmor_organ(organ, ARMOR_ENERGY) //Won't be used, but just in case.

		damage_result = armor_damage_reduction(config.marine_ranged, damage, armor, P.ammo.penetration)

		if(damage_result <= 5)
			to_chat(src,SPAN_XENONOTICE("Your armor absorbs the force of [P]!"))
		if(damage_result <= 3)
			damage_result = 0
			bullet_ping(P)
			visible_message("<span class='avoidharm'>[src]'s armor deflects [P]!</span>")
			if(P.ammo.sound_armor) playsound(src, P.ammo.sound_armor, 50, 1)

	if(P.ammo.debilitate && stat != DEAD && ( damage || ( ammo_flags & AMMO_IGNORE_RESIST) ) )  //They can't be dead and damage must be inflicted (or it's a xeno toxin).
		//Predators and synths are immune to these effects to cut down on the stun spam. This should later be moved to their apply_effects proc, but right now they're just humans.
		if(species.name != "Yautja" && !(species.flags & IS_SYNTHETIC)) apply_effects(arglist(P.ammo.debilitate))

	bullet_message(P) //We still want this, regardless of whether or not the bullet did damage. For griefers and such.

	if(damage || (ammo_flags && AMMO_SPECIAL_EMBED))
		apply_damage(damage_result, P.ammo.damage_type, P.def_zone, impact_name = P.ammo.impact_name, impact_limbs = P.ammo.impact_limbs)
		P.play_damage_effect(src)
		if(P.ammo.shrapnel_chance > 0 && prob(P.ammo.shrapnel_chance + round(damage / 10)))
			if(ammo_flags && AMMO_SPECIAL_EMBED)
				P.ammo.on_embed(src, organ)

			var/obj/item/shard/shrapnel/embedded = new P.ammo.shrapnel_type
			if(istype(embedded))
				embedded.on_embed(src, organ)

				if(!stat && !(species && species.flags & NO_PAIN))
					emote("scream")
					to_chat(src, SPAN_HIGHDANGER("You scream in pain as the impact sends <B>shrapnel</b> into the wound!"))

		if(ammo_flags & AMMO_INCENDIARY)
			adjust_fire_stacks(rand(6,11))
			IgniteMob()
			if(!stat && !(species.flags & NO_PAIN))
				emote("scream")
				to_chat(src, SPAN_HIGHDANGER("You burst into flames!! Stop drop and roll!"))
		return 1

//Deal with xeno bullets.
/mob/living/carbon/Xenomorph/bullet_act(obj/item/projectile/P)
	if(!P || !istype(P)) return
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ammo_flags & (AMMO_XENO_ACID|AMMO_XENO_TOX) ) //Aliens won't be harming aliens.
		//separate if to improve readability
		var/mob/living/carbon/Xenomorph/XNO = P.firer
		if(!istype(XNO) || XNO.hivenumber == hivenumber)
			bullet_ping(P)
			return -1

	if(ismob(P.weapon_source_mob))
		var/mob/M = P.weapon_source_mob
		M.track_shot_hit(P.weapon_source, src)

	flash_weak_pain()

	var/damage = max(0, P.damage - round(P.distance_travelled * P.damage_falloff)) //Has to be at least zero, no negatives.
	var/damage_result = damage

	if(damage > 0 && !(ammo_flags & AMMO_IGNORE_ARMOR))
		var/armor = armor_deflection + armor_deflection_buff
		if(isXenoQueen(src) || isXenoCrusher(src)) //Charging and crest resistances. Charging Xenos get a lot of extra armor, currently Crushers and Queens
			var/mob/living/carbon/Xenomorph/charger = src
			if(P.dir == reverse_direction(charger.dir)) armor += round(armor_deflection * (charger.charge_speed/charger.charge_speed_max) / 2) //Some armor deflection when charging.
			//Otherwise use the standard armor deflection for crushers.

		damage_result = armor_damage_reduction(config.xeno_ranged, damage, armor, P.ammo.penetration, P.ammo.pen_armor_punch, P.ammo.damage_armor_punch, armor_integrity)
		var/armor_punch = armor_break_calculation(config.xeno_ranged, damage, armor, P.ammo.penetration, P.ammo.pen_armor_punch, P.ammo.damage_armor_punch, armor_integrity)
		apply_armorbreak(armor_punch)

		if(damage <= 5)
			to_chat(src,SPAN_XENONOTICE("Your exoskeleton absorbs the force of [P]!"))
		if(damage <= 3)
			damage = 0
			bullet_ping(P)
			visible_message("<span class='avoidharm'>[src]'s thick exoskeleton deflects [P]!</span>")

	bullet_message(P) //Message us about the bullet, since damage was inflicted.

	if(damage)
		apply_damage(damage_result,P.ammo.damage_type, P.def_zone)	//Deal the damage.
		P.play_damage_effect(src)
		if(!stat && prob(5 + round(damage_result / 4)))
			var/pain_emote = prob(70) ? "hiss" : "roar"
			emote(pain_emote)
		if(ammo_flags & AMMO_INCENDIARY)
			if(caste.fire_immune)
				if(!stat) to_chat(src, "<span class='avoidharm'>You shrug off some persistent flames.</span>")
			else
				adjust_fire_stacks(rand(2,6) + round(damage_result / 8))
				IgniteMob()
				visible_message(SPAN_DANGER("[src] bursts into flames!"), \
				SPAN_XENODANGER("You burst into flames!! Auuugh! Resist to put out the flames!"))
		updatehealth()

	return 1

/turf/bullet_act(obj/item/projectile/P)
	if(!P || !density) return //It's just an empty turf

	bullet_ping(P)

	var/list/mobs_list = list() //Let's built a list of mobs on the bullet turf and grab one.
	for(var/mob/living/L in src)
		if(L in P.permutated) continue
		mobs_list += L

	if(mobs_list.len)
		var/mob/living/picked_mob = pick(mobs_list) //Hit a mob, if there is one.
		if(istype(picked_mob))
			picked_mob.bullet_act(P)
			return 1
	return 1

// walls can get shot and damaged, but bullets (vs energy guns) do much less.
/turf/closed/wall/bullet_act(obj/item/projectile/P)
	if(!..())
		return
	var/damage = P.damage
	if(damage < 1)
		return
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags

	switch(P.ammo.damage_type)
		if(BRUTE) //Rockets do extra damage to walls.
			if (ammo_flags & AMMO_ROCKET)
				damage = round(damage * 10)
		if(BURN)
			if(ammo_flags & AMMO_ENERGY)
				damage = round(damage * 7)
			else if(ammo_flags & AMMO_ANTISTRUCT) // Railgun does extra damage to turfs
				damage = round(damage * ANTISTRUCT_DMG_MULT_WALL)
		else
			return
	if(ammo_flags & AMMO_BALLISTIC)
		current_bulletholes++
	take_damage(damage)
	return 1


/turf/closed/wall/almayer/research/containment/bullet_act(obj/item/projectile/P)
	if(P)
		var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
		if(ammo_flags & AMMO_XENO_ACID)
			return //immune to acid spit
	. = ..()




//Hitting an object. These are too numerous so they're staying in their files.
//Why are there special cases listed here? Oh well, whatever. ~N
/obj/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	return 1

/obj/item/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	if(P.ammo.damage_type == BRUTE)
		explosion_throw(P.damage/2, P.dir, 4)
	return 1

/obj/structure/table/bullet_act(obj/item/projectile/P)
	src.bullet_ping(P)
	health -= round(P.damage/2)
	if (health < 0)
		visible_message(SPAN_WARNING("[src] breaks down!"))
		destroy()
	return 1


//----------------------------------------------------------
					//				    \\
					//    OTHER PROCS	\\
					//					\\
					//					\\
//----------------------------------------------------------


//This is where the bullet bounces off.
/atom/proc/bullet_ping(obj/item/projectile/P)
	if(!P || !P.ammo.ping)
		return

	if(P.ammo.sound_bounce) playsound(src, P.ammo.sound_bounce, 50, 1)
	var/image/I = image('icons/obj/items/weapons/projectiles.dmi',src,P.ammo.ping,10)
	var/angle = (P.firer && prob(60)) ? round(Get_Angle(P.firer,src)) : round(rand(1,359))
	I.pixel_x += rand(-6,6)
	I.pixel_y += rand(-6,6)

	var/matrix/rotate = matrix()
	rotate.Turn(angle)
	I.transform = rotate
	spawn(1) // Need to do this in order to prevent the ping from being deleted
		I.flick_overlay(src, 3)

/mob/proc/bullet_message(obj/item/projectile/P)
	if(!P) return
	var/ammo_flags = P.ammo.flags_ammo_behavior | P.projectile_override_flags
	if(ammo_flags & AMMO_IS_SILENCED)
		var/hit_msg = "You've been shot in the [parse_zone(P.def_zone)] by [P.name]!"
		to_chat(src, isXeno(src) ? SPAN_XENODANGER("[hit_msg]"):SPAN_HIGHDANGER("[hit_msg]"))
	else
		visible_message(SPAN_DANGER("[name] is hit by the [P.name] in the [parse_zone(P.def_zone)]!"), \
						SPAN_HIGHDANGER("You are hit by the [P.name] in the [parse_zone(P.def_zone)]!"), null, 4)

	if(P.weapon_source)
		last_damage_source = "[P.weapon_source]"
	else
		last_damage_source = initial(P.name)
	if(ismob(P.firer))
		var/mob/firingMob = P.firer
		last_damage_mob = firingMob
		if(ishuman(firingMob) && ishuman(src) && firingMob.mind && mind && mind.faction == firingMob.mind.faction) //One human shot another, be worried about it but do everything basically the same //special_role should be null or an empty string if done correctly
			attack_log += "\[[time_stamp()]\] <b>[firingMob]/[firingMob.ckey]</b> shot <b>[src]/[ckey]</b> with \a <b>[P]</b> in [get_area(firingMob)]."
			P.firer:attack_log += "\[[time_stamp()]\] <b>[firingMob]/[firingMob.ckey]</b> shot <b>[src]/[ckey]</b> with \a <b>[P]</b> in [get_area(firingMob)]."
			round_statistics.total_friendly_fire_instances++
			msg_admin_ff("[firingMob] ([firingMob.ckey]) shot [src] ([ckey]) with \a [P.name] in [get_area(firingMob)] (<A HREF='?_src_=admin_holder;adminplayerobservecoodjump=1;X=[P.firer.x];Y=[P.firer.y];Z=[P.firer.z]'>JMP</a>) (<a href='?priv_msg=\ref[firingMob.client]'>PM</a>)")
			if(ishuman(firingMob) && P.weapon_source)
				var/mob/living/carbon/human/H = firingMob
				H.track_friendly_fire(P.weapon_source)
		else
			if(P.weapon_source_mob)
				last_damage_mob = P.weapon_source_mob
			attack_log += "\[[time_stamp()]\] <b>[firingMob]/[firingMob.ckey]</b> shot <b>[src]/[src.ckey]</b> with \a <b>[P]</b> in [get_area(firingMob)]."
			P.firer:attack_log += "\[[time_stamp()]\] <b>[firingMob]/[firingMob.ckey]</b> shot <b>[src]/[ckey]</b> with \a <b>[P]</b> in [get_area(firingMob)]."
			msg_admin_attack("[firingMob] ([firingMob.ckey]) shot [src] ([ckey]) with \a [P.name] in [get_area(firingMob)] (<A HREF='?_src_=admin_holder;adminplayerobservecoodjump=1;X=[P.firer.x];Y=[P.firer.y];Z=[P.firer.z]'>JMP</a>)")
		return

	if(P.weapon_source_mob)
		last_damage_mob = P.weapon_source_mob

	attack_log += "\[[time_stamp()]\] <b>SOMETHING??</b> shot <b>[src]/[ckey]</b> with a <b>[P]</b>"
	msg_admin_attack("SOMETHING?? shot [src] ([ckey]) with a [P])")

//Abby -- Just check if they're 1 tile horizontal or vertical, no diagonals
/proc/get_adj_simple(atom/Loc1,atom/Loc2)
	var/dx = Loc1.x - Loc2.x
	var/dy = Loc1.y - Loc2.y

	if(dx == 0) //left or down of you
		if(dy == -1 || dy == 1)
			return 1
	if(dy == 0) //above or below you
		if(dx == -1 || dx == 1)
			return 1

#undef DEBUG_HIT_CHANCE
#undef DEBUG_HUMAN_DEFENSE
#undef DEBUG_XENO_DEFENSE
