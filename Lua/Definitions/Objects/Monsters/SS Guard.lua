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

SafeFreeSlot("SPR_SSWV",
"sfx_sssit",
"sfx_ssdth")
local name = "SSGuard"

local object = {
	health = 50,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 170,
	doomednum = 84,
	seesound = sfx_sssit,
	activesound = sfx_posact,
	painsound = sfx_popain,
	deathsound = sfx_ssdth,
	sprite = SPR_SSWV,
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
		{action = A_DoomFaceTarget, frame = E, tics = 10},
		{action = A_DoomFaceTarget, frame = F, tics = 10},
		{action = A_DoomFire, frame = G|FF_FULLBRIGHT, tics = 4, var1 = 0, var2 = 2},
		{action = A_DoomFaceTarget, frame = F, tics = 10},
		{action = A_DoomFire, frame = G|FF_FULLBRIGHT, tics = 4, var1 = 0, var2 = 2},
		{action = A_CPosRefire, frame = F, tics = 1, next = "missile", nextframe = 2},
	},
	pain = {
		{action = nil, frame = H, tics = 3},
		{action = A_DoomPain, frame = H, tics = 3, next = "chase"},
	},
	die = {
		{action = nil, frame = I, tics = 5},
		{action = A_DoomScream, frame = J, tics = 5},
		{action = A_DoomFall, frame = K, tics = 5},
		{action = nil, frame = L, tics = 5},
		{action = nil, frame = M, tics = -1},
	},
	gib = {
		{action = nil, frame = N, tics = 5},
		{action = A_DoomXScream, frame = O, tics = 5},
		{action = A_DoomFall, frame = P, tics = 5},
		{action = nil, frame = Q, tics = 5},
		{action = nil, frame = R, tics = 5},
		{action = nil, frame = S, tics = 5},
		{action = nil, frame = T, tics = 5},
		{action = nil, frame = U, tics = 5},
		{action = nil, frame = V, tics = -1},
	},
}

DefineDoomActor(name, object, states)