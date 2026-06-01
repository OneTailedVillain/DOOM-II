// Palette indices.
// For damage/bonus red-/gold-shifts
local STARTREDPALS = 1
local STARTBONUSPALS = 9
local NUMREDPALS = 8
local NUMBONUSPALS = 4
// Radiation suit, green shift.
local RADIATIONPAL = 13

// N/256*100% probability
//  that the normal face state will change
local ST_FACEPROBABILITY = 96

// Number of status faces.
local ST_NUMPAINFACES = 5
local ST_NUMSTRAIGHTFACES = 3
local ST_NUMTURNFACES = 2
local ST_NUMSPECIALFACES = 3

local ST_FACESTRIDE = (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)

local ST_EVILGRINCOUNT = (2*TICRATE)
local ST_STRAIGHTFACECOUNT = (TICRATE/2)
local ST_TURNCOUNT = (1*TICRATE)
local ST_OUCHCOUNT = (1*TICRATE)
local ST_RAMPAGEDELAY = (2*TICRATE)
local NUMWEAPONS = 9

local ST_MUCHPAIN = 20

local ST_TURNOFFSET = (ST_NUMSTRAIGHTFACES)
local ST_OUCHOFFSET = (ST_TURNOFFSET + ST_NUMTURNFACES)
local ST_EVILGRINOFFSET = (ST_OUCHOFFSET + 1)
local ST_RAMPAGEOFFSET = (ST_EVILGRINOFFSET + 1)
local ST_GODFACE = (ST_NUMPAINFACES*ST_FACESTRIDE)
local ST_DEADFACE = (ST_GODFACE+1)

local function ST_calcPainOffset(plyr)
	local funcs = P_GetMethodsForSkin(plyr)
	local myHealth = funcs.getHealth(plyr) or 0
	local myMaxHealth = funcs.getMaxHealth(plyr) or 0
	local health = min(myHealth, myMaxHealth)
	local healthpct = (health*100)/myMaxHealth
	local lastcalc = ST_FACESTRIDE * (((100 - healthpct) * ST_NUMPAINFACES) / 101)

    return lastcalc
end

