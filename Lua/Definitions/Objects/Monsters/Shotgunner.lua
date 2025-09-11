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

SafeFreeSlot("SPR_SPOS", "sfx_posit1", "sfx_posit2", "sfx_posit3",
"sfx_posact",
"sfx_podth1", "sfx_podth2", "sfx_podth3")
local name = "Shotgunner"

local object = {
	health = 30,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 170,
	doomednum = 9,
	seesound = sfx_posit1,
	activesound = sfx_posact,
	painsound = sfx_popain,
	deathsound = sfx_podth1,
	sprite = SPR_SPOS,
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
	missile = {
		{action = A_DoomFaceTarget, frame = F, tics = 10},
		{action = A_DoomFire, frame = F, tics = 8, var1 = 0, var2 = 2},
		{action = nil, frame = E, tics = 8, next = "chase"},
	},
	pain = {
		{action = nil, frame = G, tics = 3},
		{action = A_DoomPain, frame = G, tics = 3, next = "chase"},
	},
	die = {
		{action = nil, frame = H, tics = 5},
		{action = A_DoomScream, frame = I, tics = 5},
		{action = A_DoomFall, frame = J, tics = 5},
		{action = nil, frame = K, tics = 5},
		{action = nil, frame = L, tics = -1},
	},
	gib = {
		{action = nil, frame = M, tics = 5},
		{action = A_DoomXScream, frame = N, tics = 5},
		{action = A_DoomFall, frame = O, tics = 5},
		{action = nil, frame = P, tics = 5},
		{action = nil, frame = Q, tics = 5},
		{action = nil, frame = R, tics = 5},
		{action = nil, frame = S, tics = 5},
		{action = nil, frame = T, tics = 5},
		{action = nil, frame = U, tics = -1},
	},
}

DefineDoomActor(name, object, states)