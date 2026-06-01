freeslot("SPR_WRNG")

local function setupWeaponDelay(weapondelayTics, frameChar)
    local states = {
        idle = {
            {frame = frameChar, offset = {240 * FRACUNIT, 165 * FRACUNIT}, scale = FRACUNIT*2, tics = 1, action = A_DoomWeaponReady}
        },
		raise = {
            {frame = frameChar, offset = {240 * FRACUNIT, 165 * FRACUNIT}, scale = FRACUNIT*2, tics = 1, action = A_DoomRaise}
		},
		lower = {
            {frame = frameChar, offset = {240 * FRACUNIT, 165 * FRACUNIT}, scale = FRACUNIT*2, tics = 1, action = A_DoomLower}
		},
        attack = {}
    }

	local iters = weapondelayTics + 1

    for i = 1, iters do
        local progress = FixedDiv(i - 1, iters - 1)

        local frameOffset = ease.outcubic(progress, 185 * FRACUNIT, 165 * FRACUNIT)

        local frameData = {
            frame = frameChar,
            offset = {240 * FRACUNIT, frameOffset},
            scale = FRACUNIT*2,
            tics = 1
        }

        if i == 1 then frameData.action = A_DoomFire end
        if i == iters then frameData.action = A_DoomReFire end

        table.insert(states.attack, frameData)
    end

    return states
end

doom.addWeapon("infinityring", {
    sprite = SPR_WRNG,
    weaponslot = 1,
	user_johnringslingericon = "INFNIND",
    order = -1,
    damage = {25, 25},
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_THROWNINFINITY,
    states = setupWeaponDelay(TICRATE/4, D),
    ammotype = "shells",
})

doom.addWeapon("matchring", {
    sprite = SPR_WRNG,
    weaponslot = 1,
	user_johnringslingericon = "RINGIND",
    order = 0,
    damage = {15, 15},
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_REDRING,
	carouselicon = "SMMATC",
	states = setupWeaponDelay(TICRATE/4, A),
    ammotype = "bullets",
})

doom.addWeapon("automaticring", {
    sprite = SPR_WRNG,
    weaponslot = 2,
	user_johnringslingericon = "AUTOIND",
    order = 2,
    damage = {8, 8},
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_THROWNAUTOMATIC,
	shootflags2 = MF2_AUTOMATIC,
	carouselicon = "SMAUTO",
    states = setupWeaponDelay(2, H),
    ammotype = "bullets",
})

doom.addWeapon("bouncering", {
    sprite = SPR_WRNG,
    weaponslot = 3,
	user_johnringslingericon = "BNCEIND",
    order = 3,
    damage = {17, 17},
	shotcost = 2,
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_THROWNBOUNCE,
	shootflags2 = MF2_BOUNCERING,
	shootfuse = 3*TICRATE,
	carouselicon = "SMBOUN",
    states = setupWeaponDelay(TICRATE/4, F),
    ammotype = "shells",
})

