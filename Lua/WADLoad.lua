-- simple FNV-1a hash (fast, low overhead, good for strings)
local function fnv1a(str)
	local hash = 2166136261
	for i = 1, #str do
		hash = hash ^^ string.byte(str, i)
		hash = (hash * 16777619)
	end
	return hash
end

-- precompute the hash of your custom ENDOOM text
local function hashEndoom(tbl)
	-- join into one string for stable hashing
	return fnv1a(table.concat(tbl, "\n"))
end

local SRB2EndoomHash = hashEndoom({
    string.char(20) .. string.char(20) .. "                         Sonic Robo Blast",
    "                                  2",
    "",
    "                         By Sonic Team Junior",
    "",
    "                      http://stjr.segasonic.net",
    "",
    "    Come to our website to download                               ________",
    "    expansion packs, other's add-ons                                       |",
    "    and instructions on how to make                                        |",
    "    your own SRB2 levels!                                                  |",
    "                                                                           |",
    "",
    "",
    "",
    "",
    "    Sonic the Hedgehog, all characters",
    "    and related indica are (c) Sega",
    "    Enterprises, Ltd. Sonic Team Jr. is",
    "    not affiliated with Sega in any way.",
    "",
    "",
    "",
    "",
    "",
})

local function doLoadingShit()
	doom.patchesLoaded = false -- We'll have to run this back anyhow...
	if doom.basewad != false then return end

	-- check if ENDOOM matches with SRB2.WAD
	local currentHash = hashEndoom(doom.endoom.text or {})
	if currentHash == SRB2EndoomHash then
		-- Autopatch to better support SRB2 March 2000 Prototype
		-- Currently only has the Mine Maze fake FOF object
		doom.defaultgravity = FRACUNIT/2
		doom.issrb2 = true
		local inf = mobjinfo[MT_DOOM_REDPILLARWITHSKULL]
		inf.radius = 64*FRACUNIT
		inf.height = 1*FRACUNIT
		inf.flags = MF_SOLID|MF_FLOAT|MF_NOGRAVITY|MF_NOSECTOR
		inf.mass = 10000000
		states[S_DOOM_REDPILLARWITHSKULL_1].sprite = SPR_NULL
		local inf = mobjinfo[MT_DOOM_HEALTHBONUS]
		inf.flags = $|MF_NOGRAVITY
	end

	doom.strings = {
		-- P_inter.C
		GOTARMOR      = "Picked up the armor.",
		GOTMEGA       = "Picked up the MegaArmor!",
		GOTHTHBONUS   = "Picked up a health bonus.",
		GOTARMBONUS   = "Picked up an armor bonus.",
		GOTSTIM       = "Picked up a stimpack.",
		GOTMEDINEED   = "Picked up a medikit that you REALLY need!",
		GOTMEDIKIT    = "Picked up a medikit.",
		GOTSUPER      = "Supercharge!",

		GOTBLUECARD   = "Picked up a blue keycard.",
		GOTYELWCARD   = "Picked up a yellow keycard.",
		GOTREDCARD    = "Picked up a red keycard.",
		GOTBLUESKUL   = "Picked up a blue skull key.",
		GOTYELWSKUL   = "Picked up a yellow skull key.",
		GOTREDSKULL   = "Picked up a red skull key.",

		GOTINVUL      = "Invulnerability!",
		GOTBERSERK    = "Berserk!",
		GOTINVIS      = "Partial Invisibility",
		GOTSUIT       = "Radiation Shielding Suit",
		GOTMAP        = "Computer Area Map",
		GOTVISOR      = "Light Amplification Visor",
		GOTMSPHERE    = "MegaSphere!",

		GOTCLIP       = "Picked up a clip.",
		GOTCLIPBOX    = "Picked up a box of bullets.",
		GOTROCKET     = "Picked up a rocket.",
		GOTROCKBOX    = "Picked up a box of rockets.",
		GOTCELL       = "Picked up an energy cell.",
		GOTCELLBOX    = "Picked up an energy cell pack.",
		GOTSHELLS     = "Picked up 4 shotgun shells.",
		GOTSHELLBOX   = "Picked up a box of shotgun shells.",
		GOTBACKPACK   = "Picked up a backpack full of ammo!",

		GOTBFG9000    = "You got the BFG9000!  Oh, yes.",
		GOTCHAINGUN   = "You got the chaingun!",
		GOTCHAINSAW   = "A chainsaw!  Find some meat!",
		GOTLAUNCHER   = "You got the rocket launcher!",
		GOTPLASMA     = "You got the plasma gun!",
		GOTSHOTGUN    = "You got the shotgun!",
		GOTSHOTGUN2   = "You got the super shotgun!",

		-- P_Doors.C
		PD_BLUEO      = "You need a blue key to activate this object",
		PD_REDO       = "You need a red key to activate this object",
		PD_YELLOWO    = "You need a yellow key to activate this object",
		PD_BLUEK      = "You need a blue key to open this door",
		PD_REDK       = "You need a red key to open this door",
		PD_YELLOWK    = "You need a yellow key to open this door",

		-- G_game.C
		GGSAVED       = "game saved.",

		-- HU_stuff.C
		HUSTR_MSGU    = "[Message unsent]",

		HUSTR_E1M1    = "E1M1: Hangar",
		HUSTR_E1M2    = "E1M2: Nuclear Plant",
		HUSTR_E1M3    = "E1M3: Toxin Refinery",
		HUSTR_E1M4    = "E1M4: Command Control",
		HUSTR_E1M5    = "E1M5: Phobos Lab",
		HUSTR_E1M6    = "E1M6: Central Processing",
		HUSTR_E1M7    = "E1M7: Computer Station",
		HUSTR_E1M8    = "E1M8: Phobos Anomaly",
		HUSTR_E1M9    = "E1M9: Military Base",

		HUSTR_E2M1    = "E2M1: Deimos Anomaly",
		HUSTR_E2M2    = "E2M2: Containment Area",
		HUSTR_E2M3    = "E2M3: Refinery",
		HUSTR_E2M4    = "E2M4: Deimos Lab",
		HUSTR_E2M5    = "E2M5: Command Center",
		HUSTR_E2M6    = "E2M6: Halls of the Damned",
		HUSTR_E2M7    = "E2M7: Spawning Vats",
		HUSTR_E2M8    = "E2M8: Tower of Babel",
		HUSTR_E2M9    = "E2M9: Fortress of Mystery",

		HUSTR_E3M1    = "E3M1: Hell Keep",
		HUSTR_E3M2    = "E3M2: Slough of Despair",
		HUSTR_E3M3    = "E3M3: Pandemonium",
		HUSTR_E3M4    = "E3M4: House of Pain",
		HUSTR_E3M5    = "E3M5: Unholy Cathedral",
		HUSTR_E3M6    = "E3M6: Mt. Erebus",
		HUSTR_E3M7    = "E3M7: Limbo",
		HUSTR_E3M8    = "E3M8: Dis",
		HUSTR_E3M9    = "E3M9: Warrens",

		HUSTR_E4M1    = "E4M1: Hell Beneath",
		HUSTR_E4M2    = "E4M2: Perfect Hatred",
		HUSTR_E4M3    = "E4M3: Sever The Wicked",
		HUSTR_E4M4    = "E4M4: Unruly Evil",
		HUSTR_E4M5    = "E4M5: They Will Repent",
		HUSTR_E4M6    = "E4M6: Against Thee Wickedly",
		HUSTR_E4M7    = "E4M7: And Hell Followed",
		HUSTR_E4M8    = "E4M8: Unto The Cruel",
		HUSTR_E4M9    = "E4M9: Fear",

		HUSTR_1       = "level 1: entryway",
		HUSTR_2       = "level 2: underhalls",
		HUSTR_3       = "level 3: the gantlet",
		HUSTR_4       = "level 4: the focus",
		HUSTR_5       = "level 5: the waste tunnels",
		HUSTR_6       = "level 6: the crusher",
		HUSTR_7       = "level 7: dead simple",
		HUSTR_8       = "level 8: tricks and traps",
		HUSTR_9       = "level 9: the pit",
		HUSTR_10      = "level 10: refueling base",
		HUSTR_11      = "level 11: 'o' of destruction!",

		HUSTR_12      = "level 12: the factory",
		HUSTR_13      = "level 13: downtown",
		HUSTR_14      = "level 14: the inmost dens",
		HUSTR_15      = "level 15: industrial zone",
		HUSTR_16      = "level 16: suburbs",
		HUSTR_17      = "level 17: tenements",
		HUSTR_18      = "level 18: the courtyard",
		HUSTR_19      = "level 19: the citadel",
		HUSTR_20      = "level 20: gotcha!",

		HUSTR_21      = "level 21: nirvana",
		HUSTR_22      = "level 22: the catacombs",
		HUSTR_23      = "level 23: barrels o' fun",
		HUSTR_24      = "level 24: the chasm",
		HUSTR_25      = "level 25: bloodfalls",
		HUSTR_26      = "level 26: the abandoned mines",
		HUSTR_27      = "level 27: monster condo",
		HUSTR_28      = "level 28: the spirit world",
		HUSTR_29      = "level 29: the living end",
		HUSTR_30      = "level 30: icon of sin",

		HUSTR_31      = "level 31: wolfenstein",
		HUSTR_32      = "level 32: grosse",

		PHUSTR_1      = "level 1: congo",
		PHUSTR_2      = "level 2: well of souls",
		PHUSTR_3      = "level 3: aztec",
		PHUSTR_4      = "level 4: caged",
		PHUSTR_5      = "level 5: ghost town",
		PHUSTR_6      = "level 6: baron's lair",
		PHUSTR_7      = "level 7: caughtyard",
		PHUSTR_8      = "level 8: realm",
		PHUSTR_9      = "level 9: abattoire",
		PHUSTR_10     = "level 10: onslaught",
		PHUSTR_11     = "level 11: hunted",

		PHUSTR_12     = "level 12: speed",
		PHUSTR_13     = "level 13: the crypt",
		PHUSTR_14     = "level 14: genesis",
		PHUSTR_15     = "level 15: the twilight",
		PHUSTR_16     = "level 16: the omen",
		PHUSTR_17     = "level 17: compound",
		PHUSTR_18     = "level 18: neurosphere",
		PHUSTR_19     = "level 19: nme",
		PHUSTR_20     = "level 20: the death domain",

		PHUSTR_21     = "level 21: slayer",
		PHUSTR_22     = "level 22: impossible mission",
		PHUSTR_23     = "level 23: tombstone",
		PHUSTR_24     = "level 24: the final frontier",
		PHUSTR_25     = "level 25: the temple of darkness",
		PHUSTR_26     = "level 26: bunker",
		PHUSTR_27     = "level 27: anti-christ",
		PHUSTR_28     = "level 28: the sewers",
		PHUSTR_29     = "level 29: odyssey of noises",
		PHUSTR_30     = "level 30: the gateway of hell",

		PHUSTR_31     = "level 31: cyberden",
		PHUSTR_32     = "level 32: go 2 it",

		THUSTR_1      = "level 1: system control",
		THUSTR_2      = "level 2: human bbq",
		THUSTR_3      = "level 3: power control",
		THUSTR_4      = "level 4: wormhole",
		THUSTR_5      = "level 5: hanger",
		THUSTR_6      = "level 6: open season",
		THUSTR_7      = "level 7: prison",
		THUSTR_8      = "level 8: metal",
		THUSTR_9      = "level 9: stronghold",
		THUSTR_10     = "level 10: redemption",
		THUSTR_11     = "level 11: storage facility",

		THUSTR_12     = "level 12: crater",
		THUSTR_13     = "level 13: nukage processing",
		THUSTR_14     = "level 14: steel works",
		THUSTR_15     = "level 15: dead zone",
		THUSTR_16     = "level 16: deepest reaches",
		THUSTR_17     = "level 17: processing area",
		THUSTR_18     = "level 18: mill",
		THUSTR_19     = "level 19: shipping/respawning",
		THUSTR_20     = "level 20: central processing",

		THUSTR_21     = "level 21: administration center",
		THUSTR_22     = "level 22: habitat",
		THUSTR_23     = "level 23: lunar mining project",
		THUSTR_24     = "level 24: quarry",
		THUSTR_25     = "level 25: baron's den",
		THUSTR_26     = "level 26: ballistyx",
		THUSTR_27     = "level 27: mount pain",
		THUSTR_28     = "level 28: heck",
		THUSTR_29     = "level 29: river styx",
		THUSTR_30     = "level 30: last call",

		THUSTR_31     = "level 31: pharaoh",
		THUSTR_32     = "level 32: caribbean",

		HUSTR_CHATMACRO1 = "I'm ready to kick butt!",
		HUSTR_CHATMACRO2 = "I'm OK.",
		HUSTR_CHATMACRO3 = "I'm not looking too good!",
		HUSTR_CHATMACRO4 = "Help!",
		HUSTR_CHATMACRO5 = "You suck!",
		HUSTR_CHATMACRO6 = "Next time, scumbag...",
		HUSTR_CHATMACRO7 = "Come here!",
		HUSTR_CHATMACRO8 = "I'll take care of it.",
		HUSTR_CHATMACRO9 = "Yes",
		HUSTR_CHATMACRO0 = "No",

		HUSTR_TALKTOSELF1 = "You mumble to yourself",
		HUSTR_TALKTOSELF2 = "Who's there?",
		HUSTR_TALKTOSELF3 = "You scare yourself",
		HUSTR_TALKTOSELF4 = "You start to rave",
		HUSTR_TALKTOSELF5 = "You've lost it...",

		HUSTR_MESSAGESENT = "[Message Sent]",

		HUSTR_PLRGREEN = "Green: ",
		HUSTR_PLRINDIGO = "Indigo: ",
		HUSTR_PLRBROWN = "Brown: ",
		HUSTR_PLRRED   = "Red: ",

		HUSTR_KEYGREEN  = "g",
		HUSTR_KEYINDIGO = "i",
		HUSTR_KEYBROWN  = "b",
		HUSTR_KEYRED    = "r",

		-- AM_map.C
		AMSTR_FOLLOWON    = "Follow Mode ON",
		AMSTR_FOLLOWOFF   = "Follow Mode OFF",

		AMSTR_GRIDON      = "Grid ON",
		AMSTR_GRIDOFF     = "Grid OFF",

		AMSTR_MARKEDSPOT  = "Marked Spot",
		AMSTR_MARKSCLEARED= "All Marks Cleared",

		-- ST_stuff.C
		STSTR_MUS       = "Music Change",
		STSTR_NOMUS     = "IMPOSSIBLE SELECTION",
		STSTR_DQDON     = "Degreelessness Mode On",
		STSTR_DQDOFF    = "Degreelessness Mode Off",

		STSTR_KFAADDED  = "Very Happy Ammo Added",
		STSTR_FAADDED   = "Ammo (no keys) Added",

		STSTR_NCON      = "No Clipping Mode ON",
		STSTR_NCOFF     = "No Clipping Mode OFF",

		STSTR_BEHOLD    = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp",
		STSTR_BEHOLDX   = "Power-up Toggled",

		STSTR_CHOPPERS  = "... doesn't suck - GM",
		STSTR_CLEV      = "Changing Level..."
	}
end

addHook("AddonLoaded", doLoadingShit)
doLoadingShit()