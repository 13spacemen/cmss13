/proc/get_total_marines()
	var/count = 0
	var/mob/M
	for(M in player_list)
		if(ishuman(M) && M.mind && !M.mind.special_role) count++
	return count

// https://docs.google.com/spreadsheets/d/1PlnIwKhq-bVWWFPoBrzWYh1mWK04pyBSQUtUMEw3qSw/edit#gid=1290768907

/proc/job_slot_formula(var/marine_count,var/factor,var/c,var/min,var/max)
	if(marine_count <= factor)
		return min
	return round(Clamp((marine_count/factor)+c, min, max))

/proc/medic_slot_formula(var/playercount)
	return job_slot_formula(playercount,40,1,3,5)

/proc/engi_slot_formula(var/playercount)
	return job_slot_formula(playercount,50,1,2,4)

/proc/mp_slot_formula(var/playercount)
	return job_slot_formula(playercount,25,2,4,8)

/proc/po_slot_formula(var/playercount)
	return job_slot_formula(playercount,35,1,2,4)

/proc/so_slot_formula(var/playercount)
	return job_slot_formula(playercount,50,2,4,5)

/proc/doc_slot_formula(var/playercount)
	return job_slot_formula(playercount,25,1,4,6)

/proc/rsc_slot_formula(var/playercount)
	return job_slot_formula(playercount,40,1,2,3)

/proc/mt_slot_formula(var/playercount)
	return job_slot_formula(playercount,60,1,2,4)

/proc/ct_slot_formula(var/playercount)
	return job_slot_formula(playercount,30,0,2,3)

/proc/int_slot_formula(var/playercount)
	return job_slot_formula(playercount,30,1,1,3)

/proc/spec_slot_formula(var/playercount)
	return job_slot_formula(playercount,20,1,2,4)

/proc/sg_slot_formula(var/playercount)
	return job_slot_formula(playercount,20,1,2,4)

/proc/tank_slot_formula(var/playercount)
	if (map_tag == MAP_SOROKYNE_STRATA) 
		return 0
	else
		return job_slot_formula(playercount,100,1,0,2)

/proc/synth_slot_formula(var/playercount)
	return job_slot_formula(playercount,140,1,1,2)
