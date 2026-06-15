SafeFreeSlot(
    "SPR_TELP",
    "MT_DOOM_TELEFOG",
    "sfx_telept"
)

---@type StateDefs
local telestates = {
    spawn = {
        {sprite = SPR_TELP, frame = A|FF_ADD, tics = 6, action = A_PlaySound, var1 = sfx_telept, var2 = 1},
        {sprite = SPR_TELP, frame = B|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = A|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = B|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = C|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = D|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = E|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = F|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = G|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = H|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = I|FF_ADD, tics = 6},
        {sprite = SPR_TELP, frame = J|FF_ADD, tics = 6},
    },
}

FreeDoomStates("Telefog", telestates)

mobjinfo[MT_DOOM_TELEFOG] = {
spawnstate = S_DOOM_TELEFOG_SPAWN1,
spawnhealth = 1000,
doomednum = 23,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP|MF_RUNSPAWNFUNC,
}

---@param mobj mobj_t
addHook("MobjSpawn", function(mobj)
	mobj.alpha = FRACUNIT/4
end, MT_DOOM_TELEFOG)