DOOM_Freeslot(
"SPR_SAWG",
"SPR_PUNG",
"SPR_PISG", "SPR_PISF",
"SPR_SHTG", "SPR_SHTF",
"SPR_SHT2",
"SPR_CHGG", "SPR_CHGF",
"SPR_MISG", "SPR_MISF",
"SPR_PLSG",
"SPR_BFGG", "SPR_BFGF",
"sfx_sawidl", "sfx_sawful", "sfx_sawup", "sfx_sawhit",
"sfx_punch",
"sfx_pistol",
"sfx_dshtgn", "sfx_dbopn", "sfx_dbload", "sfx_dbcls",
"sfx_rlaunc",
"sfx_bfg")

doom.addWeapon("chainsaw", {
	sprite = SPR_SAWG,
	weaponslot = 1,
	order = 1,
	priority = 2200,
	damage = {5, 15},
	raycaster = true,
	hitsound = sfx_sawhit,
	pellets = 1,
	shotcost = 0,
	upsound = sfx_sawup,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = C, tics = 4, action = A_DoomWeaponReady, var1 = A_ChainSawSound, var2 = {var1 = sfx_sawidl}},
			{frame = D, tics = 4, action = A_DoomWeaponReady, var1 = A_ChainSawSound, var2 = {var1 = sfx_sawidl}},
		},
		lower = {
			{frame = C, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = C, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{frame = A, tics = 4, action = A_SawHit},
			{frame = B, tics = 4, action = A_SawHit},
			{frame = B, tics = 0, action = A_DoomReFire},
		}
	},
	ammotype = "none",
})

doom.addWeapon("brassknuckles", {
	sprite = SPR_PUNG,
	weaponslot = 1,
	order = 2,
	priority = 3700,
	damage = {5, 15},
	raycaster = true,
	wimpyweapon = true,
	hitsound = sfx_punch,
	pellets = 1,
	shotcost = 0,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
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
			{frame = B, tics = 4},
			{frame = C, tics = 4, action = A_DoomPunch},
			{frame = D, tics = 5},
			{frame = C, tics = 4},
			{frame = B, tics = 5, action = A_DoomReFire},
		}
	},
	ammotype = "none",
})

doom.addWeapon("pistol", {
	sprite = SPR_PISG,
	flashsprite = SPR_PISF,
	weaponslot = 2,
	order = 1,
	priority = 1900,
	damage = {5, 15},
	noinitfirespread = true,
	wimpyweapon = true,
	pellets = 1,
	firesound = sfx_pistol,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
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
			{frame = A, tics = 4},
			{frame = B, tics = 6, action = A_DoomFire},
			{frame = C, tics = 4},
			{frame = B, tics = 5, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 6, action = A_DoomLight1},
			{frame = A, sprite = SPR_NULL, tics = 1, action = A_DoomLight0},
		}
	},
	ammotype = "bullets",
})

doom.addWeapon("supershotgun", {
	sprite = SPR_SHT2,
	weaponslot = 3,
	order = 1,
	priority = 400,
	damage = {5, 15},
	pellets = 20,
	firesound = sfx_dshtgn,
	shotcost = 2,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = FRACUNIT*71/10,
	},
	raycaster = true,
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
			{frame = A, tics = 3},
			{frame = A, tics = 7, action = A_DoomFire},
			{frame = B, tics = 7},
			{frame = C, tics = 7, action = A_DoomCheckReload},
			{frame = D, tics = 7, action = A_PlaySound, var1 = sfx_dbopn, var2 = 1},
			{frame = E, tics = 7},
			{frame = F, tics = 7, action = A_PlaySound, var1 = sfx_dbload, var2 = 1},
			{frame = G, tics = 8},
			{frame = H, tics = 8, action = A_PlaySound, var1 = sfx_dbcls, var2 = 1},
			{frame = A, tics = 5, action = A_DoomReFire, nextstate = "idle"},
			{frame = B, tics = 7},
			{frame = A, tics = 3, nextstate = "lower"},
		},
		flash = {
			-- Flashframe jank
			{frame = I|FF_FULLBRIGHT, tics = 5, action = A_DoomLight1},
			{frame = J|FF_FULLBRIGHT, tics = 4, action = A_DoomLight2},
			{frame = A, sprite = SPR_NULL, tics = 1, action = A_DoomLight0},
		}
	},
	ammotype = "shells",
})

