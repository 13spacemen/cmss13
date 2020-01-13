	////////////
	//SECURITY//
	////////////
#define TOPIC_SPAM_DELAY	2		//2 ticks is about 2/10ths of a second; it was 4 ticks, but that caused too many clicks to be lost due to lag
#define UPLOAD_LIMIT		10485760	//Restricts client uploads to the server to 10MB //Boosted this thing. What's the worst that can happen?
#define MIN_CLIENT_VERSION	0		//Just an ambiguously low version for now, I don't want to suddenly stop people playing.
									//I would just like the code ready should it ever need to be used.
#define GOOD_BYOND_MAJOR	513
#define GOOD_BYOND_MINOR	1500
	/*
	When somebody clicks a link in game, this Topic is called first.
	It does the stuff in this proc and  then is redirected to the Topic() proc for the src=[0xWhatever]
	(if specified in the link). ie locate(hsrc).Topic()

	Such links can be spoofed.

	Because of this certain things MUST be considered whenever adding a Topic() for something:
		- Can it be fed harmful values which could cause runtimes?
		- Is the Topic call an admin-only thing?
		- If so, does it have checks to see if the person who called it (usr.client) is an admin?
		- Are the processes being called by Topic() particularly laggy?
		- If so, is there any protection against somebody spam-clicking a link?
	If you have any  questions about this stuff feel free to ask. ~Carn
	*/
/client/Topic(href, href_list, hsrc)
	if(!usr || usr != mob)	//stops us calling Topic for somebody else's client. Also helps prevent usr=null
		return

	//Reduces spamming of links by dropping calls that happen during the delay period
	if(next_allowed_topic_time > world.time)
		return
	next_allowed_topic_time = world.time + TOPIC_SPAM_DELAY

	//Asset cache
	var/job
	if(href_list["asset_cache_confirm_arrival"])
		job = round(text2num(href_list["asset_cache_confirm_arrival"]))
		//because we skip the limiter, we have to make sure this is a valid arrival and not somebody tricking us
		//into letting append to a list without limit.
		if(job > 0 && job <= last_asset_job && !(job in completed_asset_jobs))
			completed_asset_jobs += job
			return
		else if(job in completed_asset_jobs) 
			to_chat(src, SPAN_DANGER("An error has been detected in how your client is receiving resources. Attempting to correct.... (If you keep seeing these messages you might want to close byond and reconnect)"))
			src << browse("...", "window=asset_cache_browser") 

	if(href_list["_src_"] == "chat") //Hopefully this catches pings before we log
		return chatOutput.Topic(href, href_list)

	//search the href for script injection
	if(findtext(href,"<script",1,0) )
		world.log << "Attempted use of scripts within a topic call, by [src]"
		message_admins("Attempted use of scripts within a topic call, by [src]")
		//del(usr)
		return

	//Admin PM //Why is this not in /datums/admin/Topic()
	if(href_list["priv_msg"])
		var/client/C = locate(href_list["priv_msg"])
		if(ismob(C)) 		//Old stuff can feed-in mobs instead of clients
			var/mob/M = C
			C = M.client
		if(!C) return //Outdated links to logged players generate runtimes
		if(unansweredAhelps[C.computer_id]) unansweredAhelps.Remove(C.computer_id)
		cmd_admin_pm(C,null)
		return

	//Map voting
	if(href_list["vote_for_map"])
		mapVote()
		return

	else if(href_list["FaxView"])
		var/info = locate(href_list["FaxView"])
		show_browser(usr, "<body class='paper'>[info]</body>", "Fax Message", "Fax Message")

	//Logs all hrefs
	if(config && config.log_hrefs && href_logfile)
		href_logfile << "<small>[time2text(world.timeofday,"hh:mm")] [src] (usr:[usr])</small> || [hsrc ? "[hsrc] " : ""][href]<br>"

	if(job && (job in completed_asset_jobs))
		to_chat(src, SPAN_DANGER("An error has been detected in how your client is receiving resources. Attempting to correct.... (If you keep seeing these messages you might want to close byond and reconnect)"))
		src << browse("...", "window=asset_cache_browser")

	switch(href_list["_src_"])
		if("admin_holder")
			hsrc = admin_holder
		if("mhelp")
			var/client/thread_author = directory[href_list["mhelp_key"]]
			if(thread_author)
				var/datum/mentorhelp/help_thread = thread_author.current_mhelp
				hsrc = help_thread
		if("usr")
			hsrc = mob
		if("prefs")
			return prefs.process_link(usr, href_list)
		if("vars")
			return view_var_Topic(href, href_list, hsrc)
		if("glob_vars")
			return view_glob_var_Topic(href, href_list, hsrc)
		if("matrices")
			return matrix_editor_Topic(href, href_list, hsrc)
		if("chat")
			return chatOutput.Topic(href, href_list)

	switch(href_list["action"])
		if ("openLink")
			src << link(href_list["link"])
		if ("proccall")
			var/proc_to_call = text2path(href_list["procpath"])
			call(src, proc_to_call)()

	return ..()	//redirect to hsrc.Topic()

