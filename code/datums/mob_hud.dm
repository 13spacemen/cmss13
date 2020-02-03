/* HUD DATUMS */

//GLOBAL HUD LIST
var/datum/mob_hud/huds = list(
	MOB_HUD_SECURITY_BASIC = new /datum/mob_hud/security/basic(),
	MOB_HUD_SECURITY_ADVANCED = new /datum/mob_hud/security/advanced(),
	MOB_HUD_MEDICAL_BASIC = new /datum/mob_hud/medical/basic(),
	MOB_HUD_MEDICAL_ADVANCED = new /datum/mob_hud/medical/advanced(),
	MOB_HUD_MEDICAL_OBSERVER = new /datum/mob_hud/medical/observer(),
	MOB_HUD_XENO_INFECTION = new /datum/mob_hud/xeno_infection(), \
	MOB_HUD_XENO_STATUS = new /datum/mob_hud/xeno(),
	MOB_HUD_SQUAD = new /datum/mob_hud/squad(),
	)

/datum/mob_hud
	var/list/mob/hudmobs = list() //list of all mobs which display this hud
	var/list/mob/hudusers = list() //list with all mobs who can see the hud
	var/list/hud_icons = list() //these will be the indices for the atom's hud_list

/datum/mob_hud/proc/remove_hud_from(mob/user)
	for(var/mob/target in hudmobs)
		remove_from_single_hud(user, target)
	hudusers -= user

/datum/mob_hud/proc/remove_from_hud(mob/target)
	for(var/mob/user in hudusers)
		remove_from_single_hud(user, target)
	hudmobs -= target

/datum/mob_hud/proc/remove_from_single_hud(mob/user, mob/target)
	if(!user.client)
		return
	for(var/i in hud_icons)
		user.client.images -= target.hud_list[i]
		if(target.clone)
			user.client.images -= target.clone.hud_list[i]

/datum/mob_hud/proc/add_hud_to(mob/user)
	hudusers |= user
	for(var/mob/target in hudmobs)
		add_to_single_hud(user, target)

/datum/mob_hud/proc/add_to_hud(mob/target)
	hudmobs |= target
	for(var/mob/user in hudusers)
		add_to_single_hud(user, target)

/datum/mob_hud/proc/add_to_single_hud(mob/user, mob/target)
	if(!user.client)
		return
	for(var/i in hud_icons)
		user.client.images |= target.hud_list[i]
		if(target.clone)
			user.client.images |= target.clone.hud_list[i]




/////// MOB HUD TYPES //////////////////////////////////:


//Medical

/datum/mob_hud/medical
	hud_icons = list(HEALTH_HUD, STATUS_HUD)

//med hud used by silicons, only shows humans with a uniform with sensor mode activated.
/datum/mob_hud/medical/basic

/datum/mob_hud/medical/basic/proc/check_sensors(mob/living/carbon/human/H)
	if(!istype(H)) 
		return FALSE

	var/obj/item/clothing/under/U = H.w_uniform
	if(!istype(U))
		return FALSE
	
	if(U.sensor_mode <= 2 || U.has_sensor == 0)
		return FALSE

	return TRUE

/datum/mob_hud/medical/basic/add_to_single_hud(mob/user, mob/target)
	if(check_sensors(target))
		..()

/datum/mob_hud/medical/basic/proc/update_suit_sensors(mob/living/carbon/human/H)
	if(check_sensors(H))
		add_to_hud(H)
	else
		remove_from_hud(H)


//med hud used by medical hud glasses
/datum/mob_hud/medical/advanced

/datum/mob_hud/medical/advanced/add_to_single_hud(mob/user, mob/living/carbon/human/target)
	if(istype(target))
		if(target.species && target.species.name == "Yautja") //so you can't tell a pred's health with hud glasses.
			return
	..()

//medical hud used by ghosts
/datum/mob_hud/medical/observer
	hud_icons = list(HEALTH_HUD, STATUS_HUD_OOC)


//infection status that appears on humans, viewed by xenos only.
/datum/mob_hud/xeno_infection
	hud_icons = list(STATUS_HUD_XENO_INFECTION)



//Xeno status hud, for xenos
/datum/mob_hud/xeno
	hud_icons = list(HEALTH_HUD_XENO, PLASMA_HUD, PHEROMONE_HUD, QUEEN_OVERWATCH_HUD, ARMOR_HUD_XENO, XENO_STATUS_HUD)



//Security

