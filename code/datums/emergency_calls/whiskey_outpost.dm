

//whiskey outpost extra marines
/datum/emergency_call/wo
	name = "Marine Reinforcements (Squad)"
	mob_max = 15
	mob_min = 1
	probability = 0
	objectives = "Assist the USCM forces"
	max_heavies = 4
	max_medics = 2

/datum/emergency_call/wo/create_member(datum/mind/M)
	set waitfor = 0
	if(map_tag == MAP_WHISKEY_OUTPOST)
		name_of_spawn = "distress_wo"
	var/turf/spawn_loc = get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/mob = new(spawn_loc)
	mob.key = M.key
	if(mob.client) mob.client.change_view(world.view)
	mob.mind.assigned_role = ""
	mob.mind.special_role = ""

	sleep(5)
	if(!leader)
		leader = mob
		arm_equipment(mob, "Dust Raider Squad Leader", TRUE)
		to_chat(mob, "<font size='3'>\red You are a Squad leader in the USCM, your squad is here to assist in the defence of the [map_tag]. </B>")
	else if (heavies < max_heavies)
		if(prob(40))
			arm_equipment(mob, "Dust Raider Smartgunner", TRUE)
			to_chat(mob, "<font size='3'>\red You are a smartgunner in the USCM, your squad is here to assist in the defence of the [map_tag]. Listen to [leader.name] they are your (acting) squad leader. </B>")
		else if(prob(20))
			arm_equipment(mob, "Dust Raider Specialist", TRUE)
			to_chat(mob, "<font size='3'>\red You are a specialist in the USCM, your squad is here to assist in the defence of the [map_tag]. Listen to [leader.name] they are your (acting) squad leader. </B>")
		else
			arm_equipment(mob, "Dust Raider Engineer", TRUE)
			to_chat(mob, "<font size='3'>\red You are an engineer in the USCM, your squad is here to assist in the defence of the [map_tag]. Listen to [leader.name] they are your (acting) squad leader. </B>")
		heavies ++
	else if (medics < max_medics)
		arm_equipment(mob, "Dust Raider Medic", TRUE)
		to_chat(mob, "<font size='3'>\red You are a medic in the USCM, your squad is here to assist in the defence of the [map_tag]. Listen to [leader.name] they are your (acting) squad leader. </B>")
		medics ++
	else
		arm_equipment(mob,"Dust Raider Private", TRUE)
		to_chat(mob, "<font size='3'>\red You are a private in the USCM, your squad is here to assist in the defence of [map_tag]. Listen to [leader.name] they are your (acting) squad leader. </B>")

	sleep(10)
	to_chat(mob, "<B>Objectives:</b> [objectives]")
	RoleAuthority.randomize_squad(mob)
	mob.sec_hud_set_ID()
	mob.sec_hud_set_implants()
	mob.hud_set_special_role()
	mob.hud_set_squad()

	data_core.manifest_inject(mob) //Put people in crew manifest


/datum/game_mode/whiskey_outpost/activate_distress()
	picked_call = /datum/emergency_call/wo
	picked_call.activate(FALSE)
	return

datum/emergency_call/wo/platoon
	name = "Marine Reinforcements (Platoon)"
	mob_min = 8
	mob_max = 30
	probability = 0
	max_heavies = 8

datum/emergency_call/wo/platoon/cryo
	name = "Marine Reinforcements (Platoon) (Cryo)"
	probability = 0
	name_of_spawn = "Distress_Cryo"
	shuttle_id = ""

datum/emergency_call/wo/cryo
	name = "Marine Reinforcements (Squad) (Cryo)"
	probability = 0
	name_of_spawn = "Distress_Cryo"
	shuttle_id = ""