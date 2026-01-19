SafeFreeSlot(
    "SPR_TFOG",
    "MT_DOOM_TELEFOG",
    "sfx_telept"
)

---@type StateDefs
local telestates = {
    spawn = {
        {sprite = SPR_TFOG, frame = A|FF_FULLBRIGHT, tics = 6, action = A_PlaySound, var1 = sfx_telept, var2 = 1},
        {sprite = SPR_TFOG, frame = B|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = A|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = B|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = C|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = D|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = E|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = F|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = G|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = H|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = I|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_TFOG, frame = J|FF_FULLBRIGHT, tics = 6},
    },
}

FreeDoomStates("Telefog", telestates)

mobjinfo[MT_DOOM_TELEFOG] = {
spawnstate = S_DOOM_TELEFOG_SPAWN1,
spawnhealth = 1000,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP|MF_RUNSPAWNFUNC,
}