/datum/mob_hud/security

/datum/mob_hud/security/basic
	hud_icons = list(ID_HUD)

/datum/mob_hud/security/advanced
	hud_icons = list(ID_HUD, IMPTRACK_HUD, IMPLOYAL_HUD, IMPCHEM_HUD, WANTED_HUD)


/datum/mob_hud/squad
	hud_icons = list(SQUAD_HUD, ORDER_HUD)




///////// MOB PROCS //////////////////////////////:


/mob/proc/add_to_all_mob_huds()
	return

/mob/living/carbon/human/add_to_all_mob_huds()
	for(var/datum/mob_hud/hud in huds)
		if(istype(hud, /datum/mob_hud/xeno)) //this one is xeno only
			continue
		hud.add_to_hud(src)

/mob/living/carbon/Xenomorph/add_to_all_mob_huds()
	for(var/datum/mob_hud/hud in huds)
		if(!istype(hud, /datum/mob_hud/xeno))
			continue
		hud.add_to_hud(src)


/mob/proc/remove_from_all_mob_huds()
	return

/mob/living/carbon/human/remove_from_all_mob_huds()
	for(var/datum/mob_hud/hud in huds)
		if(istype(hud, /datum/mob_hud/xeno))
			continue
		hud.remove_from_hud(src)

/mob/living/carbon/Xenomorph/remove_from_all_mob_huds()
	for(var/datum/mob_hud/hud in huds)
		if(istype(hud, /datum/mob_hud/xeno))
			hud.remove_from_hud(src)
			hud.remove_hud_from(src)
		else if (istype(hud, /datum/mob_hud/xeno_infection))
			hud.remove_hud_from(src) 
			



/mob/proc/refresh_huds(mob/source_mob)
	var/mob/M = source_mob ? source_mob : src
	for(var/datum/mob_hud/hud in huds)
		if(M in hud.hudusers)
			readd_hud(hud)

/mob/proc/readd_hud(datum/mob_hud/hud)
	hud.add_hud_to(src)




 //Medical HUDs

//called when a human changes suit sensors
/mob/living/carbon/human/proc/update_suit_sensors()
	var/datum/mob_hud/medical/basic/B = huds[MOB_HUD_MEDICAL_BASIC]
	B.update_suit_sensors(src)

//called when a human changes health
/mob/proc/med_hud_set_health()
	return
/mob/proc/med_hud_set_armor()
	return

/mob/living/carbon/Xenomorph/med_hud_set_health()
	var/image/holder = hud_list[HEALTH_HUD_XENO]
	if(stat == DEAD)
		holder.icon_state = "xenohealth0"
	else
		var/amount = round(health*100/maxHealth, 10)
		if(!amount) amount = 1 //don't want the 'zero health' icon when we still have 4% of our health
		holder.icon_state = "xenohealth[amount]"

/mob/living/carbon/Xenomorph/proc/overlay_overheal()
	var/image/holder = hud_list[HEALTH_HUD_XENO]
	holder.overlays.Cut()
	var/percentage_overheal = round(overheal*100/max_overheal, 10)
	if(percentage_overheal > 1)
		holder.overlays += image('icons/mob/hud/hud.dmi', "xenooverheal[percentage_overheal]")
	else 
		holder.overlays += image('icons/mob/hud/hud.dmi', "xenooverheal0")

/mob/living/carbon/Xenomorph/med_hud_set_armor()
	var/image/holder = hud_list[ARMOR_HUD_XENO]
	if(stat == DEAD || armor_deflection <=0)
		holder.icon_state = "xenoarmor0"
	else
		var/amount = round(armor_integrity*100/armor_integrity_max, 10)
		if(!amount) amount = 1 //don't want the 'zero health' icon when we still have 4% of our health
		holder.icon_state = "xenoarmor[amount]"


/mob/living/carbon/human/med_hud_set_health()
	var/image/holder = hud_list[HEALTH_HUD]
	if(stat == DEAD)
		holder.icon_state = "hudhealth-100"
	else
		var/percentage = round(health*100/species.total_health, 10)
		if(percentage > -1)
			holder.icon_state = "hudhealth[percentage]"
		else if(percentage > -49) 
			holder.icon_state = "hudhealth-0"
		else if(percentage > -99) 
			holder.icon_state = "hudhealth-50"
		else 
			holder.icon_state = "hudhealth-100"


/mob/proc/med_hud_set_status() //called when mob stat changes, or get a virus/xeno host, etc
	return

