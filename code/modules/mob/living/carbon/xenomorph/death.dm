
/mob/living/carbon/Xenomorph/death(gibbed)
	var/msg = !is_robotic ? "lets out a waning guttural screech, green blood bubbling from its maw." : "begins to shudder, and the lights go out in its eyes as it lies still."
	. = ..(gibbed,msg)
	if(!.) return //If they're already dead, it will return.

	if(is_zoomed)
		zoom_out()

	if(!gibbed)
		if(hud_used && hud_used.healths)
			hud_used.healths.icon_state = "health_dead"
		if(hud_used && hud_used.alien_plasma_display)
			hud_used.alien_plasma_display.icon_state = "power_display_empty"
		update_icons()

	if(z != ADMIN_Z_LEVEL) //so xeno players don't get death messages from admin tests
		switch(caste)
			if("Queen")
				var/mob/living/carbon/Xenomorph/Queen/XQ = src
				playsound(loc, 'sound/voice/alien_queen_died.ogg', 75, 0)
				if(XQ.observed_xeno)
					XQ.set_queen_overwatch(XQ.observed_xeno, TRUE)
				if(XQ.ovipositor)
					XQ.dismount_ovipositor(TRUE)

				if(living_xeno_queen == src)
					xeno_message("<span class='xenoannounce'>A sudden tremor ripples through the hive... the Queen has been slain! Vengeance!</span>",3, corrupted)
					xeno_message("<span class='xenoannounce'>The slashing of hosts is now permitted.</span>",2)
					slashing_allowed = 1
					living_xeno_queen = null
					//on the off chance there was somehow two queen alive
					for(var/mob/living/carbon/Xenomorph/Queen/Q in living_mob_list)
						if(!isnull(Q) && Q != src && Q.stat != DEAD && !Q.corrupted)
							living_xeno_queen = Q
							break
					if(ticker && ticker.mode)
						ticker.mode.check_queen_status(queen_time)
			else
				if(living_xeno_queen && living_xeno_queen.observed_xeno == src)
					living_xeno_queen.set_queen_overwatch(src, TRUE)
				if(queen_chosen_lead)
					queen_chosen_lead = FALSE
				if(caste == "Predalien")
					playsound(loc, 'sound/voice/predalien_death.ogg', 75, 1)
				else
					playsound(loc, prob(50) == 1 ? 'sound/voice/alien_death.ogg' : 'sound/voice/alien_death2.ogg', 25, 1)
				var/area/A = get_area(src)
				if(living_xeno_queen && !corrupted)
					xeno_message("Hive: \The [src] has <b>died</b>[A? " at [sanitize(A.name)]":""]!", 3, corrupted)
				else if(corrupted)
					xeno_message("Hive: \The [src] has <b>died</b>[A? " at [sanitize(A.name)]":""]!", 3, corrupted)

	hud_set_queen_overwatch() //updates the overwatch hud to remove the upgrade chevrons, gold star, etc

	for(var/atom/movable/A in stomach_contents)
		stomach_contents -= A
		A.acid_damage = 0 //Reset the acid damage
		A.loc = loc

	round_statistics.total_xeno_deaths++
