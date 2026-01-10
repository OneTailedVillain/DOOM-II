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
	local health = min(myHealth, 100)
	local lastcalc = ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) / 101)

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
	if (player.mo.flags & MF_NOTHINK) then return end
	player.doom = $ or {}
	ST_updateFaceWidget(player)
	
	if player.doom.powers[pw_invisibility] then
		player.mo.doom.flags = $ | DF_SHADOW
	else
		player.mo.doom.flags = $ & ~DF_SHADOW
	end
end)

local function printTable(data, prefix)
	prefix = prefix or ""
	if type(data) == "table"
		if not next(data) then
			print("[Empty table]")
		else
			for k, v in pairs(data or {}) do
				local key = prefix .. k
				if type(v) == "table" then
					print("key " .. key .. " = a table:")
					printTable(v, key .. ".")
				else
					print("key " .. key .. " = " .. tostring(v))
				end
			end
		end
	else
		print(data)
	end
end

addHook("PlayerThink", function(player)
	if player.spectator then
		player.realmo.flags = $ | (MF_NOCLIPHEIGHT|MF_NOCLIP|MF_NOCLIPTHING)
		player.realmo.flags2 = $ & ~MF2_OBJECTFLIP
		player.realmo.eflags = $ & ~MFE_VERTICALFLIP
	end

	if not player.mo then return end

	if (player.mo.flags & MF_NOTHINK) then return end

	if (player.cmd.buttons & BT_JUMP) then
		if doom.issrb2 then
			if P_IsObjectOnGround(player.mo) and player.realmo.skin == "johndoom" then
				S_StartSound(player.mo, sfx_jump)
				player.mo.momz = 6*FRACUNIT
			end
		elseif not (player.doom.lastbuttons & BT_JUMP)
			DOOM_TryUse(player)
		end
	end

	if (player.cmd.buttons & BT_SPIN) and not (player.doom.lastbuttons & BT_SPIN) and doom.issrb2 then
		DOOM_TryUse(player)
	end
	
	player.doom.lastbuttons = player.cmd.buttons
end)

local function updateWeaponState(player, isFlashState)
	if isFlashState then
		if player.doom.flashtics == 0 and player.doom.flashframe >= 1 then
			local curDef = DOOM_GetWeaponDef(player)
			local stateTable = curDef and curDef.states and curDef.states[player.doom.flashstate or "flash"]
			local currentFrameDef = stateTable and stateTable[player.doom.flashframe]

			if currentFrameDef then
				if currentFrameDef.terminate then
					-- Terminate flash state early
					player.doom.flashframe = 0
					player.doom.flashstate = "flash"
				elseif currentFrameDef.nextstate then
					-- Use weapon-defined next state/frame for flash
					player.doom.flashstate = currentFrameDef.nextstate
					player.doom.flashframe = currentFrameDef.nextframe or 1

					-- Check if flash state transitions to a different weapon
					if currentFrameDef.nextwep then
						-- Cross-weapon flash transition (rare but possible)
						player.doom.curwep = currentFrameDef.nextwep
						curDef = DOOM_GetWeaponDef(player)
					end

					local nextDef = curDef and curDef.states and
						curDef.states[player.doom.flashstate] and
						curDef.states[player.doom.flashstate][player.doom.flashframe]

					if nextDef then
						player.doom.flashtics = nextDef.tics
						-- Call action like DOOM_SetState does (if provided)
						if nextDef.action then
							nextDef.action(player.mo, nextDef.var1, nextDef.var2, DOOM_GetWeaponDef(player))
						end
					else
						player.doom.flashframe = 0
						player.doom.flashstate = "flash"
					end
				else
					-- Linear progression (original behavior)
					player.doom.flashframe = (player.doom.flashframe or 1) + 1
					local nextDef = stateTable and stateTable[player.doom.flashframe]
					if nextDef == nil then
						player.doom.flashframe = 0
						player.doom.flashstate = "flash"
					else
						player.doom.flashtics = nextDef.tics
						-- Call action for the newly-active flash frame (if any)
						if nextDef.action then
							nextDef.action(player.mo, nextDef.var1, nextDef.var2, DOOM_GetWeaponDef(player))
						end
					end
				end
			else
				-- Invalid frame definition
				player.doom.flashframe = 0
				player.doom.flashstate = "flash"
			end
		end
	else
		if player.doom.weptics == 0 then
			local curDef = DOOM_GetWeaponDef(player)
			local stateTable = curDef and curDef.states and curDef.states[player.doom.wepstate]
			local currentFrameDef = stateTable and stateTable[player.doom.wepframe]

			if currentFrameDef then
				if currentFrameDef.terminate then
					-- Terminate state early and go to idle
					DOOM_SetState(player, "idle")
				elseif currentFrameDef.nextstate then
					-- Use weapon-defined next state/frame
					local nextState = currentFrameDef.nextstate
					local nextFrame = currentFrameDef.nextframe or 1

					-- Check if we're transitioning to a different weapon
					if currentFrameDef.nextwep then
						-- Cross-weapon transition
						player.doom.curwep = currentFrameDef.nextwep
						curDef = DOOM_GetWeaponDef(player)
					end

					DOOM_SetState(player, nextState, nextFrame)
				else
					-- Linear progression (original behavior)
					player.doom.wepframe = (player.doom.wepframe or 1) + 1
					local nextDef = stateTable and stateTable[player.doom.wepframe]
					if nextDef == nil then
						-- Get the next state from weapon definition or use default
						local nextState = curDef and curDef.nextstate and curDef.nextstate[player.doom.wepstate]

						if nextState then
							-- Weapon defines a specific next state for this state
							DOOM_SetState(player, nextState)
						else
							-- Default behavior based on current state
							if player.doom.wepstate == "lower" or player.doom.wepstate == "raise" then
								-- Continue the current state if no next state defined
								DOOM_SetState(player, player.doom.wepstate)
							else
								-- Return to idle for other states
								DOOM_SetState(player, "idle")
							end
						end
					else
						-- Continue with current frame in current state
						DOOM_SetState(player, player.doom.wepstate, player.doom.wepframe)
					end
				end
			else
				-- Invalid frame definition - go to idle
				DOOM_SetState(player, "idle")
			end
		end
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

	player.doom.weptics = ($ or 1) - 1
	if player.doom.flashframe >= 0 then
		player.doom.flashtics = ($ or 1) - 1
	end

	updateWeaponState(player, false)  -- Main weapon state
	updateWeaponState(player, true)   -- Flash state
