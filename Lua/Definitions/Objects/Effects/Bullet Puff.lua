SafeFreeSlot(
    "SPR_PUFF", "SPR_BLUD",
    "MT_DOOM_BULLETPUFF"
)

---@type StateDefs
local telestates = {
    puff = {
        {sprite = SPR_PUFF, frame = A, tics = 4},
        {sprite = SPR_PUFF, frame = B, tics = 4},
        {sprite = SPR_PUFF, frame = C, tics = 4},
        {sprite = SPR_PUFF, frame = D, tics = 4},
    },
    blood = {
        {sprite = SPR_BLUD, frame = C, tics = 4},
        {sprite = SPR_BLUD, frame = B, tics = 4},
        {sprite = SPR_BLUD, frame = A, tics = 4},
    }
}

FreeDoomStates("BPuff", telestates)

-- This state constant feels #WRONG! but oh well
-- Saying "puff puff" sounds weird*er*
mobjinfo[MT_DOOM_BULLETPUFF] = {
    spawnstate = S_DOOM_BPUFF_PUFF1,
    radius = 1*FRACUNIT,
    height = 1*FRACUNIT,
    flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}