// Individual skill
/datum/skill
	var/skill_name = "Skill" // Name of the skill
	var/skill_level = 0 // Level of skill in this... skill

/datum/skill/proc/get_skill_level()
	return skill_level

/datum/skill/proc/set_skill(var/new_level, var/datum/mind/owner)
	skill_level = new_level

/datum/skill/proc/is_skilled(var/req_level)
	return (skill_level >= req_level)

// Lots of defines here. See #define/skills.dm

/datum/skill/cqc
	skill_name = SKILL_CQC
	skill_level = SKILL_CQC_DEFAULT

/datum/skill/melee_weapons
	skill_name = SKILL_MELEE_WEAPONS
	skill_level = SKILL_MELEE_DEFAULT

/datum/skill/firearms
	skill_name = SKILL_FIREARMS
	skill_level = SKILL_FIREARMS_DEFAULT

/datum/skill/pistols
	skill_name = SKILL_PISTOLS
	skill_level = SKILL_PISTOLS_DEFAULT

/datum/skill/shotguns
	skill_name = SKILL_SHOTGUNS
	skill_level = SKILL_SHOTGUNS_DEFAULT

/datum/skill/rifles
	skill_name = SKILL_RIFLES
	skill_level = SKILL_RIFLES_DEFAULT

/datum/skill/smgs
	skill_name = SKILL_SMGS
	skill_level = SKILL_SMGS_DEFAULT

/datum/skill/heavy_weapons
	skill_name = SKILL_HEAVY_WEAPONS
	skill_level = SKILL_HEAVY_WEAPONS_DEFAULT

/datum/skill/smartgun
	skill_name = SKILL_SMARTGUN
	skill_level = SKILL_SMART_DEFAULT

/datum/skill/spec_weapons
	skill_name = SKILL_SPEC_WEAPONS
	skill_level = SKILL_SPEC_DEFAULT

/datum/skill/endurance
	skill_name = SKILL_ENDURANCE
	skill_level = SKILL_ENDURANCE_WEAK

/datum/skill/engineer
	skill_name = SKILL_ENGINEER
	skill_level = SKILL_ENGINEER_DEFAULT

/datum/skill/construction
	skill_name = SKILL_CONSTRUCTION
	skill_level = SKILL_CONSTRUCTION_DEFAULT

/datum/skill/leadership
	skill_name = SKILL_LEADERSHIP
	skill_level = SKILL_LEAD_NOVICE

/datum/skill/medical
	skill_name = SKILL_MEDICAL
	skill_level = SKILL_MEDICAL_DEFAULT

/datum/skill/surgery
	skill_name = SKILL_SURGERY
	skill_level = SKILL_SURGERY_DEFAULT

/datum/skill/research
	skill_name = SKILL_RESEARCH
	skill_level = SKILL_RESEARCH_DEFAULT

/datum/skill/pilot
	skill_name = SKILL_PILOT
	skill_level = SKILL_PILOT_DEFAULT

/datum/skill/police
	skill_name = SKILL_POLICE
	skill_level = SKILL_POLICE_DEFAULT

/datum/skill/powerloader
	skill_name = SKILL_POWERLOADER
	skill_level = SKILL_POWERLOADER_DEFAULT

/datum/skill/large_vehicle
	skill_name = SKILL_LARGE_VEHICLE
	skill_level = SKILL_LARGE_VEHICLE_DEFAULT

// Skill with an extra S at the end is a collection of multiple skills. Basically a skillSET
// This is to organize and provide a common interface to the huge heap of skills there are
/datum/skills
	var/name //the name of the skillset
	var/datum/mind/owner = null // the mind that has this skillset

	// List of skill datums.
	// Also, if this is populated when the datum is created, it will set the skill levels automagically
	var/list/skills = list()

/datum/skills/New(var/datum/mind/skillset_owner)
	owner = skillset_owner

	// Setup every single skill
	for(var/skill_type in subtypesof(/datum/skill))
		var/datum/skill/S = new skill_type()

		// Fancy hack to convert a list of desired skill levels in each named skill into a skill level in the actual skill datum
		// Lets the skills list be used multipurposely for both storing skill datums and choosing skill levels for different skillsets
		var/predetermined_skill_level = skills[S.skill_name]
		skills[S.skill_name] = S

		if(!isnull(predetermined_skill_level))
			S.set_skill(predetermined_skill_level, owner)

