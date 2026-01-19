SafeFreeSlot(
    "SPR_PLSS","SPR_PLSE",
    "sfx_plasma","sfx_firxpl",
    "MT_DOOM_PLASMASHOT"
)

local plasmastates = {
    shot = {
        {sprite = SPR_PLSS, frame = A|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_PLSS, frame = B|FF_FULLBRIGHT, tics = 6, next = "shot"},
    },

    explode = {
        {sprite = SPR_PLSE, frame = A|FF_FULLBRIGHT, tics = 4},
        {sprite = SPR_PLSE, frame = B|FF_FULLBRIGHT, tics = 4},
        {sprite = SPR_PLSE, frame = C|FF_FULLBRIGHT, tics = 4},
        {sprite = SPR_PLSE, frame = D|FF_FULLBRIGHT, tics = 4},
        {sprite = SPR_PLSE, frame = E|FF_FULLBRIGHT, tics = 4},
    },
}

FreeDoomStates("Plasma", plasmastates)

mobjinfo[MT_DOOM_PLASMASHOT] = {
    spawnstate = S_DOOM_PLASMA_SHOT1,
    seesound   = sfx_plasma,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_PLASMA_EXPLODE1,

    speed      = 25*FRACUNIT,
    radius     = 13*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 5,
    dispoffset = 5,

    flags = MF_NOGRAVITY|MF_MISSILE,
}