

//Weyland Yutani commandos. Friendly to USCM, hostile to xenos.
/datum/emergency_call/pmc
	name = "Weyland-Yutani PMC (Squad)"
	mob_max = 6
	probability = 25
	shuttle_id = "Distress_PMC"
	name_of_spawn = "Distress_PMC"

	New()
		..()
		arrival_message = "[MAIN_SHIP_NAME], this is USCSS Royce responding to your distress call. We are boarding. Any hostile actions will be met with lethal force."
		objectives = "Secure the Corporate Liaison and the [MAIN_SHIP_NAME] Commander, and eliminate any hostile threats. Do not damage W-Y property."


/datum/emergency_call/pmc/create_member(datum/mind/M)
	set waitfor = 0
	var/turf/spawn_loc = get_spawn_point()

	if(!istype(spawn_loc)) return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/mob = new(spawn_loc)
	mob.key = M.key
	if(mob.client) mob.client.change_view(world.view)

	ticker.mode.traitors += mob.mind
	if(!leader)       //First one spawned is always the leader.
		leader = mob
		arm_equipment(mob, "Weyland-Yutani PMC (Leader)", TRUE)
	else
		mob.mind.special_role = "MODE"
		if(prob(55)) //Randomize the heavy commandos and standard PMCs.
			arm_equipment(mob, "Weyland-Yutani PMC (Standard)", TRUE)
			mob << "<font size='3'>\red You are a Weyland Yutani mercenary!</font>"
		else
			if(prob(30))
				arm_equipment(mob, "Weyland-Yutani PMC (Sniper)", TRUE)
				mob << "<font size='3'>\red You are a Weyland Yutani sniper!</font>"
			else
				arm_equipment(mob, "Weyland-Yutani PMC (Gunner)", TRUE)
				mob << "<font size='3'>\red You are a Weyland Yutani heavy gunner!</font>"
	print_backstory(mob)

	sleep(10)
	M << "<B>Objectives:</b> [objectives]"



/datum/emergency_call/pmc/print_backstory(mob/living/carbon/human/M)
	M << "<B>You were born [pick(75;"in Europe", 15;"in Asia", 10;"on Mars")] to a [pick(75;"well-off", 15;"well-established", 10;"average")] family.</b>"
	M << "<B>Joining the ranks of Weyland Yutani has proven to be very profitable for you.</b>"
	M << "<B>While you are officially an employee, much of your work is off the books. You work as a skilled mercenary.</b>"
	M << "<B>You are [pick(50;"unaware of the xenomorph threat", 15;"acutely aware of the xenomorph threat", 10;"well-informed of the xenomorph threat")]</b>"
	M << ""
	M << ""
	M << "<B>You are part of  Weyland Yutani Task Force Oberon that arrived in 2182 following the UA withdrawl of the Tychon's Rift sector.</b>"
	M << "<B>Task-force Oberon is stationed aboard the USCSS Royce, a powerful Weyland-Yutani cruiser that patrols the outer edges of Tychon's Rift. </b>"
	M << "<B>Under the directive of Weyland-Yutani board member Johan Almric, you act as private security for Weyland Yutani science teams.</b>"
	M << "<B>The USCSS Royce contains a crew of roughly two hundred PMCs, and one hundred scientists and support personnel.</b>"
	M << ""
	M << ""
	M << "<B>Ensure no damage is incurred against Weyland Yutani. Make sure the CL is safe.</b>"
	M << "<B>Deny Weyland-Yutani's involvement and do not trust the UA/USCM forces.</b>"


/datum/emergency_call/pmc/spawn_items()
	var/turf/drop_spawn
	var/choice

	for(var/i = 0 to 0) //Spawns up to 3 random things.
		if(prob(20)) continue
		choice = (rand(1,8) - round(i/2)) //Decreasing values, rarer stuff goes at the end.
		if(choice < 0) choice = 0
		drop_spawn = get_spawn_point(1)
		if(istype(drop_spawn))
			switch(choice)
				if(0)
					new /obj/item/weapon/gun/smg/m39/elite(drop_spawn)
					new /obj/item/weapon/gun/smg/m39/elite(drop_spawn)
					new /obj/item/ammo_magazine/smg/m39/ap
					new /obj/item/ammo_magazine/smg/m39/ap
					continue
				if(1)
					new /obj/item/weapon/gun/smg/m39/elite(drop_spawn)
					new /obj/item/weapon/gun/smg/m39/elite(drop_spawn)
					new /obj/item/ammo_magazine/smg/m39/ap
					new /obj/item/ammo_magazine/smg/m39/ap
					continue
				if(2)
					new /obj/item/weapon/gun/flamer(drop_spawn)
					new /obj/item/weapon/gun/flamer(drop_spawn)
					new /obj/item/weapon/gun/flamer(drop_spawn)
					continue
				if(3)
					new /obj/item/explosive/plastique(drop_spawn)
					new /obj/item/explosive/plastique(drop_spawn)
					new /obj/item/explosive/plastique(drop_spawn)
					continue
				if(4)
					new /obj/item/weapon/gun/rifle/m41a/elite(drop_spawn)
					new /obj/item/weapon/gun/rifle/m41a/elite(drop_spawn)
					new /obj/item/ammo_magazine/rifle/incendiary
					new /obj/item/ammo_magazine/rifle/incendiary
					continue
				if(5)
					new /obj/item/weapon/gun/launcher/m92(drop_spawn)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					continue
				if(6)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					new /obj/item/weapon/gun/flamer(drop_spawn)
					continue
				if(7)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					new /obj/item/explosive/grenade/HE/PMC(drop_spawn)
					new /obj/item/weapon/gun/flamer(drop_spawn)
					continue

/datum/emergency_call/pmc/platoon
	name = "Weyland-Yutani PMC (Platoon)"
	mob_min = 8
	mob_max = 25
	probability = 0