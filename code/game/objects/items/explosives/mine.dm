
///***MINES***///
//Mines have an invisible "tripwire" atom that explodes when crossed
//Stepping directly on the mine will also blow it up
/obj/item/explosive/mine
	name = "\improper M20 Claymore anti-personnel mine"
	desc = "The M20 Claymore is a directional proximity-triggered anti-personnel mine designed by Armat Systems for use by the United States Colonial Marines. The mine is triggered by movement both on the mine itself, and on the space immediately in front of it. Detonation sprays shrapnel forwards in a 120-degree cone. The words \"FRONT TOWARD ENEMY\" are embossed on the front."
	icon = 'icons/obj/items/weapons/grenade.dmi'
	icon_state = "m20"
	force = 5.0
	w_class = SIZE_SMALL
	//layer = MOB_LAYER - 0.1 //You can't just randomly hide claymores under boxes. Booby-trapping bodies is fine though
	throwforce = 5.0
	throw_range = 6
	throw_speed = SPEED_VERY_FAST
	unacidable = TRUE
	flags_atom = FPRINT|CONDUCT

	var/iff_signal = ACCESS_IFF_MARINE
	var/triggered = FALSE
	var/armed = FALSE //Will the mine explode or not
	var/base_icon_state = "m20" //the unarmed icon_state
	var/trigger_type = "explosive" //Calls that proc
	var/obj/effect/mine_tripwire/tripwire
	var/source_mob


/obj/item/explosive/mine/Dispose()
	if(tripwire)
		qdel(tripwire)
		tripwire = null
	. = ..()

/obj/item/explosive/mine/ex_act()
	trigger_explosion() //We don't care about how strong the explosion was.

/obj/item/explosive/mine/emp_act()
	trigger_explosion() //Same here. Don't care about the effect strength.


//checks for things that would prevent us from placing the mine.
/obj/item/explosive/mine/proc/check_for_obstacles(mob/living/user)
	if(locate(/obj/item/explosive/mine) in get_turf(src))
		to_chat(user, SPAN_WARNING("There already is a mine at this position!"))
		return TRUE
	if(user.loc && (user.loc.density || locate(/obj/structure/fence) in user.loc))
		to_chat(user, SPAN_WARNING("You can't plant a mine here."))
		return TRUE
	/*if(user.z == MAIN_SHIP_Z_LEVEL || user.z == LOW_ORBIT_Z_LEVEL) // Almayer or dropship transit level
		to_chat(user, SPAN_WARNING("You can't plant a mine on a spaceship!"))
		return*/



//Arming
/obj/item/explosive/mine/attack_self(mob/living/user)

	if(check_for_obstacles(user))
		return

	if(armed || user.action_busy)
		return
	user.visible_message(SPAN_NOTICE("[user] starts deploying [src]."), \
		SPAN_NOTICE("You start deploying [src]."))
	if(!do_after(user, 40, INTERRUPT_NO_NEEDHAND, BUSY_ICON_HOSTILE))
		user.visible_message(SPAN_NOTICE("[user] stops deploying [src]."), \
			SPAN_NOTICE("You stop deploying \the [src]."))
		return

	if(armed)
		return

	if(check_for_obstacles(user))
		return

	user.visible_message(SPAN_NOTICE("[user] finishes deploying [src]."), \
		SPAN_NOTICE("You finish deploying [src]."))

	source_mob = user
	anchored = TRUE
	armed = 1
	playsound(loc, 'sound/weapons/mine_armed.ogg', 25, 1)
	icon_state = "[base_icon_state]_armed"
	user.drop_held_item(src)
	dir = user.dir //The direction it is planted in is the direction the user faces at that time
	var/tripwire_loc = get_turf(get_step(loc, dir))
	tripwire = new(tripwire_loc)
	tripwire.linked_claymore = src


