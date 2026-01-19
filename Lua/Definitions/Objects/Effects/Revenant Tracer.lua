SafeFreeSlot("SPR_PUFF")

local playerstates = {
	spawn = {
		{sprite = SPR_PUFF, frame = A, tics = 4},
		{sprite = SPR_PUFF, frame = B, tics = 4},
		{sprite = SPR_PUFF, frame = A, tics = 4},
		{sprite = SPR_PUFF, frame = B, tics = 4},
		{sprite = SPR_PUFF, frame = C, tics = 4},
	},
}

local freedSprites = FreeDoomStates("RevenantTracer", playerstates)

SafeFreeSlot("MT_DOOM_REVENANT_TRACER")

mobjinfo[MT_DOOM_REVENANT_TRACER] = {
    spawnstate = S_DOOM_PUFF1,
    radius = 1*FRACUNIT,
    height = 1*FRACUNIT,
    flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPTHING,
}