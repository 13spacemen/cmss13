

/mob/living/carbon/Xenomorph/proc/Pounce(atom/T)
	if(!T) return

	if(T.layer >= FLY_LAYER)//anything above that shouldn't be pounceable (hud stuff)
		return

	var/pounce_type = "pounc"
	if(isXenoRavager(src))
		pounce_type = "charg"

	if(!isturf(loc))
		to_chat(src, SPAN_XENOWARNING("You can't [pounce_type]e from here!"))
		return

	if(!check_state())
		return

	if(used_pounce)
		to_chat(src, SPAN_XENOWARNING("You must wait before [pounce_type]ing."))
		return

	if(!check_plasma(10))
		return

	if(legcuffed)
		to_chat(src, SPAN_XENODANGER("You can't [pounce_type]e with that thing on your leg!"))
		return

	if(layer == XENO_HIDING_LAYER) //Xeno is currently hiding, unhide him
		layer = MOB_LAYER

	if(m_intent == MOVE_INTENT_WALK && isXenoLurker(src)) //Hunter that is currently using its stealth ability, need to unstealth him
		toggle_mov_intent()

	if(isXenoRavager(src))
		emote("roar")

	visible_message(SPAN_XENOWARNING("\The [src] [pounce_type]es at [T]!"), \
	SPAN_XENOWARNING("You [pounce_type]e at [T]!"))
	used_pounce = 1
	flags_pass = PASSTABLE
	use_plasma(10)
	throw_at(T, caste.charge_distance + mutators.pounce_boost, caste.charge_speed, src) //Victim, distance, speed
	spawn(6)
		if(!hardcore)
			flags_pass = initial(flags_pass) //Reset the passtable.
		else
			flags_pass = 0 //Reset the passtable.

	spawn(caste.pounce_delay)
		used_pounce = 0
		to_chat(src, SPAN_NOTICE("You get ready to [pounce_type]e again."))
		for(var/X in actions)
			var/datum/action/A = X
			A.update_button_icon()

	return 1


// Praetorian acid spray
/mob/living/carbon/Xenomorph/proc/acid_spray_cone(atom/A)
	if (!A || !check_state())
		return

	if (used_acid_spray)
		to_chat(src, SPAN_XENOWARNING("You must wait to produce enough acid to spray."))
		return

	if (!check_plasma(200))
		to_chat(src, SPAN_XENOWARNING("You must produce more plasma before doing this."))
		return

	var/turf/target

	if (isturf(A))
		target = A
	else
		target = get_turf(A)

	if (target == loc || !target || action_busy)
		return

	if(!do_after(src, acid_spray_activation_time, INTERRUPT_NO_NEEDHAND, BUSY_ICON_HOSTILE))
		return

	if (used_acid_spray)
		return

	if (!check_plasma(200))
		return

	used_acid_spray = 1
	use_plasma(200)
	playsound(loc, 'sound/effects/refill.ogg', 25, 1)
	visible_message(SPAN_XENOWARNING("\The [src] spews forth a wide cone of acid!"), \
	SPAN_XENOWARNING("You spew forth a cone of acid!"), null, 5)

	to_chat(src, SPAN_XENOWARNING("Unleashing your acid spray temporarily slows you down!"))
	ability_speed_modifier += 2
	do_acid_spray_cone(target)
	spawn(rand(20,30))
		ability_speed_modifier = 0

	spawn(caste.acid_spray_cooldown)
		used_acid_spray = 0
		to_chat(src, SPAN_NOTICE("You have produced enough acid to spray again."))

/mob/living/carbon/Xenomorph/proc/do_acid_spray_cone(var/turf/T)
	set waitfor = 0

	var/facing = get_cardinal_dir(src, T)
	dir = facing

	T = loc
	for (var/i in 0 to caste.acid_spray_range-1)

		var/turf/next_T = get_step(T, facing)

		for (var/obj/O in T)
			if(!O.CheckExit(src, next_T))
				if(istype(O, /obj/structure/barricade))
					var/obj/structure/barricade/B = O
					B.health -= rand(20, 30)
					B.update_health(1)
				return

		T = next_T

		if (T.density)
			return

		for (var/obj/O in T)
			if(!O.CanPass(src, loc))
				if(istype(O, /obj/structure/barricade))
					var/obj/structure/barricade/B = O
					B.health -= rand(20, 30)
					B.update_health(1)
				return

		var/obj/effect/xenomorph/spray/S = acid_splat_turf(T)
		do_acid_spray_cone_normal(T, i, facing, S)
		sleep(3)

//Acid Spray
/mob/living/carbon/Xenomorph/proc/acid_spray(atom/T)
	if(!T || !check_state() || used_acid_spray) 
		return

	if(!isturf(loc) || istype(loc, /turf/open/space))
		to_chat(src, SPAN_WARNING("You can't do that from there.</span>"))
		return

	if(!check_plasma(10) || used_acid_spray)
		return

	var/turf/target
	if(isturf(T))
		target = T
	else
		target = get_turf(T)

	if(!istype(target)) //Something went horribly wrong. Clicked off edge of map probably
		return

	if(target == loc)
		to_chat(src, SPAN_WARNING("That's far too close!"))
		return

	if(!target || action_busy)
		return

	if(!do_after(src, acid_spray_activation_time, INTERRUPT_NO_NEEDHAND, BUSY_ICON_HOSTILE))
		to_chat(src, SPAN_WARNING("You decide to cancel your acid spray."))
		return

	used_acid_spray = 1

	use_plasma(10)
	playsound(src.loc, 'sound/effects/refill.ogg', 25, 1)
	visible_message(SPAN_XENOWARNING("\The [src] spews forth a virulent spray of acid!"), \
	SPAN_XENOWARNING("You spew forth a spray of acid!"), null, 5)
	var/turflist = getline(src, target)
	spray_turfs(turflist)
	spawn(caste.acid_spray_cooldown) //12 second cooldown.
		used_acid_spray = 0
		to_chat(src, SPAN_WARNING("You feel your acid glands refill. You can spray acid again."))
		for(var/X in actions)
			var/datum/action/A = X
			A.update_button_icon()


/mob/living/carbon/Xenomorph/proc/spray_turfs(list/turflist)
	set waitfor = 0

	if(isnull(turflist))
		return
	var/turf/prev_turf
	var/distance = 0
	var/distance_max = 5

	if(isXenoBoiler(src))
		distance_max = 7
	else if (isXenoPraetorian(src))
		distance_max = 6

	turf_loop:
		for(var/turf/T in turflist)
			distance++

			if(!prev_turf && turflist.len > 1)
				prev_turf = get_turf(src)
				continue //So we don't burn the tile we be standin on

			if(T.density || istype(T, /turf/open/space))
				break
			if(distance > distance_max)
				break

			if(locate(/obj/structure/girder, T))
				break //Nope.avi

			var/obj/structure/machinery/M = locate() in T
			if(M)
				if(M.density)
					break

			if(prev_turf && LinkBlocked(prev_turf, T))
				break

			for(var/obj/structure/barricade/B in T)
				B.health -= rand(20, 30)
				B.update_health(TRUE)
				if(prev_turf)
					if(get_dir(B, prev_turf) & B.dir)
						break turf_loop

			if(!check_plasma(10))
				break
			plasma_stored -= 10
			prev_turf = T
			splat_turf(T)
			sleep(2)

/mob/living/carbon/Xenomorph/proc/splat_turf(var/turf/target)
	if(!istype(target) || istype(target,/turf/open/space))
		return

	if(!locate(/obj/effect/xenomorph/spray) in target) //No stacking flames!

		// Spray type
		if (isXenoSpitter(src)) new /obj/effect/xenomorph/spray/weak(target, , initial(caste_name), src)
		else new /obj/effect/xenomorph/spray(target,  , initial(caste_name), src)

		for(var/mob/living/carbon/M in target)
			if(ishuman(M))
				if((M.status_flags & XENO_HOST) && istype(M.buckled, /obj/structure/bed/nest))
					continue //nested infected hosts are not hurt by acid spray
				M.adjustFireLoss(rand(20 + 5 * upgrade, 30 + 5 * upgrade))
				to_chat(M, SPAN_XENODANGER("\The [src] showers you in corrosive acid!"))
				if(!isYautja(M))
					M.emote("scream")
					if(isXenoBoiler(src))
						M.KnockDown(rand(3, 4))
					else if (isXenoPraetorian(src))
						M.KnockDown(rand(1,3))

