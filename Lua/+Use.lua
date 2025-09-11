DOOM_Freeslot("MT_DOOM_USERAYCAST", "sfx_swtchn", "MT_DOOM_BULLET", "S_ONETICINVIS",
"S_DEBUG")

states[S_ONETICINVIS] = {
	sprite = SPR_NULL,
	frame = A,
	tics = 2,
	var1 = 0,
	var2 = 0,
	nextstate = S_NULL
}

states[S_DEBUG] = {
	sprite = SPR_PLAY,
	frame = A,
	tics = -1,
	var1 = 0,
	var2 = 0,
	nextstate = S_NULL
}

mobjinfo[MT_DOOM_USERAYCAST] = {
	spawnstate = S_DEBUG,
	spawnhealth = 100,
	deathstate = S_ONETICINVIS,
	speed = 4*FRACUNIT,
	radius = 1*FRACUNIT,
	height = 2*FRACUNIT,
	dispoffset = 4,
	flags = MF_MISSILE|MF_NOGRAVITY,
}

mobjinfo[MT_DOOM_BULLET] = {
	spawnstate = S_DEBUG,
	spawnhealth = 100,
	deathstate = S_ONETICINVIS,
	speed = 4*FRACUNIT,
	radius = 1*FRACUNIT,
	height = 2*FRACUNIT,
	dispoffset = 4,
	flags = MF_MISSILE|MF_NOGRAVITY,
}

local function FixedHypot3(x, y, z)
    return FixedHypot(FixedHypot(x, y), z)
end
/*
opts = {
  speed = <fixed speed (defaults to mobjinfo[mobj.type].speed)>,
  maxdist = <fixed units>,
  online = function(ray, usedLine) -> bool/nil  -- if returns true, stops further handling (like original hook),
  onthing = function(ray, thing) -> bool/nil,
  onfinish = function(ray, hit) -> nil,
}
Returns true if a hit occurred, false otherwise.
*/
rawset(_G, "DOOM_GenericRaycast", function(mobj, opts)
    if not (mobj and mobj.valid) then return false end
    opts = opts or {}

    local shooter = mobj.target
    if shooter and shooter.valid then
        shooter.flags = shooter.flags | MF_NOCLIP
    end

    local speed_fp = opts.speed or (mobjinfo[mobj.type] and mobjinfo[mobj.type].speed) or (4*FRACUNIT)
    local maxdist  = mobj.dist or opts.maxdist or (FRACUNIT * 4096)
    local diststeps = FixedCeil(FixedDiv(maxdist, speed_fp))/FRACUNIT

    -- Normalize momentum to exactly speed_fp each step (preserve direction)
    do
        local mag = FixedHypot3(mobj.momx, mobj.momy, mobj.momz)
        if mag > 0 then
            local ux = FixedDiv(mobj.momx, mag)
            local uy = FixedDiv(mobj.momy, mag)
            local uz = FixedDiv(mobj.momz, mag)
            mobj.momx = FixedMul(ux, speed_fp)
            mobj.momy = FixedMul(uy, speed_fp)
            mobj.momz = FixedMul(uz, speed_fp)
            mobj.scale = FRACUNIT
        end
    end

    local hit = false
    for i = 1, diststeps do
        if not (mobj and mobj.valid) then break end

        -- P_RailThinker advances the mobj and triggers engine collision hooks (MobjMoveCollide / MobjLineCollide)
        local collided = P_RailThinker(mobj)

        if collided then
            hit = true
            -- If a per-rayline callback exists, call it (it may do the work and/or kill the ray)
            if not (mobj and mobj.valid) then return end
			local cb = mobj.raycastCallbacks
            if cb and cb.online then
                local ok = pcall(cb.online, mobj, collided) -- collided is the line in MobjLineCollide hook
                -- if cb returns true, consider it consumed (we already hit so break)
                -- we ignore return semantics beyond that because MobjLineCollide hook/engine handling may already apply
            end
            break
        end
    end

    -- post-trace behavior
    if not hit then
        if mobj.stats and mobj.stats.israycaster then
            mobj.state = S_NULL
        else
            mobj.dontraycast = true
        end
    else
        if mobj and mobj.valid then mobj.dontraycast = true end
    end

    if opts.onfinish then
        pcall(opts.onfinish, mobj, hit)
    end

    if shooter and shooter.valid then
        shooter.flags = shooter.flags & ~MF_NOCLIP
    end

    return hit
end)

