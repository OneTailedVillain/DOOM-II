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

SafeFreeSlot("SPR_MISL",
"S_ROCKET_SPAWN",
"S_ROCKET_EXPLODE1", "S_ROCKET_EXPLODE2", "S_ROCKET_EXPLODE3",
"sfx_barexp")

mobjinfo[MT_DOOM_ROCKETPROJ] = {
	spawnstate   = S_ROCKET_SPAWN,
	deathstate   = S_ROCKET_EXPLODE1,
	deathsound   = sfx_barexp,
	speed        = 20 * FRACUNIT,
	radius       = 11 * FRACUNIT,
	height       = 8 * FRACUNIT,
	damage       = 20,
	flags        = MF_MISSILE|MF_NOGRAVITY,
}

states[S_ROCKET_SPAWN] = {
    sprite = SPR_MISL,
    frame = A|FF_FULLBRIGHT,
    tics = -1,
    action = nil,
    var1 = nil,
    var2 = nil,
    nextstate = nil,
}

states[S_ROCKET_EXPLODE1] = {
    sprite = SPR_MISL,
    frame = B|FF_FULLBRIGHT,
    tics = 8,
	action = A_DoomExplode,
    var1 = nil,
    var2 = nil,
    nextstate = S_ROCKET_EXPLODE2
}

states[S_ROCKET_EXPLODE2] = {
    sprite = SPR_MISL,
    frame = C|FF_FULLBRIGHT,
    tics = 6,
    action = nil,
    var1 = nil,
    var2 = nil,
    nextstate = S_ROCKET_EXPLODE3
}

states[S_ROCKET_EXPLODE3] = {
    sprite = SPR_MISL,
    frame = D|FF_FULLBRIGHT,
    tics = 4,
    action = nil,
    var1 = nil,
    var2 = nil,
    nextstate = S_NULL
}