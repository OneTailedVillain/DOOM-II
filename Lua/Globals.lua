local toDeclare = {
	DF_DROPPED = 1,
	DF_NOBLOOD = 2,
	DF_CORPSE = 4,
	DF_COUNTKILL = 8,
	DF_COUNTITEM = 16,
	DF_ALWAYSPICKUP = 32,
	DF_DROPOFF = 64,
	DF_JUSTHIT = 128,
	DF_SHADOW = 256,
	pw_strength = 1,
	pw_ironfeet = 2,
}

for k, v in pairs(toDeclare) do
	rawset(_G, k, v)
end

if not doom then
	rawset(_G, "doom", {})
end
doom.gameskill = 0
doom.killcount = 0
doom.kills = 0
doom.respawnmonsters = false
doom.defaultgravity = FRACUNIT
doom.weapons = {}
doom.KEY_RED = 1
doom.KEY_BLUE = 2
doom.KEY_YELLOW = 4
doom.KEY_SKULLRED = 8
doom.KEY_SKULLBLUE = 16
doom.KEY_SKULLYELLOW = 32
doom.thinkers = {}
doom.texturesByNum = {}
doom.weaponnames = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	[6] = {},
	[7] = {},
}
doom.sectorspecials = {}
doom.sectorbackups = {}

doom.validcount = 0
doom.sectordata = {}

local wepBase = {
	sprite = SPR_PISG,
	weaponslot = 2,
	order = 1,
	damage = {5, 15},
	raycaster = true,
	shotcost = 1,
	pellets = 1,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = A, tics = INT32_MAX},
		},
		attack = {
			{frame = B, tics = 4},
			{frame = C, tics = 4, action = A_DoomPunch},
			{frame = D, tics = 5},
			{frame = C, tics = 4},
			{frame = B, tics = 5, action = A_DoomReFire},
		}
	},
	ammotype = "bullets",
}

function doom.addWeapon(wepname, properties)
	setmetatable(properties, { __index = wepBase })
	doom.weapons[wepname] = properties
	local wepslot = properties.weaponslot
	local weporder = properties.order
	doom.weaponnames[wepslot][weporder] = wepname
end

doom.ammos = {}

local ammoBase = {
    max = 200,
	icon = "SBOAMMO1"
}

setmetatable(ammoBase, {
    __index = function(t, k)
        if k == "backpackmax" then
            return t.max * 2
        end
		/*
        if k == "backpackicon" then
            return t.icon
        end
		*/
    end
})

function doom.addAmmo(ammoname, properties)
    setmetatable(properties, { __index = ammoBase })
    doom.ammos[ammoname] = properties
end

