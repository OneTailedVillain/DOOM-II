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

SafeFreeSlot("SPR_SKUL", "sfx_sklatk")
local name = "LostSoul"

local object = {
	health = 100,
	radius = 16,
	height = 56,
	mass = 50,
	speed = 8,
	damage = 3,
	painchance = 256,
	doomednum = 3006,
	seesound = sfx_bgsit1,
	activesound = sfx_bgact,
	painsound = sfx_popain,
	deathsound = sfx_bgdth1,
	attacksound = sfx_sklatk,
	sprite = SPR_SKUL,
	flags = MF_ENEMY|MF_SOLID|MF_SHOOTABLE|MF_FLOAT|MF_NOGRAVITY,
	doomflags = DF_NOBLOOD,
}

local states = {
	stand = {
		{action = A_DoomLook, frame = A|FF_FULLBRIGHT, tics = 10},
		{action = A_DoomLook, frame = B|FF_FULLBRIGHT, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A|FF_FULLBRIGHT, tics = 6},
		{action = A_DoomChase, frame = B|FF_FULLBRIGHT, tics = 6, next = "chase"},
	},
	missile = {
		{action = A_DoomFaceTarget,  frame = C|FF_FULLBRIGHT, tics = 8},
		{action = A_SkullAttack,     frame = D|FF_FULLBRIGHT, tics = 8},
		{action = nil,               frame = C|FF_FULLBRIGHT, tics = 8},
		{action = nil,               frame = D|FF_FULLBRIGHT, tics = 6, next = "missile", nextframe = 3},
	},
	pain = {
		{action = nil,        frame = H, tics = 3},
		{action = A_DoomPain, frame = H, tics = 3, next = "chase"},
	},
	die = {
		{action = nil,          frame = F|FF_FULLBRIGHT, tics = 8},
		{action = A_DoomScream, frame = G|FF_FULLBRIGHT, tics = 8},
		{action = nil,          frame = H|FF_FULLBRIGHT, tics = 6},
		{action = A_DoomFall,   frame = I|FF_FULLBRIGHT, tics = 6},
		{action = nil,          frame = J, tics = 6},
		{action = nil,          frame = K, tics = 6},
	},
}

DefineDoomActor(name, object, states)

local function stopCharging(mobj)
	-- TODO: Verify if this is correct!!!
	mobj.state = S_SEESTATE
	mobj.doom.flags = $ & ~DF_SKULLFLY

	mobj.momx = 0
	mobj.momy = 0
	mobj.momz = 0
end

local function LostSoul_MobjLineCollide(mo, line)
    if not (mo and mo.valid and line and line.valid) then
        return
    end

    -- Early return if not charging
    if not (mo.doom.flags & DF_SKULLFLY) then
        return
    end

    -- Add a guard to prevent recursion
	-- TODO: ??? SRB2 is usually smarter than this
    if mo.doom._isHandlingCollision then
        return
    end
    
    mo.doom._isHandlingCollision = true
    
    local side = P_PointOnLineSide(mo.x, mo.y, line)
    local sect = nil

    if side == 0 then
        sect = line.backsector
    else
        sect = line.frontsector
    end

    if not sect then
        stopCharging(mo)
    else
        if mo.z < sect.floorheight then
            stopCharging(mo)
        elseif (mo.z + mo.height) > sect.ceilingheight then
            stopCharging(mo)
        end
    end
    
    mo.doom._isHandlingCollision = false

	-- TODO: REINSTATE THIS!
	-- And also maybe check if v1.666 actually does this
    --if DOOM_UseRaycastInteractionChecks(mo, line, "walk", true, true) then return true else return end
end

local function LostSoul_EnemyMobjCollide(thing, tmthing)
    if not (thing and thing.valid and tmthing and tmthing.valid) then
        return
    end
    
    -- Early return if not charging
    if not (thing.doom.flags & DF_SKULLFLY) then
        return
    end
    
    -- Add recursion guard
    if thing.doom._isHandlingCollision then
        return
    end
    
    thing.doom._isHandlingCollision = true
    
    if tmthing.z + tmthing.momz <= thing.z + thing.height
    or thing.z <= tmthing.z + tmthing.height + tmthing.momz then
        if (tmthing.flags & MF_SHOOTABLE) then
            DOOM_DamageMobj(tmthing, thing, thing, (DOOM_Random() % 8 + 1) * thing.info.damage)
            stopCharging(thing)
        end
    end
    
    thing.doom._isHandlingCollision = false
end

addHook("MobjLineCollide", LostSoul_MobjLineCollide, MT_DOOM_LOSTSOUL)
addHook("MobjMoveCollide", LostSoul_EnemyMobjCollide, MT_DOOM_LOSTSOUL)