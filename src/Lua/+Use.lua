DOOM_Freeslot("MT_DOOM_USERAYCAST", "sfx_swtchn", "MT_DOOM_BULLETRAYCAST", "S_ONETICINVIS",
"S_DEBUG")

states[S_ONETICINVIS] = {
	sprite = SPR_NULL,
	frame = A,
	tics = 2,
    action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_NULL
}

states[S_DEBUG] = {
	sprite = SPR_PLAY,
	frame = A,
	tics = -1,
    action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_NULL
}

mobjinfo[MT_DOOM_USERAYCAST] = {
	spawnstate = S_DEBUG,
	spawnhealth = 100,
	deathstate = S_ONETICINVIS,
	speed = 4*FRACUNIT,
	radius = FRACUNIT/2,
	height = 1*FRACUNIT,
	dispoffset = 4,
	flags = MF_MISSILE|MF_NOGRAVITY,
}

mobjinfo[MT_DOOM_BULLETRAYCAST] = {
	spawnstate = S_DEBUG,
	spawnhealth = 100,
	deathstate = S_ONETICINVIS,
	speed = 4*FRACUNIT,
	radius = FRACUNIT/2,
	height = 1*FRACUNIT,
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

	local mo = player.mo

	local ray = P_SpawnMobjFromMobj(mo, 0, 0, mo.height - (8*mo.scale), MT_DOOM_USERAYCAST)
	if not (ray and ray.valid) then return end

	ray.scale = mo.scale
	ray.target = mo
	ray.dist = MAX_USE_DIST
	ray.doom = $ or {}
	ray.doom.damage = 0

	ray.angle = mo.angle

	local speed = FixedMul(ray.info.speed, ray.scale)
	ray.momx = FixedMul(cos(ray.angle), speed)
	ray.momy = FixedMul(sin(ray.angle), speed)
	ray.momz = 0

	DOOM_GenericRaycast(ray, {
		maxdist = MAX_USE_DIST,

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
		print("Potential invalid line special '" .. tostring(lineSpecial) .. "'")
		S_StartSound(ray.target, sfx_noway)
		P_KillMobj(ray)
		return true
	end

	-- Strife port needs this for the "message" thinker
	-- Should be otherwise harmless to include
	whatIs.triggerer = ray.target

	if whatIs.activationType == "switch" then
		if whatIs.type == "exit" then
			if G_RingSlingerGametype() then
				if not doom.cvars.dmExit.value then
					DOOM_DamageMobj(ray.target, ray.target, ray.target, (FRACUNIT/2)-1)
                    doom.doObituary(ray.target, ray.target, ray.target, doom.damage.exit)
					return true
				end
			end
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
			-- Exit-specific shit
			willExit = whatIs.type == "exit",
			exitSecret = whatIs.secret,
		}

		doom.addThinker(usedLine, switchThinker)
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
    local interacted = true -- we hit a line at least
    local activated = false

    local lineSpecial = doom.linespecials[usedLine]
    if not lineSpecial then
        if not (usedLine.flags & ML_TWOSIDED)
        or usedLine.frontsector.ceilingheight <= usedLine.backsector.floorheight then
            -- Blocked by geometry (interaction, but no interactable)
            if not silent then
                S_StartSound(ray.target, sfx_noway)
            end
            P_KillMobj(ray)
            return interacted, activated
        end
    end

    local whatIs = deepcopy(doom.lineActions[lineSpecial])

    if not whatIs then
        -- Line had a special, but it isn't interactable
        if lineSpecial then
            print("Invalid line special '" .. tostring(lineSpecial) .. "'!")
            if not silent then
                S_StartSound(ray.target, sfx_noway)
            end
            P_KillMobj(ray)
        end
        return false, false
    end

    -- Correct interactable, wrong activation type
    if whatIs.activationType != useType then
        return false, false
    end

    -- From this point on, activation WILL happen
    activated = true

    local targSide = usedLine.sidenum[0]
    if sides[targSide] then
        local sector = sides[targSide].sector
        whatIs.newfloorpic = sector.floorpic
        whatIs.newceilpic  = sector.ceilpic
        whatIs.newSectorSpecial = sector.special
    end

    -- Probably kill the player
    if whatIs.type == "exit" then
        if G_RingSlingerGametype() then
            if not doom.cvars.dmExit.value then
                DOOM_DamageMobj(ray.target, ray.target, ray.target, (FRACUNIT/2)-1)
                doom.doObituary(ray.target, ray.target, ray.target, doom.damage and doom.damage.exit)
                return interacted, activated
            end
		elseif whatIs.resetInventory then
			for player in players.iterate() do
				local funcs = P_GetMethodsForSkin(player)
				if not funcs.throwOutSaveState then player.doom.laststate = {} end
				funcs.throwOutSaveState(player)
			end
        end
    end

    -- Build thinker
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
		-- Exit-specific shit
        willExit = whatIs.type == "exit",
        exitSecret = whatIs.secret,
    }

    doom.addThinker(usedLine, switchThinker)

    if not dontkill then
        P_KillMobj(ray)
    end

    return interacted, activated
end)