/datum/skills/Dispose()
	owner = null

	for(var/datum/skill/S in skills)
		qdel(S)
		skills -= S

// Checks if the given skill is contained in this skillset at all
/datum/skills/proc/has_skill(var/skill)
	return isnull(skills[skill])

// Returns the skill DATUM for the given skill
/datum/skills/proc/get_skill(var/skill)
	return skills[skill]

// Returns the skill level for the given skill
/datum/skills/proc/get_skill_level(var/skill)
	var/datum/skill/S = skills[skill]
	if(!S)
		return -1
	return S.get_skill_level()

// Sets the skill LEVEL for a given skill
/datum/skills/proc/set_skill(var/skill, var/new_level)
	var/datum/skill/S = skills[skill]
	if(!S)
		return
	return S.set_skill(new_level, owner)

// Checks if the skillset is AT LEAST skilled enough to pass a skillcheck for the given skill level
/datum/skills/proc/is_skilled(var/skill, var/req_level)
	var/datum/skill/S = get_skill(skill)
	if(isnull(S))
		return FALSE
	return S.is_skilled(req_level)

// Adjusts the full skillset to a new type of skillset. Pass the datum type path for the desired skillset
/datum/skills/proc/set_skillset(var/skillset_type)
	var/datum/skills/skillset = new skillset_type()
	var/list/skill_levels = initial(skillset.skills)

	name = skillset.name
	for(var/skill in skill_levels)
		set_skill(skill, skill_levels[skill])
	qdel(skillset)

/*
---------------------
CIVILIAN
---------------------
*/

/datum/skills/civilian
	name = "Civilian"
	skills = list(
		SKILL_CQC = SKILL_CQC_WEAK,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_WEAK,
		SKILL_ENDURANCE = SKILL_ENDURANCE_NONE
	)

/datum/skills/civilian/survivor
	name = "Survivor"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI, //to hack airlocks so they're never stuck in a room.
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_METAL,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)

/datum/skills/civilian/survivor/doctor
	name = "Survivor Doctor"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED
	)

/datum/skills/civilian/survivor/scientist
	name = "Survivor Scientist"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED
	)

/datum/skills/civilian/survivor/chef
	name = "Survivor Chef"
	skills = list(
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED
	)

/datum/skills/civilian/survivor/miner
	name = "Survivor Miner"
	skills = list(
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED
	)

/datum/skills/civilian/survivor/atmos
	name = "Survivor Atmos Tech"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER
	)

/datum/skills/civilian/survivor/marshall
	name = "Survivor Marshall"
	skills = list(
		SKILL_CQC = SKILL_CQC_MP,
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_DEFAULT,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_MP
	)

/datum/skills/civilian/survivor/prisoner
	name = "Survivor Prisoner"
	skills = list(
		SKILL_CQC = SKILL_CQC_DEFAULT,
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_DEFAULT,
		SKILL_PISTOLS = SKILL_PISTOLS_DEFAULT
	)

/*
---------------------
COMMAND STAFF
---------------------
*/

/datum/skills/admiral
	name = "Admiral"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)

/datum/skills/commander
	name = "Commanding Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ADVANCED,
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/XO
	name = "Executive Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI, //to fix CIC apc.
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED
	)

/datum/skills/SO
	name = "Staff Officer"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_POLICE = SKILL_POLICE_FLASH
	)

/datum/skills/CMO
	name = "CMO"
	skills = list(
		SKILL_CQC = SKILL_CQC_WEAK,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_CMO,
		SKILL_SURGERY = SKILL_SURGERY_MASTER,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_WEAK,
		SKILL_POLICE = SKILL_POLICE_FLASH
	)

/datum/skills/CMP
	name = "Chief MP"
	skills = list(
		SKILL_CQC = SKILL_CQC_MP,
		SKILL_POLICE = SKILL_POLICE_MP,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED
	)

/datum/skills/CE
	name = "Chief Engineer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_POWERLOADER = SKILL_POWERLOADER_PRO
	)

