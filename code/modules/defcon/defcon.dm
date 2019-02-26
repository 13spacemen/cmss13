//A class that holds the current DEFCON level and its associated uses

#define DEFCON_COST_CHEAP 2
#define DEFCON_COST_MODERATE 3
#define DEFCON_COST_EXPENSIVE 6

#define DEFCON_POINT_GAIN_PER_LEVEL 2

var/global/datum/defcon/defcon_controller = new

/datum/defcon
	var/current_defcon_level = 5 //IRL DEFCON goes from 5 to 1, so we preserve it here
	var/last_objectives_scored_points = 0
	var/last_objectives_total_points = 0
	var/last_objectives_completion_percentage = 0

	//Percentage of objectives needed to reach the next DEFCON level
	//(ordered by DEFCON number, so things will be going in the opposite order!)
	var/list/defcon_level_triggers = list(0.5, 0.3, 0.2, 0.1, 0.0)

	var/list/purchased_rewards = list()

	//Points given for reaching the next DEFCON level, for Command to spend
	//Starts with a few points to enable a bit of fun
	var/remaining_reward_points = DEFCON_POINT_GAIN_PER_LEVEL

/datum/defcon/proc/check_defcon_level()
	var/list/objectives_status = objectives_controller.get_objective_completion_stats()

	last_objectives_scored_points = objectives_status["scored_points"]
	last_objectives_total_points = objectives_status["total_points"]
	last_objectives_completion_percentage = last_objectives_scored_points / last_objectives_total_points

	if(current_defcon_level > 1)
		if(last_objectives_completion_percentage > defcon_level_triggers[current_defcon_level - 1])
			current_defcon_level--
			remaining_reward_points += DEFCON_POINT_GAIN_PER_LEVEL
			announce_defcon_level()

	round_statistics.defcon_level = current_defcon_level
	round_statistics.objective_points = last_objectives_scored_points
	round_statistics.total_objective_points = last_objectives_total_points

/datum/defcon/proc/announce_defcon_level()
	//Send ARES message about new DEFCON level
	var/name = "ALMAYER DEFCON LEVEL LOWERED"
	var/input = "THREAT ASSESSMENT LEVEL INCREASED TO [last_objectives_completion_percentage*100]%.\n\nShip DEFCON level lowered to [current_defcon_level]. Additional assets have been authorised to handle the situation."
	command_announcement.Announce(input, name, new_sound = 'sound/AI/commandreport.ogg')

/datum/defcon/proc/list_and_purchase_rewards()
	var/list/rewards_for_purchase = available_rewards()
	if(rewards_for_purchase.len == 0)
		usr << "No additional assets have been authorised at this point. Increase the threat assessment level to enable further assets."
	var/pick = input("Which asset would you like to enable?") as null|anything in rewards_for_purchase
	if(!pick)
		return
	if(defcon_reward_list[pick].apply_reward(src))
		usr << "Asset granted!"
		defcon_reward_list[pick].announce_reward()
	else
		usr << "Asset granting failed!"
	return


//Lists rewards available for purchase
/datum/defcon/proc/available_rewards()
	var/list/can_purchase = list()
	if(!remaining_reward_points) //No points - can't buy anything
		return can_purchase

	for(var/str in defcon_reward_list)
		if (can_purchase_reward(str))
			can_purchase += str //can purchase!

	return can_purchase

/datum/defcon/proc/can_purchase_reward(var/reward_name)
	var/datum/defcon_reward/dr = defcon_reward_list[reward_name]
	if(current_defcon_level > dr.minimum_defcon_level)
		return FALSE //required DEFCON level not reached
	if(remaining_reward_points < dr.cost)
		return FALSE //reward is too expensive
	if(dr.unique)
		if(dr.name in purchased_rewards)
			return FALSE //unique reward already purchased
	return TRUE




//A class for rewarding the next DEFCON level being reached
/datum/defcon_reward
	var/name = "Reward"
	var/cost = DEFCON_COST_EXPENSIVE //Cost to get this reward
	var/minimum_defcon_level = 5 //DEFCON needs to be at this level or LOWER
	var/unique = FALSE //Whether the reward is unique or not
	var/announcement_message = "YOU SHOULD NOT BE SEEING THIS MESSAGE. TELL A DEV." //Message to be shared after a reward is purchased

/datum/defcon_reward/proc/announce_reward()
	//Send ARES message about special asset authorisation
	var/name = "ALMAYER SPECIAL ASSETS AUTHORISED"
	command_announcement.Announce(announcement_message, name, new_sound = 'sound/misc/notice2.ogg')

/datum/defcon_reward/New()
	. = ..()
	name = "([cost] points) [name]"

/datum/defcon_reward/proc/apply_reward(var/datum/defcon/d)
	if(d.remaining_reward_points < cost)
		return 0
	d.remaining_reward_points -= cost
	d.purchased_rewards += name
	return 1

/datum/defcon_reward/supply_points
	name = "Additional Supply Points"
	cost = DEFCON_COST_CHEAP
	minimum_defcon_level = 5
	announcement_message = "Additional Supply Points have been authorised for this operation."

