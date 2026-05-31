SafeFreeSlot(
    "SPR_MANF","SPR_MISL",
    "sfx_plasma","sfx_firxpl",
    "MT_DOOM_MANCUBUSFIREBALL"
)

local plasmastates = {
    shot = {
        {sprite = SPR_MANF, frame = A|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_MANF, frame = B|FF_FULLBRIGHT, tics = 6, next = "shot"},
    },

    explode = {
        {sprite = SPR_MISL, frame = B|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_MISL, frame = C|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_MISL, frame = D|FF_FULLBRIGHT, tics = 4},
    },
}

FreeDoomStates("MancubusFireball", plasmastates)

mobjinfo[MT_DOOM_MANCUBUSFIREBALL] = {
    spawnstate = S_DOOM_MANCUBUSFIREBALL_SHOT1,
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_MANCUBUSFIREBALL_EXPLODE1,

    speed      = 20*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 8,

    flags = MF_NOGRAVITY|MF_MISSILE,
}