addHook("MobjLineCollide", function(ray, usedLine)
    if not (ray and ray.valid) then return end
	if DOOM_UseRaycastInteractionChecks(ray, usedLine, "switch") then return true else return end
end, MT_DOOM_USERAYCAST)

addHook("MobjLineCollide", function(ray, usedLine)
    if not (ray and ray.valid) then return end
    -- I'm like 99% sure the gunshot use type doesn't cancel the "raycast" if it ever executes a line action
	if DOOM_UseRaycastInteractionChecks(ray, usedLine, "gunshot", true, true) then return true else return end
end, MT_DOOM_BULLETRAYCAST)

local function MaybeHitFloor_Simple(bullet)
    local shooter = bullet.shooter
    if not (shooter and shooter.valid) then return end

	local ha = bullet.doom.missaction
	if ha then
		ha.call(shooter, ha.var1, ha.var2)
	end

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

	local ha = bullet.doom.missaction
	if ha then
		ha.call(shooter, ha.var1, ha.var2)
	end

    if target then
        if not (target.z + target.height >= bullet.z and target.z <= bullet.z + bullet.height) then return end
    end

	P_SpawnMobjFromMobj(bullet, 0, 0, 0, MT_DOOM_BULLETPUFF)
    bullet.state = S_NULL
end

local function P_SpawnBlood(x, y, z, damage)
	local th
	z = $ + (DOOM_Random()-DOOM_Random()) << 10
	th = P_SpawnMobj(x, y, z, MT_DOOM_BLOOD)
	th.momz = FRACUNIT*2
	th.tics = $ - (DOOM_Random() - 3)

	if th.tics < 1 then
		th.tics = 1
	end

	if damage <= 12 and damage >= 9 then
		th.state = S_DOOM_BPUFF_BLOOD2
	elseif damage < 9 then
		th.state = S_DOOM_BPUFF_BLOOD3
	end
end

