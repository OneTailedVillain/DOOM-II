-- Utility function for safe slot freeing
local function SafeFreeSlot(...)
	for _, slot in ipairs({...}) do
		if not rawget(_G, slot) then
			freeslot(slot) -- Ensure we don't accidentally overlap existing freeslots
		end
	end
end

SafeFreeSlot("MT_FREEMDEATHCAM", "MT_FREEMCORPSE", "S_PLAY_FREEDYING1", "S_PLAY_FREEDEAD", "SPR2_DYIN", "sfx_noway", "sfx_oof", "sfx_pldeth", "sfx_pdiehi")

states[S_PLAY_FREEDYING1] = {
	sprite = SPR_PLAY,
	frame = FF_ANIMATE|SPR2_DYIN,
	tics = 60,
	var1 = 6,
	var2 = 10,
	nextstate = S_PLAY_FREEDEAD
}

states[S_PLAY_FREEDEAD] = {
	sprite = SPR_PLAY,
	frame = SPR2_DEAD,
	tics = -1,
	nextstate = S_PLAY_FREEDEAD
}

mobjinfo[MT_FREEMDEATHCAM] = {
	spawnstate = S_INVISIBLE,
	spawnhealth = 100,
	deathstate = S_NULL,
	speed = 0,
	radius = 2*FRACUNIT,
	height = 2*FRACUNIT,
	dispoffset = 4,
	flags = MF_SCENERY,
}

mobjinfo[MT_FREEMCORPSE] = {
    spawnstate = S_PLAY_FREEDYING1,
    spawnhealth = 100,
    deathstate = S_NULL,
    speed = 0,
    radius = 2*FRACUNIT,
    height = 2*FRACUNIT,
    dispoffset = 4,
}

-- Fix some other chuckler's code
if not customdeaths then
	rawset(_G, "customdeaths", {})
end

customdeaths["johndoom"] = true

-- Hook for handling player death
addHook("MobjDeath", function(mobj, inflictor, source, damageType)
	if mobj.skin ~= "johndoom" then return end

	local player = mobj.player

	if mobj.doom.health > -50 then
		P_PlayDeathSound(mobj)
	elseif mobj.doom.health > -100 then
		S_StartSound(mobj, sfx_spndsh)
	else
		S_StartSound(mobj, sfx_zoom)
	end

	if (gametyperules & GTR_DEATHPENALTY) then
		if player.score >= 50 then
			P_AddPlayerScore(mobj.player, -50)
		else
			player.score = 0
		end
	end

	mobj.player.awayviewtics = TICRATE*2
	mobj.player.awayviewmobj = P_SpawnMobjFromMobj(mobj,
	0,
	0,
	0,
	MT_FREEMDEATHCAM)
	mobj.player.awayviewaiming = mobj.player.aiming
	local killcam = mobj.player.awayviewmobj
	killcam.radius = mobj.radius
	killcam.height = mobj.height - 15*FRACUNIT
	killcam.momx = mobj.momx
	killcam.momy = mobj.momy
	killcam.momz = mobj.momz
	killcam.scale = mobj.scale
	killcam.angle = mobj.angle
	killcam.parent = mobj
	mobj.child = killcam
	mobj.player.killcam = killcam
	mobj.player.doom.deadtimer = 0
	mobj.doom.health = 0

		if not GT_SAXAMM or gametype != GT_SAXAMM then
			mobj.corpse = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_FREEMCORPSE)
			local corpse = mobj.corpse
			corpse.radius = mobj.radius
			corpse.height = mobj.radius*2
			corpse.color = mobj.color
			corpse.angle = mobj.angle
			-- corpse.z = $ - (mobj.height - 15 * FRACUNIT)
			corpse.skin = "johndoom"
			corpse.state = S_PLAY_FREEDYING1
			corpse.momz = mobj.momz
			corpse.fuse = 60*TICRATE
		end

	return true
end, MT_PLAYER)

local function FixedSquare(a)
	return FixedMul(a, a)
end

addHook("MobjThinker", function(mobj)
	local curfric = (mobj.floorrover and mobj.floorrover.sector and mobj.floorrover.sector.friction) or mobj.subsector.sector.friction
	mobj.friction = FixedMul(curfric, FRACUNIT*46/50)
	if not (mobj.parent and mobj.parent.valid) or (mobj.parent and mobj.parent.player and mobj.parent.player.quittime) then
		P_KillMobj(mobj)
		return
	end
end, MT_FREEMDEATHCAM)

addHook("MobjThinker", function(mobj)
	if not (mobj and mobj.valid) then return end
	if not mobj.fuse then
		P_KillMobj(mobj)
	end
end, MT_FREEMCORPSE)

