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
	DF_DMRESPAWN = 1536, -- DF_DMRESPAWN|DF_SM2RESPAWN
	DF_DM2RESPAWN = 1024,
	DF_INFLOAT = 2048,
	DF_TELEPORT = 4096,
	DF_DROPOFF = 8192,
	pw_strength = 1,
	pw_ironfeet = 2,
	pw_invisibility = 3,
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

function doom.addWeapon(wepname, properties)
	setmetatable(properties, { __index = wepBase })
	doom.weapons[wepname] = properties
	local wepslot = properties.weaponslot
	local weporder = properties.order
	doom.weaponnames[wepslot][weporder] = wepname
end

doom.ammos = {}
doom.textscreenmaps = {}

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

function doom.addAmmo(ammoname, properties)
    setmetatable(properties, mt)
    doom.ammos[ammoname] = properties
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
doom.megaspheregrant = 200
doom.godmodehealth = 100
doom.idfaarmor = 200
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