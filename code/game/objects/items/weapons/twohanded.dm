	/*##################################################################
	Much improved now. Leaving the overall item procs here since they're
	easier to find that way. Theoretically any item may be twohanded,
	but only these items and guns benefit from it. ~N
	####################################################################*/

/obj/item/weapon/twohanded
	var/force_wielded 	= 0
	var/wieldsound 		= null
	var/unwieldsound 	= null
	flags_item = TWOHANDED

	update_icon()
		return

	mob_can_equip(mob/user)
		unwield(user)
		return ..()

	dropped(mob/user)
		..()
		unwield(user)

	pickup(mob/user)
		unwield(user)

/obj/item/proc/wield(var/mob/user)
	if( !(flags_item & TWOHANDED) || flags_item & WIELDED ) return

	var/obj/item/I = user.get_inactive_hand()
	if(I)
		user.drop_inv_item_on_ground(I)

	if(ishuman(user))
		var/check_hand = user.r_hand == src ? "l_hand" : "r_hand"
		var/mob/living/carbon/human/wielder = user
		var/datum/limb/hand = wielder.get_limb(check_hand)
		if( !istype(hand) || !hand.is_usable() )
			to_chat(user, SPAN_WARNING("Your other hand can't hold [src]!"))
			return

	flags_item 	   ^= WIELDED
	name 	   += " (Wielded)"
	item_state += "_w"
	place_offhand(user,initial(name))
	return 1

/obj/item/proc/unwield(mob/user)
	if( (flags_item|TWOHANDED|WIELDED) != flags_item) return //Have to be actually a twohander and wielded.
	flags_item ^= WIELDED
	on_unwield()
	name 	    = copytext(name,1,-10)
	item_state  = copytext(item_state,1,-2)
	remove_offhand(user)
	return 1

/obj/item/proc/place_offhand(var/mob/user,item_name)
	to_chat(user, SPAN_NOTICE("You grab [item_name] with both hands."))
	user.recalculate_move_delay = TRUE
	var/obj/item/weapon/twohanded/offhand/offhand = new /obj/item/weapon/twohanded/offhand(user)
	offhand.name = "[item_name] - offhand"
	offhand.desc = "Your second grip on the [item_name]."
	offhand.flags_item |= WIELDED
	user.put_in_inactive_hand(offhand)
	user.update_inv_l_hand(0)
	user.update_inv_r_hand()

/obj/item/proc/remove_offhand(var/mob/user)
	to_chat(user, SPAN_NOTICE("You are now carrying [name] with one hand."))
	user.recalculate_move_delay = TRUE
	var/obj/item/weapon/twohanded/offhand/offhand = user.get_inactive_hand()
	if(istype(offhand)) offhand.unwield(user)
	user.update_inv_l_hand(0)
	user.update_inv_r_hand()

/obj/item/weapon/twohanded/wield(mob/user)
	. = ..()
	if(!.) return
	user.recalculate_move_delay = TRUE
	if(wieldsound) playsound(user, wieldsound, 15, 1)
	force 		= force_wielded

/obj/item/weapon/twohanded/unwield(mob/user)
	. = ..()
	if(!.) return
	user.recalculate_move_delay = TRUE
	if(unwieldsound) playsound(user, unwieldsound, 15, 1)
	force 	 	= initial(force)

/obj/item/weapon/twohanded/attack_self(mob/user)
	..()
	if(ismonkey(user))
		to_chat(user, SPAN_WARNING("It's too heavy for you to wield fully!"))
		return

	if(flags_item & WIELDED) unwield(user)
	else 				wield(user)

///////////OFFHAND///////////////
/obj/item/weapon/twohanded/offhand
	w_class = SIZE_HUGE
	icon_state = "offhand"
	name = "offhand"
	flags_item = DELONDROP|TWOHANDED|WIELDED

	unwield(var/mob/user)
		if(flags_item & WIELDED)
			flags_item &= ~WIELDED
			user.temp_drop_inv_item(src)
			qdel(src)

	wield()
		qdel(src) //This shouldn't even happen.

	Dispose()
		..()
		return GC_HINT_RECYCLE //So we can recycle this garbage.

	dropped(mob/user)
		..()
		//This hand should be holding the main weapon. If everything worked correctly, it should not be wielded.
		//If it is, looks like we got our hand torn off or something.
		var/obj/item/main_hand = user.get_active_hand()
		if(main_hand) main_hand.unwield(user)

	//mute both events. otherwise we are stuck in the loop
	on_unwield()
		return 0

	on_dropped()
		return 0
/*
 * Fireaxe
 */
/obj/item/weapon/twohanded/fireaxe
	name = "fire axe"
	desc = "Truly, the weapon of a madman. Who would think to fight fire with an axe?"
	icon_state = "fireaxe"
	item_state = "fireaxe"
	force = 20
	sharp = IS_SHARP_ITEM_BIG
	edge = 1
	w_class = SIZE_LARGE
	flags_equip_slot = SLOT_BACK
	flags_atom = FPRINT|CONDUCT
	flags_item = TWOHANDED
	force_wielded = 45
	attack_verb = list("attacked", "chopped", "cleaved", "torn", "cut")

/obj/item/weapon/twohanded/fireaxe/wield(mob/user)
	. = ..()
	if(!.) return
	pry_capable = IS_PRY_CAPABLE_SIMPLE

/obj/item/weapon/twohanded/fireaxe/unwield(mob/user)
	. = ..()
	if(!.) return
	pry_capable = 0