/client/proc/handle_spam_prevention(var/message, var/mute_type)
	if(config.automute_on && !admin_holder && src.last_message == message)
		src.last_message_count++
		if(src.last_message_count >= SPAM_TRIGGER_AUTOMUTE)
			to_chat(src, SPAN_DANGER("You have exceeded the spam filter limit for identical messages. An auto-mute was applied."))
			cmd_admin_mute(src.mob, mute_type, 1)
			return 1
		if(src.last_message_count >= SPAM_TRIGGER_WARNING)
			to_chat(src, SPAN_DANGER("You are nearing the spam filter limit for identical messages."))
			return 0
	else
		last_message = message
		src.last_message_count = 0
		return 0

//This stops files larger than UPLOAD_LIMIT being sent from client to server via input(), client.Import() etc.
/client/AllowUpload(filename, filelength)
	if(filelength > UPLOAD_LIMIT)
		to_chat(src, "<font color='red'>Error: AllowUpload(): File Upload too large. Upload Limit: [UPLOAD_LIMIT/1024]KiB.</font>")
		return 0
/*	//Don't need this at the moment. But it's here if it's needed later.
	//Helps prevent multiple files being uploaded at once. Or right after eachother.
	var/time_to_wait = fileaccess_timer - world.time
	if(time_to_wait > 0)
		to_chat(src, "<font color='red'>Error: AllowUpload(): Spam prevention. Please wait [round(time_to_wait/10)] seconds.</font>")
		return 0
	fileaccess_timer = world.time + FTPDELAY	*/
	return 1


	///////////
	//CONNECT//
	///////////
