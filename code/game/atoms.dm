
/atom
	layer = TURF_LAYER
	var/level = 2
	var/flags_atom = FPRINT

	var/list/fingerprintshidden
	var/fingerprintslast = null

	var/unacidable = FALSE
	var/last_bumped = 0

	// Flags for what an atom can pass through
	var/flags_pass = NO_FLAGS
	var/flags_pass_temp = NO_FLAGS

	// Flags for what can pass through an atom
	var/flags_can_pass_all = NO_FLAGS // Use for objects that are not ON_BORDER or for general pass characteristics of an atom
	var/flags_can_pass_front = NO_FLAGS // Relevant mainly for ON_BORDER atoms with the BlockedPassDirs() proc
	var/flags_can_pass_behind = NO_FLAGS // Relevant mainly for ON_BORDER atoms with the BlockedExitDirs() proc
	var/flags_can_pass_all_temp = NO_FLAGS
	var/flags_can_pass_front_temp = NO_FLAGS
	var/flags_can_pass_behind_temp = NO_FLAGS

	var/flags_barrier = NO_FLAGS
	var/throwpass = 0

	//Effects
	var/list/effects_list = list()

	///Chemistry.
	var/datum/reagents/reagents = null

	//Detective Work, used for the duplicate data points kept in the scanners
	var/list/original_atom

	//Z-Level Transitions
	var/atom/movable/clone/clone = null

	// Bitflag of which test cases this atom is exempt from
	// See #define/tests.dm
	var/test_exemptions = 0

// Temporary call in place for preparation of implementing SSatoms.
/atom/New()
	. = ..()
	Initialize()

/*
We actually care what this returns, since it can return different directives.
Not specifically here, but in other variations of this. As a general safety,
Make sure the return value equals the return value of the parent so that the
directive is properly returned.
*/
//===========================================================================
/atom/Dispose()
	if(reagents)
		qdel(reagents)
	if(light)
		qdel(light)
		light = null
	. = ..()

//===========================================================================



//atmos procs

//returns the atmos info relevant to the object (gas type, temperature, and pressure)
/atom/proc/return_air()
	if(loc)
		return loc.return_air()
	else
		return null


/atom/proc/return_pressure()
	if(loc)
		return loc.return_pressure()

/atom/proc/return_temperature()
	if(loc)
		return loc.return_temperature()

//returns the gas mix type
/atom/proc/return_gas()
	if(loc)
		return loc.return_gas()




/atom/proc/on_reagent_change()
	return

/atom/proc/Collided(atom/movable/AM)
	return

/atom/Cross(atom/movable/AM)
	return TRUE

/atom/Exit(atom/movable/AM)
	return TRUE

/*
 *	Checks whether an atom can pass through the calling atom into its target turf.
 *	Returns the blocking direction.
 *		If the atom's movement is not blocked, returns 0.
 *		If the object is completely solid, returns ALL
 */
/atom/proc/BlockedPassDirs(atom/movable/mover, target_dir)
	var/reverse_dir = REVERSE_DIR(dir)
	var/flags_can_pass = flags_can_pass_all|flags_can_pass_all_temp|flags_can_pass_front|flags_can_pass_front_temp
	var/mover_flags_pass = mover.flags_pass|mover.flags_pass_temp

	if (!density || flags_can_pass & mover_flags_pass)
		return NO_BLOCKED_MOVEMENT

	if (flags_atom & ON_BORDER)
		if (!(target_dir & reverse_dir))
			return NO_BLOCKED_MOVEMENT
		
		// This is to properly handle diagonal movement (a cade to your NE facing west when you are trying to move NE should block for north instead of east)
		if (target_dir & (NORTH|SOUTH) && target_dir & (EAST|WEST))
			return target_dir - (target_dir & reverse_dir)
		return target_dir & reverse_dir
	else
		return BLOCKED_MOVEMENT

/*
 *	Checks whether an atom can leave its current turf through the calling atom.
 *	Returns the blocking direction.
 *		If the atom's movement is not blocked, returns 0 (no directions)
 *		If the object is completely solid, returns all directions
 */
/atom/proc/BlockedExitDirs(atom/movable/mover, target_dir)
	var/flags_can_pass = flags_can_pass_all|flags_can_pass_all_temp|flags_can_pass_behind|flags_can_pass_behind_temp
	var/mover_flags_pass = mover.flags_pass|mover.flags_pass_temp

	if(flags_atom & ON_BORDER && density && !(flags_can_pass & mover_flags_pass))
		return target_dir & dir

	return NO_BLOCKED_MOVEMENT

// Convenience proc to see if a container is open for chemistry handling
// returns true if open
// false if closed
/atom/proc/is_open_container()
	return flags_atom & OPENCONTAINER

/atom/proc/can_be_syringed()
	return flags_atom & CAN_BE_SYRINGED

/*//Convenience proc to see whether a container can be accessed in a certain way.

	proc/can_subract_container()
		return flags & EXTRACT_CONTAINER

	proc/can_add_container()
		return flags & INSERT_CONTAINER
*/