end)

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if (player.mo.flags & MF_NOTHINK) then return end
	local support = P_GetSupportsForSkin(player)

	if support.noWeapons then return end

	if player.doom.curwep == nil then
		player.doom.curwep = "pistol"
		player.doom.curwepslot = 1
		player.doom.curwepcat = 1
	end

	local function firstAvailableInSlot(player, slot)
		if not doom.weaponnames[slot] then
			return nil
		end
		for order, wep in ipairs(doom.weaponnames[slot]) do
			if player.doom.weapons[wep] then
				return order
			end
		end
		return nil -- nothing owned in this slot
	end

	local function findNextWeapon(player, direction)
		-- direction: 1 for next, -1 for previous
		local currentSlot = player.doom.curwepcat
		local currentOrder = player.doom.curwepslot
		local totalSlots = #doom.weaponnames
		
		-- First, try to find next weapon in current slot
		if direction == 1 then
			-- Look for higher order weapons in current slot
			for order = currentOrder + 1, #doom.weaponnames[currentSlot] do
				local weapon = doom.weaponnames[currentSlot][order]
				if player.doom.weapons[weapon] then
					return currentSlot, order
				end
			end
		else -- direction == -1
			-- Look for lower order weapons in current slot
			for order = currentOrder - 1, 1, -1 do
				local weapon = doom.weaponnames[currentSlot][order]
				if player.doom.weapons[weapon] then
					return currentSlot, order
				end
			end
		end
		
		-- If no weapon found in current slot, search other slots
		local startSlot = currentSlot
		local slot = (currentSlot + direction - 1) % totalSlots + 1
		
		while slot ~= startSlot do
			-- Check if this slot has any weapons
			local firstOrder = firstAvailableInSlot(player, slot)
			if firstOrder then
				-- Found a slot with weapons, use the highest priority one
				if direction == 1 then
					-- For next, use the lowest order (highest priority)
					return slot, firstOrder
				else
					-- For previous, use the highest order (lowest priority) in this slot
					local highestOrder = firstOrder
					for order = firstOrder + 1, #doom.weaponnames[slot] do
						if player.doom.weapons[doom.weaponnames[slot][order]] then
							highestOrder = order
						end
					end
					return slot, highestOrder
				end
			end
			
			-- Move to next slot in direction
			slot = (slot + direction - 1) % totalSlots + 1
		end
		
		-- No other weapons found, stay with current
		return currentSlot, currentOrder
	end

	-- Check for weapon button presses (even during switching)
	local currentButtons = player.cmd.buttons & (BT_WEAPONMASK | BT_WEAPONNEXT | BT_WEAPONPREV)
	if currentButtons and (player.doom.lastwepbutton != currentButtons) then
		local slot = player.cmd.buttons & BT_WEAPONMASK
		
		if (player.cmd.buttons & BT_WEAPONNEXT) then
			-- Next weapon button
			local targetSlot, targetOrder = findNextWeapon(player, 1)
			local targetWeapon = doom.weaponnames[targetSlot][targetOrder]
			
			player.doom.wishwep = targetWeapon
			player.doom.curwepcat = targetSlot
			player.doom.curwepslot = targetOrder
			
			-- Start switching animation if not already switching
			if not player.doom.switchingweps then
				player.doom.switchingweps = true
			end
			
		elseif (player.cmd.buttons & BT_WEAPONPREV) then
			-- Previous weapon button
			local targetSlot, targetOrder = findNextWeapon(player, -1)
			local targetWeapon = doom.weaponnames[targetSlot][targetOrder]
			
			player.doom.wishwep = targetWeapon
			player.doom.curwepcat = targetSlot
			player.doom.curwepslot = targetOrder
			
			-- Start switching animation if not already switching
			if not player.doom.switchingweps then
				player.doom.switchingweps = true
			end
			
		elseif slot > 0 then
			-- Regular weapon slot button
			local wepsInSlot = doom.weaponnames[slot]

			-- Abort if slot doesn't exist or has no owned weapons
			local firstOwnedOrder = firstAvailableInSlot(player, slot)
			if not firstOwnedOrder then
				player.doom.lastwepbutton = currentButtons
				return -- deny switch entirely
			end

			-- Determine the target weapon
			local targetWeaponOrder
			if slot ~= player.doom.curwepcat then
				-- Switching to new slot: pick lowest order weapon
				targetWeaponOrder = firstOwnedOrder
			elseif #wepsInSlot > 1 then
				-- Cycling within same slot
				local nextOrder = (player.doom.curwepslot % #wepsInSlot) + 1
				for i = 1, #wepsInSlot do
					if player.doom.weapons[wepsInSlot[nextOrder]] then
						targetWeaponOrder = nextOrder
						break
					end
					nextOrder = (nextOrder % #wepsInSlot) + 1
				end
			else
				-- Only one weapon in slot, use it
				targetWeaponOrder = firstOwnedOrder
			end

			-- Set the wish weapon
			player.doom.wishwep = wepsInSlot[targetWeaponOrder]
			player.doom.curwepcat = slot
			player.doom.curwepslot = targetWeaponOrder

			-- Start switching animation if not already switching
			if not player.doom.switchingweps then
				player.doom.switchingweps = true
			end
		end
	end

	player.doom.lastbuttons = player.cmd.buttons
	player.doom.lastwepbutton = currentButtons or 0
end)

local function DoomSectorDamage(player, amount, burnthrough)
	-- If they have ironfeet, normally ignore damage
	if player
	and player.doom
	and player.doom.powers
	and player.doom.powers[pw_ironfeet]
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
			print("FAIL: VERT CHECK!")
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
			DOOM_DamageMobj(target, player.mo, player.mo, 10000)
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
		if not player.doom.powers[pw_invulnerability] then
			player.pflags = $ & ~PF_GODMODE
		end

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
		doom.secrets = ($ or 0) + 1
		S_StartSound(nil, sfx_secret)
	end
end)

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if (player.mo.flags & MF_NOTHINK) then return end
    local cnt = player.doom.damagecount or 0
    local bzc = 0

    if player.doom.powers[pw_strength] and player.doom.powers[pw_strength] > 0 then
        bzc = 12 - (player.doom.powers[pw_strength] >> 6)
        if bzc > cnt then
            cnt = bzc
        end
    end

	if player.doom.powers[pw_infrared] then
		if player.doom.powers[pw_infrared] > 4*32
			or (player.doom.powers[pw_infrared]&8) then
			player.doom.fixedcolormap = 1
		else
			player.doom.fixedcolormap = 0
		end
	end

    local paletteType = 0 -- default normal palette

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

    elseif player.doom.powers[pw_ironfeet] and (player.doom.powers[pw_ironfeet] > 4*32 or (player.doom.powers[pw_ironfeet] & 8) ~= 0) then
        paletteType = RADIATIONPAL
    end

    if paletteType ~= nil and DOOM_IsPaletteRenderer() then
        P_FlashPal(player, paletteType, 1)
    end
