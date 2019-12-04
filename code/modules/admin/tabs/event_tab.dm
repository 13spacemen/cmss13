/client/proc/cmd_admin_change_custom_event()
	set name = "A: Setup Event Text"
	set category = "Event"

	if(!admin_holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/input = input(usr, "Enter the description of the custom event. Be descriptive. To cancel the event, make this blank or hit cancel.", "Custom Event", custom_event_msg) as message|null
	if(!input || input == "")
		custom_event_msg = null
		log_admin("[usr.key] has cleared the custom event text.")
		message_admins("[key_name_admin(usr)] has cleared the custom event text.")
		return

	log_admin("[usr.key] has changed the custom event text.")
	message_admins("[key_name_admin(usr)] has changed the custom event text.")

	custom_event_msg = input

	to_world("<h1 class='alert'>Custom Event</h1>")
	to_world("<h2 class='alert'>A custom event is starting. OOC Info:</h2>")
	to_world(SPAN_ALERT("[html_encode(custom_event_msg)]"))
	to_world("<br>")

/client/proc/change_security_level()
	if(!check_rights(R_ADMIN))
		return
	var sec_level = input(usr, "It's currently code [get_security_level()].", "Select Security Level")  as null|anything in (list("green","blue","red","delta")-get_security_level())
	if(sec_level && alert("Switch from code [get_security_level()] to code [sec_level]?","Change security level?","Yes","No") == "Yes")
		set_security_level(sec_level)
		log_admin("[key_name(usr)] changed the security level to code [sec_level].")

/client/proc/toggle_gun_restrictions()
	if(!admin_holder)	
		return
	if(config)
		if(config.remove_gun_restrictions)
			to_chat(src, "<b>Enabled gun restrictions.</b>")
			message_admins("Admin [key_name_admin(usr)] has enabled WY gun restrictions.")
			log_admin("[key_name(src)] enabled WY gun restrictions.")
		else
			to_chat(src, "<b>Disabled gun restrictions.</b>")
			message_admins("Admin [key_name_admin(usr)] has disabled WY gun restrictions.")
			log_admin("[key_name(src)] disabled WY gun restrictions.")
		config.remove_gun_restrictions = !config.remove_gun_restrictions

/client/proc/adjust_weapon_mult()
	if(!admin_holder)	
		return
	if(config)
		var/acc = input("Select the new accuracy multiplier.","ACCURACY MULTIPLIER", 1) as num
		var/dam = input("Select the new damage multiplier.","DAMAGE MULTIPLIER", 1) as num
		if(acc && dam)
			config.proj_base_accuracy_mult = acc * 0.01
			config.proj_base_damage_mult = dam * 0.01
			log_admin("Admin [key_name_admin(usr)] changed global accuracy to <b>[acc]</b> and global damage to <b>[dam]</b>.", 1)
			log_debug("<b>[key_name(src)]</b> changed global accuracy to <b>[acc]</b> and global damage to <b>[dam]</b>.")

/client/proc/togglebuildmodeself()
	set name = "B: Buildmode"
	set category = "Event"
	if(src.mob)
		togglebuildmode(src.mob)

/client/proc/drop_bomb()
	set name = "B: Drop Bomb"
	set desc = "Cause an explosion of varying strength at your location."
	set category = "Event"

	var/turf/epicenter = mob.loc
	var/custom_limit = 5000
	var/list/choices = list("CANCEL", "Small Bomb", "Medium Bomb", "Big Bomb", "Custom Bomb")
	var/choice = input("What size explosion would you like to produce?") in choices
	switch(choice)
		if("CANCEL")
			return 0
		if("Small Bomb")
			explosion(epicenter, 1, 2, 3, 3)
		if("Medium Bomb")
			explosion(epicenter, 2, 3, 4, 4)
		if("Big Bomb")
			explosion(epicenter, 3, 5, 7, 5)
		if("Custom Bomb")
			var/power = input(src, "Power?", "Power?") as num
			if(!power)
				return

			var/falloff = input(src, "Falloff?", "Falloff?") as num
			if(!falloff)
				return

			if(power > custom_limit)
				return
			cell_explosion(epicenter, power, falloff)
			log_and_message_admins("[key_name(src, TRUE)] dropped a custom cell bomb with power [power] and falloff [falloff]!")
	message_admins(SPAN_NOTICE("[ckey] used 'Drop Bomb' at [epicenter.loc]."))

/client/proc/cmd_admin_emp(atom/O as obj|mob|turf in world)
	set name = "EM Pulse"
	set category = "Event"

	if(!check_rights(R_DEBUG|R_FUN))	
		return

	var/heavy = input("Range of heavy pulse.", text("Input"))  as num|null
	if(heavy == null) 
		return
	var/light = input("Range of light pulse.", text("Input"))  as num|null
	if(light == null) 
		return

	if(!heavy && !light)
		return

	empulse(O, heavy, light)
	log_admin("[key_name(usr)] created an EM Pulse ([heavy],[light]) at ([O.x],[O.y],[O.z])")
	message_admins("[key_name_admin(usr)] created an EM PUlse ([heavy],[light]) at ([O.x],[O.y],[O.z])")
	return

/datum/admins/proc/admin_force_ERT_shuttle()
	set name = "E: Force ERT Shuttle"
	set desc = "Force Launch the ERT Shuttle."
	set category = "Event"

	if (!ticker  || !ticker.mode) 
		return
	if(!check_rights(R_ADMIN))	
		return

	var/tag = input("Which ERT shuttle should be force launched?", "Select an ERT Shuttle:") as null|anything in list("Distress", "Distress_PMC", "Distress_UPP", "Distress_Big")
	if(!tag) return

	var/datum/shuttle/ferry/ert/shuttle = shuttle_controller.shuttles[tag]
	if(!shuttle || !istype(shuttle))
		message_admins("Warning: Distress shuttle not found. Aborting.")
		return

	if(shuttle.location) //in start zone in admin z level
		var/dock_id
		var/dock_list = list("Port", "Starboard", "Aft")
		if(shuttle.use_umbilical)
			dock_list = list("Port Hangar", "Starboard Hangar")
		var/dock_name = input("Where on the [MAIN_SHIP_NAME] should the shuttle dock?", "Select a docking zone:") as null|anything in dock_list
		switch(dock_name)
			if("Port") dock_id = /area/shuttle/distress/arrive_2
			if("Starboard") dock_id = /area/shuttle/distress/arrive_1
			if("Aft") dock_id = /area/shuttle/distress/arrive_3
			if("Port Hangar") dock_id = /area/shuttle/distress/arrive_s_hangar
			if("Starboard Hangar") dock_id = /area/shuttle/distress/arrive_n_hangar
			else return
		for(var/datum/shuttle/ferry/ert/F in shuttle_controller.process_shuttles)
			if(F != shuttle)
				//other ERT shuttles already docked on almayer or about to be
				if(!F.location || F.moving_status != SHUTTLE_IDLE)
					if(F.area_station.type == dock_id)
						message_admins("Warning: That docking zone is already taken by another shuttle. Aborting.")
						return

		for(var/area/A in all_areas)
			if(A.type == dock_id)
				shuttle.area_station = A
				break

	if(!shuttle.can_launch())
		message_admins("Warning: Unable to launch this Distress shuttle at this moment. Aborting.")
		return

	shuttle.launch()

	log_admin("[key_name(usr)] force launched a distress shuttle ([tag])")
	message_admins(SPAN_NOTICE("[key_name_admin(usr)] force launched a distress shuttle ([tag])"), 1)

/datum/admins/proc/admin_force_distress()
	set name = "E: Distress Beacon"
	set desc = "Call a distress beacon. This should not be done if the shuttle's already been called."
	set category = "Event"

	if (!ticker  || !ticker.mode)
		return

	if(!check_rights(R_ADMIN))	
		return

	if(ticker.mode.picked_call)
		var/confirm = alert(src, "There's already been a distress call sent. Are you sure you want to send another one? This will probably break things.", "Send a distress call?", "Yes", "No")
		if(confirm != "Yes") 
			return

		//Reset the distress call
		ticker.mode.picked_call.members = list()
		ticker.mode.picked_call.candidates = list()
		ticker.mode.waiting_for_candidates = 0
		ticker.mode.has_called_emergency = 0
		ticker.mode.picked_call = null

	var/list/list_of_calls = list()
	for(var/datum/emergency_call/L in ticker.mode.all_calls)
		if(L && L.name != "name")
			list_of_calls += L.name
	list_of_calls = sortList(list_of_calls)

	list_of_calls += "Randomize"

	var/choice = input("Which distress call?") as null|anything in list_of_calls
	if(!choice)
		return

	if(choice == "Randomize")
		ticker.mode.picked_call	= ticker.mode.get_random_call()
	else
		for(var/datum/emergency_call/C in ticker.mode.all_calls)
			if(C && C.name == choice)
				ticker.mode.picked_call = C
				break

	if(!istype(ticker.mode.picked_call))
		return

	var/is_announcing = TRUE
	var/announce = alert(src, "Would you like to announce the distress beacon to the server population? This will reveal the distress beacon to all players.", "Announce distress beacon?", "Yes", "No")
	if(announce == "No")
		is_announcing = FALSE

	ticker.mode.picked_call.activate(is_announcing)

	log_admin("[key_name(usr)] admin-called a [choice == "Randomize" ? "randomized ":""]distress beacon: [ticker.mode.picked_call.name]")
	message_admins(SPAN_NOTICE("[key_name_admin(usr)] admin-called a [choice == "Randomize" ? "randomized ":""]distress beacon: [ticker.mode.picked_call.name]"), 1)
	
/datum/admins/proc/admin_force_selfdestruct()
	set name = "E: Self Destruct"
	set desc = "Trigger self destruct countdown. This should not be done if the self destruct has already been called."
	set category = "Event"

	if(!ticker || !ticker.mode || !check_rights(R_ADMIN) || get_security_level() == "delta")
		return

	if(alert(src, "Are you sure you want to do this?", "Confirmation", "Yes", "No") == "No")
		return

	set_security_level(SEC_LEVEL_DELTA)

	log_admin("[key_name(usr)] admin-started self destruct stystem.")
	message_admins(SPAN_NOTICE("[key_name_admin(usr)] admin-started self destruct stystem."), 1)

/client/proc/view_faxes()
	set name = "X: View Faxes"
	set desc = "View faxes from this round"
	set category = "Event"

	if(!admin_holder)
		return

	var/answer = alert(src, "Which kind of faxes would you like to see?", "Faxes", "CL faxes", "USCM faxes", "Cancel")
	switch(answer)
		if("CL faxes")
			var/body = "<html><head><title>Faxes from the CL</title></head>"
			body += "<body><B>Faxes:</B>"
			body += "<br><br>"

			for(var/text in CLFaxes)
				body += text
				body += "<br><br>"

			body += "<br><br></body></html>"
			src << browse(body, "window=clfaxviewer;size=300x600")
		if("USCM faxes")
			var/body = "<html><head><title>Faxes</title></head>"
			body += "<body><B>Faxes:</B>"
			body += "<br><br>"

			for(var/text in USCMFaxes)
				body += text
				body += "<br><br>"

			body += "<br><br></body></html>"
			src << browse(body, "window=uscmfaxviewer;size=300x600")
		if("Cancel")
			return

/client/proc/show_objectives_status()
	set name = "O: Objectives Status"
	set desc = "Check the status of objectives."
	set category = "Event"

	if(!admin_holder || !(admin_holder.rights & R_MOD))
		to_chat(src, "Only administrators may use this command.")
		return

	if(objectives_controller)
		to_chat(src, objectives_controller.get_objectives_progress())

/client/proc/award_medal()
	if(!check_rights(R_ADMIN))
		return

	give_medal_award()

/client/proc/turn_everyone_into_primitives()
	var/random_names = FALSE
	if (alert(src, "Do you want to give everyone random numbered names?", "Confirmation", "Yes", "No") == "Yes")
		random_names = TRUE
	if (alert(src, "Are you sure you want to do this? It will laaag.", "Confirmation", "Yes", "No") == "No")
		return
	for(var/mob/living/carbon/human/H in mob_list)
		if(ismonkey(H))
			continue
		H.set_species(pick("Monkey", "Yiren", "Stok", "Farwa", "Neaera"))
		H.is_important = TRUE
		if(random_names)
			H.real_name = "[lowertext(H.species.name)] ([rand(1, 999)])"
			H.name = H.real_name
			H.voice_name = H.real_name
			if(H.wear_id)
				var/obj/item/card/id/card = H.wear_id
				card.registered_name = H.real_name
				card.name = "[card.registered_name]'s ID Card ([card.assignment])"

	log_admin("Admin [key_name(usr)] has turned everyone into a primitive")
	message_admins("Admin [key_name(usr)] has turned everyone into a primitive")

/client/proc/force_shuttle()
	set name = "E: Force Dropship"
	set desc = "Force a dropship to launch"
	set category = "Event"

	var/tag = input("Which dropship should be force launched?", "Select a dropship:") as null|anything in list("Dropship 1", "Dropship 2")
	if(!tag) return
	var/crash = 0
	switch(alert("Would you like to force a crash?", , "Yes", "No", "Cancel"))
		if("Yes") crash = 1
		if("No") crash = 0
		else return

	var/datum/shuttle/ferry/marine/dropship = shuttle_controller.shuttles[MAIN_SHIP_NAME + " " + tag]
	if(!dropship)
		to_chat(src, SPAN_DANGER("Error: Attempted to force a dropship launch but the shuttle datum was null. Code: MSD_FSV_DIN"))
		log_admin("Error: Attempted to force a dropship launch but the shuttle datum was null. Code: MSD_FSV_DIN")
		return

	if(crash && dropship.location != 1)
		switch(alert("Error: Shuttle is on the ground. Proceed with standard launch anyways?", , "Yes", "No"))
			if("Yes")
				dropship.process_state = WAIT_LAUNCH
				log_admin("[usr] ([usr.key]) forced a [dropship.iselevator? "elevator" : "shuttle"] using the Force Dropship verb")
			if("No")
				to_chat(src, SPAN_WARNING("Aborting shuttle launch."))
				return
	else if(crash)
		dropship.process_state = FORCE_CRASH
	else
		dropship.process_state = WAIT_LAUNCH

/client/proc/cmd_admin_create_centcom_report()
	set name = "A: Create Command Report"
	set category = "Event"

	if(!admin_holder || !(admin_holder.rights & R_MOD))
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = input(usr, "Please enter anything you want. Anything. Serious.", "What?", "") as message|null
	var/customname = input(usr, "Pick a title for the report.", "Title") as text|null
	if(!input)
		return
	if(!customname)
		customname = "USCM Update"
	for (var/obj/structure/machinery/computer/communications/C in machines)
		if(! (C.stat & (BROKEN|NOPOWER) ) )
			var/obj/item/paper/P = new /obj/item/paper( C.loc )
			P.name = "'[command_name] Update.'"
			P.info = input
			P.update_icon()
			C.messagetitle.Add("[command_name] Update")
			C.messagetext.Add(P.info)

	switch(alert("Should this be announced to the general population?",,"Yes","No"))
		if("Yes")
			marine_announcement(input, customname, 'sound/AI/commandreport.ogg');
		//if("No")
		//	world << sound('sound/AI/commandreport.ogg')

	log_admin("[key_name(src)] has created a command report: [input]")
	message_admins("[key_name_admin(src)] has created a command report")

/client/proc/cmd_admin_xeno_report()
	set name = "A: Create Queen Mother Report"
	set desc = "Basically a MOTHER report, but only for Xenos"
	set category = "Event"

	if(!admin_holder || !(admin_holder.rights & R_MOD))
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = input(usr, "This should be a message from the ruler of the Xenomorph race.", "What?", "") as message|null
	var/customname = "Queen Mother Psychic Directive"
	if(!input) 
		return FALSE

	var/data = "<br>[SPAN_ANNOUNCEMENT_HEADER_BLUE(customname)]<br><br>[SPAN_ANNOUNCEMENT_BODY(input)]<br>"

	for(var/mob/M in player_list)
		if(isXeno(M) || isobserver(M))
			to_chat(M, data)

	log_admin("[key_name(src)] has created a Queen Mother report: [input]")
	message_admins("[key_name_admin(src)] has created a Queen Mother report")
	 
/client/proc/cmd_admin_create_AI_report()
	set name = "A: Create ARES Announcement"
	set category = "Event"

	if(!admin_holder || !(admin_holder.rights & R_MOD))
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = input(usr, "This should be a message from the ship's AI.  Check with online staff before you send this. Do not use html.", "What?", "") as message|null
	if(!input) 
		return FALSE
	if(ai_announcement(input))
		for (var/obj/structure/machinery/computer/communications/C in machines)
			if(! (C.stat & (BROKEN|NOPOWER) ) )
				var/obj/item/paper/P = new /obj/item/paper( C.loc )
				P.name = "'[MAIN_AI_SYSTEM] Update.'"
				P.info = input
				P.update_icon()
				C.messagetitle.Add("[MAIN_AI_SYSTEM] Update")
				C.messagetext.Add(P.info)

		log_admin("[key_name(src)] has created an AI report: [input]")
		message_admins("[key_name_admin(src)] has created an AI report")
		 
	else
		to_chat(usr, SPAN_WARNING("[MAIN_AI_SYSTEM] is not responding. It may be offline or destroyed."))

/client/proc/cmd_admin_world_narrate() // Allows administrators to fluff events a little easier -- TLE
	set name = "N: Narrate to Everyone"
	set category = "Event"

	if (!admin_holder || !(admin_holder.rights & R_MOD))
		to_chat(src, "Only administrators may use this command.")
		return

	var/msg = input("Message:", text("Enter the text you wish to appear to everyone:")) as text

	if(!msg)
		return
		
	to_world(SPAN_ANNOUNCEMENT_HEADER_BLUE(msg))
	log_admin("GlobalNarrate: [key_name(usr)] : [msg]")
	message_admins(SPAN_NOTICE("\bold GlobalNarrate: [key_name_admin(usr)] : [msg]"))

/client/proc/admin_play_sound()
	set name = "S: Play Sound"
	set desc = "Play local or imported sounds"
	set category = "Event"

	if(!admin_holder)
		return

	var/answer = alert(src, "Which kind of sound would you like to play?", "Sound", "Sound from list", "Imported sound", "Cancel")
	switch(answer)
		if("Sound from list")
			play_sound_from_list()
		if("Imported sound")
			var/S = input("Pick a sound to play.") as sound
			play_imported_sound(S)
		if("Cancel")
			return

/client/proc/play_imported_sound(S as sound)
	if(!check_rights(R_SOUNDS))	
		return
	if(midi_playing)
		to_chat(usr, "No. An Admin already played a midi recently.")
		return

	var/sound/uploaded_sound = sound(S, repeat = 0, wait = 1, channel = 777)
	uploaded_sound.priority = 250
	switch(alert("Play sound globally or locally?", "Sound", "Global", "Local", "Individual", "Cancel"))
		if("Global")
			for(var/mob/M in player_list)
				if(M.client.prefs.toggles_sound & SOUND_MIDI)
					SSmidi.queue(M, uploaded_sound)
					heard_midi++
		if("Local")
			playsound(get_turf(src.mob), uploaded_sound, 50, 0)
			for(var/mob/M in view())
				heard_midi++
		if("Individual")
			var/mob/target = input("Select a mob to play sound to:", "List of All Mobs") as null|anything in mob_list
			if(istype(target,/mob/))
				if(target.client.prefs.toggles_sound & SOUND_MIDI)
					target << uploaded_sound
					heard_midi = "[target] ([target.key])"
				else
					heard_midi = 0
		if("Cancel")
			return
	 
	if(isnum(heard_midi))
		log_admin("[key_name(src)] played sound `[S]` for [heard_midi] player(s). [clients.len - heard_midi] player(s) have disabled admin midis.")
		message_admins("[key_name_admin(src)] played sound `[S]` for [heard_midi] player(s). [clients.len - heard_midi] player(s) have disabled admin midis.")
	else
		log_admin("[key_name(src)] played sound `[S]` for [heard_midi].")
		message_admins("[key_name_admin(src)] played sound `[S]` for [heard_midi].")
		return

	// A 30 sec timer used to show Admins how many players are silencing the sound after it starts - see preferences_toggles.dm
	var/midi_playing_timer = 30 SECONDS // Should match with the midi_silenced spawn() in preferences_toggles.dm
	midi_playing = 1
	spawn(midi_playing_timer)
		midi_playing = 0
		message_admins("'Silence Current Midi' usage reporting 30-sec timer has expired. [total_silenced] player(s) silenced the midi in the first 30 seconds out of [heard_midi] total player(s) that have 'Play Admin Midis' enabled. <span style='color: red'>[round((total_silenced / heard_midi) * 100)]% of players don't want to hear it, and likely more if the midi is longer than 30 seconds.</span>")
		heard_midi = 0
		total_silenced = 0

/client/proc/play_sound_from_list()
	if(!check_rights(R_SOUNDS))	
		return
	var/list/sounds = file2list("sound/soundlist.txt");
	sounds += "--CANCEL--"
	var/melody = input("Select a sound to play", "Sound list", "--CANCEL--") in sounds

	if(melody == "--CANCEL--")
		return

	play_imported_sound(melody)

/client/proc/enable_event_mob_verbs()
	set name = "Z: Mob Event Verbs - Show"
	set category = "Event"

	verbs += admin_mob_event_verbs_hideable 
	verbs -= /client/proc/enable_event_mob_verbs

/client/proc/hide_event_mob_verbs()
	set name = "Z: Mob Event Verbs - Hide"
	set category = "Event"

	verbs -= admin_mob_event_verbs_hideable 
	verbs += /client/proc/enable_event_mob_verbs

// ----------------------------
// PANELS
// ----------------------------

/datum/admins/proc/event_panel()
	if(!check_rights(R_FUN,0))	
		return

	var/dat = {"
		<B>Ship</B><BR>
		<A href='?src=\ref[src];events=securitylevel'>Set Security Level</A><BR>
		<A href='?src=\ref[src];events=distress'>Send a Distress Beacon</A><BR>
		<A href='?src=\ref[src];events=selfdestruct'>Activate Self-Destruct</A><BR>
		<BR>
		<B>Defcon</B><BR>
		<A href='?src=\ref[src];events=decrease_defcon'>Decrease DEFCON level</A><BR>
		<A href='?src=\ref[src];events=give_defcon_points'>Give DEFCON points</A><BR>
		<BR>
		<B>Power</B><BR>
		<A href='?src=\ref[src];events=unpower'>Unpower ship SMESs and APCs</A><BR>
		<A href='?src=\ref[src];events=power'>Power ship SMESs and APCs</A><BR>
		<A href='?src=\ref[src];events=quickpower'>Power ship SMESs</A><BR>
		<A href='?src=\ref[src];events=powereverything'>Power ALL SMESs and APCs everywhere</A><BR>
		<A href='?src=\ref[src];events=powershipreactors'>Power all ship reactors</A><BR>
		<BR>
		<B>Events</B><BR>
		<A href='?src=\ref[src];events=blackout'>Break all lights</A><BR>
		<A href='?src=\ref[src];events=whiteout'>Repair all lights</A><BR>
		<A href='?src=\ref[src];events=comms_blackout'>Trigger a Communication Blackout</A><BR>
		<BR>
		<B>Misc</B><BR>
		<A href='?src=\ref[src];events=medal'>Award a medal</A><BR>
		<A href='?src=\ref[src];events=weaponmults'>Adjust weapon multipliers</A><BR>
		<A href='?src=\ref[src];events=pmcguns'>Toggle PMC gun restrictions</A><BR>
		<A href='?src=\ref[src];events=monkify'>Turn everyone into monkies</A><BR>
		<BR>
		"}

	usr << browse(dat, "window=events")
	return

/client/proc/event_panel()
	set name = "C: Event Panel"
	set category = "Event"
	if (admin_holder)
		admin_holder.event_panel()
	return


/datum/admins/proc/chempanel()
	if(!check_rights(R_MOD)) return

	var/dat = {"<center><B>Chem Panel</B></center><hr>\n"}
	if(check_rights(R_MOD,0))
		dat += {"<A href='?src=\ref[src];chem_panel=view_reagent'>View Reagent</A><br>
				"}
	if(check_rights(R_VAREDIT,0))
		dat += {"<A href='?src=\ref[src];chem_panel=view_reaction'>View Reaction</A><br>
				<br>"}
	if(check_rights(R_SPAWN,0))
		dat += {"<A href='?src=\ref[src];chem_panel=spawn_reagent'>Spawn Reagent in Container</A><br>
				<br>"}
	if(check_rights(R_FUN,0))
		dat += {"<A href='?src=\ref[src];chem_panel=create_random_reagent'>Generate Reagent</A><br>
				<br>
				<A href='?src=\ref[src];chem_panel=create_custom_reagent'>Create Custom Reagent</A><br>
				<A href='?src=\ref[src];chem_panel=create_custom_reaction'>Create Custom Reaction</A><br>
				"}

	usr << browse(dat, "window=chempanel;size=210x300")
	return

/client/proc/chem_panel()
	set name = "C: Chem Panel"
	set category = "Event"
	if(admin_holder)
		admin_holder.chempanel()
	return