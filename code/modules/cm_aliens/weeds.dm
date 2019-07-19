#define NODERANGE 3

/obj/effect/alien/weeds
	name = "weeds"
	desc = "Weird black weeds..."
	icon = 'icons/Xeno/weeds.dmi'
	icon_state = "base"

	anchored = 1
	density = 0
	layer = WEED_LAYER
	unacidable = 1
	health = 1
	var/weed_strength = 1

/obj/effect/alien/weeds/New(pos, obj/effect/alien/weeds/node/node)
	..()
	if(node)
		weed_strength = node.weed_strength

	health = 1

	update_sprite()
	update_neighbours()
	if(node && node.loc && (get_dist(node, src) < node.node_range))
		spawn(rand(150, 200) / weed_strength) //stronger weeds expand faster
			if(loc && node && node.loc)
				weed_expand(node)


/obj/effect/alien/weeds/Dispose()
	var/oldloc = loc
	. = ..()
	update_neighbours(oldloc)


/obj/effect/alien/weeds/examine(mob/user)
	..()
	var/turf/T = get_turf(src)
	if(istype(T, /turf/open))
		T.ceiling_desc(user)


/obj/effect/alien/weeds/Crossed(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(!has_species(H,"Yautja")) //predators are immune to weed slowdown effect
			H.next_move_slowdown += 1


/obj/effect/alien/weeds/proc/weed_expand(obj/effect/alien/weeds/node/node)
	var/turf/U = get_turf(src)

	if(!istype(U))
		return

	direction_loop:
		for (var/dirn in cardinal)
			var/turf/T = get_step(src, dirn)

			if (!istype(T))
				continue

			if (!T.is_weedable())
				continue

			var/obj/effect/alien/weeds/W = locate() in T
			if (W)
				continue

			if(istype(T, /turf/closed/wall))
				new /obj/effect/alien/weeds/weedwall(T)
				continue

			if (istype(T.loc, /area/arrival))
				continue

			for(var/obj/structure/platform/P in src.loc)
				if(P.dir == reverse_direction(dirn))
					continue direction_loop

			for (var/obj/O in T)
				if(istype(O, /obj/structure/platform))
					if(O.dir == dirn)
						continue direction_loop
				if(istype(O, /obj/structure/window/framed))
					new /obj/effect/alien/weeds/weedwall/window(T)
					continue direction_loop
				else if(istype(O, /obj/structure/window_frame))
					new /obj/effect/alien/weeds/weedwall/frame(T)
					continue direction_loop
				else if(istype(O, /obj/machinery/door) && O.density && (!(O.flags_atom & ON_BORDER) || O.dir != dirn))
					continue direction_loop

			new /obj/effect/alien/weeds(T, node)


/obj/effect/alien/weeds/proc/update_neighbours(turf/U)
	if(!U)
		U = loc
	if(istype(U))
		for (var/dirn in cardinal)
			var/turf/T = get_step(U, dirn)

			if (!istype(T))
				continue

			var/obj/effect/alien/weeds/W = locate() in T
			if(W)
				W.update_sprite()


/obj/effect/alien/weeds/proc/update_sprite()
	var/my_dir = 0
	for (var/check_dir in cardinal)
		var/turf/check = get_step(src, check_dir)

		if (!istype(check))
			continue
		if(istype(check, /turf/closed/wall/resin))
			my_dir |= check_dir

		else if (locate(/obj/effect/alien/weeds) in check)
			my_dir |= check_dir

	if (my_dir == 15) //weeds in all four directions
		icon_state = "weed[rand(0,15)]"
	else if(my_dir == 0) //no weeds in any direction
		icon_state = "base"
	else
		icon_state = "weed_dir[my_dir]"


/obj/effect/alien/weeds/ex_act(severity)
	switch(severity)
		if(0 to EXPLOSION_THRESHOLD_LOW)
			if(prob(50))
				qdel(src)
		if(EXPLOSION_THRESHOLD_LOW to EXPLOSION_THRESHOLD_MEDIUM)
			if(prob(70))
				qdel(src)
		if(EXPLOSION_THRESHOLD_MEDIUM to INFINITY)
			qdel(src)

/obj/effect/alien/weeds/attackby(obj/item/W, mob/living/user)
	if(!W || !user || isnull(W) || (W.flags_item & NOBLUDGEON))
		return 0

	if(istype(src, /obj/effect/alien/weeds/node)) //The pain is real
		to_chat(user, SPAN_WARNING("You hit \the [src] with \the [W]."))
	else
		to_chat(user, SPAN_WARNING("You cut \the [src] away with \the [W]."))

	var/damage = W.force
	if(W.w_class < 4 || !W.sharp || W.force < 20) //only big strong sharp weapon are adequate
		damage /= 4

	if(istype(W, /obj/item/tool/weldingtool))
		var/obj/item/tool/weldingtool/WT = W

		if(WT.remove_fuel(0))
			damage = 15
			playsound(loc, 'sound/items/Welder.ogg', 25, 1)

	else
		playsound(loc, "alien_resin_break", 25)
	user.animation_attack_on(src)

	health -= damage
	healthcheck()
	return TRUE //don't call afterattack

/obj/effect/alien/weeds/proc/healthcheck()
	if(health <= 0)
		qdel(src)

/obj/effect/alien/weeds/update_icon()
	return

/obj/effect/alien/weeds/fire_act()
	if(!disposed)
		spawn(rand(100,175))
			qdel(src)


/obj/effect/alien/weeds/weedwall
	layer = RESIN_STRUCTURE_LAYER
	icon_state = "weedwall"
	var/list/wall_connections = list("0", "0", "0", "0")

/obj/effect/alien/weeds/weedwall/update_sprite()
	if(istype(loc, /turf/closed/wall))
		var/turf/closed/wall/W = loc
		wall_connections = W.wall_connections
		icon_state = ""
		var/image/I
		for(var/i = 1 to 4)
			I = image(icon, "weedwall[wall_connections[i]]", dir = 1<<(i-1))
			overlays += I

/obj/effect/alien/weeds/weedwall/window
	layer = ABOVE_TABLE_LAYER

/obj/effect/alien/weeds/weedwall/window/update_sprite()
	var/obj/structure/window/framed/F = locate() in loc
	if(F && F.junction)
		icon_state = "weedwall[F.junction]"

/obj/effect/alien/weeds/weedwall/frame
	layer = ABOVE_TABLE_LAYER

/obj/effect/alien/weeds/weedwall/frame/update_sprite()
	var/obj/structure/window_frame/WF = locate() in loc
	if(WF && WF.junction)
		icon_state = "weedframe[WF.junction]"



/obj/effect/alien/weeds/node
	name = "purple sac"
	desc = "A weird, pulsating node."
	icon_state = "weednode"
	var/node_range = NODERANGE
	health = 15


/obj/effect/alien/weeds/node/update_icon()
	overlays.Cut()
	overlays += "weednode"

/obj/effect/alien/weeds/node/New(loc, obj/effect/alien/weeds/node/node, mob/living/carbon/Xenomorph/X)
	for(var/obj/effect/alien/weeds/W in loc)
		if(W != src)
			qdel(W) //replaces the previous weed
			break

	overlays += "weednode"
	if(X)
		add_hiddenprint(X)
		weed_strength = X.weed_level
		if (weed_strength < 1)
			weed_strength = 1
		health = 15
		node_range = node_range + weed_strength - 1//stronger weeds expand further!
	..(loc, src)

#undef NODERANGE