/client/New(TopicData)
	chatOutput = new /datum/chatOutput(src)
	soundOutput = new /datum/soundOutput(src)
	TopicData = null							//Prevent calls to client.Topic from connect

	if(!(connection in list("seeker", "web")))					//Invalid connection type.
		return null

	if(!guests_allowed && IsGuestKey(key))
		alert(src,"This server doesn't allow guest accounts to play. Please go to http://www.byond.com/ and register for a key.","Guest","OK")
		qdel(src)
		return

	// Change the way they should download resources.
	if(config.resource_urls)
		src.preload_rsc = pick(config.resource_urls)
	else src.preload_rsc = 1 // If config.resource_urls is not set, preload like normal.

	to_chat_forced(src, SPAN_WARNING("If the title screen is black, resources are still downloading. Please be patient until the title screen appears."))


	clients += src
	directory[ckey] = src
	player_entity = setup_player_entity(ckey)

	//Admin Authorisation
	admin_holder = admin_datums[ckey]
	if(admin_holder)
		admins += src
		admin_holder.owner = src
	//preferences datum - also holds some persistant data for the client (because we may as well keep these datums to a minimum)
	prefs = preferences_datums[ckey]
	if(!prefs || isnull(prefs) || !istype(prefs))
		prefs = new /datum/preferences(src)
		preferences_datums[ckey] = prefs
	prefs.last_ip = address				//these are gonna be used for banning
	prefs.last_id = computer_id			//these are gonna be used for banning
	fps = prefs.fps
	xeno_prefix = prefs.xeno_prefix	
	xeno_postfix = prefs.xeno_postfix
	xeno_name_ban = prefs.xeno_name_ban
	if(!xeno_prefix || xeno_name_ban)	
		xeno_prefix = "XX"
	if(!xeno_postfix || xeno_name_ban)
		xeno_postfix = ""
	. = ..()	//calls mob.Login()
	chatOutput.start()

	// Version check below if we ever need to start checking against BYOND versions again.

	/*if((byond_version < world.byond_version) || ((byond_version == world.byond_version) && (byond_build < world.byond_build)))
		src << "<span class='warning'>Your version of Byond (v[byond_version].[byond_build]) differs from the server (v[world.byond_version].[world.byond_build]). You may experience graphical glitches, crashes, or other errors. You will be disconnected until your version matches or exceeds the server version.<br> \
		Direct Download (Windows Installer): http://www.byond.com/download/build/[world.byond_version]/[world.byond_version].[world.byond_build]_byond.exe <br> \
		Other versions (search for [world.byond_build] or higher): http://www.byond.com/download/build/[world.byond_version]</span>"
		qdel(src)
		return*/
	//hardcode for now
	if((byond_version < GOOD_BYOND_MAJOR) || ((byond_version == GOOD_BYOND_MAJOR) && (byond_build < GOOD_BYOND_MINOR)))
		to_chat(src, FONT_SIZE_HUGE(SPAN_BOLDNOTICE("YOUR BYOND VERSION IS NOT WELL SUITED FOR THIS SERVER. Download latest BETA build or you may suffer random crashes or disconnects.")))

	if(custom_event_msg && custom_event_msg != "")
		to_chat(src, "<h1 class='alert'>Custom Event</h1>")
		to_chat(src, "<h2 class='alert'>A custom event is taking place. OOC Info:</h2>")
		to_chat(src, SPAN_ALERT("[html_encode(custom_event_msg)]"))
		to_chat(src, "<br>")

	if( (world.address == address || !address) && !host )
		host = key
		world.update_status()

	if(admin_holder)
		add_admin_verbs()
		add_admin_whitelists()
	log_client_to_db()

	send_assets()
	nanomanager.send_resources(src)

	create_clickcatcher()
	apply_clickcatcher()

	if(prefs.lastchangelog != changelog_hash) //bolds the changelog button on the interface so we know there are updates.
		winset(src, "rpane.changelog", "background-color=#ED9F9B;font-style=bold")


	var/file = file2text("config/donators.txt")
	var/lines = splittext(file, "\n")

	for(var/line in lines)
		if(src.ckey == line)
			src.donator = 1
			verbs += /client/proc/set_ooc_color_self

	//////////////
	//DISCONNECT//
	//////////////
/client/Dispose()
	. = ..()

	if(chatOutput)
		qdel(chatOutput)
		chatOutput = null

	if(soundOutput)
		qdel(soundOutput)
		soundOutput = null

	if(admin_holder)
		admin_holder.owner = null
		admins -= src
	directory -= ckey
	clients -= src
	return GC_HINT_DELETE_NOW

