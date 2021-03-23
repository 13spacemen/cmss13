/datum/tech/xeno/structures
	name = "Defensive Structures"
	desc = "Unlock defensive structures to use to defend the hive with."

	flags = TREE_FLAG_XENO

	required_points = 15
	tier = /datum/tier/one
	var/list/constructions_to_add = list(
		/datum/resin_construction/resin_turf/wall/reflective,
		/datum/resin_construction/resin_obj/resin_spike,
		/datum/resin_construction/resin_obj/acid_pillar
	)

/datum/tech/xeno/structures/ui_static_data(mob/user)
	. = ..()
	var/list/structures = list()

	for(var/i in constructions_to_add)
		var/datum/resin_construction/RC = i
		structures += list(list(
			"content" = "Construct: [initial(RC.name)]",
			"color" = "green",
			"tooltip" = initial(RC.desc),
			"icon" = "plus"
		))

	.["stats"] += structures


/datum/tech/xeno/structures/on_unlock(datum/techtree/tree)
	. = ..()

	for(var/i in constructions_to_add)
		GLOB.resin_build_order_drone += i
		GLOB.resin_build_order_hivelord += i
