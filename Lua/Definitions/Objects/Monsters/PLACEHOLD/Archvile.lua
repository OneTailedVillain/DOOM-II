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

SafeFreeSlot("SPR_VILE", "sfx_vilatk", "sfx_flamst", "sfx_flame")
local name = "Archvile"

local object = {
	health = 700,
	radius = 20,
	height = 56,
	mass = 500,
	speed = 15,
	painchance = 200,
	doomednum = 64,
	seesound = sfx_bgsit1,
	activesound = sfx_bgact,
	painsound = sfx_popain,
	deathsound = sfx_bgdth1,
	sprite = SPR_VILE,
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
}

DefineDoomActor(name, object, states)

SafeFreeSlot("SPR_FIRE", "sfx_vilatk", "sfx_flamst", "sfx_flame")
local name = "ArchVileFire"

local object = {
	radius = 16,
	height = 32,
	doomednum = -1,
	sprite = SPR_FIRE,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPTHING
}

function A_DoomFireStart()

end

local states = {
    {frame = A|FF_FULLBRIGHT, tics = 2}, --1
    {frame = B|FF_FULLBRIGHT, tics = 2}, --2
    {frame = A|FF_FULLBRIGHT, tics = 2}, --3
    {frame = B|FF_FULLBRIGHT, tics = 2}, --4
    {frame = C|FF_FULLBRIGHT, tics = 2}, --5
    {frame = B|FF_FULLBRIGHT, tics = 2}, --6
    {frame = C|FF_FULLBRIGHT, tics = 2}, --7
    {frame = B|FF_FULLBRIGHT, tics = 2}, --8
    {frame = C|FF_FULLBRIGHT, tics = 2}, --9
    {frame = D|FF_FULLBRIGHT, tics = 2}, --10
    {frame = C|FF_FULLBRIGHT, tics = 2}, --11
    {frame = D|FF_FULLBRIGHT, tics = 2}, --12
    {frame = C|FF_FULLBRIGHT, tics = 2}, --13
    {frame = D|FF_FULLBRIGHT, tics = 2}, --14
    {frame = E|FF_FULLBRIGHT, tics = 2}, --15
    {frame = D|FF_FULLBRIGHT, tics = 2}, --16
    {frame = E|FF_FULLBRIGHT, tics = 2}, --17
    {frame = D|FF_FULLBRIGHT, tics = 2}, --18
    {frame = E|FF_FULLBRIGHT, tics = 2}, --19
    {frame = F|FF_FULLBRIGHT, tics = 2}, --20
    {frame = E|FF_FULLBRIGHT, tics = 2}, --21
    {frame = F|FF_FULLBRIGHT, tics = 2}, --22
    {frame = E|FF_FULLBRIGHT, tics = 2}, --23
    {frame = F|FF_FULLBRIGHT, tics = 2}, --24
    {frame = G|FF_FULLBRIGHT, tics = 2}, --25
    {frame = H|FF_FULLBRIGHT, tics = 2}, --26
    {frame = G|FF_FULLBRIGHT, tics = 2}, --27
    {frame = H|FF_FULLBRIGHT, tics = 2}, --28
    {frame = G|FF_FULLBRIGHT, tics = 2}, --29
    {frame = H|FF_FULLBRIGHT, tics = 2}, --30
}

DefineDoomDeco(name, object, states, onPickup)