/datum/skills/RO
	name = "Requisition Officer"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED
	)

/*
---------------------
MILITARY NONCOMBATANT
---------------------
*/

/datum/skills/doctor
	name = "Doctor"
	skills = list(
		SKILL_CQC = SKILL_CQC_WEAK,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_WEAK,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED
	)

/datum/skills/researcher
	name = "Researcher"
	skills = list(
		SKILL_CQC = SKILL_CQC_WEAK,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_WEAK,
		SKILL_SURGERY = SKILL_SURGERY_BEGINNER,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED
	)

/datum/skills/pilot
	name = "Pilot Officer"
	skills = list(
		SKILL_PILOT = SKILL_PILOT_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC
	)

/datum/skills/MP
	name = "Military Police"
	skills = list(
		SKILL_CQC = SKILL_CQC_MP,
		SKILL_POLICE = SKILL_POLICE_MP,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED
	)

/datum/skills/MT
	name = "Maintenance Technician"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER
	)

/datum/skills/CT
	name = "Cargo Technician"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_METAL,
		SKILL_POWERLOADER = SKILL_POWERLOADER_PRO
	)

/*
---------------------
SYNTHETIC
---------------------
*/

/datum/skills/synthetic
	name = "Synthetic"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_CMO,
		SKILL_SURGERY = SKILL_SURGERY_MASTER,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_PILOT = SKILL_PILOT_TRAINED,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_SMGS = SKILL_SMGS_TRAINED,
		SKILL_RIFLES = SKILL_RIFLES_TRAINED,
		SKILL_SHOTGUNS = SKILL_SHOTGUNS_TRAINED,
		SKILL_HEAVY_WEAPONS = SKILL_HEAVY_WEAPONS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_MP,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_LARGE_VEHICLE = SKILL_LARGE_VEHICLE_TRAINED
	)

/datum/skills/early_synthetic
	name = "Early Synthetic"
	skills = list(
		SKILL_CQC = SKILL_MELEE_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_EXPERT,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_PILOT = SKILL_PILOT_TRAINED,
		SKILL_POLICE = SKILL_POLICE_MP,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_LARGE_VEHICLE = SKILL_LARGE_VEHICLE_TRAINED
	)

/*
------------------------------
United States Colonial Marines
------------------------------
*/

/datum/skills/pfc
	name = "Private"
	//same as default

/datum/skills/pfc/crafty
	name = "Crafty Private"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_METAL,
		SKILL_ENGINEER = SKILL_ENGINEER_METAL
	)

/datum/skills/combat_medic
	name = "Combat Medic"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC
	)

/datum/skills/combat_medic/crafty
	name = "Crafty Combat Medic"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_METAL,
		SKILL_ENGINEER = SKILL_ENGINEER_METAL
	)

/datum/skills/combat_engineer
	name = "Combat Engineer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ADVANCED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER
	)

/datum/skills/smartgunner
	name = "Squad Smartgunner"
	skills = list(
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER
	)

/datum/skills/specialist
	name = "Squad Specialist"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_METAL,
		SKILL_ENGINEER = SKILL_ENGINEER_METAL, //to use c4 in scout set.
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED
	)

/datum/skills/SL
	name = "Squad Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_ENGINEER = SKILL_ENGINEER_PLASTEEL,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED
	)

/datum/skills/intel
	name = "Intelligence Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED
	)


/*
-------------------------
COLONIAL LIBERATION FRONT
-------------------------
*/

//NOTE: The CLF have less firearms skill, but compensate with additional civilian skills and resourcefulness

/datum/skills/clf
	name = "CLF Fighter"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_LARGE_VEHICLE = SKILL_LARGE_VEHICLE_TRAINED,
		SKILL_POLICE = SKILL_POLICE_MP,
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED
	)

/datum/skills/clf/combat_medic
	name = "CLF Medic"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_CMO,
		SKILL_SURGERY = SKILL_SURGERY_MASTER
	)

/datum/skills/clf/leader
	name = "CLF Leader"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED
	)

/*
-----------
FREELANCERS
-----------
*/

//NOTE: Freelancer training is similar to the USCM's, but with additional construction skills

/datum/skills/freelancer
	name = "Freelancer Private"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI
	)

