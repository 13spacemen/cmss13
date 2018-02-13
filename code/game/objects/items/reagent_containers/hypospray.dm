////////////////////////////////////////////////////////////////////////////////
/// HYPOSPRAY
////////////////////////////////////////////////////////////////////////////////

/obj/item/reagent_container/hypospray
	name = "hypospray"
	desc = "The DeForest Medical Corporation hypospray is a sterile, air-needle autoinjector for rapid administration of drugs to patients."
	icon = 'icons/obj/items/syringe.dmi'
	item_state = "hypo"
	icon_state = "hypo"
	amount_per_transfer_from_this = 5
	volume = 30
	possible_transfer_amounts = null
	flags_atom = FPRINT|OPENCONTAINER
	flags_equip_slot = SLOT_WAIST
	var/skilllock = 1

/obj/item/reagent_container/hypospray/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/item/reagent_container/hypospray/attack(mob/M, mob/living/user)
	if(!reagents.total_volume)
		user << "\red [src] is empty."
		return
	if (!( istype(M, /mob) ))
		return
	if (reagents.total_volume)
		if(skilllock && user.mind && user.mind.cm_skills && user.mind.cm_skills.medical < SKILL_MEDICAL_CHEM)
			user << "<span class='warning'>You can't figure out to use \the [src], guess you shouldn't have dropped out of kindergarten.</span>"
			return 0
		var/mob/target = null
		if(user.mind && user.mind.cm_skills && user.mind.cm_skills.medical < SKILL_MEDICAL_CHEM && prob(50))
			user << "<span class='warning'>You fumble the injector and end up jabbing yourself with it!</span>"
			target = user
		else
			target = M
			user << "\blue You inject [M] with [src]."
		target << "\red You feel a tiny prick!"
		playsound(loc, 'sound/items/hypospray.ogg', 50, 1)

		src.reagents.reaction(target, INGEST)
		if(target.reagents)

			var/list/injected = list()
			for(var/datum/reagent/R in src.reagents.reagent_list)
				injected += R.name
			var/contained = english_list(injected)
			target.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been injected with [src.name] by [user.name] ([user.ckey]). Reagents: [contained]</font>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to inject [target.name] ([target.key]). Reagents: [contained]</font>")
			msg_admin_attack("[user.name] ([user.ckey]) injected [target.name] ([target.key]) with [src.name]. Reagents: [contained] (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")

			var/trans = reagents.trans_to(target, amount_per_transfer_from_this)
			user << "\blue [trans] units injected. [reagents.total_volume] units remaining in [src]."

	return 1

/obj/item/reagent_container/hypospray/autoinjector
	name = "\improper Inaprovaline autoinjector"
	//desc = "A rapid and safe way to administer small amounts of drugs by untrained or trained personnel."
	desc = "An autoinjector containing Inaprovaline.  Useful for saving lives."
	icon_state = "autoinjector"
	item_state = "hypo"
	amount_per_transfer_from_this = 5
	volume = 5

/obj/item/reagent_container/hypospray/autoinjector/attack(mob/M as mob, mob/user as mob)
	. = ..()
	if(.)
		if(reagents.total_volume <= 0) //Prevents autoinjectors to be refilled.
			flags_atom &= ~OPENCONTAINER
			update_icon()

/obj/item/reagent_container/hypospray/autoinjector/attackby() return

/obj/item/reagent_container/hypospray/autoinjector/update_icon()
	if(reagents.total_volume <= 0)
		icon_state += "0"
		name += " expended" //So people can see what have been expended since we have smexy new sprites people aren't used too...

/obj/item/reagent_container/hypospray/autoinjector/examine(mob/user)
	..()
	if(reagents && reagents.reagent_list.len)
		user << "\blue It is currently loaded."
	else
		user << "\blue It is spent."

/obj/item/reagent_container/hypospray/tricordrazine
	desc = "The DeForest Medical Corporation hypospray is a sterile, air-needle autoinjector for rapid administration of drugs to patients. Contains tricordrazine."
	volume = 30

/obj/item/reagent_container/hypospray/tricordrazine/New()
	..()
	reagents.add_reagent("tricordrazine", 30)

