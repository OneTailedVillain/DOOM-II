SafeFreeSlot(
    "SPR_BAL2","SPR_MISL",
    "MT_DOOM_CACODEMONSHOT"
)

local plasmastates = {
    shot = {
        {sprite = SPR_BAL2, frame = A|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_BAL2, frame = B|FF_FULLBRIGHT, tics = 6, next = "shot"},
    },

    explode = {
        {sprite = SPR_BAL2, frame = B|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BAL2, frame = C|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_BAL2, frame = D|FF_FULLBRIGHT, tics = 4},
    },
}

local states = FreeDoomStates("CacodemonShot", plasmastates)

mobjinfo[MT_DOOM_CACODEMONSHOT] = {
    spawnstate = states.shot[1],
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,
    deathstate = states.explode[1],

    speed      = 10*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 8,

    flags = MF_NOGRAVITY|MF_MISSILE,
}