local function BulletHitObject(tmthing, thing)
    if tmthing.hitenemy then return false end
    if tmthing.target == thing then return false end
	if not (thing.flags & MF_SHOOTABLE) then return false end

	local damageVal = mobjinfo[tmthing.type].damage
	local damage = (DOOM_Random() % 8 + 1) * damageVal

	tmthing.hitenemy = true
	tmthing.momx = 0
	tmthing.momy = 0
	tmthing.momz = 0
    DOOM_DamageMobj(thing, tmthing, tmthing.target, damage, damagetype)
	P_KillMobj(tmthing)
	S_StartSound(tmthing, mobjinfo[tmthing.type].deathsound)
	return false
end

local projectiles = {
	MT_TROOPSHOT,
	MT_DOOM_PLASMASHOT,
	MT_DOOM_MANCUBUSFIREBALL,
	MT_DOOM_BARONFIREBALL,
	MT_DOOM_ARCHNOTRONPLASMA,
	MT_DOOM_ROCKETPROJ,
}

for _, mt in ipairs(projectiles) do
    addHook("MobjMoveCollide", BulletHitObject, mt)
end

doom.mthingReplacements = {
	[5] = MT_DOOM_BLUEKEYCARD,
	[6] = MT_DOOM_YELLOWKEYCARD,
	[7] = MT_DOOM_SPIDERMASTERMIND,
	[8] = MT_DOOM_BACKPACK,
	[9] = MT_DOOM_SHOTGUNNER,
	[10] = MT_DOOM_BLOODYMESS,
	-- 11 used for deathmatch start
	[12] = MT_DOOM_BLOODYMESSEXTRA,
	[13] = MT_DOOM_REDKEYCARD,
	[14] = MT_DOOM_TELETARGET,
	[15] = MT_DOOM_CORPSE,
	[16] = MT_DOOM_CYBERDEMON,
	[17] = MT_DOOM_CELLPACK,
	[18] = MT_DOOM_DEADZOMBIEMAN,
	[19] = MT_DOOM_DEADSHOTGUNNER,
	[20] = MT_DOOM_DEADIMP,
	[21] = MT_DOOM_DEADDEMON,
	[22] = MT_DOOM_DEADCACODEMON,
	[23] = MT_DOOM_DEADLOSTSOUL,
	[24] = MT_DOOM_CRUSHGIBS,
	[25] = MT_DOOM_DEADSTICK,
	[26] = MT_DOOM_LIVESTICK,
	[27] = MT_DOOM_HEADONASTICK,
	[28] = MT_DOOM_HEADSONASTICK,
	[29] = MT_DOOM_HEADCANDLES,
	[30] = MT_DOOM_TALLGREENCOLUMN,
	[31] = MT_DOOM_SHORTGREENPILLAR,
	[32] = MT_DOOM_TALLREDCOLUMN,
	[33] = MT_DOOM_SHORTREDCOLUMN,
	[34] = MT_DOOM_CANDLESTICK,
	[35] = MT_DOOM_CANDELABRA,
}

doom.immunity = doom.immunity or {}
doom.immunity.excludedSourceTypes = $ or {} -- source types that bypass the checks (like bullet trays/lost souls)
doom.immunity.pairImmunities = $ or {} -- table-of-tables for specific A->B immunity
doom.immunity.ignoreSameType = ($ == nil) and true or $ -- default behaviour: ignore same-type attacks
doom.immunity.noRetaliateAgainst = $ or {} -- types that monsters should not retaliate against (e.g. Arch-Vile)
doom.immunity.noExplosionDamage = $ or {} -- types that are immune to explosion damage (e.g. the Cyberdemon)

-- Helper functions to populate/manage immunities
function doom.setIgnoreSameType(enabled)
    doom.immunity.ignoreSameType = enabled and true or false
end

function doom.addExcludedSourceType(t)
    doom.immunity.excludedSourceTypes[t] = true
end

function doom.addNoExplosionDamageType(t)
    doom.immunity.noExplosionDamage[t] = true
end

function doom.removeExcludedSourceType(t)
    doom.immunity.excludedSourceTypes[t] = nil
end

