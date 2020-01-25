/obj/structure/machinery/door/poddoor/shutters
	name = "\improper Shutters"
	icon = 'icons/obj/structures/doors/rapid_pdoor.dmi'
	icon_state = "shutter1"
	power_channel = ENVIRON
	processable = 0

/obj/structure/machinery/door/poddoor/shutters/New()
	..()
	layer = PODDOOR_CLOSED_LAYER

/obj/structure/machinery/door/poddoor/shutters/attackby(obj/item/C as obj, mob/user as mob)
	add_fingerprint(user)
	if(!C.pry_capable)
		return
	if(density && (stat & NOPOWER) && !operating && !unacidable)
		operating = 1
		spawn(-1)
			flick("shutterc0", src)
			icon_state = "shutter0"
			sleep(15)
			density = 0
			SetOpacity(0)
			operating = 0
			return
	return

/obj/structure/machinery/door/poddoor/shutters/open()
	if(operating == 1) //doors can still open when emag-disabled
		return
	if(!ticker)
		return 0
	if(!operating) //in case of emag
		operating = 1
	flick("shutterc0", src)
	icon_state = "shutter0"
	playsound(loc, 'sound/machines/blastdoor.ogg', 25)
	sleep(10)
	density = 0
	layer = open_layer
	SetOpacity(0)

	if(operating == 1) //emag again
		operating = 0
	if(autoclose)
		add_timer(CALLBACK(src, .proc/autoclose), 150)
	return 1

/obj/structure/machinery/door/poddoor/shutters/close()
	if(operating)
		return
	operating = 1
	flick("shutterc1", src)
	icon_state = "shutter1"
	layer = closed_layer
	density = 1
	if(visible)
		SetOpacity(1)
	playsound(loc, 'sound/machines/blastdoor.ogg', 25)

	sleep(10)
	operating = 0
	return

/obj/structure/machinery/door/poddoor/shutters/almayer
	icon = 'icons/obj/structures/doors/blastdoors_shutters.dmi'
	openspeed = 4 //shorter open animation.
	tiles_with = list(
		/obj/structure/window/framed/almayer,
		/obj/structure/machinery/door/airlock)

/obj/structure/machinery/door/poddoor/shutters/almayer/New()
	add_timer(CALLBACK(src, /atom.proc/relativewall_neighbours), 10)
	..()


//transit shutters used by marine dropships
/obj/structure/machinery/door/poddoor/shutters/transit
	name = "Transit shutters"
	desc = "Safety shutters to prevent dangerous depressurization during flight"
	icon = 'icons/obj/structures/doors/blastdoors_shutters.dmi'
	unacidable = TRUE

	ex_act(severity) //immune to explosions
		return

/obj/structure/machinery/door/poddoor/shutters/almayer/pressure
	name = "pressure shutters"
	density = 0
	opacity = 0
	unacidable = TRUE
	icon_state = "shutter0"
	open_layer = PODDOOR_CLOSED_LAYER
	closed_layer = PODDOOR_CLOSED_LAYER
	ex_act(severity)
		return
