/obj/item/weapon/claymore
	name = "claymore"
	desc = "What are you standing around staring at this for? Get to killing!"
	icon_state = "claymore"
	item_state = "claymore"
	flags_atom = FPRINT|CONDUCT
	flags_equip_slot = SLOT_WAIST
	force = 40
	throwforce = 10
	sharp = IS_SHARP_ITEM_BIG
	edge = 1
	w_class = SIZE_MEDIUM
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")

/obj/item/weapon/claymore/mercsword
	name = "combat sword"
	desc = "A dusty sword commonly seen in historical museums. Where you got this is a mystery, for sure. Only a mercenary would be nuts enough to carry one of these. Sharpened to deal massive damage."
	icon_state = "mercsword"
	item_state = "machete"
	force = 39


/obj/item/weapon/claymore/mercsword/commander
	name = "Ceremonial Sword"
	desc = "A fancy ceremonial sword passed down from generation to generation. Despite this, it has been very well cared for, and is in top condition. Has the name 'Chang' printed along the blade."
	icon_state = "mercsword"
	item_state = "machete"
	force = 65

/obj/item/weapon/claymore/mercsword/machete
	name = "\improper M2132 machete"
	desc = "Latest issue of the USCM Machete. Great for clearing out jungle or brush on outlying colonies. Found commonly in the hands of scouts and trackers, but difficult to carry with the usual kit."
	icon_state = "machete"
	force = 35
	w_class = SIZE_LARGE

/obj/item/weapon/katana
	name = "katana"
	desc = "A finely made Japanese sword, with a well sharpened blade. The blade has been filed to a molecular edge, and is extremely deadly. Commonly found in the hands of mercenaries and yakuza."
	icon_state = "katana"
	flags_atom = FPRINT|CONDUCT
	force = 50
	throwforce = 10
	sharp = IS_SHARP_ITEM_BIG
	edge = 1
	w_class = SIZE_MEDIUM
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")

//To do: replace the toys.
/obj/item/weapon/katana/replica
	name = "replica katana"
	desc = "A cheap knock-off commonly found in regular knife stores. Can still do some damage."
	force = 27
	throwforce = 7

/obj/item/weapon/combat_knife
	name = "\improper M5 'Night Raider' survival knife"
	icon = 'icons/obj/items/weapons/weapons.dmi'
	icon_state = "combat_knife"
	item_state = "combat_knife"
	desc = "The standard issue survival knife issued to Colonial Marines soldiers. You can slide this knife into your boots, and can be field-modified to attach to the end of a rifle."
	flags_atom = FPRINT|CONDUCT
	sharp = IS_SHARP_ITEM_ACCURATE
	force = 25
	w_class = SIZE_SMALL
	throwforce = 20
	throw_speed = 3
	throw_range = 6
	hitsound = 'sound/weapons/slash.ogg'
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	flags_equip_slot = SLOT_FACE
	flags_armor_protection = SLOT_FACE

/obj/item/weapon/combat_knife/attack(mob/living/target as mob, mob/living/carbon/human/user as mob)
	if(user.mind.cm_skills.medical >= SKILL_MEDICAL_MEDIC && ishuman(user) && user.a_intent == "help") //Squad medics and above
		dig_out_shrapnel(target, user)
	else
		..()

/obj/item/weapon/combat_knife/attackby(obj/item/I as obj, mob/user as mob)
	if(istype(I,/obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/CC = I
		if (CC.use(5))
			to_chat(user, "You wrap some cable around the bayonet. It can now be attached to a gun.")
			if(istype(loc, /obj/item/storage))
				var/obj/item/storage/S = loc
				S.remove_from_storage(src)
			if(loc == user)
				user.temp_drop_inv_item(src)
			var/obj/item/attachable/bayonet/F = new(src.loc)
			user.put_in_hands(F) //This proc tries right, left, then drops it all-in-one.
			if(F.loc != user) //It ended up on the floor, put it whereever the old flashlight is.
				F.loc = get_turf(src)
			qdel(src) //Delete da old knife
		else
			to_chat(user, SPAN_NOTICE("You don't have enough cable for that."))
			return
	else
		..()

/obj/item/weapon/combat_knife/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user)) 
		return
	if(!hasorgans(user)) 
		return

	dig_out_shrapnel(user)


/obj/item/weapon/combat_knife/upp
	name = "\improper Type 30 survival knife"
	icon_state = "upp_knife"
	item_state = "knife"
	desc = "The standard issue survival knife of the UPP forces, the Type 30 is effective, but humble. It is small enough to be non-cumbersome, but lethal none-the-less."
	force = 20
	throwforce = 10
	throw_speed = 2
	throw_range = 8