//
// This is a not-very-pretty routine which handles
//  the face states and their timing.
// the precedence of expressions is:
//  dead > evil grin > turned head > straight ahead
//
local function ST_updateFaceWidget(plyr)
	-- methods for the player's skin (health is provided here)
	local funcs = P_GetMethodsForSkin(plyr)
	local myHealth = funcs.getHealth(plyr) or 0

	-- shortcut to player's doom subtable; create if missing
	plyr.doom = plyr.doom or {}
	local pd = plyr.doom

	-- init per-player state if absent
	pd.faceindex = pd.faceindex or 0
	pd.facecount = pd.facecount or 0
	pd.oldhealth = pd.oldhealth or myHealth
	pd.oldweapons = pd.oldweapons or {}
	pd.lastattackdown = (pd.lastattackdown == nil) and -1 or pd.lastattackdown
	pd.priority = pd.priority or 0

	-- 10: death check (highest precedence)
	if pd.priority < 10 then
		if myHealth == 0 then
			pd.priority = 9
			pd.faceindex = ST_DEADFACE
			pd.facecount = 1
		end
	end

	-- 9: evil grin on weapon pickup
	if pd.priority < 9 then
		if pd.bonuscount and pd.bonuscount ~= 0 then
			local doevilgrin = false
			for wkey, _ in pairs(doom.weapons) do
				-- ensure weapons table exists
				if pd.oldweapons[wkey] ~= pd.weapons[wkey] then
					doevilgrin = true
					pd.oldweapons[wkey] = pd.weapons[wkey]
				end
			end

			if doevilgrin then
				pd.priority = 8
				pd.facecount = ST_EVILGRINCOUNT
				pd.faceindex = ST_calcPainOffset(plyr) + ST_EVILGRINOFFSET
			end
		end
	end

	-- 8: being attacked by another mobj
	if pd.priority < 8 then
		if pd.damagecount and pd.damagecount ~= 0
		   and pd.attacker
		   and pd.attacker ~= plyr.mo then

			pd.priority = 7

			-- ouchface bug except i'm evil and it's intentional
			if myHealth - pd.oldhealth > ST_MUCHPAIN then
				pd.facecount = ST_TURNCOUNT
				pd.faceindex = ST_calcPainOffset(plyr) + ST_OUCHOFFSET
			else
				local badguyangle = pd.attacker and R_PointToAngle2(
					plyr.mo.x, plyr.mo.y,
					pd.attacker and pd.attacker.x or 0, pd.attacker and pd.attacker.y or 0
				) or 0

				local diffang, turnedRight
				if badguyangle > plyr.mo.angle then
					diffang = badguyangle - plyr.mo.angle
					turnedRight = diffang > ANGLE_180
				else
					diffang = plyr.mo.angle - badguyangle
					turnedRight = diffang <= ANGLE_180
				end

				pd.facecount = ST_TURNCOUNT
				pd.faceindex = ST_calcPainOffset(plyr)

				if diffang < ANGLE_45 then
					-- head-on
					pd.faceindex = pd.faceindex + ST_RAMPAGEOFFSET
				elseif turnedRight then
					-- turn right
					pd.faceindex = pd.faceindex + ST_TURNOFFSET
				else
					-- turn left
					pd.faceindex = pd.faceindex + (ST_TURNOFFSET + 1)
				end
			end
		end
	end

	-- 7 & 6: hurting yourself (damagecount without attacker or same mobj)
	if pd.priority < 7 then
		if pd.damagecount and pd.damagecount ~= 0 then
			if myHealth - pd.oldhealth > ST_MUCHPAIN then
				pd.priority = 7
				pd.facecount = ST_TURNCOUNT
				pd.faceindex = ST_calcPainOffset(plyr) + ST_OUCHOFFSET
			else
				pd.priority = 6
				pd.facecount = ST_TURNCOUNT
				pd.faceindex = ST_calcPainOffset(plyr) + ST_RAMPAGEOFFSET
			end
		end
	end

	-- 6 & 5: rapid firing -> rampage face
	if pd.priority < 6 then
		if pd.attackdown and pd.attackdown ~= 0 then
			if pd.lastattackdown == -1 then
				pd.lastattackdown = ST_RAMPAGEDELAY
			else
				-- decrement and check for zero (equiv to C's --lastattackdown == 0)
				if pd.lastattackdown > 0 then
					pd.lastattackdown = pd.lastattackdown - 1
				end
				if pd.lastattackdown == 0 then
					pd.priority = 5
					pd.faceindex = ST_calcPainOffset(plyr) + ST_RAMPAGEOFFSET
					pd.facecount = 1
					pd.lastattackdown = 1
				end
			end
		else
			pd.lastattackdown = -1
		end
	end

	-- 5 & 4: invulnerability / godface
	if pd.priority < 5 then
		if ((pd.cheats and (pd.cheats & CF_GODMODE) ~= 0) or (pd.powers and pd.powers[pw_invulnerability])) then
			pd.priority = 4
			pd.faceindex = ST_GODFACE
			pd.facecount = 1
		end
	end

	-- when facecount times out, pick a straight/neutral face (left/mid/right)
	if (not pd.facecount) or pd.facecount == 0 then
		local rnd = DOOM_Random()
		pd.faceindex = ST_calcPainOffset(plyr) + (rnd % 3)
		pd.facecount = ST_STRAIGHTFACECOUNT
		pd.priority = 0
	end

	-- decrement the facecount for next tick and store oldhealth for comparisons next frame
	pd.facecount = (pd.facecount or 0) - 1
	pd.oldhealth = myHealth
end

addHook("PlayerThink", function(player)
	if not player.mo then return end
	local funcs = P_GetMethodsForSkin(player)

	if (player.mo.flags & MF_NOTHINK) then return end
	player.doom = $ or {}
	ST_updateFaceWidget(player)

	local hasPInvis = false
	if funcs.hasPowerUp(player, "invisibility") then
		hasPInvis = true
	else
		hasPInvis = (player.doom.powers[pw_invisibility] or 0) > 0
	end

	if hasPInvis then
		player.mo.doom.flags = $ | DF_SHADOW
	else
		player.mo.doom.flags = $ & ~DF_SHADOW
	end
end)

addHook("PlayerThink", function(player)
	player.doom.lastbuttons = $ or 0
	if player.spectator then
		player.realmo.flags = $ | (MF_NOCLIPHEIGHT|MF_NOCLIP|MF_NOCLIPTHING)
		player.realmo.flags2 = $ & ~MF2_OBJECTFLIP
		player.realmo.eflags = $ & ~MFE_VERTICALFLIP
	end

	if not player.mo then return end

	if (player.mo.flags & MF_NOTHINK) then return end

	if (player.cmd.buttons & BT_JUMP) then
		if player.doom.alreadyInteracted then return end
		if doom.issrb2 then
			if P_IsObjectOnGround(player.mo) and player.realmo.skin == "johndoom" then
				S_StartSound(player.mo, sfx_jump)
				player.mo.momz = 6*FRACUNIT
			end
		else
			DOOM_TryUse(player)
		end
		player.doom.alreadyInteracted = true
	else
		player.doom.alreadyInteracted = false
	end

	if (player.cmd.buttons & BT_SPIN) and not (player.doom.lastbuttons & BT_SPIN) and doom.issrb2 then
		DOOM_TryUse(player)
	end
end)

local function DOOM_ApplyStateJump(player, slot, targetState, targetFrame)
    local psp = DOOM_GetPSprite(player, slot)

    -- Allow jumping to arbitrary real states or fakestates
    if targetState == nil then
        targetState = DOOM_GetPSpriteDefaultState(slot)
    end

    psp.state = targetState
    psp.frame = targetFrame or 1

    local wepDef = DOOM_GetWeaponDef(player)
    if not wepDef then
        error("Invalid weapon " .. tostring(player.doom.curwep) .. "!")
    end

    local stateDef, realSlot = DOOM_ResolveStateDef(wepDef, targetState, psp.frame)
	if realSlot then
		-- Real state: collapse into engine state system
		psp.state = realSlot
		psp.frame = nil
	else
		-- Fakestate: keep string + frame
		psp.state = targetState
		psp.frame = targetFrame or 1
	end

	if targetState != S_NULL then
	    if not stateDef then
	        error("Invalid state/frame " .. tostring(targetState) .. " " .. tostring(psp.frame) .. "!")
	    end
	else
		stateDef = {tics = INT32_MAX}
	end

    psp.tics = stateDef.tics or 0

    if stateDef.action then
        stateDef.action(player.mo, stateDef.var1, stateDef.var2, wepDef)
    end
end

local HOLD_STATES = {
    raise = true,
    lower = true,
}

local function DOOM_AdvancePSprite(player, slot, fallbackState)
    local psp = DOOM_GetPSprite(player, slot)
    local wepDef = DOOM_GetWeaponDef(player)
    if not wepDef then return end

    psp.tics = $ - 1
    if psp.tics > 0 then
        return
    end

    local frameDef = DOOM_ResolveStateDef(wepDef, psp.state, psp.frame)
    if not frameDef then
        if HOLD_STATES[psp.state] then
            psp.tics = 1
            if frameDef and frameDef.action then
                frameDef.action(player.mo, frameDef.var1, frameDef.var2, wepDef)
            end
            return
        end

        DOOM_ApplyStateJump(player, slot, fallbackState or DOOM_GetPSpriteDefaultState(slot), 1)
        return
    end

    if frameDef.goto ~= nil then
        DOOM_ApplyStateJump(player, slot, frameDef.goto, frameDef.gotoframe)
        return
    end

    local nextstate = frameDef.nextstate
    if nextstate == nil and type(psp.state) == "number" then
        nextstate = states[psp.state].nextstate
    end

    if nextstate ~= nil then
        DOOM_ApplyStateJump(player, slot, nextstate, frameDef.nextframe)
        return
    end

    local nextFrame = (psp.frame or 1) + 1
    local nextDef = DOOM_ResolveStateDef(wepDef, psp.state, nextFrame)

    if nextDef then
        psp.frame = nextFrame
        psp.tics = nextDef.tics or 0
        if nextDef.action then
            nextDef.action(player.mo, nextDef.var1, nextDef.var2, wepDef)
        end
        return
    end

    if HOLD_STATES[psp.state] then
        psp.tics = 1
        if frameDef.action then
            frameDef.action(player.mo, frameDef.var1, frameDef.var2, wepDef)
        end
        return
    end

    DOOM_ApplyStateJump(player, slot, fallbackState or DOOM_GetPSpriteDefaultState(slot), 1)
end

local function updateWeaponState(player, isFlashState)
    if isFlashState then
        DOOM_AdvancePSprite(player, PSP_FLASH, "flash")
    else
        DOOM_AdvancePSprite(player, PSP_WEAPON, "idle")
    end
end

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if (player.mo.flags & MF_NOTHINK) then return end

	if (player.mo.eflags & MFE_JUSTHITFLOOR) then
		if (player.doom.lastmomz or 0) <= doom.defaultgravity*-8 then
			S_StartSound(player.mo, sfx_oof)
			--player.deltaviewheight = player.doom.lastmomz>>3
		end
	else
		player.doom.lastmomz = player.mo.momz
	end

	player.doom.powers = $ or {}

	if player.doom.powers[pw_strength] then
		player.doom.powers[pw_strength] = $ + 1
	end

	if player.doom.powers[pw_ironfeet] then
		player.doom.powers[pw_ironfeet] = $ - 1
	end

	if player.doom.powers[pw_infrared] then
		player.doom.powers[pw_infrared] = $ - 1
	end

	if player.doom.powers[pw_invulnerability] then
		player.doom.powers[pw_invulnerability] = $ - 1
	end

	player.doom.bonuscount = ($ or 1) - 1
	player.doom.damagecount = ($ or 1) - 1
	player.doom.messageclock = ($ or 1) - 1

	local support = P_GetSupportsForSkin(player)
	if support.noWeapons then return end

	-- attacker ##MIGHT be important for killcam logic
	if player.mo.doom.health > 0 then
		if not player.doom.damagecount then player.doom.attacker = nil end
	end

	updateWeaponState(player, false)  -- Main weapon state
	updateWeaponState(player, true)   -- Flash state
end)

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if (player.mo.flags & MF_NOTHINK) then return end
	local support = P_GetSupportsForSkin(player)

	if support.noWeapons then return end
	if not player.doom then return end
	player.doom.lastbuttons = $ or 0

	if player.doom.curwep == nil then
		player.doom.curwep = "pistol"
		player.doom.curwepslot = 1
		player.doom.curwepcat = 1
	end

	if not player.doom.wepcarousel then
		player.doom.wepcarousel = {
			curwep = player.doom.curwep,
			curwepslot = player.doom.curwepslot,
			curwepcat = player.doom.curwepcat,
			wepconfirmationtimer = 0,
			showtimer = 0,
			active = false,
			cooldown = 0
		}
	end

	local carousel = player.doom.wepcarousel

	local function commitWeapon(player, weapon, slot, order, feedbackTime)
		player.doom.curwepcat = slot
		player.doom.curwepslot = order
		player.doom.wishwep = weapon
		player.doom.switchingweps = true

		carousel.curwep = weapon
		carousel.curwepcat = slot
		carousel.curwepslot = order
		carousel.active = false
		carousel.wepconfirmationtimer = 0
		carousel.showtimer = feedbackTime or 0
	end

	-- Update cooldown timer
	if carousel.cooldown > 0 then
		carousel.cooldown = $-1
	end

	local currentButtons = player.cmd.buttons & (BT_WEAPONMASK | BT_WEAPONNEXT | BT_WEAPONPREV)

	local baseSlot = player.doom.curwepcat
	local baseOrder = player.doom.curwepslot

	-- Only process BT_WEAPONNEXT and BT_WEAPONPREV if cooldown is 0
	local canProcessPrevNext = (carousel.cooldown == 0)
	
	if canProcessPrevNext then
		if player.cmd.buttons & BT_WEAPONNEXT ~= 0 and player.doom.lastbuttons & BT_WEAPONNEXT == 0 then
			local targetSlot, targetOrder = doom.findNextWeapon(player, 1, baseSlot, baseOrder)
			local targetWeapon = doom.weaponnames[targetSlot][targetOrder]
			commitWeapon(player, targetWeapon, targetSlot, targetOrder, TICRATE/2)
			carousel.cooldown = 3
		elseif player.cmd.buttons & BT_WEAPONPREV ~= 0 and player.doom.lastbuttons & BT_WEAPONPREV == 0 then
			local targetSlot, targetOrder = doom.findNextWeapon(player, -1, baseSlot, baseOrder)
			local targetWeapon = doom.weaponnames[targetSlot][targetOrder]
			commitWeapon(player, targetWeapon, targetSlot, targetOrder, TICRATE/2)
			carousel.cooldown = 3
		end
	end

	local slotPressed = player.cmd.buttons & BT_WEAPONMASK
	local slotWasPressed = player.doom.lastbuttons & BT_WEAPONMASK

	-- only act if a new slot was pressed this tic
	if slotPressed ~= 0 and slotPressed ~= slotWasPressed then
		local slot = slotPressed
		local wepsInSlot = doom.weaponnames[slot]
		local firstOwnedOrder = doom.firstAvailableInSlot(player, slot)
		if firstOwnedOrder then
			local targetOrder
			if slot ~= baseSlot then
				targetOrder = firstOwnedOrder
			else
				-- cycle within slot if multiple weapons
				local nextOrder = (baseOrder % #wepsInSlot) + 1
				for i = 1, #wepsInSlot do
					if player.doom.weapons[wepsInSlot[nextOrder]] then
						targetOrder = nextOrder
						break
					end
					nextOrder = (nextOrder % #wepsInSlot) + 1
				end
				targetOrder = targetOrder or firstOwnedOrder
			end

			local targetWeapon = wepsInSlot[targetOrder]
			commitWeapon(player, targetWeapon, slot, targetOrder, TICRATE/4)
		end
	end

	-- TODO: Maybe Not needed? Woof does weapon switching immediately
	if carousel.active then
		if carousel.wepconfirmationtimer > 0 then
			carousel.wepconfirmationtimer = $-1
		else
			--player.doom.curwep = carousel.curwep
			player.doom.curwepcat = carousel.curwepcat
			player.doom.curwepslot = carousel.curwepslot
			player.doom.wishwep = carousel.curwep
			player.doom.switchingweps = true
			carousel.active = false
		end
	end

	local noPendingSwitch =
		(not player.doom.switchingweps)
		and (
			not player.doom.wepcarousel.active
			or player.doom.wepcarousel.curwep == player.doom.curwep
		)
		and (
			not player.doom.wishwep
			or player.doom.wishwep == ""
			or player.doom.wishwep == player.doom.curwep
		)

	if noPendingSwitch then
		if carousel.showtimer then
			carousel.showtimer = $-1
		end
	end

	player.doom.lastbuttons = player.cmd.buttons
end)

local function DoomSectorDamage(player, amount, burnthrough)
	local funcs = P_GetMethodsForSkin(player)
	-- If they have ironfeet, normally ignore damage
	if funcs.hasPowerUp(player, "ironfeet")
	then
		-- burnthrough ONLY applies to 20 dmg floors
		if not burnthrough then
			return
		end

		-- burnthrough chance (NOT pw_ironfeet OR DOOM_Random()<5)
		if DOOM_Random() >= 5 then
			return
		end
	end

	DOOM_DamageMobj(player.mo, nil, nil, amount)
end

local function getIntersectingObjects(target, shootables)
	if not target or not target.valid then
		return {}
	end

	local results = {}

	local tx = target.x
	local ty = target.y
	local tr = target.radius or 0

	-- target vertical span
	local ttop = target.z + (target.height or 0)
	local tbot = target.z

	for mobj in mobjs.iterate() do
		if not mobj or not mobj.valid then
			continue
		end

		if mobj == target then
			continue
		end

		-- skip noclip / noclipheight
		if (mobj.flags & MF_NOCLIP) or (mobj.flags & MF_NOCLIPHEIGHT) then
			continue
		end

		if shootables then
			if not (mobj.flags & MF_SHOOTABLE) then
				continue
			end
		end

		local r = mobj.radius or 0

		-- XY cylinder overlap check
		-- Instead of sqrt check, use AABB-overlap style like your original
		if (mobj.x + r) < (tx - tr) then continue end
		if (mobj.x - r) > (tx + tr) then continue end
		if (mobj.y + r) < (ty - tr) then continue end
		if (mobj.y - r) > (ty + tr) then continue end

		-- Z overlap check
		local mbot = mobj.z
		local mtop = mobj.z + (mobj.height or 0)

		-- If they don't overlap vertically, skip
		if (mtop <= tbot) or (mbot >= ttop) then
			continue
		end

		-- Passed all checks, add to list
		results[#results + 1] = mobj
	end

	return results
end

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if (player.mo.flags & MF_NOTHINK) then return end

	if doom.issrb2 then
		player.mo.doom.armor = leveltime/TICRATE
	end

	if player.mo.tele then
		local tel = player.mo.tele
		P_SetOrigin(player.mo, tel.x, tel.y, tel.z)
		local victims = getIntersectingObjects(player.mo, true)

		for i = 1, #victims do
			local target = victims[i]
			DOOM_DamageMobj(target, player.mo, player.mo, 10000, doom.damagetypes.telefrag)
		end
		player.mo.tele = nil
		-- fog at destination (20 units in front of exit angle)
		local destfog = P_SpawnMobj(player.mo.x + 20*cos(player.mo.angle), player.mo.y + 20*sin(player.mo.angle), player.mo.z, MT_DOOM_TELEFOG)
	end

	if player.mo.z != player.mo.subsector.sector.floorheight then return end

	local funcs = P_GetMethodsForSkin(player)
	local spec = doom.sectorspecials[player.mo.subsector.sector]

	if spec == 16 then
		if not (leveltime & 31) then
			DoomSectorDamage(player, 20, true) -- 20 dmg floor w/burnthrough
		end
	elseif spec == 5 then
		if not (leveltime & 31) then
			DoomSectorDamage(player, 10)
		end
	elseif spec == 7 then
		if not (leveltime & 31) then
			DoomSectorDamage(player, 5)
		end
	elseif spec == 4 then
		if not (leveltime & 31) then
			DoomSectorDamage(player, 20, true) -- 20 dmg floor w/burnthrough
		end
	elseif spec == 11 then
		player.doom.cheats = player.doom.cheats & ~CF_GODMODE

		if not (leveltime & 31) then
			DOOM_DamageMobj(player.mo, nil, nil, 20, 0, 1)
		end

		local curHealth = funcs.getHealth(player) or 0
		if curHealth <= 10 and not DOOM_IsExiting() then
			DOOM_ExitLevel()
		end
		if curHealth <= 1 then
			funcs.setHealth(player, 1)
		end
	elseif spec == 9 then
		doom.sectorspecials[player.mo.subsector.sector] = 0
		player.doom.secrets = ($ or 0) + 1
		S_StartSound(nil, sfx_secret)
	end
end)

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if (player.mo.flags & MF_NOTHINK) then return end
    local cnt = player.doom.damagecount or 0
    local bzc = 0
	local funcs = P_GetMethodsForSkin(player)
	local berserkTime = 0
	local infraredTime = 0
	local ironfeetTime = 0

    if funcs.getPowerupTime then
		berserkTime = funcs.getPowerupTime(player, "berserk")
	else
		berserkTime = player.doom.powers[pw_strength]
    end

	if berserkTime then
    	bzc = 12 - (player.doom.powers[pw_strength] >> 6)
        if bzc > cnt then
            cnt = bzc
        end
	end

	if funcs.getPowerupTime then
		infraredTime = funcs.getPowerupTime(player, "infrared")
	else
		infraredTime = player.doom.powers[pw_infrared]
	end

	if infraredTime then
		if infraredTime > 4*32
			or (infraredTime&8) then
			player.doom.fixedcolormap = 1
		else
			player.doom.fixedcolormap = 0
		end
	end

    local paletteType = 0 -- default normal palette

	if funcs.getPowerupTime then
		ironfeetTime = funcs.getPowerupTime(player, "ironfeet")
	else
		ironfeetTime = player.doom.powers[pw_ironfeet]
	end

    if cnt > 0 then
        -- red palette for damage/berserk
        local redPal = ((cnt + 7) >> 3)
        if redPal >= NUMREDPALS then redPal = NUMREDPALS - 1 end
        paletteType = STARTREDPALS + redPal

    elseif player.doom.bonuscount and player.doom.bonuscount > 0 then
        -- yellow/bonus palette
        local bonusPal = ((player.doom.bonuscount + 7) >> 3)
        if bonusPal >= NUMBONUSPALS then bonusPal = NUMBONUSPALS - 1 end
        paletteType = STARTBONUSPALS + bonusPal

    elseif ironfeetTime and (ironfeetTime > 4*32 or (ironfeetTime & 8) ~= 0) then
        paletteType = RADIATIONPAL
    end

    if paletteType ~= nil and DOOM_IsPaletteRenderer() then
        P_FlashPal(player, paletteType, 1)
    end
end)

