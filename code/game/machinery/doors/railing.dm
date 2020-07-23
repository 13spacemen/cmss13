/obj/structure/machinery/door/poddoor/railing
	name = "\improper retractable railing"
	icon = 'icons/obj/structures/doors/railing.dmi'
	icon_state = "railing1"
	use_power = 0
	flags_atom = ON_BORDER
	opacity = 0
	unslashable = TRUE
	unacidable = TRUE
	projectile_coverage = PROJECTILE_COVERAGE_LOW

	throwpass = TRUE //You can throw objects over this, despite its density.
	open_layer = CATWALK_LAYER
	closed_layer = WINDOW_LAYER
	var/closed_layer_south = ABOVE_MOB_LAYER

/obj/structure/machinery/door/poddoor/railing/New()
	..()
	close()		//this makes sure to update sprite
	if(dir == SOUTH)
		layer = closed_layer_south
	else
		layer = closed_layer

/obj/structure/machinery/door/poddoor/railing/initialize_pass_flags(var/datum/pass_flags_container/PF)
	..()
	if (PF)
		PF.flags_can_pass_all = SETUP_LIST_FLAGS(LIST_FLAGS_REMOVE(PASS_OVER, PASS_OVER_FIRE), PASS_CRUSHER_CHARGE)

/obj/structure/machinery/door/poddoor/railing/open()
	if (operating == 1) //doors can still open when emag-disabled
		return 0
	if (!ticker)
		return 0
	if(!operating) //in case of emag
		operating = 1
	flick("railingc0", src)
	icon_state = "railing0"
	layer = open_layer

	sleep(12)

	density = 0
	if(operating == 1) //emag again
		operating = 0
	return 1

/obj/structure/machinery/door/poddoor/railing/close()
	if (operating)
		return 0
	density = 1
	operating = 1
	switch(dir)
		if(SOUTH)
			layer = closed_layer_south
		else
			layer = closed_layer
	flick("railingc1", src)
	icon_state = "railing1"

	sleep(12)

	operating = 0
	return 1