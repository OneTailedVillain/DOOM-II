SafeFreeSlot(
    "SPR_BAL7",
    "sfx_firsht","sfx_firxpl",
    "MT_DOOM_BARONFIREBALL"
)

local plasmastates = {
    shot = {
        {sprite = SPR_BAL7, frame = A, tics = 4},
        {sprite = SPR_BAL7, frame = B, tics = 4, next = "shot"},
    },

    explode = {
        {sprite = SPR_BAL7, frame = C, tics = 6},
        {sprite = SPR_BAL7, frame = D, tics = 6},
        {sprite = SPR_BAL7, frame = E, tics = 6},
    },
}

FreeDoomStates("BaronFireball", plasmastates)

mobjinfo[MT_DOOM_BARONFIREBALL] = {
    spawnstate = S_DOOM_BARONFIREBALL_SHOT1,
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_BARONFIREBALL_EXPLODE1,

    speed      = 15*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 16*FRACUNIT,
    damage     = 8,

    flags = MF_NOGRAVITY|MF_MISSILE,
}

mobjinfo[MT_DOOM_BARONFIREBALL].fastspeed = 20*FRACUNIT