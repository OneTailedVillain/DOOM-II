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

SafeFreeSlot("SPR_PAIN",
"sfx_pesit",
"sfx_dmact",
"sfx_pepain",
"sfx_pedth")
local name = "PainElemental"

local object = {
	health = 400,
	radius = 31,
	height = 56,
	mass = 400,
	speed = 8,
	painchance = 128,
	doomednum = 71,
	seesound = sfx_pesit,
	activesound = sfx_dmact,
	painsound = sfx_pepain,
	deathsound = sfx_pedth,
	sprite = SPR_PAIN,
	doomflags = DF_COUNTKILL
}

//
// A_PainShootSkull
// Spawn a lost soul and launch it at the target
//
local function A_PainShootSkull(actor, angle)
	local x
	local y
	local z
	local newmobj
	local an
	local prestep
	local count = 0

	// count total number of skull currently on the level
	for mobj in mobjs.iterate() do
		if mobj.type == MT_DOOM_LOSTSOUL then
			count = $ + 1
		end
	end

    // if there are allready 20 skulls on the level,
    // don't spit another one
	if count > 20 then
		return
	end


    // okay, there's playe for another one
	an = angle -- no need for ANGLETOFINESHIFT
	prestep = 4*FRACUNIT + 3*(actor.info.radius + mobjinfo[MT_DOOM_LOSTSOUL].radius)/2

	x = actor.x + FixedMul(prestep, cos(an))
	y = actor.y + FixedMul(prestep, sin(an))
	z = actor.z + 8*FRACUNIT

	newmobj = P_SpawnMobj(x, y, z, MT_DOOM_LOSTSOUL)


    // Check for movements.
	if not P_TryMove(newmobj, newmobj.x, newmobj.y) then
		// kill it immediately
		DOOM_DamageMobj(newmobj, actor, actor, 10000)
	end

	newmobj.target = actor.target
	A_SkullAttack(newmobj)
end

local function A_PainAttack(actor)
	if not actor.target then return end

	A_DoomFaceTarget(actor)
	A_PainShootSkull(actor, actor.angle)
end

local function A_PainDie(actor)
	A_Fall(actor)
	A_PainShootSkull(actor, actor.angle + ANGLE_90)
	A_PainShootSkull(actor, actor.angle + ANGLE_180)
	A_PainShootSkull(actor, actor.angle + ANGLE_270)
end

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3, next = "chase"},
	},
	missile = {
		{action = A_DoomFaceTarget, frame = E, tics = 6},
		{action = A_DoomFaceTarget, frame = E, tics = 12},
		{action = A_DoomFaceTarget, frame = E, tics = 12},
		{action = A_PainAttack,     frame = F, tics = 12, var2 = 4, next = "chase"},
	},
	pain = {
		{action = nil,        frame = G, tics = 10},
		{action = A_DoomPain, frame = G, tics = 10, next = "chase"},
	},
	die = {
		{action = nil,             frame = H, tics = 8},
		{action = A_DoomScream,    frame = I, tics = 8},
		{action = nil,             frame = J, tics = 8},
		{action = nil,             frame = K, tics = 8},
		{action = A_PainDie,       frame = L, tics = 8},
		{action = nil,             frame = M, tics = 8},
	},
	raise = {
		{action = nil,             frame = H, tics = 8},
		{action = A_DoomScream,    frame = I, tics = 8},
		{action = nil,             frame = J, tics = 8},
		{action = nil,             frame = K, tics = 8},
		{action = A_PainDie,       frame = L, tics = 8},
		{action = nil,             frame = M, tics = 8},
	},
}

DefineDoomActor(name, object, states)