SafeFreeSlot(
    "SPR_IFOG",
    "MT_DOOM_ITEMFOG",
    "sfx_telept"
)

---@type StateDefs
local telestates = {
    spawn = {
        {sprite = SPR_IFOG, frame = A|FF_FULLBRIGHT, tics = 6, action = A_PlaySound, var1 = sfx_telept, var2 = 1},
        {sprite = SPR_IFOG, frame = B|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_IFOG, frame = A|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_IFOG, frame = B|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_IFOG, frame = C|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_IFOG, frame = D|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_IFOG, frame = E|FF_FULLBRIGHT, tics = 6},
    },
}

FreeDoomStates("Itemfog", telestates)

mobjinfo[MT_DOOM_ITEMFOG] = {
spawnstate = S_DOOM_ITEMFOG_SPAWN1,
spawnhealth = 1000,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP|MF_RUNSPAWNFUNC,
}