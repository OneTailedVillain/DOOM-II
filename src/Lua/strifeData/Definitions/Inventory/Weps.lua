DOOM_Freeslot(
"SPR_PNCH",
"sfx_sawidl", "sfx_sawful", "sfx_sawup", "sfx_sawhit",
"sfx_punch",
"sfx_pistol",
"sfx_dshtgn", "sfx_dbopn", "sfx_dbload", "sfx_dbcls",
"sfx_rlaunc",
"sfx_bfg")

strife.addWeapon("punchdagger", {
	sprite = SPR_PNCH,
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