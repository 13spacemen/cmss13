




/////////////////////// Hand Labeler ////////////////////////////////


/obj/item/tool/hand_labeler
	name = "hand labeler"
	icon = 'icons/obj/items/paper.dmi'
	icon_state = "labeler0"
	item_state = "flight"
	var/label = null
	var/labels_left = 50
	var/mode = 0	//off or on.

/obj/item/tool/hand_labeler/afterattack(atom/A, mob/user as mob, proximity)
	if(!proximity) return
	if(!mode)	//if it's off, give up.
		return
	if(A == loc)	// if placing the labeller into something (e.g. backpack)
		return		// don't set a label

	if(!labels_left)
		to_chat(user, SPAN_NOTICE("No labels left."))
		return
	if(!label || !length(label))
		to_chat(user, SPAN_NOTICE("No text set."))
		return
	if(length(A.name) + length(label) > 64)
		to_chat(user, SPAN_NOTICE("Label too big."))
		return
	if(isliving(A))
		to_chat(user, SPAN_NOTICE("You can't label living beings."))
		return
	if(istype(A, /obj/item/reagent_container/glass))
		to_chat(user, SPAN_NOTICE("The label will not stick to [A]. Use a pen instead."))
		return
	if(istype(A, /obj/item/tool/surgery))
		to_chat(user, SPAN_NOTICE("That wouldn't be sanitary."))
		return
	if(isturf(A))
		to_chat(user, SPAN_NOTICE("The label won't stick to that."))
		return

	user.visible_message(SPAN_NOTICE("[user] labels [A] as \"[label]\"."), \
						 SPAN_NOTICE("You label [A] as \"[label]\"."))
	msg_admin_niche("[user]/([user.ckey]) has labeled [A.name] with label \"[label]\".")
	A.name = "[A.name] ([label])"
	labels_left--

/obj/item/tool/hand_labeler/attack_self(mob/user as mob)
	mode = !mode
	icon_state = "labeler[mode]"
	if(mode)
		to_chat(user, SPAN_NOTICE("You turn on \the [src]."))
		//Now let them chose the text.
		var/str = copytext(reject_bad_text(input(user,"Label text?", "Set label", "")), 1, MAX_NAME_LEN)
		if(!str || !length(str))
			to_chat(user, SPAN_NOTICE("Invalid text."))
			return
		label = str
		to_chat(user, SPAN_NOTICE("You set the text to '[str]'."))
	else
		to_chat(user, SPAN_NOTICE("You turn off \the [src]."))





/*
 * Pens
 */
/obj/item/tool/pen
	desc = "It's a normal black ink pen."
	name = "pen"
	icon = 'icons/obj/items/paper.dmi'
	icon_state = "pen"
	item_state = "pen"
	flags_equip_slot = SLOT_WAIST|SLOT_EAR
	throwforce = 0
	w_class = 1
	throw_speed = 7
	throw_range = 15
	matter = list("metal" = 10)
	var/colour = "black"	//what colour the ink is!



/obj/item/tool/pen/blue
	desc = "It's a normal blue ink pen."
	icon_state = "pen_blue"
	colour = "blue"

/obj/item/tool/pen/red
	desc = "It's a normal red ink pen."
	icon_state = "pen_red"
	colour = "red"

/obj/item/tool/pen/invisible
	desc = "It's an invisble pen marker."
	icon_state = "pen"
	colour = "white"


/obj/item/tool/pen/attack(mob/M as mob, mob/user as mob)
	if(!ismob(M))
		return
	to_chat(user, SPAN_WARNING("You stab [M] with the pen."))
//	to_chat(M, SPAN_WARNING("You feel a tiny prick!")) //That's a whole lot of meta!
	M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been stabbed with [name]  by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [name] to stab [M.name] ([M.ckey])</font>")
	msg_admin_attack("[user.name] ([user.ckey]) Used the [name] to stab [M.name] ([M.ckey]) (<A HREF='?_src_=admin_holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")
	return


/*
 * Sleepy Pens
 */
/obj/item/tool/pen/sleepypen
	desc = "It's a black ink pen with a sharp point and a carefully engraved \"Waffle Co.\""
	flags_atom = FPRINT|OPENCONTAINER
	flags_equip_slot = SLOT_WAIST
	origin_tech = "materials=2;syndicate=5"


/obj/item/tool/pen/sleepypen/New()
	. = ..()
	var/datum/reagents/R = new/datum/reagents(30) //Used to be 300
	reagents = R
	R.my_atom = src
	R.add_reagent("chloralhydrate", 22)	//Used to be 100 sleep toxin//30 Chloral seems to be fatal, reducing it to 22./N
	..()
	return


/obj/item/tool/pen/sleepypen/attack(mob/M as mob, mob/user as mob)
	if(!(istype(M,/mob)))
		return
	..()
	if(reagents.total_volume)
		if(M.reagents) reagents.trans_to(M, 50) //used to be 150
	return


/*
 * Parapens
 */
 /obj/item/tool/pen/paralysis
	flags_atom = FPRINT|OPENCONTAINER
	flags_equip_slot = SLOT_WAIST
	origin_tech = "materials=2;syndicate=5"


/obj/item/tool/pen/paralysis/attack(mob/living/M as mob, mob/user as mob)
	if(!(istype(M,/mob)))
		return
	..()
	if(M.can_inject(user,1))
		if(reagents.total_volume)
			if(M.reagents) reagents.trans_to(M, 50)

/obj/item/tool/pen/paralysis/New()
	. = ..()
	var/datum/reagents/R = new/datum/reagents(50)
	reagents = R
	R.my_atom = src
	R.add_reagent("zombiepowder", 10)
	R.add_reagent("cryptobiolin", 15)
	..()

/obj/item/tool/stamp
	name = "rubber stamp"
	desc = "A rubber stamp for stamping important documents."
	icon = 'icons/obj/items/paper.dmi'
	icon_state = "stamp-qm"
	item_state = "stamp"
	throwforce = 0
	w_class = 1.0
	throw_speed = 7
	throw_range = 15
	matter = list("metal" = 60)
	attack_verb = list("stamped")

/obj/item/tool/stamp/captain
	name = "captain's rubber stamp"
	icon_state = "stamp-cap"

/obj/item/tool/stamp/hop
	name = "head of personnel's rubber stamp"
	icon_state = "stamp-hop"

/obj/item/tool/stamp/hos
	name = "head of security's rubber stamp"
	icon_state = "stamp-hos"

/obj/item/tool/stamp/ce
	name = "chief engineer's rubber stamp"
	icon_state = "stamp-ce"

/obj/item/tool/stamp/rd
	name = "research director's rubber stamp"
	icon_state = "stamp-rd"

/obj/item/tool/stamp/cmo
	name = "chief medical officer's rubber stamp"
	icon_state = "stamp-cmo"

/obj/item/tool/stamp/denied
	name = "\improper DENIED rubber stamp"
	icon_state = "stamp-deny"

/obj/item/tool/stamp/clown
	name = "clown's rubber stamp"
	icon_state = "stamp-clown"

/obj/item/tool/stamp/internalaffairs
	name = "internal affairs rubber stamp"
	icon_state = "stamp-intaff"

/obj/item/tool/stamp/centcomm
	name = "centcomm rubber stamp"
	icon_state = "stamp-cent"
