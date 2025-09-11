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

			if myHealth - pd.oldhealth > ST_MUCHPAIN then
				pd.facecount = ST_TURNCOUNT
				pd.faceindex = ST_calcPainOffset(plyr) + ST_OUCHOFFSET
			else
				local badguyangle = R_PointToAngle2(
					plyr.mo.x, plyr.mo.y,
					pd.attacker and pd.attacker.x or 0, pd.attacker and pd.attacker.y or 0
				)

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
	player.doom = $ or {}
	ST_updateFaceWidget(player)
	player.doom.bonuscount = ($ or 1) - 1
	player.doom.damagecount = ($ or 1) - 1
	if not player.doom.damagecount then player.doom.attacker = nil end
end)

addHook("PlayerThink", function(player)
	if (player.cmd.buttons & BT_JUMP) then
		if doom.issrb2 then
			if P_IsObjectOnGround(player.mo) then
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

addHook("PlayerThink", function(player)
	if (player.mo.eflags & MFE_JUSTHITFLOOR) then
		if (player.doom.lastmomz or 0) <= doom.defaultgravity*-8 then
			S_StartSound(player.mo, sfx_oof)
			--player.deltaviewheight = player.doom.lastmomz>>3
		end
	else
		player.doom.lastmomz = player.mo.momz
	end

	if player.doom.powers[pw_strength] then
		player.doom.powers[pw_strength] = $ + 1
	end

	player.hl1wepbob = FixedMul(player.mo.momx, player.mo.momx) + FixedMul(player.mo.momy, player.mo.momy)
	player.hl1wepbob = player.hl1wepbob >> 2
	if player.hl1wepbob > FRACUNIT*16 then
		player.hl1wepbob = FRACUNIT*16
	end

	player.doom.weptics = ($ or 1) - 1
	-- print("tics = " .. player.doom.weptics, "state = " .. player.doom.wepstate, "frame = " .. player.doom.wepframe)
	if player.doom.weptics == 0 then
		player.doom.wepframe = ($ or 1) + 1
		local nextDef = DOOM_GetWeaponDef(player).states[player.doom.wepstate][player.doom.wepframe]
		if nextDef == nil then
			DOOM_SetState(player)
		else
			DOOM_SetState(player, player.doom.wepstate, player.doom.wepframe)
		end
	end
end)

addHook("PlayerThink", function(player)
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

	if (player.cmd.buttons & BT_WEAPONMASK) and not (player.doom.switchingweps or player.doom.switchtimer) then
		local slot = player.cmd.buttons & BT_WEAPONMASK
		local wepsInSlot = doom.weaponnames[slot]

		-- Abort if slot doesn't exist or has no owned weapons
		local firstOwnedOrder = firstAvailableInSlot(player, slot)
		if not firstOwnedOrder then
			return -- deny switch entirely
		end

		if slot ~= player.doom.curwepcat then
			-- Switching to new slot: pick lowest order weapon
			player.doom.curwepcat = slot
			player.doom.curwepslot = firstOwnedOrder

		elseif #wepsInSlot > 1 then
			-- Cycling within same slot
			local nextOrder = (player.doom.curwepslot % #wepsInSlot) + 1
			for i = 1, #wepsInSlot do
				if player.doom.weapons[wepsInSlot[nextOrder]] then
					player.doom.curwepslot = nextOrder
					break
				end
				nextOrder = (nextOrder % #wepsInSlot) + 1
			end
		end

		player.doom.wishwep = wepsInSlot[player.doom.curwepslot]
		player.doom.switchingweps = true
	end

	if player.doom.switchingweps then
		player.doom.switchtimer = ($ or 0) + 1
		if player.doom.switchtimer >= 16 then
			player.doom.curwep = player.doom.wishwep
			player.doom.wishwep = nil
			player.doom.switchingweps = false
		end
	elseif player.doom.switchtimer then
		player.doom.switchtimer = $ - 1
	end

	if (player.cmd.buttons & BT_ATTACK) and player.doom.wepstate == "idle" then
		DOOM_FireWeapon(player)
	end
end)

addHook("PlayerThink", function(player)
	if doom.issrb2 then
		player.mo.doom.armor = leveltime/TICRATE
	end

	if player.mo.tele then
		local tel = player.mo.tele
		P_SetOrigin(player.mo, tel.x, tel.y, tel.z)
		player.mo.tele = nil
	end

	if player.mo.z != player.mo.subsector.sector.floorheight then return end

	-- print(doom.sectorspecials[player.mo.subsector.sector])
	local funcs = P_GetMethodsForSkin(player)

	if doom.sectorspecials[player.mo.subsector.sector] == 16 then
		if not (leveltime & 31) then
			DOOM_DamageMobj(player.mo, nil, nil, 20)
		end
	elseif doom.sectorspecials[player.mo.subsector.sector] == 5 then
		if not (leveltime & 31) then
			DOOM_DamageMobj(player.mo, nil, nil, 10)
		end
	elseif doom.sectorspecials[player.mo.subsector.sector] == 7 then
		if not (leveltime & 31) then
			DOOM_DamageMobj(player.mo, nil, nil, 5)
		end
	elseif doom.sectorspecials[player.mo.subsector.sector] == 4 then
		if not (leveltime & 31) then
			DOOM_DamageMobj(player.mo, nil, nil, 20)
		end
	elseif doom.sectorspecials[player.mo.subsector.sector] == 11 then
		if not (leveltime & 31) then
			DOOM_DamageMobj(player.mo, nil, nil, 20, 0, 1)
		end
		if funcs.getHealth(player) <= 10 then
			DOOM_ExitLevel()
		end
	elseif doom.sectorspecials[player.mo.subsector.sector] == 9 then
		doom.sectorspecials[player.mo.subsector.sector] = 0
		doom.secrets = ($ or 0) + 1
		S_StartSound(nil, sfx_secret)
	end

    local cnt = player.doom.damagecount or 0
    local bzc = 0

    if player.doom.powers[pw_strength] and player.doom.powers[pw_strength] > 0 then
        bzc = 12 - (player.doom.powers[pw_strength] >> 6)
        if bzc > cnt then
            cnt = bzc
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

local function saveStatus(player)
	player.doom = $ or {}
	player.mo.doom = $ or {}
	player.doom.laststate = {}
	player.doom.laststate.ammo = deepcopy(player.doom.ammo)
	player.doom.laststate.weapons = deepcopy(player.doom.weapons)
	player.doom.laststate.oldweapons = deepcopy(player.doom.oldweapons)
	player.doom.laststate.curwep = deepcopy(player.doom.curwep)
	player.doom.laststate.health = deepcopy(player.mo.doom.health)
	player.doom.laststate.armor = deepcopy(player.mo.doom.armor)
	player.doom.laststate.flashlight = deepcopy(player.doom.curwep)
	player.doom.laststate.pos = {
		x = deepcopy(player.mo.x),
		y = deepcopy(player.mo.y),
		z = deepcopy(player.mo.z),
	}
	player.doom.laststate.momentum = {
		x = deepcopy(player.mo.momx),
		y = deepcopy(player.mo.momy),
		z = deepcopy(player.mo.momz),
	}
	player.doom.laststate.map = deepcopy(gamemap)
end

addHook("PlayerSpawn",function(player)
	if not player.mo return end
	if consoleplayer == player then
		camera.chase = false
	end
	player.doom = $ or {}
	if player.doom.laststate and player.doom.laststate.map == gamemap then
		P_SetOrigin(player.mo, player.doom.laststate.pos.x, player.doom.laststate.pos.y, player.doom.laststate.pos.z)
		player.mo.momx = player.doom.laststate.momentum.x
		player.mo.momy = player.doom.laststate.momentum.y
		player.mo.momz = player.doom.laststate.momentum.z
	end

	local function pick(saved_val, default_val)
		return saved_val ~= nil and saved_val or default_val
	end

	local preset = {
		useinvbackups = true,
		ammo = {
			none = INT32_MIN,
			bullets = 50,
			shells = 0,
			rockets = 0,
			cells = 0,
		},
		oldweapons = {
			brassknuckles = true,
			pistol = true,
		},
		weapons = {
			brassknuckles = true,
			pistol = true,
		},
		health = 100,
		armor = 0,
		curwep = "pistol",
		curwepslot = 1,
		curwepcat = 2,
	}
	if doom.issrb2 then
		preset.health = 1
	end
	local saved  = player.doom.laststate

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
	player.doom.oldweapons = choose("oldweapons")
	player.doom.notrigger = false
	player.doom.keys = 0
	DOOM_SetState(player)

	player.mo.flags2 = $ & ~MF2_OBJECTFLIP
	player.mo.eflags = $ & ~MFE_VERTICALFLIP
	if player.mo and (player.mo.info.flags & MF_SPAWNCEILING) then
		player.mo.z = player.mo.height - P_CeilingzAtPos(player.mo.x, player.mo.y, 0, 0)
	else
		player.mo.z = P_FloorzAtPos(player.mo.x, player.mo.y, 0, 0)
	end
	
	saveStatus(player) -- for some fuckass reason I have to save this again RIGHT after the player spawns because srb2 CAN'T comprehend not having variables not be a live reference to eachother
end)

local function ActorCrossedLine(mo, line)
    local cx, cy = mo.x, mo.y
    local r = mo.radius + FRACUNIT
    local sides = {
        P_PointOnLineSide(cx, cy, line),
        P_PointOnLineSide(cx + r, cy, line),
        P_PointOnLineSide(cx - r, cy, line),
        P_PointOnLineSide(cx, cy + r, line),
        P_PointOnLineSide(cx, cy - r, line),
    }
    local first = sides[1]
    for i = 2, #sides do
        if sides[i] ~= first then
            return true
        end
    end
    return false
end


local typeHandlers = {
	teleport = function(usedLine, whatIs, plyrmo)
		if (plyrmo.flags & MF_MISSILE) then return end
		if plyrmo.reactiontime and plyrmo.reactiontime > 0 then return end
		if P_PointOnLineSide(plyrmo.x, plyrmo.y, usedLine) == 1 then return end
		-- Praying to the gods that this works
		if ActorCrossedLine(plyrmo, usedLine) then return end

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
		S_StartSound(fog, sfx_telept)

		-- fog at destination (20 units in front of exit angle)
		local destfog = P_SpawnMobj(teletarg.x + 20*cos(teletarg.angle), teletarg.y + 20*sin(teletarg.angle), plyrmo.z, MT_TFOG)
		S_StartSound(destfog, sfx_telept)
	end,
	exit = function()
		DOOM_ExitLevel()
	end
}

addHook("MobjLineCollide", function(mobj, hit)
	if mobj.player.doom.notrigger then return end
    if not mobj.player then return end -- only care about players
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
			DOOM_AddThinker(sector, whatIs)
		end
	end
end, MT_PLAYER)

addHook("ShouldDamage", function(mobj, inf, src, dmg, dt)
	if dt == DMG_CRUSHED and not (inf or src) then return false end
end)