// Technically a support weapon but it functions like a gun
// Sue me
/obj/item/hardpoint/gun/smoke_launcher
	name = "Smoke Launcher"
	desc = "Launches smoke forward to obscure vision"

	icon_state = "slauncher_0"
	disp_icon = "tank"
	disp_icon_state = "slauncher"
	firing_sounds = list('sound/weapons/tank_smokelauncher_fire.ogg')

	slot = HDPT_SUPPORT
	hdpt_layer = HDPT_LAYER_SUPPORT

	point_cost = 250
	health = 300
	damage_multiplier = 0.075
	cooldown = 30
	accuracy = 0.8

	ammo = new /obj/item/ammo_magazine/hardpoint/tank_slauncher
	max_clips = 4

	use_muzzle_flash = FALSE

/obj/item/hardpoint/gun/smoke_launcher/get_icon_image(var/x_offset, var/y_offset, var/new_dir)

	var/icon_suffix = "NS"
	var/icon_state_suffix = "0"

	if(new_dir in list(NORTH, SOUTH))
		icon_suffix = "NS"
	else if(new_dir in list(EAST, WEST))
		icon_suffix = "EW"

	if(health <= 0) icon_state_suffix = "1"
	else if(ammo.current_rounds <= 0) icon_state_suffix = "2"

	return image(icon = "[disp_icon]_[icon_suffix]", icon_state = "[disp_icon_state]_[icon_state_suffix]", pixel_x = x_offset, pixel_y = y_offset)