local function HL_TheRaycastingAtHome(mobj)
    if not (mobj and mobj.valid) then return end
    if mobj.dontraycast then return end

    DOOM_GenericRaycast(mobj, {
        onfinish = function(ray, hit)
            P_KillMobj(ray)
        end,
    })
end

local MAX_USE_DIST = USERANGE -- How far the check can go before it's too far
rawset(_G, "DOOM_TryUse", function(player)
    if not (player and player.mo) then return end
    local ray = P_SpawnPlayerMissile(player.mo, MT_DOOM_USERAYCAST)
    if not (ray and ray.valid) then return end

    ray.scale = player.mo.scale
    ray.target = player.mo
    ray.dist = MAX_USE_DIST
	ray.doom = $ or {}
	ray.doom.damage = 0

    DOOM_GenericRaycast(ray, { maxdist = MAX_USE_DIST,
	onfinish = function(ray, hit)
		P_KillMobj(ray)
	end
	})
end)

rawset(_G, "DOOM_ShootBullet", function(player, dist)
    if not (player and player.mo) then return end
    local ray = P_SpawnPlayerMissile(player.mo, MT_DOOM_BULLET)
    if not (ray and ray.valid) then return end

    ray.scale = player.mo.scale
    ray.target = player.mo

    DOOM_GenericRaycast(ray, { maxdist = dist or MISSILERANGE })
end)

addHook("MobjLineCollide", function(ray, usedLine)
    if not (ray and ray.valid) then return end

    local lineSpecial = doom.linespecials[usedLine]
	if not lineSpecial then
		if not (usedLine.flags & ML_TWOSIDED) or usedLine.frontsector.ceilingheight <= usedLine.backsector.floorheight then
			-- Blocked
			S_StartSound(ray.target, sfx_noway)
			P_KillMobj(ray)
			return
		end
	end
    local whatIs = doom.lineActions[lineSpecial]

    if not whatIs then
		if lineSpecial != 0 then
			print("Invalid line special '" .. tostring(lineSpecial) .. "'!")
			S_StartSound(ray.target, sfx_noway) P_KillMobj(ray)
		end
		return
	end
    if whatIs.activationType == "interact" then
        if whatIs.type == "exit" then
			DOOM_ExitLevel()
            return true
        end
        DOOM_AddThinker(usedLine.backsector, whatIs)
    elseif whatIs.activationType == "switch" then
		S_StartSound(ray.target, sfx_swtchn)
        for sector in sectors.tagged(usedLine.tag) do
            DOOM_AddThinker(sector, whatIs)
        end
	else
		S_StartSound(ray.target, sfx_noway)
    end

    P_KillMobj(ray)
    return true
end, MT_DOOM_USERAYCAST)

local function MaybeHitFloor_Simple(bullet)
    local shooter = bullet.shooter
    if not (shooter and shooter.valid) then return end

    local bottom = bullet.z
    local top    = bullet.z + bullet.height

    if not bullet.hitenemy and bottom <= bullet.floorz then
        bullet.z = bullet.floorz
        bullet.fuse = 0
		P_SpawnMobjFromMobj(bullet, 0, 0, 0, MT_DOOM_BULLETPUFF)
        bullet.state = S_NULL
    elseif not bullet.hitenemy and top >= bullet.ceilingz then
        bullet.z = bullet.ceilingz - bullet.height
        bullet.fuse = 0
		P_SpawnMobjFromMobj(bullet, 0, 0, 0, MT_DOOM_BULLETPUFF)
        bullet.state = S_NULL
    end
