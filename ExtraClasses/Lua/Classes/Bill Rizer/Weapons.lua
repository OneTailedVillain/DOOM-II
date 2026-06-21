SafeFreeSlot(
	"SPR_BILL_RIFLE",
	"SPR_BILL_SHOT",
	"sfx_brmfir",
	"sfx_brsfir",
	"sfx_brrfir"
)

-- SMFIST
-- SMCSAW
-- SMPISG
-- SMSHOT
-- SMSGN2
-- SMMGUN
-- SMLAUN
-- SMPLAS
-- SMBFGG

local shotstates = {
    rifle = {
        {sprite = SPR_BILL_SHOT, frame = 0|FF_SEMIBRIGHT, tics = -1},
	},

    spread = {
        {sprite = SPR_BILL_SHOT, frame = 1|FF_SEMIBRIGHT, tics = 10/2},
        {sprite = SPR_BILL_SHOT, frame = 2|FF_SEMIBRIGHT, tics = 9/2},
        {sprite = SPR_BILL_SHOT, frame = 3|FF_SEMIBRIGHT, tics = -1},
    },

	machine = {
        {sprite = SPR_BILL_SHOT, frame = 1|FF_SEMIBRIGHT, tics = -1},
    },
}

local states = FreeDoomStates("BillShot", shotstates)

mobjinfo[freeslot("MT_BILL_RIFLESHOT")] = {
	spawnstate = states.rifle[1],
	radius = 4*FRACUNIT,
	height = 8*FRACUNIT,
	speed = 60*FRACUNIT,
	flags = MF_MISSILE|MF_NOGRAVITY
}

mobjinfo[freeslot("MT_BILL_SPREADSHOT")] = {
	spawnstate = states.spread[1],
	radius = 4*FRACUNIT,
	height = 8*FRACUNIT,
	speed = 40*FRACUNIT,
	flags = MF_MISSILE|MF_NOGRAVITY
}

mobjinfo[freeslot("MT_BILL_MACHINESHOT")] = {
	spawnstate = states.machine[1],
	radius = 4*FRACUNIT,
	height = 8*FRACUNIT,
	speed = 60*FRACUNIT,
	flags = MF_MISSILE|MF_NOGRAVITY
}

doom.addWeapon("bill-rifle", {
	sprite = SPR_BILL_RIFLE,
	weaponslot = 1,
	order = 10,
	ammotype = "none",
	priority = 1900,
	damage = {18, 18},
	pellets = 1,
	firesound = sfx_brrfir,
	shootmobj = MT_BILL_RIFLESHOT,
	shotcost = 0,
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
			{frame = 0, tics = 7, action = A_NotDoomFire},
			{frame = 0, tics = 1, action = A_DoomReFire}
		},
		flash = {
			{frame = 1|FF_FULLBRIGHT, tics = 2, action = A_DoomLight2},
			{frame = 2|FF_FULLBRIGHT, tics = 2, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
		}
	},
})

doom.addWeapon("bill-spreadgun", {
	sprite = SPR_BILL_RIFLE,
	weaponslot = 3,
	order = 10,
	ammotype = "none",
	priority = 1900,
	damage = {24, 24},
	pellets = 3,
	firesound = sfx_brsfir,
	bill_icon = "SPREAD",
	shootmobj = MT_BILL_SPREADSHOT,
	shotcost = 0,
	spread = {
		horiz = FRACUNIT*15/10,
		vert = FRACUNIT*15/10,
	},
	carouselicon = "SMSHOT",
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
			{frame = 0, tics = 20, action = A_NotDoomFire},
			{frame = 0, tics = 1, action = A_DoomReFire}
		},
		flash = {
			{frame = 1|FF_FULLBRIGHT, tics = 2, action = A_DoomLight2},
			{frame = 2|FF_FULLBRIGHT, tics = 2, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
		}
	},
})

doom.addWeapon("bill-machinegun", {
	sprite = SPR_BILL_RIFLE,
	weaponslot = 4,
	order = 10,
	ammotype = "none",
	priority = 1900,
	damage = {24, 24},
	pellets = 1,
	firesound = sfx_brmfir,
	bill_icon = "MACHINE",
	shootmobj = MT_BILL_MACHINESHOT,
	shotcost = 0,
	spread = {
		horiz = 0,
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
			{frame = 0, tics = 5, action = A_NotDoomFire},
			{frame = 0, tics = 1, action = A_DoomReFire}
		},
		flash = {
			{frame = 1|FF_FULLBRIGHT, tics = 2, action = A_DoomLight2},
			{frame = 2|FF_FULLBRIGHT, tics = 2, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
		}
	},
})