doom.strings = {
GOTARMOR = "Put on a force field vest.",
GOTMEGA = "Put on the attuned force field armor!",
GOTHTHBONUS = "Health boosted!",
GOTARMBONUS = "Armor boosted!",
GOTSTIM = "Took a health refill.",
GOTMEDINEED = "Took a large health refill. Never give up!",
GOTMEDIKIT = "Took a large health refill.",
GOTSUPER = "Ectoplasmic surge!",
GOTBLUECARD = "Blue passcard secured!",
GOTYELWCARD = "Yellow passcard secured!",
GOTREDCARD = "Red passcard secured!",
GOTBLUESKUL = "Blue skeleton key secured!",
GOTYELWSKUL = "Yellow skeleton key secured!",
GOTREDSKULL = "Red skeleton key secured!",
GOTINVUL = "Vanguard of the gods!",
GOTBERSERK = "Smash them to pieces!",
GOTINVIS = "Invisibility!",
GOTSUIT = "Rescue operations suit.",
GOTMAP = "Area survey map.",
GOTVISOR = "Low-light goggles.",
GOTMSPHERE = "Negentropic surge!",
GOTCLIP = "Picked up some bullets.",
GOTCLIPBOX = "Picked up a case of bullets.",
GOTROCKET = "Picked up a missile.",
GOTROCKBOX = "Picked up a crate of missiles.",
GOTCELL = "Picked up an energy recharge.",
GOTCELLBOX = "Picked up a large energy recharge.",
GOTSHELLS = "Picked up some shotgun shells.",
GOTSHELLBOX = "Picked up a box of shotgun shells.",
GOTBACKPACK = "A backpack for all your ammo storage needs!",
GOTBFG9000 = "Got the SKAG 1337... time to kick some ass!",
GOTCHAINGUN = "Got the minigun!",
GOTCHAINSAW = "Got the ripsaw!",
GOTLAUNCHER = "Got the missile launcher!",
GOTPLASMA = "Got the polaric energy weapon!",
GOTSHOTGUN = "Got the pump-action shotgun!",
GOTSHOTGUN2 = "Got the double-barrelled shotgun!",
TAG_FIST = "fist",
TAG_BFG9000 = "SKAG 1337",
TAG_CHAINGUN = "minigun",
TAG_CHAINSAW = "ripsaw",
TAG_ROCKETLAUNCHER = "missile launcher",
TAG_PLASMARIFLE = "polaric energy weapon",
TAG_SHOTGUN = "pump-action shotgun",
TAG_SUPERSHOTGUN = "double-barrelled shotgun",
PD_BLUEO = "Blue key needed.",
PD_REDO = "Red key needed.",
PD_YELLOWO = "Yellow key needed.",
PD_BLUEK = "Blue key needed for this door.",
PD_REDK = "Red key needed for this door.",
PD_YELLOWK = "Yellow key needed for this door.",
PD_BLUEC = "Blue passcard needed for this door.",
PD_REDC = "Red passcard needed for this door.",
PD_YELLOWC = "Yellow passcard needed for this door.",
PD_BLUES = "Blue skeleton key needed for this door.",
PD_REDS = "Red skeleton key needed for this door.",
PD_YELLOWS = "Yellow skeleton key needed for this door.",
PD_ANY = "Any key will open this door.",
PD_ALL3 = "This door requires all three keys.",
PD_ALL6 = "This door requires all six keys!",

CC_ZOMBIE = "zombie",
CC_SHOTGUN = "shotgun zombie",
CC_HEAVY = "minigun zombie",
CC_IMP = "serpentipede",
CC_DEMON = "flesh worm",
CC_LOST = "hatchling",
CC_CACO = "trilobite",
CC_HELL = "pain bringer",
CC_BARON = "pain lord",
CC_ARACH = "technospider",
CC_PAIN = "matribite",
CC_REVEN = "octaminator",
CC_MANCU = "combat slug",
CC_ARCH = "necromancer",
CC_SPIDER = "large technospider",
CC_CYBER = "assault tripod",
CC_HERO = "savior of humanity",
HUSTR_1 = "MAP01: Hydroelectric Plant",
HUSTR_2 = "MAP02: Filtration Tunnels",
HUSTR_3 = "MAP03: Crude Processing Center",
HUSTR_4 = "MAP04: Containment Bay",
HUSTR_5 = "MAP05: Sludge Burrow",
HUSTR_6 = "MAP06: Janus Terminal",
HUSTR_7 = "MAP07: Logic Gate",
HUSTR_8 = "MAP08: Astronomy Complex",
HUSTR_9 = "MAP09: Datacenter",
HUSTR_10 = "MAP10: Deadly Outlands",
HUSTR_11 = "MAP11: Dimensional Rift Observatory",
HUSTR_12 = "MAP12: Railroads",
HUSTR_13 = "MAP13: Station Earth",
HUSTR_14 = "MAP14: Nuclear Zone",
HUSTR_15 = "MAP15: Hostile Takeover",
HUSTR_16 = "MAP16: Urban Jungle",
HUSTR_17 = "MAP17: City Capitol",
HUSTR_18 = "MAP18: Aquatics Lab",
HUSTR_19 = "MAP19: Sewage Control",
HUSTR_20 = "MAP20: Blood Ember Fortress",
HUSTR_21 = "MAP21: Under Realm",
HUSTR_22 = "MAP22: Remanasu",
HUSTR_23 = "MAP23: Underground Facility",
HUSTR_24 = "MAP24: Abandoned Teleporter Lab",
HUSTR_25 = "MAP25: Persistence of Memory",
HUSTR_26 = "MAP26: Dark Depths",
HUSTR_27 = "MAP27: Palace of Red",
HUSTR_28 = "MAP28: Grim Redoubt",
HUSTR_29 = "MAP29: Melting Point",
HUSTR_30 = "MAP30: Jaws of Defeat",
HUSTR_31 = "MAP31: Be Quiet",
HUSTR_32 = "MAP32: Not Sure",

HUSTR_PLRGREEN = "g:",
HUSTR_PLRINDIGO = "i:",
HUSTR_PLRBROWN = "b:",
HUSTR_PLRRED = "r:",
AMSTR_FOLLOWON = "Map following player.",
AMSTR_FOLLOWOFF = "Map no longer following player.",
AMSTR_GRIDON = "Map grid on.",
AMSTR_GRIDOFF = "Map grid off.",
AMSTR_MARKEDSPOT = "Added map bookmark.",
AMSTR_MARKSCLEARED = "All map bookmarks cleared.",
STSTR_MUS = "Music changed.",
STSTR_NOMUS = "Unknown music track?",
STSTR_DQDON = "God mode on.",
STSTR_DQDOFF = "God mode off.",
STSTR_KFAADDED = "Keys, weapons and ammo added.",
STSTR_FAADDED = "Weapons and ammo added.",
STSTR_NCON = "Noclip on.",
STSTR_NCOFF = "Noclip off.",
STSTR_CHOPPERS = "Vroom!",
STSTR_BEHOLD = "vanguard, smash, invis, rescue, area or light?",
NIGHTMARE = [[The game is not designed to be
            beatable at this skill level.

            Not recommended unless you're
            really that good - or bored.

            (Press Y to confirm)]],


-- # After MAP06, before MAP07:
C1TEXT = [[Not even Earth is safe. The monsters show
         up ahead of you everywhere you run.
         Where are they even coming from?

         Despite all the other destruction they've
         wrought, the teleportation infrastructure
         remains intact - you might be able to
         get back to civilization this way.

         You find an old pad and boot it up.
         Connection live. Handshake established.

         Growling and chittering on the intercom.

         Planted your feet.
         Checked your weapons.
         Time to punch through.]],
-- # After MAP11, before MAP12:
C2TEXT = [[You didn't find anyone alive. Again.

         The fighting is taking its toll on you.
         The pain. The brutality. The loneliness.
         There's got to be a way to somewhere,
         something that isn't... this.

         A train rumbles in the distance.

         You follow the sound down the empty road
         and reach the edge of a railyard.

         Trains mean cities.
         Cities mean people.

         Right?]],
-- # After MAP20, before MAP21:
C3TEXT = [[Here is no AGM but only monsters.
         Monsters, no humans and dusty days
         sleeping in old ruins and eating scraps.
         No one has escaped this wasteland alive.

         You've been tracking their movements.
         AGM records and alien scrawlings point
         to something big worming its way through
         the entire teleportation network.
         Sending its nightmare armies of brain-
         scrambled sapients - including humans -
         to conquer all known space.

         And now you're fighting at its doorstep.

         This could be the beginning
         of your freedom - or your doom.]],
-- # After MAP30 (endgame text):
C4TEXT = [[The evil thing becomes unstable.
         Its final roars echo throughout the room
         until it crumples into scrap metal.

         A targeting portal opens, blissfully
         unaware of its master's demise.

         On the other side you see a small town.
         You ditch your weapons and slip through,
         leaving AGM and all its horrors behind.

         No one will know who saved them.

         No one will know what happened here.

         No one will ever find you again.]],
-- MAP31 Secret
C5TEXT = [[You step into the teleporter. You feel a
         familiar flash and... you're in a cage?
         Jailed?

         There are other cages in here. Occupied.
         So is this how they capture humans?
         Or did they set this up specially for you,
         as a reward for being such a monkey wrench
         in their plans?
         The guards haven't noticed you - yet.
         Any noise could mean death. Or worse.

         When they zombify you, are you awake the
         entire time, locked inside of your brain?

         You'd rather not find out.]],
-- MAP32 Secret
C6TEXT = [[Forcibly uncaged again. Good job.

         But where are you? The air and gravity
         still feel like whatever planet that
         strange prison had been on.

         You look around and the layout triggers
         some old memories from history class.

         This is an arena.
         Where they send prisoners to die.
         That wasn't an exit - but an entrance.
         You will find your way back to the city,
         but it will have to be on the other side
         of a few homicidal mutants...]],
BGFLATE1 = "AQF051",
BGFLATE2 = "AQF054",
BGFLATE3 = "FLAT5_2",
BGFLATE4 = "AQF075",
BGFLAT06 = "AQF016",
BGFLAT11 = "AQF001",
BGFLAT20 = "FLAT5_6",
BGFLAT30 = "SLIME13",
BGFLAT15 = "AQF004",
BGFLAT31 = "AQF021",

DOSY = "(Press Y to exit the program.)",
QUITMSG = "AGM's investors are planning\nan even worse nightmare.\nPress Y if you don't care.",
QUITMSG1 = "Why would you...",
QUITMSG2 = "Hey buddy, there's still\nwork to be done.\nAre you sure you want to quit?",
QUITMSG3 = "Press N to keep\nannihilating aliens.\nPress Y to surrender.",
QUITMSG4 = "I wouldn't press Y if I were you.\nSocial media is much worse.",
QUITMSG5 = "If you leave now, it's over.",
QUITMSG6 = "If you give up, this\nfight will never end.\nWe still need you\nto restore our freedom.",
QUITMSG7 = "They'll never rest.\nWill you rest?",
QUITMSG8 = "What do you do with your life?",
QUITMSG9 = "Don't press Y!\nThere's an army of\nzombies on your desktop!",
QUITMSG10 = "Your revenge is unsatisfied.\nAre you sure you want to quit?",
QUITMSG11 = "Press Y to let AGM decimate\nEarth with their monstrosities.",
QUITMSG12 = "Don't quit!\nMonsters will kill\nyou while you sleep.",
QUITMSG13 = "Do you think you can\nwalk away just like that?",
QUITMSG14 = "Not even going to\nstay for Deathmatch?",

SKILL_BABY = "Please don't kill me!",
SKILL_EASY = "Will this hurt?",
SKILL_NORMAL = "Bring on the pain.",
SKILL_HARD = "Extreme Carnage.",
SKILL_NIGHTMARE = "MAYHEM!",
TXT_D1E1 = "Outpost Outbreak",
TXT_D1E2 = "Military Labs",
TXT_D1E3 = "Event Horizon",
TXT_D1E4 = "Double Impact",
TXT_D2E1 = "Phase 2",
}

doom.endoom = doom.endoom or {}
doom.endoom.text = {
    "",
    "",
    "  " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. "                                                      " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. "    " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176),
    "  " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. "    " .. string.char(176) .. string.char(177) .. "                                                      " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(177) .. "    " .. string.char(177) .. string.char(177) .. string.char(177) .. string.char(176),
    "   " .. string.char(178) .. string.char(178) .. string.char(176) .. "                                                             " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. "  " .. string.char(176) .. string.char(178) .. string.char(178) .. string.char(178),
    "   " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. "  " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. " " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. " " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. " " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. "   " .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(178) .. string.char(176) .. "  " .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(178) .. string.char(176) .. "   " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. string.char(176) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178),
    "   " .. string.char(177) .. string.char(177) .. string.char(176) .. "       " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. " " .. string.char(176) .. string.char(177) .. string.char(177) .. " " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. "   " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. "   " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. " " .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(176) .. "  " .. string.char(176) .. string.char(219) .. string.char(178) .. string.char(176) .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(176) .. "  " .. string.char(176) .. string.char(219) .. string.char(178) .. string.char(176) .. "  " .. string.char(177) .. string.char(177) .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(177) .. string.char(177) .. string.char(176) .. string.char(177) .. string.char(177),
    "   " .. string.char(176) .. string.char(176) .. "         " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. "  " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. "  " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. "  " .. string.char(176) .. string.char(176) .. "  " .. string.char(176) .. string.char(176) .. string.char(176) .. " " .. string.char(178) .. string.char(219) .. string.char(176) .. "    " .. string.char(176) .. string.char(219) .. string.char(178) .. string.char(178) .. string.char(219) .. string.char(176) .. "    " .. string.char(176) .. string.char(219) .. string.char(178) .. "  " .. string.char(176) .. string.char(176) .. " " .. string.char(176) .. string.char(176) .. string.char(176) .. string.char(176) .. " " .. string.char(176) .. string.char(176),
    "  " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. "       " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(177) .. " " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. "   " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. "   " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. " " .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(176) .. "  " .. string.char(176) .. string.char(219) .. string.char(178) .. string.char(176) .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(176) .. "  " .. string.char(176) .. string.char(219) .. string.char(178) .. string.char(176) .. " " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176) .. " " .. string.char(176) .. string.char(176) .. " " .. string.char(176) .. string.char(177) .. string.char(177) .. string.char(176),
    "  " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. "      " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. string.char(178) .. string.char(178) .. string.char(176) .. " " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. " " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. " " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. "   " .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(178) .. string.char(176) .. "  " .. string.char(176) .. string.char(178) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(219) .. string.char(178) .. string.char(176) .. "  " .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(176) .. "  " .. string.char(176) .. string.char(178) .. string.char(178) .. string.char(178) .. string.char(178),
    "",
    " " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(203) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(203) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
    "                           " .. string.char(186) .. "   freedoom.github.io   " .. string.char(186),
    "                           " .. string.char(200) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(188),
    "          " .. string.char(201) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(187),
    "          " .. string.char(186) .. "   Freedoom is a free and libre game project for the Doom  " .. string.char(186),
    "          " .. string.char(186) .. "   engine, made available under the BSD 3-clause licence.  " .. string.char(186),
    "          " .. string.char(200) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(188),
    "        " .. string.char(201) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(187),
    "        " .. string.char(186) .. "   For the full terms of the licence, please see COPYING.txt.  " .. string.char(186),
    "        " .. string.char(186) .. "   For the full list of contributors, please see CREDITS.txt.  " .. string.char(186),
    "        " .. string.char(200) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(188),
    "       " .. string.char(201) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(187),
    "       " .. string.char(186) .. " Development builds can be downloaded at freedoom.soulsphere.org." .. string.char(186),
    "       " .. string.char(200) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(205) .. string.char(188),
}