/obj/item/weapon/twohanded/fireaxe/afterattack(atom/A as mob|obj|turf|area, mob/user as mob, proximity)
	if(!proximity) return
	..()
	if(A && (flags_item & WIELDED) && istype(A,/obj/structure/grille)) //destroys grilles in one hit
		qdel(A)

/obj/item/weapon/twohanded/sledgehammer
	name = "sledgehammer"
	desc = "a large block of metal on the end of a pole. Smashing!"
	icon_state = "sledgehammer"
	item_state = "sledgehammer"
	force = 20
	force_wielded = 50
	sharp = null
	edge = 0
	w_class = SIZE_LARGE
	flags_equip_slot = SLOT_BACK
	flags_atom = FPRINT|CONDUCT
	flags_item = TWOHANDED
	attack_verb = list("smashed", "beaten", "slammed", "struck", "smashed", "battered", "cracked")

//The following is copypasta and not the sledge being a child of the fireaxe due to the fire axe being able to crowbar airlocks
/obj/item/weapon/twohanded/sledgehammer/afterattack(atom/A as mob|obj|turf|area, mob/user as mob, proximity)
	if(!proximity) return
	..()
	if(A && (flags_item & WIELDED) && istype(A,/obj/structure/grille)) //destroys grilles in one hit
		qdel(A)

/*
 * Double-Bladed Energy Swords - Cheridan
 */
/obj/item/weapon/twohanded/dualsaber
	name = "double-bladed energy sword"
	desc = "Handle with care."
	icon_state = "dualsaber"
	item_state = "dualsaber"
	force = 3
	throwforce = 5.0
	throw_speed = SPEED_FAST
	throw_range = 5
	w_class = SIZE_SMALL
	force_wielded = 70
	wieldsound = 'sound/weapons/saberon.ogg'
	unwieldsound = 'sound/weapons/saberoff.ogg'
	flags_atom = FPRINT|NOBLOODY
	flags_item = NOSHIELD|TWOHANDED
	origin_tech = "magnets=3;syndicate=4"
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharp = IS_SHARP_ITEM_BIG
	edge = 1

/obj/item/weapon/twohanded/dualsaber/attack(target as mob, mob/living/user as mob)
	..()
	if((CLUMSY in user.mutations) && (flags_item & WIELDED) &&prob(40))
		to_chat(user, SPAN_HIGHDANGER("You twirl around a bit before losing your balance and impaling yourself on [src]."))
		user.take_limb_damage(20,25)
		return
	if((flags_item & WIELDED) && prob(50))
		spawn(0)
			for(var/i in list(1,2,4,8,4,2,1,2,4,8,4,2))
				user.dir = i
				sleep(1)

/obj/item/weapon/twohanded/dualsaber/IsShield()
	if(flags_item & WIELDED) return 1

/obj/item/weapon/twohanded/dualsaber/wield(mob/user)
	. = ..()
	if(!.) return
	icon_state += "_w"

/obj/item/weapon/twohanded/dualsaber/unwield(mob/user)
	. = ..()
	if(!.) return
	icon_state 	= copytext(icon_state,1,-2)

/obj/item/weapon/twohanded/spear
	name = "spear"
	desc = "A haphazardly-constructed yet still deadly weapon of ancient design."
	icon_state = "spearglass"
	item_state = "spearglass"
	force = 14
	w_class = SIZE_LARGE
	flags_equip_slot = SLOT_BACK
	force_wielded = 24
	throwforce = 30
	throw_speed = SPEED_VERY_FAST
	edge = 1
	sharp = IS_SHARP_ITEM_SIMPLE
	flags_item = NOSHIELD|TWOHANDED
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "stabbed", "jabbed", "torn", "gored")



/obj/item/weapon/twohanded/glaive
	name = "war glaive"
	icon = 'icons/obj/items/weapons/predator.dmi'
	icon_state = "glaive"
	item_state = "glaive"
	desc = "A huge, powerful blade on a metallic pole. Mysterious writing is carved into the weapon."
	force = 28
	w_class = SIZE_LARGE
	flags_equip_slot = SLOT_BACK
	force_wielded = 60
	throwforce = 50
	throw_speed = SPEED_VERY_FAST
	edge = 1
	sharp = IS_SHARP_ITEM_BIG
	flags_atom = FPRINT|CONDUCT
	flags_item = NOSHIELD|TWOHANDED|ITEM_PREDATOR
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("sliced", "slashed", "jabbed", "torn", "gored")
	unacidable = TRUE
	attack_speed = 12 //Default is 7.

/obj/item/weapon/twohanded/glaive/Dispose()
	remove_from_missing_pred_gear(src)
	..()

/obj/item/weapon/twohanded/glaive/dropped(mob/living/user)
	add_to_missing_pred_gear(src)
	..()

/obj/item/weapon/twohanded/glaive/pickup(mob/living/user)
	if(isYautja(user))
		remove_from_missing_pred_gear(src)
	..()

/obj/item/weapon/two_handed/glaive/attack(mob/living/target, mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return
	if(isYautja(user) && isXeno(target))
		var/mob/living/carbon/Xenomorph/X = target
		X.interference = 30

/obj/item/weapon/twohanded/glaive/damaged
	name = "war glaive"
	desc = "A huge, powerful blade on a metallic pole. Mysterious writing is carved into the weapon. This one is ancient and has suffered serious acid damage, making it near-useless."
	force = 18
	force_wielded = 28