// Normal refers to the mathematical normal
/mob/living/carbon/Xenomorph/proc/do_acid_spray_cone_normal(turf/T, distance, facing, obj/effect/xenomorph/spray/source_spray)
	if (!distance)
		return

	var/obj/effect/xenomorph/spray/left_S = source_spray
	var/obj/effect/xenomorph/spray/right_S = source_spray

	var/normal_dir = turn(facing, 90)
	var/inverse_normal_dir = turn(facing, -90)

	var/turf/normal_turf = T
	var/turf/inverse_normal_turf = T

	var/normal_density_flag = 0
	var/inverse_normal_density_flag = 0

	for (var/i in 0 to distance-1)
		if (normal_density_flag && inverse_normal_density_flag)
			return

		if (!normal_density_flag)
			var/next_normal_turf = get_step(normal_turf, normal_dir)

			for (var/obj/O in normal_turf)
				if(!O.CheckExit(left_S, next_normal_turf))
					if(istype(O, /obj/structure/barricade))
						var/obj/structure/barricade/B = O
						B.health -= rand(20, 30)
						B.update_health(1)
					normal_density_flag = 1
					break

			normal_turf = next_normal_turf

			if(!normal_density_flag)
				normal_density_flag = normal_turf.density

			if(!normal_density_flag)
				for (var/obj/O in normal_turf)
					if(!O.CanPass(left_S, left_S.loc))
						if(istype(O, /obj/structure/barricade))
							var/obj/structure/barricade/B = O
							B.health -= rand(20, 30)
							B.update_health(1)
						normal_density_flag = 1
						break

			if (!normal_density_flag)
				left_S = acid_splat_turf(normal_turf)


		if (!inverse_normal_density_flag)

			var/next_inverse_normal_turf = get_step(inverse_normal_turf, inverse_normal_dir)

			for (var/obj/O in inverse_normal_turf)
				if(!O.CheckExit(right_S, next_inverse_normal_turf))
					if(istype(O, /obj/structure/barricade))
						var/obj/structure/barricade/B = O
						B.health -= rand(20, 30)
						B.update_health(1)
					inverse_normal_density_flag = 1
					break

			inverse_normal_turf = next_inverse_normal_turf

			if(!inverse_normal_density_flag)
				inverse_normal_density_flag = inverse_normal_turf.density

			if(!inverse_normal_density_flag)
				for (var/obj/O in inverse_normal_turf)
					if(!O.CanPass(right_S, right_S.loc))
						if(istype(O, /obj/structure/barricade))
							var/obj/structure/barricade/B = O
							B.health -= rand(20, 30)
							B.update_health(1)
						inverse_normal_density_flag = 1
						break

			if (!inverse_normal_density_flag)
				right_S = acid_splat_turf(inverse_normal_turf)



/mob/living/carbon/Xenomorph/proc/acid_splat_turf(var/turf/T)
	. = locate(/obj/effect/xenomorph/spray) in T
	if(!.)
		. = new /obj/effect/xenomorph/spray(T, , initial(caste_name), src)

		// This should probably be moved into obj/effect/xenomorph/spray or something
		for (var/obj/structure/barricade/B in T)
			B.health -= rand(20, 30)
			B.update_health(1)

		for (var/mob/living/carbon/C in T)
			if (!ishuman(C) && !ismonkey(C))
				continue

			if ((C.status_flags & XENO_HOST) && istype(C.buckled, /obj/structure/bed/nest))
				continue

			C.adjustFireLoss(rand(20,30) + 5 * upgrade)
			to_chat(C, SPAN_XENODANGER("\The [src] showers you in corrosive acid!"))

			if (!isYautja(C))
				C.emote("scream")
				C.KnockDown(rand(3, 4))


