SafeFreeSlot(
    "SPR_BAL1",
    "sfx_firsht", "sfx_firxpl",
    "MT_TROOPSHOT"
)

local plasmastates = {
    shot = {
        {sprite = SPR_BAL1, frame = A|FF_FULLBRIGHT, tics = 4},
        {sprite = SPR_BAL1, frame = B|FF_FULLBRIGHT, tics = 4, next = "shot"},
    },

    explode = {
        {sprite = SPR_BAL1, frame = C|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_BAL1, frame = D|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_BAL1, frame = E|FF_FULLBRIGHT, tics = 6},
    },
}

FreeDoomStates("ImpFireball", plasmastates)

mobjinfo[MT_TROOPSHOT] = {
    spawnstate = plasmastates.shot[1],
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,
    deathstate = plasmastates.shot[2],
    speed      = 10*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 3,
    flags      = MF_MISSILE|MF_NOGRAVITY,
}

mobjinfo[MT_TROOPSHOT].doomname = "ImpFireball"