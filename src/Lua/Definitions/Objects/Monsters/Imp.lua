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

SafeFreeSlot("SPR_TROO")
local name = "Imp"

local object = {
	health = 60,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 200,
	doomednum = 3001,
	seesound = sfx_bgsit1,
	activesound = sfx_bgact,
	painsound = sfx_popain,
	deathsound = sfx_bgdth1,
	sprite = SPR_TROO,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = D, tics = 3},
		{action = A_DoomChase, frame = D, tics = 3, next = "chase"},
	},
	attack = {
		{action = A_DoomFaceTarget, frame = E, tics = 8},
		{action = A_DoomFaceTarget, frame = F, tics = 8},
		{action = A_DoomTroopAttack, frame = G, tics = 6, next = "chase"},
	},
	pain = {
		{action = nil, frame = H, tics = 3},
		{action = A_DoomPain, frame = H, tics = 3, next = "chase"},
	},
	die = {
		{action = nil, frame = I, tics = 8},
		{action = A_DoomScream, frame = J, tics = 8},
		{action = nil, frame = K, tics = 6},
		{action = A_DoomFall, frame = L, tics = 6},
		{action = nil, frame = M, tics = -1},
	},
	gib = {
		{action = nil, frame = N, tics = 5},
		{action = A_DoomXScream, frame = O, tics = 5},
		{action = nil, frame = P, tics = 5},
		{action = A_DoomFall, frame = Q, tics = 5},
		{action = nil, frame = R, tics = 5},
		{action = nil, frame = S, tics = 5},
		{action = nil, frame = T, tics = 5},
		{action = nil, frame = U, tics = -1},
	},
	raise = {
		{frame = M, tics = 8},
		{frame = L, tics = 8},
		{frame = K, tics = 6},
		{frame = J, tics = 6},
		{frame = I, tics = 6, next = "chase"},
	},
}

DefineDoomActor(name, object, states)