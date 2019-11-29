


//Deathsquad Commandos
/datum/emergency_call/death
	name = "Weyland Deathsquad"
	mob_max = 8
	mob_min = 5
	arrival_message = "Intercepted Transmission: '!`2*%slau#*jer t*h$em a!l%. le&*ve n(o^ w&*nes%6es.*v$e %#d ou^'"
	objectives = "Wipe out everything. Ensure there are no traces of the infestation or any witnesses."
	probability = 0
	shuttle_id = "Distress_PMC"
	name_of_spawn = "Distress_PMC"
	max_medics = 1
	max_heavies = 2



// DEATH SQUAD--------------------------------------------------------------------------------
/datum/emergency_call/death/create_member(datum/mind/M)
	set waitfor = 0
	var/turf/spawn_loc = get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/mob = new(spawn_loc)
	mob.key = M.key
	if(mob.client) mob.client.change_view(world.view)
	ticker.mode.traitors += mob.mind
	mob.mind.set_cm_skills(/datum/skills/commando/deathsquad)

	if(!leader)       //First one spawned is always the leader.
		leader = mob
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are the Deathsquad Leader!")))
		to_chat(mob, "<B> You must clear out any traces of the infestation and its survivors.</b>")
		to_chat(mob, "<B> Follow any orders directly from Weyland-Yutani!</b>")
		arm_equipment(mob, "Weyland-Yutani Deathsquad Leader", TRUE, TRUE)
	else if(medics < max_medics)
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Deathsquad Medic!")))
		to_chat(mob, "<B> You must clear out any traces of the infestation and its survivors.</b>")
		to_chat(mob, "<B> Follow any orders directly from Weyland-Yutani!</b>")
		arm_equipment(mob, "Weyland-Yutani Deathsquad Medic", TRUE, TRUE)
		medics++
	else if(heavies < max_heavies)
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Deathsquad Terminator!")))
		to_chat(mob, "<B> You must clear out any traces of the infestation and its survivors.</b>")
		to_chat(mob, "<B> Follow any orders directly from Weyland-Yutani!</b>")
		arm_equipment(mob, "Weyland-Yutani Deathsquad Terminator", TRUE, TRUE)
		heavies++
	else
		to_chat(mob, SPAN_WARNING(FONT_SIZE_BIG("You are a Deathsquad Commando!")))
		to_chat(mob, "<B> You must clear out any traces of the infestation and its survivors.</b>")
		to_chat(mob, "<B> Follow any orders directly from Weyland-Yutani!</b>")
		arm_equipment(mob, "Weyland-Yutani Deathsquad", TRUE, TRUE)

	sleep(10)
	to_chat(M, "<B>Objectives:</b> [objectives]")