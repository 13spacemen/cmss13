
/*
//================================================
				Blast Grenades
//================================================
*/

#define GRENADE_FIRE_RESISTANCE_MIN 10
#define GRENADE_FIRE_RESISTANCE_MAX 60

/obj/item/explosive/grenade/HE
	name = "\improper M40 HEDP grenade"
	desc = "High-Explosive Dual-Purpose. A small, but deceptively strong blast grenade that has been phasing out the M15 HE grenades alongside the M40 HEFA. Capable of being loaded in the M92 Launcher, or thrown by hand."
	icon_state = "grenade"
	det_time = 40
	item_state = "grenade"
	dangerous = 1
	underslug_launchable = TRUE
	var/explosion_power = 100
	var/explosion_falloff = 18
	var/shrapnel_count = 0
	var/shrapnel_type = /datum/ammo/bullet/shrapnel
	var/fire_resistance = 30 //to prevent highly controlled massive explosions

/obj/item/explosive/grenade/HE/New()

	..()

	fire_resistance = rand(GRENADE_FIRE_RESISTANCE_MIN, GRENADE_FIRE_RESISTANCE_MAX)

/obj/item/explosive/grenade/HE/prime()
	spawn(0)
		if(shrapnel_count)
			create_shrapnel(loc, shrapnel_count, , ,shrapnel_type)
			sleep(2) //so that mobs are not knocked down before being hit by shrapnel. shrapnel might also be getting deleted by explosions?
		apply_explosion_overlay()
		explosion_rec(loc, explosion_power, explosion_falloff)
		qdel(src)
	return

/obj/item/explosive/grenade/HE/proc/apply_explosion_overlay()
	var/obj/effect/overlay/O = new /obj/effect/overlay(loc)
	O.name = "grenade"
	O.icon = 'icons/effects/explosion.dmi'
	flick("grenade", O)
	spawn(7)
		qdel(O)
	return

/obj/item/explosive/grenade/HE/flamer_fire_act()
	fire_resistance-=1;
	if(fire_resistance<=0)
		spawn(rand(10,50))
			prime()

/obj/item/explosive/grenade/HE/PMC
	name = "\improper M12 blast grenade"
	desc = "A high-explosive grenade produced for private security firms. It explodes 3 seconds after the pin has been pulled."
	icon_state = "grenade_pmc"
	item_state = "grenade_ex"
	underslug_launchable = FALSE
	explosion_power = 130



/obj/item/explosive/grenade/HE/stick
	name = "\improper Webley Mk15 stick grenade"
	desc = "A blast grenade produced in the colonies, most commonly using old designs and schematics. It explodes 3 seconds after the pin has been pulled."
	icon_state = "grenade_stick"
	item_state = "grenade_stick"
	force = 10
	w_class = SIZE_SMALL
	throwforce = 15
	throw_speed = 2
	throw_range = 7
	underslug_launchable = FALSE
	explosion_power = 100


/*
//================================================
				Fragmentation Grenades
//================================================
*/
/obj/item/explosive/grenade/HE/frag
	name = "\improper M40 HEFA grenade"
	desc = "High-Explosive Fragmenting-Antipersonnel. A small, but deceptively strong fragmentation grenade that has been phasing out the M15 fragmentation grenades alongside the M40 HEDP. Capable of being loaded in the M92 Launcher, or thrown by hand."
	icon_state = "grenade_frag"
	item_state = "grenade_frag"
	explosion_power = 40
	shrapnel_count = 48



/obj/item/explosive/grenade/HE/m15
	name = "\improper M15 fragmentation grenade"
	desc = "An outdated USCM Fragmentation Grenade. With decades of service in the USCM, the old M15 Fragmentation Grenade is slowly being replaced by the slightly safer M40-series grenades. It is set to detonate in 4 seconds."
	icon_state = "grenade_ex"
	item_state = "grenade_ex"
	throw_speed = 2
	throw_range = 6
	underslug_launchable = FALSE
	explosion_power = 120
	shrapnel_count = 48



/obj/item/explosive/grenade/HE/upp
	name = "\improper Type 6 shrapnel grenade"
	desc = "A fragmentation grenade found within the ranks of the UPP. Designed to explode into shrapnel and rupture the bodies of opponents. It explodes 3 seconds after the pin has been pulled."
	icon_state = "grenade_upp"
	item_state = "grenade_upp"
	throw_speed = 2
	throw_range = 6
	underslug_launchable = FALSE
	explosion_power = 60
	shrapnel_count = 56


/*
//================================================
				Incendiary Grenades
//================================================
*/

/obj/item/explosive/grenade/incendiary
	name = "\improper M40 HIDP incendiary grenade"
	desc = "The M40 HIDP is a small, but deceptively strong incendiary grenade. It is set to detonate in 4 seconds."
	icon_state = "grenade_fire"
	det_time = 40
	item_state = "grenade_fire"
	flags_equip_slot = SLOT_WAIST
	dangerous = 1
	underslug_launchable = TRUE

	prime()
		spawn(0)
			flame_radius(2, get_turf(src))
			playsound(src.loc, 'sound/weapons/gun_flamethrower2.ogg', 35, 1, 4)
			qdel(src)
		return

