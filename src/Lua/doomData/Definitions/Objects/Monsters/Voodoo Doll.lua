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

local name = "VoodooDoll"

local object = {
	health = 100,
	radius = 16,
	height = 56,
	mass = 100,
	speed = 0,
	painchance = 255,
	doomednum = -1,
	painsound = sfx_plpain,
	deathsound = sfx_pldeth,
	sprite = SPR_PLAY,
	seestate = S_DOOM_PLAYER_MOVE1,
	spawnstate = S_DOOM_PLAYER_STAND1,
	missilestate = S_DOOM_PLAYER_ATTACK1,
	deathstate = S_DOOM_PLAYER_DIE1,
	xdeathstate = S_DOOM_PLAYER_GIB1,
	painstate = S_DOOM_PLAYER_PAIN1,
	doomflags = 0
	-- TODO:
	--doomflags = DF_COUNTKILL
}

local states = {}

DefineDoomActor(name, object, states)

/*
doom.addHook("MobjDamage", function(target, inflictor, source, damage, damagetype, minhealth)
    -- Get first player
    local player = players[0]
    if not player or not player.valid then return true end
    if not player.mo or not player.mo.valid then return true end

    -- Forward damage to player
    DOOM_DamageMobj(player.mo, inflictor, source, damage, damagetype, minhealth)
end, MT_DOOM_VOODOODOLL)
*/