// Warrior Fling
/mob/living/carbon/Xenomorph/proc/fling(atom/A)

	if (!A || !istype(A, /mob/living/carbon/human))
		return

	if (!check_state() || agility)
		return

	if (used_fling)
		to_chat(src, SPAN_XENOWARNING("You must gather your strength before flinging something."))
		return

	if (!check_plasma(10))
		return

	if (!Adjacent(A))
		return

	var/mob/living/carbon/human/H = A
	if(H.stat == DEAD) return
	if(istype(H.buckled, /obj/structure/bed/nest)) return

	visible_message(SPAN_XENOWARNING("\The [src] effortlessly flings [H] to the side!"), \
	SPAN_XENOWARNING("You effortlessly fling [H] to the side!"))
	playsound(H,'sound/weapons/alien_claw_block.ogg', 75, 1)
	used_fling = 1
	use_plasma(10)
	H.apply_effect(1, STUN)
	H.apply_effect(2, WEAKEN)
	H.last_damage_mob = src
	H.last_damage_source = initial(caste_name)
	shake_camera(H, 2, 1)

	var/facing = get_dir(src, H)
	var/fling_distance = 4
	var/turf/T = loc
	var/turf/temp = loc

	for (var/x in 0 to fling_distance-1)
		temp = get_step(T, facing)
		if (!temp)
			break
		T = temp

	H.throw_at(T, fling_distance, 1, src, 1)

	spawn(caste.fling_cooldown)
		used_fling = 0
		to_chat(src, SPAN_NOTICE("You gather enough strength to fling something again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()

/mob/living/carbon/Xenomorph/proc/punch(atom/A)

	if (!A || !ishuman(A))
		return

	if (!check_state() || agility)
		return

	if (used_punch)
		to_chat(src, SPAN_XENOWARNING("You must gather your strength before punching."))
		return

	if (!check_plasma(10))
		return

	if (!Adjacent(A))
		return

	var/mob/living/carbon/human/H = A
	if(H.stat == DEAD) return
	if(istype(H.buckled, /obj/structure/bed/nest)) return
	if(H.status_flags & XENO_HOST)
		to_chat(src, SPAN_XENOWARNING("This would harm the embryo!"))
		return
	var/datum/limb/L = H.get_limb(check_zone(zone_selected))

	if (!L || (L.status & LIMB_DESTROYED))
		return

	H.last_damage_mob = src
	H.last_damage_source = initial(caste_name)
	visible_message(SPAN_XENOWARNING("\The [src] hits [H] in the [L.display_name] with a devastatingly powerful punch!"), \
	SPAN_XENOWARNING("You hit [H] in the [L.display_name] with a devastatingly powerful punch!"))
	var/S = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
	playsound(H,S, 50, 1)
	used_punch = 1
	use_plasma(10)

	if(!boxer)

		if(L.status & LIMB_SPLINTED) //If they have it splinted, the splint won't hold.
			L.status &= ~LIMB_SPLINTED
			to_chat(H, SPAN_DANGER("The splint on your [L.display_name] comes apart!"))

		if(isYautja(H))
			L.take_damage(rand(8,12))
		else if(L.status & LIMB_ROBOT)
			L.take_damage(rand(30,40), 0, 0) // just do more damage
		else
			var/fracture_chance = 100
			switch(L.body_part)
				if(HEAD)
					fracture_chance = 20
				if(UPPER_TORSO)
					fracture_chance = 30
				if(LOWER_TORSO)
					fracture_chance = 40

			L.take_damage(rand(15,25), 0, 0)
			if(prob(fracture_chance))
				L.fracture()

		shake_camera(H, 2, 1)
		step_away(H, src, 2)

	if(boxer)
		if(isYautja(H))
			L.take_damage(rand(12, 16))
		else if(L.status & LIMB_ROBOT)
			L.take_damage(rand(40, 50), 0, 0) // just do more damage
		else
			L.take_damage(rand(25, 30), 0, 0)
			if(L.body_part == HEAD)
				var/knockdown_chance = 14
				if(prob(knockdown_chance))
					H.KnockDown(1)

		shake_camera(H, 3, 1)

		if(H.lying)
			step_away(H, src, 3)
			H.KnockDown(1)
		else
			step_away(H, src, 2)

	spawn(caste.punch_cooldown)
		used_punch = 0
		to_chat(src, SPAN_NOTICE("You gather enough strength to punch again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()

/mob/living/carbon/Xenomorph/proc/lunge(atom/A)

	if (!A)
		return

	if (!isturf(loc))
		to_chat(src, SPAN_XENOWARNING("You can't lunge from here!"))
		return

	if (!check_state() || agility)
		return

	if (used_lunge)
		to_chat(src, SPAN_XENOWARNING("You must gather your strength before lunging."))
		return

	if (!check_plasma(10))
		return

	if(!isHumanStrict(A) && !ismonkey(A))
		used_lunge = 1
		spawn(15)
			used_lunge = 0
		return

	var/mob/living/carbon/human/H = A
	if(H.stat == DEAD) return
	visible_message(SPAN_XENOWARNING("\The [src] lunges towards [H]!"), \
	SPAN_XENOWARNING("You lunge at [H]!"))

	used_lunge = 1 // triggered by start_pulling
	use_plasma(10)
	throw_at(get_step_towards(A, src), 6, 2, src)

	if (Adjacent(H))
		start_pulling(H,1)

	if(used_lunge == 1)
		spawn(caste.lunge_cooldown)
			used_lunge = 0
			to_chat(src, SPAN_NOTICE("You get ready to lunge again."))
			for(var/X in actions)
				var/datum/action/act = X
				act.update_button_icon()

	return 1

// Called when pulling something and attacking yourself with the pull
/mob/living/carbon/Xenomorph/proc/pull_power(var/mob/M)
	if (isXenoWarrior(src) && !ripping_limb && M.stat != DEAD)
		if(M.status_flags & XENO_HOST)
			to_chat(src, SPAN_XENOWARNING("This would harm the embryo!"))
			return
		ripping_limb = 1
		if(rip_limb(M))
			stop_pulling()
		ripping_limb = 0


// Warrior Rip Limb - called by pull_power()
/mob/living/carbon/Xenomorph/proc/rip_limb(var/mob/M)
	if (!istype(M, /mob/living/carbon/human))
		return 0

	if(action_busy) //can't stack the attempts
		return 0

	var/mob/living/carbon/human/H = M
	var/datum/limb/L = H.get_limb(check_zone(zone_selected))

	if (!L || L.body_part == UPPER_TORSO || L.body_part == LOWER_TORSO || (L.status & LIMB_DESTROYED)) //Only limbs and head.
		to_chat(src, SPAN_XENOWARNING("You can't rip off that limb."))
		return 0
	var/limb_time = rand(40,60)

	if (L.body_part == HEAD)
		limb_time = rand(90,110)

	visible_message(SPAN_XENOWARNING("\The [src] begins pulling on [M]'s [L.display_name] with incredible strength!"), \
	SPAN_XENOWARNING("You begin to pull on [M]'s [L.display_name] with incredible strength!"))

	if(!do_after(src, limb_time, INTERRUPT_ALL|INTERRUPT_DIFF_SELECT_ZONE, BUSY_ICON_HOSTILE) || M.stat == DEAD)
		to_chat(src, SPAN_NOTICE("You stop ripping off the limb."))
		return 0

	if(L.status & LIMB_DESTROYED)
		return 0

	if(L.status & LIMB_ROBOT)
		L.take_damage(rand(30,40), 0, 0) // just do more damage
		visible_message(SPAN_XENOWARNING("You hear [M]'s [L.display_name] being pulled beyond its load limits!"), \
		SPAN_XENOWARNING("\The [M]'s [L.display_name] begins to tear apart!"))
	else
		visible_message(SPAN_XENOWARNING("You hear the bones in [M]'s [L.display_name] snap with a sickening crunch!"), \
		SPAN_XENOWARNING("\The [M]'s [L.display_name] bones snap with a satisfying crunch!"))
		L.take_damage(rand(15,25), 0, 0)
		L.fracture()
	M.last_damage_source = initial(name)
	M.last_damage_mob = src
	src.attack_log += text("\[[time_stamp()]\] <font color='red'>ripped the [L.display_name] off of [M.name] ([M.ckey]) 1/2 progress</font>")
	M.attack_log += text("\[[time_stamp()]\] <font color='orange'>had their [L.display_name] ripped off by [src.name] ([src.ckey]) 1/2 progress</font>")
	log_attack("[src.name] ([src.ckey]) ripped the [L.display_name] off of [M.name] ([M.ckey]) 1/2 progress")

	if(!do_after(src, limb_time, INTERRUPT_ALL|INTERRUPT_DIFF_SELECT_ZONE, BUSY_ICON_HOSTILE)  || M.stat == DEAD || iszombie(M))
		to_chat(src, SPAN_NOTICE("You stop ripping off the limb."))
		return 0

	if(L.status & LIMB_DESTROYED)
		return 0

	visible_message(SPAN_XENOWARNING("\The [src] rips [M]'s [L.display_name] away from \his body!"), \
	SPAN_XENOWARNING("\The [M]'s [L.display_name] rips away from \his body!"))
	src.attack_log += text("\[[time_stamp()]\] <font color='red'>ripped the [L.display_name] off of [M.name] ([M.ckey]) 2/2 progress</font>")
	M.attack_log += text("\[[time_stamp()]\] <font color='orange'>had their [L.display_name] ripped off by [src.name] ([src.ckey]) 2/2 progress</font>")
	log_attack("[src.name] ([src.ckey]) ripped the [L.display_name] off of [M.name] ([M.ckey]) 2/2 progress")

	L.droplimb(0, 0, initial(name))

	return 1


// Warrior Agility
/mob/living/carbon/Xenomorph/proc/toggle_agility()
	if (!check_state(1))
		return

	if (used_toggle_agility)
		return

	agility = !agility

	if (agility)
		to_chat(src, SPAN_XENOWARNING("You lower yourself to all fours."))
	else
		to_chat(src, SPAN_XENOWARNING("You raise yourself to stand on two feet."))
	recalculate_speed()
	update_icons()
	do_agility_cooldown()

/mob/living/carbon/Xenomorph/proc/do_agility_cooldown()
	spawn(caste.toggle_agility_cooldown)
		used_toggle_agility = 0
		to_chat(src, SPAN_NOTICE("You can [agility ? "raise yourself back up" : "lower yourself back down"] again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()


// Defender Headbutt
/mob/living/carbon/Xenomorph/proc/headbutt(var/mob/M)
	if (!M || !istype(M, /mob/living/carbon/human))
		return

	if (fortify)
		to_chat(src, SPAN_XENOWARNING("You cannot use abilities while fortified."))
		return

	if (crest_defense && !spiked)
		to_chat(src, SPAN_XENOWARNING("You cannot use abilities with your crest lowered."))
		return

	if (!check_state())
		return

	if (used_headbutt)
		to_chat(src, SPAN_XENOWARNING("You must gather your strength before headbutting."))
		return

	if (!check_plasma(10))
		return

	var/mob/living/carbon/human/H = M
	if(H.stat == DEAD)
		return

	var/distance = get_dist(src, H)

	var/max_distance = 2 + spiked

	if (distance > max_distance)
		return

	if (distance > 1)
		step_towards(src, H, max_distance)

	if (!Adjacent(H))
		return

	H.last_damage_mob = src
	H.last_damage_source = initial(caste_name)
	visible_message(SPAN_XENOWARNING("\The [src] rams [H] with its armored crest!"), \
	SPAN_XENOWARNING("You ram [H] with your armored crest!"))

	used_headbutt = 1
	use_plasma(10)

	if(H.stat != DEAD && (!(H.status_flags & XENO_HOST) || !istype(H.buckled, /obj/structure/bed/nest)) )
		var/h_damage = 20 + (spiked * 5)
		H.apply_damage(h_damage)
		shake_camera(H, 2, 1)

	var/facing = get_dir(src, H)
	var/headbutt_distance = spiked + 3
	var/turf/T = loc
	var/turf/temp = loc

	for (var/x in 0 to headbutt_distance-1)
		temp = get_step(T, facing)
		if (!temp)
			break
		T = temp

	H.throw_at(T, headbutt_distance, 1, src)
	playsound(H,'sound/weapons/alien_claw_block.ogg', 50, 1)
	spawn(caste.headbutt_cooldown)
		used_headbutt = 0
		to_chat(src, SPAN_NOTICE("You gather enough strength to headbutt again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()


// Defender Tail Sweep
/mob/living/carbon/Xenomorph/proc/tail_sweep()
	if (fortify)
		to_chat(src, SPAN_XENOWARNING("You cannot use abilities while fortified."))
		return

	if (crest_defense)
		to_chat(src, SPAN_XENOWARNING("You cannot use abilities with your crest lowered."))
		return

	if (!check_state())
		return

	if (used_tail_sweep)
		to_chat(src, SPAN_XENOWARNING("You must gather your strength before tail sweeping."))
		return

	if (!check_plasma(10))
		return

	visible_message(SPAN_XENOWARNING("\The [src] sweeps its tail in a wide circle!"), \
	SPAN_XENOWARNING("You sweep your tail in a wide circle!"))

	spin_circle()

	var/sweep_range = 1
	var/list/L = orange(sweep_range)		// Not actually the fruit

	for (var/mob/living/carbon/human/H in L)
		if(H != H.handle_barriers(src)) continue
		if(H.stat == DEAD) continue
		if(istype(H.buckled, /obj/structure/bed/nest)) continue
		step_away(H, src, sweep_range, 2)
		H.last_damage_mob = src
		H.last_damage_source = initial(caste_name)
		H.apply_damage(10)
		shake_camera(H, 2, 1)

		if(isXenoDefender(src))
			if (prob(50))
				H.KnockDown(2, 1)

		if(isXenoPraetorian(src))
			H.KnockDown(2, 1)

		to_chat(H, SPAN_XENOWARNING("You are struck by \the [src]'s tail sweep!"))
		playsound(H,'sound/weapons/alien_claw_block.ogg', 50, 1)
	used_tail_sweep = 1
	use_plasma(10)
	
	spawn(caste.tail_sweep_cooldown)
		used_tail_sweep = 0
		to_chat(src, SPAN_NOTICE("You gather enough strength to tail sweep again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()


// Defender Crest Defense
/mob/living/carbon/Xenomorph/proc/toggle_crest_defense()

	if (fortify)
		to_chat(src, SPAN_XENOWARNING("You cannot use abilities while fortified."))
		return

	if (!check_state())
		return

	if (used_crest_defense)
		return

	crest_defense = !crest_defense
	used_crest_defense = 1

	if (crest_defense)
		to_chat(src, SPAN_XENOWARNING("You lower your crest."))
		armor_deflection_buff += 15
		ability_speed_modifier += 0.7	// This is actually a slowdown but speed is dumb
		update_icons()
		do_crest_defense_cooldown()
		return

	to_chat(src, SPAN_XENOWARNING("You raise your crest."))
	armor_deflection_buff -= 15
	ability_speed_modifier = 0
	update_icons()
	do_crest_defense_cooldown()

/mob/living/carbon/Xenomorph/proc/do_crest_defense_cooldown()
	spawn(caste.crest_defense_cooldown)
		used_crest_defense = 0
		to_chat(src, SPAN_NOTICE("You can [crest_defense ? "raise" : "lower"] your crest."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()


// Defender Fortify
/mob/living/carbon/Xenomorph/proc/fortify()
	if(crest_defense && spiked)
		to_chat(src, SPAN_XENOWARNING("You cannot fortify while your crest is already down!"))
		return

	if (crest_defense)
		to_chat(src, SPAN_XENOWARNING("You cannot use abilities with your crest lowered."))
		return

	if (!check_state())
		return

	if (used_fortify)
		return

	fortify = !fortify
	used_fortify = 1

	if (fortify)
		to_chat(src, SPAN_XENOWARNING("You tuck yourself into a defensive stance."))
		armor_deflection_buff += 40
		armor_explosive_buff += 60
		if(!spiked)
			frozen = 1
			anchored = 1
			update_canmove()
		if(spiked)
			ability_speed_modifier += 2.5
		update_icons()
		do_fortify_cooldown()
		fortify_timer = world.timeofday + 90		// How long we can be fortified
		process_fortify()
		playsound(loc, 'sound/effects/stonedoor_openclose.ogg', 30, 1)
		return

	fortify_off()
	do_fortify_cooldown()

/mob/living/carbon/Xenomorph/proc/process_fortify()
	set background = 1

	spawn while (fortify)
		if (world.timeofday > fortify_timer)
			fortify = 0
			fortify_off()
		sleep(10)	// Process every second.

/mob/living/carbon/Xenomorph/proc/fortify_off()
	to_chat(src, SPAN_XENOWARNING("You resume your normal stance."))
	armor_deflection_buff -= 40
	armor_explosive_buff -= 60
	frozen = 0
	anchored = 0
	if(spiked)
		ability_speed_modifier -= 2.5
	playsound(loc, 'sound/effects/stonedoor_openclose.ogg', 30, 1)
	update_canmove()
	update_icons()

/mob/living/carbon/Xenomorph/proc/do_fortify_cooldown()
	spawn(caste.fortify_cooldown)
		used_fortify = 0
		to_chat(src, SPAN_NOTICE("You can [fortify ? "stand up" : "fortify"] again."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()


//Burrower Abilities
/mob/living/carbon/Xenomorph/proc/burrow()
	if (!check_state())
		return

	if (used_burrow || tunnel || is_ventcrawling || action_busy)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	if(istype(T, /turf/open/floor/almayer/research/containment))
		to_chat(src, SPAN_XENOWARNING("You can't escape this cell!"))
		return

	if(clone) //Prevents burrowing on stairs
		to_chat(src, SPAN_XENOWARNING("You can't burrow here!"))
		return

	used_burrow = 1

	if (!burrow)
		to_chat(src, SPAN_XENOWARNING("You begin burrowing yourself into the ground."))
		if(!do_after(src, 15, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
			do_burrow_cooldown()
			return
		// TODO Make immune to all damage here.
		to_chat(src, SPAN_XENOWARNING("You burrow yourself into the ground."))
		burrow = 1
		frozen = 1
		invisibility = 101
		anchored = 1
		density = 0
		update_canmove()
		update_icons()
		do_burrow_cooldown()
		burrow_timer = world.timeofday + 90		// How long we can be burrowed
		process_burrow()
		return

	burrow_off()

/mob/living/carbon/Xenomorph/proc/process_burrow()
	set background = 1

	spawn while (burrow)
		if (world.timeofday > burrow_timer && !tunnel)
			burrow = 0
			burrow_off()
		if (observed_xeno)
			overwatch(observed_xeno, TRUE)
		sleep(10)	// Process every second.

/mob/living/carbon/Xenomorph/proc/burrow_off()

	to_chat(src, SPAN_NOTICE("You resurface."))
	frozen = 0
	invisibility = 0
	anchored = 0
	density = 1
	for(var/mob/living/carbon/human/H in loc)
		H.KnockDown(2)
	do_burrow_cooldown()
	update_canmove()
	update_icons()

/mob/living/carbon/Xenomorph/proc/do_burrow_cooldown()
	spawn(caste.burrow_cooldown)
		used_burrow = 0
		to_chat(src, SPAN_NOTICE("You can now surface."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()


/mob/living/carbon/Xenomorph/proc/tunnel(var/turf/T)
	if (!burrow)
		to_chat(src, SPAN_NOTICE("You must be burrowed to do this."))
		return

	if (used_tunnel)
		to_chat(src, SPAN_NOTICE("You must wait some time to do this."))
		return

	if (!T)
		to_chat(src, SPAN_NOTICE("You can't tunnel there!"))
		return

	if (T.density)
		to_chat(src, SPAN_XENOWARNING("You can't tunnel into a solid wall!"))
		return

	if (clone) //Prevents tunnels in Z transition areas
		to_chat(src, SPAN_XENOWARNING("You make tunnels, not wormholes!"))
		return

	var/area/A = get_area(T)
	if (A.flags_atom & AREA_NOTUNNEL)
		to_chat(src, SPAN_XENOWARNING("There's no way to tunnel over there."))
		return

	for(var/obj/O in T.contents)
		if(O.density)
			if(O.flags_atom & ON_BORDER)
				continue
			to_chat(src, SPAN_WARNING("There's something solid there to stop you emerging."))
			return

	if (tunnel)
		tunnel = 0
		to_chat(src, SPAN_NOTICE("You stop tunneling."))
		used_tunnel = 1
		do_tunnel_cooldown()
		return

	if (!T || T.density)
		to_chat(src, SPAN_NOTICE("You cannot tunnel to there!"))
	tunnel = 1
	to_chat(src, SPAN_NOTICE("You start tunneling!"))
	tunnel_timer = (get_dist(src, T)*10) + world.timeofday
	process_tunnel(T)


/mob/living/carbon/Xenomorph/proc/process_tunnel(var/turf/T)
	set background = 1

	spawn while (tunnel && T)
		if (world.timeofday > tunnel_timer)
			tunnel = 0
			do_tunnel(T)
		sleep(10)	// Process every second.

/mob/living/carbon/Xenomorph/proc/do_tunnel(var/turf/T)
	to_chat(src, SPAN_NOTICE("You tunnel to your destination."))
	anchored = 0
	frozen = 0
	update_canmove()
	forceMove(T)
	burrow = 0
	burrow_off()

/mob/living/carbon/Xenomorph/proc/do_tunnel_cooldown()
	spawn(caste.tunnel_cooldown)
		used_tunnel = 0
		to_chat(src, SPAN_NOTICE("You can now tunnel while burrowed."))
		for(var/X in actions)
			var/datum/action/act = X
			act.update_button_icon()

/mob/living/carbon/Xenomorph/proc/rename_tunnel(var/obj/structure/tunnel/T in oview(1))
	set name = "Rename Tunnel"
	set desc = "Rename the tunnel."
	set category = null

	if(!istype(T))
		return

	var/new_name = copytext(sanitize(input("Change the description of the tunnel:", "Tunnel Description") as text|null), 1, MAX_MESSAGE_LEN)
	if(new_name)
		new_name = "[new_name] ([get_area_name(T)])"
		log_admin("[key_name(src)] has renamed the tunnel \"[T.tunnel_desc]\" as \"[new_name]\".")
		msg_admin_niche("[src]/([key_name(src)]) has renamed the tunnel \"[T.tunnel_desc]\" as \"[new_name]\".")
		T.tunnel_desc = "[new_name]"
	return

// Ravager Empower
/mob/living/carbon/Xenomorph/proc/empower()
	var/datum/caste_datum/ravager/rCaste = src.caste

	if (!check_state())
		return

	if (used_lunge)
		to_chat(src, SPAN_XENOWARNING("You must gather your strength before using empower again."))
		return

	if (!check_plasma(100))
		to_chat(src, SPAN_XENOWARNING("You don't have enough plasma! You need [100-src.plasma_stored] more.</span>"))
		return

	visible_message(SPAN_XENOWARNING("[src] gets empowered by the surrounding enemies!"), SPAN_XENOWARNING("You feel a rush of power from the surrounding enemies!"))

	create_empower()

	var/range = 2
	var/list/mobs_in_range = orange(range)
	// Spook patrol
	emote("tail")

	var/accumulative_health = 0
	for(var/mob/living/carbon/human/H in mobs_in_range)
		if(H.stat == DEAD || istype(H.buckled, /obj/structure/bed/nest))
			continue

		accumulative_health += round(max_overheal/XENO_ENEMIES_FOR_MAXOVERHEAL)

		shake_camera(H, 2, 1)

		if(accumulative_health >= max_overheal)
			accumulative_health = max_overheal
			break

	set_overheal(accumulative_health)

	used_lunge = 1
	use_plasma(100)

	add_timer(CALLBACK(src, .proc/empower_cooldown), rCaste.empower_cooldown)

// Adds overheal to the xeno
/mob/living/carbon/Xenomorph/proc/set_overheal(var/added_health)
	if(added_health > max_overheal)
		added_health = max_overheal

	overheal = added_health

	updatehealth()

// Cooldown proc for Ravager Empower
/mob/living/carbon/Xenomorph/proc/empower_cooldown()
	used_lunge = 0
	to_chat(src, SPAN_NOTICE("You gather enough strength to use your empower again."))
	for(var/X in actions)
		var/datum/action/act = X
		act.update_button_icon()

// Praetorain screech ability. Varies based on the strain of the Praetorian
/mob/living/carbon/Xenomorph/proc/praetorian_screech()
	set waitfor = 0

	var/mob/living/carbon/Xenomorph/Praetorian/P = src

	if(!check_state())
		return

	if(has_screeched)
		to_chat(src, SPAN_WARNING("You are not ready to screech again."))
		return

	if(!check_plasma(300))
		return

	var/datum/caste_datum/praetorian/pCaste = src.caste
	var/screechwave_color = null

	// Time to screech
	has_screeched = 1
	use_plasma(300)
	var/screech_cooldown = 600 // Initialized later on but just making sure we get a solid default

	playsound(loc, P.screech_sound_effect, 45, 0)
	visible_message("<span class='xenohighdanger'>\The [src] roars loudly!</span>")

	for(var/mob/M in view())
		if(M && M.client)
			if(!isXeno(M))
				shake_camera(M, 10, 1)

	switch(P.mutation_type)
		if (PRAETORIAN_NORMAL)

			screechwave_color =  "#b7d728" // "Acid" green

			gain_health(pCaste.xenoheal_screech_healamount)
			to_chat(src, SPAN_XENOWARNING("Your screech reinvigorates you!"))
			var/range = 7
			for(var/mob/living/carbon/Xenomorph/X in oview(range, src))
				X.gain_health(pCaste.xenoheal_screech_healamount)
				to_chat(X, SPAN_XENOWARNING("You feel reinvigorated after hearing the screech of [src]!"))

			screech_cooldown = pCaste.xenoheal_screech_cooldown

		if (PRAETORIAN_ROYALGUARD)

			screechwave_color =  "#c2242e" // Ravager red

			if (!(prae_status_flags & PRAE_SCREECH_BUFFED))
				damage_modifier += pCaste.xenodamage_screech_damagebuff
				recalculate_damage()
				prae_status_flags |= PRAE_SCREECH_BUFFED
				to_chat(src, SPAN_XENOWARNING("Your screech empowers you to strike harder!"))

				spawn (pCaste.screech_duration)
					damage_modifier -= pCaste.xenodamage_screech_damagebuff
					recalculate_damage()
					prae_status_flags &= ~PRAE_SCREECH_BUFFED
					to_chat(src, SPAN_XENOWARNING("You feel the power of your screech wane."))

			else
				to_chat(src, "<span class='xenohighdanger'>Your screech's effects do NOT stack with those of your sisters!</span>")

			var/range = 7
			for(var/mob/living/carbon/Xenomorph/X in oview(range, src))
				if (!(X.prae_status_flags & PRAE_SCREECH_BUFFED))
					X.damage_modifier += pCaste.xenodamage_screech_damagebuff
					X.recalculate_damage()
					X.prae_status_flags |= PRAE_SCREECH_BUFFED
					to_chat(X, SPAN_XENOWARNING("You feel empowered to strike harder after hearing the screech of [src]!"))

					spawn (pCaste.screech_duration)
						X.damage_modifier -= pCaste.xenodamage_screech_damagebuff
						X.recalculate_damage()
						X.prae_status_flags &= ~PRAE_SCREECH_BUFFED
						to_chat(X, SPAN_XENOWARNING("You feel the power of the screech of [src] wane."))

				else
					to_chat(X, SPAN_XENOWARNING("You can only be empowered by one Praetorian at once!"))

			screech_cooldown = pCaste.xenodamage_screech_cooldown

		if (PRAETORIAN_OPPRESSOR)

			screechwave_color = "#9539c6" // Purple

			if (!(prae_status_flags & PRAE_SCREECH_BUFFED))
				armor_deflection_buff += pCaste.xenoarmor_screech_armorbuff
				armor_explosive_buff += pCaste.xenoarmor_screech_explosivebuff
				prae_status_flags |= PRAE_SCREECH_BUFFED

				to_chat(src, SPAN_XENOWARNING("Your screech makes you feel even harder to kill than before!"))

				spawn (pCaste.screech_duration)
					// TODO: Test with sleep to see it it works
					armor_deflection_buff -= pCaste.xenoarmor_screech_armorbuff
					armor_explosive_buff -= pCaste.xenoarmor_screech_explosivebuff
					prae_status_flags &= ~PRAE_SCREECH_BUFFED
					to_chat(src, SPAN_XENOWARNING("You feel the power of your screech wane!"))

			else
				to_chat(src, "<span class='xenohighdanger'>Your screech's effects do NOT stack with those of your sisters!</span>")

			var/range = 7
			for(var/mob/living/carbon/Xenomorph/X in oview(range, src))
				if (!(X.prae_status_flags & PRAE_SCREECH_BUFFED))
					X.armor_deflection_buff += pCaste.xenoarmor_screech_armorbuff
					X.armor_explosive_buff += pCaste.xenoarmor_screech_explosivebuff
					X.prae_status_flags |= PRAE_SCREECH_BUFFED
					to_chat(X, SPAN_XENOWARNING("You feel indestructible after heearing the screech of [src]!"))

					spawn (pCaste.screech_duration)
						X.armor_deflection_buff -= pCaste.xenoarmor_screech_armorbuff
						X.armor_explosive_buff -= pCaste.xenoarmor_screech_explosivebuff
						X.prae_status_flags &= ~PRAE_SCREECH_BUFFED
						to_chat(X, SPAN_XENOWARNING("You feel the power of the screech of [src] wane!"))
				else
					to_chat(X, SPAN_XENOWARNING("You can only be empowered by one Praetorian at once!"))

			screech_cooldown = pCaste.xenoarmor_screech_cooldown

		if (PRAETORIAN_DANCER)

			screechwave_color = "#6baeae" // Xeno teal color made brighter

			if (!(prae_status_flags & PRAE_SCREECH_BUFFED))
				speed_modifier -= pCaste.xenomovement_screech_speedbuff
				recalculate_speed()
				prae_status_flags |= PRAE_SCREECH_BUFFED
				to_chat(src, SPAN_XENOWARNING("You feel even more agile as you screech!"))

				spawn (pCaste.screech_duration)
					speed_modifier += pCaste.xenomovement_screech_speedbuff
					recalculate_speed()
					prae_status_flags &= ~PRAE_SCREECH_BUFFED
					to_chat(src, SPAN_XENOWARNING("You feel the power of your screech wane!"))

			else
				to_chat(src, "<span class='xenohighdanger'>Your screech's effects do NOT stack with those of your sisters!</span>")

			var/range = 7
			for(var/mob/living/carbon/Xenomorph/X in oview(range, src))
				if (!(X.prae_status_flags & PRAE_SCREECH_BUFFED))
					X.speed_modifier -= pCaste.xenomovement_screech_speedbuff
					X.recalculate_speed()
					to_chat(X, SPAN_XENOWARNING("You feel very agile after hearing the screech of [src]!"))

					spawn (pCaste.screech_duration)
						X.speed_modifier += pCaste.xenomovement_screech_speedbuff
						X.recalculate_speed()
						X.prae_status_flags &= ~PRAE_SCREECH_BUFFED
						to_chat(X, SPAN_XENOWARNING("You feel the power of the screech of [src] wane!"))

				else
					to_chat(src, "<span class='xenohighdanger'>Your screech's effects do NOT stack with those of your sisters!</span>")

			screech_cooldown = pCaste.xenomovement_screech_cooldown

		else
			log_debug("Error: [src] tried to screech with an invalid screech identifier. Error code: PRAE_SCREECH_01")
			log_admin("Error: bugged Praetorian screech. Tell the devs. Error code: PRAE_SCREECH_01")
			return

	create_shriekwave(screechwave_color)

	spawn(screech_cooldown)
		has_screeched = 0
		to_chat(src, SPAN_WARNING("You feel your throat muscles vibrate. You are ready to screech again."))
		for(var/Z in actions)
			var/datum/action/A = Z
			A.update_button_icon()


// Vent Crawl
/mob/living/carbon/Xenomorph/proc/vent_crawl()
	set name = "Crawl through Vent"
	set desc = "Enter an air vent and crawl through the pipe system."
	set category = "Alien"
	if(!check_state() || !can_ventcrawl())
		return
	var/pipe = start_ventcrawl()
	if(pipe)
		handle_ventcrawl(pipe)


/mob/living/carbon/Xenomorph/proc/xeno_transfer_plasma(atom/A, amount = 50, transfer_delay = 20, max_range = 2)
	if(!istype(A, /mob/living/carbon/Xenomorph))
		return
	var/mob/living/carbon/Xenomorph/target = A

	if(!check_state())
		return

	if(!isturf(loc))
		to_chat(src, SPAN_WARNING("You can't transfer plasma from here!"))
		return

	if(get_dist(src, target) > max_range)
		to_chat(src, SPAN_WARNING("You need to be closer to [target]."))
		return

	to_chat(src, SPAN_NOTICE("You start focusing your plasma towards [target]."))
	to_chat(target, SPAN_NOTICE("You feel that [src] starts transferring some of their plasma to you."))
	if(!do_after(src, transfer_delay, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
		return

	if(!check_state())
		return

	if(!isturf(loc))
		to_chat(src, SPAN_WARNING("You can't transfer plasma from here!"))
		return

	if(get_dist(src, target) > max_range)
		to_chat(src, SPAN_WARNING("You need to be closer to [target]."))
		return

	if(plasma_stored < amount)
		amount = plasma_stored //Just use all of it
	use_plasma(amount)
	target.gain_plasma(amount)
	to_chat(target, SPAN_XENOWARNING("\The [src] has transfered [amount] plasma to you. You now have [target.plasma_stored]."))
	to_chat(src, SPAN_XENOWARNING("You have transferred [amount] plasma to \the [target]. You now have [plasma_stored]."))
	playsound(src, "alien_drool", 25)

//Note: All the neurotoxin projectile items are stored in XenoProcs.dm
/mob/living/carbon/Xenomorph/proc/xeno_spit(atom/T)

	if(!check_state())
		return

	if(!isturf(loc))
		to_chat(src, SPAN_WARNING("You can't spit from here!"))
		return

	if(has_spat > world.time)
		to_chat(src, SPAN_WARNING("You must wait for your spit glands to refill."))
		return

	if(!check_plasma(ammo.spit_cost))
		return

	var/turf/current_turf = get_turf(src)

	if(!current_turf)
		return

	visible_message(SPAN_XENOWARNING("\The [src] spits at \the [T]!"), \
	SPAN_XENOWARNING("You spit at \the [T]!") )
	var/sound_to_play = pick(1, 2) == 1 ? 'sound/voice/alien_spitacid.ogg' : 'sound/voice/alien_spitacid2.ogg'
	playsound(src.loc, sound_to_play, 25, 1)

	var/obj/item/projectile/A = new /obj/item/projectile(initial(caste_name), src, current_turf)
	A.generate_bullet(ammo)
	A.permutated += src
	A.def_zone = get_limbzone_target()
	A.fire_at(T, src, src, ammo.max_range, ammo.shell_speed)
	has_spat = world.time + caste.spit_delay + ammo.added_spit_delay
	use_plasma(ammo.spit_cost)
	cooldown_notification(caste.spit_delay + ammo.added_spit_delay, "spit")

	return TRUE

/mob/living/carbon/Xenomorph/proc/cooldown_notification(cooldown, message)
	set waitfor = 0
	sleep(cooldown)
	switch(message)
		if("spit")
			to_chat(src, SPAN_NOTICE("You feel your neurotoxin glands swell with ichor. You can spit again."))
	for(var/X in actions)
		var/datum/action/A = X
		A.update_button_icon()



/mob/living/carbon/Xenomorph/proc/build_resin(atom/A, resin_plasma_cost, thick=FALSE, message=TRUE)
	if (action_busy)
		return FALSE
	if (!check_state())
		return FALSE
	if (!check_plasma(resin_plasma_cost))
		return FALSE

	var/turf/current_turf = get_turf(A)

	if (get_dist(src, A) > src.caste.max_build_dist + extra_build_dist) // Hivelords have max_build_dist of 1, drones and queens 0
		current_turf = get_turf(src)
	else if (thick) //hivelords can thicken existing resin structures.
		var/thickened = FALSE
		if(istype(A, /turf/closed/wall/resin))
			var/turf/closed/wall/resin/WR = A
			if(WR.walltype == WALL_RESIN)
				var/prev_old_turf = WR.old_turf
				WR.ChangeTurf(/turf/closed/wall/resin/thick)
				WR.old_turf = prev_old_turf
			else if(WR.walltype == WALL_MEMBRANE)
				var/prev_old_turf = WR.old_turf
				WR.ChangeTurf(/turf/closed/wall/resin/membrane/thick)
				WR.old_turf = prev_old_turf
			else
				to_chat(src, SPAN_XENOWARNING("[WR] can't be made thicker."))
				return FALSE
			thickened = TRUE

		else if(istype(A, /obj/structure/mineral_door/resin))
			var/obj/structure/mineral_door/resin/DR = A
			if(DR.hardness == 1.5) //non thickened
				var/oldloc = DR.loc
				qdel(DR)
				new /obj/structure/mineral_door/resin/thick (oldloc)
			else
				to_chat(src, SPAN_XENOWARNING("[DR] can't be made thicker."))
				return FALSE
			thickened = TRUE

		if (thickened)
			if(message)
				visible_message(SPAN_XENONOTICE("\The [src] regurgitates a thick substance and thickens [A]."), \
					SPAN_XENONOTICE("You regurgitate some resin and thicken [A]."), null, 5)
				use_plasma(resin_plasma_cost)
				playsound(loc, "alien_resin_build", 25)
			A.add_hiddenprint(src) //so admins know who thickened the walls
			return TRUE

	var/mob/living/carbon/Xenomorph/blocker = locate() in current_turf
	if(blocker && blocker != src && blocker.stat != DEAD)
		to_chat(src, SPAN_WARNING("Can't do that with [blocker] in the way!"))
		return FALSE

	if(!istype(current_turf) || !current_turf.is_weedable())
		to_chat(src, SPAN_WARNING("You can't do that here."))
		return FALSE

	var/area/AR = get_area(current_turf)
	if(istype(AR,/area/shuttle/drop1/lz1) || istype(AR,/area/shuttle/drop2/lz2)) //Bandaid for atmospherics bug when Xenos build around the shuttles
		to_chat(src, SPAN_WARNING("You sense this is not a suitable area for expanding the hive."))
		return FALSE

	var/obj/effect/alien/weeds/alien_weeds = locate() in current_turf

	if(!alien_weeds)
		to_chat(src, SPAN_WARNING("You can only shape on weeds. Find some resin before you start building!"))
		return FALSE

	if(!check_alien_construction(current_turf))
		return FALSE

	if(selected_resin == RESIN_DOOR)
		var/wall_support = FALSE
		for(var/D in cardinal)
			var/turf/T = get_step(current_turf,D)
			if(T)
				if(T.density)
					wall_support = TRUE
					break
				else if(locate(/obj/structure/mineral_door/resin) in T)
					wall_support = TRUE
					break
		if(!wall_support)
			to_chat(src, SPAN_WARNING("Resin doors need a wall or resin door next to them to stand up."))
			return FALSE

	var/wait_time = caste.build_time

	alien_weeds.secreting = 1
	alien_weeds.update_icon()

	if(!do_after(src, wait_time, INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		alien_weeds.secreting = 0
		alien_weeds.update_icon()

		return FALSE

	alien_weeds.secreting = 0
	alien_weeds.update_icon()

	blocker = locate() in current_turf
	if(blocker && blocker != src && blocker.stat != DEAD)
		return FALSE

	if(!check_state())
		return FALSE
	if(!check_plasma(resin_plasma_cost))
		return FALSE

	if(!istype(current_turf) || !current_turf.is_weedable())
		return FALSE

	AR = get_area(current_turf)
	if(istype(AR,/area/shuttle/drop1/lz1 || istype(AR,/area/shuttle/drop2/lz2))) //Bandaid for atmospherics bug when Xenos build around the shuttles
		return FALSE

	alien_weeds = locate() in current_turf
	if(!alien_weeds)
		return FALSE

	if(!check_alien_construction(current_turf))
		return FALSE

	if(selected_resin == RESIN_DOOR)
		var/wall_support = FALSE
		for(var/D in cardinal)
			var/turf/T = get_step(current_turf,D)
			if(T)
				if(T.density)
					wall_support = TRUE
					break
				else if(locate(/obj/structure/mineral_door/resin) in T)
					wall_support = TRUE
					break
		if(!wall_support)
			to_chat(src, SPAN_WARNING("Resin doors need a wall or resin door next to them to stand up."))
			return FALSE

	use_plasma(resin_plasma_cost)
	if(message)
		visible_message(SPAN_XENONOTICE("\The [src] regurgitates a thick substance and shapes it into \a [resin2text(selected_resin, thick)]!"), \
			SPAN_XENONOTICE("You regurgitate some resin and shape it into \a [resin2text(selected_resin, thick)]."), null, 5)
		playsound(loc, "alien_resin_build", 25)

	var/atom/new_resin

	switch(selected_resin)
		if(RESIN_DOOR)
			if (thick)
				new_resin = new /obj/structure/mineral_door/resin/thick(current_turf)
			else
				new_resin = new /obj/structure/mineral_door/resin(current_turf)
		if(RESIN_WALL)
			if (thick)
				current_turf.ChangeTurf(/turf/closed/wall/resin/thick)
			else
				current_turf.ChangeTurf(/turf/closed/wall/resin)
			new_resin = current_turf
		if(RESIN_MEMBRANE)
			if (thick)
				current_turf.ChangeTurf(/turf/closed/wall/resin/membrane/thick)
			else
				current_turf.ChangeTurf(/turf/closed/wall/resin/membrane)
			new_resin = current_turf
		if(RESIN_NEST)
			new_resin = new /obj/structure/bed/nest(current_turf)
		if(RESIN_STICKY)
			new_resin = new /obj/effect/alien/resin/sticky(current_turf)
		if(RESIN_FAST)
			new_resin = new /obj/effect/alien/resin/sticky/fast(current_turf)

	new_resin.add_hiddenprint(src) //so admins know who placed it
	return TRUE


//Corrosive acid is consolidated -- it checks for specific castes for strength now, but works identically to each other.
//The acid items are stored in XenoProcs.
/mob/living/carbon/Xenomorph/proc/corrosive_acid(atom/O, acid_type, plasma_cost)

	if(!O.Adjacent(src))
		to_chat(src, SPAN_WARNING("\The [O] is too far away."))
		return

	if(!isturf(loc) || burrow)
		to_chat(src, SPAN_WARNING("You can't melt [O] from here!"))
		return

	face_atom(O)

	var/wait_time = 10

	//OBJ CHECK
	if(isobj(O))
		var/obj/I = O

		if(I.unacidable || istype(I, /obj/structure/machinery/computer) || istype(I, /obj/effect)) //So the aliens don't destroy energy fields/singularies/other aliens/etc with their acid.
			to_chat(src, SPAN_WARNING("You cannot dissolve \the [I].")) // ^^ Note for obj/effect.. this might check for unwanted stuff. Oh well
			return
		if(istype(O, /obj/structure/window_frame))
			var/obj/structure/window_frame/WF = O
			if(WF.reinforced && acid_type != /obj/effect/xenomorph/acid/strong)
				to_chat(src, SPAN_WARNING("This [O.name] is too tough to be melted by your weak acid."))
				return

		if(O.density || istype(O, /obj/structure))
			wait_time = 40 //dense objects are big, so takes longer to melt.

	//TURF CHECK
	else if(isturf(O))
		var/turf/T = O

		if(istype(O, /turf/closed/wall))
			var/turf/closed/wall/wall_target = O
			if (wall_target.acided_hole)
				to_chat(src, SPAN_WARNING("[O] is already weakened."))
				return

		var/dissolvability = T.can_be_dissolved()
		switch(dissolvability)
			if(0)
				to_chat(src, SPAN_WARNING("You cannot dissolve \the [T]."))
				return
			if(1)
				wait_time = 50
			if(2)
				if(acid_type != /obj/effect/xenomorph/acid/strong)
					to_chat(src, SPAN_WARNING("This [T.name] is too tough to be melted by your weak acid."))
					return
				wait_time = 100
			else
				return
		to_chat(src, SPAN_XENOWARNING("You begin generating enough acid to melt through \the [T]."))
	else
		to_chat(src, SPAN_WARNING("You cannot dissolve \the [O]."))
		return

	if(!do_after(src, wait_time, INTERRUPT_NO_NEEDHAND, BUSY_ICON_HOSTILE))
		return

	if(!check_state())
		return

	if(!O || !get_turf(O)) //Some logic.
		return

	if(!check_plasma(plasma_cost))
		return

	if(!O.Adjacent(src))
		return

	use_plasma(plasma_cost)

	var/obj/effect/xenomorph/acid/A = new acid_type(get_turf(O), O)

	if(istype(O, /obj/vehicle/multitile/root/cm_armored))
		var/obj/vehicle/multitile/root/cm_armored/R = O
		R.take_damage_type( (1 / A.acid_strength) * 20, "acid", src)
		visible_message(SPAN_XENOWARNING("\The [src] vomits globs of vile stuff at \the [O]. It sizzles under the bubbling mess of acid!"), \
			SPAN_XENOWARNING("You vomit globs of vile stuff at \the [O]. It sizzles under the bubbling mess of acid!"), null, 5)
		playsound(loc, "sound/bullets/acid_impact1.ogg", 25)
		sleep(20)
		qdel(A)
		return

	if(isturf(O))
		A.icon_state += "_wall"

	if(istype(O, /obj/structure) || istype(O, /obj/structure/machinery)) //Always appears above machinery
		A.layer = O.layer + 0.1
	else //If not, appear on the floor or on an item
		A.layer = LOWER_ITEM_LAYER //below any item, above BELOW_OBJ_LAYER (smartfridge)

	A.add_hiddenprint(src)

	if(!isturf(O))
		msg_admin_attack("[src.name] ([src.ckey]) spat acid on [O] at ([src.loc.x],[src.loc.y],[src.loc.z]) (<A HREF='?_src_=admin_holder;adminplayerobservecoodjump=1;X=[src.loc.x];Y=[src.loc.y];Z=[src.loc.z]'>JMP</a>).")
		attack_log += text("\[[time_stamp()]\] <font color='green'>Spat acid on [O]</font>")
	visible_message(SPAN_XENOWARNING("\The [src] vomits globs of vile stuff all over \the [O]. It begins to sizzle and melt under the bubbling mess of acid!"), \
	SPAN_XENOWARNING("You vomit globs of vile stuff all over \the [O]. It begins to sizzle and melt under the bubbling mess of acid!"), null, 5)
	playsound(loc, "sound/bullets/acid_impact1.ogg", 25)

/mob/living/carbon/Xenomorph/verb/hive_status()
	set name = "Hive Status"
	set desc = "Check the status of your current hive."
	set category = "Alien"

	if(!hive.living_xeno_queen)
		to_chat(src, SPAN_WARNING("There is no Queen. You are alone."))
		return

	if(interference)
		to_chat(src, SPAN_WARNING("A headhunter temporarily cut off your psychic connection!"))
		return

	hive.hive_ui.open_hive_status(src)

/mob/living/carbon/Xenomorph/verb/toggle_xeno_mobhud()
	set name = "Toggle Xeno Status HUD"
	set desc = "Toggles the health and plasma hud appearing above Xenomorphs."
	set category = "Alien"

	xeno_mobhud = !xeno_mobhud
	var/datum/mob_hud/H = huds[MOB_HUD_XENO_STATUS]
	if(xeno_mobhud)
		H.add_hud_to(usr)
	else
		H.remove_hud_from(usr)


/mob/living/carbon/Xenomorph/verb/middle_mouse_toggle()
	set name = "Toggle Middle/Shift Clicking"
	set desc = "Toggles between using middle mouse click and shift click for selected abilitiy use."
	set category = "Alien"

	if (!client || !client.prefs)
		return

	client.prefs.toggle_prefs ^= TOGGLE_MIDDLE_MOUSE_CLICK
	client.prefs.save_preferences()
	if (client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK)
		to_chat(src, SPAN_NOTICE("The selected xeno ability will now be activated with middle mouse clicking."))		
	else
		to_chat(src, SPAN_NOTICE("The selected xeno ability will now be activated with shift clicking."))


/mob/living/carbon/Xenomorph/verb/directional_attack_toggle()
	set name = "Toggle Directional Attacks"
	set desc = "Toggles the use of directional assist attacks."
	set category = "Alien"

	if (!client || !client.prefs)
		return
	
	client.prefs.toggle_prefs ^= TOGGLE_DIRECTIONAL_ATTACK
	client.prefs.save_preferences()
	if(client.prefs.toggle_prefs & TOGGLE_DIRECTIONAL_ATTACK)
		to_chat(src, SPAN_NOTICE("Attacks will now use directional assist."))
	else
		to_chat(src, SPAN_NOTICE("Attacks will no longer use directional assist."))

/mob/living/carbon/Xenomorph/proc/morph_resin(var/turf/current_turf, var/structure_type)
	if (!structure_type || !check_state() || action_busy)
		return FALSE

	var/area/current_area = get_area(current_turf)

	if(isnull(current_turf))
		to_chat(src, SPAN_WARNING("You can't do that here."))
		return FALSE

	if(!hive.living_xeno_queen)
		to_chat(src, SPAN_WARNING("There is no queen!"))
		return FALSE

	if(!hive.hive_location)
		to_chat(src, SPAN_WARNING("There is no hive!"))
		return FALSE

	if(get_dist(src, hive.hive_location) > XENO_HIVE_AREA_SIZE)
		to_chat(src, SPAN_WARNING("You are too far from the hive!"))
		return FALSE

	if (!current_area.can_build_special)
		to_chat(src, SPAN_WARNING("You cannot build here!"))
		return FALSE		

	for(var/turf/T in (range(current_turf, 1)))
		var/failed = FALSE
		if(T.density)
			failed = TRUE
		if(!check_alien_construction(current_turf))
			failed = TRUE
		if(failed)
			to_chat(src, SPAN_WARNING("You need more open space to build here."))
			return
		var/obj/effect/alien/weeds/alien_weeds = locate() in T
		if(!alien_weeds)
			to_chat(src, SPAN_WARNING("You can only shape on weeds. Find some resin before you start building!"))
			return FALSE

	if(!do_after(src, XENO_STRUCTURE_BUILD_TIME, INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return FALSE

	KnockDown(80)

	if(!do_after(src, XENO_STRUCTURE_BUILD_TIME, INTERRUPT_DIFF_TURF|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		return FALSE

	var/obj/effect/alien/resin/special/new_structure = new structure_type(loc, hive)

	visible_message(SPAN_XENONOTICE("\The [src] regurgitates a thick substance and morphs itself into \a [new_structure]!"), \
		SPAN_XENONOTICE("You regurgitate some resin and morph yourself into \a [new_structure]."), null, 5)
	playsound(loc, "alien_resin_build", 25)

	if(hive.living_xeno_queen)
		xeno_message("Hive: \The [src] has <b>morphed</b> into \a [new_structure] at [sanitize(current_area)]!", 3, hivenumber)

	hive.queue_spawn(src)
	track_death_calculations()
	qdel(src)