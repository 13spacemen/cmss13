var/datum/subsystem/database_query_manager/SSdatabase

/datum/subsystem/database_query_manager
	name          = "Database QM"
	wait		  = 1 // CALL US AS OFTEN AS YOU CAN, GAME!
	init_order    = SS_INIT_DATABASE
	flags         = SS_FIRE_IN_LOBBY
	priority      = SS_PRIORITY_DATABASE
	display_order = SS_DISPLAY_DATABASE

	var/datum/db/connection/connection
	var/datum/db/connection_settings/settings
	var/list/datum/db/query_response/queries

	var/list/datum/db/query_response/all_queries

	var/list/datum/db/query_response/currentrun

	var/list/query_texts

	var/in_progress = 0
	var/in_callback = 0

	var/in_progress_tally = 0
	var/in_callback_tally = 0

	var/last_query_id = 0

	var/debug_mode = FALSE

/datum/subsystem/database_query_manager/New()
	queries = list()
	currentrun = list()
	all_queries = list()
	var/list/result = loadsql("config/dbconfig.txt")
	settings = connection_settings_from_config(result)
	debug_mode = settings.debug_mode
	NEW_SS_GLOBAL(SSdatabase)

/datum/subsystem/database_query_manager/Initialize()
	set waitfor=0
	connection = settings.create_connection()
	connection.keep()

/datum/subsystem/database_query_manager/stat_entry()
	var/text = (connection && connection.status == DB_CONNECTION_READY) ? ("READY") : ("PREPPING")
	..("[text], Q:[queries.len]; P:[currentrun.len]; C:[in_callback]")

/datum/subsystem/database_query_manager/fire(resumed = FALSE)
	if (!resumed)
		connection.keep()
		currentrun = queries.Copy()
		in_progress_tally = 0
		in_callback_tally = 0
	if(connection.status != DB_CONNECTION_READY)
		return
	while (currentrun.len)
		var/list/datum/db/query_response/Q = currentrun[currentrun.len]		
		if (!Q || Q.disposed)
			queries -= Q
			continue
		in_progress_tally++
		if(Q.process())
			queries -= Q
			in_callback_tally++
		currentrun.len--
		if (MC_TICK_CHECK)			
			return
	in_progress = in_progress_tally
	in_callback = in_callback_tally

/datum/subsystem/database_query_manager/proc/create_query(query_text, success_callback, fail_callback, unique_query_id)
	var/datum/db/query_response/qr = new()
	qr.query = connection.query(query_text)
	qr.query_text = query_text
	qr.success_callback = success_callback
	qr.fail_callback = fail_callback
	if(unique_query_id)
		qr.unique_query_id = unique_query_id
	else
		qr.unique_query_id = last_query_id
		last_query_id++
	queries += qr
	if(debug_mode)
		all_queries += qr
	
// if DB supports this
/datum/subsystem/database_query_manager/proc/create_parametric_query(query_text, parameters, success_callback, fail_callback, unique_query_id)
	var/datum/db/query_response/qr = new()
	var/list/prs = list()
	prs.Add(query_text)
	if(parameters)
		prs.Add(parameters)
	qr.query = connection.query(arglist(prs))
	qr.query_text = query_text
	qr.success_callback = success_callback
	qr.fail_callback = fail_callback
	if(unique_query_id)
		qr.unique_query_id = unique_query_id
	else
		qr.unique_query_id = last_query_id
		last_query_id++
	queries += qr
	if(debug_mode)
		all_queries += qr

// Do not use this if you don't know why this exists
/datum/subsystem/database_query_manager/proc/create_query_sync(query_text, wait_attempts = 20, wait_timer = 1)
	var/datum/db/query_response/qr = new()
	qr.query = connection.query(query_text)
	qr.query_text = query_text
	if(debug_mode)
		all_queries += qr
	var/wait_tally = 0
	while(wait_tally++ <= wait_attempts && !qr.process())
		sleep(wait_timer)
	return qr

/datum/subsystem/database_query_manager/proc/create_parametric_query_sync(query_text, parameters, wait_attempts = 20, wait_timer = 1)
	var/datum/db/query_response/qr = new()
	var/list/prs = list()
	prs += query_text
	if(parameters)
		prs += parameters
	qr.query = connection.query(arglist(prs))
	qr.query_text = query_text
	if(debug_mode)
		all_queries += qr
	var/wait_tally = 0
	while(wait_tally++ <= wait_attempts && !qr.process())
		sleep(wait_timer)
	return qr

/proc/loadsql(filename)
	var/list/Lines = file2list(filename)
	var/list/result = list()
	for(var/t in Lines)
		if(!t)	continue

		t = trim(t)
		if(length(t) == 0)
			continue
		else if (copytext(t, 1, 2) == "#")
			continue

		var/pos = findtext(t, " ")
		var/name = null
		var/value = null

		if(pos)
			name = lowertext(copytext(t, 1, pos))
			value = copytext(t, pos + 1)
		else
			name = lowertext(t)
		
		if(findtext(name, "db_")==0)
			continue

		if(!name)
			continue

		result[name] = value
	return result