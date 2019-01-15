

//whiskey outpost extra marines
/datum/emergency_call/tank_crew
	name = "Tank Crew Cryo Reinforcements"
	mob_max = 2
	mob_min = 2
	probability = 0
	objectives = "Assist the USCM forces"
	name_of_spawn = "Distress_Cryo"
	shuttle_id = ""

/datum/emergency_call/tank_crew/create_member(datum/mind/M)
	set waitfor = 0
	if(map_tag == MAP_WHISKEY_OUTPOST)
		name_of_spawn = "distress_wo"
	var/turf/spawn_loc = get_spawn_point()
	var/mob/original = M.current

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/H = new(spawn_loc)
	H.dna.ready_dna(H)
	H.key = M.key
	if(H.client) H.client.change_view(world.view)

	sleep(5)
	arm_equipment(H, "USCM Tank Crewman (TC)", TRUE)
	H << "<font size='3'>\red You are a tank crewman in the USCM, you are here to assist in the defence of the [map_tag]. Listen to the chain of command.</B>"
		
	sleep(10)
	H << "<B>Objectives:</b> [objectives]"


	if(original)
		cdel(original)
