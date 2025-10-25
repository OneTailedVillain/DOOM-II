local function warn(warning)
	print("\x82WARNING:\x80 " .. tostring(warning))
end

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

rawset(_G, "DefineDoomActor", function(name, objData, stateData)
    local up     = name:upper()
    local prefix = "DOOM_" .. up

    -- build the list of all the globals we need
    local needed = { "MT_"..prefix }
    for stateKey, frames in pairs(stateData) do
        local stU = stateKey:upper()
        for i=1,#frames do
            needed[#needed+1] = string.format("S_%s_%s%d", prefix, stU, i)
        end
    end

    -- free and capture the slots
---@diagnostic disable-next-line: deprecated
    local slots = SafeFreeSlot( unpack(needed) )

    -- 3) fill mobjinfo using slots[...] and the MT_'s object data
    local MT = slots["MT_"..prefix]
    mobjinfo[MT] = {
		spawnstate   = objData.spawnstate or slots["S_"..prefix.."_STAND1"],
		spawnhealth  = objData.health,
		seestate     = objData.seestate or slots["S_"..prefix.."_CHASE1"] or slots["S_"..prefix.."_STAND1"],
		seesound     = objData.seesound,
		painsound    = objData.painsound,
		deathsound   = objData.deathsound,
		attacksound  = objData.attacksound,
		missilestate = objData.missilestate or slots["S_"..prefix.."_MISSILE1"] or slots["S_"..prefix.."_ATTACK1"],
		meleestate   = objData.meleestate or slots["S_"..prefix.."_MELEE1"] or slots["S_"..prefix.."_ATTACK1"],
		painstate    = objData.painstate or slots["S_"..prefix.."_PAIN1"] or slots["S_"..prefix.."_CHASE1"] or slots["S_"..prefix.."_STAND1"],
		deathstate   = objData.deathstate or slots["S_"..prefix.."_DIE1"] or slots["S_"..prefix.."_GIB1"],
		xdeathstate  = objData.xdeathstate or slots["S_"..prefix.."_GIB1"] or slots["S_"..prefix.."_DIE1"],
		speed        = (objData.speed or 0)   * FRACUNIT,
		radius       = (objData.radius or 0)  * FRACUNIT,
		height       = (objData.height or 0)  * FRACUNIT,
		mass         = objData.mass,
        reactiontime = objData.reactiontime or 8,
        dispoffset   = 0,
        damage       = objData.damage or 0,
        raisestate   = S_NULL,
		painchance   = objData.painchance,
		activesound  = objData.activesound,
		doomednum    = objData.doomednum or -1,
		flags        = objData.flags or MF_ENEMY|MF_SOLID|MF_SHOOTABLE,
    }

    -- VSCode doesn't seem to realize that field injection is only IMpossible when you do it like the above!!
---@diagnostic disable-next-line: inject-field
	mobjinfo[MT].doomflags = objData.doomflags

    -- 4) fill states[] the same way
    for stateKey, frames in pairs(stateData) do
        local stU = stateKey:upper()
        for i, f in ipairs(frames) do
            local thisName = string.format("S_%s_%s%d", prefix, stU, i)
            local nextName  = f.next
                and string.format("S_%s_%s%d", prefix, f.next:upper(), tonumber(f.nextframe) or 1)
                or frames[i+1] 
                    and string.format("S_%s_%s%d", prefix, stU, i+1)
                    or "S_NULL"

			local frame = f.frame
			if ((objData.doomflags or 0) & DF_SHADOW) then
				frame = $|FF_MODULATE
			end

			local nextstate
			if nextName == "S_NULL" then
				nextstate = S_NULL
			else
				nextstate = slots[nextName] or S_NULL
				if nextstate == S_NULL and not (nextName == "S_NULL") then
					print("DefineDoomActor: missing slot for nextName:", nextName)
				end
			end

			states[ slots[thisName] ] = {
				sprite    = f.sprite ~= nil and f.sprite or objData.sprite,
				frame     = frame,
				tics      = f.tics,
				action    = f.action,
				var1      = f.var1,
				var2      = f.var2,
				nextstate = nextstate
			}
        end
    end

	addHook("MobjThinker", function(mobj)
		if mobj.z < mobj.subsector.sector.floorheight then
			P_MoveOrigin(mobj, mobj.x, mobj.y, mobj.subsector.sector.floorheight)
		end
		local mdoom = mobj.doom
		if mobj.tics ~= -1 then return end
		if not (mobj.doom.flags & DF_COUNTKILL) then return end
		if not doom.respawnmonsters then return end
		mobj.movecount = ($ or 0) + 1
		if mobj.movecount < 12*TICRATE then return end
		if leveltime & 31 then return end
		if DOOM_Random() > 4 then return end
		local new = P_SpawnMobj(mobj.spawnpoint.x*FRACUNIT, mobj.spawnpoint.y*FRACUNIT, 0, mobj.type)
        local spawnz = P_FloorzAtPos(mobj.spawnpoint.x*FRACUNIT, mobj.spawnpoint.y*FRACUNIT, 0, 0)
        local new = P_SpawnMobj(mobj.spawnpoint.x*FRACUNIT, mobj.spawnpoint.y*FRACUNIT, spawnz, mobj.type)
        P_SpawnMobj(mobj.spawnpoint.x*FRACUNIT, mobj.spawnpoint.y*FRACUNIT, spawnz, MT_DOOM_TELEFOG)
        mobj.state = S_TELEFOG1
        mobj.type = MT_DOOM_TELEFOG
		new.angle = FixedAngle(mobj.spawnpoint.angle*FRACUNIT)
	end, MT)

	addHook("MobjDeath", function(target, inflictor, source, damage, damagetype)
		if not (target.doom.flags & DF_COUNTKILL) then return end
		doom.kills = ($ or 0) + 1
	end, MT)

	addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
		local attacker = inflictor or source

		if inflictor != source or (source.type != MT_DOOM_BULLET) or (source.type != MT_DOOM_LOSTSOUL) then
			if inflictor.target and (
				inflictor.target.type == target.type
			) or ( (inflictor.target.type == MT_DOOM_HELLKNIGHT and target.type == MT_DOOM_BARONOFHELL)
				  or (inflictor.target.type == MT_DOOM_BARONOFHELL and target.type == MT_DOOM_HELLKNIGHT) ) then
				return true
			end
		end
		if damage == 0 then return end
		DOOM_DamageMobj(target, inflictor, source, damage, damagetype)
		return true
	end, MT)
