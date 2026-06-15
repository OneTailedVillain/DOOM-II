SafeFreeSlot(
    "SPR_MEAT",
    "MT_DOOM_MEAT"
)

local plasmastates = {
    spawn = {
        {sprite = SPR_MEAT, frame = A, tics = 700},
    }
}

local states = FreeDoomStates("Meat", plasmastates)

mobjinfo[MT_DOOM_MEAT] = {
    spawnstate = states.spawn[1],

    speed      = 10*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 8,

    flags = MF_NOCLIP,
}

SafeFreeSlot(
    "SPR_JUNK",
    "MT_DOOM_JUNK"
)

local plasmastates = {
    spawn = {
        {sprite = SPR_JUNK, frame = A, tics = 700},
    }
}

local states = FreeDoomStates("Junk", plasmastates)

mobjinfo[MT_DOOM_JUNK] = {
    spawnstate = states.spawn[1],

    speed      = 10*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 8,

    flags = MF_NOCLIP,
}

function A_DoomTossGib(actor)
    local type = MT_DOOM_MEAT
    if actor.doom.flags & DF_NOBLOOD then
        type = MT_DOOM_JUNK
    end
    -- Spawn the gib at the actor's position + 24 units up
    local gib = P_SpawnMobjFromMobj(actor, 0, 0, 24, type)
    if not gib then
        return
    end
    gib.angle = FixedAngle(P_RandomRange(0, 360) * FRACUNIT)
    P_InstaThrust(gib, gib.angle, P_RandomRange(0, 15) * FRACUNIT)
    gib.momz = P_RandomRange(0, 15) * FRACUNIT
end