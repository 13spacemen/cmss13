
//Weston-Yamada SCP. Neutral to USCM, hostile to xenos.
/datum/emergency_call/scp
	name = "SCP - Secure, Contain, Protect (Squad)"
	mob_min = 5
	mob_max = 10
	shuttle_id = "Distress_PMC"
	name_of_spawn = "Distress_PMC"
	max_medics = 1
	max_heavies = 2


/datum/emergency_call/scp/New()
	..()
	arrival_message = "[MAIN_SHIP_NAME], this is USCSS Lunalorne responding to your distress call. We are boarding. Any hostile actions will be met with lethal force."
	objectives = "Sweep the [MAIN_SHIP_NAME], secure the specimen, get it safely back onto your shuttle and return. Don't antagonise the crew or engage hostiles, unless they stand between you and your mission."


/datum/emergency_call/scp/create_member(datum/mind/M)
	set waitfor = 0
	var/turf/spawn_loc = get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/mob = new(spawn_loc)
	mob.key = M.key
	if(mob.client) mob.client.change_view(world.view)

	ticker.mode.traitors += mob.mind

	if(!leader)       //First one spawned is always the leader.
		leader = mob
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Weston-Yamada SCP PMC squad leader!")))
		arm_equipment(mob, "Weston-Yamada SCP PMC (Leader)", TRUE, TRUE)
	else if(medics < max_medics)
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Weston-Yamada SCP PMC medic!")))
		arm_equipment(mob, "Weston-Yamada SCP PMC (Medic)", TRUE, TRUE)
		medics++
	else if(heavies < max_heavies*ERT_PMC_GUNNER_FRACTION)
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Weston-Yamada SCP PMC heavy gunner!")))
		arm_equipment(mob, "Weston-Yamada SCP PMC (Gunner)", TRUE, TRUE)
		heavies++
	else if(heavies < max_heavies)
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Weston-Yamada SCP PMC sniper!")))
		arm_equipment(mob, "Weston-Yamada SCP PMC (Sniper)", TRUE, TRUE)
		heavies++
	else
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Weston-Yamada SCP PMC mercenary!")))
		arm_equipment(mob, "Weston-Yamada SCP PMC (Standard)", TRUE, TRUE)
	print_backstory(mob)

	sleep(10)
	to_chat(M, "<B>Objectives:</b> [objectives]")


/datum/emergency_call/scp/print_backstory(mob/living/carbon/human/M)
	to_chat(M, "<B>You are part of Weston-Yamada Special Task Force Royal that arrived in 2182 following the UA withdrawl of the Tychon's Rift sector.</b>")
	to_chat(M, "<B>Task-force Royal is stationed aboard the USCSS Lunalorne, a powerful Weston-Yamada cruiser that patrols the outer edges of Tychon's Rift.</b>")
	to_chat(M, "<B>Under the directive of Weston-Yamada board member Johan Almric, you act as private security for Weston-Yamada science teams.</b>")
	to_chat(M, "<B>The USCSS Lunalorne contains a crew of roughly two hundred PMCs, and one hundred scientists and support personnel.</b>")
	to_chat(M, "")
	to_chat(M, "")
	to_chat(M, "<B>Sweep the [MAIN_SHIP_NAME], secure the specimen, get it safely back onto your shuttle and return.</b>")
	to_chat(M, "<B>Don't antagonise the crew or engage hostiles, unless they stand between you and your mission.</b>")


/datum/emergency_call/scp/platoon
	name = "SCP - Secure, Contain, Protect (Platoon)"
	mob_min = 8
	mob_max = 25
	probability = 0
	max_medics = 2
	max_heavies = 4