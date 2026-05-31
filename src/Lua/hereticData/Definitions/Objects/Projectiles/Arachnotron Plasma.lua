SafeFreeSlot(
    "SPR_APLS","SPR_APBX",
    "S_DOOM_ARACHPLASMA1","S_DOOM_ARACHPLASMA2",
    "S_DOOM_ARACHPLASMAX1","S_DOOM_ARACHPLASMAX2",
    "S_DOOM_ARACHPLASMAX3","S_DOOM_ARACHPLASMAX4","S_DOOM_ARACHPLASMAX5",
    "MT_DOOM_ARCHNOTRONPLASMA"
)

states[S_DOOM_ARACHPLASMA1] = { sprite=SPR_APLS, frame=A|FF_FULLBRIGHT, tics=6, nextstate=S_DOOM_ARACHPLASMA2 }
states[S_DOOM_ARACHPLASMA2] = { sprite=SPR_APLS, frame=B|FF_FULLBRIGHT, tics=6, nextstate=S_DOOM_ARACHPLASMA1 }

states[S_DOOM_ARACHPLASMAX1] = { sprite=SPR_APBX, frame=A|FF_FULLBRIGHT, tics=4, nextstate=S_DOOM_ARACHPLASMAX2 }
states[S_DOOM_ARACHPLASMAX2] = { sprite=SPR_APBX, frame=B|FF_FULLBRIGHT, tics=4, nextstate=S_DOOM_ARACHPLASMAX3 }
states[S_DOOM_ARACHPLASMAX3] = { sprite=SPR_APBX, frame=C|FF_FULLBRIGHT, tics=4, nextstate=S_DOOM_ARACHPLASMAX4 }
states[S_DOOM_ARACHPLASMAX4] = { sprite=SPR_APBX, frame=D|FF_FULLBRIGHT, tics=4, nextstate=S_DOOM_ARACHPLASMAX5 }
states[S_DOOM_ARACHPLASMAX5] = { sprite=SPR_APBX, frame=E|FF_FULLBRIGHT, tics=4, nextstate=S_NULL }

mobjinfo[MT_DOOM_ARCHNOTRONPLASMA] = {
    spawnstate = S_DOOM_ARACHPLASMA1,
    seesound   = sfx_plasma,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_ARACHPLASMAX1,

    speed      = 25*FRACUNIT,
    radius     = 13*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 5,

    flags = MF_NOGRAVITY|MF_MISSILE,
}