SafeFreeSlot(
    "SPR_TFOG",
    "S_TELEFOG1","S_TELEFOG2","S_TELEFOG3","S_TELEFOG4",
    "S_TELEFOG5","S_TELEFOG6","S_TELEFOG7","S_TELEFOG8",
    "S_TELEFOG9","S_TELEFOG10","S_TELEFOG11","S_TELEFOG12",
    "MT_DOOM_TELEFOG",
    "sfx_telept"
)

mobjinfo[MT_DOOM_TELEFOG] = {
spawnstate = S_TELEFOG1,
spawnhealth = 1000,
deathstate = S_TELEFOG1,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP|MF_RUNSPAWNFUNC,
}

states[S_TELEFOG1] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|A,
    tics = 6,
	action = A_PlaySound,
	var1 = sfx_telept,
	var2 = 1,
    nextstate = S_TELEFOG2
}

states[S_TELEFOG2] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|B,
    tics = 6,
    nextstate = S_TELEFOG3
}

states[S_TELEFOG3] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|A,
    tics = 6,
    nextstate = S_TELEFOG4
}

states[S_TELEFOG4] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|B,
    tics = 6,
    nextstate = S_TELEFOG5
}

states[S_TELEFOG5] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|C,
    tics = 6,
    nextstate = S_TELEFOG6
}

states[S_TELEFOG6] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|D,
    tics = 6,
    nextstate = S_TELEFOG7
}

states[S_TELEFOG7] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|E,
    tics = 6,
    nextstate = S_TELEFOG8
}

states[S_TELEFOG8] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|F,
    tics = 6,
    nextstate = S_TELEFOG9
}

states[S_TELEFOG9] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|G,
    tics = 6,
    nextstate = S_TELEFOG10
}

states[S_TELEFOG10] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|H,
    tics = 6,
    nextstate = S_TELEFOG11
}

states[S_TELEFOG11] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|I,
    tics = 6,
    nextstate = S_TELEFOG12
}

states[S_TELEFOG12] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|J,
    tics = 6,
    nextstate = S_NULL
}