doom.addWeapon("shotgun", {
	sprite = SPR_SHTG,
	flashsprite = SPR_SHTF,
	weaponslot = 3,
	order = 2,
	priority = 1300,
	damage = {5, 15},
	pellets = 7,
	firesound = sfx_shotgn,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	raycaster = true,
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
			{frame = A, tics = 3},
			{frame = A, tics = 7, action = A_DoomFire},
			{frame = B, tics = 5},
			{frame = C, tics = 5},
			{frame = D, tics = 4},
			{frame = C, tics = 5},
			{frame = B, tics = 5},
			{frame = A, tics = 3},
			{frame = A, tics = 7, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1},
			{frame = B|FF_FULLBRIGHT, tics = 3, action = A_DoomLight2},
			{frame = A, sprite = SPR_NULL, tics = 1, action = A_DoomLight0},
		}
	},
	ammotype = "shells",
})

doom.addWeapon("chaingun", {
	sprite = SPR_CHGG,
	flashsprite = SPR_CHGF,
	weaponslot = 4,
	order = 1,
	priority = 700,
	damage = {5, 15},
	noinitfirespread = true,
	pellets = 1,
	firesound = sfx_pistol,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
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
			{frame = A, tics = 4, action = A_DoomFire},
			{frame = B, tics = 4, action = A_DoomFire, var1 = nil, var2 = {noFlash = true}},
			{frame = B, tics = 0, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1},
			{frame = B|FF_FULLBRIGHT, tics = 4, action = A_DoomLight2},
			{frame = A, sprite = SPR_NULL, tics = 1, action = A_DoomLight0},
		}
	},
	raycaster = true,
	ammotype = "bullets",
})

doom.addWeapon("rocketlauncher", {
	sprite = SPR_MISG,
	flashsprite = SPR_MISF,
	weaponslot = 5,
	order = 1,
	priority = 2500,
	damage = {5, 15},
	noinitfirespread = true,
	noautoswitchfire = true,
	pellets = 1,
	firesound = sfx_rlaunc,
	shootmobj = MT_DOOM_ROCKETPROJ,
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
			{frame = B, tics = 8, action = A_DoomGunFlash},
			{frame = B, tics = 12, action = A_DoomFire, var2 = {noFlash = true}},
			{frame = B, tics = 0, action = A_DoomReFire},
		},
		flash = {
			{frame = A, tics = 3, action = A_DoomLight1},
			{frame = B, tics = 4},
			{frame = C, tics = 4, action = A_DoomLight2},
			{frame = D, tics = 4, action = A_DoomLight2},
			{frame = A, sprite = SPR_NULL, tics = 1, action = A_DoomLight0},
		}
	},
	raycaster = true,
	ammotype = "rockets",
})

doom.addWeapon("plasmarifle", {
	sprite = SPR_PLSG,
	weaponslot = 6,
	order = 1,
	priority = 100,
	damage = {5, 40},
	pellets = 1,
	shootmobj = MT_DOOM_PLASMASHOT,
	noshareware = true,
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
			{frame = A, tics = 3, action = A_DoomFire},
			{frame = B, tics = 20, action = A_DoomReFire},
		}
	},
	raycaster = true,
	ammotype = "cells",
})

doom.addWeapon("bfg9000", {
	sprite = SPR_BFGG,
	flashsprite = SPR_BFGF,
	weaponslot = 7,
	order = 1,
	priority = 2800,
	shotcost = 40,
	damage = {9999, 9999},
	noinitfirespread = true,
	noautoswitchfire = true,
	noshareware = true,
	pellets = 60,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
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
			{frame = A, tics = 20, action = A_PlaySound, var1 = sfx_bfg, var2 = 1},
			{frame = B, tics = 10, action = A_GunFlash},
			{frame = B, tics = 10, action = A_DoomFire, var2 = {noFlash = true}},
			{frame = B, tics = 20, action = A_DoomReFire},
		},
		flash = {
			{frame = A, tics = 11, action = A_DoomLight1},
			{frame = B, tics = 6, action = A_DoomLight2},
			{frame = A, sprite = SPR_NULL, tics = 1, action = A_DoomLight0},
		}
	},
	raycaster = true,
	ammotype = "cells",
})