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

local function LostSoul_MobjLineCollide(mo, line)
    if not (mo and mo.valid and line and line.valid) then
        return
    end

    DOOM_UseRaycastInteractionChecks(mo, line, "walk", true, true)
end

local function LostSoul_EnemyMobjCollide(thing, tmthing)
    if not (thing and thing.valid and tmthing and tmthing.valid) then
        return
    end
    
    if tmthing.z + tmthing.momz <= thing.z + thing.height
    or thing.z <= tmthing.z + tmthing.height + tmthing.momz then
		if tmthing.doom.flags & DF_SKULLFLY ~= 0 then
			print("Successfully hit something!")
			DOOM_DamageMobj(tmthing, thing, tmthing, (DOOM_Random() % 8 + 1) * thing.info.damage)
		end
    end
end

addHook("MobjLineCollide", LostSoul_MobjLineCollide, MT_DOOM_LOSTSOUL)
addHook("MobjCollide", LostSoul_EnemyMobjCollide, MT_DOOM_LOSTSOUL)