doom.addWeapon("scatterring", {
    sprite = SPR_WRNG,
    weaponslot = 4,
	user_johnringslingericon = "SCATIND",
    order = 2,
    damage = {19, 19},
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_THROWNSCATTER,
	shootflags2 = MF2_SCATTER,
	carouselicon = "SMSCAT",
	firefunc = function(player, bullet)
		local mobj = player.mo
		local oldz = mobj.z
		local shotangle = mobj.angle
		local oldaiming = player.aiming
		local oldangle = mobj.angle
		local offset = mobj.height >> 1
		local zoff = 8*FRACUNIT

		// Center (the original bullet)
		if bullet then
			bullet.doom = $ or {}
			bullet.doom.damage = 19
		end

		// Left
		mobj.angle = shotangle - ANG2
		local spawnz = FixedMul(mobj.height - offset, mobj.scale) + zoff
		if (mobj.eflags & MFE_VERTICALFLIP) then
			spawnz = FixedMul(offset, mobj.scale) - zoff
		end
		local mo = P_SpawnMobjFromMobj(mobj, 0, 0, spawnz, MT_THROWNSCATTER)
		if mo then
			mo.flags2 = MF2_SCATTER
			local speed = mobjinfo[MT_THROWNSCATTER].speed
			local angle = mobj.angle
			local pitch = player.aiming
			mo.momx = FixedMul(FixedMul(speed, cos(angle)), cos(pitch))
			mo.momy = FixedMul(FixedMul(speed, sin(angle)), cos(pitch))
			mo.momz = FixedMul(speed, sin(pitch))
			mo.angle = angle
			mo.doom = $ or {}
			mo.doom.damage = 19
			mo.doom.preferselfdamage = true
			mo.scale = mobj.scale
			mo.target = mobj
			mo.shooter = mobj
			mo.fuse = 0
		end
		mobj.angle = oldangle

		// Right
		mobj.angle = shotangle + ANG2
		spawnz = FixedMul(mobj.height - offset, mobj.scale) + zoff
		if (mobj.eflags & MFE_VERTICALFLIP) then
			spawnz = FixedMul(offset, mobj.scale) - zoff
		end
		mo = P_SpawnMobjFromMobj(mobj, 0, 0, spawnz, MT_THROWNSCATTER)
		if mo then
			mo.flags2 = MF2_SCATTER
			local speed = mobjinfo[MT_THROWNSCATTER].speed
			local angle = mobj.angle
			local pitch = player.aiming
			mo.momx = FixedMul(FixedMul(speed, cos(angle)), cos(pitch))
			mo.momy = FixedMul(FixedMul(speed, sin(angle)), cos(pitch))
			mo.momz = FixedMul(speed, sin(pitch))
			mo.angle = angle
			mo.doom = $ or {}
			mo.doom.damage = 19
			mo.doom.preferselfdamage = true
			mo.scale = mobj.scale
			mo.target = mobj
			mo.shooter = mobj
			mo.fuse = 0
		end
		mobj.angle = oldangle

		// Down
		mobj.z = oldz + FixedMul(12*FRACUNIT, mobj.scale)
		player.aiming = oldaiming + ANG1
		spawnz = FixedMul(mobj.height - offset, mobj.scale) + zoff - FixedMul(12*FRACUNIT, mobj.scale)
		if (mobj.eflags & MFE_VERTICALFLIP) then
			spawnz = FixedMul(offset, mobj.scale) - zoff - FixedMul(12*FRACUNIT, mobj.scale)
		end
		mo = P_SpawnMobjFromMobj(mobj, 0, 0, spawnz, MT_THROWNSCATTER)
		if mo then
			mo.flags2 = MF2_SCATTER
			local speed = mobjinfo[MT_THROWNSCATTER].speed
			local angle = mobj.angle
			local pitch = player.aiming
			mo.momx = FixedMul(FixedMul(speed, cos(angle)), cos(pitch))
			mo.momy = FixedMul(FixedMul(speed, sin(angle)), cos(pitch))
			mo.momz = FixedMul(speed, sin(pitch))
			mo.angle = angle
			mo.doom = $ or {}
			mo.doom.damage = 19
			mo.doom.preferselfdamage = true
			mo.scale = mobj.scale
			mo.target = mobj
			mo.shooter = mobj
			mo.fuse = 0
		end

		// Up
		mobj.z = oldz - FixedMul(24*FRACUNIT, mobj.scale)
		player.aiming = oldaiming - ANG2
		spawnz = FixedMul(mobj.height - offset, mobj.scale) + zoff + FixedMul(24*FRACUNIT, mobj.scale)
		if (mobj.eflags & MFE_VERTICALFLIP) then
			spawnz = FixedMul(offset, mobj.scale) - zoff + FixedMul(24*FRACUNIT, mobj.scale)
		end
		mo = P_SpawnMobjFromMobj(mobj, 0, 0, spawnz, MT_THROWNSCATTER)
		if mo then
			mo.flags2 = MF2_SCATTER
			local speed = mobjinfo[MT_THROWNSCATTER].speed
			local angle = mobj.angle
			local pitch = player.aiming
			mo.momx = FixedMul(FixedMul(speed, cos(angle)), cos(pitch))
			mo.momy = FixedMul(FixedMul(speed, sin(angle)), cos(pitch))
			mo.momz = FixedMul(speed, sin(pitch))
			mo.angle = angle
			mo.doom = $ or {}
			mo.doom.damage = 19
			mo.doom.preferselfdamage = true
			mo.scale = mobj.scale
			mo.target = mobj
			mo.shooter = mobj
			mo.fuse = 0
		end

		// Restore
		player.aiming = oldaiming
		mobj.z = oldz
	end,
    states = setupWeaponDelay(TICRATE*2/3, B),
    ammotype = "shells",
})