end)

addHook("PlayerThink", function(player)
	player.pflags = $ & ~(PF_SPINNING)
end, MT_PLAYER)

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

local function deepcopy(orig)
	local orig_type = type(orig)
	if orig_type ~= 'table' then
		if orig_type == "boolean" then
			return orig == true
		else
			return tonumber(orig) == nil and tostring(orig) or tonumber(orig)
		end
	end
	local copy = {}
	for k, v in next, orig, nil do
		copy[deepcopy(k)] = deepcopy(v)
	end
	return copy
end

addHook("PlayerSpawn",function(player)
	if not player.mo return end
	if consoleplayer == player then
		camera.chase = false
	end
	player.doom = $ or {}
	player.doom.damagecount = 0
	player.doom.bonuscount = 0
	player.doom.facecount = 0
	player.doom.bobx = 0
	player.doom.boby = 0
	player.doom.flashtics = 0
	player.doom.flashstate = "flash"
	player.doom.flashframe = -1
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
	local saved  = player.doom.laststate
	if doom.issrb2 then
		preset.health = 1
	end

	local function choose(field)
		if preset.useinvbackups and saved and saved[field] ~= nil then
			return saved[field]
		end
		return preset[field]
	end

	-- Assign latest backup
	player.doom = $ or {}
	player.doom.powers = {}
	player.doom.deadtimer = 0
	player.killcam = nil
	player.doom.ammo = choose("ammo")
	player.doom.weapons = choose("weapons")
	player.doom.curwep = choose("curwep")
	player.doom.curwepslot = choose("curwepslot")
	player.doom.curwepcat = choose("curwepcat")
	player.doom.twoxammo = choose("twoxammo")
	player.mo.doom.health = choose("health")
	player.mo.doom.armor = choose("armor")
	player.mo.doom.maxhealth = choose("maxhealth")
	player.mo.doom.maxarmor = choose("maxarmor")
	player.mo.doom.armorefficiency = choose("armorefficiency")
	player.doom.oldweapons = choose("oldweapons")
	player.doom.notrigger = false
	if gametype == GT_DOOMDM or gametype == GT_DOOMDMTWO then
		player.doom.keys = UINT32_MAX
	elseif not multiplayer then
		player.doom.keys = 0
	end
	player.doom.switchtimer = 128
	player.doom.wishwep = nil

	DOOM_SetState(player, "raise")

	player.mo.flags2 = $ & ~MF2_OBJECTFLIP
	player.mo.eflags = $ & ~MFE_VERTICALFLIP
	if player.mo and (player.mo.info.flags & MF_SPAWNCEILING) then
		-- place object's top at the ceiling: ceilingz - height
		player.mo.z = P_CeilingzAtPos(player.mo.x, player.mo.y, 0, 0) - player.mo.height
	else
		player.mo.z = P_FloorzAtPos(player.mo.x, player.mo.y, 0, 0)
	end
	
	saveStatus(player) -- for some fuckass reason I have to save this again RIGHT after the player spawns because srb2 CAN'T comprehend having variables not be a live reference to eachother
end)


local typeHandlers = {
	teleport = function(usedLine, whatIs, plyrmo)
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

	print("Activating " .. tostring(whatIs.type) .. " thinker with line action " .. tostring(lineSpecial) .. "!")

	if typeHandlers[whatIs.type] then
		typeHandlers[whatIs.type](usedLine, whatIs, mobj)
	else
		for sector in sectors.tagged(usedLine.tag) do
			DOOM_AddThinker(sector, whatIs)
		end
	end

	if not doom.lineActions[lineSpecial].repeatable then
		doom.linespecials[usedLine] = 0
	end
end, MT_PLAYER)

addHook("ShouldDamage", function(mobj, inf, src, dmg, dt)
	if dt == DMG_CRUSHED and not (inf or src) then return false end
end)