---@param player player_t
addHook("PlayerThink", function(player)
	player.pflags = $ & ~(PF_SPINNING)
	camera.chase = false
	player.drawangle = player.mo.angle
end)

-- TODO: Verify if this is necessary
addHook("PlayerHeight", function(player)
	if not player.mo then return end
	local mobj = player.mo
	local mdoom = mobj.doom
	local space = abs(mobj.floorz - mobj.ceilingz)
	if space < mdoom.height then
		return max(space, 0)
	end
end)

local function merge(target_table, source_table)
    for key, value in pairs(source_table) do
        target_table[key] = value
    end
end

local function syncWeaponFields(player)
	local wep = player.doom.curwep
	local def = wep and doom.weapons[wep]
	if def then
		player.doom.curwepcat = def.weaponslot
		-- Find the sequential index of this weapon in its slot
		local slot = def.weaponslot
		local wepsInSlot = doom.weaponnames[slot]
		for idx, wepname in ipairs(wepsInSlot) do
			if wepname == wep then
				player.doom.curwepslot = idx
				break
			end
		end
	end
end

addHook("PlayerSpawn",function(player)
	if not player.mo return end
	if consoleplayer == player then
		camera.chase = false
	end
	player.doom = $ or {}
	player.doom.prefs = $ or {}
	player.doom.damagecount = 0
	player.doom.bonuscount = 0
	player.doom.facecount = 0
	player.doom.bobx = 0
	player.doom.boby = 0
	player.doom.flashtics = 0
	player.doom.flashstate = "flash"
	player.doom.flashframe = -1

	if (gametyperules & GTR_RINGSLINGER) then
		local funcs = P_GetMethodsForSkin(player)
		if funcs and funcs.throwOutSaveState then
			funcs.throwOutSaveState(player)
		end
	end

	if player.doom.laststate and player.doom.laststate.map == gamemap then
		P_SetOrigin(player.mo, player.doom.laststate.pos.x, player.doom.laststate.pos.y, player.doom.laststate.pos.z)
		player.mo.momx = player.doom.laststate.momentum.x
		player.mo.momy = player.doom.laststate.momentum.y
		player.mo.momz = player.doom.laststate.momentum.z
	end

	local function pick(saved_val, default_val)
		return saved_val ~= nil and saved_val or default_val
	end

	local preset = deepcopy(doom.pistolstartstate)
	local properties = P_GetPlayerSkinProperties(player)

	local function merge_defined_shallow(dest, srcmap)
		for dest_key, src_value in pairs(srcmap) do
			if src_value ~= nil then
				dest[dest_key] = src_value
			end
		end
	end

	local function merge_defined_semideep(dest, srcmap)
		for dest_key, src_value in pairs(srcmap) do
			if src_value ~= nil then
				if type(dest[dest_key]) == "table" and type(src_value) == "table" then
					merge(dest[dest_key], src_value)
				else
					dest[dest_key] = src_value
				end
			end
		end
	end

	local startweapons = properties.startweapons
	if type(startweapons) == "table" and #startweapons > 0 then
		local wepTable = {}
		for _, wep in ipairs(startweapons) do
			wepTable[wep] = true
		end
		startweapons = wepTable
	end

	merge_defined_semideep(preset, {
		ammo = properties.startammo,
		curwep = properties.startweapon,
		health = properties.starthealth,
		armor = properties.startarmor,
		maxhealth = properties.maxhealth,
		maxarmor = properties.maxarmor,
		maxammo = properties.maxammo,
		armorefficiency = properties.startarmorprot
	})

	merge_defined_shallow(preset, {
		weapons = startweapons
	})

	preset.oldweapons = preset.weapons

	local saved  = player.doom.laststate
	if doom.issrb2 then
		preset.health = 1
	end

	local function choose(field)
		if preset.useinvbackups and saved and saved[field] ~= nil then
			return deepcopy(saved[field])
		end
		return deepcopy(preset[field])
	end

	-- Assign latest backup
	player.doom = $ or {}
	player.doom.powers = {}
	player.doom.deadtimer = 0
	player.killcam = nil
	player.doom.ammo = choose("ammo")
	player.doom.weapons = choose("weapons")
	player.doom.curwep = choose("curwep")
	syncWeaponFields(player)
	player.doom.twoxammo = choose("twoxammo")
	player.mo.doom.health = choose("health")
	player.mo.doom.armor = choose("armor")
	player.mo.doom.maxhealth = choose("maxhealth")
	player.mo.doom.maxarmor = choose("maxarmor")
	player.mo.doom.armorefficiency = choose("armorefficiency")
	player.doom.oldweapons = choose("oldweapons")
	player.doom.notrigger = false
	player.doom.cheats = ($ or 0)
	if G_RingSlingerGametype() then
		player.doom.keys = UINT32_MAX
	elseif not multiplayer then
		player.doom.keys = 0
	end
	player.doom.frags = $ or {}
	player.doom.switchtimer = 128
	player.doom.wishwep = nil
	player.doom.properties = properties

	DOOM_SetState(player, "raise")

	player.mo.flags2 = $ & ~MF2_OBJECTFLIP
	player.mo.eflags = $ & ~MFE_VERTICALFLIP
	if player.mo and (player.mo.info.flags & MF_SPAWNCEILING) then
		-- place object's top at the ceiling: ceilingz - height
		player.mo.z = P_CeilingzAtPos(player.mo.x, player.mo.y, 0, 0) - player.mo.height
	else
		player.mo.z = P_FloorzAtPos(player.mo.x, player.mo.y, 0, 0)
	end

	local sp = doom.spawnpoints
	-- If spawnpoints are initialized...
	if (sp and sp.player and sp.player[1] and #sp.player[1] > 0)
	or (sp and sp.deathmatch and #sp.deathmatch > 0) then
		local function getPlayerSpawn(preferred)
			for i = 0, 3 do
				local slot = ((preferred - 1 + i) % 4) + 1
				local list = sp.player[slot]

				if list and list[#list] then
					return list[#list]
				end
			end
		end

		if (gametyperules & GTR_RINGSLINGER) then
			local matchspawncount = #sp.deathmatch
			if matchspawncount > 0 then
				local pspawn_index = P_RandomKey(matchspawncount) + 1
				local pspawn = sp.deathmatch[pspawn_index]

				P_SetOrigin(player.mo, pspawn.x, pspawn.y, pspawn.z)
				player.mo.angle = pspawn.angle
				player.drawangle = pspawn.angle
			end
		else
			local pnum = #player
			local preferred = (pnum % 4) + 1
			local pspawn = getPlayerSpawn(preferred)

			if pspawn then
				P_SetOrigin(player.mo, pspawn.x, pspawn.y, pspawn.z)
				player.mo.angle = pspawn.angle
				player.drawangle = pspawn.angle
			end
		end
	end
end)

local function lineToLinePos(mo, src, dst, reversed)
	local sdx = src.v2.x - src.v1.x
	local sdy = src.v2.y - src.v1.y
	local slen = P_AproxDistance(sdx, sdy)
	if slen == 0 then return end

	local dx = mo.x - src.v1.x
	local dy = mo.y - src.v1.y

	// Fraction along the source line: 0 = v1, FRACUNIT = v2
	local along = FixedDiv(
		FixedMul(dx, sdx) + FixedMul(dy, sdy),
		FixedMul(slen, slen)
	)

	if reversed then
		along = FRACUNIT - along
	end

	// Signed perpendicular offset from the source line
	local perp = FixedDiv(
		FixedMul(dx, -sdy) + FixedMul(dy, sdx),
		slen
	)

	local ddx = dst.v2.x - dst.v1.x
	local ddy = dst.v2.y - dst.v1.y
	local dlen = P_AproxDistance(ddx, ddy)
	if dlen == 0 then return end

	local newx = dst.v1.x
		+ FixedMul(along, ddx)
		+ FixedMul(perp, FixedDiv(-ddy, dlen))

	local newy = dst.v1.y
		+ FixedMul(along, ddy)
		+ FixedMul(perp, FixedDiv(ddx, dlen))

	return newx, newy
end

local typeHandlers = {
	---@param usedLine line_t
	teleport = function(usedLine, whatIs, plyrmo)
		local player = plyrmo.player
		local line = usedLine

		if whatIs.linetoline then
			local lineTag

			for line in lines.tagged(usedLine.tag) do
				if line == usedLine then continue end
				lineTag = line
				break
			end
			if not lineTag then return end

			local newx, newy = lineToLinePos(plyrmo, usedLine, lineTag, true)
			if newx == nil then return end

			plyrmo.doom.handlingtele = true
			plyrmo.tele = {x = newx, y = newy, z = plyrmo.z}
			plyrmo.doom.handlingtele = false

			return
		end

		if (plyrmo.flags & MF_MISSILE) then return end
		if plyrmo.reactiontime and plyrmo.reactiontime > 0 then return end
		if P_PointOnLineSide(plyrmo.x, plyrmo.y, usedLine) == 1 then return end

		local teletarg
		for sector in sectors.tagged(usedLine.tag) do
			if sector == plyrmo.subsector.sector then continue end
			for mobj in sector.thinglist() do
				if mobj.type == MT_DOOM_TELETARGET then
					teletarg = mobj
					break
				end
			end
			if teletarg then break end
		end
		if not teletarg then return end

		local oldx, oldy, oldz = plyrmo.x, plyrmo.y, plyrmo.z
		local newx, newy, newz = teletarg.x, teletarg.y, teletarg.z
		plyrmo.tele = {x = newx, y = newy, z = newz}

		--plyrmo.z = plyrmo.floorz
		if plyrmo.player then
			plyrmo.player.viewz = plyrmo.z + plyrmo.player.viewheight
			plyrmo.reactiontime = 18
		end

		plyrmo.angle = teletarg.angle
		plyrmo.momx, plyrmo.momy, plyrmo.momz = 0, 0, 0

		-- fog at source
		local fog = P_SpawnMobj(oldx, oldy, oldz, MT_DOOM_TELEFOG)
	end,
	exit = function(_, whatIs)
		doom.didSecretExit = whatIs.secret
		DOOM_ExitLevel()
	end
}

addHook("MobjLineCollide", function(mobj, hit)
	if mobj.doom.handlingtele then return end
	-- pos + momentum = the direction the player intended to go
	-- TODO: Add checks for if the movement is available to the player!
	if P_PointOnLineSide(mobj.x, mobj.y, hit) == P_PointOnLineSide(mobj.x + mobj.momx, mobj.y + mobj.momy, hit) then return end
	if not (mobj and mobj.player) then return end
	-- TODO: is this actually required?
	if mobj.player.doom.notrigger then return end
    local usedLine = hit
    local lineSpecial = doom.linespecials[usedLine]
    if not lineSpecial then
		return
	end
    local whatIs = doom.lineActions[lineSpecial]
    if not whatIs or whatIs.activationType ~= "walk" then
		return
	end

	if typeHandlers[whatIs.type] then
		typeHandlers[whatIs.type](usedLine, whatIs, mobj)
	else
		for sector in sectors.tagged(usedLine.tag) do
			doom.addThinker(sector, whatIs)
		end
	end

	if not doom.lineActions[lineSpecial].repeatable then
		doom.linespecials[usedLine] = 0
	end
end, MT_PLAYER)

addHook("ShouldDamage", function(mobj, inf, src, dmg, dt)
	if dt == DMG_CRUSHED and not (inf or src) then return false end
end)
/*
addHook("PlayerThink", function(player)
	local mobj = player.mo
	if not mobj then return end

	local curSector = mobj.subsector.sector

	if mobj.z > curSector.floorheight then
		player.doom.conveyorhandled = false
		return
	end

	for k, data in iteratethinkerdata(curSector, "sectorscroll") do
		if data.place ~= "floor" then continue end

		player.cmomx = $ + data.carryx
		player.cmomy = $ + data.carryy
	end

	if (player.cmomx ~= 0 or player.cmomy ~= 0) and not player.doom.conveyorhandled then
		player.onconveyor = 4

		mobj.momx = $ + player.cmomx
		mobj.momy = $ + player.cmomy
		player.doom.conveyorhandled = true
	end

	-- print(mobj.momx / FU, (player.rmomx) / FU)
end)
*/