-- ThinkFrame Hook
addHook("ThinkFrame", function()
	for player in players.iterate do
		if not player.mo then continue end
		if player.mo.skin != "johndoom" then continue end

		-- Only run death-think while actually dead
		if player.playerstate == PST_DEAD then
			local mo = player.mo

			-- keep away view aiming disabled
			player.awayviewaiming = 0

			local corpse = mo.corpse
			if corpse and corpse.valid then
				corpse.fuse = 60 * TICRATE
				-- reposition corpse to follow the awayviewmobj's XY (keeps camera/corpse synced)
				if player.awayviewmobj and player.awayviewmobj.valid then
					P_MoveOrigin(corpse, player.awayviewmobj.x, player.awayviewmobj.y, corpse.z)
				end
			end

			-- Dead timer logic (preserve your original behavior)
			if not (gametyperules & GTR_RESPAWNDELAY) then
				local timer = player.doom.deadtimer or 0
				if timer > 35 then
					player.deadtimer = timer - (107 + TICRATE)
				else
					player.deadtimer = 0
				end

				if (player.cmd.buttons & BT_JUMP) and timer > TICRATE then
					player.deadtimer = 100 * TICRATE
					player.cmd.buttons = 0
				end

				player.doom.deadtimer = timer + 1
			end

			-- compute time for viewheight fall
			local time = (player.doom.deadtimer or player.deadtimer) or 0

			-- emulate "fall to the ground" for the player's viewheight using killcam.height
			local MIN_VIEW = 6 * FRACUNIT
			if player.killcam and player.killcam.valid then
				-- target height: base height minus an amount that grows with time
				local target = (mo.height - 15 * FRACUNIT) - (FRACUNIT * time)
				if target < MIN_VIEW then target = MIN_VIEW end
				player.killcam.height = target
			end

			-- If there's a valid attacker (and it's not the player themselves), rotate the
			-- player's mobj angle a small step each tick toward that attacker (ANG5).
			local attacker = player.attacker
			if attacker and attacker.valid and attacker ~= mo then
				-- R_PointToAngle2 returns an engine angle in the same units as mo.angle
				local badguyangle = R_PointToAngle2(mo.x, mo.y, attacker.x, attacker.y)
				local delta = badguyangle - mo.angle

				-- normalize delta to range (-ANGLE_180, ANGLE_180]
				local ANGLE_360 = ANGLE_180 * 2
				if delta <= -ANGLE_180 then
					delta = delta + ANGLE_360
				elseif delta > ANGLE_180 then
					delta = delta - ANGLE_360
				end

				-- if close enough, snap to attacker; otherwise step by ANG5 each tick
				if math.abs(delta) < ANG5 then
					mo.angle = badguyangle
				elseif delta > 0 then
					mo.angle = mo.angle + ANG5
				else
					mo.angle = mo.angle - ANG5
				end
			end

			-- Ensure the awayview mobj (the camera proxy) mirrors the mo.angle so the player sees it
			if player.awayviewmobj and player.awayviewmobj.valid then
				player.awayviewmobj.angle = mo.angle
			end

			-- keep the away view alive briefly
			player.awayviewtics = TICRATE * 2

		elseif player.playerstate == PST_REBORN then
			-- ensure objects get decoupled if for SOME reason player.mo doesn't refresh
			if player.mo.child and player.mo.child.valid then
				player.mo.child.parent = nil
			end
			player.mo.corpse = nil
		end
	end
end)

COM_AddCommand("kill", function(player, victim)
	if not (player and player.mo)
		return
	end
	-- kill runner as a placeholder
	P_PlayerEmeraldBurst(player, false)
	P_PlayerWeaponAmmoBurst(player)
	P_PlayerFlagBurst(player, false)
	P_KillMobj(player.mo, player.mo, player.mo, DMG_SPECTATOR|DMG_CANHURTSELF)
end)

addHook("PreThinkFrame", function()
	for player in players.iterate do
		if not player.mo then continue end
		if player.mo.skin != "johndoom" then continue end

		if not (player.killcam and player.killcam.valid) then continue end
		player.killcam.z = $ - (player.killcam.height - 8 * player.killcam.scale)
	end
end)

addHook("PostThinkFrame", function()
	for player in players.iterate do
		if not player.mo continue end
		if player.mo.skin != "johndoom" then continue end
		player.bob = 0
		player.viewheight = player.mo.height - 15*FRACUNIT
		player.deltaviewheight = 0
		if not (player.killcam and player.killcam.valid) then continue end
		player.killcam.z = $ + (player.killcam.height - 8 * player.killcam.scale)
	end
end)

addHook("PlayerThink", function(player)
	if player.mo.skin != "johndoom" then return end
	-- player.aiming = 0
end)

addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
	local player = target.player
	local support = P_GetSupportsForSkin(player)
	if support.customDamage then return end

	DOOM_DamageMobj(target, inflictor, source, damage, damagetype)
	return true
end, MT_PLAYER)

addHook("ShouldDamage", function(mobj, inf, src, dmg, dt)
    if dt == DMG_CRUSHED then return false end
end)