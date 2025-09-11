DOOM_Freeslot(
"SPR_SAWG",
"SPR_PUNG",
"SPR_PISG",
"SPR_SHTG",
"SPR_SHT2",
"SPR_CHGG", "SPR_CHGF",
"SPR_MISG",
"SPR_PLSG",
"sfx_sawidl", "sfx_sawful", "sfx_sawup", "sfx_sawhit",
"sfx_pistol",
"sfx_dshtgn", "sfx_dbopn", "sfx_dbload", "sfx_dbcls",
"sfx_bfg")

doom.addWeapon("chainsaw", {
	sprite = SPR_SAWG,
	weaponslot = 1,
	order = 1,
	damage = {5, 15},
	raycaster = true,
	pellets = 1,
	shotcost = 0,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = C, tics = 4, action = A_ChainSawSound, var1 = sfx_sawidl, var2 = 1},
			{frame = D, tics = 4, action = A_ChainSawSound, var1 = sfx_sawidl, var2 = 1},
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
	damage = {5, 15},
	raycaster = true,
	pellets = 1,
	shotcost = 0,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = A, tics = 1},
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
	weaponslot = 2,
	order = 1,
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
			{frame = A, tics = 1},
		},
		attack = {
			{frame = A, tics = 4},
			{frame = B, tics = 6, action = A_DoomFire},
			{frame = C, tics = 4},
			{frame = B, tics = 5, action = A_DoomReFire},
		}
	},
	ammotype = "bullets",
})

doom.addWeapon("supershotgun", {
	sprite = SPR_SHT2,
	weaponslot = 3,
	order = 1,
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
			{frame = A, tics = 1},
		},
		attack = {
			{frame = A, tics = 3},
			{frame = A, tics = 7, action = A_DoomFire},
			{frame = B, tics = 7},
			{frame = C, tics = 7},
			{frame = D, tics = 7, action = A_PlaySound, var1 = sfx_dbopn, var2 = 1},
			{frame = E, tics = 7},
			{frame = F, tics = 7, action = A_PlaySound, var1 = sfx_dbload, var2 = 1},
			{frame = G, tics = 8},
			{frame = H, tics = 8, action = A_PlaySound, var1 = sfx_dbcls, var2 = 1},
			{frame = A, tics = 5, action = A_DoomReFire},
		}
	},
	ammotype = "shells",
})

doom.addWeapon("shotgun", {
	sprite = SPR_SHTG,
	weaponslot = 3,
	order = 2,
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
			{frame = A, tics = 1},
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
		}
	},
	ammotype = "shells",
})

doom.addWeapon("chaingun", {
	sprite = SPR_CHGG,
	weaponslot = 4,
	order = 1,
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
			{frame = A, tics = 1},
		},
		attack = {
			{frame = A, tics = 4, action = A_DoomFire},
			{frame = B, tics = 4, action = A_DoomFire},
			{frame = B, tics = 0, action = A_DoomReFire},
		}
	},
	raycaster = true,
	ammotype = "bullets",
})

doom.addWeapon("rocketlauncher", {
	sprite = SPR_MISG,
	weaponslot = 5,
	order = 1,
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
			{frame = A, tics = 1},
		},
		attack = {
			{frame = A, tics = 4, action = A_DoomFire},
			{frame = B, tics = 4, action = A_DoomFire},
			{frame = B, tics = 0, action = A_DoomReFire},
		}
	},
	raycaster = true,
	ammotype = "rockets",
})

doom.addWeapon("plasmarifle", {
	sprite = SPR_PLSG,
	weaponslot = 6,
	order = 1,
	damage = {5, 15},
	noinitfirespread = true,
	pellets = 1,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = A, tics = 1},
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
	sprite = SPR_PLSG,
	weaponslot = 7,
	order = 1,
	damage = {5, 15},
	noinitfirespread = true,
	pellets = 1,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = A, tics = 1},
		},
		attack = {
			{frame = A, tics = 20, action = A_PlaySound, var1 = sfx_bfg, var2 = 1},
			{frame = B, tics = 10}, --action = A_PlaySound, var1 = sfx_bfg, var2 = 1},
			{frame = B, tics = 10}, --action = A_PlaySound, var1 = sfx_bfg, var2 = 1},
			{frame = B, tics = 20, action = A_DoomReFire},
		}
	},
	raycaster = true,
	ammotype = "cells",
})