/atom/proc/allow_drop()
	return 1


/atom/proc/HasProximity(atom/movable/AM as mob|obj)
	return

/atom/proc/emp_act(var/severity)
	return

/atom/proc/in_contents_of(container)//can take class or object instance as argument
	if(ispath(container))
		if(istype(src.loc, container))
			return 1
	else if(src in container)
		return 1
	return

/*
 *	atom/proc/search_contents_for(path,list/filter_path=null)
 * Recursevly searches all atom contens (including contents contents and so on).
 *
 * ARGS: path - search atom contents for atoms of this type
 *	   list/filter_path - if set, contents of atoms not of types in this list are excluded from search.
 *
 * RETURNS: list of found atoms
 */

/atom/proc/search_contents_for(path,list/filter_path=null)
	var/list/found = list()
	for(var/atom/A in src)
		if(istype(A, path))
			found += A
		if(filter_path)
			var/pass = 0
			for(var/type in filter_path)
				pass |= istype(A, type)
			if(!pass)
				continue
		if(A.contents.len)
			found += A.search_contents_for(path,filter_path)
	return found




/*
Beam code by Gunbuddy

Beam() proc will only allow one beam to come from a source at a time.  Attempting to call it more than
once at a time per source will cause graphical errors.
Also, the icon used for the beam will have to be vertical and 32x32.
The math involved assumes that the icon is vertical to begin with so unless you want to adjust the math,
its easier to just keep the beam vertical.
*/
/atom/proc/Beam(atom/BeamTarget,icon_state="b_beam",icon='icons/effects/beam.dmi',time=50, maxdistance=10)
	//BeamTarget represents the target for the beam, basically just means the other end.
	//Time is the duration to draw the beam
	//Icon is obviously which icon to use for the beam, default is beam.dmi
	//Icon_state is what icon state is used. Default is b_beam which is a blue beam.
	//Maxdistance is the longest range the beam will persist before it gives up.
	var/EndTime=world.time+time
	while(BeamTarget&&world.time<EndTime&&get_dist(src,BeamTarget)<maxdistance&&z==BeamTarget.z)
	//If the BeamTarget gets deleted, the time expires, or the BeamTarget gets out
	//of range or to another z-level, then the beam will stop.  Otherwise it will
	//continue to draw.

		dir=get_dir(src,BeamTarget)	//Causes the source of the beam to rotate to continuosly face the BeamTarget.

		for(var/obj/effect/overlay/beam/O in orange(10,src))	//This section erases the previously drawn beam because I found it was easier to
			if(O.BeamSource==src)				//just draw another instance of the beam instead of trying to manipulate all the
				qdel(O)							//pieces to a new orientation.
		var/Angle=round(Get_Angle(src,BeamTarget))
		var/icon/I=new(icon,icon_state)
		I.Turn(Angle)
		var/DX=(32*BeamTarget.x+BeamTarget.pixel_x)-(32*x+pixel_x)
		var/DY=(32*BeamTarget.y+BeamTarget.pixel_y)-(32*y+pixel_y)
		var/N=0
		var/length=round(sqrt((DX)**2+(DY)**2))
		for(N,N<length,N+=32)
			var/obj/effect/overlay/beam/X=new(loc)
			X.BeamSource=src
			if(N+32>length)
				var/icon/II=new(icon,icon_state)
				II.DrawBox(null,1,(length-N),32,32)
				II.Turn(Angle)
				X.icon=II
			else X.icon=I
			var/Pixel_x=round(sin(Angle)+32*sin(Angle)*(N+16)/32)
			var/Pixel_y=round(cos(Angle)+32*cos(Angle)*(N+16)/32)
			if(DX==0) Pixel_x=0
			if(DY==0) Pixel_y=0
			if(Pixel_x>32)
				for(var/a=0, a<=Pixel_x,a+=32)
					X.x++
					Pixel_x-=32
			if(Pixel_x<-32)
				for(var/a=0, a>=Pixel_x,a-=32)
					X.x--
					Pixel_x+=32
			if(Pixel_y>32)
				for(var/a=0, a<=Pixel_y,a+=32)
					X.y++
					Pixel_y-=32
			if(Pixel_y<-32)
				for(var/a=0, a>=Pixel_y,a-=32)
					X.y--
					Pixel_y+=32
			X.pixel_x=Pixel_x
			X.pixel_y=Pixel_y
		sleep(3)	//Changing this to a lower value will cause the beam to follow more smoothly with movement, but it will also be more laggy.
					//I've found that 3 ticks provided a nice balance for my use.
	for(var/obj/effect/overlay/beam/O in orange(10,src)) if(O.BeamSource==src) qdel(O)


//All atoms
/atom/verb/atom_examine()
	set name = "Examine"
	set category = "IC"
	set src in view(usr.client) //If it can be seen, it can be examined.

	if(!usr) return
	examine(usr)

