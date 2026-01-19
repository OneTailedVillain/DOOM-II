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
	DF_DMRESPAWN = 1536, -- DF_DMRESPAWN|DF_DM2RESPAWN
	DF_DM2RESPAWN = 1024,
	DF_INFLOAT = 2048,
	DF_TELEPORT = 4096,
	pw_strength = 1,
	pw_ironfeet = 2,
	pw_invisibility = 3,
	pw_infrared = 4,
	DML_BLOCKING = 1,
	DML_BLOCKMONSTERS = 2,
	DML_TWOSIDED = 4,
	DML_DONTPEGTOP = 8,
	DML_DONTPEGBOTTOM = 16,
	DML_SECRET = 32,
	DML_SOUNDBLOCK = 64,
	DML_DONTDRAW = 128,
	DML_MAPPED = 256,
    CF_GODMODE = 1,
}

for k, v in pairs(toDeclare) do
	rawset(_G, k, v)
end

if not doom then
	rawset(_G, "doom", {})
end
---@type doomglobal_t
doom = doom or {}

doom.mapString = "HUSTR_"
doom.gameskill = 3
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
doom.subthinkers = {}
doom.texturesByNum = {}
doom.torespawn = {}
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

-- local lastBitFlag = INT32_MAX + 1

local lastBitFlag = 1

-- Maybe attempt to get the last bit flag in case of a future move to 64-bit integers? Or maybe if SRB2 moves to 16 bit for some reason
repeat
    lastBitFlag = lastBitFlag << 1
until lastBitFlag <= 0 -- overflowed

lastBitFlag = lastBitFlag >> 1

doom.damagetypes = {
    fall = 1,                  -- Fall damage
    crush = 2,                 -- Crushing damage
    explodesplash = 3,         -- Explosion splash damage
    telefrag = 4,              -- Telefrag damage
    slime = 5,                 -- Slime/acid damage
    fire = 6,                  -- Fire damage
    exit = 7,                  -- "Attempt to leave the level" damage
    instakill = 0x80000000,    -- Special: direct health zeroing
}

doom.validcount = 0
doom.sectordata = {}
doom.gamemode = "commercial" -- Assume Doom II by default

doom.switchTexNames = {
    // Doom shareware episode 1 switches
    {"SW1BRCOM",	"SW2BRCOM",	1},
    {"SW1BRN1",	"SW2BRN1",	1},
    {"SW1BRN2",	"SW2BRN2",	1},
    {"SW1BRNGN",	"SW2BRNGN",	1},
    {"SW1BROWN",	"SW2BROWN",	1},
    {"SW1COMM",	"SW2COMM",	1},
    {"SW1COMP",	"SW2COMP",	1},
    {"SW1DIRT",	"SW2DIRT",	1},
    {"SW1EXIT",	"SW2EXIT",	1},
    {"SW1GRAY",	"SW2GRAY",	1},
    {"SW1GRAY1",	"SW2GRAY1",	1},
    {"SW1METAL",	"SW2METAL",	1},
    {"SW1PIPE",	"SW2PIPE",	1},
    {"SW1SLAD",	"SW2SLAD",	1},
    {"SW1STARG",	"SW2STARG",	1},
    {"SW1STON1",	"SW2STON1",	1},
    {"SW1STON2",	"SW2STON2",	1},
    {"SW1STONE",	"SW2STONE",	1},
    {"SW1STRTN",	"SW2STRTN",	1},
    
    // Doom registered episodes 2&3 switches
    {"SW1BLUE",	"SW2BLUE",	2},
    {"SW1CMT",		"SW2CMT",	2},
    {"SW1GARG",	"SW2GARG",	2},
    {"SW1GSTON",	"SW2GSTON",	2},
    {"SW1HOT",		"SW2HOT",	2},
    {"SW1LION",	"SW2LION",	2},
    {"SW1SATYR",	"SW2SATYR",	2},
    {"SW1SKIN",	"SW2SKIN",	2},
    {"SW1VINE",	"SW2VINE",	2},
    {"SW1WOOD",	"SW2WOOD",	2},
    
    // Doom II switches
    {"SW1PANEL",	"SW2PANEL",	3},
    {"SW1ROCK",	"SW2ROCK",	3},
    {"SW1MET2",	"SW2MET2",	3},
    {"SW1WDMET",	"SW2WDMET",	3},
    {"SW1BRIK",	"SW2BRIK",	3},
    {"SW1MOD1",	"SW2MOD1",	3},
    {"SW1ZIM",		"SW2ZIM",	3},
    {"SW1STON6",	"SW2STON6",	3},
    {"SW1TEK",		"SW2TEK",	3},
    {"SW1MARB",	"SW2MARB",	3},
    {"SW1SKULL",	"SW2SKULL",	3},
	
    {"\0",		"\0",		0}
}