doom.addWeapon("grenadering", {
    sprite = SPR_WRNG,
    weaponslot = 5,
	user_johnringslingericon = "GRENIND",
    order = 2,
    damage = {15, 15}, -- Relies on blast damage
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_THROWNGRENADE,
	shootflags2 = MF2_EXPLOSION,
	shootfuse = mobjinfo[MT_THROWNGRENADE].reactiontime,
	carouselicon = "SMGREN",
    states = setupWeaponDelay(TICRATE/3, E),
    ammotype = "rockets",
})

doom.addWeapon("explosionring", {
    sprite = SPR_WRNG,
    weaponslot = 6,
	user_johnringslingericon = "BOMBIND",
    order = 2,
    damage = {4, 4}, -- Relies on blast damage
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_THROWNEXPLOSION,
	shootflags2 = MF2_EXPLOSION,
	carouselicon = "SMEXPL",
    states = setupWeaponDelay(TICRATE*3/2, G),
    ammotype = "rockets",
})

doom.addWeapon("railring", {
    sprite = SPR_WRNG,
    weaponslot = 7,
	user_johnringslingericon = "RAILIND",
    order = 2,
    damage = {250, 250},
	shotcost = 20,
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_REDRING,
	shootflags2 = MF2_RAILRING|MF2_DONTDRAW,
	firefunc = function(player, bullet)
		S_StartSound(player.mo, sfx_rail1)
		if bullet then
			bullet.doom = $ or {}
			bullet.doom.damage = 250
			for i = 0, 255 do
				if i & 1 then
					P_SpawnMobjFromMobj(bullet, 0, 0, 0, MT_SPARK)
				end
				if P_RailThinker(bullet) then
					break
				end
			end

			S_StartSound(bullet, sfx_rail2)
		end
	end,
	carouselicon = "SMRAIL",
    states = setupWeaponDelay(TICRATE*3/2, C),
    ammotype = "cells",
})

local function RandomFixedRange(a, b)
	local diff = b - a
	local result = FixedMul(diff, P_RandomFixed()) + a
	return result
end

local function Valid(userdata)
	return userdata and userdata.valid
end