-- Add pair immunity: if attackerType attacks targetType, target ignores the attack.
function doom.addPairImmunity(attackerType, targetType)
    doom.immunity.pairImmunities[attackerType] = $ or {}
    doom.immunity.pairImmunities[attackerType][targetType] = true
    doom.immunity.pairImmunities[targetType] = $ or {}
    doom.immunity.pairImmunities[targetType][attackerType] = true
end
function doom.removePairImmunity(attackerType, targetType)
    if doom.immunity.pairImmunities[attackerType] then
        doom.immunity.pairImmunities[attackerType][targetType] = nil
    end
end

-- Control which monster types should not be retaliated against (e.g. Arch-Vile)
function doom.setNoRetaliateAgainst(monsterType, enabled)
    if enabled then
        doom.immunity.noRetaliateAgainst[monsterType] = true
    else
        doom.immunity.noRetaliateAgainst[monsterType] = nil
    end
end

doom.addExcludedSourceType(MT_DOOM_BULLETRAYCAST)
doom.addExcludedSourceType(MT_DOOM_LOSTSOUL)

doom.addPairImmunity(MT_DOOM_HELLKNIGHT, MT_DOOM_BARONOFHELL)

doom.setNoRetaliateAgainst(MT_DOOM_ARCHVILE, true)

doom.addNoExplosionDamageType(MT_DOOM_CYBERDEMON)
-- "Later." - Medic TF2
-- doom.addNoExplosionDamageType(MT_DOOM_SPIDERMASTERMIND)

