DOOM_Freeslot("S_LIGHTDONE", "S_SPAWNFIRE1", "S_SPAWNFIRE2", "S_SPAWNFIRE3", "S_SPAWNFIRE4", "S_SPAWNFIRE5", "S_SPAWNFIRE6", "S_SPAWNFIRE7", "S_SPAWNFIRE8")

states[S_SPAWNFIRE5] = {
	sprite = SPR_FIRE, 
	frame = E|FF_FULLBRIGHT,
	tics = 4
}

doom.dropTable = {
	[MT_DOOM_ZOMBIEMAN] = MT_DOOM_CLIP,
	[MT_DOOM_SSGUARD] = MT_DOOM_CLIP,
	[MT_DOOM_CHAINGUNNER] = MT_DOOM_CHAINGUN,
	[MT_DOOM_SHOTGUNNER] = MT_DOOM_SHOTGUN,
}

doom.bossDeathSpecials = {
	[MT_DOOM_BARONOFHELL] = {
		map = 8,
		tag = 666,
		special = 23,
	},
	/*
	[MT_DOOM_BARONOFHELL] = { -- cyber
		map = 30,
		tag = 666,
		special = 112,
	},
	[MT_DOOM_BARONOFHELL] = { -- spiderdemon
		map = 32,
		tag = 666,
		special = 23,
	},
	[MT_DOOM_BARONOFHELL] = { -- mancubus
		map = 7,
		tag = 666,
		special = 23,
	},
	[MT_DOOM_BARONOFHELL] = { -- arachnotron
		map = 7,
		tag = 667,
		type = 30,
	},
	*/
}

