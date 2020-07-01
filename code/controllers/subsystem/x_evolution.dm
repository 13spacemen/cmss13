var/datum/subsystem/xevolution/SSxevolution

#define BOOST_POWER_MAX 20
#define BOOST_POWER_MIN 1
#define EVOLUTION_INCREMENT_TIME MINUTES_30 // Evolution increases by 1 every 25 minutes.

/datum/subsystem/xevolution
	name = "Evilution"
	wait = 1 MINUTES
	priority = SS_PRIORITY_INACTIVITY
	
	var/human_xeno_ratio_modifier = 0.4
	var/time_ratio_modifier = 0.4

	var/list/boost_power = list()
	var/force_boost_power = FALSE // Debugging only

/datum/subsystem/xevolution/New()
	for(var/datum/hive_status/HS in hive_datum)
		boost_power += HS.hivenumber
		boost_power[HS.hivenumber] = 1
	NEW_SS_GLOBAL(SSxevolution)

/datum/subsystem/xevolution/fire(resumed = FALSE)
	for(var/datum/hive_status/HS in hive_datum)
		if(!HS)
			continue

		var/boost_power_new
		// Minimum of 5 evo until 10 minutes have passed.
		if((world.time - ticker.game_start_time) < XENO_ROUNDSTART_PROGRESS_TIME_2)
			boost_power_new = max(boost_power_new, XENO_ROUNDSTART_PROGRESS_AMOUNT) 
		else
			boost_power_new = Floor(10 * (world.time - XENO_ROUNDSTART_PROGRESS_TIME_2 - ticker.game_start_time) / EVOLUTION_INCREMENT_TIME) / 10

			//Add on any bonuses from evopods after applying upgrade progress
			boost_power_new += (0.2 * HS.has_special_structure(XENO_STRUCTURE_EVOPOD))

		boost_power_new = Clamp(boost_power_new, BOOST_POWER_MIN, BOOST_POWER_MAX)

		if(!force_boost_power)
			boost_power[HS.hivenumber] = boost_power_new

		//Update displayed Evilution, which is under larva apparently
		HS.hive_ui.update_pooled_larva()

/datum/subsystem/xevolution/proc/get_evolution_boost_power(var/hivenumber)
	return boost_power[hivenumber]

#undef EVOLUTION_INCREMENT_TIME
#undef BOOST_POWER_MIN
#undef BOOST_POWER_MAX