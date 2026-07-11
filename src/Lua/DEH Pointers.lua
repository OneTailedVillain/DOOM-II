local function BulletHitObject(tmthing, thing)
	if not (tmthing and tmthing.valid) then return false end
	if doom.missileHookIgnoreList[tmthing.type] then return false end
    if tmthing.hitenemy then return false end
    if tmthing.target == thing then return false end
	if not (thing.flags & MF_SHOOTABLE) then return false end

	-- thing's bounds
	local thingbottom = thing.z
	local thingtop = thing.z + thing.height

	-- projectile bounds
	local bulletbottom = tmthing.z
	local bullettop = tmthing.z + tmthing.height

	if bullettop < thingbottom or bulletbottom > thingtop then
		return false
	end

	local damageVal = mobjinfo[tmthing.type].damage
	local damage
	if tmthing.doom.damage != nil then
		damage = tmthing.doom.damage
	else
		damage = (DOOM_Random() % 8 + 1) * damageVal
	end

	tmthing.hitenemy = true
	tmthing.momx = 0
	tmthing.momy = 0
	tmthing.momz = 0
    DOOM_DamageMobj(thing, tmthing, tmthing.target, damage, damagetype)
	P_KillMobj(tmthing)
	if not (tmthing and tmthing.valid) then return false end
	S_StartSound(tmthing, mobjinfo[tmthing.type].deathsound)
	return false
end

doom.missileHookIgnoreList = {
	[MT_DOOM_BULLETRAYCAST] = true
}

function doom.addToIgnoreList(mt)
	doom.missileHookIgnoreList[mt] = true
end

local function addMobjHookByFlags(hookType, mobjFlags, hook)
    local hookedMobjTypes = {}

	local function addShit()
        for mt = 0, #mobjinfo - 1 do
			if doom.missileHookIgnoreList[mt] then continue end
            if mobjinfo[mt].flags & mobjFlags and not hookedMobjTypes[mt] then
                addHook(hookType, hook, mt)
                hookedMobjTypes[mt] = true
            end
        end
	end

    addHook("AddonLoaded", addShit)
	addShit()
end

addMobjHookByFlags("MobjMoveCollide", MF_MISSILE, BulletHitObject)

doom.mthingReplacements = {}

doom.deathmatchDoomEdNum = 11

-- Array of what each player start goes to in-editor
doom.playerStartMap = {
	1,
	2,
	3,
	4,
	--#ifdef DOOM
	4001,
	4002,
	4003,
	4004,
	--#elif HEXEN
	-- Unsure why Hexen places its extended player starts all the way down here
	9100,
	9101,
	9102,
	9103,
	--#elif STRIFE
	5,
	6,
	7,
	8,
	--#endif
}

-- Automatically build based on every defined object's mobjinfo
for i = 0, INT32_MAX do
	local def
	local ok = pcall(function() def = mobjinfo[i] end)
	if not ok or not def then
		break -- out of range
	end

	if def.doomednum and def.doomednum <= 35 then
		doom.mthingReplacements[def.doomednum] = i
	end
end

do
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
doom.addNoExplosionDamageType(MT_DOOM_SPIDERMASTERMIND)
end

do
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
end

-- DeHackEd bullshit
DOOM_Freeslot("S_DOOM_UNUSED_DEADTORSO",
"S_DOOM_UNUSED_DEADBOTTOM", "SPR_SMT2",
"S_DOOM_UNUSED_STALAG")

states[S_DOOM_UNUSED_DEADTORSO] = {
	sprite = SPR_FIRE,
	frame = 13,
	tics = -1,
	action = nil,
	var1 = nil,
	var2 = nil,
	nextstate = S_NULL
}

states[S_DOOM_UNUSED_DEADBOTTOM] = {
	sprite = SPR_FIRE,
	frame = 18,
	tics = -1,
	action = nil,
	var1 = nil,
	var2 = nil,
	nextstate = S_NULL
}