/obj/item/weapon/throwing_knife
	name ="\improper M11 throwing knife"
	icon='icons/obj/items/weapons/weapons.dmi'
	icon_state = "throwing_knife"
	item_state = "combat_knife"
	desc="A military knife designed to be thrown at the enemy. Much quieter than a firearm, but requires a steady hand to be used effectively."
	flags_atom = FPRINT|CONDUCT
	sharp = IS_SHARP_ITEM_ACCURATE
	force = 10
	w_class = SIZE_TINY
	throwforce = 35
	throw_speed = 4
	throw_range = 7
	hitsound = 'sound/weapons/slash.ogg'
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	flags_equip_slot = SLOT_STORE|SLOT_FACE
	flags_armor_protection = SLOT_FACE


/obj/item/weapon/unathiknife
	name = "duelling knife"
	desc = "A length of leather-bound wood studded with razor-sharp teeth. How crude."
	icon = 'icons/obj/items/weapons/weapons.dmi'
	icon_state = "unathiknife"
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("ripped", "torn", "cut")


/obj/item/weapon/pizza_cutter
	name = "\improper PIZZA TIME"
	icon = 'icons/obj/items/weapons/weapons.dmi'
	icon_state = "pizza_cutter"
	item_state = "pizza_cutter"
	desc = "Before you is holy relic of a bygone era when the great Pizza Lords reigned supreme. You know either that or it's just a big damn pizza cutter."
	sharp = IS_SHARP_ITEM_ACCURATE
	force = 50
	edge = 1


/obj/item/weapon/yautja_knife
	name = "ceremonial dagger"
	desc = "A viciously sharp dagger enscribed with ancient Yautja markings. Smells thickly of blood. Carried by some hunters."
	icon = 'icons/obj/items/weapons/predator.dmi'
	icon_state = "predknife"
	item_state = "knife"
	flags_atom = FPRINT|CONDUCT
	flags_item = ITEM_PREDATOR
	flags_equip_slot = SLOT_STORE
	sharp = IS_SHARP_ITEM_ACCURATE
	force = 24
	w_class = SIZE_TINY
	throwforce = 28
	throw_speed = 3
	throw_range = 6
	hitsound = 'sound/weapons/slash.ogg'
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	actions_types = list(/datum/action/item_action)
	unacidable = 1

/obj/item/weapon/yautja_knife/attack_self(mob/living/carbon/human/user)
	if(!isYautja(user)) 
		return
	if(!hasorgans(user)) 
		return

	dig_out_shrapnel(user)

/obj/item/weapon/yautja_knife/dropped(mob/living/user)
	add_to_missing_pred_gear(src)
	..()

// If no user, it means that the embedded_human is removing it themselves
/obj/item/weapon/proc/dig_out_shrapnel(var/mob/living/carbon/human/embedded_human, var/mob/living/carbon/human/user = null)
	if(!istype(embedded_human))
		return

	var/mob/living/carbon/human/H = embedded_human
	var/mob/living/carbon/human/H_user = embedded_human

	if(user)
		H_user = user

	if(H_user.action_busy) 
		return

	if(user)
		to_chat(user, SPAN_NOTICE("You begin using [src] to rip shrapnel out of [embedded_human]."))
		if(!do_after(user, 20, INTERRUPT_NO_NEEDHAND, BUSY_ICON_FRIENDLY, H, INTERRUPT_MOVED, BUSY_ICON_MEDICAL))
			to_chat(H_user, SPAN_NOTICE("You were interrupted!"))
			return
	else
		to_chat(H, SPAN_NOTICE("You begin using [src] to rip shrapnel out. Hold still. This will probably hurt..."))
		if(!do_after(H, 20, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
			to_chat(H_user, SPAN_NOTICE("You were interrupted!"))
			return

	var/found_shrapnel = helper_shrapnel_removal(embedded_human)
	if(!found_shrapnel)
		to_chat(H_user, SPAN_NOTICE("You couldn't find any shrapnel."))

/obj/item/weapon/proc/helper_shrapnel_removal(var/mob/living/carbon/human/embedded_human)
	for(var/obj/item/shard/shrapnel/embedded in embedded_human.embedded_items)
		var/datum/limb/organ = embedded.embedded_organ
		to_chat(embedded_human, SPAN_NOTICE("[embedded] is removed from your [organ.display_name]."))
		embedded.loc = embedded_human.loc
		organ.implants -= embedded
		embedded_human.embedded_items -= embedded
		if(!(organ.status & LIMB_ROBOT) && !(embedded_human.species.flags & NO_BLOOD)) //Big thing makes us bleed when moving
			organ.status |= LIMB_BLEEDING
		organ = null
		return TRUE
	return FALSE

