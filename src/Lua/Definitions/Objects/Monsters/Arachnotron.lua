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

SafeFreeSlot("SPR_BSPI",
"sfx_bspsit", "sfx_bspact", "sfx_dmpain", "sfx_bspdth", "sfx_bspwlk")
local name = "Arachnotron"

local object = {
	health = 500,
	radius = 64,
	height = 64,
	mass = 600,
	speed = 12,
	painchance = 128,
	doomednum = 68,
	seesound = sfx_bspsit,
	activesound = sfx_bspact,
	painsound = sfx_dmpain,
	deathsound = sfx_bspdth,
	sprite = SPR_BSPI,
	doomflags = DF_COUNTKILL
}

function A_DoomBabyMetal(actor)
	S_StartSound(actor, sfx_bspwlk)
	A_DoomChase(actor)
end

function A_DoomBspiAttack(actor)
	A_DoomFaceTarget(actor)
	DOOM_SpawnMissile(actor, actor.target, MT_DOOM_ARCHNOTRONPLASMA)
end

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 15},
		{action = A_DoomLook, frame = B, tics = 15, next = "stand"},
	},

	chase = {
		{action = A_DoomChase, frame = A, tics = 20},
		{action = A_DoomBabyMetal, frame = A, tics = 3},
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomBabyMetal, frame = D, tics = 3},
		{action = A_DoomChase, frame = D, tics = 3},
		{action = A_DoomChase, frame = E, tics = 3},
		{action = A_DoomChase, frame = E, tics = 3},
		{action = A_DoomChase, frame = F, tics = 3},
		{action = A_DoomChase, frame = F, tics = 3, next = "chase", nextframe = 2},
	},

	missile = {
		{action = A_DoomFaceTarget,      frame = A|FF_FULLBRIGHT, tics = 20},
		{action = A_DoomBspiAttack,      frame = G|FF_FULLBRIGHT, tics = 4, var1 = 0, var2 = 3},
		{action = A_DoomBspiAttack,      frame = H|FF_FULLBRIGHT, tics = 4, var1 = 0, var2 = 3},
		{action = A_SpidRefire,          frame = H|FF_FULLBRIGHT, tics = 1, next = "missile", nextframe = 2},
	},

	pain = {
		{action = nil,        frame = I, tics = 3},
		{action = A_DoomPain, frame = I, tics = 3, next = "chase"},
	},

	die = {
		{action = A_DoomScream,    frame = J, tics = 6},
		{action = A_DoomFall,      frame = K, tics = 6},
		{action = nil,             frame = L, tics = 6},
		{action = nil,             frame = M, tics = 6},
		{action = nil,             frame = N, tics = 6},
		{action = nil,             frame = O, tics = 6},
		{action = A_DoomBossDeath, frame = P, tics = -1},
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