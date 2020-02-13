
//Alium nests. Essentially beds with an unbuckle delay that only aliums can buckle mobs to.
/obj/structure/bed/nest
	name = "alien nest"
	desc = "It's a gruesome pile of thick, sticky resin shaped like a nest."
	icon = 'icons/mob/xenos/Effects.dmi'
	icon_state = "nest"
	buckling_y = 6
	buildstacktype = null //can't be disassembled and doesn't drop anything when destroyed
	unacidable = TRUE
	health = 100
	var/on_fire = 0
	var/resisting = 0
	var/resisting_ready = 0
	var/nest_resist_time = 1200
	var/mob/dead/observer/ghost_of_buckled_mob =  null
	layer = RESIN_STRUCTURE_LAYER

/obj/structure/bed/nest/New()
	..()
	if(!locate(/obj/effect/alien/weeds) in loc) new /obj/effect/alien/weeds(loc)

/obj/structure/bed/nest/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/grab))
		var/obj/item/grab/G = W
		if(ismob(G.grabbed_thing))
			var/mob/M = G.grabbed_thing
			to_chat(user, SPAN_NOTICE("You place [M] on [src]."))
			M.forceMove(loc)
		return TRUE
	else
		if(W.flags_item & NOBLUDGEON) return
		var/aforce = W.force
		health = max(0, health - aforce)
		playsound(loc, "alien_resin_break", 25)
		user.visible_message(SPAN_WARNING("\The [user] hits \the [src] with \the [W]!"), \
		SPAN_WARNING("You hit \the [src] with \the [W]!"))
		healthcheck()

/obj/structure/bed/nest/manual_unbuckle(mob/living/user)
	if(!(buckled_mob && buckled_mob.buckled == src && (buckled_mob != user)))
		return

	if(user.stat || user.lying || user.is_mob_restrained())
		return

	if(isXeno(user))
		var/mob/living/carbon/Xenomorph/X = user
		if(!X.caste.can_denest_hosts)
			to_chat(X, SPAN_XENOWARNING("You shouldn't interfere with the nest, leave that to the drones."))
			return

	buckled_mob.visible_message(SPAN_NOTICE("\The [user] pulls \the [buckled_mob] free from \the [src]!"),\
	SPAN_NOTICE("\The [user] pulls you free from \the [src]."),\
	SPAN_NOTICE("You hear squelching."))
	playsound(loc, "alien_resin_move", 50)
	if(ishuman(buckled_mob))
		var/mob/living/carbon/human/H = buckled_mob
		H.attack_log += "\[[time_stamp()]\]<font color='orange'>Unnested by [key_name(user)] at [get_location_in_text(H)]</font>"
		H.start_nesting_cooldown()
	unbuckle()
	return

/mob/living/carbon/human/proc/start_nesting_cooldown()
	set waitfor = 0
	recently_unbuckled = 1
	sleep(50)
	recently_unbuckled = 0

/obj/structure/bed/nest/buckle_mob(mob/M as mob, mob/user as mob)
	if(!ismob(M) || isXenoLarva(user) || (get_dist(src, user) > 1) || (M.loc != loc) || user.is_mob_restrained() || user.stat || user.lying || M.buckled || !iscarbon(user))
		return

	if(isXeno(M))
		to_chat(user, SPAN_WARNING("You can't buckle your sisters."))
		return

	if(buckled_mob)
		to_chat(user, SPAN_WARNING("There's already someone in [src]."))
		return

	if(M.mob_size > MOB_SIZE_HUMAN)
		to_chat(user, SPAN_WARNING("\The [M] is too big to fit in [src]."))
		return

	if(!isXeno(user) || isSynth(M))
		to_chat(user, SPAN_WARNING("Gross! You're not touching that stuff."))
		return

	if(isYautja(M))
		to_chat(user, SPAN_WARNING("\The [M] seems to be wearing some kind of resin-resistant armor!"))
		return

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.recently_unbuckled)
			to_chat(user, SPAN_WARNING("[M] was recently unbuckled. Wait a bit."))
			return

	if(M == user)
		return

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.lying) //Don't ask me why is has to be
			to_chat(user, SPAN_WARNING("[M] is resisting, ground them."))
			return

	var/securing_time = 15
	// Don't increase the nesting time for monkeys and other species
	if(isHumanStrict(M))
		securing_time = 75

	user.visible_message(SPAN_WARNING("[user] pins [M] into [src], preparing the securing resin."),
	SPAN_WARNING("[user] pins [M] into [src], preparing the securing resin."))
	var/M_loc = M.loc
	if(!do_after(user, securing_time, INTERRUPT_ALL, BUSY_ICON_HOSTILE))
		return
	if(M.loc != M_loc) 
		return

	if(buckled_mob) //Just in case
		to_chat(user, SPAN_WARNING("There's already someone in [src]."))
		return

	if(ishuman(M)) //Improperly stunned Marines won't be nested
		var/mob/living/carbon/human/H = M
		if(!H.lying) //Don't ask me why is has to be
			to_chat(user, SPAN_WARNING("[M] is resisting, ground them."))
			return
			
	do_buckle(M, user)
	if(!M.mind || !ishuman(M))
		return

	var/choice = alert(M, "You have no possibility of escaping unless freed by your fellow marines, do you wish to Ghost? If you are freed while ghosted, you will be given the choice to return to your body.", ,"Ghost", "Remain")
	if(choice == "Ghost")
		ghost_of_buckled_mob = M.ghostize(FALSE)

