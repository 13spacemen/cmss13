/****************************************************
				EXTERNAL ORGANS
****************************************************/
/datum/limb
	var/name = "limb"
	var/icon_name = null
	var/body_part = null
	var/icon_position = 0
	var/damage_state = "00"
	var/brute_dam = 0
	var/burn_dam = 0
	var/max_damage = 0
	var/max_size = 0
	var/last_dam = -1
	var/knitting_time = -1
	var/time_to_knit = -1 // snowflake vars for doing self-bone healing, think preds and magic research chems

	var/display_name
	var/list/wounds = list()
	var/number_wounds = 0 // cache the number of wounds, which is NOT wounds.len!

	var/tmp/perma_injury = 0

	var/min_broken_damage = 30

	var/list/datum/autopsy_data/autopsy_data = list()
	var/list/trace_chemicals = list() // traces of chemicals in the organ,
									  // links chemical IDs to number of ticks for which they'll stay in the blood

	var/datum/limb/parent
	var/list/datum/limb/children

	// Internal organs of this body part
	var/list/datum/internal_organ/internal_organs

	var/damage_msg = "<span class='danger'>You feel an intense pain</span>"
	var/broken_description

	var/surgery_open_stage = 0
	var/bone_repair_stage = 0
	var/limb_replacement_stage = 0
	var/cavity = 0

	var/in_surgery_op = FALSE //whether someone is currently doing a surgery step to this limb
	var/surgery_organ //name of the organ currently being surgically worked on (detach/remove/etc)

	var/encased       // Needs to be opened with a saw to access the organs.

	var/obj/item/hidden = null
	var/list/implants = list()

	// how often wounds should be updated, a higher number means less often
	var/wound_update_accuracy = 1
	var/status //limb status flags

	var/mob/living/carbon/human/owner = null
	var/vital //Lose a vital limb, die immediately.

	var/has_stump_icon = FALSE

	var/splint_icon_amount = 1
	var/bandage_icon_amount = 1

	var/icon/splinted_icon = null

	var/list/bleeding_effects_list = list()


/datum/limb/New(datum/limb/P, mob/mob_owner)
	if(P)
		parent = P
		if(!parent.children)
			parent.children = list()
		parent.children.Add(src)
	if(mob_owner)
		owner = mob_owner
	return ..()



/*
/datum/limb/proc/get_icon(var/icon/race_icon, var/icon/deform_icon)
	return icon('icons/mob/human.dmi',"blank")
*/

/datum/limb/proc/process()
		return 0

//Autopsy stuff

//Handles chem traces
/mob/living/carbon/human/proc/handle_trace_chems()
	//New are added for reagents to random organs.
	for(var/datum/reagent/A in reagents.reagent_list)
		var/datum/limb/O = pick(limbs)
		O.trace_chemicals[A.name] = 100

//Adds autopsy data for used_weapon.
/datum/limb/proc/add_autopsy_data(var/used_weapon, var/damage)
	var/datum/autopsy_data/W = autopsy_data[used_weapon]
	if(!W)
		W = new()
		W.weapon = used_weapon
		autopsy_data[used_weapon] = W

	W.hits += 1
	W.damage += damage
	W.time_inflicted = world.time



/****************************************************
			   DAMAGE PROCS
****************************************************/

/datum/limb/proc/emp_act(severity)
	if(!(status & LIMB_ROBOT))	//meatbags do not care about EMP
		return
	var/probability = 30
	var/damage = 15
	if(severity == 2)
		probability = 1
		damage = 3
	if(prob(probability))
		droplimb(0, 0, "EMP")
	else
		take_damage(damage, 0, 1, 1, used_weapon = "EMP")


/datum/limb/proc/take_damage_organ_damage(brute, sharp)	
	if(!owner)
		return

	var/armor = owner.getarmor_organ(src, ARMOR_INTERNALDAMAGE)
	if(owner.mind && owner.mind.cm_skills)
		armor += owner.mind.cm_skills.get_skill_level(SKILL_ENDURANCE)*5

	var/damage = armor_damage_reduction(config.marine_organ_damage, brute, armor, sharp ? ARMOR_SHARP_INTERNAL_PENETRATION : 0, 0, 0, max_damage ? (100*(max_damage-brute_dam) / max_damage) : 100)

	if(internal_organs && prob(2*damage/3))
		//Damage an internal organ
		var/datum/internal_organ/I = pick(internal_organs)
		I.take_damage(brute / 2)
		return TRUE
	return FALSE

/datum/limb/proc/take_damage_bone_break(brute)
	if(!owner)
		return

	var/armor = owner.getarmor_organ(src, ARMOR_INTERNALDAMAGE)
	if(owner.mind && owner.mind.cm_skills)
		armor += owner.mind.cm_skills.get_skill_level(SKILL_ENDURANCE)*5

	var/damage = armor_damage_reduction(config.marine_organ_damage, brute*3, armor, 0, 0, 0, max_damage ? (100*(max_damage-brute_dam) / max_damage) : 100)

	if(brute_dam > min_broken_damage * config.organ_health_multiplier && prob(damage*2))
		fracture()
