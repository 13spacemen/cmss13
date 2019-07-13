/mob/living/carbon/Xenomorph/say(var/message)
	var/verb = "says"
	var/forced = 0
	var/message_range = world.view

	if(client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, SPAN_WARNING("You cannot speak in IC (Muted)."))
			return

	message =  trim(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))

	if(stat == DEAD)
		return say_dead(message)

	if(stat == UNCONSCIOUS)
		return //Unconscious? Nope.

	if(dazed > 0)
		to_chat(src, SPAN_WARNING("You are too dazed to talk."))
		return

	if(copytext(message, 1, 2) == "*")
		return emote(copytext(message, 2))

	var/datum/language/speaking = null			
	if(length(message) >= 2)
		if(copytext(message,1,2) == ";" && languages.len)
			for(var/datum/language/L in languages)
				if(L.flags & HIVEMIND)
					verb = L.speech_verb
					speaking = L
					break
		var/channel_prefix = copytext(message, 1, 3)
		if(languages.len)
			for(var/datum/language/L in languages)
				if(lowertext(channel_prefix) == ":[L.key]" || lowertext(channel_prefix) == ".[L.key]")
					verb = L.speech_verb
					speaking = L
					break

	if(!caste.is_robotic)
		if(isnull(speaking) || speaking.key != "a") //Not hivemind? Then default to xenocommon. BRUTE FORCE YO
			for(var/datum/language/L in languages)
				if(L.key == "x")
					verb = L.speech_verb
					speaking = L
					forced = 1
					break
	else
		if(!speaking || isnull(speaking))
			for(var/datum/language/L in languages)
				if(L.key == "0")
					verb = L.speech_verb
					speaking = L
					forced = 1
					break

	if(speaking && !forced) 
		if (copytext(message,1,2) == ";")
			message = trim(copytext(message,2))
		else if (copytext(message,1,3) == ":a" || copytext(message,1,3) == ":A")
			message = trim(copytext(message,3))

	message = capitalize(trim_left(message))

	if(!message || stat)
		return

	if(forced)
		if(caste.is_robotic)
			var/noise = pick('sound/machines/ping.ogg','sound/machines/twobeep.ogg')
			verb = pick("beeps", "buzzes", "pings")
			playsound(src.loc, noise, 25, 1)
		else if(isXenoPredalien(src))
			playsound(loc, 'sound/voice/predalien_click.ogg', 25, 1)
		else
			playsound(loc, "alien_talk", 25, 1)
		..(message, speaking, verb, null, null, message_range, null)
	else
		hivemind_talk(message)

/mob/living/carbon/Xenomorph/say_understands(var/mob/other,var/datum/language/speaking = null)

	if(isXeno(other))
		return 1
	return ..()


//General proc for hivemind. Lame, but effective.
/mob/living/carbon/Xenomorph/proc/hivemind_talk(var/message)
	if(!message || src.stat)
		return

	if(!hive.living_xeno_queen && !Check_WO())
		to_chat(src, SPAN_WARNING("There is no Queen. You are alone."))
		return

	if(interference)
		to_chat(src, SPAN_WARNING("A headhunter temporarily cut off your psychic connection!"))
		return


	log_hivemind("[key_name(src)] : [message]")	

	var/track = ""
	var/overwatch_target = XENO_OVERWATCH_TARGET_HREF
	var/overwatch_src = XENO_OVERWATCH_SRC_HREF
	var/overwatch_insert = ""
	var/ghostrend
	var/rendered

	for (var/mob/S in player_list)
		if(!isnull(S) && (isXeno(S) || S.stat == DEAD) && !istype(S,/mob/new_player))
			if(istype(S,/mob/dead/observer))
				if(S.client.prefs && S.client.prefs.toggles_chat & CHAT_GHOSTHIVEMIND)
					track = "(<a href='byond://?src=\ref[S];track=\ref[src]'>follow</a>)"
					if(isXenoQueen(src))
						ghostrend = "<font size='3' font color='purple'><i><span class='game say'>Hivemind, <span class='name'>[name]</span> [track]<span class='message'> hisses, '[message]'</span></span></i></font>"
					else if(src in hive.xeno_leader_list)
						ghostrend = "<font color='purple'><i><span class='game say'>Hivemind, <span class='name'>[name]</span> [track]<span class='message'> hisses, '[message]'</span></span></i></font>"
					else
						ghostrend = "<i><span class='game say'>Hivemind, <span class='name'>[name]</span> [track]<span class='message'> hisses, '[message]'</span></span></i>"
					S.show_message(ghostrend, 2)

			else if(hivenumber == xeno_hivenumber(S))
				overwatch_insert = "(<a href='byond://?src=\ref[S];[overwatch_target]=\ref[src];[overwatch_src]=\ref[S]'>watch</a>)"

				if(isXenoQueen(src))
					rendered = "<font size='3' font color='purple'><i><span class='game say'>Hivemind, <span class='name'>[name]</span> [overwatch_insert]<span class='message'> hisses, '[message]'</span></span></i></font>"
				else if(src in hive.xeno_leader_list)
					rendered = "<font color='purple'><i><span class='game say'>Hivemind, <span class='name'>[name]</span> [overwatch_insert]<span class='message'> hisses, '[message]'</span></span></i></font>"
				else if(caste.is_robotic)
					var/message_b = pick("high-pitched blast of static","series of pings","long string of numbers","loud, mechanical squeal", "series of beeps")
					rendered = "<i><span class='game say'>Hivemind, <span class='name'>[name]</span> [overwatch_insert]emits a [message_b]!</span></i>"
				else
					rendered = "<i><span class='game say'>Hivemind, <span class='name'>[name]</span> [overwatch_insert]<span class='message'> hisses, '[message]'</span></span></i>"
				
				S.show_message(rendered, 2)
				