doom.dehackedpointers = {
	sprites = {
		SPR_TROO,
		SPR_SHTG,
		SPR_PUNG,
		SPR_PISG,
		SPR_PISF,
		SPR_SHTF,
		SPR_SHT2,
		SPR_CHGG,
		SPR_CHGF,
		SPR_MISG,
		SPR_MISF,
		SPR_SAWG,
		SPR_PLSG,
		SPR_PLSF,
		SPR_BFGG,
		SPR_BFGF,
		SPR_BLUD,
		SPR_PUFF,
		SPR_BAL1,
		SPR_BAL2,
		SPR_PLSS,
		SPR_PLSE,
		SPR_MISL,
		SPR_BFS1,
		SPR_BFE1,
		SPR_BFE2,
		SPR_TFOG,
		SPR_IFOG,
		SPR_PLAY,
		SPR_POSS,
		SPR_SPOS,
		SPR_VILE,
		SPR_FIRE,
		SPR_FATB,
		SPR_FBXP,
		SPR_SKEL,
		SPR_MANF,
		SPR_FATT,
		SPR_CPOS,
		SPR_SARG,
		SPR_HEAD,
		SPR_BAL7,
		SPR_BOSS,
		SPR_BOS2,
		SPR_SKUL,
		SPR_SPID,
		SPR_BSPI,
		SPR_APLS,
		SPR_APBX,
		SPR_CYBR,
		SPR_PAIN,
		SPR_SSWV,
		SPR_KEEN,
		SPR_BBRN,
		SPR_BOSF,
		SPR_ARM1,
		SPR_ARM2,
		SPR_BAR1,
		SPR_BEXP,
		SPR_FCAN,
		SPR_BON1,
		SPR_BON2,
		SPR_BKEY,
		SPR_RKEY,
		SPR_YKEY,
		SPR_BSKU,
		SPR_RSKU,
		SPR_YSKU,
		SPR_STIM,
		SPR_MEDI,
		SPR_SOUL,
		SPR_PINV,
		SPR_PSTR,
		SPR_PINS,
		SPR_MEGA,
		SPR_SUIT,
		SPR_PMAP,
		SPR_PVIS,
		SPR_CLIP,
		SPR_AMMO,
		SPR_ROCK,
		SPR_BROK,
		SPR_CELL,
		SPR_CELP,
		SPR_SHEL,
		SPR_SBOX,
		SPR_BPAK,
		SPR_BFUG,
		SPR_MGUN,
		SPR_CSAW,
		SPR_LAUN,
		SPR_PLAS,
		SPR_SHOT,
		SPR_SGN2,
		SPR_COLU,
		SPR_SMT2,
		SPR_GOR1,
		SPR_POL2,
		SPR_POL5,
		SPR_POL4,
		SPR_POL3,
		SPR_POL1,
		SPR_POL6,
		SPR_GOR2,
		SPR_GOR3,
		SPR_GOR4,
		SPR_GOR5,
		SPR_SMIT,
		SPR_COL1,
		SPR_COL2,
		SPR_COL3,
		SPR_COL4,
		SPR_CAND,
		SPR_CBRA,
		SPR_COL6,
		SPR_TRE1,
		SPR_TRE2,
		SPR_ELEC,
		SPR_CEYE,
		SPR_FSKU,
		SPR_COL5,
		SPR_TBLU,
		SPR_TGRN,
		SPR_TRED,
		SPR_SMBT,
		SPR_SMGT,
		SPR_SMRT,
		SPR_HDB1,
		SPR_HDB2,
		SPR_HDB3,
		SPR_HDB4,
		SPR_HDB5,
		SPR_HDB6,
		SPR_POB1,
		SPR_POB2,
		SPR_BRS1,
		SPR_TLMP,
		SPR_TLP2
	},

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
		MT_DOOM_PLASMASHOT, -- Plasma Bullet
		nil, -- BFG Shot
		nil, -- Arachnotron Fireball
		[98] = MT_DOOM_STALAGTITE,
		[106] = MT_DOOM_MEAT5,
		[113] = MT_DOOM_CORPSE,
		[119] = MT_DOOM_BLOODYMESS,
		[120] = MT_DOOM_BLOODYMESSEXTRA,
		[121] = MT_DOOM_CRUSHGIBS,
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
		nil,
		sfx_pistol,
		sfx_shotgn,
		sfx_sgcock,
		sfx_dshtgn,
		sfx_dbopn,
		sfx_dbcls,
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
		sfx_skepch,
		sfx_vilatk,
		sfx_claw,
		sfx_skeswg,
		sfx_pldeth,
		sfx_pdiehi,
		sfx_podth1,
		sfx_podth2,
		sfx_podth3,
		sfx_bgdth1,
		sfx_bgdth2,
		sfx_sgtdth,
		sfx_cacdth,
		sfx_skldth,
		sfx_brsdth,
		sfx_cybdth,
		sfx_spidth,
		sfx_bspdth,
		sfx_vildth,
		sfx_kntdth,
		sfx_pedth,
		sfx_skedth,
		sfx_posact,
		sfx_bgact,
		sfx_dmact,
		sfx_bspact,
		sfx_bspwlk,
		sfx_vilact,
		sfx_noway,
		sfx_barexp,
		sfx_punch,
		sfx_hoof,
		sfx_metal,
		sfx_chgun,
		sfx_tink,
		sfx_bdopn,
		sfx_bdcls,
		sfx_itmbk,
		sfx_flame,
		sfx_flamst,
		sfx_getpow,
		sfx_bospit,
		sfx_boscub,
		sfx_bossit,
		sfx_bospn,
		sfx_bosdth,
		sfx_manatk,
		sfx_mandth,
		sfx_sssit,
		sfx_ssdth,
		sfx_keenpn,
		sfx_keendt,
		sfx_skeact,
		sfx_skesit,
		sfx_skeatk,
		sfx_radio,
	},

	frames = {
		[90] = S_DOOM_BLOOD1,
		[91] = S_DOOM_BLOOD2,
		[92] = S_DOOM_BLOOD3,
		[93] = S_DOOM_PUFF1,
		[94] = S_DOOM_PUFF2,
		[95] = S_DOOM_PUFF3,
		[96] = S_DOOM_PUFF4,
		[97] = S_DOOM_IMPFIRE1,
		[98] = S_DOOM_IMPFIRE2,
		[99] = S_DOOM_IMPFIREEXPLODE1,
		[100] = S_DOOM_IMPFIREEXPLODE2,
		[101] = S_DOOM_IMPFIREEXPLODE3,
		[102] = 0, -- S_RBALL1
		[103] = 0, -- S_RBALL2
		[104] = 0, -- S_RBALLX1
		[105] = 0, -- S_RBALLX2
		[106] = 0, -- S_RBALLX3
		[281] = S_DOOM_ARCHVILEFIRE_1,
		[282] = S_DOOM_ARCHVILEFIRE_2,
		[283] = S_DOOM_ARCHVILEFIRE_3,
		[284] = S_DOOM_ARCHVILEFIRE_4,
		[285] = S_DOOM_ARCHVILEFIRE_5,
		[286] = S_DOOM_ARCHVILEFIRE_6,
		[287] = S_DOOM_ARCHVILEFIRE_7,
		[288] = S_DOOM_ARCHVILEFIRE_8,
		[289] = S_DOOM_ARCHVILEFIRE_9,
		[290] = S_DOOM_ARCHVILEFIRE_10,
		[291] = S_DOOM_ARCHVILEFIRE_11,
		[292] = S_DOOM_ARCHVILEFIRE_12,
		[293] = S_DOOM_ARCHVILEFIRE_13,
		[294] = S_DOOM_ARCHVILEFIRE_14,
		[295] = S_DOOM_ARCHVILEFIRE_15,
		[296] = S_DOOM_ARCHVILEFIRE_16,
		[297] = S_DOOM_ARCHVILEFIRE_17,
		[298] = S_DOOM_ARCHVILEFIRE_18,
		[299] = S_DOOM_ARCHVILEFIRE_19,
		[300] = S_DOOM_ARCHVILEFIRE_20,
		[301] = S_DOOM_ARCHVILEFIRE_21,
		[302] = S_DOOM_ARCHVILEFIRE_22,
		[303] = S_DOOM_ARCHVILEFIRE_23,
		[304] = S_DOOM_ARCHVILEFIRE_24,
		[305] = S_DOOM_ARCHVILEFIRE_25,
		[306] = S_DOOM_ARCHVILEFIRE_26,
		[307] = S_DOOM_ARCHVILEFIRE_27,
		[308] = S_DOOM_ARCHVILEFIRE_28,
		[309] = S_DOOM_ARCHVILEFIRE_29,
		[310] = S_DOOM_ARCHVILEFIRE_30,
		[667] = S_DOOM_ARACHPLASMA1,
		[668] = S_DOOM_ARACHPLASMA2,
		[669] = S_DOOM_ARACHPLASMAX1,
		[670] = S_DOOM_ARACHPLASMAX2,
		[671] = S_DOOM_ARACHPLASMAX3,
		[795] = S_SPAWNFIRE5,
		[816] = S_DOOM_HEALTHBONUS_1,
		[817] = S_DOOM_HEALTHBONUS_2,
		[818] = S_DOOM_HEALTHBONUS_3,
		[819] = S_DOOM_HEALTHBONUS_4,
		[820] = S_DOOM_HEALTHBONUS_5,
		[821] = S_DOOM_HEALTHBONUS_6,
		[822] = S_DOOM_ARMORBONUS_1,
		[823] = S_DOOM_ARMORBONUS_2,
		[824] = S_DOOM_ARMORBONUS_3,
		[825] = S_DOOM_ARMORBONUS_4,
		[826] = S_DOOM_ARMORBONUS_5,
		[827] = S_DOOM_ARMORBONUS_6,
		[942] = S_DOOM_SHORTGREENTORCH_1,
		[943] = S_DOOM_SHORTGREENTORCH_2,
		[944] = S_DOOM_SHORTGREENTORCH_3,
		[945] = S_DOOM_SHORTGREENTORCH_4,
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
