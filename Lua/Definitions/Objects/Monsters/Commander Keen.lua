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

SafeFreeSlot("SPR_KEEN", "sfx_keenpn", "sfx_keendt")
local name = "Keen"

local object = {
	health = 100,
	radius = 16,
	height = 72,
	mass = 10000000,
	painchance = 256,
	doomednum = 72,
	painsound = sfx_keenpn,
	deathsound = sfx_keendt,
	sprite = SPR_KEEN,
	flags = MF_ENEMY|MF_SPAWNCEILING|MF_SHOOTABLE|MF_SOLID|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = nil, frame = A, tics = -1, next = "stand"}
	},
	pain = {
		{action = nil, frame = M, tics = 4},
		{action = A_DoomPain, frame = M, tics = 8, next = "stand"},
	},
	die = {
		{action = nil, frame = A, tics = 6},
		{action = nil, frame = B, tics = 6},
		{action = A_DoomScream, frame = C, tics = 6},
		{action = nil, frame = D, tics = 6},
		{action = nil, frame = E, tics = 6},
		{action = nil, frame = F, tics = 6},
		{action = nil, frame = G, tics = 6},
		{action = nil, frame = H, tics = 6},
		{action = nil, frame = I, tics = 6},
		{action = nil, frame = J, tics = 6},
		{action = A_DoomKeenDeath, frame = K, tics = 6},
		{action = nil, frame = L, tics = -1},
	},
}

DefineDoomActor(name, object, states)