/datum/admins/proc/topic_autoresponses(var/href_list)
	var/mob/ref_person = locate(href_list["extra"])
	if(!istype(ref_person))
		to_chat(usr, SPAN_NOTICE(" Looks like that person stopped existing!"))
		return
	if(ref_person && ref_person.adminhelp_marked && ref_person.adminhelp_marked_admin != usr.key)
		to_chat(usr, "<b>This Adminhelp is already being handled by another staff member. You can proceed but it's not recommended.</b>")
		usr << sound('sound/effects/adminhelp-error.ogg')
		if(alert(usr, "Are you sure you want to autoreply to this ahelp that is handled by another staff member?", "Confirmation", "Yes", "No") != "Yes")
			return

	if(ref_person && !ref_person.adminhelp_marked)
		to_chat(usr, "<b>This Adminhelp is not marked. You should mark ahelp first before autoresponding.</b>")
		return

	var/choice = input("Which autoresponse option do you want to send to the player?\n\n L - A webpage link.\n A - An answer to a common question.", "Autoresponse", "--CANCEL--") in list ("--CANCEL--", "IC Issue", "Being Handled", "Fixed", "Thanks", "Marine Law", "L: Xeno Quickstart Guide", "L: Marine quickstart guide", "L: Current Map", "A: No plasma regen", "A: Devour as Xeno", "T: Tunnel", "J: Job bans", "E: Event in progress", "R: Radios", "B: Binoculars", "D: Joining disabled", "M: Macros", "C: Changelog", "G: Gitlab it", "H: Clear Cache")
	var/msgplayer
	switch(choice)
		if("IC Issue")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. This issue has been deemed an IC (In-Character) issue, and will not be handled by staff. In case it's relevant, you may wish to ask your <a href='[URL_WIKI_COC]'>Chain Of Command</a> about your issue if you believe <a href='[URL_WIKI_LAW]'>Marine Law</a> has been broken.</b>")
		if("Being Handled")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. The issue is already being dealt with.</b>")
		if("Fixed")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. The issue is already fixed.</b>")
		if("Thanks")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>! Have a CM day!</b>")
		if("Marine Law")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. This is a <a href='[URL_WIKI_LAW]'>marine law issue</a>. Unless the MPs are breaking procedure in a significant way we will not influence IC events. You do have the right to appeal your sentence and should try to appeal to the Captain first. If you wish, you may <a href='[URL_FORUM_PLAYER_REPORT]'>file a player report</a> at our forums.</b>")
		if("L: Xeno Quickstart Guide")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Your answer can be found on the Xeno Quickstart Guide on our wiki. <a href='[URL_WIKI_XENO_QUICKSTART]'>Check it out here.</a></b>")
		if("L: Marine quickstart guide")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Your answer can be found on the Marine Quickstart Guide on our wiki. <a href='[URL_WIKI_MARINE_QUICKSTART]'>Check it out here.</a></b>")
		if("L: Current Map")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. If you need a map overview of the current round, use Current Map verb in OOC tab to check name of the map. Then open our <a href='[URL_WIKI_LANDING]'>wiki front page</a> and look for the map overview in the 'Maps' section. If the map is not listed, it's a new or rare map and the overview hasn't been finished yet.</b>")
		if("A: No plasma regen")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. If you have low/no plasma regen, it's most likely because you are off weeds or are currently using a passive ability, such as the Runner's 'Hide' or emitting a pheromone.</b>")
		if("A: Devour as Xeno")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Devouring is useful to quickly transport incapacitated hosts from one place to another. In order to devour a host as a Xeno, grab the mob (CTRL + Click) and then click on yourself to begin devouring. The host can break out of your belly, which will result in your death so make sure your target is incapacitated. After approximately 1 minute host will be automatically regurgitated. To release your target voluntary, click 'Regurgitate' on the HUD to throw them back up.</b>")
		if("T: Tunnel")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Click on the tunnel to enter it. While being in the tunnel, Alt + Click it to exit, Ctrl + Click to choose a destination.</b>")
		if("J: Job bans")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. All job bans, including xeno bans, are permanent until appealed. You can appeal it on the <a href='[URL_FORUM_APPEALS]'>forums</a></b>.")
		if("E: Event in progress")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. There is currently a special event running and many things may be changed or different, however normal rules still apply unless you have been specifically instructed otherwise by a staff member.</b>")
		if("R: Radios")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Examine your radio headset (Shift + Click) to get a list of the channels your headset has access to. Marine headsets have their respective squad channels available on \";\" key. Ship crew headsets have access to the Almayer public comms on \";\" and their respective department channel on \":h\". Command channel key is \":v\".</b>")
		if("B: Binoculars")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Binoculars allow you to increase distance of your view in direction you are looking. To zoom in, take them into your hand and activate them by pressing Z (in Hotkey Mode), PageDown or clicking on them in your hand.\nRangefinders allow you to get tile coordinates (longitude and latitude) by lasing it while zoomed in (Green laser). Ctrl + Click on any open tile to start lasing. Ctrl + Click on your rangefinders to stop lasing without looking up from them. Coordinates can be used by Staff Officers to send supply drops or to perform Orbital Bombardment. You also can use them to call mortar fire from engineers if they have mortar.\nLaser Designators have a second mode (Red laser) that allows highlighting targets for Close Air Support performed by pilots. They also have a fixed ID number that is shown in pilot's weaponry console. Examine laser designator to check it's ID. Red laser must be maintained as long as needed in order for pilot to bomb the designated area. To switch between lasing modes, Alt + Click the laser designator. Alternatively, Right + Click it in hand and press Toggle Mode.</b>")
		if("D: Joining disabled")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. Joining for new players is disabled for the current round due to either a staff member or and automatic setting during the end of the round. You can observe while it ends and wait for a new round to start.</b>")
		if("M: Macros")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. This <a href='[URL_WIKI_MACROS]'>guide</a> explains how to set up macros including examples of most common and useful ones.</b>")
		if("C: Changelog")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. The answer to your question can be found in the changelog. Click the changelog button at the top-right of the screen to view it in-game, or visit <a href='[URL_CHANGELOG]'>changelog page</a> on our wiki instead.</b>")
		if("G: Gitlab it")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>! Please, submit your suggestion/bug report issue in our <a href='[URL_ISSUE_TRACKER]'>Gitlab</a>.</b>")
		if("H: Clear Cache")
			msgplayer = SPAN_NOTICE("<b>NOTICE: <font color=red>[key_name_admin(usr, 0)]</font> is autoresponding with <font color='#009900'>'[choice]'</font>. In order to clear cache, you need to click on gear icon located in upper-right corner of your BYOND client and select preferences. Switch to Games tab and click Clear Cache button. In some cases you need to manually delete cache. To do that, select Advanced tab and click Open User Directory and delete \"cache\" folder there.</b>")
		else return
	msgplayer += " <b><i>You may click on the staff member's name to ask more about this response.</i></b>"
	message_staff("[usr.key] is autoresponding to [ref_person] with <font color='#009900'>'[choice]'</font>. They have been shown the following:\n[msgplayer]", 1)
	log_admin("[usr.key] is autoresponding to [ref_person] with <font color='#009900'>'[choice]'</font>.", 1) //No need to log the text we send them.
	STUI.staff.Add("\[[time_stamp()]][usr.key] is autoresponding to [ref_person] with [choice].<br>")
	STUI.processing |= 3
	to_chat(ref_person, msgplayer) //send a message to the player when the Admin clicks "Mark"
	ref_person << sound('sound/effects/adminhelp-reply.ogg')

	unansweredAhelps.Remove(ref_person.computer_id) //It has been answered so take it off of the unanswered list
	viewUnheardAhelps() //This SHOULD refresh the page

	ref_person.adminhelp_marked = 1 //Timer to prevent multiple clicks
	spawn(1000) //This should be <= the Adminhelp cooldown in adminhelp.dm
		if(ref_person)	ref_person.adminhelp_marked = 0