/datum/skills/freelancer/combat_medic
	name = "Freelancer Medic"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC
	)

/datum/skills/freelancer/SL
	name = "Freelancer Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM
	)

/*
--------------------------
UNITED PROGRESSIVE PEOPLES
--------------------------
*/

//NOTE: UPP training is similar to the USCM's, but with additional construction skills

/datum/skills/upp
	name = "UPP Private"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/upp/combat_medic
	name = "UPP Medic"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/upp/specialist
	name = "UPP Specialist"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/upp/SL
	name = "UPP Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/*
----------------------------
Private Military Contractors
----------------------------
*/

//NOTE: Compared to the USCM, PMCs have additional firearms training, construction skills and policing skills

/datum/skills/pmc
	name = "PMC Private"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_MP,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/pmc/smartgunner
	name = "PMC Smartgunner"
	skills = list(
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/pmc/specialist
	name = "PMC Specialist"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_SMARTGUN = SKILL_SMART_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/pmc/SL
	name = "PMC Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/*
---------------------
SPEC-OPS
---------------------
*/

/datum/skills/commando
	name = "Commando"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_SMGS = SKILL_SMGS_TRAINED,
		SKILL_RIFLES = SKILL_RIFLES_TRAINED,
		SKILL_SHOTGUNS = SKILL_SHOTGUNS_TRAINED,
		SKILL_HEAVY_WEAPONS = SKILL_HEAVY_WEAPONS_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)

/datum/skills/commando/medic
	name = "Commando Medic"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC
	)

/datum/skills/commando/leader
	name = "Commando Leader"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED
	)

/datum/skills/commando/deathsquad
	name = "Deathsquad"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_SMARTGUN = SKILL_SMART_MASTER,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC
	)

/datum/skills/spy
	name = "Spy"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_SMGS = SKILL_SMGS_TRAINED,
		SKILL_RIFLES = SKILL_RIFLES_TRAINED,
		SKILL_SHOTGUNS = SKILL_SHOTGUNS_TRAINED,
		SKILL_HEAVY_WEAPONS = SKILL_HEAVY_WEAPONS_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ADVANCED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED
	)

/datum/skills/ninja
	name = "Ninja"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_METAL,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER
	)

/*
---------------------
MISCELLANEOUS
---------------------
*/

/datum/skills/mercenary
	name = "Mercenary"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_SMGS = SKILL_SMGS_TRAINED,
		SKILL_RIFLES = SKILL_RIFLES_TRAINED,
		SKILL_SHOTGUNS = SKILL_SHOTGUNS_TRAINED,
		SKILL_HEAVY_WEAPONS = SKILL_HEAVY_WEAPONS_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED
	)

/datum/skills/tank_crew
	name = "Tank Crew"
	skills = list(
		SKILL_LARGE_VEHICLE = SKILL_LARGE_VEHICLE_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_POWERLOADER = SKILL_POWERLOADER_DABBLING,
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED
	)

/datum/skills/gladiator
	name = "Gladiator"
	skills = list(
		SKILL_CQC = SKILL_CQC_MP,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_NOVICE,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)

/datum/skills/gladiator/champion
	name = "Gladiator Champion"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)

/datum/skills/gladiator/champion/leader
	name = "Gladiator Leader"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER, //Spartacus!
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)

/datum/skills/yautja/warrior
	name = "Yautja Warrior"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_MT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_CMO,
		SKILL_SURGERY = SKILL_SURGERY_MASTER,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_SMGS = SKILL_SMGS_TRAINED,
		SKILL_RIFLES = SKILL_RIFLES_TRAINED,
		SKILL_POLICE = SKILL_POLICE_MP
	)

/datum/skills/dutch
	name = "Dutch"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_PLASTEEL,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_CHEM,
		SKILL_PISTOLS = SKILL_PISTOLS_TRAINED,
		SKILL_SMGS = SKILL_SMGS_TRAINED,
		SKILL_RIFLES = SKILL_RIFLES_TRAINED,
		SKILL_SHOTGUNS = SKILL_SHOTGUNS_TRAINED,
		SKILL_HEAVY_WEAPONS = SKILL_HEAVY_WEAPONS_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR
	)