local function Explode(mo, bombDist, bombDamage, fullDist)
	if not Valid(mo) then return end
	if bombDist == nil then bombDist = 128*FRACUNIT end
	if not bombDamage then bombDamage = 90 end
	if fullDist == nil then fullDist = 3*bombDist/8 end

	local moScale = mo.scale

	bombDist = FixedMul($, moScale)
	fullDist = min(FixedMul($, moScale), bombDist) -- Make sure fullDist doesn't go above bombDist
	local checkDist = bombDist -- Make sure thrustDist always works

	mo.flags2 = $|MF2_DEBRIS -- The Explosion Ring does this in vanilla, so why not do it here too? (Makes it so Stickybombs can blow each other up)
	mo.rsrProjectile = nil
	mo.rsrRealDamage = true
	mo.rsrDontThrust = true -- The damage thrust code conflicts with the explosion thrust code, so disable it
	mo.doom.preferselfdamage = false

	searchBlockmap("objects", function(bomb, enemy)
		if not (Valid(bomb) and Valid(enemy)) then return end
		if enemy == bomb then return end -- Don't damage yourself!
		if enemy.health <= 0 then return end -- Don't damage enemies with 0 health
		if not (enemy.flags & MF_SHOOTABLE) then return end -- Don't damage non-shootable objects
		--if Valid(bomb.target) and not bomb.target == enemy and RSR.PlayersAreTeammates(bomb.target.player, enemy.player) then return end -- Don't apply knockback to teammates

		-- Make an exception for MT_BLASTEXECUTOR so the breakable wall in Jade Valley works
		--if not (RSR.MOBJ_INFO[enemy.type] and RSR.MOBJ_INFO[enemy.type].nosplashsightcheck) and not P_CheckSight(bomb, enemy) then return end
		local source = bomb.target
		local damagetype = 0
		-- if enemy == bomb.target then source = nil end
		if enemy == bomb.target then damagetype = $|DMG_CANHURTSELF end

		local distXY = FixedHypot(enemy.x - bomb.x, enemy.y - bomb.y)
		local distZ = (enemy.z + enemy.height/2) - (bomb.z + bomb.height/2)
		local dist = max(0, FixedHypot(distXY, distZ)) -- Consider subtracting enemy.radius to make larger enemies easier to kill
-- 		if dist < 0 then dist = 0 end

		-- Don't destroy monitors with splash damage
		if not (enemy.info.flags & MF_MONITOR) then
			if dist <= bombDist then
				local damage = bombDamage * min(FixedDiv(bombDist - dist, max(bombDist - fullDist, mo.scale)), FRACUNIT) / FRACUNIT
				if damage > 0 then P_DamageMobj(enemy, bomb, source, damage, damagetype) end
			end
		end
	end, mo, mo.x - checkDist, mo.x + checkDist, mo.y - checkDist, mo.y + checkDist)

	mo.rsrRealDamage = nil
end

--- Makes the actor explode like an Explosion Ring or Grenade Ring, but for RSR.
---@param mo mobj_t
---@param var1 integer Determines the explosion FX type. 0 is for the normal paraloop-based explosion; 1 is for the low-CPU paraloop-based explosion; 2 is for the Mass Scrambler's bomblets.
local function A_RSRRingExplode(mo, var1, var2)
	if not Valid(mo) then return end
	S_StopSound(mo) -- Attempt to stop all sounds (travel and alert sounds included)

	A_DoomExplode(mo, 128*FRACUNIT, 128, 128*FRACUNIT)

	local sparkleState = S_NULL
	local iterCount = 0
	local iterAngle = ANGLE_45

	if var1 == 1 then
		iterCount = 7
		iterAngle = ANGLE_45
	else
		iterCount = 15
		iterAngle = ANGLE_22h
	end
	if var1 == 2 then
		for i = 0, 6 do
			local spark = P_SpawnMobj(mo.x, mo.y, mo.z, MT_NIGHTSPARKLE)
			if Valid(spark) then
				if sparkleState then spark.state = sparkleState end -- Don't set the state to S_NULL!
				spark.scale = 11*FRACUNIT/5
				-- Randomize the spark's momentum
				spark.momx = RandomFixedRange(3*spark.scale/4, 4*spark.scale/3)
				spark.momy = RandomFixedRange(3*spark.scale/4, 4*spark.scale/3)
				spark.momz = RandomFixedRange(3*spark.scale/4, 4*spark.scale/3)
				if P_RandomChance(FRACUNIT/2) then spark.momx = -$ end
				if P_RandomChance(FRACUNIT/2) then spark.momy = -$ end
				if P_RandomChance(FRACUNIT/2) then spark.momz = -$ end

				-- Make the spark shrink to scale 0 in roughly 3 seconds
				spark.scalespeed = FRACUNIT/18
				spark.destscale = 0
				spark.tics = 105
			end
		end
	else
		for d = 0, iterCount do
			P_SpawnParaloop(
				mo.x,
				mo.y,
				mo.z + mo.height/2,
				FixedMul(mo.info.painchance, mo.scale),
				iterCount + 1,
				MT_NIGHTSPARKLE,
				d * iterAngle,
				sparkleState,
				true
			)
		end
	end
	S_StartSound(mo, sfx_prloop)
