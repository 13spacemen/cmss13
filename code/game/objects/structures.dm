/obj/structure
	icon = 'icons/obj/structures/structures.dmi'
	var/climbable
	var/climb_delay = 50
	var/breakable
	var/parts
	var/list/debris = list()
	var/unslashable = FALSE
	health = 100
	anchored = 1
	projectile_coverage = PROJECTILE_COVERAGE_MEDIUM

/obj/structure/New()
	..()
	structure_list += src

	if(climbable)
		verbs += /obj/structure/proc/climb_on

/obj/structure/Dispose()
	//before ..() because the parent does loc = null
	for(var/atom/movable/A in contents_recursive())
		var/obj/O = A
		if(!istype(O))
			continue
		if(O.unacidable)
			O.forceMove(get_turf(loc))
	structure_list -= src
	. = ..()

/obj/structure/proc/destroy(deconstruct)
	if(parts)
		new parts(loc)
	density = 0
	qdel(src)

/obj/structure/attack_animal(mob/living/user)
	if(breakable)
		if(user.wall_smash)
			visible_message(SPAN_DANGER("[user] smashes [src] apart!"))
			destroy()

/obj/structure/ex_act(severity, direction)
	if(src.health) //Prevents unbreakable objects from being destroyed
		src.health -= severity
		if(src.health <= 0)
			handle_debris(severity, direction)
			qdel(src)

/obj/structure/proc/handle_debris(severity = 0, direction = 0)
	if(!debris.len)
		return
	switch(severity)
		if(0)
			for(var/thing in debris)
				new thing(loc)
		if(0 to EXPLOSION_THRESHOLD_HIGH) //beyond EXPLOSION_THRESHOLD_HIGH, the explosion is too powerful to create debris. It's all atomized.
			for(var/thing in debris)
				var/obj/item/I = new thing(loc)
				I.explosion_throw(severity, direction)

/obj/structure/proc/climb_on()

	set name = "Climb structure"
	set desc = "Climbs onto a structure."
	set category = "Object"
	set src in oview(1)

	do_climb(usr)

/obj/structure/MouseDrop_T(mob/target, mob/user)
	. = ..()
	var/mob/living/H = user
	if(!istype(H) || target != user) //No making other people climb onto tables.
		return

	do_climb(target)

/obj/structure/proc/can_climb(var/mob/living/user)
	if(!climbable || !can_touch(user))
		return FALSE

	var/turf/T = src.loc
	var/turf/U = get_turf(user)
	if(!istype(T) || !istype(U)) 
		return FALSE

	var/result = handle_barriers(user)
	if(result != src)
		to_chat(user, SPAN_WARNING("There's \a [result] in the way."))
		return FALSE

	if(!(flags_atom & ON_BORDER))
		return TRUE
	if(user.loc != loc && user.loc != get_step(T, dir))
		to_chat(user, SPAN_WARNING("You need to be up against [src] to leap over."))
		return FALSE
	if(user.loc == loc)
		var/turf/target = get_step(T, dir)
		if(target.density) //Turf is dense, not gonna work
			to_chat(user, SPAN_WARNING("You cannot leap this way."))
			return FALSE
		for(var/atom/movable/A in target)
			if(!A || !A.density)
				continue
			if(isStructure(A))
				var/obj/structure/S = A
				if (S.flags_atom & ON_BORDER)
					if (!S.climbable && turn(dir, 180) == S.dir)
						to_chat(user, SPAN_WARNING("You cannot leap this way."))
						return FALSE
				else if(!S.climbable) //Transfer onto climbable surface
					to_chat(user, SPAN_WARNING("You cannot leap this way."))
					return FALSE
			else
				to_chat(user, SPAN_WARNING("You cannot leap this way."))
				return FALSE
	return TRUE

/obj/structure/proc/do_climb(var/mob/living/user)
	if(!can_climb(user))
		return

	user.visible_message(SPAN_WARNING("[user] starts [flags_atom & ON_BORDER ? "leaping over":"climbing onto"] \the [src]!"))

	if(!do_after(user, climb_delay, INTERRUPT_NO_NEEDHAND, BUSY_ICON_GENERIC))
		return

	if(!can_climb(user))
		return

	if(!(flags_atom & ON_BORDER)) //If not a border structure or we are not on its tile, assume default behavior
		user.forceMove(get_turf(src))

		if(get_turf(user) == get_turf(src))
			user.visible_message(SPAN_WARNING("[user] climbs onto \the [src]!"))
	else //If border structure, assume complex behavior
		var/turf/target = get_step(get_turf(src), dir)
		if(user.loc == target)
			user.forceMove(get_turf(src))
			user.visible_message(SPAN_WARNING("[user] leaps over \the [src]!"))
		else
			if(target.density) //Turf is dense, not gonna work
				to_chat(user, SPAN_WARNING("You cannot leap this way."))
				return
			for(var/atom/movable/A in target)
				if(A && A.density && !(A.flags_atom & ON_BORDER))
					if(istype(A, /obj/structure))
						var/obj/structure/S = A
						if(!S.climbable) //Transfer onto climbable surface
							to_chat(user, SPAN_WARNING("You cannot leap this way."))
							return
					else
						to_chat(user, SPAN_WARNING("You cannot leap this way."))
						return
			user.forceMove(get_turf(target)) //One more move, we "leap" over the border structure

			if(get_turf(user) == get_turf(target))
				user.visible_message(SPAN_WARNING("[user] leaps over \the [src]!"))

/obj/structure/proc/structure_shaken()

	for(var/mob/living/M in get_turf(src))

		if(M.lying) return //No spamming this on people.

		M.KnockDown(5)
		to_chat(M, SPAN_WARNING("You topple as \the [src] moves under you!"))

		if(prob(25))

			var/damage = rand(15,30)
			var/mob/living/carbon/human/H = M
			if(!istype(H))
				to_chat(H, SPAN_DANGER("You land heavily!"))
				M.apply_damage(damage, BRUTE)
				return

			var/datum/limb/affecting

			switch(pick(list("ankle","wrist","head","knee","elbow")))
				if("ankle")
					affecting = H.get_limb(pick("l_foot", "r_foot"))
				if("knee")
					affecting = H.get_limb(pick("l_leg", "r_leg"))
				if("wrist")
					affecting = H.get_limb(pick("l_hand", "r_hand"))
				if("elbow")
					affecting = H.get_limb(pick("l_arm", "r_arm"))
				if("head")
					affecting = H.get_limb("head")

			if(affecting)
				to_chat(M, SPAN_DANGER("You land heavily on your [affecting.display_name]!"))
				affecting.take_damage(damage, 0)
				if(affecting.parent)
					affecting.parent.add_autopsy_data("Misadventure", damage)
			else
				to_chat(H, SPAN_DANGER("You land heavily!"))
				H.apply_damage(damage, BRUTE)

			H.UpdateDamageIcon()
			H.updatehealth()
	return

/obj/structure/proc/can_touch(mob/user)
	if(!user)
		return 0
	if(!Adjacent(user) || !isturf(user.loc))
		return 0
	if(user.is_mob_restrained() || user.buckled)
		to_chat(user, SPAN_NOTICE("You need your hands and legs free for this."))
		return 0
	if(user.is_mob_incapacitated(TRUE) || user.lying)
		return 0
	if(issilicon(user))
		to_chat(user, SPAN_NOTICE("You need hands for this."))
		return 0
	return 1

