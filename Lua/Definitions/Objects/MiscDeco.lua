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

local mt = freeslot("MT_DOOM_DEADZOMBIEMAN")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_ZOMBIEMAN_DIE5

local mt = freeslot("MT_DOOM_DEADSHOTGUNNER")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_SHOTGUNNER_DIE5

local mt = freeslot("MT_DOOM_DEADIMP")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_IMP_DIE5

local mt = freeslot("MT_DOOM_DEADDEMON")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_DEMON_DIE6

local mt = freeslot("MT_DOOM_DEADCACODEMON")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_CACODEMON_DIE6

local mt = freeslot("MT_DOOM_DEADLOSTSOUL")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_LOSTSOUL_DIE6

local mt = freeslot("MT_DOOM_CORPSE")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_PLAYER_DIE7

local mt = freeslot("MT_DOOM_BLOODYMESS")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_PLAYER_GIB9

local mt = freeslot("MT_DOOM_BLOODYMESSEXTRA")
mobjinfo[mt] = deepcopy(baseInfo)
mobjinfo[mt].spawnstate = S_DOOM_PLAYER_GIB9