end
states[S_RINGEXPLODE].action = A_RSRRingExplode
states[S_RINGEXPLODE].var1 = 0

freeslot("SPR_THOM", "MT_DOOM_THROWNHOMING", "sfx_homifr", "sfx_homitg", "sfx_homiab", "sfx_homiwn", "sfx_homict")

local plasmastates = {
    active = {
        {sprite = SPR_THOM, frame = A|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = B|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = C|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = D|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = E|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = F|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = G|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = H|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = I|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = J|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = K|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = L|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = M|FF_FULLBRIGHT, tics = 2},
        {sprite = SPR_THOM, frame = N|FF_FULLBRIGHT, tics = 2, next = "active"},
    },
}

local mtSt = FreeDoomStates("HomingRing", plasmastates)

mobjinfo[MT_DOOM_THROWNHOMING] = {
	spawnstate = mtSt.active[1],
	seesound = sfx_homifr,
	deathstate = mobjinfo[MT_THROWNSCATTER].deathstate,
	deathsound = sfx_itemup,
	speed = 90*FRACUNIT,
	radius = 19*FRACUNIT,
	height = 19*FRACUNIT,
	activesound = sfx_homiab,
	flags = MF_MISSILE|MF_NOGRAVITY
}

--- Check if the enemy is within the missile's angle and pitch range.
---@param missile mobj_t
---@param enemy mobj_t
local function HomingRingAngleCheck(missile, enemy)
	if not (Valid(missile) and Valid(enemy)) then return end

	-- Don't target enemies outside the missile's angle search!
	local angleTo = R_PointToAngle2(missile.x, missile.y, enemy.x, enemy.y)
	local distTo = R_PointToDist2(missile.x, missile.y, enemy.x, enemy.y)
	local pitchTo = R_PointToDist2(0, missile.z + missile.height/2, distTo, enemy.z + enemy.height/2)
	local angleDelta = AngleFixed(angleTo - missile.angle)
	local pitchDelta = AngleFixed(pitchTo - missile.pitch)

	if angleDelta > 180*FRACUNIT then angleDelta = $ - 360*FRACUNIT end
	if pitchDelta > 180*FRACUNIT then pitchDelta = $ - 360*FRACUNIT end

	if abs(angleDelta) > 30*FRACUNIT then return end
	if abs(pitchDelta) > 30*FRACUNIT then return end

	return true
end

local RSR = {}

RSR.ProjectileGhostTimer = function(mo, smokeType)
	if not Valid(mo) then return end
	if not ((mo.flags & MF_MISSILE) and mo.health > 0) then return end

	mo.rsrGhostTimer = $-1
	if mo.rsrGhostTimer < 1 then
		if smokeType then
			P_SpawnMobjFromMobj(
				mo,
				RSR.RandomFixedRange(-mo.info.radius, mo.info.radius),
				RSR.RandomFixedRange(-mo.info.radius, mo.info.radius),
				RSR.RandomFixedRange(0, mo.info.height),
				smokeType
			)
		else
			P_SpawnGhostMobj(mo)
		end
		mo.rsrGhostTimer = 4
	end
end

--- Makes the projectile emit a sound as it travels.
---@param mo mobj_t The projectile.
---@param repeatTime tic_t|nil Tics between repeats of the sound effect. Default is 6 if there is no traveltimer defined in MOBJ_INFO.
---@param sound soundnum_t|nil The sound to play as the projectile travels. Default is sfx_alarm if there is not travelsound defined in .
RSR.ProjectileTravelSound = function(mo, repeatTime, sound)
	if not Valid(mo) then return end
	/*
	if RSR.MOBJ_INFO[mo.type] then
		if not sound and RSR.MOBJ_INFO[mo.type].travelsound then sound = RSR.MOBJ_INFO[mo.type].travelsound end
		if not repeatTime and RSR.MOBJ_INFO[mo.type].traveltimer then repeatTime = RSR.MOBJ_INFO[mo.type].traveltimer end
	end
	*/
	if not sound then sound = sfx_homiab end
	if not repeatTime then repeatTime = 6 end

	mo.rsrSoundTimer = $-1
	if mo.rsrSoundTimer < 1 then
		S_StartSound(mo, sound)
		mo.rsrSoundTimer = repeatTime
	end