/client/proc/log_client_to_db()

	if ( IsGuestKey(src.key) )
		return

	establish_db_connection()
	if(!dbcon.IsConnected())
		return

	var/sql_ckey = sql_sanitize_text(src.ckey)

	var/DBQuery/query = dbcon.NewQuery("SELECT id, datediff(Now(),firstseen) as age FROM erro_player WHERE ckey = '[sql_ckey]'")
	query.Execute()
	var/sql_id = 0
	player_age = 0	// New players won't have an entry so knowing we have a connection we set this to zero to be updated if their is a record.
	while(query.NextRow())
		sql_id = query.item[1]
		player_age = text2num(query.item[2])
		break

	var/DBQuery/query_ip = dbcon.NewQuery("SELECT ckey FROM erro_player WHERE ip = '[address]'")
	query_ip.Execute()
	related_accounts_ip = ""
	while(query_ip.NextRow())
		related_accounts_ip += "[query_ip.item[1]], "
		break

	var/DBQuery/query_cid = dbcon.NewQuery("SELECT ckey FROM erro_player WHERE computerid = '[computer_id]'")
	query_cid.Execute()
	related_accounts_cid = ""
	while(query_cid.NextRow())
		related_accounts_cid += "[query_cid.item[1]], "
		break

	//Just the standard check to see if it's actually a number
	if(sql_id)
		if(istext(sql_id))
			sql_id = text2num(sql_id)
		if(!isnum(sql_id))
			return

	var/admin_rank = "Player"
	if(src.admin_holder)
		admin_rank = src.admin_holder.rank

	var/sql_ip = sql_sanitize_text(src.address)
	var/sql_computerid = sql_sanitize_text(src.computer_id)
	var/sql_admin_rank = sql_sanitize_text(admin_rank)


	if(sql_id)
		//Player already identified previously, we need to just update the 'lastseen', 'ip' and 'computer_id' variables
		var/DBQuery/query_update = dbcon.NewQuery("UPDATE erro_player SET lastseen = Now(), ip = '[sql_ip]', computerid = '[sql_computerid]', lastadminrank = '[sql_admin_rank]' WHERE id = [sql_id]")
		query_update.Execute()
	else
		//New player!! Need to insert all the stuff
		var/DBQuery/query_insert = dbcon.NewQuery("INSERT INTO erro_player (id, ckey, firstseen, lastseen, ip, computerid, lastadminrank) VALUES (null, '[sql_ckey]', Now(), Now(), '[sql_ip]', '[sql_computerid]', '[sql_admin_rank]')")
		query_insert.Execute()

	//Logging player access
	var/serverip = "[world.internet_address]:[world.port]"
	var/DBQuery/query_accesslog = dbcon.NewQuery("INSERT INTO `erro_connection_log`(`id`,`datetime`,`serverip`,`ckey`,`ip`,`computerid`) VALUES(null,Now(),'[serverip]','[sql_ckey]','[sql_ip]','[sql_computerid]');")
	query_accesslog.Execute()


#undef TOPIC_SPAM_DELAY
#undef UPLOAD_LIMIT
#undef MIN_CLIENT_VERSION

//checks if a client is afk
//3000 frames = 5 minutes
/client/proc/is_afk(duration=3000)
	if(inactivity > duration)	return inactivity
	return 0

//send resources to the client. It's here in its own proc so we can move it around easiliy if need be
/client/proc/send_assets()
	//get the common files
	getFiles(
		'html/search.js',
		'html/panels.css',
		'html/loading.gif',
		'html/images/wylogo.png',
		'html/images/uscmlogo.png',
		'html/images/faxwylogo.png',
		'html/images/faxbackground.jpg'
		)
	add_timer(CALLBACK(GLOBAL_PROC, .proc/get_files_slot, src, SSassets.preload, FALSE), 10)

/client/Stat()
	// We just did a short sleep because of a change, do another to render quickly, but flip the flag back.
	if (stat_fast_update)
		stat_fast_update = 0
		Stat()
		return 0

	last_statpanel = statpanel

	. = ..() // Do our regular Stat stuff

	//statpanel changed? We doin a short sleep
	if (statpanel != last_statpanel || stat_force_fast_update)
		stat_fast_update = 1
		stat_force_fast_update = 0
		return .

	// Nothing happening, long sleep
	sleep(5)
	return .

/proc/setup_player_entity(var/ckey)
	if(!ckey)
		return
	if(player_entities["[ckey]"])
		return player_entities["[ckey]"]
	var/datum/entity/player_entity/P = new()
	P.ckey = ckey
	P.name = ckey
	player_entities["[ckey]"] = P
	P.setup_save(ckey)
	return P

/proc/save_player_entities()
	for(var/key_ref in player_entities)
		var/datum/entity/player_entity/P = player_entities["[key_ref]"]
		P.save_statistics()

/client/proc/clear_chat_spam_mute(var/warn_level = 1, var/message = FALSE, var/increase_warn = FALSE)
	if(talked > warn_level)
		return
	talked = 0
	if(message)
		to_chat(src, SPAN_NOTICE("You may now speak again."))
	if(increase_warn)
		chatWarn++