states[S_DOOM_UNUSED_STALAG] = {
	sprite = SPR_SMT2,
	frame = 1,
	tics = -1,
	action = nil,
	var1 = nil,
	var2 = nil,
	nextstate = S_NULL
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
		SPR_NULL,
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
		[1] = MT_PLAYER,
		[2] = MT_DOOM_ZOMBIEMAN,
		[3] = MT_DOOM_SHOTGUNNER,
		[4] = MT_DOOM_ARCHVILE,
		[5] = MT_DOOM_ARCHVILEFIRE, -- Archvile Attack
		[6] = MT_DOOM_REVENANT, -- Revenant
		[7] = MT_DOOM_REVENANT_PROJECTILE, -- Revenant Fireball
		[8] = MT_DOOM_REVENANT_TRACER, -- Fireball Trail
		[9] = MT_DOOM_MANCUBUS, -- Mancubus
		[10] = MT_DOOM_MANCUBUSFIREBALL, -- Mancubus Fireball
		[11] = MT_DOOM_CHAINGUNNER,
		[12] = MT_DOOM_IMP,
		[13] = MT_DOOM_DEMON,
		[14] = MT_DOOM_SPECTRE,
		[15] = MT_DOOM_CACODEMON,
		[16] = MT_DOOM_BARONOFHELL,
		[17] = MT_DOOM_BARONFIREBALL, -- Baron Fireball
		[18] = MT_DOOM_HELLKNIGHT,
		[19] = MT_DOOM_LOSTSOUL,
		[20] = MT_DOOM_SPIDERMASTERMIND,
		[21] = MT_DOOM_ARACHNOTRON,
		[22] = MT_DOOM_CYBERDEMON,
		[23] = MT_DOOM_PAINELEMENTAL, -- Pain Elemental
		[24] = MT_DOOM_SSGUARD, -- aka "SS Nazi"
		[25] = MT_DOOM_KEEN, -- aka "Commander Keen"
		[26] = MT_DOOM_ROMEROHEAD, -- aka "Icon of Sin"
		[27] = MT_DOOM_MONSTERSPAWNER, -- aka "Demon Spawner"
		[28] = MT_DOOM_BOSSTARGET, -- aka "Demon Spawn Spot"
		[29] = nil, -- Demon Spawn Cube
		[30] = MT_DOOM_SPAWNFIRE, -- Demon Spawn Fire
		[31] = MT_DOOM_BARREL,
		[32] = MT_TROOPSHOT, -- aka "Imp Fireball"
		[33] = MT_DOOM_CACODEMONSHOT, -- Cacodemon Fireball
		[34] = MT_DOOM_ROCKETPROJ,
		[35] = MT_DOOM_PLASMASHOT, -- Plasma Bullet
		[36] = MT_DOOM_BFGBALL, -- BFG Shot
		[37] = MT_DOOM_ARCHNOTRONPLASMA, -- Arachnotron Fireball
		[38] = MT_DOOM_BULLETPUFF, -- Bullet Puff
		[39] = MT_DOOM_BLOOD, -- Blood Splat
		[40] = MT_DOOM_TELEFOG, -- Telefog
		[41] = nil, -- Item Respawn Fog
		[42] = MT_DOOM_TELETARGET, -- Teleport Exit
		[43] = nil, -- BFG Hit
		[44] = MT_DOOM_SECURITYARMOR,
		[45] = MT_DOOM_COMBATARMOR,
		[46] = MT_DOOM_HEALTHBONUS,
		[47] = MT_DOOM_ARMORBONUS,
		[48] = MT_DOOM_BLUEKEYCARD,
		[49] = MT_DOOM_REDKEYCARD,
		[50] = MT_DOOM_YELLOWKEYCARD,
		[51] = MT_DOOM_YELLOWSKULL,
		[52] = MT_DOOM_REDSKULL,
		[53] = MT_DOOM_BLUESKULL,
		[54] = MT_DOOM_STIMPACK,
		[55] = MT_DOOM_MEDIKIT,
		[56] = MT_DOOM_SOULSPHERE,
		[57] = MT_DOOM_INVULNSPHERE,
		[58] = MT_DOOM_BERSERK,
		[59] = MT_DOOM_BLURSPHERE,
		[77] = MT_DOOM_PLASMARIFLE,
		[78] = MT_DOOM_SHOTGUN,
		[79] = MT_DOOM_SUPERSHOTGUN,
		[80] = MT_DOOM_TALLTECHNOFLOORLAMP,
		[81] = MT_DOOM_SHORTTECHNOFLOORLAMP,
		[83] = MT_DOOM_TALLGREENCOLUMN,
		[89] = MT_DOOM_EVILEYE,
		[90] = MT_DOOM_FLOATINGSKULL,
		[91] = MT_DOOM_TORCHTREE,
		[92] = MT_DOOM_BLUETORCH,
		[93] = MT_DOOM_GREENTORCH,
		[94] = MT_DOOM_REDTORCH,
		[95] = MT_DOOM_SHORTBLUETORCH,
		[96] = MT_DOOM_SHORTGREENTORCH,
		[97] = MT_DOOM_SHORTREDTORCH,
		[98] = MT_DOOM_STALAGTITE,
		[101] = MT_DOOM_CANDELABRA,
		[106] = MT_DOOM_MEAT5,
		[107] = MT_DOOM_NONSOLIDMEAT2,
		[108] = MT_DOOM_NONSOLIDMEAT4,
		[109] = MT_DOOM_NONSOLIDMEAT3,
		[110] = MT_DOOM_NONSOLIDMEAT5,
		[111] = MT_DOOM_NONSOLIDTWITCH,
		[112] = MT_DOOM_DEADCACODEMON,
		[113] = MT_DOOM_CORPSE,
		[114] = MT_DOOM_DEADZOMBIEMAN,
		[115] = MT_DOOM_DEADDEMON,
		[116] = MT_DOOM_DEADLOSTSOUL,
		[117] = MT_DOOM_DEADIMP,
		[118] = MT_DOOM_DEADSHOTGUNNER,
		[119] = MT_DOOM_BLOODYMESS,
		[120] = MT_DOOM_BLOODYMESSEXTRA,
		[121] = MT_DOOM_CRUSHGIBS,
		[122] = MT_DOOM_CRUSHGIBS,
		[123] = MT_DOOM_HEADONASTICK,
		[124] = MT_DOOM_HEADCANDLES,
		[125] = MT_DOOM_DEADSTICK,
		[126] = MT_DOOM_LIVESTICK,
		[127] = MT_DOOM_BIGTREE,
		[128] = MT_DOOM_FLAMINGBARREL,
		[129] = MT_DOOM_HANGNOGUTS,
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
		[0] = 0,
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
		-- MBF helper dog sounds
		sfx_dgsit,
		sfx_dgatk,
		sfx_dgact,
		sfx_dgdth,
		sfx_dgpain,
	},

	frames = {
		--#region weapons
		[0] = S_NULL,
		[1] = S_DOOM_LIGHTDONE,
		[2] = S_DOOM_BRASSKNUCKLES_IDLE1,           -- S_PUNCH
		[3] = S_DOOM_BRASSKNUCKLES_LOWER1,          -- S_PUNCHDOWN
		[4] = S_DOOM_BRASSKNUCKLES_RAISE1,          -- S_PUNCHUP
		[5] = S_DOOM_BRASSKNUCKLES_ATTACK1,         -- S_PUNCH1
		[6] = S_DOOM_BRASSKNUCKLES_ATTACK2,         -- S_PUNCH2
		[7] = S_DOOM_BRASSKNUCKLES_ATTACK3,         -- S_PUNCH3
		[8] = S_DOOM_BRASSKNUCKLES_ATTACK4,         -- S_PUNCH4
		[9] = S_DOOM_BRASSKNUCKLES_ATTACK5,         -- S_PUNCH5

		[10] = S_DOOM_PISTOL_IDLE1,                 -- S_PISTOL
		[11] = S_DOOM_PISTOL_LOWER1,                -- S_PISTOLDOWN
		[12] = S_DOOM_PISTOL_RAISE1,                -- S_PISTOLUP
		[13] = S_DOOM_PISTOL_ATTACK1,               -- S_PISTOL1
		[14] = S_DOOM_PISTOL_ATTACK2,               -- S_PISTOL2
		[15] = S_DOOM_PISTOL_ATTACK3,               -- S_PISTOL3
		[16] = S_DOOM_PISTOL_ATTACK4,               -- S_PISTOL4
		[17] = S_DOOM_PISTOL_FLASH1,                -- S_PISTOLFLASH

		[18] = S_DOOM_SHOTGUN_IDLE1,                -- S_SGUN
		[19] = S_DOOM_SHOTGUN_LOWER1,               -- S_SGUNDOWN
		[20] = S_DOOM_SHOTGUN_RAISE1,               -- S_SGUNUP
		[21] = S_DOOM_SHOTGUN_ATTACK1,              -- S_SGUN1
		[22] = S_DOOM_SHOTGUN_ATTACK2,              -- S_SGUN2
		[23] = S_DOOM_SHOTGUN_ATTACK3,              -- S_SGUN3
		[24] = S_DOOM_SHOTGUN_ATTACK4,              -- S_SGUN4
		[25] = S_DOOM_SHOTGUN_ATTACK5,              -- S_SGUN5
		[26] = S_DOOM_SHOTGUN_ATTACK6,              -- S_SGUN6
		[27] = S_DOOM_SHOTGUN_ATTACK7,              -- S_SGUN7
		[28] = S_DOOM_SHOTGUN_ATTACK8,              -- S_SGUN8
		[29] = S_DOOM_SHOTGUN_ATTACK9,              -- S_SGUN9
		[30] = S_DOOM_SHOTGUN_FLASH1,               -- S_SGUNFLASH1
		[31] = S_DOOM_SHOTGUN_FLASH2,               -- S_SGUNFLASH2

		[32] = S_DOOM_SUPERSHOTGUN_IDLE1,           -- S_DSGUN
		[33] = S_DOOM_SUPERSHOTGUN_LOWER1,          -- S_DSGUNDOWN
		[34] = S_DOOM_SUPERSHOTGUN_RAISE1,          -- S_DSGUNUP
		[35] = S_DOOM_SUPERSHOTGUN_ATTACK1,         -- S_DSGUN1
		[36] = S_DOOM_SUPERSHOTGUN_ATTACK2,         -- S_DSGUN2
		[37] = S_DOOM_SUPERSHOTGUN_ATTACK3,         -- S_DSGUN3
		[38] = S_DOOM_SUPERSHOTGUN_ATTACK4,         -- S_DSGUN4
		[39] = S_DOOM_SUPERSHOTGUN_ATTACK5,         -- S_DSGUN5
		[40] = S_DOOM_SUPERSHOTGUN_ATTACK6,         -- S_DSGUN6
		[41] = S_DOOM_SUPERSHOTGUN_ATTACK7,         -- S_DSGUN7
		[42] = S_DOOM_SUPERSHOTGUN_ATTACK8,         -- S_DSGUN8
		[43] = S_DOOM_SUPERSHOTGUN_ATTACK9,         -- S_DSGUN9
		[44] = S_DOOM_SUPERSHOTGUN_ATTACK10,        -- S_DSGUN10
		[45] = S_DOOM_SUPERSHOTGUN_ATTACK11,        -- S_DSNR1 (reload state)
		[46] = S_DOOM_SUPERSHOTGUN_ATTACK12,        -- S_DSNR2 (reload state)
		[47] = S_DOOM_SUPERSHOTGUN_FLASH1,          -- S_DSGUNFLASH1
		[48] = S_DOOM_SUPERSHOTGUN_FLASH2,          -- S_DSGUNFLASH2

		[49] = S_DOOM_CHAINGUN_IDLE1,               -- S_CHAIN
		[50] = S_DOOM_CHAINGUN_LOWER1,              -- S_CHAINDOWN
		[51] = S_DOOM_CHAINGUN_RAISE1,              -- S_CHAINUP
		[52] = S_DOOM_CHAINGUN_ATTACK1,             -- S_CHAIN1
		[53] = S_DOOM_CHAINGUN_ATTACK2,             -- S_CHAIN2
		[54] = S_DOOM_CHAINGUN_ATTACK3,             -- S_CHAIN3
		[55] = S_DOOM_CHAINGUN_FLASH1,              -- S_CHAINFLASH1
		[56] = S_DOOM_CHAINGUN_FLASH2,              -- S_CHAINFLASH2

		[57] = S_DOOM_ROCKETLAUNCHER_IDLE1,         -- S_MISSILE
		[58] = S_DOOM_ROCKETLAUNCHER_LOWER1,        -- S_MISSILEDOWN
		[59] = S_DOOM_ROCKETLAUNCHER_RAISE1,        -- S_MISSILEUP
		[60] = S_DOOM_ROCKETLAUNCHER_ATTACK1,       -- S_MISSILE1
		[61] = S_DOOM_ROCKETLAUNCHER_ATTACK2,       -- S_MISSILE2
		[62] = S_DOOM_ROCKETLAUNCHER_ATTACK3,       -- S_MISSILE3
		[63] = S_DOOM_ROCKETLAUNCHER_FLASH1,        -- S_MISSILEFLASH1
		[64] = S_DOOM_ROCKETLAUNCHER_FLASH2,        -- S_MISSILEFLASH2
		[65] = S_DOOM_ROCKETLAUNCHER_FLASH3,        -- S_MISSILEFLASH3
		[66] = S_DOOM_ROCKETLAUNCHER_FLASH4,        -- S_MISSILEFLASH4

		[67] = S_DOOM_CHAINSAW_IDLE1,               -- S_SAW (first idle frame)
		[68] = S_DOOM_CHAINSAW_IDLE2,               -- S_SAWB (second idle frame)
		[69] = S_DOOM_CHAINSAW_LOWER1,              -- S_SAWDOWN
		[70] = S_DOOM_CHAINSAW_RAISE1,              -- S_SAWUP
		[71] = S_DOOM_CHAINSAW_ATTACK1,             -- S_SAW1
		[72] = S_DOOM_CHAINSAW_ATTACK2,             -- S_SAW2
		[73] = S_DOOM_CHAINSAW_ATTACK3,             -- S_SAW3

		[74] = S_DOOM_PLASMARIFLE_IDLE1,            -- S_PLASMA
		[75] = S_DOOM_PLASMARIFLE_LOWER1,           -- S_PLASMADOWN
		[76] = S_DOOM_PLASMARIFLE_RAISE1,           -- S_PLASMAUP
		[77] = S_DOOM_PLASMARIFLE_ATTACK1,          -- S_PLASMA1
		[78] = S_DOOM_PLASMARIFLE_ATTACK2,          -- S_PLASMA2
		[79] = S_DOOM_PLASMARIFLE_FLASH1,           -- S_PLASMAFLASH1
		[80] = S_DOOM_PLASMARIFLE_FLASH2,           -- S_PLASMAFLASH2

		[81] = S_DOOM_BFG9000_IDLE1,                -- S_BFG
		[82] = S_DOOM_BFG9000_LOWER1,               -- S_BFGDOWN
		[83] = S_DOOM_BFG9000_RAISE1,               -- S_BFGUP
		[84] = S_DOOM_BFG9000_ATTACK1,              -- S_BFG1
		[85] = S_DOOM_BFG9000_ATTACK2,              -- S_BFG2
		[86] = S_DOOM_BFG9000_ATTACK3,              -- S_BFG3
		[87] = S_DOOM_BFG9000_ATTACK4,              -- S_BFG4
		[88] = S_DOOM_BFG9000_FLASH1,               -- S_BFGFLASH1
		[89] = S_DOOM_BFG9000_FLASH2,               -- S_BFGFLASH2
		--#endregion weapons
		[90] = S_DOOM_BPUFF_BLOOD1,
		[91] = S_DOOM_BPUFF_BLOOD2,
		[92] = S_DOOM_BPUFF_BLOOD3,
		[93] = S_DOOM_BPUFF_PUFF1,
		[94] = S_DOOM_BPUFF_PUFF2,
		[95] = S_DOOM_BPUFF_PUFF3,
		[96] = S_DOOM_BPUFF_PUFF4,
		[97] = S_DOOM_IMPFIREBALL_SHOT1,
		[98] = S_DOOM_IMPFIREBALL_SHOT2,
		[99] = S_DOOM_IMPFIREBALL_EXPLODE1,
		[100] = S_DOOM_IMPFIREBALL_EXPLODE2,
		[101] = S_DOOM_IMPFIREBALL_EXPLODE3,
		[102] = S_DOOM_CACODEMONSHOT_SHOT1,
		[103] = S_DOOM_CACODEMONSHOT_SHOT2,
		[104] = S_DOOM_CACODEMONSHOT_EXPLODE1,
		[105] = S_DOOM_CACODEMONSHOT_EXPLODE2,
		[106] = S_DOOM_CACODEMONSHOT_EXPLODE3,
		[107] = S_DOOM_PLASMA_SHOT1,
		[108] = S_DOOM_PLASMA_SHOT2,
		[109] = S_DOOM_PLASMA_EXPLODE1,
		[110] = S_DOOM_PLASMA_EXPLODE2,
		[111] = S_DOOM_PLASMA_EXPLODE3,
		[112] = S_DOOM_PLASMA_EXPLODE4,
		[113] = S_DOOM_PLASMA_EXPLODE5,
		[114] = S_ROCKET_SPAWN,
		[115] = S_DOOM_BFGBALL_SHOT1,
		[116] = S_DOOM_BFGBALL_SHOT1,
		[117] = S_DOOM_BFGBALL_EXPLODE1,
		[118] = S_DOOM_BFGBALL_EXPLODE2,
		[119] = S_DOOM_BFGBALL_EXPLODE3,
		[120] = S_DOOM_BFGBALL_EXPLODE4,
		[121] = S_DOOM_BFGBALL_EXPLODE5,
		[122] = S_DOOM_BFGBALL_EXPLODE6,
		-- gap, BFG tracers
		[127] = S_ROCKET_EXPLODE1,
		[128] = S_ROCKET_EXPLODE2,
		[129] = S_ROCKET_EXPLODE3,
		--#region Telefog
		[130] = S_DOOM_TELEFOG_SPAWN1,
		[131] = S_DOOM_TELEFOG_SPAWN2,
		[132] = S_DOOM_TELEFOG_SPAWN3,
		[133] = S_DOOM_TELEFOG_SPAWN4,
		[134] = S_DOOM_TELEFOG_SPAWN5,
		[135] = S_DOOM_TELEFOG_SPAWN6,
		[136] = S_DOOM_TELEFOG_SPAWN7,
		[137] = S_DOOM_TELEFOG_SPAWN8,
		[138] = S_DOOM_TELEFOG_SPAWN9,
		[139] = S_DOOM_TELEFOG_SPAWN10,
		[140] = S_DOOM_TELEFOG_SPAWN11,
		[141] = S_DOOM_TELEFOG_SPAWN12,
		--#endregion Telefog
		--#region Itemfog
		[142] = S_DOOM_ITEMFOG_SPAWN1,
		[143] = S_DOOM_ITEMFOG_SPAWN2,
		[144] = S_DOOM_ITEMFOG_SPAWN3,
		[145] = S_DOOM_ITEMFOG_SPAWN4,
		[146] = S_DOOM_ITEMFOG_SPAWN5,
		[147] = S_DOOM_ITEMFOG_SPAWN6,
		[148] = S_DOOM_ITEMFOG_SPAWN7,
		--#endregion Itemfog
		--#region Player
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
		--#endregion Player
		--#region Zombieman
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
		--#endregion Zombieman
		--#region Shotgunner
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
		[222] = S_DOOM_SHOTGUNNER_DIE1,
		[223] = S_DOOM_SHOTGUNNER_DIE2,
		[224] = S_DOOM_SHOTGUNNER_DIE3,
		[225] = S_DOOM_SHOTGUNNER_DIE4,
		[226] = S_DOOM_SHOTGUNNER_DIE5,
		[227] = S_DOOM_SHOTGUNNER_GIB1,
		[228] = S_DOOM_SHOTGUNNER_GIB2,
		[229] = S_DOOM_SHOTGUNNER_GIB3,
		[230] = S_DOOM_SHOTGUNNER_GIB4,
		[231] = S_DOOM_SHOTGUNNER_GIB5,
		[232] = S_DOOM_SHOTGUNNER_GIB6,
		[233] = S_DOOM_SHOTGUNNER_GIB7,
		[234] = S_DOOM_SHOTGUNNER_GIB8,
		[235] = S_DOOM_SHOTGUNNER_GIB9,
		[236] = S_DOOM_SHOTGUNNER_RAISE1,
		[237] = S_DOOM_SHOTGUNNER_RAISE2,
		[238] = S_DOOM_SHOTGUNNER_RAISE3,
		[239] = S_DOOM_SHOTGUNNER_RAISE4,
		[240] = S_DOOM_SHOTGUNNER_RAISE5,
		--#endregion Shotgunner
		--#region Archvile
		[241] = S_DOOM_ARCHVILE_STAND1,
		[242] = S_DOOM_ARCHVILE_STAND2,
		[243] = S_DOOM_ARCHVILE_CHASE1,
		[244] = S_DOOM_ARCHVILE_CHASE2,
		[245] = S_DOOM_ARCHVILE_CHASE3,
		[246] = S_DOOM_ARCHVILE_CHASE4,
		[247] = S_DOOM_ARCHVILE_CHASE5,
		[248] = S_DOOM_ARCHVILE_CHASE6,
		[249] = S_DOOM_ARCHVILE_CHASE7,
		[250] = S_DOOM_ARCHVILE_CHASE8,
		[251] = S_DOOM_ARCHVILE_CHASE9,
		[252] = S_DOOM_ARCHVILE_CHASE10,
		[253] = S_DOOM_ARCHVILE_CHASE11,
		[254] = S_DOOM_ARCHVILE_CHASE12,
		[255] = S_DOOM_ARCHVILE_ATTACK1,
		[256] = S_DOOM_ARCHVILE_ATTACK2,
		[257] = S_DOOM_ARCHVILE_ATTACK3,
		[258] = S_DOOM_ARCHVILE_ATTACK4,
		[259] = S_DOOM_ARCHVILE_ATTACK5,
		[260] = S_DOOM_ARCHVILE_ATTACK6,
		[261] = S_DOOM_ARCHVILE_ATTACK7,
		[262] = S_DOOM_ARCHVILE_ATTACK8,
		[263] = S_DOOM_ARCHVILE_ATTACK9,
		[264] = S_DOOM_ARCHVILE_ATTACK10,
		[265] = S_DOOM_ARCHVILE_ATTACK11,
		[266] = S_DOOM_ARCHVILE_HEAL1,
		[267] = S_DOOM_ARCHVILE_HEAL2,
		[268] = S_DOOM_ARCHVILE_HEAL3,
		[269] = S_DOOM_ARCHVILE_PAIN1,
		[270] = S_DOOM_ARCHVILE_PAIN2,
		[271] = S_DOOM_ARCHVILE_DIE1,
		[272] = S_DOOM_ARCHVILE_DIE2,
		[273] = S_DOOM_ARCHVILE_DIE3,
		[274] = S_DOOM_ARCHVILE_DIE4,
		[275] = S_DOOM_ARCHVILE_DIE5,
		[276] = S_DOOM_ARCHVILE_DIE6,
		[277] = S_DOOM_ARCHVILE_DIE7,
		[278] = S_DOOM_ARCHVILE_DIE8,
		[279] = S_DOOM_ARCHVILE_DIE9,
		[280] = S_DOOM_ARCHVILE_DIE10,
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
		--#endregion Archvile
		-- Revenant tracer states
		--#region Revenant
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
		--#endregion Revenant
		[357] = S_DOOM_MANCUBUSFIREBALL_SHOT1,
		[358] = S_DOOM_MANCUBUSFIREBALL_SHOT2,
		[359] = S_DOOM_MANCUBUSFIREBALL_EXPLODE1,
		[360] = S_DOOM_MANCUBUSFIREBALL_EXPLODE2,
		[361] = S_DOOM_MANCUBUSFIREBALL_EXPLODE3,
		[362] = S_DOOM_MANCUBUS_STAND1,
		[363] = S_DOOM_MANCUBUS_STAND2,
		[364] = S_DOOM_MANCUBUS_CHASE1,
		[365] = S_DOOM_MANCUBUS_CHASE2,
		[366] = S_DOOM_MANCUBUS_CHASE3,
		[367] = S_DOOM_MANCUBUS_CHASE4,
		[368] = S_DOOM_MANCUBUS_CHASE5,
		[369] = S_DOOM_MANCUBUS_CHASE6,
		[370] = S_DOOM_MANCUBUS_CHASE7,
		[371] = S_DOOM_MANCUBUS_CHASE8,
		[372] = S_DOOM_MANCUBUS_CHASE9,
		[373] = S_DOOM_MANCUBUS_CHASE10,
		[374] = S_DOOM_MANCUBUS_CHASE11,
		[375] = S_DOOM_MANCUBUS_CHASE12,
		[376] = S_DOOM_MANCUBUS_MISSILE1,
		[377] = S_DOOM_MANCUBUS_MISSILE2,
		[378] = S_DOOM_MANCUBUS_MISSILE3,
		[379] = S_DOOM_MANCUBUS_MISSILE4,
		[380] = S_DOOM_MANCUBUS_MISSILE5,
		[381] = S_DOOM_MANCUBUS_MISSILE6,
		[382] = S_DOOM_MANCUBUS_MISSILE7,
		[383] = S_DOOM_MANCUBUS_MISSILE8,
		[384] = S_DOOM_MANCUBUS_MISSILE9,
		[385] = S_DOOM_MANCUBUS_MISSILE10,
		[386] = S_DOOM_MANCUBUS_PAIN1,
		[387] = S_DOOM_MANCUBUS_PAIN2,
		[388] = S_DOOM_MANCUBUS_DIE1,
		[389] = S_DOOM_MANCUBUS_DIE2,
		[390] = S_DOOM_MANCUBUS_DIE3,
		[391] = S_DOOM_MANCUBUS_DIE4,
		[392] = S_DOOM_MANCUBUS_DIE5,
		[393] = S_DOOM_MANCUBUS_DIE6,
		[394] = S_DOOM_MANCUBUS_DIE7,
		[395] = S_DOOM_MANCUBUS_DIE8,
		[396] = S_DOOM_MANCUBUS_DIE9,
		[397] = S_DOOM_MANCUBUS_DIE10,
		[398] = S_DOOM_MANCUBUS_RAISE1,
		[399] = S_DOOM_MANCUBUS_RAISE2,
		[400] = S_DOOM_MANCUBUS_RAISE3,
		[401] = S_DOOM_MANCUBUS_RAISE4,
		[402] = S_DOOM_MANCUBUS_RAISE5,
		[403] = S_DOOM_MANCUBUS_RAISE6,
		[404] = S_DOOM_MANCUBUS_RAISE7,
		[405] = S_DOOM_MANCUBUS_RAISE8,
		[406] = S_DOOM_CHAINGUNNER_STAND1,
		[407] = S_DOOM_CHAINGUNNER_STAND2,
		[408] = S_DOOM_CHAINGUNNER_CHASE1,
		[409] = S_DOOM_CHAINGUNNER_CHASE2,
		[410] = S_DOOM_CHAINGUNNER_CHASE3,
		[411] = S_DOOM_CHAINGUNNER_CHASE4,
		[412] = S_DOOM_CHAINGUNNER_CHASE5,
		[413] = S_DOOM_CHAINGUNNER_CHASE6,
		[414] = S_DOOM_CHAINGUNNER_CHASE7,
		[415] = S_DOOM_CHAINGUNNER_CHASE8,
		[416] = S_DOOM_CHAINGUNNER_MISSILE1,
		[417] = S_DOOM_CHAINGUNNER_MISSILE2,
		[418] = S_DOOM_CHAINGUNNER_MISSILE3,
		[419] = S_DOOM_CHAINGUNNER_MISSILE4,
		[420] = S_DOOM_CHAINGUNNER_PAIN1,
		[421] = S_DOOM_CHAINGUNNER_PAIN2,
		[422] = S_DOOM_CHAINGUNNER_DIE1,
		[423] = S_DOOM_CHAINGUNNER_DIE2,
		[424] = S_DOOM_CHAINGUNNER_DIE3,
		[425] = S_DOOM_CHAINGUNNER_DIE4,
		[426] = S_DOOM_CHAINGUNNER_DIE5,
		[427] = S_DOOM_CHAINGUNNER_DIE6,
		[428] = S_DOOM_CHAINGUNNER_DIE7,
		[429] = S_DOOM_CHAINGUNNER_GIB1,
		[430] = S_DOOM_CHAINGUNNER_GIB2,
		[431] = S_DOOM_CHAINGUNNER_GIB3,
		[432] = S_DOOM_CHAINGUNNER_GIB4,
		[433] = S_DOOM_CHAINGUNNER_GIB5,
		[434] = S_DOOM_CHAINGUNNER_GIB6,
		[435] = S_DOOM_CHAINGUNNER_RAISE1,
		[436] = S_DOOM_CHAINGUNNER_RAISE2,
		[437] = S_DOOM_CHAINGUNNER_RAISE3,
		[438] = S_DOOM_CHAINGUNNER_RAISE4,
		[439] = S_DOOM_CHAINGUNNER_RAISE5,
		[440] = S_DOOM_CHAINGUNNER_RAISE6,
		[441] = S_DOOM_CHAINGUNNER_RAISE7,
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
		[457] = S_DOOM_IMP_DIE1,
		[458] = S_DOOM_IMP_DIE2,
		[459] = S_DOOM_IMP_DIE3,
		[460] = S_DOOM_IMP_DIE4,
		[461] = S_DOOM_IMP_DIE5,
		[462] = S_DOOM_IMP_GIB1,
		[463] = S_DOOM_IMP_GIB2,
		[464] = S_DOOM_IMP_GIB3,
		[465] = S_DOOM_IMP_GIB4,
		[466] = S_DOOM_IMP_GIB5,
		[467] = S_DOOM_IMP_GIB6,
		[468] = S_DOOM_IMP_GIB7,
		[469] = S_DOOM_IMP_GIB8,
		[470] = S_DOOM_IMP_RAISE1,
		[471] = S_DOOM_IMP_RAISE2,
		[472] = S_DOOM_IMP_RAISE3,
		[473] = S_DOOM_IMP_RAISE4,
		[474] = S_DOOM_IMP_RAISE5,
		[475] = S_DOOM_DEMON_STAND1,
		[476] = S_DOOM_DEMON_STAND2,
		[477] = S_DOOM_DEMON_CHASE1,
		[478] = S_DOOM_DEMON_CHASE2,
		[479] = S_DOOM_DEMON_CHASE3,
		[480] = S_DOOM_DEMON_CHASE4,
		[481] = S_DOOM_DEMON_CHASE5,
		[482] = S_DOOM_DEMON_CHASE6,
		[483] = S_DOOM_DEMON_CHASE7,
		[484] = S_DOOM_DEMON_CHASE8,
		[485] = S_DOOM_DEMON_MELEE1,
		[486] = S_DOOM_DEMON_MELEE2,
		[487] = S_DOOM_DEMON_MELEE3,
		[488] = S_DOOM_DEMON_PAIN1,
		[489] = S_DOOM_DEMON_PAIN2,
		[490] = S_DOOM_DEMON_DIE1,
		[491] = S_DOOM_DEMON_DIE2,
		[492] = S_DOOM_DEMON_DIE3,
		[493] = S_DOOM_DEMON_DIE4,
		[494] = S_DOOM_DEMON_DIE5,
		[495] = S_DOOM_DEMON_DIE6,
		[496] = S_DOOM_DEMON_RAISE1,
		[497] = S_DOOM_DEMON_RAISE2,
		[498] = S_DOOM_DEMON_RAISE3,
		[499] = S_DOOM_DEMON_RAISE4,
		[500] = S_DOOM_DEMON_RAISE5,
		[501] = S_DOOM_DEMON_RAISE6,
		[502] = S_DOOM_CACODEMON_STAND1,
		[503] = S_DOOM_CACODEMON_CHASE1,
		[504] = S_DOOM_CACODEMON_MISSILE1,
		[505] = S_DOOM_CACODEMON_MISSILE2,
		[506] = S_DOOM_CACODEMON_MISSILE3,
		[507] = S_DOOM_CACODEMON_PAIN1,
		[508] = S_DOOM_CACODEMON_PAIN2,
		[509] = S_DOOM_CACODEMON_PAIN3,
		[510] = S_DOOM_CACODEMON_DIE1,
		[511] = S_DOOM_CACODEMON_DIE2,
		[512] = S_DOOM_CACODEMON_DIE3,
		[513] = S_DOOM_CACODEMON_DIE4,
		[514] = S_DOOM_CACODEMON_DIE5,
		[515] = S_DOOM_CACODEMON_DIE6,
		[516] = S_DOOM_CACODEMON_RAISE1,
		[517] = S_DOOM_CACODEMON_RAISE2,
		[518] = S_DOOM_CACODEMON_RAISE3,
		[519] = S_DOOM_CACODEMON_RAISE4,
		[520] = S_DOOM_CACODEMON_RAISE5,
		[521] = S_DOOM_CACODEMON_RAISE6,
		[556] = S_DOOM_HELLKNIGHT_STAND1,
		[557] = S_DOOM_HELLKNIGHT_STAND2,
		[558] = S_DOOM_HELLKNIGHT_CHASE1,
		[559] = S_DOOM_HELLKNIGHT_CHASE2,
		[560] = S_DOOM_HELLKNIGHT_CHASE3,
		[561] = S_DOOM_HELLKNIGHT_CHASE4,
		[562] = S_DOOM_HELLKNIGHT_CHASE5,
		[563] = S_DOOM_HELLKNIGHT_CHASE6,
		[564] = S_DOOM_HELLKNIGHT_CHASE7,
		[565] = S_DOOM_HELLKNIGHT_CHASE8,
		[566] = S_DOOM_HELLKNIGHT_ATTACK1,
		[567] = S_DOOM_HELLKNIGHT_ATTACK2,
		[568] = S_DOOM_HELLKNIGHT_ATTACK3,
		[569] = S_DOOM_HELLKNIGHT_PAIN1,
		[570] = S_DOOM_HELLKNIGHT_PAIN2,
		[571] = S_DOOM_HELLKNIGHT_DIE1,
		[572] = S_DOOM_HELLKNIGHT_DIE2,
		[573] = S_DOOM_HELLKNIGHT_DIE3,
		[574] = S_DOOM_HELLKNIGHT_DIE4,
		[575] = S_DOOM_HELLKNIGHT_DIE5,
		[576] = S_DOOM_HELLKNIGHT_DIE6,
		[577] = S_DOOM_HELLKNIGHT_DIE7,
		[578] = S_DOOM_HELLKNIGHT_RAISE1,
		[579] = S_DOOM_HELLKNIGHT_RAISE2,
		[580] = S_DOOM_HELLKNIGHT_RAISE3,
		[581] = S_DOOM_HELLKNIGHT_RAISE4,
		[582] = S_DOOM_HELLKNIGHT_RAISE5,
		[583] = S_DOOM_HELLKNIGHT_RAISE6,
		[584] = S_DOOM_HELLKNIGHT_RAISE7,
		[585] = S_DOOM_LOSTSOUL_STAND1,
		[586] = S_DOOM_LOSTSOUL_STAND2,
		[587] = S_DOOM_LOSTSOUL_CHASE1,
		[588] = S_DOOM_LOSTSOUL_CHASE2,
		[589] = S_DOOM_LOSTSOUL_MISSILE1,
		[590] = S_DOOM_LOSTSOUL_MISSILE2,
		[591] = S_DOOM_LOSTSOUL_MISSILE3,
		[592] = S_DOOM_LOSTSOUL_MISSILE4,
		[593] = S_DOOM_LOSTSOUL_PAIN1,
		[594] = S_DOOM_LOSTSOUL_PAIN2,
		[595] = S_DOOM_LOSTSOUL_DIE1,
		[596] = S_DOOM_LOSTSOUL_DIE2,
		[597] = S_DOOM_LOSTSOUL_DIE3,
		[598] = S_DOOM_LOSTSOUL_DIE4,
		[599] = S_DOOM_LOSTSOUL_DIE5,
		[600] = S_DOOM_LOSTSOUL_DIE6,
		[601] = S_DOOM_SPIDERMASTERMIND_STAND1,
		[602] = S_DOOM_SPIDERMASTERMIND_STAND2,
		[603] = S_DOOM_SPIDERMASTERMIND_CHASE1,
		[604] = S_DOOM_SPIDERMASTERMIND_CHASE2,
		[605] = S_DOOM_SPIDERMASTERMIND_CHASE3,
		[606] = S_DOOM_SPIDERMASTERMIND_CHASE4,
		[607] = S_DOOM_SPIDERMASTERMIND_CHASE5,
		[608] = S_DOOM_SPIDERMASTERMIND_CHASE6,
		[609] = S_DOOM_SPIDERMASTERMIND_CHASE7,
		[610] = S_DOOM_SPIDERMASTERMIND_CHASE8,
		[611] = S_DOOM_SPIDERMASTERMIND_CHASE9,
		[612] = S_DOOM_SPIDERMASTERMIND_CHASE10,
		[613] = S_DOOM_SPIDERMASTERMIND_CHASE11,
		[614] = S_DOOM_SPIDERMASTERMIND_CHASE12,
		[615] = S_DOOM_SPIDERMASTERMIND_MISSILE1,
		[616] = S_DOOM_SPIDERMASTERMIND_MISSILE2,
		[617] = S_DOOM_SPIDERMASTERMIND_MISSILE3,
		[618] = S_DOOM_SPIDERMASTERMIND_MISSILE4,
		[619] = S_DOOM_SPIDERMASTERMIND_PAIN1,
		[620] = S_DOOM_SPIDERMASTERMIND_PAIN2,
		[621] = S_DOOM_SPIDERMASTERMIND_DIE1,
		[622] = S_DOOM_SPIDERMASTERMIND_DIE2,
		[623] = S_DOOM_SPIDERMASTERMIND_DIE3,
		[624] = S_DOOM_SPIDERMASTERMIND_DIE4,
		[625] = S_DOOM_SPIDERMASTERMIND_DIE5,
		[626] = S_DOOM_SPIDERMASTERMIND_DIE6,
		[627] = S_DOOM_SPIDERMASTERMIND_DIE7,
		[628] = S_DOOM_SPIDERMASTERMIND_DIE8,
		[629] = S_DOOM_SPIDERMASTERMIND_DIE9,
		[630] = S_DOOM_SPIDERMASTERMIND_DIE10,
		[631] = S_DOOM_SPIDERMASTERMIND_DIE11,
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
		[701] = S_DOOM_PAINELEMENTAL_STAND1,
		[702] = S_DOOM_PAINELEMENTAL_CHASE1,
		[703] = S_DOOM_PAINELEMENTAL_CHASE2,
		[704] = S_DOOM_PAINELEMENTAL_CHASE3,
		[705] = S_DOOM_PAINELEMENTAL_CHASE4,
		[706] = S_DOOM_PAINELEMENTAL_CHASE5,
		[707] = S_DOOM_PAINELEMENTAL_CHASE6,
		[708] = S_DOOM_PAINELEMENTAL_MISSILE1,
		[709] = S_DOOM_PAINELEMENTAL_MISSILE2,
		[710] = S_DOOM_PAINELEMENTAL_MISSILE3,
		[711] = S_DOOM_PAINELEMENTAL_MISSILE4,
		[712] = S_DOOM_PAINELEMENTAL_PAIN1,
		[713] = S_DOOM_PAINELEMENTAL_PAIN2,
		[714] = S_DOOM_PAINELEMENTAL_DIE1,
		[715] = S_DOOM_PAINELEMENTAL_DIE2,
		[716] = S_DOOM_PAINELEMENTAL_DIE3,
		[717] = S_DOOM_PAINELEMENTAL_DIE4,
		[718] = S_DOOM_PAINELEMENTAL_DIE5,
		[719] = S_DOOM_PAINELEMENTAL_DIE6,
		[720] = S_DOOM_PAINELEMENTAL_RAISE1,
		[721] = S_DOOM_PAINELEMENTAL_RAISE2,
		[722] = S_DOOM_PAINELEMENTAL_RAISE3,
		[723] = S_DOOM_PAINELEMENTAL_RAISE4,
		[724] = S_DOOM_PAINELEMENTAL_RAISE5,
		[725] = S_DOOM_PAINELEMENTAL_RAISE6,
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
		[778] = S_DOOM_ROMEROHEAD_STAND1,
		[779] = S_DOOM_ROMEROHEAD_PAIN1,
		[780] = S_DOOM_ROMEROHEAD_DIE1,
		[781] = S_DOOM_ROMEROHEAD_DIE2,
		[782] = S_DOOM_ROMEROHEAD_DIE3,
		[783] = S_DOOM_ROMEROHEAD_DIE4,
		[784] = S_DOOM_MONSTERSPAWNER_STAND1,
		[785] = S_DOOM_MONSTERSPAWNER_CHASE1,
		[786] = S_DOOM_MONSTERSPAWNER_CHASE2,
		[791] = S_DOOM_SPAWNFIRE_1,
		[792] = S_DOOM_SPAWNFIRE_2,
		[793] = S_DOOM_SPAWNFIRE_3,
		[794] = S_DOOM_SPAWNFIRE_4,
		[795] = S_DOOM_SPAWNFIRE_5,
		[796] = S_DOOM_SPAWNFIRE_6,
		[797] = S_DOOM_SPAWNFIRE_7,
		[798] = S_DOOM_SPAWNFIRE_8,
		[802] = S_DOOM_SECURITYARMOR_1,
		[803] = S_DOOM_SECURITYARMOR_2,
		[804] = S_DOOM_COMBATARMOR_1,
		[805] = S_DOOM_COMBATARMOR_2,
		[813] = S_DOOM_FLAMINGBARREL_1,
		[814] = S_DOOM_FLAMINGBARREL_2,
		[815] = S_DOOM_FLAMINGBARREL_3,
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
		[828] = S_DOOM_BLUEKEYCARD_1,
		[829] = S_DOOM_BLUEKEYCARD_2,
		[830] = S_DOOM_REDKEYCARD_1,
		[831] = S_DOOM_REDKEYCARD_2,
		[832] = S_DOOM_YELLOWKEYCARD_1,
		[833] = S_DOOM_YELLOWKEYCARD_2,
		[834] = S_DOOM_BLUESKULL_1,
		[835] = S_DOOM_BLUESKULL_2,
		[836] = S_DOOM_REDSKULL_1,
		[837] = S_DOOM_REDSKULL_2,
		[838] = S_DOOM_YELLOWSKULL_1,
		[839] = S_DOOM_YELLOWSKULL_2,
		[840] = S_DOOM_STIMPACK_1,
		[841] = S_DOOM_MEDIKIT_1,
		[842] = S_DOOM_SOULSPHERE_1,
		[843] = S_DOOM_SOULSPHERE_2,
		[844] = S_DOOM_SOULSPHERE_3,
		[845] = S_DOOM_SOULSPHERE_4,
		[846] = S_DOOM_SOULSPHERE_5,
		[847] = S_DOOM_SOULSPHERE_6,
		[848] = S_DOOM_INVULNSPHERE_1,
		[849] = S_DOOM_INVULNSPHERE_2,
		[850] = S_DOOM_INVULNSPHERE_3,
		[851] = S_DOOM_INVULNSPHERE_4,
		[852] = S_DOOM_BERSERK_1,
		[853] = S_DOOM_BLURSPHERE_1,
		[854] = S_DOOM_BLURSPHERE_2,
		[855] = S_DOOM_BLURSPHERE_3,
		[856] = S_DOOM_BLURSPHERE_4,
		[857] = S_DOOM_MEGASPHERE_1,
		[858] = S_DOOM_MEGASPHERE_2,
		[859] = S_DOOM_MEGASPHERE_3,
		[860] = S_DOOM_MEGASPHERE_4,

		-- gap
		[870] = S_DOOM_CLIP_1,
		[871] = S_DOOM_CLIPBOX_1,
		[872] = S_DOOM_ROCKET_1,
		[873] = S_DOOM_ROCKETBOX_1,
		[874] = S_DOOM_CELL_1,
		[875] = S_DOOM_CELLPACK_1,
		[876] = S_DOOM_SHELLS_1,
		[877] = S_DOOM_SHELLBOX_1,

		[886] = S_DOOM_FLOORLAMP_1,
		[887] = S_DOOM_UNUSED_STALAG,
		[888] = S_DOOM_BLOODYTWITCH_1,
		[889] = S_DOOM_BLOODYTWITCH_2,
		[890] = S_DOOM_BLOODYTWITCH_3,
		[891] = S_DOOM_BLOODYTWITCH_4,
		[892] = S_DOOM_UNUSED_DEADTORSO,
		[893] = S_DOOM_UNUSED_DEADBOTTOM,
		[894] = S_DOOM_HEADSONASTICK_1,
		[895] = S_DOOM_CRUSHGIBS_1,
		[911] = S_DOOM_CANDLESTICK_1,
		[917] = S_DOOM_EVILEYE_1,
		[918] = S_DOOM_EVILEYE_2,
		[919] = S_DOOM_EVILEYE_3,
		[920] = S_DOOM_EVILEYE_4,
		[921] = S_DOOM_FLOATINGSKULL_1,
		[922] = S_DOOM_FLOATINGSKULL_2,
		[923] = S_DOOM_FLOATINGSKULL_1,
		[924] = S_DOOM_HEARTCOLUMN_1,
		[925] = S_DOOM_HEARTCOLUMN_2,
		[926] = S_DOOM_BLUETORCH_1,
		[927] = S_DOOM_BLUETORCH_2,
		[928] = S_DOOM_BLUETORCH_3,
		[929] = S_DOOM_BLUETORCH_4,
		[930] = S_DOOM_GREENTORCH_1,
		[931] = S_DOOM_GREENTORCH_2,
		[932] = S_DOOM_GREENTORCH_3,
		[933] = S_DOOM_GREENTORCH_4,
		[934] = S_DOOM_REDTORCH_1,
		[935] = S_DOOM_REDTORCH_2,
		[936] = S_DOOM_REDTORCH_3,
		[937] = S_DOOM_REDTORCH_4,
		[938] = S_DOOM_SHORTBLUETORCH_1,
		[939] = S_DOOM_SHORTBLUETORCH_2,
		[940] = S_DOOM_SHORTBLUETORCH_3,
		[941] = S_DOOM_SHORTBLUETORCH_4,
		[942] = S_DOOM_SHORTGREENTORCH_1,
		[943] = S_DOOM_SHORTGREENTORCH_2,
		[944] = S_DOOM_SHORTGREENTORCH_3,
		[945] = S_DOOM_SHORTGREENTORCH_4,
		[946] = S_DOOM_SHORTREDTORCH_1,
		[947] = S_DOOM_SHORTREDTORCH_2,
		[948] = S_DOOM_SHORTREDTORCH_3,
		[949] = S_DOOM_SHORTREDTORCH_4,
		[959] = S_DOOM_TALLTECHNOFLOORLAMP_1,
		[960] = S_DOOM_TALLTECHNOFLOORLAMP_2,
		[961] = S_DOOM_TALLTECHNOFLOORLAMP_3,
		[962] = S_DOOM_TALLTECHNOFLOORLAMP_4,
		[963] = S_DOOM_SHORTTECHNOFLOORLAMP_1,
		[964] = S_DOOM_SHORTTECHNOFLOORLAMP_2,
		[965] = S_DOOM_SHORTTECHNOFLOORLAMP_3,
		[966] = S_DOOM_SHORTTECHNOFLOORLAMP_4,
	},

	-- String to codepointer mapping
	bex_codeptr = {
		Chase = A_DoomChase,
		Scream = A_DoomScream,
		Fall = A_DoomFall,
		Punch = A_DoomPunch,
		FirePistol = A_DoomFirePistol,
		ReFire = A_DoomReFire,
		WeaponReady = A_DoomWeaponReady,
		Look = A_DoomLook,
		Pain = A_DoomPain,
		BossDeath = A_DoomBossDeath,
		Lower = A_DoomLower,
		Raise = A_DoomRaise,
		GunFlash = A_DoomGunFlash,
		Hoof = A_Hoof,
		XScream = A_DoomXScream,
	}
}

function A_Dummy() end