local wepBase = {
    sprite = SPR_PISG,
    weaponslot = 2,
    order = 1,
    damage = {5, 15},
    raycaster = true,
    shotcost = 1,
    pellets = 1,
    spread = {
        horiz = 0,
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

-- small helper to shallow-copy a state entry table
local function copy_state_entry(entry)
    if type(entry) ~= "table" then return nil end
    local out = {}
    for k, v in pairs(entry) do out[k] = v end
    return out
end

-- Create a default lower/raise state using `idle[1]` as source and forcing action
local function make_lower_or_raise_from_idle(states, action)
    local idle = states and states.idle
    local src = (idle and idle[1]) or (wepBase.states and wepBase.states.idle and wepBase.states.idle[1])
    if not src then
        -- ultimate fallback: create a minimal state
        return { { frame = 0, tics = 1, action = action } }
    end
    local newEntry = copy_state_entry(src)
    newEntry.action = action
    return { newEntry }
end

function doom.addWeapon(wepname, properties)
    -- attach metatable to provide defaults from wepBase
    setmetatable(properties, {
        __index = function(t, key)
            if key == "flashsprite" then
                return rawget(t, "sprite") or wepBase.sprite
            else
                return wepBase[key]
            end
        end
    })

    -- Ensure states table exists (so we can safely index it)
    properties.states = properties.states or {}

    -- If idle isn't present, try to inherit the base idle (so we have a usable source)
    if not properties.states.idle or #properties.states.idle == 0 then
        if wepBase.states and wepBase.states.idle and #wepBase.states.idle > 0 then
            -- shallow-copy the base idle entries
            properties.states.idle = {}
            for i, entry in ipairs(wepBase.states.idle) do
                properties.states.idle[i] = copy_state_entry(entry)
            end
        else
            -- make a minimal idle so we always have something
            properties.states.idle = { { frame = 0, tics = INT32_MAX } }
        end
    end

    -- Provide default lower/raise states if missing
    if not properties.states.lower then
        properties.states.lower = make_lower_or_raise_from_idle(properties.states, A_DoomLower)
    end
    if not properties.states.raise then
        properties.states.raise = make_lower_or_raise_from_idle(properties.states, A_DoomRaise)
    end

    doom.weapons[wepname] = properties
    local wepslot = properties.weaponslot
    local weporder = properties.order
    doom.weaponnames[wepslot][weporder] = wepname
end

doom.ammos = {}
doom.textscreenmaps = {}

---@class doomglobal_t
---@field ammonameToPickupDef table<string, {[1]: string, [2]: integer, [3]: boolean}> Mapping of ammo pickup names to ammo definitions. [1] = ammo type, [2] = amount (multiplied by pickupamount), [3] = isSmallPickup

doom.ammonameToPickupDef = {}

local ammoBase = {
    max = 200,
    icon = "SBOAMMO1"
}

local mt = {
    __index = function(t, k)
        if k == "backpackmax" then
            return t.max * 2
        end
    end
}

setmetatable(ammoBase, mt)

local function warn(warning)
	print("\x82WARNING:\x80 " .. tostring(warning))
end

function doom.addAmmo(ammoname, properties)
    setmetatable(properties, mt)
    doom.ammos[ammoname] = properties

    if not properties.pickupamount then
        warn("Ammo '" .. ammoname .. "' is missing pickupamount property! Defaulting to 1...")
        properties.pickupamount = 1
    end
    if properties.smallpickupName then
        doom.ammonameToPickupDef[properties.smallpickupName] = {ammoname, properties.smallpickupAmount or 1, true}
    else
        warn("Ammo '" .. ammoname .. "' is missing smallpickupName property! Defaulting to '" .. ammoname .. "'...")
        doom.ammonameToPickupDef[ammoname] = {ammoname, properties.smallpickupAmount or 1, true}
    end

    if properties.bigpickupName then
        doom.ammonameToPickupDef[properties.bigpickupName] = {ammoname, properties.bigpickupAmount or 5}
    else
        warn("Ammo '" .. ammoname .. "' is missing bigpickupName property! Defaulting to '" .. ammoname .. "box'...")
        doom.ammonameToPickupDef[ammoname .. "box"] = {ammoname, properties.bigpickupAmount or 5}
    end
end

doom.textscreen = {
	active = false,
	text = "",
	elapsed = 0,
	lineHeight = 11,
	bg = "EP1CUTSC",
	x = 10,
	y = 10
}

doom.pistolstartstate = {
		useinvbackups = true,
		ammo = {
			none = INT32_MIN,
			bullets = 50,
			shells = 0,
			rockets = 0,
			cells = 0,
		},
		oldweapons = {
			brassknuckles = true,
			pistol = true,
		},
		weapons = {
			brassknuckles = true,
			pistol = true,
		},
		health = 100,
		maxhealth = 100,
		armor = 0,
		maxarmor = 100,
		curwep = "pistol",
		curwepslot = 1,
		curwepcat = 2,
		armorefficiency = FRACUNIT/3,
	}

-- DEHACKED Bullshit
doom.soulspheregrant = 100
doom.maxsoulsphere = 200
doom.megaspheregrant = 200
doom.godmodehealth = 100
doom.idfaarmor = 200
doom.greenarmorclass = 1
doom.bluearmorclass = 2
doom.idfaarmorclass = 2
doom.idkfaarmor = 200
doom.idkfaarmorclass = 2
doom.bfgshotcost = 40
doom.infighting = true

doom.strings = {}

doom.endoom = doom.endoom or {}
doom.endoom.text = {
}

doom.endoom.colors = {
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