/obj/structure/bed/nest/send_buckling_message(mob/M, mob/user)
	M.visible_message(SPAN_XENONOTICE("[user] secretes a thick, vile resin, securing [M] into [src]!"), \
	SPAN_XENONOTICE("[user] drenches you in a foul-smelling resin, trapping you in [src]!"), \
	SPAN_NOTICE("You hear squelching."))
	playsound(loc, "alien_resin_move", 50)

/obj/structure/bed/nest/afterbuckle(mob/M)
	. = ..()
	if(. && M.pulledby)
		M.pulledby.stop_pulling()
		resisting = 0 //just in case
		resisting_ready = 0
	update_icon()

/obj/structure/bed/nest/unbuckle(mob/user)
	if(!buckled_mob)
		return
	resisting = FALSE
	resisting_ready = FALSE
	buckled_mob.pixel_y = 0
	buckled_mob.old_y = 0

	if(ghost_of_buckled_mob && ishuman(buckled_mob))
		var/mob/living/carbon/human/H = buckled_mob
		if(H.undefibbable)
			return
			
		if(alert(ghost_of_buckled_mob, "You have been freed from your nest, do you want to return to your body?", ,"Yes", "No") == "Yes")
			if(!ghost_of_buckled_mob)
				return
			ghost_of_buckled_mob.can_reenter_corpse = TRUE
			ghost_of_buckled_mob.reenter_corpse()
			null_ghost_of_buckled_mob()
	..()

/obj/structure/bed/nest/ex_act(var/power)
	if(power >= EXPLOSION_THRESHOLD_VLOW)
		qdel(src)

/obj/structure/bed/nest/update_icon()
	overlays.Cut()
	if(on_fire)
		overlays += "alien_fire"
	if(buckled_mob)
		overlays += image("icon_state"="nest_overlay","layer"=LYING_LIVING_MOB_LAYER + 0.1)


/obj/structure/bed/nest/proc/healthcheck()
	if(health <= 0)
		density = 0
		qdel(src)

/obj/structure/bed/nest/fire_act()
	on_fire = 1
	if(on_fire)
		update_icon()
		QDEL_IN(src, rand(225, 400))


/obj/structure/bed/nest/attack_alien(mob/living/carbon/Xenomorph/M)
	if(isXenoLarva(M)) //Larvae can't do shit
		return
	if(M.a_intent == "hurt" && !buckled_mob) //can't slash nest with an occupant.
		M.visible_message(SPAN_DANGER("\The [M] claws at \the [src]!"), \
		SPAN_DANGER("You claw at \the [src]."))
		playsound(loc, "alien_resin_break", 25)
		health -= (M.melee_damage_upper + 25) //Beef up the damage a bit
		healthcheck()
	else
		attack_hand(M)

/obj/structure/bed/nest/attack_animal(mob/living/M as mob)
	M.visible_message(SPAN_DANGER("\The [M] tears at \the [src]!"), \
		SPAN_DANGER("You tear at \the [src]."))
	playsound(loc, "alien_resin_break", 25)
	health -= 40
	healthcheck()

/obj/structure/bed/nest/flamer_fire_act()
	qdel(src)

/obj/structure/bed/nest/Dispose()
	unbuckle()
	
	. = ..()

	if(ghost_of_buckled_mob)
		add_timer(CALLBACK(src, .proc/null_ghost_of_buckled_mob), 600) // Give the user 60 seconds to respond when nest is destroyed.

/obj/structure/bed/nest/proc/null_ghost_of_buckled_mob()
	ghost_of_buckled_mob = null