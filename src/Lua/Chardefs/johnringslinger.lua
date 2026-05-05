---@type doommethods_t
local methods = deepcopy(doom.charSupportBaseMethods)

SafeFreeSlot(
    "MT_DOOM_SCATTEREDRING",
	"SPR_FRNG"
)

local plasmastates = {
    active = {
        {sprite = SPR_FRNG, frame = A|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = B|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = C|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = D|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = E|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = F|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = G|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = H|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = I|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = J|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = K|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = L|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = M|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = N|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = O|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_FRNG, frame = P|FF_FULLBRIGHT, tics = 2, next = "active"},
    },
}

local mtSt = FreeDoomStates("ScatteredRing", plasmastates)

mobjinfo[MT_DOOM_SCATTEREDRING] = {
    spawnstate = mtSt.active[1],
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,

    speed      = 20*FRACUNIT,
    radius     = 16*FRACUNIT,
    height     = 20*FRACUNIT,
    damage     = 8,

    flags = mobjinfo[MT_FLINGRING].flags,
}

local function GiveHealthCompat(funcs, player, heal, clampMax)
	-- Prefer skin-provided giveHealth if available
	if funcs.giveHealth then
		-- expectedMaxHealth is used for clamping inside giveHealth
		return funcs.giveHealth(player, heal, clampMax)
	end

	-- Fallback: manual get/set
	local health = funcs.getHealth(player)
	local newhealth = min(health + heal, clampMax)

	if newhealth <= health then
		return false
	end

	funcs.setHealth(player, newhealth)
	return true
end

-- Act like a health bonus
---@param mobj mobj_t
---@param item mobj_t
addHook("TouchSpecial", function(item, mobj)
	if not mobj.player then return true end

	local player = mobj.player
	if item.fuse > 29*TICRATE then return end

	local funcs = P_GetMethodsForSkin(player)

	local maxhealth = funcs.getMaxHealth(player)
	local clampMax = maxhealth * 2

	GiveHealthCompat(funcs, player, 1, clampMax)
	DOOM_DoMessage(player, "$GOTHTHBONUS")
end, MT_DOOM_SCATTEREDRING)

doom.charSupport.johnringslinger = {
	-- Custom CSS bullshit
	css = {
		name = "John Ringslinger",
		description = {
			"Wields a full spread of weaponry",
			"Each packing serious firepower",
			"However far from built to take hits",
			"So keep moving or get torn apart"
		},
		sprite = SPR2_WALK,
		sequence = {A, 4}
	},

	properties = {
		doomDeathanim = true,

		sounds = {
			--[sfx_plpain] = sfx_sd2pai,
			--[sfx_pdiehi] = sfx_sd2dhi,
			--[sfx_pldeth] = sfx_sd2die,
		},

		dealdamagefactor = FRACUNIT*4/4,

		damagefactor = {
			all = FRACUNIT*5/4,
		},

		movefactor = 2300,
		walkfactor = FRACUNIT*3/5,
		jumpfactor = FRACUNIT,
		mass = 100,

		starthealth = 80,
		maxhealth = 80,

		-- The maximum value that Armor Bonuses
		-- And Megaspheres can get Armor to
		armormax = 150,

		armorproperties = {
			armorclassmult = 75, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/4, -- How much armor protection armor class 1 gives you
			armorclass2prot = FRACUNIT/3, -- How much armor protection armor class 2 (and up, as for some reason DOOM considers armor classes > 2 as 50% protection) gives you
		},

		-- Ammo is only valid for characters under the vanilla
		-- DOOM system
		startammo = {
			bullets = 50,
			shells = 0,
			cells = 0,
			rockets = 0,
		},

		maxammo = {
			bullets = 320 + 400, -- Basic + Automatic
			shells = 50 + 160, -- Scatter + Bounce
			cells = 50 + 50, -- Rail + Homing
			rockets = 50 + 50, -- Explosion + Grenade
		},

		-- Multipliers of what pick-ups will give to the player
		-- "all" and a specific type will multiply the type factor with the "all" multiplier
		pickupfactors = {
			ammo = {
				all = FRACUNIT,
				bullets = FRACUNIT*3/2,
				shells = FRACUNIT*5/4,
				cells = FRACUNIT*2/3,
				rockets = FRACUNIT,
			},
			health = {
				all = FRACUNIT*5/4
			},
			powerups = {
				all = FRACUNIT,
				invisibility = FRACUNIT,
				infrared = FRACUNIT,
				radsuit = FRACUNIT,
				invulnerability = FRACUNIT
			},
		},

		startweapon = "matchring",
		startweapons = {
			brassknuckles = true,
			matchring = true
		},

		-- Basically just Quake Ranger's Ringslinger support
		-- Then translated into DOOM support
		weaponremapping = {
			chainsaw = "bouncering",
			pistol = "matchring",
			shotgun = "scatterring",
			supershotgun = "grenadering",
			chaingun = "automaticring",
			rocketlauncher = "explosionring",
			plasmarifle = "homingring",
			bfg9000 = "railring"
		}
	},

	vanillaoverrides = {
		strings = {
			GOTCLIP = "Picked up small Match/Automatic ammo.",
			GOTCLIPBOX = "Picked up large Match/Automatic ammo.",
			GOTSHELLS = "Picked up small Scatter/Bounce ammo.",
			GOTSHELLBOX = "Picked up large Scatter/Bounce ammo.",
			GOTROCKET = "Picked up small Explosion/Grenade ammo.",
			GOTROCKBOX = "Picked up large Explosion/Grenade ammo.",
			GOTCELL = "Picked up small Homing/Rail ammo.",
			GOTCELLBOX = "Picked up large Homing/Rail ammo.",
			GOTCHAINSAW = "You got the Bounce Ring!",
			GOTSHOTGUN = "You got the Scatter Ring!",
			GOTSHOTGUN2 = "You got the Grenade Ring!",
			GOTCHAINGUN = "You got the Automatic Ring!",
			GOTLAUNCHER = "You got the Explosion Ring!",
			GOTPLASMA = "You got the Homing Ring!",
			GOTBFG9000 = "You got the Rail Ring! Oh, yes.",
		}
	},

	useDoomMovement = true,
	forceDisableJump = true,
    methods = methods
}