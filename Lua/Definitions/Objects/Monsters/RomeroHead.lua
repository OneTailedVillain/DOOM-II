-- Includes Monster Spawner
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

SafeFreeSlot("SPR_BBRN", "sfx_bospn", "sfx_bosdth")
local name = "RomeroHead"

local object = {
	health = 250,
	radius = 16,
	height = 16,
	mass = 10000000,
	speed = 8,
	painchance = 255,
	doomednum = 88,
	painsound = sfx_bospn,
	deathsound = sfx_bosdth,
	sprite = SPR_BBRN,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = nil, frame = A, tics = -1},
	},
	pain = {
		{action = A_DoomPain, frame = B, tics = 36, next = "stand"},
	},
	die = {
		{action = nil, frame = A, tics = 100},
		{action = nil, frame = A, tics = 10},
		{action = nil, frame = A, tics = 10},
		{action = nil, frame = A, tics = -1},
	},
}

DefineDoomActor(name, object, states)

SafeFreeSlot("SPR_SSWV")

local name = "MonsterSpawner"

local object = {
	radius = 20,
	height = 32,
	painchance = 255,
	doomednum = 89,
	sprite = SPR_SSWV,
	flags = MF_SCENERY|MF_NOSECTOR|MF_NOBLOCKMAP|MF_NOGRAVITY
}

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_BrainAwake, frame = A, tics = 181},
		{action = A_BrainSpit, frame = A, tics = 150, next = "chase"},
	},
}

DefineDoomActor(name, object, states)