end

--- Makes the projectile emit a sound as it follows a player.
---@param mo mobj_t The projectile.
---@param player player_t Player that the projectile is targetting.
---@param repeatTime tic_t|nil Tics between repeats of the sound effect. Default is 6 if there is no alerttimer defined in MOBJ_INFO.
---@param sound soundnum_t|nil The sound to play as the projectile travels. Default is sfx_alarm if there is no alertsound defined in MOBJ_INFO.
RSR.ProjectileAlertSound = function(mo, player, repeatTime, sound)
	if not (Valid(mo) and Valid(player)) then return end
	/*
	if RSR.MOBJ_INFO[mo.type] then
		if not sound and RSR.MOBJ_INFO[mo.type].alertsound then sound = RSR.MOBJ_INFO[mo.type].alertsound end
		if not repeatTime and RSR.MOBJ_INFO[mo.type].alerttimer then repeatTime = RSR.MOBJ_INFO[mo.type].alerttimer end
	end
	*/
	if not sound then sound = sfx_homict end
	if not repeatTime then repeatTime = 35 end

	mo.rsrAlertTimer = $-1
	if mo.rsrAlertTimer < 1 then
		S_StartSound(mo, sound, player)
		mo.rsrAlertTimer = repeatTime
	end
end

--- Returns true if the players given are teammates.
---@param player player_t
---@param player2 player_t
RSR.PlayersAreTeammates = function(player, player2)
	if not (Valid(player) and Valid(player2)) then return end

	-- If the gametype is a co-op gametype, they are teammates
	if (gametyperules & GTR_FRIENDLY) then return true end
	-- If the gametype uses teams and both players have an equal ctfteam value, they are teammates
	if (gametyperules & GTR_TEAMS) and player.ctfteam == player2.ctfteam then return true end
	-- If the gametype is Tag (or H&S) and both players are IT (or not IT), they are teammates
	if G_TagGametype() and (player.pflags & PF_TAGIT) == (player2.pflags & PF_TAGIT) then return true end

	-- Otherwise, they are NOT teammates
	return false
end

--- Returns a random fixed-point number between a and b.
---@param a fixed_t|integer
---@param b fixed_t|integer
RSR.RandomFixedRange = function(a, b)
	local diff = b - a
	local result = FixedMul(diff, P_RandomFixed()) + a
	return result
end

--- Returns a new angle inbetween angle and destAngle using maxTurn. Based off of Snap the Sentinel v3.1's code.
---@param angle angle_t Initial angle (Default is 0).
---@param destAngle angle_t Destination angle (Default is 0).
---@param maxTurn angle_t|fixed_t|nil Maximum turning angle (Default is ANGLE_22h).
RSR.AngleTowardsAngle = function(angle, destAngle, maxTurn)
	angle = $ or 0
	destAngle = $ or 0
	if maxTurn == nil then maxTurn = ANGLE_22h end
	maxTurn = AngleFixed($)
	if maxTurn > 180*FRACUNIT then
		maxTurn = $ - 360*FRACUNIT
	end

	local delta = AngleFixed(angle - destAngle)
	if delta > 180*FRACUNIT then
		delta = $ - 360*FRACUNIT
	end

	if maxTurn < abs(delta) then
		if delta > 0 then
			angle = $ - FixedAngle(maxTurn)
		else
			angle = $ + FixedAngle(maxTurn)
		end
	else
		angle = destAngle
	end

	return angle
end