end

local function BulletHit_Simple(bullet, target, line)
    local shooter = bullet.shooter
    if not (shooter and shooter.valid) then return end

    if target then
        if not (target.z + target.height >= bullet.z and target.z <= bullet.z + bullet.height) then return end
    end

	P_SpawnMobjFromMobj(bullet, 0, 0, 0, MT_DOOM_BULLETPUFF)
    bullet.state = S_NULL
end

local function BulletHitObject_Simple(tmthing, thing)
    if tmthing.hitenemy then return false end
    if tmthing.target == thing then return false end
    if not (thing.flags & MF_SHOOTABLE) then return false end
    if not (thing.z + thing.height >= tmthing.z and thing.z <= tmthing.z + tmthing.height) then return end

    local damage = tmthing.doom.damage or 10
    DOOM_DamageMobj(thing, tmthing, tmthing and tmthing.target or tmthing, damage)
    -- tmthing.state = S_HL1_HIT or S_NULL
	local puff = P_SpawnMobjFromMobj(tmthing, 0, 0, 0, MT_DOOM_BULLETPUFF)
    tmthing.momx = 0
    tmthing.momy = 0
    tmthing.momz = 0
    tmthing.hitenemy = true

    return false
end

for _, mt in ipairs({MT_DOOM_BULLET}) do
    addHook("MobjThinker", MaybeHitFloor_Simple, mt)
    addHook("MobjMoveBlocked", BulletHit_Simple, mt)
    addHook("MobjMoveCollide", BulletHitObject_Simple, mt)
end

rawset(_G, "DOOM_Fire", function(source, dist, horizspread, vertspread, pellets, min, max, incs)
    if not (source and source.valid) then return end

    -- normalize arguments
    dist        = dist        or MISSILERANGE
    horizspread = horizspread or 0
    vertspread  = vertspread  or 0
    pellets     = pellets     or 1

    local shooter, player = nil, nil

    -- figure out whether we're dealing with a player or generic mobj
    if source.player then
        -- source is a mobj_t belonging to a player
        shooter = source
        player  = source.player
    elseif source.mo then
        -- source is a player_t
        shooter = source.mo
        player  = source
    else
        -- probably plain mobj_t?
        shooter = source
    end

    for i = 1, pellets do
        -- save original state
        local ogangle = shooter.angle
        local ogaiming = player and player.aiming or 0

        -- spread
        local hspr = FixedMul(P_RandomFixed() - FRACUNIT/2, horizspread*2)
        local vspr = FixedMul(P_RandomFixed() - FRACUNIT/2, vertspread*2)

        shooter.angle = $ + FixedAngle(hspr)
        if player then
            player.aiming = $ + FixedAngle(vspr)
        end

        -- choose spawn call
        local bullet
        if player then
            -- player-based missile (respects vertical aim)
            bullet = P_SpawnPlayerMissile(shooter, MT_DOOM_BULLET)
        else
            -- generic mobj missile
            local aimtarget = shooter.target
            bullet = P_SpawnMissile(shooter, aimtarget or shooter, MT_DOOM_BULLET)
        end

        -- restore state
        shooter.angle = ogangle
        if player then player.aiming = ogaiming end

        if bullet and bullet.valid then
            local divisor = incs or min
            bullet.doom = $ or {}
            bullet.doom.damage = (DOOM_Random() % (max / divisor) + 1) * divisor

            bullet.scale   = shooter.scale
            bullet.target  = shooter
            bullet.shooter = shooter
            bullet.dist    = dist

            -- raycast cleanup
            DOOM_GenericRaycast(bullet, {
                maxdist = dist,
                onfinish = function(ray, hit)
					if not (ray and ray.valid) then return end
                    P_KillMobj(ray)
                end
            })
        end
    end
end)