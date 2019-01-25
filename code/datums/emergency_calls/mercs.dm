


//Randomly-equipped mercenaries. May be friendly or hostile to the USCM, hostile to xenos.
/datum/emergency_call/mercs
	name = "Freelancers (Squad)"
	mob_max = 8
	probability = 25

	New()
		..()
		arrival_message = "[MAIN_SHIP_NAME], this is Freelancer shuttle MC-98 responding to your distress call. Prepare for boarding."
		objectives = "Help the crew of the [MAIN_SHIP_NAME] in exchange for payment, and choose your payment well. Do what your Captain says. Ensure your survival at all costs."

/datum/emergency_call/mercs/print_backstory(mob/living/carbon/human/mob)
	mob << "<B> You started off in Tychon's Rift system as a colonist seeking work at one of the established colonies.</b>"
	mob << "<B> The withdrawl of United American forces in the early 2180s, the system fell into disarray.</b>"
	mob << "<B> Taking up arms as a mercenary, the Freelancers have become a powerful force of order in the system.</b>"
	mob << "<B> While they are motivated primarily by money, many colonists see the Freelancers as the main forces of order in Tychon's Rift.</b>"
	if(hostility)
		mob << "<B> Despite this, you have been tasked to ransack the [MAIN_SHIP_NAME] and kill anyone who gets in your way.</b>"
		mob << "<B> Any UPP, CLF or WY forces also responding are to be considered neutral parties unless proven hostile.</b>"
	else
		mob << "<B> To this end, you have been contacted by Weyland-Yutani of the USCSS Royce to assist the [MAIN_SHIP_NAME]..</b>"
		mob << "<B> Ensure they are not destroyed.</b>"

/datum/emergency_call/mercs/create_member(datum/mind/M)
	set waitfor = 0
	var/turf/spawn_loc = get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/mob = new(spawn_loc)
	mob.name = mob.real_name
	mob.dna.ready_dna(mob)
	mob.key = M.key
	if(mob.client) mob.client.change_view(world.view)
	mob.mind.assigned_role = "MODE"
	mob.mind.special_role = "Mercenary"
	ticker.mode.traitors += mob.mind

	if(!leader)       //First one spawned is always the leader.
		leader = mob
		arm_equipment(mob, "Freelancer (Leader)", TRUE)
		mob << "<font size='3'>\red You are the Freelancer leader!</font>"

	else if(medics < max_medics)
		arm_equipment(mob, "Freelancer (Medic)", TRUE)
		medics++
		mob << "<font size='3'>\red You are a Freelancer medic!</font>"
	else
		arm_equipment(mob, "Freelancer (Standard)", TRUE)
		mob << "<font size='3'>\red You are a Freelancer mercenary!</font>"
	print_backstory(mob)

	sleep(10)
	M << "<B>Objectives:</b> [objectives]"




/datum/emergency_call/mercs/platoon
	name = "Freelancers (Platoon)"
	mob_min = 8
	mob_max = 30
	probability = 0
	max_medics = 3
