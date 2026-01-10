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

SafeFreeSlot("SPR_SKEL",
"sfx_skesit",
"sfx_skeact",
"sfx_skedth",
"sfx_skeswg",
"sfx_skepch")
local name = "Revenant"

local object = {
	health = 300,
	radius = 20,
	height = 56,
	mass = 500,
	speed = 10,
	painchance = 100,
	doomednum = 66,
	seesound = sfx_skesit,
	activesound = sfx_skeact,
	painsound = sfx_popain,
	deathsound = sfx_skedth,
	sprite = SPR_SKEL,
	doomflags = DF_COUNTKILL
}

local function A_SkelWhoosh(actor)
	A_DoomFaceTarget(actor)
	S_StartSound(actor, sfx_skeswg)
end

local function A_SkelFist(actor)
	if not actor.target then return end

	A_DoomFaceTarget(actor)

	if P_CheckMeleeRange(actor) then
		local damage = ((DOOM_Random()%10)+1)*6
		S_StartSound(actor, sfx_skepch)
		DOOM_DamageMobj(actor.target, actor, actor, damage)
	end
end

/*
//
// A_SkelMissile
//
void A_SkelMissile (mobj_t* actor)
{	
    mobj_t*	mo;
	
    if (!actor->target)
	return;
		
    A_FaceTarget (actor);
    actor->z += 16*FRACUNIT;	// so missile spawns higher
    mo = P_SpawnMissile (actor, actor->target, MT_TRACER);
    actor->z -= 16*FRACUNIT;	// back to normal

    mo->x += mo->momx;
    mo->y += mo->momy;
    mo->tracer = actor->target;
}
*/

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 2},
		{action = A_DoomChase, frame = A, tics = 2},
		{action = A_DoomChase, frame = B, tics = 2},
		{action = A_DoomChase, frame = B, tics = 2},
		{action = A_DoomChase, frame = C, tics = 2},
		{action = A_DoomChase, frame = C, tics = 2},
		{action = A_DoomChase, frame = D, tics = 2},
		{action = A_DoomChase, frame = D, tics = 2},
		{action = A_DoomChase, frame = E, tics = 2},
		{action = A_DoomChase, frame = E, tics = 2},
		{action = A_DoomChase, frame = F, tics = 2},
		{action = A_DoomChase, frame = F, tics = 2, next = "chase"},
	},
	melee = {
		{action = A_DoomFaceTarget, frame = G, tics = 0},
		{action = A_SkelWhoosh,     frame = G, tics = 6},
		{action = A_DoomFaceTarget, frame = H, tics = 6},
		{action = A_SkelFist,       frame = I, tics = 6, next = "chase"},
	},
	missile = {
		{action = A_DoomFaceTarget, frame = J|FF_FULLBRIGHT, tics = 0},
		{action = A_DoomFaceTarget, frame = J|FF_FULLBRIGHT, tics = 10, var1 = 0, var2 = 2},
		{action = A_DoomFaceTarget, frame = K, tics = 8}, -- this should ACTUALLY use A_SkelMissile!
		{action = A_DoomFaceTarget, frame = K, tics = 8, next = "chase"},
	},
	pain = {
		{action = nil,        frame = L, tics = 5},
		{action = A_DoomPain, frame = L, tics = 5, next = "chase"},
	},
	die = {
		{action = nil,          frame = L, tics = 7},
		{action = nil,          frame = M, tics = 7},
		{action = A_DoomScream, frame = N, tics = 7},
		{action = A_DoomFall,   frame = O, tics = 7},
		{action = nil,          frame = P, tics = 7},
		{action = nil,          frame = Q, tics = -1},
	},
	raise = {
		{action = nil, frame = Q, tics = 5},
		{action = nil, frame = P, tics = 5},
		{action = nil, frame = O, tics = 5},
		{action = nil, frame = N, tics = 5},
		{action = nil, frame = M, tics = 5},
		{action = nil, frame = L, tics = 5, next = "chase"},
	},
}

DefineDoomActor(name, object, states)