/mob/living/carbon/Xenomorph/med_hud_set_status()
	hud_set_plasma()
	hud_set_pheromone()

/mob/living/carbon/human/med_hud_set_status()
	var/image/holder = hud_list[STATUS_HUD]
	var/image/holder2 = hud_list[STATUS_HUD_OOC]
	var/image/holder3 = hud_list[STATUS_HUD_XENO_INFECTION]

	if(species && species.flags & IS_SYNTHETIC)
		holder.icon_state = "hudsynth"
		holder2.icon_state = "hudsynth"
		holder3.icon_state = "hudsynth"
	else
		var/revive_enabled = check_tod() && is_revivable()
		var/datum/internal_organ/heart/heart = internal_organs_by_name["heart"]

		var/holder2_set = 0
		if(status_flags & XENO_HOST)
			holder2.icon_state = "hudxeno"//Observer and admin HUD only
			holder2_set = 1
			var/obj/item/alien_embryo/E = locate(/obj/item/alien_embryo) in src
			if(E)
				holder3.icon_state = "infected[E.stage]"
			else if(locate(/mob/living/carbon/Xenomorph/Larva) in src)
				holder.icon_state = "infected5"

		if(stat == DEAD)
			if(revive_enabled)
				var/mob/dead/observer/G = get_ghost()
				if(client || istype(G))
					if(world.time > timeofdeath + revive_grace_period - SECONDS_60)
						holder.icon_state = "huddeadalmost"
						if(!holder2_set)
							holder2.icon_state = "huddeadalmost"
							holder3.icon_state = "huddead"
							holder2_set = 1
					else
						holder.icon_state = "huddeaddefib"
						if(!holder2_set)
							holder2.icon_state = "huddeaddefib"
							holder3.icon_state = "huddead"
							holder2_set = 1
				else
					holder.icon_state = "huddeaddnr"
					if(!holder2_set)
						holder2.icon_state = "huddeaddnr"
						holder3.icon_state = "huddead"
						holder2_set = 1
			else
				if(heart && (heart.is_broken() && check_tod())) // broken heart icon
					holder.icon_state = "huddeadheart"
					if(!holder2_set)
						holder2.icon_state = "huddeadheart"
						holder3.icon_state = "huddead"
						holder2_set = 1
					return

				holder.icon_state = "huddead"
				if(!holder2_set)
					holder2.icon_state = "huddead"
					holder3.icon_state = "huddead"
					holder2_set = 1

			return


		for(var/datum/disease/D in viruses)
			if(!D.hidden[SCANNER])
				holder.icon_state = "hudill"
				if(!holder2_set)
					holder2.icon_state = "hudill"
				return
		holder.icon_state = "hudhealthy"
		if(!holder2_set)
			holder2.icon_state = "hudhealthy"
			holder3.icon_state = ""




//xeno status HUD

/mob/living/carbon/Xenomorph/proc/hud_set_plasma()
	var/image/holder = hud_list[PLASMA_HUD]
	if(stat == DEAD)
		holder.icon_state = "plasma0"
	else
		var/amount = round(get_plasma_percentage(), 10)
		holder.icon_state = "plasma[amount]"


/mob/living/carbon/Xenomorph/proc/hud_set_pheromone()
	var/image/holder = hud_list[PHEROMONE_HUD]
	holder.overlays.Cut()
	holder.icon_state = "hudblank"
	if(stat != DEAD)
		var/tempname = ""
		if(frenzy_aura)
			tempname += "frenzy"
		if(warding_aura)
			tempname += "warding"
		if(recovery_aura)
			tempname += "recovery"
		if(tempname)
			holder.icon_state = "hud[tempname]"

		var/has_frenzy_aura = FALSE
		var/has_recovery_aura = FALSE
		var/has_warding_aura = FALSE
		switch(current_aura)
			if("frenzy")
				has_frenzy_aura = TRUE
			if("recovery")
				has_recovery_aura = TRUE
			if("warding")
				has_warding_aura = TRUE
			if("all")
				has_frenzy_aura = TRUE
				has_recovery_aura = TRUE
				has_warding_aura = TRUE		
		switch(leader_current_aura)
			if("frenzy")
				has_frenzy_aura = TRUE
			if("recovery")
				has_recovery_aura = TRUE
			if("warding")
				has_warding_aura = TRUE
			if("all")
				has_frenzy_aura = TRUE
				has_recovery_aura = TRUE
				has_warding_aura = TRUE	

		if (has_frenzy_aura)
			holder.overlays += image('icons/mob/hud/hud.dmi',src, "hudaurafrenzy")
		if(has_recovery_aura)
			holder.overlays += image('icons/mob/hud/hud.dmi',src, "hudaurarecovery")
		if(has_warding_aura)
			holder.overlays += image('icons/mob/hud/hud.dmi',src, "hudaurawarding")

	hud_list[PHEROMONE_HUD] = holder