/*
	Describes how limbs (body parts) of human mobs get damage applied.
	Less clear vars:
	*	impact_name: name of an "impact icon." For now, is only relevant for projectiles but can be expanded to apply to melee weapons with special impact sprites.
*/
/datum/limb/proc/take_damage(brute, burn, sharp, edge, used_weapon = null, list/forbidden_limbs = list(), no_limb_loss, impact_name = null, var/damage_source = "dismemberment")
	if((brute <= 0) && (burn <= 0))
		return 0

	if(status & LIMB_DESTROYED)
		return 0
	if(status & LIMB_ROBOT)

		var/brmod = 0.66
		var/bumod = 0.66

		if(istype(owner,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			if(H.species && H.species.flags & IS_SYNTHETIC)
				brmod = H.species.brute_mod
				bumod = H.species.burn_mod

		brute *= brmod //~2/3 damage for ROBOLIMBS
		burn *= bumod //~2/3 damage for ROBOLIMBS

	//High brute damage or sharp objects may damage internal organs
	if(istype(owner,/mob/living/carbon/human))
		if(take_damage_organ_damage(brute, sharp))
			brute /= 2

	if(config.bones_can_break && !(status & LIMB_ROBOT))
		take_damage_bone_break(brute)

	if(status & LIMB_BROKEN && prob(40) && brute > 10)
		if(!(owner.species && (owner.species.flags & NO_PAIN)))
			owner.emote("scream") //Getting hit on broken hand hurts
	if(used_weapon)
		add_autopsy_data("[used_weapon]", brute + burn)

	var/can_cut = (prob(brute*2) || sharp) && !(status & LIMB_ROBOT)
	// If the limbs can break, make sure we don't exceed the maximum damage a limb can take before breaking
	if((brute_dam + burn_dam + brute + burn) < max_damage || !config.limbs_can_break)
		if(brute)
			if(can_cut)
				createwound(CUT, brute, impact_name)
			else
				createwound(BRUISE, brute, impact_name)
		if(burn)
			createwound(BURN, burn, impact_name)
	else
		//If we can't inflict the full amount of damage, spread the damage in other ways
		//How much damage can we actually cause?
		var/can_inflict = max_damage * config.organ_health_multiplier - (brute_dam + burn_dam)
		var/remain_brute = brute
		var/remain_burn = burn
		if(can_inflict)
			if(brute > 0)
				//Inflict all brute damage we can
				if(can_cut)
					createwound(CUT, min(brute, can_inflict), impact_name)
				else
					createwound(BRUISE, min(brute, can_inflict), impact_name)
				var/temp = can_inflict
				//How much more damage can we inflict
				can_inflict = max(0, can_inflict - brute)
				//How much brute damage is left to inflict
				remain_brute = max(0, brute - temp)

			if(burn > 0 && can_inflict)
				//Inflict all burn damage we can
				createwound(BURN, min(burn,can_inflict), impact_name)
				//How much burn damage is left to inflict
				remain_burn = max(0, burn - can_inflict)

		//If there are still hurties to dispense
		if(remain_burn || remain_brute)
			//List organs we can pass it to
			var/list/datum/limb/possible_points = list()
			if(parent)
				possible_points += parent
			if(children)
				possible_points += children
			if(forbidden_limbs.len)
				possible_points -= forbidden_limbs
			if(possible_points.len)
				//And pass the damage around, but not the chance to cut the limb off.
				var/datum/limb/target = pick(possible_points)
				target.take_damage(remain_brute, remain_burn, sharp, edge, used_weapon, forbidden_limbs + src, TRUE)


	//Sync the organ's damage with its wounds
	src.update_damages()

	//If limb took enough damage, try to cut or tear it off
	if(body_part != UPPER_TORSO && body_part != LOWER_TORSO && !no_limb_loss)
		var/obj/item/clothing/head/helmet/H = owner.head
		if(!(body_part == HEAD && istype(H) && !isSynth(owner)) \
			&& config.limbs_can_break && brute_dam >= max_damage * config.organ_health_multiplier
		)
			var/cut_prob = brute/max_damage * 5
			if(prob(cut_prob))
				droplimb(0, 0, damage_source)
				return

	owner.updatehealth()
	start_processing()
	return update_icon()

/datum/limb/proc/heal_damage(brute, burn, internal = 0, robo_repair = 0)
	if(status & LIMB_ROBOT && !robo_repair)
		return

	if(brute)
		remove_all_bleeding(TRUE)

	if(internal)
		remove_all_bleeding(FALSE, TRUE)

	//Heal damage on the individual wounds
	for(var/datum/wound/W in wounds)
		if(brute == 0 && burn == 0)
			break

		// heal brute damage
		if(W.damage_type == CUT || W.damage_type == BRUISE)
			brute = W.heal_damage(brute)
		else if(W.damage_type == BURN)
			burn = W.heal_damage(burn)

	if(internal)
		status &= ~LIMB_BROKEN
		status |= LIMB_REPAIRED
		perma_injury = 0

	//Sync the organ's damage with its wounds
	src.update_damages()
	owner.updatehealth()

	var/result = update_icon()
	return result

/*
This function completely restores a damaged organ to perfect condition.
*/
/datum/limb/proc/rejuvenate()
	damage_state = "00"
	if(status & LIMB_ROBOT)	//Robotic organs stay robotic.  Fix because right click rejuvinate makes IPC's organs organic.
		status = LIMB_ROBOT
	else
		status = 0
	perma_injury = 0
	brute_dam = 0
	burn_dam = 0
	wounds.Cut()
	number_wounds = 0

	// heal internal organs
	for(var/datum/internal_organ/current_organ in internal_organs)
		current_organ.rejuvenate()

	// remove embedded objects and drop them on the floor
	for(var/obj/implanted_object in implants)
		if(!istype(implanted_object,/obj/item/implant))	// We don't want to remove REAL implants. Just shrapnel etc.
			implanted_object.loc = owner.loc
			implants -= implanted_object
			if(is_sharp(implanted_object) || istype(implanted_object, /obj/item/shard/shrapnel))
				owner.embedded_items -= implanted_object

	owner.updatehealth()


/datum/limb/proc/take_damage_internal_bleeding(damage)
	if(!owner)
		return
	
	var/armor = owner.getarmor_organ(src, ARMOR_INTERNALDAMAGE)
	if(owner.mind && owner.mind.cm_skills)
		armor += owner.mind.cm_skills.get_skill_level(SKILL_ENDURANCE)*5
	
	var/damage_ratio = armor_damage_reduction(config.marine_organ_damage, 2*damage/3, armor, 0, 0, 0, max_damage ? (100*(max_damage - brute_dam) / max_damage) : 100)
	if(prob(damage_ratio) && damage > 10)
		var/datum/wound/internal_bleeding/I = new (0)
		add_bleeding(I, TRUE)
		wounds += I
		owner.custom_pain("You feel something rip in your [display_name]!", 1)

/datum/limb/proc/createwound(var/type = CUT, var/damage, var/impact_name)
	if(!damage) 
		return

	//moved this before the open_wound check so that having many small wounds for example doesn't somehow protect you from taking internal damage (because of the return)
	//Possibly trigger an internal wound, too.
	if(type != BURN && !(status & LIMB_ROBOT))
		take_damage_internal_bleeding(damage)

	if(status & LIMB_SPLINTED && damage > 5 && prob(50 + damage * 2.5)) //If they have it splinted, the splint won't hold.
		status &= ~LIMB_SPLINTED
		to_chat(owner, SPAN_DANGER("The splint on your [display_name] comes apart!"))
		owner.update_med_icon()

	// first check whether we can widen an existing wound
	var/datum/wound/W
	if(wounds.len > 0 && prob(max(50+(number_wounds-1)*10,90)))
		if((type == CUT || type == BRUISE) && damage >= 5)
			//we need to make sure that the wound we are going to worsen is compatible with the type of damage...
			var/compatible_wounds[] = new
			for(W in wounds)
				if(W.can_worsen(type, damage)) compatible_wounds += W

			if(compatible_wounds.len)
				W = pick(compatible_wounds)
				W.open_wound(damage)
				if(type != BURN)
					add_bleeding(W)
				if(impact_name)
					W.add_impact_icon(impact_name, icon_name)
				if(prob(25))
					//maybe have a separate message for BRUISE type damage?
					owner.visible_message(SPAN_WARNING("The wound on [owner.name]'s [display_name] widens with a nasty ripping noise."),
					SPAN_WARNING("The wound on your [display_name] widens with a nasty ripping noise."),
					SPAN_WARNING("You hear a nasty ripping noise, as if flesh is being torn apart."))
				return

	//Creating wound
	var/wound_type = get_wound_type(type, damage)

	if(wound_type)
		W = new wound_type(damage)
		if(damage >= 10 && type != BURN) //Only add bleeding when its over 10 damage
			add_bleeding(W)
		W.add_impact_icon(impact_name, icon_name)

		//Check whether we can add the wound to an existing wound
		for(var/datum/wound/other in wounds)
			if(other.can_merge(W))
				other.merge_wound(W)
				W = null // to signify that the wound was added
				break
		if(W) 
			wounds += W


/datum/limb/proc/add_bleeding(var/datum/wound/W, var/internal = FALSE)
	if(!(ticker && ticker.current_state >= GAME_STATE_PLAYING)) //If the game hasnt started, don't add bleed. Hacky fix to avoid having 100 bleed effect from roundstart.
		return

	if(status & LIMB_ROBOT)
		return

	if(bleeding_effects_list.len)
		if(!internal)
			for(var/datum/effects/bleeding/external/B in bleeding_effects_list)
				B.add_on(W.damage)
				return
		else
			for(var/datum/effects/bleeding/internal/B in bleeding_effects_list)
				B.add_on(30)
				return

	var/datum/effects/bleeding/bleeding_status
	if(internal)
		bleeding_status = new /datum/effects/bleeding/internal(owner, src, 40)
	else
		bleeding_status = new /datum/effects/bleeding/external(owner, src, W.damage)
	bleeding_effects_list += bleeding_status


/datum/limb/proc/remove_all_bleeding(var/external = FALSE, var/internal = FALSE)
	if(external)
		for(var/datum/effects/bleeding/external/B in bleeding_effects_list)
			qdel(B)
	
	if(internal)
		for(var/datum/effects/bleeding/internal/I in bleeding_effects_list)
			qdel(I)


/****************************************************
			   PROCESSING & UPDATING
****************************************************/

//Determines if we even need to process this organ.

/datum/limb/proc/need_process()
	if(status & LIMB_DESTROYED)	//Missing limb is missing
		return 0
	if(status && !(status & LIMB_ROBOT) && !(status & LIMB_REPAIRED)) // Any status other than destroyed or robotic requires processing
		return 1
	if(brute_dam || burn_dam)
		return 1
	if(last_dam != brute_dam + burn_dam) // Process when we are fully healed up.
		last_dam = brute_dam + burn_dam
		return 1
	else
		last_dam = brute_dam + burn_dam
	if(knitting_time > 0)
		return 1
	return 0

/datum/limb/process()

	// Process wounds, doing healing etc. Only do this every few ticks to save processing power
	if(owner.life_tick % wound_update_accuracy == 0)
		update_wounds()

	//Chem traces slowly vanish
	if(owner.life_tick % 10 == 0)
		for(var/chemID in trace_chemicals)
			trace_chemicals[chemID] = trace_chemicals[chemID] - 1
			if(trace_chemicals[chemID] <= 0)
				trace_chemicals.Remove(chemID)

	//Bone fractures	
	if(!(status & LIMB_BROKEN))
		perma_injury = 0
	if(knitting_time > 0)
		if(world.time > knitting_time)
			to_chat(owner, SPAN_WARNING("The bones in your [display_name] feel fully knitted."))
			status &= ~LIMB_BROKEN //Let it be known that this code never unbroke the limb.
			knitting_time = -1

//Updating wounds. Handles wound natural I had some free spachealing, internal bleedings and infections
/datum/limb/proc/update_wounds()
	if((status & LIMB_ROBOT)) //Robotic limbs don't heal or get worse.
		return

	var/wound_disappeared = FALSE
	for(var/datum/wound/W in wounds)
		// we don't care about wounds after we heal them. We are not an antag simulator
		if(W.damage <= 0 && !W.internal)
			wounds -= W
			wound_disappeared = TRUE
			continue
			// let the GC handle the deletion of the wound

		// Internal wounds get worse over time. Low temperatures (cryo) stop them.
		if(W.internal)
			if(owner.bodytemperature < T0C && (owner.reagents.get_reagent_amount("cryoxadone") || owner.reagents.get_reagent_amount("clonexadone"))) // IB is healed in cryotubes
				if(W.created + MINUTES_2 <= world.time)	// sped up healing due to cryo magics
					remove_all_bleeding(FALSE, TRUE)
					wounds -= W
					wound_disappeared = TRUE
					if(istype(owner.loc, /obj/structure/machinery/atmospherics/unary/cryo_cell))	// check in case they cheesed the location
						var/obj/structure/machinery/atmospherics/unary/cryo_cell/cell = owner.loc
						cell.display_message("internal bleeding is")
			if(owner.reagents.get_reagent_amount("thwei") >= 0.05)
				remove_all_bleeding(FALSE, TRUE)

		// slow healing
		var/heal_amt = 0

		// if damage >= 50 AFTER treatment then it's probably too severe to heal within the timeframe of a round.
		if (W.can_autoheal() && owner.health >= 0 && !W.is_treated() && owner.bodytemperature > owner.species.cold_level_1)
			heal_amt += 0.3 * 0.35 //They can't autoheal if in critical
		else if (W.is_treated())
			heal_amt += 0.5 * 0.75 //Treated wounds heal faster

		if(heal_amt)
			//we only update wounds once in [wound_update_accuracy] ticks so have to emulate realtime
			heal_amt = heal_amt * wound_update_accuracy
			//configurable regen speed woo, no-regen hardcore or instaheal hugbox, choose your destiny
			heal_amt = heal_amt * config.organ_regeneration_multiplier
			// amount of healing is spread over all the wounds
			heal_amt = heal_amt / (wounds.len + 1)
			// making it look prettier on scanners
			heal_amt = round(heal_amt,0.1)
			W.heal_damage(heal_amt)

	// sync the organ's damage with its wounds
	src.update_damages()
	if (update_icon())
		owner.UpdateDamageIcon(1)
	if (wound_disappeared)
		owner.update_med_icon()

//Updates brute_damn and burn_damn from wound damages.
/datum/limb/proc/update_damages()
	number_wounds = 0
	brute_dam = 0
	burn_dam = 0

	for(var/datum/wound/W in wounds)
		if(W.damage_type == CUT || W.damage_type == BRUISE)
			brute_dam += W.damage
		else if(W.damage_type == BURN)
			burn_dam += W.damage

		number_wounds += W.amount


// new damage icon system
// adjusted to set damage_state to brute/burn code only (without r_name0 as before)
/datum/limb/proc/update_icon()
	var/n_is = damage_state_text()
	if (n_is != damage_state)
		damage_state = n_is
		return 1
	return 0

// new damage icon system
// returns just the brute/burn damage code
/datum/limb/proc/damage_state_text()
	if(status & LIMB_DESTROYED)
		return "--"

	var/tburn = 0
	var/tbrute = 0

	if(burn_dam == 0)
		tburn = 0
	else if (burn_dam < (max_damage * 0.25 / 1.5))
		tburn = 1
	else if (burn_dam < (max_damage * 0.75 / 1.5))
		tburn = 2
	else
		tburn = 3

	if (brute_dam == 0)
		tbrute = 0
	else if (brute_dam < (max_damage * 0.25 / 1.5))
		tbrute = 1
	else if (brute_dam < (max_damage * 0.75 / 1.5))
		tbrute = 2
	else
		tbrute = 3
	return "[tbrute][tburn]"

/****************************************************
			   DISMEMBERMENT
****************************************************/

//Recursive setting of all child organs to amputated
/datum/limb/proc/setAmputatedTree()
	for(var/datum/limb/O in children)
		O.status |= LIMB_AMPUTATED
		O.setAmputatedTree()

/mob/living/carbon/human/proc/remove_random_limb(var/delete_limb = 0)
	var/list/limbs_to_remove = list()
	for(var/datum/limb/E in limbs)
		if(istype(E, /datum/limb/chest) || istype(E, /datum/limb/groin) || istype(E, /datum/limb/head))
			continue
		limbs_to_remove += E
	if(limbs_to_remove.len)
		var/datum/limb/L = pick(limbs_to_remove)
		var/limb_name = L.display_name
		L.droplimb(0, delete_limb)
		return limb_name
	return null

/datum/limb/proc/start_processing()
	if(!(src in owner.limbs_to_process))
		owner.limbs_to_process += src

/datum/limb/proc/stop_processing()
	owner.limbs_to_process -= src

//Handles dismemberment
/datum/limb/proc/droplimb(amputation, var/delete_limb = 0, var/cause)
	if(status & LIMB_DESTROYED)
		return
	else
		if(body_part == UPPER_TORSO)
			return
		stop_processing()
		if(status & LIMB_ROBOT)
			status = LIMB_DESTROYED|LIMB_ROBOT
		else
			status = LIMB_DESTROYED
		if(amputation)
			status |= LIMB_AMPUTATED
		for(var/i in implants)
			implants -= i
			if(is_sharp(i) || istype(i, /obj/item/shard/shrapnel))
				owner.embedded_items -= i
			qdel(i)

		if(hidden)
			hidden.forceMove(owner.loc)
			hidden = null

		// If any organs are attached to this, destroy them
		for(var/datum/limb/O in children) 
			O.droplimb(amputation, delete_limb, cause)

		//Replace all wounds on that arm with one wound on parent organ.
		wounds.Cut()
		if(parent && !amputation)
			var/datum/wound/W
			if(max_damage < 50) W = new/datum/wound/lost_limb/small(max_damage)
			else 				W = new/datum/wound/lost_limb(max_damage)

			parent.wounds += W
			parent.update_damages()
		update_damages()

		//we reset the surgery related variables
		reset_limb_surgeries()

		var/obj/organ	//Dropped limb object
		switch(body_part)
			if(HEAD)
				if(owner.species.flags & IS_SYNTHETIC) //special head for synth to allow brainmob to talk without an MMI
					organ= new /obj/item/limb/head/synth(owner.loc, owner)
				else
					organ= new /obj/item/limb/head(owner.loc, owner)
				owner.drop_inv_item_on_ground(owner.glasses, null, TRUE)
				owner.drop_inv_item_on_ground(owner.head, null, TRUE)
				owner.drop_inv_item_on_ground(owner.wear_ear, null, TRUE)
				owner.drop_inv_item_on_ground(owner.wear_mask, null, TRUE)
				owner.update_hair()
			if(ARM_RIGHT)
				if(status & LIMB_ROBOT) 	
					organ = new /obj/item/robot_parts/r_arm(owner.loc)
				else 						
					organ = new /obj/item/limb/arm/r_arm(owner.loc, owner)
				if(owner.w_uniform && !amputation)
					var/obj/item/clothing/under/U = owner.w_uniform
					U.removed_parts |= body_part
					owner.update_inv_w_uniform()
			if(ARM_LEFT)
				if(status & LIMB_ROBOT) 	
					organ = new /obj/item/robot_parts/l_arm(owner.loc)
				else 						
					organ = new /obj/item/limb/arm/l_arm(owner.loc, owner)
				if(owner.w_uniform && !amputation)
					var/obj/item/clothing/under/U = owner.w_uniform
					U.removed_parts |= body_part
					owner.update_inv_w_uniform()
			if(LEG_RIGHT)
				if(status & LIMB_ROBOT) 	
					organ = new /obj/item/robot_parts/r_leg(owner.loc)
				else 						
					organ = new /obj/item/limb/leg/r_leg(owner.loc, owner)
				if(owner.w_uniform && !amputation)
					var/obj/item/clothing/under/U = owner.w_uniform
					U.removed_parts |= body_part
					owner.update_inv_w_uniform()
			if(LEG_LEFT)
				if(status & LIMB_ROBOT) 	
					organ = new /obj/item/robot_parts/l_leg(owner.loc)
				else 						
					organ = new /obj/item/limb/leg/l_leg(owner.loc, owner)
				if(owner.w_uniform && !amputation)
					var/obj/item/clothing/under/U = owner.w_uniform
					U.removed_parts |= body_part
					owner.update_inv_w_uniform()
			if(HAND_RIGHT)
				if(!(status & LIMB_ROBOT)) 
					organ= new /obj/item/limb/hand/r_hand(owner.loc, owner)
				owner.drop_inv_item_on_ground(owner.gloves, null, TRUE)
				owner.drop_inv_item_on_ground(owner.r_hand, null, TRUE)
			if(HAND_LEFT)
				if(!(status & LIMB_ROBOT)) 
					organ= new /obj/item/limb/hand/l_hand(owner.loc, owner)
				owner.drop_inv_item_on_ground(owner.gloves, null, TRUE)
				owner.drop_inv_item_on_ground(owner.l_hand, null, TRUE)
			if(FOOT_RIGHT)
				if(!(status & LIMB_ROBOT)) 
					organ= new /obj/item/limb/foot/r_foot/(owner.loc, owner)
				owner.drop_inv_item_on_ground(owner.shoes, null, TRUE)
			if(FOOT_LEFT)
				if(!(status & LIMB_ROBOT)) 
					organ = new /obj/item/limb/foot/l_foot(owner.loc, owner)
				owner.drop_inv_item_on_ground(owner.shoes, null, TRUE)

		if(delete_limb)
			qdel(organ)
		else
			owner.visible_message(SPAN_WARNING("[owner.name]'s [display_name] flies off in an arc!"),
			SPAN_HIGHDANGER("<b>Your [display_name] goes flying off!</b>"),
			SPAN_WARNING("You hear a terrible sound of ripping tendons and flesh!"), 3)

			if(organ)
				//Throw organs around
				var/lol = pick(cardinal)
				step(organ,lol)

		owner.update_body(1, 1)
		owner.UpdateDamageIcon(1)

		// OK so maybe your limb just flew off, but if it was attached to a pair of cuffs then hooray! Freedom!
		release_restraints()

		if(vital) owner.death(cause)

/****************************************************
			   HELPERS
****************************************************/

/datum/limb/proc/release_restraints()
	if (owner.handcuffed && body_part in list(ARM_LEFT, ARM_RIGHT, HAND_LEFT, HAND_RIGHT))
		owner.visible_message(\
			"\The [owner.handcuffed.name] falls off of [owner.name].",\
			"\The [owner.handcuffed.name] falls off you.")

		owner.drop_inv_item_on_ground(owner.handcuffed)

	if (owner.legcuffed && body_part in list(FOOT_LEFT, FOOT_RIGHT, LEG_LEFT, LEG_RIGHT))
		owner.visible_message(\
			"\The [owner.legcuffed.name] falls off of [owner.name].",\
			"\The [owner.legcuffed.name] falls off you.")

		owner.drop_inv_item_on_ground(owner.legcuffed)

/datum/limb/proc/bandage()
	var/rval = 0
	remove_all_bleeding(TRUE)
	for(var/datum/wound/W in wounds)
		if(W.internal) continue
		rval |= !W.bandaged
		W.bandaged = 1
	owner.update_med_icon()
	return rval

/datum/limb/proc/is_bandaged()
	if(!(surgery_open_stage == 0))
		return 1
	var/rval = 0
	for(var/datum/wound/W in wounds)
		if(W.internal) continue
		rval |= !W.bandaged
	return rval

/datum/limb/proc/clamp()
	var/rval = 0
	remove_all_bleeding(TRUE)
	for(var/datum/wound/W in wounds)
		if(W.internal) continue
		rval |= !W.clamped
		W.clamped = 1
	return rval

/datum/limb/proc/salve()
	var/rval = 0
	for(var/datum/wound/W in wounds)
		rval |= !W.salved
		W.salved = 1
	return rval

/datum/limb/proc/is_salved()
	if(!(surgery_open_stage == 0))
		return 1
	var/rval = 1
	for(var/datum/wound/W in wounds)
		rval |= !W.salved
	return rval

/datum/limb/proc/fracture()

	if(status & (LIMB_BROKEN|LIMB_DESTROYED|LIMB_ROBOT) )
		if (knitting_time != -1)
			knitting_time = -1
			to_chat(owner, SPAN_WARNING("You feel your [src] stop knitting together as it absorbs damage!"))
		return

	owner.visible_message(\
		SPAN_WARNING("You hear a loud cracking sound coming from [owner]!"),
		SPAN_HIGHDANGER("Something feels like it shattered in your [display_name]!"),
		"<span class='warning'>You hear a sickening crack!<span>")
	var/F = pick('sound/effects/bone_break1.ogg','sound/effects/bone_break2.ogg','sound/effects/bone_break3.ogg','sound/effects/bone_break4.ogg','sound/effects/bone_break5.ogg','sound/effects/bone_break6.ogg','sound/effects/bone_break7.ogg')
	playsound(owner,F, 45, 1)
	if(owner.species && !(owner.species.flags & NO_PAIN))
		owner.emote("scream")

	start_processing()

	status |= LIMB_BROKEN
	status &= ~LIMB_REPAIRED
	broken_description = pick("broken","fracture","hairline fracture")
	perma_injury = brute_dam

	// Fractures have a chance of getting you out of restraints
	if (prob(25))
		release_restraints()

	// This is mostly for the ninja suit to stop ninja being so crippled by breaks.
	// TODO: consider moving this to a suit proc or process() or something during
	// hardsuit rewrite.
	if(!(status & LIMB_SPLINTED) && istype(owner,/mob/living/carbon/human))

		var/mob/living/carbon/human/H = owner

		if(H.wear_suit && istype(H.wear_suit,/obj/item/clothing/suit/space))

			var/obj/item/clothing/suit/space/suit = H.wear_suit

			if(isnull(suit.supporting_limbs))
				return

			to_chat(owner, "You feel [suit] constrict about your [display_name], supporting it.")
			status |= LIMB_SPLINTED
			suit.supporting_limbs |= src
	return

/datum/limb/proc/robotize()
	status &= ~LIMB_BROKEN
	status &= ~LIMB_SPLINTED
	status &= ~LIMB_AMPUTATED
	status &= ~LIMB_DESTROYED
	status &= ~LIMB_MUTATED
	status &= ~LIMB_REPAIRED
	status |= LIMB_ROBOT
	stop_processing()
	reset_limb_surgeries()

	perma_injury = 0
	for (var/datum/limb/T in children)
		if(T)
			T.robotize()

/datum/limb/proc/mutate()
	src.status |= LIMB_MUTATED
	owner.update_body()

/datum/limb/proc/unmutate()
	src.status &= ~LIMB_MUTATED
	owner.update_body()

/datum/limb/proc/get_damage()	//returns total damage
	return max(brute_dam + burn_dam - perma_injury, perma_injury)	//could use health?

/datum/limb/proc/get_icon(var/icon/race_icon, var/icon/deform_icon,gender="")

	if (status & LIMB_ROBOT && !(owner.species && owner.species.flags & IS_SYNTHETIC))
		return new /icon('icons/mob/robotic.dmi', "[icon_name][gender ? "_[gender]" : ""]")

	if (status & LIMB_MUTATED)
		return new /icon(deform_icon, "[icon_name][gender ? "_[gender]" : ""]")

	var/datum/ethnicity/E = ethnicities_list[owner.ethnicity]
	var/datum/body_type/B = body_types_list[owner.body_type]

	var/e_icon
	var/b_icon

	if (!E)
		e_icon = "western"
	else
		e_icon = E.icon_name

	if (!B)
		b_icon = "mesomorphic"
	else
		b_icon = B.icon_name

	return new /icon(race_icon, "[get_limb_icon_name(owner.species, b_icon, owner.gender, icon_name, e_icon)]")

	//return new /icon(race_icon, "[icon_name][gender ? "_[gender]" : ""]")


/datum/limb/proc/is_usable()
	return !(status & (LIMB_DESTROYED|LIMB_MUTATED))

/datum/limb/proc/is_broken()
	return ((status & LIMB_BROKEN) && !(status & LIMB_SPLINTED))

/datum/limb/proc/is_malfunctioning()
	return ((status & LIMB_ROBOT) && prob(brute_dam + burn_dam))

//for arms and hands
/datum/limb/proc/process_grasp(var/obj/item/c_hand, var/hand_name)
	if (!c_hand)
		return

	if(is_broken())
		if(prob(15))
			owner.drop_inv_item_on_ground(c_hand)
			var/emote_scream = pick("screams in pain and", "lets out a sharp cry and", "cries out and")
			owner.emote("me", 1, "[(owner.species && owner.species.flags & NO_PAIN) ? "" : emote_scream ] drops what they were holding in their [hand_name]!")
	if(is_malfunctioning())
		if(prob(10))
			owner.drop_inv_item_on_ground(c_hand)
			owner.emote("me", 1, "drops what they were holding, their [hand_name] malfunctioning!")
			var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
			spark_system.set_up(5, 0, owner)
			spark_system.attach(owner)
			spark_system.start()
			spawn(10)
				qdel(spark_system)
				spark_system = null

/datum/limb/proc/embed(var/obj/item/W, var/silent = 0)
	if(!W || W.disposed || (W.flags_item & (NODROP|DELONDROP)) || W.embeddable == FALSE)
		return
	if(!silent)
		owner.visible_message(SPAN_DANGER("\The [W] sticks in the wound!"))
	implants += W
	start_processing()
	
	if(is_sharp(W) || istype(W, /obj/item/shard/shrapnel))
		W.embedded_organ = src		
		owner.embedded_items += W
		if(is_sharp(W)) // Only add the verb if its not a shrapnel
			owner.verbs += /mob/proc/yank_out_object
	W.add_mob_blood(owner)

	if(ismob(W.loc))
		var/mob/living/H = W.loc
		H.drop_held_item()
	if(W)
		W.forceMove(owner)

/datum/limb/proc/apply_splints(obj/item/stack/medical/splint/S, mob/living/user, mob/living/carbon/human/target)
	if(!(status & LIMB_DESTROYED) && !(status & LIMB_SPLINTED))
		if (target != user)
			if(do_after(user, 50, INTERRUPT_NO_NEEDHAND, BUSY_ICON_FRIENDLY, target, INTERRUPT_MOVED, BUSY_ICON_MEDICAL))
				var/possessive = "[user == target ? "your" : "[target]'s"]"
				var/possessive_their = "[user == target ? "their" : "[target]'s"]"
				user.affected_message(target,
					SPAN_HELPFUL("You finish applying <b>[S]</b> to [possessive] [display_name]."),
					SPAN_HELPFUL("[user] finishes applying <b>[S]</b> to your [display_name]."),
					SPAN_NOTICE("[user] finish applying [S] to [possessive_their] [display_name]."))
				status |= LIMB_SPLINTED
				. = 1
		else
			user.visible_message(SPAN_WARNING("[user] fumbles with the [S]"), SPAN_WARNING("You fumble with the [S]..."))
			if(do_after(user, 150, INTERRUPT_NO_NEEDHAND, BUSY_ICON_FRIENDLY, target, INTERRUPT_MOVED, BUSY_ICON_MEDICAL))
				user.visible_message(
				SPAN_WARNING("[user] successfully applies [S] to their [display_name]."),
				SPAN_NOTICE("You successfully apply [S] to your [display_name]."))
				status |= LIMB_SPLINTED
				. = 1
				owner.update_med_icon()

//called when limb is removed or robotized, any ongoing surgery and related vars are reset
/datum/limb/proc/reset_limb_surgeries()
	surgery_open_stage = 0
	bone_repair_stage = 0
	limb_replacement_stage = 0
	surgery_organ = null
	cavity = 0




/****************************************************
			   LIMB TYPES
****************************************************/

/datum/limb/chest
	name = "chest"
	icon_name = "torso"
	display_name = "chest"
	max_damage = 200
	min_broken_damage = 30
	body_part = UPPER_TORSO
	vital = 1
	encased = "ribcage"
	splint_icon_amount = 4
	bandage_icon_amount = 4

/datum/limb/groin
	name = "groin"
	icon_name = "groin"
	display_name = "groin"
	max_damage = 200
	min_broken_damage = 30
	body_part = LOWER_TORSO
	vital = 1
	splint_icon_amount = 1
	bandage_icon_amount = 2

/datum/limb/leg
	name = "leg"
	display_name = "leg"
	max_damage = 35
	min_broken_damage = 20

/datum/limb/foot
	name = "foot"
	display_name = "foot"
	max_damage = 30
	min_broken_damage = 20

/datum/limb/arm
	name = "arm"
	display_name = "arm"
	max_damage = 35
	min_broken_damage = 20

/datum/limb/hand
	name = "hand"
	display_name = "hand"
	max_damage = 30
	min_broken_damage = 20

/datum/limb/arm/l_arm
	name = "l_arm"
	display_name = "left arm"
	icon_name = "l_arm"
	body_part = ARM_LEFT
	has_stump_icon = TRUE

	process()
		..()
		process_grasp(owner.l_hand, "left hand")

/datum/limb/leg/l_leg
	name = "l_leg"
	display_name = "left leg"
	icon_name = "l_leg"
	body_part = LEG_LEFT
	icon_position = LEFT
	has_stump_icon = TRUE

/datum/limb/arm/r_arm
	name = "r_arm"
	display_name = "right arm"
	icon_name = "r_arm"
	body_part = ARM_RIGHT
	has_stump_icon = TRUE

	process()
		..()
		process_grasp(owner.r_hand, "right hand")

/datum/limb/leg/r_leg
	name = "r_leg"
	display_name = "right leg"
	icon_name = "r_leg"
	body_part = LEG_RIGHT
	icon_position = RIGHT
	has_stump_icon = TRUE

/datum/limb/foot/l_foot
	name = "l_foot"
	display_name = "left foot"
	icon_name = "l_foot"
	body_part = FOOT_LEFT
	icon_position = LEFT
	has_stump_icon = TRUE

/datum/limb/foot/r_foot
	name = "r_foot"
	display_name = "right foot"
	icon_name = "r_foot"
	body_part = FOOT_RIGHT
	icon_position = RIGHT
	has_stump_icon = TRUE

/datum/limb/hand/r_hand
	name = "r_hand"
	display_name = "right hand"
	icon_name = "r_hand"
	body_part = HAND_RIGHT
	has_stump_icon = TRUE

	process()
		..()
		process_grasp(owner.r_hand, "right hand")

/datum/limb/hand/l_hand
	name = "l_hand"
	display_name = "left hand"
	icon_name = "l_hand"
	body_part = HAND_LEFT
	has_stump_icon = TRUE

	process()
		..()
		process_grasp(owner.l_hand, "left hand")

/datum/limb/head
	name = "head"
	icon_name = "head"
	display_name = "head"
	max_damage = 60
	min_broken_damage = 30
	body_part = HEAD
	vital = 1
	encased = "skull"
	has_stump_icon = TRUE
	splint_icon_amount = 4
	bandage_icon_amount = 4
	var/disfigured = 0 //whether the head is disfigured.
	var/face_surgery_stage = 0

/datum/limb/head/take_damage(brute, burn, sharp, edge, used_weapon = null, list/forbidden_limbs = list(), no_limb_loss, impact_name = null)
	. = ..()
	if (!disfigured)
		if (brute_dam > 50 || brute_dam > 40 && prob(50))
			disfigure("brute")
		if (burn_dam > 40)
			disfigure("burn")

/datum/limb/head/proc/disfigure(var/type = "brute")
	if (disfigured)
		return
	if(type == "brute")
		owner.visible_message(SPAN_DANGER("You hear a sickening cracking sound coming from \the [owner]'s face."),	\
		SPAN_DANGER("<b>Your face becomes unrecognizible mangled mess!</b>"),	\
		SPAN_DANGER("You hear a sickening crack."))
	else
		owner.visible_message(SPAN_DANGER("[owner]'s face melts away, turning into mangled mess!"),	\
		SPAN_DANGER("<b>Your face melts off!</b>"),	\
		SPAN_DANGER("You hear a sickening sizzle."))
	disfigured = 1
	owner.name = owner.get_visible_name()

/datum/limb/head/reset_limb_surgeries()
	..()
	face_surgery_stage = 0