--- MobjThinker hook code for the Homing Ring.
---@param mo mobj_t
---@param radius fixed_t|nil Search radius for the Homing Ring. Default is 640.
---@param noPlayerSpeed boolean|nil If true, always use the projectile's speed instead of the targeted player's normalspeed.
local function HomingRingThinker(mo, radius, noPlayerSpeed)
	if not Valid(mo) then return end
	if not (mo.flags & MF_MISSILE) then return end

	-- Produce smoke and sizzle if the homing ring is locked onto a target
	if noPlayerSpeed then -- Make the Router RPB produce smoke
		RSR.ProjectileGhostTimer(mo, MT_SMOKE)
	end
	if not Valid(mo.tracer) then
		RSR.ProjectileGhostTimer(mo)
		if mo.rsrLockOnSound then mo.rsrLockOnSound = nil end
	else
		if not noPlayerSpeed then RSR.ProjectileTravelSound(mo) end -- Regular travelling sound
		RSR.ProjectileAlertSound(mo, mo.tracer.player) -- Player alert sound
		RSR.ProjectileGhostTimer(mo, MT_SONIC3KBOSSEXPLODE)
	end

	if Valid(mo.tracer) and Valid(mo.target) and RSR.PlayersAreTeammates(mo.target.player, mo.tracer.player) then mo.tracer = nil end -- Stop targeting your tracer if you're on the same team now (can happen in LaserTag when a hider with active heat-seeking weapons is killed)
	if not (Valid(mo.tracer) and mo.tracer.health > 0) then
		if radius == nil then radius = 640*FRACUNIT end
		radius = FixedMul($, mo.scale)
		local xShift = FixedMul(radius/2, cos(mo.angle))
		local yShift = FixedMul(radius/2, sin(mo.angle))
		local x1 = mo.x + xShift - radius
		local x2 = mo.x + xShift + radius
		local y1 = mo.y + yShift - radius
		local y2 = mo.y + yShift + radius

		local bestDist = 2*radius
		local bestTracer = nil
		local bestDistEnemy = 2*radius
		local bestTracerEnemy = nil

		searchBlockmap("objects", function(missile, enemy)
			if not (Valid(missile) and Valid(enemy) and enemy.health > 0) then return end
			if missile.target == enemy then return end -- Don't target the projectile's source
			if not (enemy.flags & MF_SHOOTABLE) then return end
			--if RSR.MOBJ_INFO[enemy.type] and RSR.MOBJ_INFO[enemy.type].nothomable then return end
-- 			if not Valid(enemy.player) then return end -- Only target players!

			if not P_CheckSight(missile, enemy) then return end -- Don't target enemies outside the missile's view!
			-- Don't target teammates
			if Valid(missile.target) and Valid(missile.target.player) and Valid(enemy.player) then
				if RSR.PlayersAreTeammates(missile.target.player, enemy.player) or (gametyperules & GTR_FRIENDLY) then return end
				if enemy.player.spectator and not RSR.CV_Ghostbusters.value then return end -- Don't target spectators if rsr_ghostbusters is false
			end

			-- Ignore monitors unless they're Eggman monitors (for the lulz)
			if (enemy.flags & MF_MONITOR) and not (enemy.type == MT_EGGMAN_BOX or enemy.type == MT_EGGMAN_GOLDBOX) then return end

			-- Don't target enemies outside the missile's distance search!
			local dist = FixedHypot(FixedHypot(enemy.x - missile.x, enemy.y - missile.y), enemy.z - missile.z)
			if dist <= bestDist and HomingRingAngleCheck(missile, enemy) then
				bestDist = dist
				bestTracer = enemy
			end

			if ((enemy.flags & (MF_ENEMY|MF_BOSS)) or Valid(enemy.player))
			and dist <= bestDistEnemy and HomingRingAngleCheck(missile, enemy) then
				bestDistEnemy = dist
				bestTracerEnemy = enemy
			end
		end, mo, x1, x2, y1, y2)
		-- Prioritize enemies and non-teammate players over other shootables
		if Valid(bestTracerEnemy) then
			mo.tracer = bestTracerEnemy
			-- Don't need to check for mo.tracer here since bestTracerEnemy has already been checked
			S_StartSound(mo, sfx_homitg)
			return
		end
		mo.tracer = bestTracer
		if Valid(mo.tracer) then S_StartSound(mo, sfx_homitg) end
		return
	end

	local player = mo.tracer.player

	local angleTurn = ANGLE_22h
	if Valid(player) then
		-- Alert the player that they're being targeted by a homing ring
		if not mo.rsrLockOnSound then
			S_StartSound(mo.tracer, sfx_homiwn, player)
			mo.rsrLockOnSound = true
		end
		if not noPlayerSpeed then RSR.ProjectileAlertSound(mo, mo.tracer.player) end -- Router RPB alert sound
		angleTurn = FixedAngle(4*FRACUNIT)
	end
	local angleTo = R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y)
	local distTo = R_PointToDist2(mo.x, mo.y, mo.tracer.x, mo.tracer.y)
	local pitchTo = R_PointToAngle2(0, mo.z + mo.height/2, distTo, mo.tracer.z + mo.tracer.height/2)

	mo.angle = RSR.AngleTowardsAngle($, angleTo, angleTurn)
	mo.pitch = RSR.AngleTowardsAngle($, pitchTo, angleTurn)

	local curSpeed = FixedHypot(FixedHypot(mo.momx, mo.momy), mo.momz)
	if not noPlayerSpeed and Valid(player) then -- Try to catch up with players, similar to the Deton
		curSpeed = player.normalspeed
		-- TODO: player.speed might cause problems
		if player.speed > player.normalspeed then curSpeed = FixedDiv(player.speed, mo.tracer.scale) end -- Go faster if the player is going faster than their normalspeed
		curSpeed = FixedMul(3*$/4, mo.tracer.scale)
	end
	if noPlayerSpeed then
		RSR.ProjectileTravelSound(mo) -- Router RPB travelling sound
		RSR.ProximityDetonate(mo, 192*FRACUNIT, function(missile)
			if Valid(missile.tracer) and Valid(missile.tracer.player) then
				S_StopSoundByID(missile, sfx_hoatct)
			end
			P_ExplodeMissile(missile)
		end)
		if not (mo.flags & MF_MISSILE) then return end -- Don't move further if the RPB has exploded
	end

	P_InstaThrust(mo, mo.angle, FixedMul(cos(mo.pitch), curSpeed))
	mo.momz = FixedMul(sin(mo.pitch), curSpeed)
