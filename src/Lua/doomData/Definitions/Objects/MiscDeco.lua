-- extra stuff that DOESN'T use DefineDoomDeco (copies from existing states)
-- Likely not a good way to do this... Too bad!
local baseInfo = {
	spawnhealth = 0,
	radius      = 20*FRACUNIT,
	height      = 16*FRACUNIT,
	mass        = 100,
	doomednum   = 18,
	speed       = 0,
	flags       = MF_SCENERY,
}

/*
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
*/

local mt = freeslot("MT_DOOM_DEADZOMBIEMAN")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_ZOMBIEMAN_DIE5
mobjinfo[mt].doomname = "DeadZombieman"
mobjinfo[mt].doomednum = 18

local mt = freeslot("MT_DOOM_DEADSHOTGUNNER")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_SHOTGUNNER_DIE5
mobjinfo[mt].doomname = "DeadShotgunner"
mobjinfo[mt].doomednum = 19

local mt = freeslot("MT_DOOM_DEADIMP")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_IMP_DIE5
mobjinfo[mt].doomname = "DeadImp"
mobjinfo[mt].doomednum = 20

local mt = freeslot("MT_DOOM_DEADDEMON")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_DEMON_DIE6
mobjinfo[mt].doomname = "DeadDemon"
mobjinfo[mt].doomednum = 21

local mt = freeslot("MT_DOOM_DEADCACODEMON")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_CACODEMON_DIE6
mobjinfo[mt].doomname = "DeadCacodemon"
mobjinfo[mt].doomednum = 22

local mt = freeslot("MT_DOOM_DEADLOSTSOUL")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_LOSTSOUL_DIE6
mobjinfo[mt].doomname = "DeadLostSoul"
mobjinfo[mt].doomednum = 23

local mt = freeslot("MT_DOOM_CORPSE")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_PLAYER_DIE7
mobjinfo[mt].doomname = "Corpse"
mobjinfo[mt].doomednum = 15

local mt = freeslot("MT_DOOM_BLOODYMESS")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_PLAYER_GIB9
mobjinfo[mt].doomname = "BloodyMess"
mobjinfo[mt].doomednum = 10

local mt = freeslot("MT_DOOM_BLOODYMESSEXTRA")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_PLAYER_GIB9
mobjinfo[mt].doomname = "BloodyMessExtra"
mobjinfo[mt].doomednum = 12