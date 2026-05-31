SafeFreeSlot(
    "SPR_BAL1",
    "S_DOOM_IMPFIRE1", "S_DOOM_IMPFIRE2",
    "S_DOOM_IMPFIREEXPLODE1", "S_DOOM_IMPFIREEXPLODE2", "S_DOOM_IMPFIREEXPLODE3",
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
    spawnstate = S_DOOM_IMPFIRE1,
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_IMPFIREEXPLODE1,
    speed      = 10*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 3,
    flags      = MF_MISSILE|MF_NOGRAVITY,
}

states[S_DOOM_IMPFIRE1] = { sprite=SPR_BAL1, frame=A|FF_FULLBRIGHT, tics=4, nextstate=S_DOOM_IMPFIRE2 }
states[S_DOOM_IMPFIRE2] = { sprite=SPR_BAL1, frame=B|FF_FULLBRIGHT, tics=4, nextstate=S_DOOM_IMPFIRE1 }

states[S_DOOM_IMPFIREEXPLODE1] = { sprite=SPR_BAL1, frame=C|FF_FULLBRIGHT, tics=6, nextstate=S_DOOM_IMPFIREEXPLODE2 }
states[S_DOOM_IMPFIREEXPLODE2] = { sprite=SPR_BAL1, frame=D|FF_FULLBRIGHT, tics=6, nextstate=S_DOOM_IMPFIREEXPLODE3 }
states[S_DOOM_IMPFIREEXPLODE3] = { sprite=SPR_BAL1, frame=E|FF_FULLBRIGHT, tics=6, nextstate=S_NULL }