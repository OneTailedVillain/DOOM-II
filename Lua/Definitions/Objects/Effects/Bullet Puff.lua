SafeFreeSlot(
    "SPR_PUFF",
    "S_DOOM_PUFF1","S_DOOM_PUFF2","S_DOOM_PUFF3","S_DOOM_PUFF4",
    "S_DOOM_BLOOD1","S_DOOM_BLOOD2","S_DOOM_BLOOD3",
    "MT_DOOM_BULLETPUFF"
)

mobjinfo[MT_DOOM_BULLETPUFF] = {
    spawnstate = S_DOOM_PUFF1,
    radius = 1*FRACUNIT,
    height = 1*FRACUNIT,
    flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}

-- puff anim
states[S_DOOM_PUFF1] = { sprite=SPR_PUFF, frame=A, tics=4, nextstate=S_DOOM_PUFF2 }
states[S_DOOM_PUFF2] = { sprite=SPR_PUFF, frame=B, tics=4, nextstate=S_DOOM_PUFF3 }
states[S_DOOM_PUFF3] = { sprite=SPR_PUFF, frame=C, tics=4, nextstate=S_DOOM_PUFF4 }
states[S_DOOM_PUFF4] = { sprite=SPR_PUFF, frame=D, tics=4, nextstate=S_NULL }

-- blood anim
states[S_DOOM_BLOOD1] = { sprite=SPR_BLUD, frame=C, tics=4, nextstate=S_DOOM_BLOOD2 }
states[S_DOOM_BLOOD2] = { sprite=SPR_BLUD, frame=B, tics=4, nextstate=S_DOOM_BLOOD3 }
states[S_DOOM_BLOOD3] = { sprite=SPR_BLUD, frame=A, tics=4, nextstate=S_NULL }