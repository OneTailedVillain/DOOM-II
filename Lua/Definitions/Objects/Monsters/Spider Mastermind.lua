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

SafeFreeSlot("SPR_SPID",
"sfx_spisit", "sfx_dmact", "sfx_dmpain", "sfx_spidth", "sfx_metal")
local name = "SpiderMastermind"

local object = {
	health = 3000,
	radius = 128,
	height = 100,
	mass = 1000,
	speed = 12,
	painchance = 40,
	doomednum = 7,
	seesound = sfx_spisit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_spidth,
	sprite = SPR_SPID,
	doomflags = DF_COUNTKILL
}

local function A_Metal(actor)
	S_StartSound(actor, sfx_metal)
	A_DoomChase(actor)
end

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"},
	},

	chase = {
		{action = A_Metal,         frame = A, tics = 3},
		{action = A_DoomChase,     frame = A, tics = 3},
		{action = A_DoomChase,     frame = B, tics = 3},
		{action = A_DoomChase,     frame = B, tics = 3},
		{action = A_Metal,         frame = C, tics = 3},
		{action = A_DoomChase,     frame = C, tics = 3},
		{action = A_DoomChase,     frame = D, tics = 3},
		{action = A_DoomChase,     frame = D, tics = 3},
		{action = A_Metal,         frame = E, tics = 3},
		{action = A_DoomChase,     frame = E, tics = 3},
		{action = A_DoomChase,     frame = F, tics = 3},
		{action = A_DoomChase,     frame = F, tics = 3, next = "chase", nextframe = 2},
	},

	missile = {
		{action = A_DoomFaceTarget,      frame = A|FF_FULLBRIGHT, tics = 20},
		{action = A_DoomFire,            frame = G|FF_FULLBRIGHT, tics = 4, var1 = 0, var2 = 2},
		{action = A_DoomFire,            frame = H|FF_FULLBRIGHT, tics = 4, var1 = 0, var2 = 2},
		{action = A_SpidRefire,          frame = H|FF_FULLBRIGHT, tics = 1, next = "missile", nextframe = 2},
	},

	pain = {
		{action = nil,        frame = I, tics = 3},
		{action = A_DoomPain, frame = I, tics = 3, next = "chase"},
	},

	die = {
		{action = A_DoomScream,    frame = J, tics = 10},
		{action = A_DoomFall,      frame = K, tics = 10},
		{action = nil,             frame = L, tics = 10},
		{action = nil,             frame = M, tics = 10},
		{action = nil,             frame = N, tics = 10},
		{action = nil,             frame = O, tics = 10},
		{action = nil,             frame = P, tics = 10},
		{action = nil,             frame = Q, tics = 10},
		{action = nil,             frame = R, tics = 10},
		{action = nil,             frame = S, tics = 30},
		{action = A_DoomBossDeath, frame = S, tics = -1},
	},

	raise = {
		{action = nil, frame = P, tics = 5},
		{action = nil, frame = O, tics = 5},
		{action = nil, frame = N, tics = 5},
		{action = nil, frame = M, tics = 5},
		{action = nil, frame = L, tics = 5},
		{action = nil, frame = K, tics = 5},
		{action = nil, frame = J, tics = 5, next = "chase", nextframe = 2},
	},
}

DefineDoomActor(name, object, states)