sfxinfo[sfx_pistol].caption = "Pistol Shot"
sfxinfo[sfx_shotgn].caption = "Shotgun Shot"
sfxinfo[sfx_sgcock].caption = "Shotgun Cock" -- shotgun WHAT?! :fearful:
sfxinfo[sfx_dshtgn].caption = "Super Shotgun Firing"
sfxinfo[sfx_dbopn].caption = "Double-barrel Opening"
sfxinfo[sfx_dbcls].caption = "Double-barrel Closing"
sfxinfo[sfx_dbload].caption = "Double-barrel Loaded"
sfxinfo[sfx_plasma].caption = "Plasma Rifle Firing"
sfxinfo[sfx_bfg].caption = "BFG Shot"
sfxinfo[sfx_sawup].caption = "Chainsaw Raising"
sfxinfo[sfx_sawidl].caption = "Chainsaw Idle"
sfxinfo[sfx_sawful].caption = "Chainsaw Miss"
sfxinfo[sfx_sawhit].caption = "Chainsaw Hit"
sfxinfo[sfx_rlaunc].caption = "Rocket Launched"
sfxinfo[sfx_barexp].caption = "Explosion"
sfxinfo[sfx_firsht].caption = "Fireball Shot"
sfxinfo[sfx_firxpl].caption = "Fireball Explosion"
sfxinfo[sfx_noway].caption = "Unf!"
sfxinfo[sfx_oof].caption = "Unf!"
sfxinfo[sfx_slop].caption = "Gibbing noises"
sfxinfo[sfx_swtchn].caption = "Switch activated"
sfxinfo[sfx_swtchx].caption = "Switch deactivated"
sfxinfo[sfx_secret].caption = "A secret is revealed!"
sfxinfo[sfx_itmbk].caption = "Item respawned"

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
	[MT_DOOM_CYBERDEMON] = { -- cyber
		map = 30,
		tag = 666,
		special = 112,
	},
	[MT_DOOM_SPIDERMASTERMIND] = { -- spiderdemon
		map = 36,
		tag = 666,
		special = 23,
	},
	[MT_DOOM_MANCUBUS] = { -- mancubus
		map = 7,
		tag = 666,
		special = 23,
	},
	[MT_DOOM_ARACHNOTRON] = { -- arachnotron
		map = 7,
		tag = 667,
		special = 30,
	},
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
		MT_DOOM_REVENANT, -- Revenant
		nil, -- Revenant Fireball
		nil, -- Fireball Trail
		MT_DOOM_MANCUBUS, -- Mancubus
		MT_DOOM_MANCUBUSFIREBALL, -- Mancubus Fireball
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
		MT_DOOM_CYBERDEMON, -- Cyberdemon
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
		[81] = MT_DOOM_SHORTTECHNOFLOORLAMP,
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
		0,
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
		[0] = S_NULL,
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
		[149] = S_DOOM_PLAYER_STAND1,
		[150] = S_DOOM_PLAYER_MOVE1,
		[151] = S_DOOM_PLAYER_MOVE2,
		[152] = S_DOOM_PLAYER_MOVE3,
		[153] = S_DOOM_PLAYER_MOVE4,
		[154] = S_DOOM_PLAYER_ATTACK1,
		[155] = S_DOOM_PLAYER_FLASH1,
		[156] = S_DOOM_PLAYER_PAIN1,
		[157] = S_DOOM_PLAYER_PAIN2,
		[158] = S_DOOM_PLAYER_DIE1,
		[159] = S_DOOM_PLAYER_DIE2,
		[160] = S_DOOM_PLAYER_DIE3,
		[161] = S_DOOM_PLAYER_DIE4,
		[162] = S_DOOM_PLAYER_DIE5,
		[163] = S_DOOM_PLAYER_DIE6,
		[164] = S_DOOM_PLAYER_DIE7,
		[165] = S_DOOM_PLAYER_GIB1,
		[166] = S_DOOM_PLAYER_GIB2,
		[167] = S_DOOM_PLAYER_GIB3,
		[168] = S_DOOM_PLAYER_GIB4,
		[169] = S_DOOM_PLAYER_GIB5,
		[170] = S_DOOM_PLAYER_GIB6,
		[171] = S_DOOM_PLAYER_GIB7,
		[172] = S_DOOM_PLAYER_GIB8,
		[173] = S_DOOM_PLAYER_GIB9,
		[174] = S_DOOM_ZOMBIEMAN_STAND1,
		[175] = S_DOOM_ZOMBIEMAN_STAND2,
		[176] = S_DOOM_ZOMBIEMAN_CHASE1,
		[177] = S_DOOM_ZOMBIEMAN_CHASE2,
		[178] = S_DOOM_ZOMBIEMAN_CHASE3,
		[179] = S_DOOM_ZOMBIEMAN_CHASE4,
		[180] = S_DOOM_ZOMBIEMAN_CHASE5,
		[181] = S_DOOM_ZOMBIEMAN_CHASE6,
		[182] = S_DOOM_ZOMBIEMAN_CHASE7,
		[183] = S_DOOM_ZOMBIEMAN_CHASE8,
		[184] = S_DOOM_ZOMBIEMAN_MISSILE1,
		[185] = S_DOOM_ZOMBIEMAN_MISSILE2,
		[186] = S_DOOM_ZOMBIEMAN_MISSILE3,
		[187] = S_DOOM_ZOMBIEMAN_PAIN1,
		[188] = S_DOOM_ZOMBIEMAN_PAIN2,
		[189] = S_DOOM_ZOMBIEMAN_DIE1,
		[190] = S_DOOM_ZOMBIEMAN_DIE2,
		[191] = S_DOOM_ZOMBIEMAN_DIE3,
		[192] = S_DOOM_ZOMBIEMAN_DIE4,
		[193] = S_DOOM_ZOMBIEMAN_DIE5,
		[194] = S_DOOM_ZOMBIEMAN_GIB1,
		[195] = S_DOOM_ZOMBIEMAN_GIB2,
		[196] = S_DOOM_ZOMBIEMAN_GIB3,
		[197] = S_DOOM_ZOMBIEMAN_GIB4,
		[198] = S_DOOM_ZOMBIEMAN_GIB5,
		[199] = S_DOOM_ZOMBIEMAN_GIB6,
		[200] = S_DOOM_ZOMBIEMAN_GIB7,
		[201] = S_DOOM_ZOMBIEMAN_GIB8,
		[202] = S_DOOM_ZOMBIEMAN_GIB9,
		[203] = S_DOOM_ZOMBIEMAN_RAISE1,
		[204] = S_DOOM_ZOMBIEMAN_RAISE2,
		[205] = S_DOOM_ZOMBIEMAN_RAISE3,
		[206] = S_DOOM_ZOMBIEMAN_RAISE4,
		[207] = S_DOOM_SHOTGUNNER_STAND1,
		[208] = S_DOOM_SHOTGUNNER_STAND2,
		[209] = S_DOOM_SHOTGUNNER_CHASE1,
		[210] = S_DOOM_SHOTGUNNER_CHASE2,
		[211] = S_DOOM_SHOTGUNNER_CHASE3,
		[212] = S_DOOM_SHOTGUNNER_CHASE4,
		[213] = S_DOOM_SHOTGUNNER_CHASE5,
		[214] = S_DOOM_SHOTGUNNER_CHASE6,
		[215] = S_DOOM_SHOTGUNNER_CHASE7,
		[216] = S_DOOM_SHOTGUNNER_CHASE8,
		[217] = S_DOOM_SHOTGUNNER_MISSILE1,
		[218] = S_DOOM_SHOTGUNNER_MISSILE2,
		[219] = S_DOOM_SHOTGUNNER_MISSILE3,
		[220] = S_DOOM_SHOTGUNNER_PAIN1,
		[221] = S_DOOM_SHOTGUNNER_PAIN2,
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
		[321] = S_DOOM_REVENANT_STAND1,
		[322] = S_DOOM_REVENANT_STAND2,
		[323] = S_DOOM_REVENANT_CHASE1,
		[324] = S_DOOM_REVENANT_CHASE2,
		[325] = S_DOOM_REVENANT_CHASE3,
		[326] = S_DOOM_REVENANT_CHASE4,
		[327] = S_DOOM_REVENANT_CHASE5,
		[328] = S_DOOM_REVENANT_CHASE6,
		[329] = S_DOOM_REVENANT_CHASE7,
		[330] = S_DOOM_REVENANT_CHASE8,
		[331] = S_DOOM_REVENANT_CHASE9,
		[332] = S_DOOM_REVENANT_CHASE10,
		[333] = S_DOOM_REVENANT_CHASE11,
		[334] = S_DOOM_REVENANT_CHASE12,
		[335] = S_DOOM_REVENANT_MELEE1,
		[336] = S_DOOM_REVENANT_MELEE2,
		[337] = S_DOOM_REVENANT_MELEE3,
		[338] = S_DOOM_REVENANT_MELEE4,
		[339] = S_DOOM_REVENANT_MISSILE1,
		[340] = S_DOOM_REVENANT_MISSILE2,
		[341] = S_DOOM_REVENANT_MISSILE3,
		[342] = S_DOOM_REVENANT_MISSILE4,
		[343] = S_DOOM_REVENANT_PAIN1,
		[344] = S_DOOM_REVENANT_PAIN2,
		[345] = S_DOOM_REVENANT_DIE1,
		[346] = S_DOOM_REVENANT_DIE2,
		[347] = S_DOOM_REVENANT_DIE3,
		[348] = S_DOOM_REVENANT_DIE4,
		[349] = S_DOOM_REVENANT_DIE5,
		[350] = S_DOOM_REVENANT_DIE6,
		[351] = S_DOOM_REVENANT_RAISE1,
		[352] = S_DOOM_REVENANT_RAISE2,
		[353] = S_DOOM_REVENANT_RAISE3,
		[354] = S_DOOM_REVENANT_RAISE4,
		[355] = S_DOOM_REVENANT_RAISE5,
		[356] = S_DOOM_REVENANT_RAISE6,
		[416] = S_DOOM_CHAINGUNNER_MISSILE1,
		[417] = S_DOOM_CHAINGUNNER_MISSILE2,
		[418] = S_DOOM_CHAINGUNNER_MISSILE3,
		[419] = S_DOOM_CHAINGUNNER_MISSILE4,
		[442] = S_DOOM_IMP_STAND1,
		[443] = S_DOOM_IMP_STAND2,
		[444] = S_DOOM_IMP_CHASE1,
		[445] = S_DOOM_IMP_CHASE2,
		[446] = S_DOOM_IMP_CHASE3,
		[447] = S_DOOM_IMP_CHASE4,
		[448] = S_DOOM_IMP_CHASE5,
		[449] = S_DOOM_IMP_CHASE6,
		[450] = S_DOOM_IMP_CHASE7,
		[451] = S_DOOM_IMP_CHASE8,
		[452] = S_DOOM_IMP_ATTACK1,
		[453] = S_DOOM_IMP_ATTACK2,
		[454] = S_DOOM_IMP_ATTACK3,
		[455] = S_DOOM_IMP_PAIN1,
		[456] = S_DOOM_IMP_PAIN2,
		[632] = S_DOOM_ARACHNOTRON_STAND1,
		[633] = S_DOOM_ARACHNOTRON_STAND2,
		[634] = S_DOOM_ARACHNOTRON_CHASE1,
		[635] = S_DOOM_ARACHNOTRON_CHASE2,
		[636] = S_DOOM_ARACHNOTRON_CHASE3,
		[637] = S_DOOM_ARACHNOTRON_CHASE4,
		[638] = S_DOOM_ARACHNOTRON_CHASE5,
		[639] = S_DOOM_ARACHNOTRON_CHASE6,
		[640] = S_DOOM_ARACHNOTRON_CHASE7,
		[641] = S_DOOM_ARACHNOTRON_CHASE8,
		[642] = S_DOOM_ARACHNOTRON_CHASE9,
		[643] = S_DOOM_ARACHNOTRON_CHASE10,
		[644] = S_DOOM_ARACHNOTRON_CHASE11,
		[645] = S_DOOM_ARACHNOTRON_CHASE12,
		[646] = S_DOOM_ARACHNOTRON_CHASE13,
		[647] = S_DOOM_ARACHNOTRON_MISSILE1,
		[648] = S_DOOM_ARACHNOTRON_MISSILE2,
		[649] = S_DOOM_ARACHNOTRON_MISSILE3,
		[650] = S_DOOM_ARACHNOTRON_MISSILE4,
		[651] = S_DOOM_ARACHNOTRON_PAIN1,
		[652] = S_DOOM_ARACHNOTRON_PAIN2,
		[653] = S_DOOM_ARACHNOTRON_DIE1,
		[654] = S_DOOM_ARACHNOTRON_DIE2,
		[655] = S_DOOM_ARACHNOTRON_DIE3,
		[656] = S_DOOM_ARACHNOTRON_DIE4,
		[657] = S_DOOM_ARACHNOTRON_DIE5,
		[658] = S_DOOM_ARACHNOTRON_DIE6,
		[659] = S_DOOM_ARACHNOTRON_DIE7,
		[660] = S_DOOM_ARACHNOTRON_RAISE1,
		[661] = S_DOOM_ARACHNOTRON_RAISE2,
		[662] = S_DOOM_ARACHNOTRON_RAISE3,
		[663] = S_DOOM_ARACHNOTRON_RAISE4,
		[664] = S_DOOM_ARACHNOTRON_RAISE5,
		[665] = S_DOOM_ARACHNOTRON_RAISE6,
		[666] = S_DOOM_ARACHNOTRON_RAISE7,
		[667] = S_DOOM_ARACHPLASMA1,
		[668] = S_DOOM_ARACHPLASMA2,
		[669] = S_DOOM_ARACHPLASMAX1,
		[670] = S_DOOM_ARACHPLASMAX2,
		[671] = S_DOOM_ARACHPLASMAX3,
		[672] = S_DOOM_ARACHPLASMAX4,
		[673] = S_DOOM_ARACHPLASMAX5,
		[674] = S_DOOM_CYBERDEMON_STAND1,
		[675] = S_DOOM_CYBERDEMON_STAND2,
		[676] = S_DOOM_CYBERDEMON_CHASE1,
		[677] = S_DOOM_CYBERDEMON_CHASE2,
		[678] = S_DOOM_CYBERDEMON_CHASE3,
		[679] = S_DOOM_CYBERDEMON_CHASE4,
		[680] = S_DOOM_CYBERDEMON_CHASE5,
		[681] = S_DOOM_CYBERDEMON_CHASE6,
		[682] = S_DOOM_CYBERDEMON_CHASE7,
		[683] = S_DOOM_CYBERDEMON_CHASE8,
		[684] = S_DOOM_CYBERDEMON_MISSILE1,
		[685] = S_DOOM_CYBERDEMON_MISSILE2,
		[686] = S_DOOM_CYBERDEMON_MISSILE3,
		[687] = S_DOOM_CYBERDEMON_MISSILE4,
		[688] = S_DOOM_CYBERDEMON_MISSILE5,
		[689] = S_DOOM_CYBERDEMON_MISSILE6,
		[690] = S_DOOM_CYBERDEMON_PAIN1,
		[691] = S_DOOM_CYBERDEMON_DIE1,
		[692] = S_DOOM_CYBERDEMON_DIE2,
		[693] = S_DOOM_CYBERDEMON_DIE3,
		[694] = S_DOOM_CYBERDEMON_DIE4,
		[695] = S_DOOM_CYBERDEMON_DIE5,
		[696] = S_DOOM_CYBERDEMON_DIE6,
		[697] = S_DOOM_CYBERDEMON_DIE7,
		[698] = S_DOOM_CYBERDEMON_DIE8,
		[699] = S_DOOM_CYBERDEMON_DIE9,
		[700] = S_DOOM_CYBERDEMON_DIE10,
		[726] = S_DOOM_SSGUARD_STAND1,
		[727] = S_DOOM_SSGUARD_STAND2,
		[728] = S_DOOM_SSGUARD_CHASE1,
		[729] = S_DOOM_SSGUARD_CHASE2,
		[730] = S_DOOM_SSGUARD_CHASE3,
		[731] = S_DOOM_SSGUARD_CHASE4,
		[732] = S_DOOM_SSGUARD_CHASE5,
		[733] = S_DOOM_SSGUARD_CHASE6,
		[734] = S_DOOM_SSGUARD_CHASE7,
		[735] = S_DOOM_SSGUARD_CHASE8,
		[736] = S_DOOM_SSGUARD_MISSILE1,
		[737] = S_DOOM_SSGUARD_MISSILE2,
		[738] = S_DOOM_SSGUARD_MISSILE3,
		[739] = S_DOOM_SSGUARD_MISSILE4,
		[740] = S_DOOM_SSGUARD_MISSILE5,
		[741] = S_DOOM_SSGUARD_MISSILE6,
		[742] = S_DOOM_SSGUARD_PAIN1,
		[743] = S_DOOM_SSGUARD_PAIN2,
		[744] = S_DOOM_SSGUARD_DIE1,
		[745] = S_DOOM_SSGUARD_DIE2,
		[746] = S_DOOM_SSGUARD_DIE3,
		[747] = S_DOOM_SSGUARD_DIE4,
		[748] = S_DOOM_SSGUARD_DIE5,
		[749] = S_DOOM_SSGUARD_GIB1,
		[750] = S_DOOM_SSGUARD_GIB2,
		[751] = S_DOOM_SSGUARD_GIB3,
		[752] = S_DOOM_SSGUARD_GIB4,
		[753] = S_DOOM_SSGUARD_GIB5,
		[754] = S_DOOM_SSGUARD_GIB6,
		[755] = S_DOOM_SSGUARD_GIB7,
		[756] = S_DOOM_SSGUARD_GIB8,
		[757] = S_DOOM_SSGUARD_GIB9,
		[758] = S_DOOM_SSGUARD_RAISE1,
		[759] = S_DOOM_SSGUARD_RAISE2,
		[760] = S_DOOM_SSGUARD_RAISE3,
		[761] = S_DOOM_SSGUARD_RAISE4,
		[762] = S_DOOM_SSGUARD_RAISE5,
		[763] = S_DOOM_KEEN_STAND1,
		[764] = S_DOOM_KEEN_DIE1,
		[765] = S_DOOM_KEEN_DIE2,
		[766] = S_DOOM_KEEN_DIE3,
		[767] = S_DOOM_KEEN_DIE4,
		[768] = S_DOOM_KEEN_DIE5,
		[769] = S_DOOM_KEEN_DIE6,
		[770] = S_DOOM_KEEN_DIE7,
		[771] = S_DOOM_KEEN_DIE8,
		[772] = S_DOOM_KEEN_DIE9,
		[773] = S_DOOM_KEEN_DIE10,
		[774] = S_DOOM_KEEN_DIE11,
		[775] = S_DOOM_KEEN_DIE12,
		[776] = S_DOOM_KEEN_PAIN1,
		[777] = S_DOOM_KEEN_PAIN2,
		[784] = S_DOOM_MONSTERSPAWNER_STAND1,
		[785] = S_DOOM_MONSTERSPAWNER_CHASE1,
		[786] = S_DOOM_MONSTERSPAWNER_CHASE2,
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
		[963] = S_DOOM_SHORTTECHNOFLOORLAMP_1,
		[964] = S_DOOM_SHORTTECHNOFLOORLAMP_2,
		[965] = S_DOOM_SHORTTECHNOFLOORLAMP_3,
		[966] = S_DOOM_SHORTTECHNOFLOORLAMP_4,
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