local function P_SpawnPuff(x, y, z, attackrange)
	local th

	z = $ + (DOOM_Random()-DOOM_Random()) << 10

	th = P_SpawnMobj(x, y, z, MT_DOOM_BULLETPUFF)
	th.momz = FRACUNIT
	th.tics = $ - (DOOM_Random() - 3)

	if th.tics < 1 then
		th.tics = 1
	end

	if attackrange == MELEERANGE then
		th.state = S_DOOM_BPUFF_PUFF2
	end
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

	local ha = tmthing.doom.hitaction
	if ha then
		ha.call(tmthing.target, ha.var1, ha.var2)
	end

	if tmthing.doom.shooteranglesnapbehavior then
		local snapb = tmthing.doom.shooteranglesnapbehavior
		local actor = tmthing.target
		local linetarget = thing
		local angle
		if snapb == "chainsaw" then
			// turn to face target
			angle = R_PointToAngle2(actor.x, actor.y, linetarget.x, linetarget.y)
			if angle - actor.angle > ANGLE_180 then
				if angle - actor.angle < ANGLE_90 / 20 then
					actor.angle = angle + ANGLE_90/21
				else
					actor.angle = $ - ANGLE_90/20
				end
			else
				if angle - actor.angle > ANGLE_90/20 then
					actor.angle = angle - ANGLE_90/21
				else
					actor.angle = $ + ANGLE_90/20
				end
			end
		elseif snapb == "fists" then
			// turn to face target
			actor.angle = R_PointToAngle2(actor.x, actor.y, linetarget.x, linetarget.y)
			S_StartSound(actor, sfx_punch)
		end
	end

    local damage = tmthing.doom.damage or 10
    DOOM_DamageMobj(thing, tmthing, tmthing and tmthing.target or tmthing, damage)
    -- tmthing.state = S_HL1_HIT or S_NULL
	if (thing.doom.flags & DF_NOBLOOD) then
		P_SpawnPuff(tmthing.x, tmthing.y, tmthing.z, tmthing.doom.dist)
	else
		P_SpawnBlood(tmthing.x, tmthing.y, tmthing.z, tmthing.doom.damage)
	end
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
	if horizspread == nil then
		horizspread = 0
	end

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

    local offset = shooter.height >> 1
    local zoff = 8*FRACUNIT
	local curwepdef
	if player then
		curwepdef = DOOM_GetWeaponDef(player)
	end

    for i = 1, pellets do
        -- save original state
        local ogangle = shooter.angle
        local ogaiming = player and player.aiming or 0

        -- spread
        local hspr
        local vspr

		if type(horizspread) == "boolean" then
			if not horizspread then
				local difference = (DOOM_Random()-DOOM_Random()) << 18
				shooter.angle = $ + difference
				hspr = AngleFixed(difference)
			else
				hspr = 0
			end
		else
			hspr = FixedMul(P_RandomFixed() - FRACUNIT/2, horizspread*2)
			shooter.angle = $ + FixedAngle(hspr)
		end
        if player then
			if type(vertspread) == "boolean" then
				if not vertspread then
					local difference = (DOOM_Random()-DOOM_Random()) << 18
					player.aiming = $ + difference
					vspr = AngleFixed(difference)
				else
					vspr = 0
				end
			else
				vspr = FixedMul(P_RandomFixed() - FRACUNIT/2, vertspread*2)
				player.aiming = $ + FixedAngle(vspr)
			end
        end

        local angle = shooter.angle
        local pitch = player and player.aiming or 0

        if not player then
            local dest = source.target
            local shootz  = source.z + (source.height >> 1) + 8*FRACUNIT
            local targetz = dest.z + (dest.height >> 1)

            local dist_calc = P_AproxDistance(dest.x - source.x, dest.y - source.y)

            local dz = targetz - shootz
            local slope = FixedDiv(dz, dist_calc)

            -- Doom autoaim limits
            local topslope    =  100*FRACUNIT/160
            local bottomslope = -100*FRACUNIT/160

            slope = Clamp(slope, bottomslope, topslope)

            pitch = slope  -- approximation
        end

        local spawnz = FixedMul(shooter.height - offset, shooter.scale) + zoff

        if (shooter.eflags & MFE_VERTICALFLIP) then
            spawnz = FixedMul(offset, shooter.scale) - zoff
        end

        local bullet = P_SpawnMobjFromMobj(shooter, 0, 0, spawnz, shootmobj or MT_DOOM_BULLETRAYCAST)

        -- restore state
        shooter.angle = $ - FixedAngle(hspr or 0)
        if player and vspr then player.aiming = $ - FixedAngle(vspr) end

        if bullet and bullet.valid then
            bullet.flags2 = shootflags2 or 0
            local speed = mobjinfo[bullet.type].speed
            bullet.momx = FixedMul(FixedMul(speed, cos(angle)), cos(pitch))
            bullet.momy = FixedMul(FixedMul(speed, sin(angle)), cos(pitch))
            bullet.momz = FixedMul(speed, sin(pitch))
            bullet.angle = angle
			S_StartSound(bullet, bullet.info.seesound)

            local divisor = incs or min
            bullet.doom = $ or {}
            bullet.doom.damage = min != max and ((DOOM_Random() % (max / divisor) + 1) * divisor) or max
			bullet.doom.preferselfdamage = true
			bullet.doom.hitsound = hitsound

			if curwepdef then
				bullet.doom.shooteranglesnapbehavior = curwepdef.anglesnapbehavior
				bullet.doom.hitaction = curwepdef.hitaction
				bullet.doom.missaction = curwepdef.missaction
			end

            bullet.scale   = shooter.scale
            bullet.target  = shooter
            bullet.shooter = shooter
            bullet.dist    = dist
			bullet.fuse    = shootfuse or 0

			if firefunc then
				if type(firefunc) != "function" then error("firefunc field should be of type 'function'!") end
				firefunc(shooter and shooter.player or shooter, bullet)
			end

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