end)

local function maybeAddToRespawnTable(mo)
	if (mo.doom.flags & DF_DM2RESPAWN) then
		table.insert(doom.torespawn, {
			time = leveltime,
			x = mo.x,
			y = mo.y,
			z = mo.z,
			type = mo.type,
		})
	end
end

rawset(_G, "DefineDoomItem", function(name, objData, stateFrames, onPickup)
    local up     = name:upper()
    local prefix = "DOOM_" .. up

    -- needed slots: one MT and one S_ per frame
    local needed = { "MT_"..prefix }
    for i = 1, #stateFrames do
        needed[#needed+1] = string.format("S_%s_%d", prefix, i)
    end

    local slots = SafeFreeSlot(unpack(needed))
    local MT = slots["MT_"..prefix]

    -- first state name (for looping)
    local firstStateName = string.format("S_%s_1", prefix)

    mobjinfo[MT] = {
        spawnstate  = slots[firstStateName],
        spawnhealth  = objData.health or 0,
        radius       = (objData.radius or 16) * FRACUNIT,
        height       = (objData.height or 16) * FRACUNIT,
        mass         = objData.mass or 100,
        doomednum    = objData.doomednum or -1,
        speed        = objData.speed or 0,
        flags        = objData.flags or MF_SPECIAL,
        activesound  = objData.activesound,
        painsound    = objData.painsound,
        deathsound   = objData.deathsound,
        sprite       = objData.sprite,
        seestate     = objData.seestate,
        seesound     = objData.seesound,
        reactiontime = objData.reactiontime,
    }

    mobjinfo[MT].doomflags = objData.doomflags

	if onPickup then
		addHook("TouchSpecial", function(mo, toucher)
			-- Always call the original onPickup callback
			local res = onPickup(mo, toucher)

			-- Check for DF_COUNTITEM
			if (res == nil or res == false) and mo and mo.doom then
				maybeAddToRespawnTable(mo)
				toucher.player.doom.bonuscount = ($ or 0) + 6
				if mo.doom.flags & DF_COUNTITEM then
					if (mo.doom and mo.doom.flags and (mo.doom.flags & DF_DROPPED)) then return res end
					doom.items = $ + 1
				end
			end

			return res
		end, MT)
	end

    -- fill states and make them loop (last -> first)
    for i, frame in ipairs(stateFrames) do
        local thisName = string.format("S_%s_%d", prefix, i)
        local nextSlot
        if i < #stateFrames then
            nextSlot = slots[string.format("S_%s_%d", prefix, i + 1)]
        else
            -- loop back to first state
            nextSlot = slots[firstStateName]
        end
		local thisSlot = slots[thisName]

        states[thisSlot] = {
            sprite    = frame.sprite != nil and frame.sprite or objData.sprite,
            frame     = (type(frame) == "table" and frame.frame) and tonumber(frame.frame),
            tics      = (type(frame) == "table" and frame.tics) and tonumber(frame.tics),
            nextstate = nextSlot or S_NULL,
        }
    end
end)

rawset(_G, "DefineDoomDeco", function(name, objData, stateFrames)
    local up     = name:upper()
    local prefix = "DOOM_" .. up

    -- needed slots: one MT and one S_ per frame
    local needed = { "MT_"..prefix }
    for i = 1, #stateFrames do
        needed[#needed+1] = string.format("S_%s_%d", prefix, i)
    end

    local slots = SafeFreeSlot(unpack(needed))
    local MT = slots["MT_"..prefix]

    -- first state name (for looping)
    local firstStateName = string.format("S_%s_1", prefix)

    -- minimal mobjinfo for an item
    mobjinfo[MT] = {
        spawnstate  = slots[firstStateName],
        spawnhealth = objData.health or 0,
        radius      = (objData.radius or 0) * FRACUNIT,
        height      = (objData.height or 0) * FRACUNIT,
        mass        = objData.mass or 100,
        doomednum   = objData.doomednum or -1,
        speed       = 0,
        flags       = objData.flags and objData.flags|MF_SCENERY or MF_SCENERY,
        activesound = objData.activesound,
        painsound   = objData.painsound,
        deathsound  = objData.deathsound,
        sprite      = objData.sprite,
    }

    mobjinfo[MT].doomflags = objData.doomflags

    -- fill states and make them loop (last -> first)
    for i, frame in ipairs(stateFrames) do
        local thisName = string.format("S_%s_%d", prefix, i)
        local nextSlot
        if i < #stateFrames then
            nextSlot = slots[string.format("S_%s_%d", prefix, i + 1)]
        else
            -- loop back to first state
            nextSlot = slots[firstStateName]
        end
		local thisSlot = slots[thisName]

        states[thisSlot] = {
            sprite    = frame.sprite != nil and frame.sprite or objData.sprite,
            frame     = (type(frame) == "table" and frame.frame) and tonumber(frame.frame),
            tics      = (type(frame) == "table" and frame.tics) and tonumber(frame.tics),
            nextstate = nextSlot or S_NULL,
        }
    end
end)

local function P_CheckMissileSpawn(th)
    if not th then return end
    -- randomize tics slightly
/*
	-- FIXME: What is going wrong to make this not function properly?
    th.tics = th.tics - (DOOM_Random() & 3)
    if th.tics < 1 then
        th.tics = 1
    end

    -- nudge forward a little so an angle can be computed
	P_SetOrigin(th, 
    th.x + (th.momx >> 1),
    th.y + (th.momy >> 1),
    th.z + (th.momz >> 1))

    -- if missile is immediately blocked, explode
    if not P_TryMove(th, th.x, th.y, true) then
        P_ExplodeMissile(th)
    end
*/
end

rawset(_G, "DOOM_ResolveString", function(text)
	if type(text) ~= "string" then
        error("DOOM_ResolveString: Invalid type passed (string expected, got " .. type(text) .. ")")
	end

    -- Check if it looks like an index and resolve it
    if text:sub(1, 1) == "$" and #text > 1 then
        local index = text:sub(2)
        if index:match("^[%w_]+$") then
            -- Prefer dehacked strings if present, otherwise fall back to base doom.strings
            if doom.dehacked and type(doom.dehacked.strings) == "table" and doom.dehacked.strings[index] then
                return doom.dehacked.strings[index]
            elseif doom.strings and doom.strings[index] then
                return doom.strings[index]
            else
                warn("DOOM string index not found in doom.dehacked.strings or doom.strings: " .. index)
                -- Keep original text as fallback (literal "$index")
                return text
            end
        else
            warn("DOOM string index invalid format: " .. tostring(index))
            -- Keep original text as fallback
            return text
        end
    end

    -- Return original text if not an index format
    return text
end)

rawset(_G, "DOOM_SpawnMissile", function(source, dest, type)
    if not (source and dest) then return nil end

    local th = P_SpawnMobj(source.x,
                           source.y,
                           source.z + 4*8*FRACUNIT,
                           type)
    if not th then return nil end

    if th.info.seesound then
        S_StartSound(th, th.info.seesound)
    end

    th.target = source

    -- angle to target
    local an = R_PointToAngle2(source.x, source.y, dest.x, dest.y)

    -- fuzzy player (shadow)
    if (dest.doom.flags & DF_SHADOW) ~= 0 then
        an = $ + (DOOM_Random() - DOOM_Random()) << 20
    end

    th.angle = an

    th.momx = FixedMul(th.info.speed, cos(an))
    th.momy = FixedMul(th.info.speed, sin(an))

    local dist = P_AproxDistance(dest.x - source.x,
                                 dest.y - source.y)
    dist = dist / th.info.speed

    if dist < 1 then dist = 1 end

    th.momz = (dest.z - source.z) / dist

    P_CheckMissileSpawn(th)
    return th
end)

rawset(_G, "P_GetSupportsForSkin", function(player)
	return doom.charSupport[player.mo.skin]
end)

rawset(_G, "P_GetMethodsForSkin", function(player)
	local support = P_GetSupportsForSkin(player)
	return support.methods
end)

rawset(_G, "DOOM_GetWeaponDef", function(player)
	return doom.weapons[player.doom.curwep]
end)

rawset(_G, "DOOM_IsExiting", function()
	return doom.intermission or doom.textscreen.active
end)

-- TODO: monsters CANNOT in-fight Archviles!
rawset(_G, "DOOM_DamageMobj", function(target, inflictor, source, damage, damagetype, minhealth)
    if not target or not target.valid then return end
    damage = inflictor and inflictor.doom.damage or damage
	
	
    local player = target.player
    
    if player then
        -- Player-specific handling
		if DOOM_IsExiting() then return end
        local funcs = P_GetMethodsForSkin(player)
        funcs.damage(target, damage, source, inflictor, damagetype, minhealth)
        player.doom.damagecount = (player.doom.damagecount or 0) + damage
        if player.doom.damagecount > 100 then player.doom.damagecount = 100 end
        player.doom.attacker = source
    else
        -- Non-player (monster) handling - DOOM-style
        if not (target.flags & MF_SHOOTABLE) or target.doom.health <= 0 then
            return
        end

        -- Handle skullfly
        if target.flags2 & MF2_SKULLFLY then
            target.momx, target.momy, target.momz = 0, 0, 0
        end

        -- Apply thrust/knockback
        if inflictor and not (target.flags & MF_NOCLIP) and
           (not source or not source.player or source.player.curwep ~= "chainsaw") then
            local ang = R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y)
            local thrust = damage * (FRACUNIT >> 3) * 100 / target.info.mass

            -- Make fall forwards sometimes
            if damage < 40 and damage > target.doom.health and 
               target.z - inflictor.z > 64*FRACUNIT and P_RandomChance(FRACUNIT/2) then
                ang = $ + ANGLE_180
                thrust = $ * 4
            end

            target.momx = $ + FixedMul(thrust, cos(ang))
            target.momy = $ + FixedMul(thrust, sin(ang))
        end

        -- Apply damage
        target.doom.health = $ - damage

        if target.doom.health <= 0 then
            -- Handle death
            target.flags = $ & ~(MF_SHOOTABLE|MF_FLOAT)
			target.flags2 = $ & ~MF2_SKULLFLY
            if target.type ~= MT_DOOM_LOSTSOUL or target.type ~= MT_DOOM_KEEN then
                target.flags = $ & ~MF_NOGRAVITY
            end
            target.doom.flags = $ | DF_CORPSE|DF_DROPOFF
            target.height = $ >> 2

            -- Handle kill counting
            if source and source.player then
                if target.doom.flags & DF_COUNTKILL then
                    source.player.doom.killcount = ($ or 0) + 1
                end
            elseif not netgame and (target.doom.flags & DF_COUNTKILL) then
                players[0].doom.killcount = ($ or 0) + 1
            end

            -- Set death state
            if target.doom.health < -target.info.spawnhealth and target.info.xdeathstate then
                target.state = target.info.xdeathstate
            else
                target.state = target.info.deathstate
            end

            target.tics = $ - (DOOM_Random() & 3)
            if target.tics < 1 then target.tics = 1 end

			local itemDropList = {
				[MT_DOOM_ZOMBIEMAN] = MT_DOOM_CLIP,
				[MT_DOOM_SSGUARD] = MT_DOOM_CLIP,
				[MT_DOOM_CHAINGUNNER] = MT_DOOM_CHAINGUN,
				[MT_DOOM_SHOTGUNNER] = MT_DOOM_SHOTGUN,
			}

            -- Handle item drops
            local itemtype = itemDropList[target.type]

            if itemtype then
                local mo = P_SpawnMobj(target.x, target.y, ONFLOORZ, itemtype)
                mo.doom.flags = $ | DF_DROPPED
            end
        else
            -- Handle pain
            if DOOM_Random() < target.info.painchance and not (target.flags2 & MF2_SKULLFLY) then
                target.doom.flags = $ | DF_JUSTHIT
				if target.info.painstate then
					target.state = target.info.painstate
				end
            end

            target.reactiontime = 0

            -- Alert monster to attacker
            if (not target.threshold or target.type == MT_DOOM_ARCHVILE ) and 
               source and source != target and source.type != MT_DOOM_ARCHVILE  then
                target.target = source
                target.threshold = 100 --BASETHRESHOLD
                if target.state == states[target.info.spawnstate] and 
					target.info.seestate != S_NULL then
					target.state = target.info.painstate
                end
            end
        end
    end
end)

rawset(_G, "DOOM_Freeslot", function(...)
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
end)

rawset(_G, "DOOM_SetState", function(player, state, frame)
	state = state or "idle"
	frame = frame or 1
	if not player then return end
	player.doom.wepstate = state
	player.doom.wepframe = frame
	local wepDef = DOOM_GetWeaponDef(player)
	if not wepDef then error("Invalid weapon " .. tostring(player.doom.curwep) .. "!") end
	wepDef = $.states
	if not wepDef then error("No 'states' table for current weapon!") end
	wepDef = $[state]
	if not wepDef then error("Invalid state " .. tostring(state) .. "!") end
	wepDef = $[frame]
	if not wepDef then error("Invalid frame " .. tostring(state) .. " " .. tostring(frame) .. "!") end
	player.doom.weptics = wepDef.tics
	if wepDef.action then
		wepDef.action(player.mo, wepDef.var1, wepDef.var2, DOOM_GetWeaponDef(player))
	end
end)

rawset(_G, "DOOM_FireWeapon", function(player)
	local funcs = P_GetMethodsForSkin(player)
	local curWep = DOOM_GetWeaponDef(player)
	local curAmmo = funcs.getCurAmmo(player)

	if type(curAmmo) != "boolean" then
		if curAmmo - curWep.shotcost < 0 then return end
	end

	DOOM_SetState(player, "attack", 1)
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

rawset(_G, "DOOM_AddThinker", function(any, thinkingType)
    if doom.thinkers[any] ~= nil then return end -- Emulate DOOM disallowing multiple thinkers for one sector
    if thinkingType == nil then return end
	-- clone the lineAction data so each sector gets its own independent state
    local data = deepcopy(thinkingType)
	print("adding " .. tostring(data.type) .. " thinker!")
    doom.thinkers[any] = data
end)

rawset(_G, "DOOM_SwitchWeapon", function(player, wepname, force)
	if not (player and player.valid) then return end
	if not player.doom then return end
	if not player.doom.weapons[wepname] then return end -- player must own it

	-- Find which slot + order this weapon belongs to
	for slot, weplist in pairs(doom.weaponnames) do
		for order, w in ipairs(weplist) do
			if w == wepname then
				if not force then
					-- Emulate manual switch
					player.doom.curwepcat = slot
					player.doom.curwepslot = order
					player.doom.wishwep = wepname
					player.doom.switchingweps = true
					player.doom.switchtimer = 0
				else
					player.doom.curwepcat = slot
					player.doom.curwepslot = order
					player.doom.curwep = wepname
				end
				return true
			end
		end
	end

	return false -- weapon exists but wasn’t found in any slot (bad config?)
end)

rawset(_G, "DOOM_DoAutoSwitch", function(player, force)
	local candidates = {}
	local funcs = P_GetMethodsForSkin(player)
	local weapon = DOOM_GetWeaponDef(player)
	local curAmmo = funcs.getCurAmmo(player)
	if not force then
		if type(curAmmo) == "boolean" then return end
		if curAmmo - weapon.shotcost >= 0 then return end
	end
	for name, definition in pairs(doom.weapons) do
        local funcs = P_GetMethodsForSkin(player)
		curAmmo = funcs.getAmmoFor(player, definition.ammotype)

		if not player.doom.weapons[name] then continue end
		if curAmmo - definition.shotcost < 0 then continue end

		table.insert(candidates, {
		priority = definition.priority or 1000,
		name = name
		})
	end
	table.sort(candidates, function(a, b)
		return a.priority < b.priority
	end)
	return DOOM_SwitchWeapon(player, candidates[1].name)
end)

local function DOOM_WhatInter()
	if doom.isdoom1 then
		return "INTER"
	else
		return "DM2INT"
	end
end

rawset(_G, "saveStatus", function(player)
	player.doom = $ or {}
	player.mo.doom = $ or {}
	player.doom.laststate = {}
	player.doom.laststate.ammo = deepcopy(player.doom.ammo)
	player.doom.laststate.weapons = deepcopy(player.doom.weapons)
	player.doom.laststate.oldweapons = deepcopy(player.doom.oldweapons)
	player.doom.laststate.curwep = deepcopy(player.doom.curwep)
	player.doom.laststate.curwepslot = deepcopy(player.doom.curwepslot)
	player.doom.laststate.curwepcat = deepcopy(player.doom.curwepcat)
	player.doom.laststate.health = deepcopy(player.mo.doom.health)
	player.doom.laststate.armor = deepcopy(player.mo.doom.armor)
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
end)

local function printTable(data, prefix)
	prefix = prefix or ""
	if type(data) == "table"
		for k, v in pairs(data or {}) do
			local key = prefix .. k
			if type(v) == "table" then
				CONS_Printf(server, "key " .. key .. " = a table:")
				printTable(v, key .. ".")
			else
				CONS_Printf(server, "key " .. key .. " = " .. tostring(v))
			end
		end
	else
		CONS_Printf(server, data)
	end
end

rawset(_G, "DOOM_StartTextScreen", function(text)
    -- Input validation
    if type(text) ~= "table" then
        error("DOOM_StartTextScreen: Invalid type passed (table expected, got " .. type(text) .. ")")
    end
	if not text.text then
		error("DOOM_StartTextScreen: No 'text' key in table argument")
	end
	if not text.bg then
		error("DOOM_StartTextScreen: No 'bg' key in table argument")
	end
	if type(text.text) ~= "string" then
		error("DOOM_StartTextScreen: Invalid type in key 'text' (string expected, got " .. type(text.text) .. ")")
	end
	if type(text.bg) ~= "string" then
		error("DOOM_StartTextScreen: Invalid type in key 'bg' (string expected, got " .. type(text.text) .. ")")
	end

    local isIndex = false
    local content = DOOM_ResolveString(text.text)

    doom.textscreen.active = true
    doom.textscreen.elapsed = 0
    doom.textscreen.text = content
	doom.textscreen.bg = text.bg
    if doom.isdoom1 then
        S_ChangeMusic("victor")
    else
        S_ChangeMusic("read_m")
    end
end)

rawset(_G, "DOOM_ExitLevel", function()
	if doom.intermission then return end
	local targetTextScreen = doom.textscreenmaps[gamemap]
	if doom.textscreenmaps[gamemap] and doom.isdoom1 then
		for player in players.iterate do
			player.doom.laststate = {}
		end
		DOOM_StartTextScreen(targetTextScreen)
	else
		if doom.isdoom1 then
			doom.animatorOffsets = {}
			for i = 1, 10 do
				doom.animatorOffsets[i] = DOOM_Random()
			end
		end
		for player in players.iterate() do
			player.doom.intstate = 1
			player.doom.intpause = TICRATE
			player.doom.wintime = leveltime
			saveStatus(player)
		end
		doom.intermission = true
		S_ChangeMusic(DOOM_WhatInter())
	end

	for mobj in mobjs.iterate() do
		mobj.flags = $ | MF_NOTHINK
		S_StopSound(mobj)
	end
end)

rawset(_G, "DOOM_NextLevel", function()
	local nextLev
	local targetTextScreen = doom.textscreenmaps[gamemap]
	if targetTextScreen and not doom.isdoom1 and not doom.textscreen.active and targetTextScreen.secret == doom.didSecretExit then
		DOOM_StartTextScreen(targetTextScreen)
		return
	end
	if doom.didSecretExit then
		nextLev = mapheaderinfo[gamemap].nextsecretlevel or doom.secretExits[gamemap]
	else
		nextLev = mapheaderinfo[gamemap].nextlevel or gamemap + 1
	end
	G_SetCustomExitVars(nextLev, 1, GT_DOOM, true)
	G_ExitLevel()
end)

rawset(_G, "DOOM_DoMessage", function(player, string)
	player.doom.messageclock = TICRATE*5
	player.doom.message = DOOM_ResolveString(string)
	if player.doom.message != string then
		player.doom.message = $:upper()
	end
end)

rawset(_G, "DOOM_LookForPlayers", function(actor, allaround)
    if not actor or not actor.subsector or not actor.subsector.sector then return false end

    actor.lastlook = actor.lastlook or 0

    for player in players.iterate do
        -- Skip invalid player objects
        if not player or not player.mo or not player.mo.doom then
            continue
        end

        -- Skip dead players
        if player.mo.doom.health <= 0 then
            continue
        end

        -- Skip if enemy can't see the player
        if not P_CheckSight(actor, player.mo) then
            continue
        end

        if not allaround then
            local an = (R_PointToAngle2(actor.x, actor.y, player.mo.x, player.mo.y) - actor.angle)
			an = AngleFixed($)
			if an > 90*FRACUNIT and an < 270*FRACUNIT then
				local dist = R_PointToDist2(player.mo.x, player.mo.y, actor.x, actor.y)
				if dist > MELEERANGE then
					continue
				end
			end
        end

        actor.target = player.mo
        return true
    end

    return false
end)

rawset(_G, "DOOM_Random", function()
    doom.prndindex = (doom.prndindex+1)&0xff;
    return doom.rndtable[doom.prndindex + 1];
end)