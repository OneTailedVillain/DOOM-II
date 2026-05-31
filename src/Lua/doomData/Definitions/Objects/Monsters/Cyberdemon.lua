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

SafeFreeSlot("SPR_CYBR",
"sfx_cybsit",
"sfx_hoof",
"sfx_metal",
"sfx_dmact",
"sfx_dmpain",
"sfx_cybdth")
local name = "Cyberdemon"

local object = {
	health = 4000,
	radius = 40,
	height = 110,
	mass = 1000,
	speed = 16,
	painchance = 20,
	doomednum = 16,
	seesound = sfx_cybsit,
	activesound = sfx_dmact,
	painsound = sfx_dmpain,
	deathsound = sfx_cybdth,
	sprite = SPR_CYBR,
	doomflags = DF_COUNTKILL
}

local function A_Hoof(actor)
	S_StartSound(actor, sfx_hoof)
	A_DoomChase(actor)
end

local function A_Metal(actor)
	S_StartSound(actor, sfx_metal)
	A_DoomChase(actor)
end

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_Hoof, frame = A, tics = 3},
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_Metal, frame = D, tics = 3},
		{action = A_DoomChase, frame = D, tics = 3, next = "chase"},
	},
	missile = {
		{action = A_DoomFaceTarget, frame = E, tics = 6},
		{action = A_DoomFire,       frame = F, tics = 12, var2 = 4},
		{action = A_DoomFaceTarget, frame = E, tics = 12},
		{action = A_DoomFire,       frame = F, tics = 12, var2 = 4},
		{action = A_DoomFaceTarget, frame = E, tics = 12},
		{action = A_DoomFire,       frame = F, tics = 12, var2 = 4, next = "chase"},
	},
	pain = {
		{action = A_DoomPain, frame = G, tics = 10, next = "chase"},
	},
	die = {
		{action = nil,             frame = H, tics = 10},
		{action = A_DoomScream,    frame = I, tics = 10},
		{action = nil,             frame = J, tics = 10},
		{action = nil,             frame = K, tics = 10},
		{action = nil,             frame = L, tics = 10},
		{action = A_DoomFall,      frame = M, tics = 10},
		{action = nil,             frame = N, tics = 10},
		{action = nil,             frame = O, tics = 10},
		{action = nil,             frame = P, tics = 30},
		{action = A_DoomBossDeath, frame = P, tics = -1},
	},
}

DefineDoomActor(name, object, states)