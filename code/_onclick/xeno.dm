/*
	Xenomorph
*/

/mob/living/carbon/Xenomorph/UnarmedAttack(var/atom/A)
	if(lying || burrow) //No attacks while laying down
		return FALSE
	var/atom/target = A
	var/mob/alt
	if(isturf(target))
		var/turf/T = target
		for(var/mob/living/L in T)
			if (!iscarbon(L))
				if (!alt)
					alt = L // last option is a simple mob
				continue

			if (!L.is_xeno_grabbable())
				continue
			if (L.lying)
				alt = L
				continue
			target = L
			break
		if (target == T && alt)
			target = alt
	target = target.handle_barriers(src) // Checks if target will be attacked by the current alien OR if the blocker will be attacked
	target.attack_alien(src)
	track_slashes(caste_name)
	next_move = world.time + (10 + (caste ? caste.attack_delay : 0)) //Adds some lag to the 'attack'
	return TRUE

/mob/living/carbon/Xenomorph/RangedAttack(var/atom/A)
	. = ..()
	if (.)
		return
	if (client && client.prefs && client.prefs.toggle_prefs & TOGGLE_DIRECTIONAL_ATTACK)
		return UnarmedAttack(get_turf(get_step(src, get_dir(src, A))))
	return FALSE

//The parent proc, will default to UnarmedAttack behaviour unless overriden
/atom/proc/attack_alien(mob/user as mob)
	return

/mob/living/carbon/Xenomorph/click(var/atom/A, var/list/mods)
	if (queued_action)
		handle_queued_action(A)
		return TRUE

	if(mods["middle"] && !mods["shift"])
		if(selected_ability && client && client.prefs && client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK)
			selected_ability.use_ability(A)
			return TRUE

	if (mods["alt"] && mods["shift"])
		if (istype(A, /mob/living/carbon/Xenomorph))
			var/mob/living/carbon/Xenomorph/X = A

			if (X && !X.disposed && X != observed_xeno && X.stat != DEAD && X.z != ADMIN_Z_LEVEL && X.check_state(1))
				if (caste && istype(caste, /datum/caste_datum/queen))
					var/mob/living/carbon/Xenomorph/oldXeno = observed_xeno
					overwatch(X, FALSE, /datum/event_handler/xeno_overwatch_onmovement/queen)

					if (oldXeno)
						oldXeno.hud_set_queen_overwatch()
					if (X && !X.disposed)
						X.hud_set_queen_overwatch()

				else
					overwatch(X)

				next_move = world.time + 3 // Some minimal delay so this isn't crazy spammy
				return 1

	if(mods["shift"] && !mods["middle"])
		if(selected_ability && client && client.prefs && !(client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK))
			selected_ability.use_ability(A)
			return TRUE

	if(next_move >= world.time)
		return 1

	return ..()

/mob/living/carbon/Xenomorph/Boiler/click(var/atom/A, var/list/mods)
	if(!istype(A,/obj/screen))
		if(is_zoomed && !is_bombarding)
			zoom_out()
			return 1

		if(is_bombarding)
			if(isturf(A))
				bomb_turf(A)
			else if(isturf(get_turf(A)))
				bomb_turf(get_turf(A))
			if(client)
				client.mouse_pointer_icon = initial(client.mouse_pointer_icon)
			return 1

	if (queued_action)
		handle_queued_action()
		return 1

	if(mods["middle"] && !mods["shift"])
		if (selected_ability && client && client.prefs && client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK)
			selected_ability.use_ability(A)
			return 1

	if(mods["shift"])
		if (selected_ability && client && client.prefs && !client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK)
			selected_ability.use_ability(A)
			return 1

	return ..()

/mob/living/carbon/Xenomorph/Crusher/click(var/atom/A, var/list/mods)
	if(!istype(A, /obj/screen))
		if(is_charging)
			stop_momentum(charge_dir)

	if (queued_action)
		handle_queued_action()
		return 1

	if(mods["middle"] && !mods["shift"])
		if(selected_ability && client && client.prefs && client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK)
			selected_ability.use_ability(A)
			return 1

	if(mods["shift"])
		if(selected_ability && client && client.prefs && !client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK)
			selected_ability.use_ability(A)
			return 1

	return ..()

/mob/living/carbon/Xenomorph/Larva/UnarmedAttack(var/atom/A, var/list/mods)
	if(!caste)
		return FALSE

	if(lying) //No attacks while laying down
		return 0

	A.attack_larva(src)
	next_move = world.time + (10 + caste.attack_delay) //Adds some lag to the 'attack'

//Larva attack, will default to attack_alien behaviour unless overriden
/atom/proc/attack_larva(mob/living/carbon/Xenomorph/Larva/user)
	return attack_alien(user)
