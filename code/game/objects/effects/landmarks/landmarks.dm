/obj/effect/landmark
	name = "landmark"
	icon = 'icons/mob/hud/screen1.dmi'
	icon_state = "x2"
	anchored = 1.0
	unacidable = TRUE

/obj/effect/landmark/New()

	..()
	tag = "landmark*[name]"
	invisibility = 101

	landmarks_list += src

	switch(name)			//some of these are probably obsolete

		if("start")
			newplayer_start += loc
			qdel(src)

		if("JoinLate")
			latejoin += loc
			qdel(src)

		if("latewhiskey")
			latewhiskey += loc
			qdel(src)

		if("JoinLateGateway")
			latejoin_gateway += loc
			qdel(src)

		if("JoinLateCryo")
			latejoin_cryo += loc
			qdel(src)

		if("SupplyElevator")
			SupplyElevator = loc
			qdel(src)

		if("HangarUpperElevator")
			HangarUpperElevator = loc
			qdel(src)

		if("HangarLowerElevator")
			HangarLowerElevator = loc
			qdel(src)

		//prisoners
		if("prisonwarp")
			prisonwarp += loc
			qdel(src)

		if("Holding Facility")
			holdingfacility += loc
			qdel(src)

		if("tdome1")
			tdome1	+= loc
			qdel(src)

		if("tdome2")
			tdome2 += loc
			qdel(src)

		if("tdomeadmin")
			tdomeadmin	+= loc
			qdel(src)

		if("tdomeobserve")
			tdomeobserve += loc
			qdel(src)

		//not prisoners
		if("prisonsecuritywarp")
			prisonsecuritywarp += loc
			qdel(src)

		if("blobstart")
			blobstart += loc
			qdel(src)

		if("xeno_spawn")
			xeno_spawn += loc
			qdel(src)

		if("surv_spawn")
			surv_spawn += loc
			qdel(src)

		if("pred_spawn")
			pred_spawn += loc
			qdel(src)

		if("pred_elder_spawn")
			pred_elder_spawn += loc
			qdel(src)

		if("yautja_teleport_loc")
			if(z == MAIN_SHIP_Z_LEVEL)
				yautja_almayer_loc += loc
			else
				yautja_teleport_loc += loc
			qdel(src)



	return 1

/obj/effect/landmark/Dispose()
	landmarks_list -= src
	. = ..()

/obj/effect/landmark/start
	name = "start"
	icon = 'icons/mob/hud/screen1.dmi'
	icon_state = "x"
	anchored = 1.0

/obj/effect/landmark/start/New()
	..()
	if(!disposed)
		tag = "start*[name]"
		invisibility = 101

	return 1

/obj/effect/landmark/start/AISloc
	name = "AI"

/obj/effect/landmark/start/whiskey
	icon = 'icons/old_stuff/mark.dmi'
	icon_state = "spawn_shuttle"

/obj/effect/landmark/map_tag
	name = "mapping tag"

/obj/effect/landmark/map_tag/New()
	map_tag = name
	qdel(src)
	return
