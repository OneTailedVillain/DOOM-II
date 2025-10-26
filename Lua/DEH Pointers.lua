DOOM_Freeslot("S_LIGHTDONE")

doom.dehackedpointers = {
	things = {
		MT_PLAYER,
		MT_DOOM_ZOMBIEMAN,
		MT_DOOM_SHOTGUNNER,
		MT_DOOM_ARCHVILE,
		nil, -- Archvile Attack
		nil, -- Revenant
		nil, -- Revenant Fireball
		nil, -- Fireball Trail
		nil, -- Mancubus
		nil, -- Mancubus Fireball
		MT_DOOM_CHAINGUNNER,
		MT_DOOM_IMP,
		MT_DOOM_DEMON,
		MT_DOOM_SPECTRE,
		MT_DOOM_CACODEMON,
		MT_DOOM_BARONOFHELL,
		nil, -- Baron Fireball
		MT_DOOM_HELLKNIGHT,
		MT_DOOM_LOSTSOUL,
		nil, -- Spiderdemon
		nil, -- Arachnotron
		nil, -- Cyberdemon
		nil, -- Pain Elemental
		MT_DOOM_SSGUARD, -- aka "SS Nazi"
		MT_DOOM_KEEN, -- aka "Commander Keen"
		MT_DOOM_ROMEROHEAD, -- aka "Icon of Sin"
		MT_DOOM_MONSTERSPAWNER, -- aka "Demon Spawner"
		MT_DOOM_BOSSTARGET, -- aka "Demon Spawn Spot"
		nil, -- Demon Spawn Cube
		nil, -- Demon Spawn Fire
		MT_DOOM_BARREL,
		MT_TROOPSHOT, -- aka "Imp Fireball"
		nil, -- Cacodemon Fireball
		MT_DOOM_ROCKETPROJ,
		nil, -- Plasma Bullet
		nil, -- BFG Shot
		nil, -- Arachnotron Fireball
	},

	flags = {
		[1<<0]  = {num = MF_SPECIAL,      type = "MF"},
		[1<<1]  = {num = MF_SOLID,        type = "MF"},
		[1<<2]  = {num = MF_SHOOTABLE,    type = "MF"},
		[1<<3]  = {num = MF_NOSECTOR,     type = "MF"},
		[1<<4]  = {num = MF_NOBLOCKMAP,   type = "MF"},
		[1<<5]  = {num = MF2_AMBUSH,      type = "MF2"},
		[1<<6]  = {num = DF_JUSTHIT,      type = "DF"},
		[1<<7]  = {num = MF2_JUSTATTACKED,type = "MF2"},
		[1<<8]  = {num = MF_SPAWNCEILING, type = "MF"},
		[1<<9]  = {num = MF_NOGRAVITY,    type = "MF"},
		[1<<10] = {num = DF_DROPOFF,      type = "DF"},
		[1<<11] = {num = DF_PICKUP,       type = "DF"},
		[1<<12] = {num = MF_NOCLIP,       type = "MF"},
		[1<<13] = {num = MF_SLIDEME,      type = "MF"},
		[1<<14] = {num = MF_FLOAT,        type = "MF"},
		[1<<15] = {num = DF_TELEPORT,     type = "DF"},
		[1<<16] = {num = MF_MISSILE,      type = "MF"},
		[1<<17] = {num = DF_DROPPED,      type = "DF"},
		[1<<18] = {num = DF_SHADOW,       type = "DF"},
		[1<<19] = {num = DF_NOBLOOD,      type = "DF"},
		[1<<20] = {num = DF_CORPSE,       type = "DF"},
		[1<<21] = {num = MF2_INFLOAT,     type = "MF2"},
		[1<<22] = {num = DF_COUNTKILL,    type = "DF"},
		[1<<23] = {num = DF_COUNTITEM,    type = "DF"},
		[1<<24] = {num = MF2_SKULLFLY,    type = "MF"},
		[1<<25] = {num = DF_NOTDMATCH,    type = "DF"},
		[1<<26] = {num = DF_SKINCOLOR1,   type = "DF"},
		[1<<27] = {num = DF_SKINCOLOR2,   type = "DF"},
	},
	sounds = {
		sfx_pistol,
		sfx_shotgn,
		sfx_sgcock,
		sfx_dshtgn,
		sfx_dbopn,
		sfx_dcls,
		sfx_dbload,
		sfx_plasma,
		sfx_bfg,
		sfx_sawup,
		sfx_sawidl,
		sfx_sawful,
		sfx_sawhit,
		sfx_rlaunc,
		sfx_rxplod,
		sfx_firsht,
		sfx_firxpl,
		sfx_pstart,
		sfx_pstop,
		sfx_doropn,
		sfx_dorcls,
		sfx_stnmov,
		sfx_swtchn,
		sfx_swtchx,
		sfx_plpain,
		sfx_dmpain,
		sfx_popain,
		sfx_vipain,
		sfx_mnpain,
		sfx_pepain,
		sfx_slop,
		sfx_itemup,
		sfx_wpnup,
		sfx_oof,
		sfx_telept,
		sfx_posit1,
		sfx_posit2,
		sfx_posit3,
		sfx_bgsit1,
		sfx_bgsit2,
		sfx_sgtsit,
		sfx_cacsit,
		sfx_brssit,
		sfx_cybsit,
		sfx_spisit,
		sfx_bspsit,
		sfx_kntsit,
		sfx_vilsit,
		sfx_mansit,
		sfx_pesit,
		sfx_sklatk,
		sfx_sgtatk,
		sfx_skepch
	},

	frames = {
		S_NULL,
		S_LIGHTDONE,
		{sprite = SPR_PUNG, frame = 0, nextstate = 3},
		[90] = S_DOOM_BLOOD1,
		[91] = S_DOOM_BLOOD2,
		[92] = S_DOOM_BLOOD3,
		[93] = S_DOOM_PUFF1,
		[94] = S_DOOM_PUFF2,
		[95] = S_DOOM_PUFF3,
	},

	frametowepstate = {
		[2] = {"brassknuckles", "idle", 1},        -- S_PUNCH
		[3] = {"brassknuckles", "lower", 1},       -- S_PUNCHDOWN
		[4] = {"brassknuckles", "raise", 1},       -- S_PUNCHUP
		[5] = {"brassknuckles", "attack", 1},      -- S_PUNCH1
		[6] = {"brassknuckles", "attack", 2},      -- S_PUNCH2
		[7] = {"brassknuckles", "attack", 3},      -- S_PUNCH3
		[8] = {"brassknuckles", "attack", 4},      -- S_PUNCH4
		[9] = {"brassknuckles", "attack", 5},      -- S_PUNCH5
		
		[10] = {"pistol", "idle", 1},              -- S_PISTOL
		[11] = {"pistol", "lower", 1},             -- S_PISTOLDOWN
		[12] = {"pistol", "raise", 1},             -- S_PISTOLUP
		[13] = {"pistol", "attack", 1},            -- S_PISTOL1
		[14] = {"pistol", "attack", 2},            -- S_PISTOL2
		[15] = {"pistol", "attack", 3},            -- S_PISTOL3
		[16] = {"pistol", "attack", 4},            -- S_PISTOL4
		[17] = {"pistol", "flash", 1},             -- S_PISTOLFLASH
		
		[18] = {"shotgun", "idle", 1},             -- S_SGUN
		[19] = {"shotgun", "lower", 1},            -- S_SGUNDOWN
		[20] = {"shotgun", "raise", 1},            -- S_SGUNUP
		[21] = {"shotgun", "attack", 1},           -- S_SGUN1
		[22] = {"shotgun", "attack", 2},           -- S_SGUN2
		[23] = {"shotgun", "attack", 3},           -- S_SGUN3
		[24] = {"shotgun", "attack", 4},           -- S_SGUN4
		[25] = {"shotgun", "attack", 5},           -- S_SGUN5
		[26] = {"shotgun", "attack", 6},           -- S_SGUN6
		[27] = {"shotgun", "attack", 7},           -- S_SGUN7
		[28] = {"shotgun", "attack", 8},           -- S_SGUN8
		[29] = {"shotgun", "attack", 9},           -- S_SGUN9
		[30] = {"shotgun", "flash", 1},            -- S_SGUNFLASH1
		[31] = {"shotgun", "flash", 2},            -- S_SGUNFLASH2
		
		[32] = {"supershotgun", "idle", 1},        -- S_DSGUN
		[33] = {"supershotgun", "lower", 1},       -- S_DSGUNDOWN
		[34] = {"supershotgun", "raise", 1},       -- S_DSGUNUP
		[35] = {"supershotgun", "attack", 1},      -- S_DSGUN1
		[36] = {"supershotgun", "attack", 2},      -- S_DSGUN2
		[37] = {"supershotgun", "attack", 3},      -- S_DSGUN3
		[38] = {"supershotgun", "attack", 4},      -- S_DSGUN4
		[39] = {"supershotgun", "attack", 5},      -- S_DSGUN5
		[40] = {"supershotgun", "attack", 6},      -- S_DSGUN6
		[41] = {"supershotgun", "attack", 7},      -- S_DSGUN7
		[42] = {"supershotgun", "attack", 8},      -- S_DSGUN8
		[43] = {"supershotgun", "attack", 9},      -- S_DSGUN9
		[44] = {"supershotgun", "attack", 10},     -- S_DSGUN10
		[45] = {"supershotgun", "attack", 11},     -- S_DSNR1 (reload state)
		[46] = {"supershotgun", "attack", 12},     -- S_DSNR2 (reload state)
		[47] = {"supershotgun", "flash", 1},       -- S_DSGUNFLASH1
		[48] = {"supershotgun", "flash", 2},       -- S_DSGUNFLASH2
		
		[49] = {"chaingun", "idle", 1},            -- S_CHAIN
		[50] = {"chaingun", "lower", 1},           -- S_CHAINDOWN
		[51] = {"chaingun", "raise", 1},           -- S_CHAINUP
		[52] = {"chaingun", "attack", 1},          -- S_CHAIN1
		[53] = {"chaingun", "attack", 2},          -- S_CHAIN2
		[54] = {"chaingun", "attack", 3},          -- S_CHAIN3
		[55] = {"chaingun", "flash", 1},           -- S_CHAINFLASH1
		[56] = {"chaingun", "flash", 2},           -- S_CHAINFLASH2
		
		[57] = {"rocketlauncher", "idle", 1},      -- S_MISSILE
		[58] = {"rocketlauncher", "lower", 1},     -- S_MISSILEDOWN
		[59] = {"rocketlauncher", "raise", 1},     -- S_MISSILEUP
		[60] = {"rocketlauncher", "attack", 1},    -- S_MISSILE1
		[61] = {"rocketlauncher", "attack", 2},    -- S_MISSILE2
		[62] = {"rocketlauncher", "attack", 3},    -- S_MISSILE3
		[63] = {"rocketlauncher", "flash", 1},     -- S_MISSILEFLASH1
		[64] = {"rocketlauncher", "flash", 2},     -- S_MISSILEFLASH2
		[65] = {"rocketlauncher", "flash", 3},     -- S_MISSILEFLASH3
		[66] = {"rocketlauncher", "flash", 4},     -- S_MISSILEFLASH4
		
		[67] = {"chainsaw", "idle", 1},            -- S_SAW (first idle frame)
		[68] = {"chainsaw", "idle", 2},            -- S_SAWB (second idle frame)
		[69] = {"chainsaw", "lower", 1},           -- S_SAWDOWN
		[70] = {"chainsaw", "raise", 1},           -- S_SAWUP
		[71] = {"chainsaw", "attack", 1},          -- S_SAW1
		[72] = {"chainsaw", "attack", 2},          -- S_SAW2
		[73] = {"chainsaw", "attack", 3},          -- S_SAW3
		
		[74] = {"plasmarifle", "idle", 1},         -- S_PLASMA
		[75] = {"plasmarifle", "lower", 1},        -- S_PLASMADOWN
		[76] = {"plasmarifle", "raise", 1},        -- S_PLASMAUP
		[77] = {"plasmarifle", "attack", 1},       -- S_PLASMA1
		[78] = {"plasmarifle", "attack", 2},       -- S_PLASMA2
		[79] = {"plasmarifle", "flash", 1},        -- S_PLASMAFLASH1
		[80] = {"plasmarifle", "flash", 2},        -- S_PLASMAFLASH2
		
		[81] = {"bfg9000", "idle", 1},             -- S_BFG
		[82] = {"bfg9000", "lower", 1},            -- S_BFGDOWN
		[83] = {"bfg9000", "raise", 1},            -- S_BFGUP
		[84] = {"bfg9000", "attack", 1},           -- S_BFG1
		[85] = {"bfg9000", "attack", 2},           -- S_BFG2
		[86] = {"bfg9000", "attack", 3},           -- S_BFG3
		[87] = {"bfg9000", "attack", 4},           -- S_BFG4
		[88] = {"bfg9000", "flash", 1},            -- S_BFGFLASH1
		[89] = {"bfg9000", "flash", 2},            -- S_BFGFLASH2
	},
}