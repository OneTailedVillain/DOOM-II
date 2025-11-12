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

SafeFreeSlot("SPR_BOS2", "sfx_kmtsit", "sfx_dmact", "sfx_dmpain",
"sfx_kntdth")
local name = "HellKnight"

local object = {
	health = 500,
	radius = 24,
	height = 64,
	mass = 1000,
	speed = 8,
	painchance = 50,
	doomednum = 69,
	seesound = sfx_kmtsit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_kntdth,
	sprite = SPR_BOS2,
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
		{action = A_DoomTroopAttack, frame = G, tics = 8, var1 = 0, var2 = 1, next = "chase"},
	},
	pain = {
		{action = nil,        frame = H, tics = 2},
		{action = A_DoomPain, frame = H, tics = 2, next = "chase"},
	},
	die = {
		{action = nil, frame = I, tics = 5},
		{action = A_DoomScream, frame = J, tics = 5},
		{action = nil, frame = K, tics = 5},
		{action = A_DoomFall, frame = L, tics = 5},
		{action = nil, frame = M, tics = 5},
		{action = nil, frame = N, tics = 5},
		{action = A_DoomBossDeath, frame = O, tics = -1},
	},
}

DefineDoomActor(name, object, states)

SafeFreeSlot("SPR_BOSS", "sfx_brssit", "sfx_brsdth")
local name = "BaronOfHell"

local object = {
	health = 1000,
	radius = 24,
	height = 64,
	mass = 1000,
	speed = 8,
	painchance = 50,
	doomednum = 3003,
	seesound = sfx_brssit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_brsdth,
	sprite = SPR_BOSS,
	doomflags = DF_COUNTKILL
}

DefineDoomActor(name, object, states)