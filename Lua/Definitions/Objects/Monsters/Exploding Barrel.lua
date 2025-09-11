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

SafeFreeSlot("SPR_BAR1", "SPR_BEXP", "sfx_barexp")
local name = "Barrel"

local object = {
	health = 20,
	radius = 10,
	height = 42,
	mass = 100,
	speed = 8,
	painchance = 200,
	doomednum = 2035,
	deathsound = sfx_barexp,
}

local states = {
	stand = {
		{sprite = SPR_BAR1, action = nil, frame = A, tics = 10},
		{sprite = SPR_BAR1, action = nil, frame = B, tics = 10, next = "stand"}
	},
	die = {
		{sprite = SPR_BEXP, action = nil, frame = A, tics = 5},
		{sprite = SPR_BEXP, action = A_DoomScream, frame = B, tics = 5},
		{sprite = SPR_BEXP, action = nil, frame = C, tics = 5},
		{sprite = SPR_BEXP, action = A_DoomExplode, frame = D, tics = 10},
		{sprite = SPR_BEXP, action = A_DoomFall, frame = E, tics = 10},
		{action = nil, frame = A, tics = 1050},
		{action = nil, frame = A, tics = 5},
	},
}

DefineDoomActor(name, object, states)