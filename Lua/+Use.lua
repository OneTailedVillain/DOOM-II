DOOM_Freeslot("MT_DOOM_USERAYCAST", "sfx_swtchn", "MT_DOOM_BULLETRAYCAST", "S_ONETICINVIS",
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

mobjinfo[MT_DOOM_BULLETRAYCAST] = {
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
        --shooter.flags = shooter.flags | MF_NOCLIP
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
        --shooter.flags = shooter.flags & ~MF_NOCLIP
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
	local oldpitch = player.pitch
	player.pitch = 0
    local ray = P_SpawnPlayerMissile(player.mo, MT_DOOM_USERAYCAST)
	player.pitch = oldpitch
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
    local ray = P_SpawnPlayerMissile(player.mo, MT_DOOM_BULLETRAYCAST)
    if not (ray and ray.valid) then return end

    ray.scale = player.mo.scale
    ray.target = player.mo

    DOOM_GenericRaycast(ray, { maxdist = dist or MISSILERANGE })
end)

rawset(_G, "DOOM_HandleUseRayHit", function(ray, usedLine)
	local lineSpecial = doom.linespecials[usedLine]
	if not lineSpecial then
		if not (usedLine.flags & ML_TWOSIDED) 
		or usedLine.frontsector.ceilingheight <= usedLine.backsector.floorheight 
		then
			S_StartSound(ray.target, sfx_noway)
			P_KillMobj(ray)
			return true
		end
		return false
	end

	local whatIs = doom.lineActions[lineSpecial]
	if not whatIs then
		S_StartSound(ray.target, sfx_noway)
		P_KillMobj(ray)
		return true
	end

	if whatIs.activationType == "switch" then
		if whatIs.type == "exit" then
			if gametype == GT_DOOMDM or gametype == GT_DOOMDMTWO then
				if not doom.cvars.dmExit.value then
					DOOM_DamageMobj(ray.target, ray.target, ray.target, (FRACUNIT/2)-1)
                    doom.doObituary(ray.target, ray.target, ray.target, doom.damage.exit)
					return true
				end
			end

			doom.didSecretExit = whatIs.secret
			DOOM_ExitLevel()
			return true
		end

		local switchThinker = {
			type = "switch",
			victimData = whatIs,
			owner = whatIs.owner,
			switcher = ray.target,
			victimLine = usedLine,
			victimTag = usedLine.tag,
			allowOff = whatIs.repeatable,
			lock = whatIs.lock,
			denyMessage = whatIs.denyMessage,
			onSound = whatIs.onSound,
			offSound = whatIs.offSound,
			delay = whatIs.delay,
		}

		DOOM_AddThinker(usedLine, switchThinker)
		P_KillMobj(ray)
		return true
	end

	return false
end)

---@param ray mobj_t
---@param usedLine line_t
---@param useType string
---@param silent boolean|nil
---@param dontkill boolean|nil
rawset(_G, "DOOM_UseRaycastInteractionChecks", function(ray, usedLine, useType, silent, dontkill)
    local lineSpecial = doom.linespecials[usedLine]
	if not lineSpecial then
		if not (usedLine.flags & ML_TWOSIDED) or usedLine.frontsector.ceilingheight <= usedLine.backsector.floorheight then
			-- Blocked
			if not silent then
				S_StartSound(ray.target, sfx_noway)
			end
			P_KillMobj(ray)
			return
		end
	end
    local whatIs = doom.lineActions[lineSpecial]

    if not whatIs then
		if lineSpecial != 0 then
			print("Invalid line special '" .. tostring(lineSpecial) .. "'!")
			if not silent then
				S_StartSound(ray.target, sfx_noway) P_KillMobj(ray)
			end
		end
		return
	end

	if whatIs.activationType != useType then return end
    
    -- Handle immediate exit special
    if whatIs.type == "exit" then
		if gametype == GT_DOOMDM or gametype == GT_DOOMDMTWO then
			if not doom.cvars.dmExit.value then
				DOOM_DamageMobj(ray.target, ray.target, ray.target, (FRACUNIT/2)-1)
                doom.doObituary(ray.target, ray.target, ray.target, doom.damage.exit)
				return true
			end
		end

        doom.didSecretExit = whatIs.secret
        DOOM_ExitLevel()
        return true
    end

    -- Build thinker data and hand off to thinkers
    local switchThinker = {
        type = "switch",
        victimData = whatIs,
		owner = whatIs.owner,
        switcher = ray.target,
        victimLine = usedLine,
        victimTag = usedLine.tag,
        allowOff = whatIs.repeatable,
        lock = whatIs.lock,
        denyMessage = whatIs.denyMessage,
        onSound = whatIs.onSound,
        offSound = whatIs.offSound,
        delay = whatIs.delay,
    }

	DOOM_AddThinker(usedLine, switchThinker)
    print("Use function called (with " .. useType .. ") with dont kill set to " .. dontkill)
    if not dontkill then
        P_KillMobj(ray)
    end
    return true
end)

addHook("MobjLineCollide", function(ray, usedLine)
    if not (ray and ray.valid) then return end
	if DOOM_UseRaycastInteractionChecks(ray, usedLine, "switch") then return true else return end
end, MT_DOOM_USERAYCAST)

addHook("MobjLineCollide", function(ray, usedLine)
    if not (ray and ray.valid) then return end
	if DOOM_UseRaycastInteractionChecks(ray, usedLine, "gunshot", true) then return true else return end
end, MT_DOOM_BULLETRAYCAST)

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

	if tmthing.doom.hitsound then
		S_StartSound(tmthing.target, tmthing.doom.hitsound)
	elseif tmthing.target.player and tmthing.target.player.doom.curwep then
		if doom.weapons[tmthing.target.player.doom.curwep] and doom.weapons[tmthing.target.player.doom.curwep].hitsound then
			S_StartSound(tmthing.target, doom.weapons[tmthing.target.player.doom.curwep].hitsound)
		end
	end

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

for _, mt in ipairs({MT_DOOM_BULLETRAYCAST}) do
    addHook("MobjThinker", MaybeHitFloor_Simple, mt)
    addHook("MobjMoveBlocked", BulletHit_Simple, mt)
    addHook("MobjMoveCollide", BulletHitObject_Simple, mt)
end

local topslope    =  100*FRACUNIT/160;
local bottomslope = -100*FRACUNIT/160;

local function Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

rawset(_G, "DOOM_Fire", function(source, dist, horizspread, vertspread, pellets, min, max, incs, shootmobj, shootflags2, shootfuse, firefunc, hitsound)
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

		if horizspread then
			shooter.angle = $ + FixedAngle(hspr)
		end
        if player and vertspread then
            player.aiming = $ + FixedAngle(vspr)
        end

        -- choose spawn call
        local bullet
        if player then
            bullet = P_SpawnPlayerMissile(shooter, shootmobj or MT_DOOM_BULLETRAYCAST, shootflags2)
        else
            bullet = P_SPMAngle(shooter, shootmobj or MT_DOOM_BULLETRAYCAST, shooter.angle, 0, shootflags2)
        end

		if firefunc then
			if type(firefunc) != "function" then error("firefunc field should be of type 'function'!") end
			firefunc(shooter and shooter.player or shooter, bullet)
		end

        -- restore state
        shooter.angle = ogangle
        if player then player.aiming = ogaiming end

		if not player then
			local dest = source.target
			local shootz  = source.z + (source.height >> 1) + 8*FRACUNIT
			local targetz = dest.z + (dest.height >> 1)

			local dist = P_AproxDistance(dest.x - source.x, dest.y - source.y)

			local dz = targetz - shootz
			local slope = FixedDiv(dz, dist)

			-- Doom autoaim limits
			local topslope    =  100*FRACUNIT/160
			local bottomslope = -100*FRACUNIT/160

			slope = Clamp(slope, bottomslope, topslope)

			bullet.momz = FixedMul(slope, mobjinfo[MT_DOOM_BULLETRAYCAST].speed)
		end

        if bullet and bullet.valid then
            local divisor = incs or min
            bullet.doom = $ or {}
            bullet.doom.damage = min != max and ((DOOM_Random() % (max / divisor) + 1) * divisor) or max
			bullet.doom.hitsound = hitsound

            bullet.scale   = shooter.scale
            bullet.target  = shooter
            bullet.shooter = shooter
            bullet.dist    = dist
			bullet.fuse    = shootfuse or 0

            -- raycast cleanup
			if bullet.type == MT_DOOM_BULLETRAYCAST then
				DOOM_GenericRaycast(bullet, {
					maxdist = dist,
					onfinish = function(ray, hit)
						if not (ray and ray.valid) then return end
						P_KillMobj(ray)
					end
				})
			end
        end
    end
end)