end

addHook("MobjSpawn", function(mo)
	if not Valid(mo) then return end
	mo.shadowscale = 2*FRACUNIT/3
	mo.rsrProjectile = true
	mo.rsrGhostTimer = 4
	mo.rsrSoundTimer = 1
	mo.rsrAlertTimer = 1
	mo.rsrLockOnSound = nil
end, MT_DOOM_THROWNHOMING)

addHook("MobjThinker", HomingRingThinker, MT_DOOM_THROWNHOMING)

doom.addWeapon("homingring", {
    sprite = SPR_WRNG,
    weaponslot = 3,
	user_johnringslingericon = "HOMGIND",
    order = 4,
    damage = {19, 19},
	shotcost = 2,
    noinitfirespread = true,
    pellets = 1,
	shootmobj = MT_DOOM_THROWNHOMING,
	carouselicon = "SMHOME",
    states = setupWeaponDelay(TICRATE/4, I),
    ammotype = "cells",
})

local function finalizeWeaponDelays()
    local weaponsToProcess = {
        "infinityring", "matchring", "rs_brassknuckles", 
        "automaticring", "bouncering", "scatterring", 
        "grenadering", "explosionring", "railring", "homingring"
    }
    
    for _, wepname in ipairs(weaponsToProcess) do
        local weapon = doom.weapons[wepname]
        if weapon then
            local delay = nil

            if weapon.states and weapon.states.attack then
            	delay = 0
        		for _, frame in ipairs(weapon.states.attack) do
            		delay = delay + (frame.tics or 0)
        		end
            end

            if delay and delay > 0 then
                weapon.user_firedelay = delay
            end
        end
    end
end

finalizeWeaponDelays()