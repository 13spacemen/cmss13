/obj/structure/machinery/portable_atmospherics/powered/pump
	name = "portable air pump"

	icon = 'icons/obj/structures/machinery/atmos.dmi'
	icon_state = "psiphon:0"
	density = 1
	flags_can_pass_all = PASS_OVER|PASS_AROUND|PASS_UNDER

	var/on = 0

/obj/structure/machinery/portable_atmospherics/powered/pump/New()
	..()
	cell = new/obj/item/cell(src)

/obj/structure/machinery/portable_atmospherics/powered/pump/update_icon()
	src.overlays = 0

	if(on && cell && cell.charge)
		icon_state = "psiphon:1"
	else
		icon_state = "psiphon:0"

	if(connected_port)
		overlays += "siphon-connector"

	return
