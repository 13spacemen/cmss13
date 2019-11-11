//Refer to life.dm for caller

/mob/living/carbon/human/proc/handle_regular_status_updates()

	if(status_flags & GODMODE)
		return 0

	if(stat == DEAD) //DEAD. BROWN BREAD. SWIMMING WITH THE SPESS CARP
		blinded = 1
		silent = 0
	else //ALIVE. LIGHTS ARE ON
		//updatehealth() // moved to Life()

		recalculate_move_delay = TRUE

		if(health <= config.health_threshold_dead || (species.has_organ["brain"] && !has_brain()))
			death(last_damage_source)
			blinded = 1
			silent = 0
			return 1

		//The analgesic effect wears off slowly
		analgesic = max(0, analgesic - 1)

		//UNCONSCIOUS. NO-ONE IS HOME
		if((getOxyLoss() > 50) || (config.health_threshold_crit > health))
			KnockOut(3)

		if(hallucination)
			if(hallucination >= 20)
				if(prob(3))
					fake_attack(src)
				if(!handling_hal)
					spawn handle_hallucinations() //The not boring kind!

			if(hallucination <= 2)
				hallucination = 0
				halloss = 0
			else
				hallucination -= 2

		else
			for(var/atom/a in hallucinations)
				hallucinations -= a
				qdel(a)

			if(halloss > 100)
				visible_message(SPAN_WARNING("\The [src] slumps to the ground, too weak to continue fighting."), \
				SPAN_WARNING("You slump to the ground, you're in too much pain to keep going."))
				KnockOut(10)
				setHalLoss(99)

		if(knocked_out)
			AdjustKnockedout(-species.knock_out_reduction)
			blinded = 1
			stat = UNCONSCIOUS
			if(halloss > 0)
				adjustHalLoss(-3)
		else if(sleeping)
			speech_problem_flag = 1
			handle_dreams()
			adjustHalLoss(-3)
			if(mind)
				if((mind.active && client != null) || immune_to_ssd) //This also checks whether a client is connected, if not, sleep is not reduced.
					sleeping = max(sleeping - 1, 0)
			blinded = 1
			stat = UNCONSCIOUS
			if(prob(2) && health && !hal_crit)
				spawn()
					emote("snore")
		else
			stat = CONSCIOUS

		if(in_stasis == STASIS_IN_CRYO_CELL) blinded = TRUE //Always blinded while in stasisTUBES

		//Eyes
		if(!species.has_organ["eyes"]) //Presumably if a species has no eyes, they see via something else.
			eye_blind = 0
			if(stat == CONSCIOUS) //even with 'eye-less' vision, unconsciousness makes you blind
				blinded = 0
			eye_blurry = 0
		else if(!has_eyes())           //Eyes cut out? Permablind.
			eye_blind =  1
			blinded =    1
			eye_blurry = 1
		else if(eye_blind)		       //Blindness, heals slowly over time
			eye_blind =  max(eye_blind - 1, 0)
			blinded =    1
		else if(eye_blurry)	           //Blurry eyes heal slowly
			eye_blurry = max(eye_blurry - 1, 0)

		//Ears
		if(ear_deaf) //Deafness, heals slowly over time
			ear_deaf = max(ear_deaf - 1, 0)
		else if(ear_damage)
			ear_damage = max(ear_damage - 0.05, 0)

		//Resting
		if(resting)
			dizziness = max(0, dizziness - 15)
			jitteriness = max(0, jitteriness - 15)
			adjustHalLoss(-3)
		else
			dizziness = max(0, dizziness - 3)
			jitteriness = max(0, jitteriness - 3)
			adjustHalLoss(-1)

		//Other
		handle_statuses()

		if(paralyzed)
			speech_problem_flag = 1
			KnockDown(1)
			silent = 1
			blinded = 1
			use_me = 0
			reagent_pain_modifier += PAIN_REDUCTION_FULL
			paralyzed--

		if(drowsyness)
			drowsyness = max(0,drowsyness--)
			eye_blurry = max(2, eye_blurry)
			if(prob(5))
				sleeping += 1
				KnockOut(5)

		confused = max(0, confused - 1)

	return 1