//Disarming
/obj/item/explosive/mine/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/device/multitool))
		if(armed)
			if(user.action_busy)
				return
			user.visible_message(SPAN_NOTICE("[user] starts disarming [src]."), \
			SPAN_NOTICE("You start disarming [src]."))
			if(!do_after(user, 30, INTERRUPT_NO_NEEDHAND, BUSY_ICON_FRIENDLY))
				user.visible_message("<span class='warning'>[user] stops disarming [src].", \
				"<span class='warning'>You stop disarming [src].")
				return
			if(!armed)//someone beat us to it
				return
			user.visible_message(SPAN_NOTICE("[user] finishes disarming [src]."), \
			SPAN_NOTICE("You finish disarming [src]."))
			anchored = FALSE
			armed = 0
			icon_state = base_icon_state
			if(tripwire)
				qdel(tripwire)
				tripwire = null
	else
		return ..()


//Mine can also be triggered if you "cross right in front of it" (same tile)
/obj/item/explosive/mine/Crossed(atom/A)
	..()
	if(isliving(A))
		var/mob/living/L = A
		if(!L.lying)//so dragged corpses don't trigger mines.
			try_to_trigger(A)


/obj/item/explosive/mine/Collided(atom/movable/AM)
	try_to_trigger(AM)


/obj/item/explosive/mine/proc/try_to_trigger(mob/living/carbon/human/H)
	if(!armed || triggered)
		return
	if(!isliving(H))
		return
	if((istype(H) && H.get_target_lock(iff_signal)) || isrobot(H))
		return

	H.visible_message(SPAN_DANGER("[htmlicon(src, viewers(src))] The [name] clicks as [H] moves in front of it."), \
	SPAN_DANGER("[htmlicon(src, H)] The [name] clicks as you move in front of it."), \
	SPAN_DANGER("You hear a click."))

	triggered = TRUE
	playsound(loc, 'sound/weapons/mine_tripped.ogg', 25, 1)
	trigger_explosion()


//Note : May not be actual explosion depending on linked method
/obj/item/explosive/mine/proc/trigger_explosion()
	set waitfor = 0

	switch(trigger_type)
		if("explosive")
			create_shrapnel(loc, 12, dir, 60, , initial(name), source_mob)
			sleep(2) //so that shrapnel has time to hit mobs before they are knocked over by the explosion
			cell_explosion(loc, 60, 20, dir, initial(name), source_mob)
			qdel(src)


/obj/item/explosive/mine/attack_alien(mob/living/carbon/Xenomorph/M)
	if(triggered) //Mine is already set to go off
		return

	if(M.a_intent == HELP_INTENT)
		return
	M.visible_message(SPAN_DANGER("[M] has slashed [src]!"), \
		SPAN_DANGER("You slash [src]!"))
	playsound(loc, 'sound/weapons/slice.ogg', 25, 1)

	//We move the tripwire randomly in either of the four cardinal directions
	triggered = TRUE
	if(tripwire)
		var/direction = pick(cardinal)
		var/step_direction = get_step(src, direction)
		tripwire.forceMove(step_direction)
	trigger_explosion()


/obj/item/explosive/mine/flamer_fire_act() //adding mine explosions
	trigger_explosion()


/obj/effect/mine_tripwire
	name = "claymore tripwire"
	anchored = TRUE
	mouse_opacity = 0
	invisibility = 101
	unacidable = TRUE //You never know
	var/obj/item/explosive/mine/linked_claymore

/obj/effect/mine_tripwire/Dispose()
	if(linked_claymore)
		linked_claymore = null
	. = ..()

//immune to explosions.
/obj/effect/mine_tripwire/ex_act(severity)
	return

/obj/effect/mine_tripwire/Crossed(atom/movable/AM)
	if(!linked_claymore)
		qdel(src)
		return

	if(linked_claymore.triggered) //Mine is already set to go off
		return

	if(linked_claymore)
		linked_claymore.try_to_trigger(AM)


/obj/item/explosive/mine/pmc
	name = "\improper M20P Claymore anti-personnel mine"
	desc = "The M20P Claymore is a directional proximity triggered anti-personnel mine designed by Armat Systems for use by the United States Colonial Marines. It has been modified for use by the W-Y PMC forces."
	icon_state = "m20p"
	iff_signal = ACCESS_IFF_PMC
	base_icon_state = "m20p"

