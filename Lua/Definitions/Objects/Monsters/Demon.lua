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

SafeFreeSlot("SPR_SARG",
"sfx_sgtsit", "sfx_dmact", "sfx_dmpain", "sfx_sgtdth", "sfx_sgtatk")
local name = "Demon"

local object = {
	health = 150,
	radius = 30,
	height = 56,
	mass = 400,
	speed = 10,
	painchance = 180,
	doomednum = 3002,
	seesound = sfx_sgtsit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_sgtdth,
	attacksound = sfx_sgtatk,
	sprite = SPR_SARG,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 2},
		{action = A_DoomChase, frame = A, tics = 2},
		{action = A_DoomChase, frame = B, tics = 2},
		{action = A_DoomChase, frame = B, tics = 2},
		{action = A_DoomChase, frame = C, tics = 2},
		{action = A_DoomChase, frame = C, tics = 2},
		{action = A_DoomChase, frame = D, tics = 2},
		{action = A_DoomChase, frame = D, tics = 2, next = "chase"},
	},
	melee = {
		{action = A_DoomFaceTarget, frame = E, tics = 8},
		{action = A_DoomFaceTarget, frame = F, tics = 8},
		{action = A_DoomSargAttack, frame = G, tics = 6, next = "chase"},
	},
	pain = {
		{action = nil, frame = H, tics = 3},
		{action = A_DoomPain, frame = H, tics = 3, next = "chase"},
	},
	die = {
		{action = nil, frame = I, tics = 8},
		{action = A_DoomScream, frame = J, tics = 8},
		{action = nil, frame = K, tics = 4},
		{action = A_DoomFall, frame = L, tics = 4},
		{action = nil, frame = M, tics = 4},
		{action = nil, frame = N, tics = -1},
	},
}

DefineDoomActor(name, object, states)

local name = "Spectre"

local object = {
	health = 150,
	radius = 30,
	height = 56,
	mass = 400,
	speed = 10,
	painchance = 180,
	doomednum = 58,
	seesound = sfx_sgtsit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_sgtdth,
	attacksound = sfx_sgtatk,
	sprite = SPR_SARG,
	doomflags = DF_COUNTKILL|DF_SHADOW
}

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 2},
		{action = A_DoomChase, frame = A, tics = 2},
		{action = A_DoomChase, frame = B, tics = 2},
		{action = A_DoomChase, frame = B, tics = 2},
		{action = A_DoomChase, frame = C, tics = 2},
		{action = A_DoomChase, frame = C, tics = 2},
		{action = A_DoomChase, frame = D, tics = 2},
		{action = A_DoomChase, frame = D, tics = 2, next = "chase"},
	},
	melee = {
		{action = A_DoomFaceTarget, frame = E, tics = 8},
		{action = A_DoomFaceTarget, frame = F, tics = 8},
		{action = A_DoomSargAttack, frame = G, tics = 6, next = "chase"},
	},
	pain = {
		{action = nil, frame = H, tics = 3},
		{action = A_DoomPain, frame = H, tics = 3, next = "chase"},
	},
	die = {
		{action = nil, frame = I, tics = 8},
		{action = A_DoomScream, frame = J, tics = 8},
		{action = nil, frame = K, tics = 4},
		{action = A_DoomFall, frame = L, tics = 4},
		{action = nil, frame = M, tics = 4},
		{action = nil, frame = N, tics = -1},
	},
}

DefineDoomActor(name, object, states)