/datum/defcon_reward/supply_points/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return
	supply_controller.points += 200

/datum/defcon_reward/dropship_part_fabricator_points
	name = "Additional Dropship Part Fabricator Points"
	cost = DEFCON_COST_CHEAP
	minimum_defcon_level = 5
	announcement_message = "Additional Dropship Part Fabricator Points have been authorised for this operation."

/datum/defcon_reward/dropship_part_fabricator_points/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return
	supply_controller.dropship_points += 1600 //Enough for both fuel enhancers, or about 3.5 fatties

/datum/defcon_reward/cryo_squad
	name = "Wake up additional troops"
	cost = DEFCON_COST_MODERATE
	minimum_defcon_level = 4
	unique = TRUE
	announcement_message = "Additional troops are being taken out of cryo."

/datum/defcon_reward/cryo_squad/apply_reward(var/datum/defcon/d)
	if (!ticker  || !ticker.mode)
		return

	. = ..()
	if(. == 0)
		return

	ticker.mode.get_specific_call("Marine Cryo Reinforcements (Squad)", FALSE, FALSE)

/datum/defcon_reward/emergency_squad
	name = "Emergency troop reinforcements"
	cost = DEFCON_COST_EXPENSIVE
	minimum_defcon_level = 3
	unique = TRUE
	announcement_message = "Emergency troop reinforcements are being taken out of cryo."

/datum/defcon_reward/emergency_squad/apply_reward(var/datum/defcon/d)
	if (!ticker  || !ticker.mode)
		return

	. = ..()
	if(. == 0)
		return

	ticker.mode.get_specific_call("Marine Reinforcements (Squad) (Cryo)", FALSE, FALSE)

/datum/defcon_reward/tank_points
	name = "Additional Tank Part Fabricator Points"
	cost = DEFCON_COST_EXPENSIVE
	minimum_defcon_level = 2
	unique = TRUE
	announcement_message = "Additional Tank Part Fabricator Points have been authorised for this operation."

/datum/defcon_reward/tank_points/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return
	supply_controller.tank_points += 3000 //Enough for full kit + ammo

/datum/defcon_reward/ob_he
	name = "Additional OB projectiles - HE x2"
	cost = DEFCON_COST_CHEAP
	minimum_defcon_level = 5
	unique = FALSE
	announcement_message = "Additional Orbital Bombardment ornaments (HE, count:2) have been delivered to Requisitions' ASRS."

/datum/defcon_reward/ob_he/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return

	var/datum/supply_order/O = new /datum/supply_order()
	O.ordernum = supply_controller.ordernum
	supply_controller.ordernum++
	O.object = supply_controller.supply_packs["OB HE Crate"]
	O.orderedby = MAIN_AI_SYSTEM

	supply_controller.shoppinglist += O

/datum/defcon_reward/ob_cluster
	name = "Additional OB projectiles - Cluster x2"
	cost = DEFCON_COST_CHEAP
	minimum_defcon_level = 5
	unique = FALSE
	announcement_message = "Additional Orbital Bombardment ornaments (Cluster, count:2) have been delivered to Requisitions' ASRS."

/datum/defcon_reward/ob_cluster/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return

	var/datum/supply_order/O = new /datum/supply_order()
	O.ordernum = supply_controller.ordernum
	supply_controller.ordernum++
	O.object = supply_controller.supply_packs["OB Cluster Crate"]
	O.orderedby = MAIN_AI_SYSTEM

	supply_controller.shoppinglist += O

/datum/defcon_reward/ob_incendiary
	name = "Additional OB projectiles - Incendiary x2"
	cost = DEFCON_COST_CHEAP
	minimum_defcon_level = 5
	unique = FALSE
	announcement_message = "Additional Orbital Bombardment ornaments (Incendiary, count:2) have been delivered to Requisitions' ASRS."

/datum/defcon_reward/ob_incendiary/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return

	var/datum/supply_order/O = new /datum/supply_order()
	O.ordernum = supply_controller.ordernum
	supply_controller.ordernum++
	O.object = supply_controller.supply_packs["OB Incendiary Crate"]
	O.orderedby = MAIN_AI_SYSTEM

	supply_controller.shoppinglist += O

/datum/defcon_reward/nuke
	name = "Planetary nuke"
	cost = DEFCON_COST_CHEAP
	minimum_defcon_level = 1
	unique = TRUE
	announcement_message = "Planetary nuke has been been delivered to Requisitions' ASRS."

/datum/defcon_reward/nuke/apply_reward(var/datum/defcon/d)
	. = ..()
	if(. == 0)
		return

	var/datum/supply_order/O = new /datum/supply_order()
	O.ordernum = supply_controller.ordernum
	supply_controller.ordernum++
	O.object = /obj/machinery/nuclearbomb
	O.orderedby = MAIN_AI_SYSTEM

	supply_controller.shoppinglist += O

/datum/defcon_reward/nuke/announce_reward(var/announcement_message)
	//Send ARES message about special asset authorisation
	var/name = "STRATEGIC NUKE AUTHORISED"
	command_announcement.Announce(announcement_message, name, new_sound = 'sound/misc/notice1.ogg')