/atom/proc/examine(mob/user)
	to_chat(user, "[htmlicon(src, user)] That's \a [src].") //changed to "That's" from "This is" because "This is some metal sheets" sounds dumb compared to "That's some metal sheets" ~Carn
	if(desc)
		to_chat(user, desc)

// called by mobs when e.g. having the atom as their machine, pulledby, loc (AKA mob being inside the atom) or buckled var set.
// see code/modules/mob/mob_movement.dm for more.
/atom/proc/relaymove()
	return

/atom/proc/ex_act()
	return

/atom/proc/fire_act()
	return

/atom/proc/hitby(atom/movable/AM)
	return

/atom/proc/add_hiddenprint(mob/living/M)
	if(!M || M.disposed || !M.key || !(flags_atom  & FPRINT) || fingerprintslast == M.key)
		return
	if (ishuman(M))
		var/mob/living/carbon/human/H = M
		if (H.gloves)
			fingerprintshidden += "\[[time_stamp()]\] (Wearing gloves). Real name: [H.real_name], Key: [H.key]"
		else
			fingerprintshidden += "\[[time_stamp()]\] Real name: [H.real_name], Key: [H.key]"
	else
		fingerprintshidden += "\[[time_stamp()]\] Real name: [M.real_name], Key: [M.key]"
	fingerprintslast = M.key


/atom/proc/add_fingerprint(mob/living/M)
	if(!M || M.disposed || !M.key || !(flags_atom & FPRINT) || fingerprintslast == M.key)
		return
	if(!fingerprintshidden)
		fingerprintshidden = list()
	fingerprintslast = M.key

	if (ishuman(M))
		var/mob/living/carbon/human/H = M

		//Fibers~
		blood_touch(H)

		fingerprintslast = M.key

		//Now, deal with gloves.
		if (H.gloves && H.gloves != src)
			fingerprintshidden += "\[[time_stamp()]\](Wearing gloves). Real name: [H.real_name], Key: [H.key]"
		else
			fingerprintshidden += "\[[time_stamp()]\]Real name: [H.real_name], Key: [H.key]"
	else
		fingerprintshidden +=  "\[[time_stamp()]\]Real name: [M.real_name], Key: [M.key]"



//put blood on stuff we touched
/atom/proc/blood_touch(mob/living/carbon/human/M)
	if(M.gloves)
		var/obj/item/clothing/gloves/G = M.gloves
		if(G.gloves_blood_amt && add_blood(G.blood_color)) //only reduces the bloodiness of our gloves if the item wasn't already bloody
			G.gloves_blood_amt--
	else if(M.hands_blood_amt && add_blood(M.hands_blood_color))
		M.hands_blood_amt--




/atom/proc/transfer_fingerprints_to(var/atom/A)

	if(!istype(A.fingerprintshidden,/list))
		A.fingerprintshidden = list()

	if(!istype(fingerprintshidden, /list))
		fingerprintshidden = list()

	if(A.fingerprintshidden && fingerprintshidden)
		A.fingerprintshidden |= fingerprintshidden.Copy()




/atom/proc/add_vomit_floor(mob/living/carbon/M, var/toxvomit = 0)
	return

/turf/add_vomit_floor(mob/living/carbon/M, var/toxvomit = 0)
	var/obj/effect/decal/cleanable/vomit/this = new /obj/effect/decal/cleanable/vomit(src)

	// Make toxins vomit look different
	if(toxvomit)
		this.icon_state = "vomittox_[pick(1,4)]"


/atom/proc/get_global_map_pos()
	if(!islist(global_map) || isemptylist(global_map)) return
	var/cur_x = null
	var/cur_y = null
	var/list/y_arr = null
	for(cur_x=1,cur_x<=global_map.len,cur_x++)
		y_arr = global_map[cur_x]
		cur_y = y_arr.Find(src.z)
		if(cur_y)
			break
	if(cur_x && cur_y)
		return list("x"=cur_x,"y"=cur_y)
	else
		return 0

//Generalized Fire Proc.
/atom/proc/flamer_fire_act(var/dam = config.min_burnlevel)
	return

/atom/proc/acid_spray_act()
	return


//things that object need to do when a movable atom inside it is deleted
/atom/proc/on_stored_atom_del(atom/movable/AM)
	return

/atom/proc/handle_barrier_chance()
	return FALSE

/atom/proc/initialize()
	return

/atom/proc/Initialize()
	return

///---CLONE---///

/atom/clone
	var/proj_x = 0
	var/proj_y = 0

/atom/proc/create_clone(shift_x, shift_y) //NOTE: Use only for turfs, otherwise use create_clone_movable
	var/turf/T = null
	T = locate(src.x + shift_x, src.y + shift_y, src.z)

	T.appearance = src.appearance
	T.dir = src.dir

	clones_t.Add(src)
	src.clone = T

// EFFECTS
/atom/proc/extinguish_acid()
	for(var/datum/effects/acid/A in effects_list)
		qdel(A)

/atom/proc/remove_weather_effects()
	for(var/datum/effects/weather/W in effects_list)
		qdel(W)
