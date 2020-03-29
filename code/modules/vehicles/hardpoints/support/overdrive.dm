/obj/item/hardpoint/buff/support/overdrive_enhancer
	name = "Overdrive Enhancer"
	desc = "Increases the movement speed of the vehicle it's atached to"

	icon_state = "odrive_enhancer"
	disp_icon = "tank"
	disp_icon_state = "odrive_enhancer"

	point_cost = 400
	health = 250

	// 25% movespeed increase. Remember that movespeed is given in delay
	buff_multipliers = list(
		"move" = 0.75
	)

	px_offsets = list(
		"1" = list(0, 0),
		"2" = list(0, 0),
		"4" = list(0, 32),
		"8" = list(0, 0)
	)
