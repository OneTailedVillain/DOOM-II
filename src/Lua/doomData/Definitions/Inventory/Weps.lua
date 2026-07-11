DOOM_Freeslot(
"SPR_SAWG",
"SPR_PUNG",
"SPR_PISG", "SPR_PISF",
"SPR_SHTG", "SPR_SHTF",
"SPR_SHT2",
"SPR_CHGG", "SPR_CHGF",
"SPR_MISG", "SPR_MISF",
"SPR_PLSG", "SPR_PLSF",
"SPR_BFGG", "SPR_BFGF",
"sfx_sawidl", "sfx_sawful", "sfx_sawup", "sfx_sawhit",
"sfx_punch",
"sfx_pistol",
"sfx_dshtgn", "sfx_dbopn", "sfx_dbload", "sfx_dbcls",
"sfx_rlaunc",
"sfx_bfg", "S_DOOM_LIGHTDONE")

states[S_DOOM_LIGHTDONE] = {
	frame = A,
	sprite = SPR_NULL,
	tics = 1,
	action = A_DoomLight0
}

doom.addWeapon("chainsaw", {
	sprite = SPR_SAWG,
	weaponslot = 1,
	order = 1,
	priority = 2200,
	damage = {2, 20},
	raycaster = true,
	hitsound = sfx_sawhit,
	pellets = 1,
	shotcost = 0,
	upsound = sfx_sawup,
	idleaction = {call = A_ChainSawSound, var1 = sfx_sawidl},
	hitaction = {call = A_ChainSawSound, var1 = sfx_sawhit},
	missaction = {call = A_ChainSawSound, var1 = sfx_sawful},
	anglesnapbehavior = "chainsaw",
	carouselicon = "SMCSAW",
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	statesasslots = true,
	states = {
		idle = {
			{frame = C, tics = 4, action = A_DoomWeaponReady},
			{frame = D, tics = 4, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = C, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = C, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{frame = A, tics = 4, action = A_DoomSaw},
			{frame = B, tics = 4, action = A_DoomSaw},
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
	damage = {2, 20},
	raycaster = true,
	wimpyweapon = true,
	hitsound = sfx_punch,
	pellets = 1,
	shotcost = 0,
	anglesnapbehavior = "fists",
	carouselicon = "SMFIST",
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	statesasslots = true,
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
	shotcost = 1,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	statesasslots = true, -- States WHAT slots???
	carouselicon = "SMPISG",
	states = {
		idle = {
			{frame = A, tics = 1, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = A, tics = 1, action = A_DoomLower, goto = "lower"}
		},
		raise = {
			{frame = A, tics = 1, action = A_DoomRaise, goto = "raise"}
		},
		attack = {
			{frame = A, tics = 4},
			{frame = B, tics = 6, action = A_DoomFirePistol},
			{frame = C, tics = 4},
			{frame = B, tics = 5, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 6, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
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
	statesasslots = true,
	carouselicon = "SMSGN2",
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
			{frame = A, tics = 7, action = A_DoomFireShotgun2},
			{frame = B, tics = 7},
			{frame = C, tics = 7, action = A_DoomCheckReload},
			{frame = D, tics = 7, action = A_PlaySound, var1 = sfx_dbopn, var2 = 1},
			{frame = E, tics = 7},
			{frame = F, tics = 7, action = A_PlaySound, var1 = sfx_dbload, var2 = 1},
			{frame = G, tics = 8},
			{frame = H, tics = 8, action = A_PlaySound, var1 = sfx_dbcls, var2 = 1},
			{frame = A, tics = 5, action = A_DoomReFire, goto = "idle"},
			{frame = B, tics = 7},
			{frame = A, tics = 3, goto = "lower"},
		},
		flash = {
			-- Flashframe jank
			{frame = I|FF_FULLBRIGHT, tics = 5, action = A_DoomLight1},
			{frame = J|FF_FULLBRIGHT, tics = 4, action = A_DoomLight2, goto = S_DOOM_LIGHTDONE},
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
	shotcost = 1,
	statesasslots = true,
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
			{frame = A, tics = 3},
			{frame = A, tics = 7, action = A_DoomFireShotgun},
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
			{frame = B|FF_FULLBRIGHT, tics = 3, action = A_DoomLight2, goto = S_DOOM_LIGHTDONE},
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
	shotcost = 1,
	statesasslots = true,
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
			{frame = A, tics = 4, action = A_DoomFireCGun},
			{frame = B, tics = 4, action = A_DoomFireCGun},
			{frame = B, tics = 0, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
			{frame = B|FF_FULLBRIGHT, tics = 4, action = A_DoomLight2, goto = S_DOOM_LIGHTDONE},
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
	damage = {20, 160},
	noinitfirespread = true,
	noautoswitchfire = true,
	pellets = 1,
	shootmobj = MT_DOOM_ROCKETPROJ,
	shotcost = 1,
	statesasslots = true,
	carouselicon = "SMLAUN",
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
			{frame = B, tics = 12, action = A_DoomFireMissile},
			{frame = B, tics = 0, action = A_DoomReFire},
		},
		flash = {
			{frame = A, tics = 3, action = A_DoomLight1},
			{frame = B, tics = 4},
			{frame = C, tics = 4, action = A_DoomLight2},
			{frame = D, tics = 4, action = A_DoomLight2, goto = S_DOOM_LIGHTDONE},
		}
	},
	raycaster = true,
	ammotype = "rockets",
})

doom.addWeapon("plasmarifle", {
	sprite = SPR_PLSG,
	flashsprite = SPR_PLSF,
	weaponslot = 6,
	order = 1,
	priority = 100,
	damage = {5, 40},
	pellets = 1,
	shootmobj = MT_DOOM_PLASMASHOT,
	noshareware = true,
	shotcost = 1,
	statesasslots = true,
	carouselicon = "SMPLAS",
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
			{frame = A, tics = 3, action = A_DoomFirePlasma},
			{frame = B, tics = 20, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
			{frame = B|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
		},
	},
	raycaster = true,
	ammotype = "cells",
})

function A_DoomPlayFireSound(actor, var1, var2, wepdef)
	S_StartSound(actor, wepdef.firesound)
end

doom.addWeapon("bfg9000", {
	sprite = SPR_BFGG,
	flashsprite = SPR_BFGF,
	weaponslot = 7,
	order = 1,
	priority = 2800,
	shotcost = 40,
	noinitfirespread = true,
	noautoswitchfire = true,
	noshareware = true,
	pellets = 60,
	firesound = sfx_bfg,
	statesasslots = true,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	carouselicon = "SMBFGG",
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
			{frame = A, tics = 20, action = A_DoomPlayFireSound},
			{frame = B, tics = 10, action = A_DoomGunFlash},
			{frame = B, tics = 10, action = A_DoomFireBFG},
			{frame = B, tics = 20, action = A_DoomReFire},
		},
		flash = {
			{frame = A|FF_FULLBRIGHT, tics = 11, action = A_DoomLight1},
			{frame = B|FF_FULLBRIGHT, tics = 6, action = A_DoomLight2, goto = S_DOOM_LIGHTDONE},
		}
	},
	raycaster = true,
	ammotype = "cells",
})