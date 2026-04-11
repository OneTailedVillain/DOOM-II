freeslot("SPR_LINK_SLINGSHOT_WEP", "SPR_LINK_FIGHTERSWORD")

SafeFreeSlot(
    "SPR_BAL2","SPR_MISL",
    "MT_DOOM_LINKSLINGSHOT",
	"sfx_lttpss",
	"SPR_LINK_SLINGSHOT_ROCK"
)

local plasmastates = {
    shot = {
        {sprite = SPR_LINK_SLINGSHOT_ROCK, frame = A|FF_FULLBRIGHT, tics = -1},
    },

    explode = {
        {sprite = SPR_LINK_SLINGSHOT_ROCK, frame = B|FF_FULLBRIGHT, tics = 1},
        {sprite = SPR_LINK_SLINGSHOT_ROCK, frame = C|FF_FULLBRIGHT, tics = 1},
        {sprite = SPR_LINK_SLINGSHOT_ROCK, frame = D|FF_FULLBRIGHT, tics = 1},
    },
}

local states = FreeDoomStates("Slingshot", plasmastates)

mobjinfo[MT_DOOM_LINKSLINGSHOT] = {
    spawnstate = states.shot[1],
    seesound   = sfx_lttpss,
    deathstate = states.explode[1],

    speed      = 40*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 3,

    flags = MF_MISSILE,
}

SafeFreeSlot(
    "SPR_BAL2","SPR_MISL",
    "MT_DOOM_LINKBOMB"
)

local plasmastates = {
    shot = {
        {sprite = SPR_BAL2, frame = A|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_BAL2, frame = B|FF_FULLBRIGHT, tics = 6, next = "shot"},
    },

    explode = {
        {sprite = SPR_BAL2, frame = B|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BAL2, frame = C|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_BAL2, frame = D|FF_FULLBRIGHT, tics = 4},
    },
}

local states = FreeDoomStates("LinkBomb", plasmastates)

mobjinfo[MT_DOOM_LINKBOMB] = {
    spawnstate = states.shot[1],
    seesound   = sfx_lttpss,
	activesound = sfx_lttpbd,
	deathsound = sfx_lttpbb,
    deathstate = states.explode[1],

    speed      = 40*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 3,

    flags = MF_MISSILE|MF_GRENADEBOUNCE,
}

function A_DoomFireSlingshot(actor, var1, var2, wepdef)
	local player = actor.mo and actor or actor.player
	if not player then return end
	local pd = player.doom
	pd.ammo[doom.weapons[pd.curwep].ammotype] = $ - wepdef.shotcost

	local MAXHORIZ = FRACUNIT*45/4 -- Maximum achievable horizontal spread
	local MAXVERT  = FRACUNIT*45/8 -- Maximum achievable vertical spread

	-- Scale spread based on pd.refire
	local refireFactor = (pd.refire*FRACUNIT) / 20 -- Adjust denominator to tune how fast spread grows

	if refireFactor > FRACUNIT then refireFactor = FRACUNIT end

	local horizSpread = FixedMul(MAXHORIZ, refireFactor)
	local vertSpread  = FixedMul(MAXVERT,  refireFactor)

	DOOM_Fire(actor, MISSILERANGE, horizSpread, vertSpread, 1, nil, nil, nil, MT_DOOM_LINKSLINGSHOT)
end

doom.addWeapon("fighterssword", {
	sprite = SPR_LINK_FIGHTERSWORD,
	weaponslot = 1,
	order = 10,
	priority = 1900,
	damage = {8, 16},
	noinitfirespread = true,
	pellets = 1,
	firesound = sfx_pistol,
	shotcost = 0,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	carouselicon = "SMFSWD",
	states = {
		idle = {
			{frame = A, tics = 1, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = A, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = A, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{frame = 2, tics = 2},
			{frame = 3, tics = 2},
			{frame = 4, tics = 2},
			{frame = 5, tics = 2},
			{frame = 6, tics = 2, action = A_DoomFireSlingshot},
			{frame = 0, tics = 1, action = A_DoomReFire},
		}
	},
	ammotype = "none",
})

doom.addWeapon("bow", {
	sprite = SPR_LINK_SLINGSHOT_WEP,
	weaponslot = 2,
	order = 10,
	priority = 1900,
	damage = {5, 15},
	noinitfirespread = true,
	pellets = 1,
	firesound = sfx_pistol,
	shotcost = 1,
	spread = {
		horiz = 0,
		vert = 0,
	},
	carouselicon = "SMPISG",
	states = {
		idle = {
			{frame = A, tics = 1, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = A, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = A, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{frame = B, tics = 2, action = A_DoomFireSlingshot},
			{frame = C, tics = 2},
			{frame = D, tics = 2},
			{frame = A, tics = 1, action = A_DoomReFire},
		}
	},
	ammotype = "arrows",
})

doom.addWeapon("slingshot", {
	sprite = SPR_LINK_SLINGSHOT_WEP,
	weaponslot = 4,
	order = 1,
	priority = 1900,
	damage = {5, 15},
	noinitfirespread = true,
	pellets = 1,
	firesound = sfx_pistol,
	shotcost = 1,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	carouselicon = "SMMGUN",
	states = {
		idle = {
			{frame = A, tics = 1, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = A, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = A, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{frame = B, tics = 2, action = A_DoomFireSlingshot},
			{frame = C, tics = 2},
			{frame = D, tics = 2},
			{frame = A, tics = 1, action = A_DoomReFire},
		}
	},
	ammotype = "rupees",
})