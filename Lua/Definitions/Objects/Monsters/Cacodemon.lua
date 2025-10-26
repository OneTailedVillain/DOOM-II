local function SafeFreeSlot(...)
    local ret = {}
    for _, name in ipairs({...}) do
        -- If already freed, just use the existing slot
        if rawget(_G, name) ~= nil then
            ret[name] = _G[name]
        else
            -- Otherwise, safely freeslot it and return the value
            ret[name] = freeslot(name)
        end
    end
    return ret
end

SafeFreeSlot("SPR_HEAD", "sfx_cacsit", "sfx_cacdth")
local name = "Cacodemon"

local object = {
	health = 400,
	radius = 31,
	height = 56,
	mass = 400,
	speed = 8,
	painchance = 128,
	doomednum = 3005,
	seesound = sfx_cacsit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_cacdth,
	sprite = SPR_HEAD,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 3, next = "chase"},
	},
	attack = {
		{action = A_DoomFaceTarget, frame = B, tics = 8},
		{action = A_DoomFaceTarget, frame = C, tics = 8},
		{action = A_DoomHeadAttack, frame = D|FF_FULLBRIGHT, tics = 6, next = "chase"},
	},
	pain = {
		{action = nil, frame = E, tics = 3},
		{action = A_DoomPain, frame = E, tics = 3},
		{action = nil, frame = F, tics = 3, next = "chase"},
	},
	die = {
		{action = nil, frame = G, tics = 8},
		{action = A_DoomScream, frame = H, tics = 8},
		{action = nil, frame = I, tics = 8},
		{action = nil, frame = J, tics = 8},
		{action = A_DoomFall, frame = K, tics = 8},
		{action = nil, frame = L, tics = -1},
	},
}

DefineDoomActor(name, object, states)