proc/flame_radius(radius = 1, turf/turf) //~Art updated fire.
	if(!turf || !isturf(turf)) return
	if(radius < 0) radius = 0
	if(radius > 5) radius = 5
	new /obj/flamer_fire(turf, 5 + rand(0,11), 15, null, radius)


/obj/item/explosive/grenade/incendiary/molotov
	name = "\improper improvised firebomb"
	desc = "A potent, improvised firebomb, coupled with a pinch of gunpowder. Cheap, very effective, and deadly in confined spaces. Commonly found in the hands of rebels and terrorists. It can be difficult to predict how many seconds you have before it goes off, so be careful. Chances are, it might explode in your face."
	icon_state = "molotov"
	item_state = "molotov"
	arm_sound = 'sound/items/Welder2.ogg'
	underslug_launchable = FALSE
	New()
		det_time = rand(10,40)//Adds some risk to using this thing.
		..()

	prime()
		spawn(0)
			playsound(src.loc, 'sound/effects/hit_on_shattered_glass.ogg', 35, 1, 4)
			flame_radius(2, get_turf(src))
			playsound(src.loc, 'sound/weapons/gun_flamethrower2.ogg', 30, 1, 4)
			qdel(src)
		return


/obj/item/explosive/grenade/smokebomb
	name = "\improper M40 HSDP smoke grenade"
	desc = "The M40 HSDP is a small, but powerful smoke grenade. Based off the same platform as the M40 HEDP. It is set to detonate in 2 seconds."
	icon_state = "grenade_smoke"
	det_time = 20
	item_state = "grenade_smoke"
	underslug_launchable = TRUE
	var/datum/effect_system/smoke_spread/bad/smoke
	harmful = FALSE

	New()
		..()
		smoke = new /datum/effect_system/smoke_spread/bad
		smoke.attach(src)

	prime()
		playsound(src.loc, 'sound/effects/smoke.ogg', 25, 1, 4)
		smoke.set_up(3, 0, usr.loc, null, 6)
		smoke.start()
		qdel(src)

/obj/item/explosive/grenade/phosphorus
	name = "\improper M40 HPDP grenade"
	desc = "The M40 HPDP is a small, but powerful phosphorus grenade. It is set to detonate in 2 seconds."
	icon_state = "grenade_phos"
	det_time = 20
	item_state = "grenade_phos"
	underslug_launchable = TRUE
	var/datum/effect_system/smoke_spread/phosphorus/smoke
	dangerous = 1
	harmful = TRUE

	New()
		..()
		smoke = new /datum/effect_system/smoke_spread/phosphorus
		smoke.attach(src)

	prime()
		playsound(src.loc, 'sound/effects/smoke.ogg', 25, 1, 4)
		smoke.set_up(3, 0, usr.loc)
		smoke.start()
		qdel(src)

/obj/item/explosive/grenade/phosphorus/upp
	name = "\improper Type 8 WP grenade"
	desc = "A deadly gas grenade found within the ranks of the UPP. Designed to spill white phosporus on the target. It explodes 2 seconds after the pin has been pulled."
	icon_state = "grenade_upp_wp"
	item_state = "grenade_upp_wp"

/*
//================================================
					Other
//================================================
*/

/obj/item/explosive/grenade/HE/training
	name = "M07 training grenade"
	desc = "A harmless reusable version of the M40 HEDP, used for training. Capable of being loaded in the M92 Launcher, or thrown by hand."
	icon_state = "training_grenade"
	item_state = "grenade"
	dangerous = 0
	harmful = FALSE

/obj/item/explosive/grenade/HE/training/prime()
	spawn(0)
		playsound(loc, 'sound/items/detector.ogg', 80, 0, 7)
		active = 0 //so we can reuse it
		overlays.Cut()
		icon_state = initial(icon_state)
		det_time = initial(det_time) //these can be modified when fired by UGL
		throw_range = initial(throw_range)


/obj/item/explosive/grenade/HE/training/flamer_fire_act()
	return

/obj/item/explosive/grenade/HE/holy_hand_grenade
	name = "\improper Holy Hand Grenade of Antioch"
	desc = "And Saint Attila raised the hand grenade up on high, saying, \"O LORD, bless this Thy hand grenade that with it Thou mayest blow Thine enemies to tiny bits, in Thy mercy.\" And the LORD did grin and the people did feast upon the lambs and sloths and carp and anchovies... And the LORD spake, saying, \"First shalt thou take out the Holy Pin, then shalt thou count to three, no more, no less. Three shall be the number thou shalt count, and the number of the counting shall be three. Four shalt thou not count, neither count thou two, excepting that thou then proceed to three. Five is right out. Once the number three, being the third number, be reached, then lobbest thou thy Holy Hand Grenade of Antioch towards thy foe, who, being naughty in My sight, shall snuff it.\""
	icon_state = "banana"
	item_state = "banana"
	throw_speed = 3
	throw_range = 10
	underslug_launchable = FALSE
	explosion_power = 300
	det_time = 50
	unacidable = 1
	arm_sound = 'sound/voice/holy_chorus.ogg'//https://www.youtube.com/watch?v=hNV5sPZFuGg