doom.endoom.colors = {
    {{0,80}},
    {{0,80}},
    {{0,2},{15,9},{7,1},{0,54},{15,3},{7,1},{0,4},{7,1},{15,3},{0,2}},
    {{0,2},{7,1},{15,2},{7,1},{0,4},{7,1},{15,1},{0,54},{7,1},{15,3},{0,4},{15,3},{7,1},{0,2}},
    {{0,3},{15,2},{7,1},{0,61},{15,3},{7,1},{0,2},{7,1},{15,3},{0,3}},
    {{0,3},{15,7},{7,1},{0,2},{15,7},{7,1},{0,1},{15,6},{0,1},{15,6},{0,1},{15,6},{7,1},{0,3},{6,8},{0,2},{6,8},{0,3},{15,4},{7,2},{15,4},{0,3}},
    {{0,3},{15,2},{7,1},{0,7},{7,1},{15,2},{7,1},{0,1},{7,1},{15,2},{0,1},{7,1},{15,2},{7,1},{0,3},{7,1},{15,2},{7,1},{0,3},{7,1},{15,2},{7,2},{15,2},{7,1},{0,1},{6,4},{0,2},{6,8},{0,2},{6,4},{0,2},{15,2},{7,1},{15,4},{7,1},{15,2},{0,3}},
    {{0,3},{15,2},{0,9},{15,6},{7,1},{0,2},{15,5},{0,2},{15,5},{0,2},{15,2},{0,2},{7,1},{15,2},{0,1},{6,3},{0,4},{6,6},{0,4},{6,3},{0,2},{15,2},{0,1},{7,1},{15,2},{7,1},{0,1},{15,2},{0,3}},
    {{0,2},{7,1},{15,2},{7,1},{0,7},{7,1},{15,2},{7,2},{15,3},{0,1},{7,1},{15,2},{7,1},{0,3},{7,1},{15,2},{7,1},{0,3},{7,1},{15,2},{7,2},{15,2},{7,1},{0,1},{6,4},{0,2},{6,8},{0,2},{6,4},{0,1},{7,1},{15,2},{7,1},{0,1},{7,2},{0,1},{7,1},{15,2},{7,1},{0,2}},
    {{0,2},{15,4},{7,1},{0,6},{15,4},{7,1},{15,2},{7,1},{0,1},{15,6},{0,1},{15,6},{0,1},{15,6},{7,1},{0,3},{6,8},{0,2},{6,8},{0,2},{15,4},{7,1},{0,2},{7,1},{15,4},{0,2}},
    {{0,80}},
    {{0,1},{8,78},{0,1}},
    {{0,27},{8,1},{0,3},{7,18},{0,3},{8,1},{0,27}},
    {{0,27},{8,26},{0,27}},
    {{0,10},{4,61},{0,9}},
    {{0,10},{4,1},{0,3},{9,54},{0,2},{4,1},{0,9}},
    {{0,10},{4,1},{0,3},{9,54},{0,2},{4,1},{0,9}},
    {{0,10},{4,61},{0,9}},
    {{0,8},{4,65},{0,7}},
    {{0,8},{4,1},{0,3},{8,26},{7,7},{8,13},{7,7},{8,5},{0,2},{4,1},{0,7}},
    {{0,8},{4,1},{0,3},{8,21},{7,12},{8,13},{7,7},{8,5},{0,2},{4,1},{0,7}},
    {{0,8},{4,65},{0,7}},
    {{0,7},{8,67},{0,6}},
    {{0,7},{8,1},{0,1},{9,19},{1,21},{9,23},{1,1},{8,1},{0,6}},
    {{0,7},{8,67},{0,6}},
}

doom.rndtable = {
    0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66 ,
    74,  21, 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36 ,
    95, 110,  85,  48, 212, 140, 211, 249,  22,  79, 200,  50,  28, 188 ,
    52, 140, 202, 120,  68, 145,  62,  70, 184, 190,  91, 197, 152, 224 ,
    149, 104,  25, 178, 252, 182, 202, 182, 141, 197,   4,  81, 181, 242 ,
    145,  42,  39, 227, 156, 198, 225, 193, 219,  93, 122, 175, 249,   0 ,
    175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135,   2, 235 ,
    25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113 ,
    94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75 ,
    136, 156,  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196 ,
    135, 106,  63, 197, 195,  86,  96, 203, 113, 101, 170, 247, 181, 113 ,
    80, 250, 108,   7, 255, 237, 129, 226,  79, 107, 112, 166, 103, 241 ,
    24, 223, 239, 120, 198,  58,  60,  82, 128,   3, 184,  66, 143, 224 ,
    145, 224,  81, 206, 163,  45,  63,  90, 168, 114,  59,  33, 159,  95 ,
    28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14, 109, 226 ,
    71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36 ,
    17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106 ,
    197, 242,  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136 ,
    120, 163, 236, 249
}
doom.prndindex = 0