/mob/living/carbon/Xenomorph/proc/hud_set_queen_overwatch()
	var/image/holder = hud_list[QUEEN_OVERWATCH_HUD]
	holder.overlays.Cut()
	holder.icon_state = "hudblank"
	if (stat != DEAD && hivenumber && hivenumber <= hive_datum.len)
		var/datum/hive_status/hive = hive_datum[hivenumber]
		var/mob/living/carbon/Xenomorph/Queen/Q = hive.living_xeno_queen
		if (Q && Q.observed_xeno == src)
			holder.icon_state = "queen_overwatch"
	hud_list[QUEEN_OVERWATCH_HUD] = holder


/mob/living/carbon/Xenomorph/proc/hud_update()
	var/image/holder = hud_list[XENO_STATUS_HUD]
	holder.overlays.Cut()
	if (stat == DEAD)
		return
	if (IS_XENO_LEADER(src))
		var/image/I = image('icons/mob/hud/hud.dmi',src, "hudxenoleader")
		holder.overlays += I
	if (upgrade)
		var/image/J = image('icons/mob/hud/hud.dmi',src, "hudxenoupgrade[upgrade]")
		holder.overlays += J

//Sec HUDs

/mob/living/carbon/proc/sec_hud_set_ID()
	return

/mob/living/carbon/human/sec_hud_set_ID()
	var/image/holder = hud_list[ID_HUD]
	holder.icon_state = "hudunknown"
	if(wear_id)
		var/obj/item/card/id/I = wear_id.GetID()
		if(I)
			holder.icon_state = "hud[ckey(I.GetJobName())]"



/mob/proc/sec_hud_set_implants()
	return

/mob/living/carbon/human/sec_hud_set_implants()
	var/image/holder1 = hud_list[IMPTRACK_HUD]
	var/image/holder2 = hud_list[IMPLOYAL_HUD]
	var/image/holder3 = hud_list[IMPCHEM_HUD]

	holder1.icon_state = "hudblank"
	holder2.icon_state = "hudblank"
	holder3.icon_state = "hudblank"

	for(var/obj/item/implant/I in src)
		if(I.implanted)
			if(istype(I,/obj/item/implant/tracking))
				holder1.icon_state = "hud_imp_tracking"
			if(istype(I,/obj/item/implant/loyalty))
				holder2.icon_state = "hud_imp_loyal"
			if(istype(I,/obj/item/implant/chem))
				holder3.icon_state = "hud_imp_chem"

/mob/living/carbon/human/proc/sec_hud_set_security_status()
	var/image/holder = hud_list[WANTED_HUD]
	holder.icon_state = "hudblank"
	var/perpname = name
	if(wear_id)
		var/obj/item/card/id/I = wear_id.GetID()
		if(I)
			perpname = I.registered_name

	if(!data_core)
		return

	for(var/datum/data/record/E in data_core.general)
		if(E.fields["name"] == perpname)
			for(var/datum/data/record/R in data_core.security)
				if((R.fields["id"] == E.fields["id"]) && (R.fields["criminal"] == "*Arrest*"))
					holder.icon_state = "hudwanted"
					break
				else if((R.fields["id"] == E.fields["id"]) && (R.fields["criminal"] == "Incarcerated"))
					holder.icon_state = "hudprisoner"
					break
				else if((R.fields["id"] == E.fields["id"]) && (R.fields["criminal"] == "Released"))
					holder.icon_state = "hudreleased"
					break



//Special role HUD

/mob/proc/hud_set_special_role()
	return

