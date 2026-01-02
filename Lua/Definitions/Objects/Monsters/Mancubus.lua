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

SafeFreeSlot("SPR_FATT",
"sfx_mansit", "sfx_posact", "sfx_mnpain", "sfx_mandth", "sfx_manatk")
local name = "Mancubus"

local object = {
	health = 600,
	radius = 48,
	height = 64,
	mass = 1000,
	speed = 8,
	painchance = 80,
	doomednum = 67,
	seesound = sfx_mansit,
	activesound = sfx_posact,
	painsound = sfx_mnpain,
	deathsound = sfx_mandth,
	sprite = SPR_FATT,
	doomflags = DF_COUNTKILL
}

local FATSPREAD	= ANGLE_90 / 8

function A_DoomFatRaise(actor)
	if not actor or not actor.valid then return end
	A_FaceTarget(actor)
	S_StartSound(actor, sfx_manatk)
end

function A_DoomFatAttack1(actor)
	if not actor.target then return end

	A_DoomFaceTarget(actor)

	-- Change base aim to one side
	actor.angle = $ + FATSPREAD

	-- First straight shot
	DOOM_SpawnMissile(actor, actor.target, MT_DOOM_MANCUBUSFIREBALL)

	-- Second shot with extra spread
	local mo = DOOM_SpawnMissile(actor, actor.target, MT_DOOM_MANCUBUSFIREBALL)
	if not mo then return end

	mo.angle = $ + FATSPREAD
	local cx = cos(mo.angle)
	local sx = sin(mo.angle)

	-- ? DOOM decides to do this for some reason...
	-- We'll probably have to do it, too
	mo.momx = FixedMul(mo.info.speed, cx)
	mo.momy = FixedMul(mo.info.speed, sx)
end

function A_DoomFatAttack2(actor)
	if not actor.target then return end

	A_DoomFaceTarget(actor)

	-- Aim to opposite side
	actor.angle = $ - FATSPREAD

	-- First straight shot
	DOOM_SpawnMissile(actor, actor.target, MT_DOOM_MANCUBUSFIREBALL)

	-- Second shot with extra opposite deviation
	local mo = DOOM_SpawnMissile(actor, actor.target, MT_DOOM_MANCUBUSFIREBALL)
	if not mo then return end

	mo.angle = $ - (FATSPREAD * 2)
	local cx = cos(mo.angle)
	local sx = sin(mo.angle)

	mo.momx = FixedMul(mo.info.speed, cx)
	mo.momy = FixedMul(mo.info.speed, sx)
end

function A_DoomFatAttack3(actor)
	if not actor.target then return end

	A_DoomFaceTarget(actor)

	-- Left shot
	local mo = DOOM_SpawnMissile(actor, actor.target, MT_DOOM_MANCUBUSFIREBALL)
	if mo then
		mo.angle = $ - (FATSPREAD / 2)
		local cx = cos(mo.angle)
		local sx = sin(mo.angle)

		mo.momx = FixedMul(mo.info.speed, cx)
		mo.momy = FixedMul(mo.info.speed, sx)
	end

	-- Right shot
	mo = DOOM_SpawnMissile(actor, actor.target, MT_DOOM_MANCUBUSFIREBALL)
	if mo then
		mo.angle = $ + (FATSPREAD / 2)
		local cx = cos(mo.angle)
		local sx = sin(mo.angle)

		mo.momx = FixedMul(mo.info.speed, cx)
		mo.momy = FixedMul(mo.info.speed, sx)
	end
end

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 15},
		{action = A_DoomLook, frame = B, tics = 15, next = "stand"},
	},

	chase = {
		{action = A_DoomChase, frame = A, tics = 4},
		{action = A_DoomChase, frame = A, tics = 4},
		{action = A_DoomChase, frame = B, tics = 4},
		{action = A_DoomChase, frame = B, tics = 4},
		{action = A_DoomChase, frame = C, tics = 4},
		{action = A_DoomChase, frame = C, tics = 4},
		{action = A_DoomChase, frame = D, tics = 4},
		{action = A_DoomChase, frame = D, tics = 4},
		{action = A_DoomChase, frame = E, tics = 4},
		{action = A_DoomChase, frame = E, tics = 4},
		{action = A_DoomChase, frame = F, tics = 4},
		{action = A_DoomChase, frame = F, tics = 4, next = "chase"},
	},

	missile = {
		{action = A_DoomFatRaise, frame = G, tics = 20},
		{action = A_DoomFatAttack1, frame = H, tics = 10},
		{action = A_DoomFaceTarget, frame = I, tics = 5},
		{action = A_DoomFaceTarget, frame = G, tics = 5},
		{action = A_DoomFatAttack2, frame = H, tics = 10},
		{action = A_DoomFaceTarget, frame = I, tics = 5},
		{action = A_DoomFaceTarget, frame = G, tics = 5},
		{action = A_DoomFatAttack3, frame = H, tics = 10},
		{action = A_DoomFaceTarget, frame = I, tics = 5},
		{action = A_DoomFaceTarget, frame = G, tics = 5, next = "chase"},
	},

	pain = {
		{action = nil, frame = J, tics = 3},
		{action = A_DoomPain, frame = J, tics = 3, next = "chase"},
	},

	die = {
		{action = nil, frame = K, tics = 6},
		{action = A_DoomScream, frame = L, tics = 6},
		{action = A_DoomFall, frame = M, tics = 6},
		{action = nil, frame = N, tics = 6},
		{action = nil, frame = O, tics = 6},
		{action = nil, frame = P, tics = 6},
		{action = nil, frame = Q, tics = 6},
		{action = nil, frame = R, tics = 6},
		{action = nil, frame = S, tics = 6},
		{action = A_DoomBossDeath, frame = T, tics = -1},
	},

	raise = {
		{action = nil, frame = R, tics = 5},
		{action = nil, frame = Q, tics = 5},
		{action = nil, frame = P, tics = 5},
		{action = nil, frame = O, tics = 5},
		{action = nil, frame = N, tics = 5},
		{action = nil, frame = M, tics = 5},
		{action = nil, frame = L, tics = 5},
		{action = nil, frame = K, tics = 5, next = "chase"},
	},
}

DefineDoomActor(name, object, states)