/mob/living/carbon/human/hud_set_special_role()
	var/image/holder = hud_list[SPECIALROLE_HUD]
	holder.icon_state = ""

	if(mind)
		switch(mind.special_role)
			if("traitor", "Syndicate")
				holder.icon_state = "hudsyndicate"
			if("Revolutionary")
				holder.icon_state = "hudrevolutionary"
			if("Head Revolutionary")
				holder.icon_state = "hudheadrevolutionary"
			if("Cultist")
				holder.icon_state = "hudcultist"
			if("Changeling")
				holder.icon_state = "hudchangeling"
			if("Wizard", "Fake Wizard")
				holder.icon_state = "hudwizard"
			if("Death Commando")
				holder.icon_state = "huddeathsquad"
			if("Ninja")
				holder.icon_state = "hudninja"
			if("head_loyalist")
				holder.icon_state = "hudloyalist"
			if("loyalist")
				holder.icon_state = "hudloyalist"
			if("head_mutineer")
				holder.icon_state = "hudmutineer"
			if("mutineer")
				holder.icon_state = "hudmutineer"





//Squad HUD

/mob/proc/hud_set_squad()
	return

/mob/living/carbon/human/hud_set_squad()
	var/image/holder = hud_list[SQUAD_HUD]
	holder.icon_state = "hudblank"
	holder.overlays.Cut()
	if(assigned_squad)
		var/squad_clr = squad_colors[assigned_squad.color]
		var/marine_rk
		var/obj/item/card/id/I = get_idcard()
		var/_role
		if(mind)
			_role = mind.assigned_role
		else if(I)
			_role = I.rank
		switch(_role)
			if("Squad Engineer") marine_rk = "engi"
			if("Squad Specialist") marine_rk = "spec"
			if("Squad Medic") marine_rk = "med"
			if("Squad Smartgunner") marine_rk = "gun"
			if("Executive Officer") marine_rk = "xo"
			if("Commanding Officer") marine_rk = "co"
			if("Pilot Officer") marine_rk = "po"
			if("Intelligence Officer") marine_rk = "io"
			if("Tank Crewman") marine_rk = "tc"
		if(assigned_squad.squad_leader == src)
			marine_rk = "leader"
		if(marine_rk)
			var/image/IMG = image('icons/mob/hud/hud.dmi',src, "hudmarinesquad")
			if(squad_clr)
				IMG.color = squad_clr
			else
				IMG.color = "#5A934A"
			holder.overlays += IMG
			holder.overlays += image('icons/mob/hud/hud.dmi',src, "hudmarinesquad[marine_rk]")
		if(assigned_squad && assigned_fireteam)
			var/image/IMG2 = image('icons/mob/hud/hud.dmi',src, "hudmarinesquad[assigned_fireteam]")
			IMG2.color = squad_clr
			holder.overlays += IMG2
			if(assigned_squad.fireteam_leaders[assigned_fireteam] == src)
				var/image/IMG3 = image('icons/mob/hud/hud.dmi',src, "hudmarinesquadftl")
				IMG3.color = squad_clr
				holder.overlays += IMG3
	else
		var/marine_rk
		var/border_rk
		var/obj/item/card/id/ID = get_idcard()
		var/_role
		if(mind)
			_role = mind.assigned_role
		else if(ID)
			_role = ID.rank
		switch(_role)
			if("Executive Officer")
				marine_rk = "xo"
				border_rk = "command"
			if("Commanding Officer")
				marine_rk = "co"
				border_rk = "command"
			if("Staff Officer")
				marine_rk = "so"
				border_rk = "command"
			if("Pilot Officer") marine_rk = "po"
			if("Intelligence Officer") marine_rk = "io"
			if("Tank Crewman") marine_rk = "tc"
		if(marine_rk)
			var/image/I = image('icons/mob/hud/hud.dmi',src, "hudmarinesquad")
			I.color = "#5A934A"
			holder.overlays += I
			holder.overlays += image('icons/mob/hud/hud.dmi',src, "hudmarinesquad[marine_rk]")
			if(border_rk)
				holder.overlays += image('icons/mob/hud/hud.dmi',src, "hudmarineborder[border_rk]")
	hud_list[SQUAD_HUD] = holder


/mob/proc/hud_set_order()
	return

// ORDER HUD
/mob/living/carbon/human/hud_set_order()
	var/image/holder = hud_list[ORDER_HUD]
	holder.icon_state = "hudblank"
	holder.overlays.Cut()
	if(mobility_aura)
		holder.overlays += image('icons/mob/hud/hud.dmi', src, "hudmove")
	if(protection_aura)
		holder.overlays += image('icons/mob/hud/hud.dmi', src, "hudhold")
	if(marksman_aura)
		holder.overlays += image('icons/mob/hud/hud.dmi', src, "hudfocus")
	hud_list[ORDER_HUD] = holder
