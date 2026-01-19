---@class StateFrame
---@field sprite integer The sprite ID
---@field frame string The animation frame (e.g., "A", "B")
---@field tics integer Duration in tics
---@field action? fun(actor:mobj_t, var1:integer?, var2:integer?) Optional action function
---@field var1? integer Optional parameter 1
---@field var2? integer Optional parameter 2
---@field next? string|integer|nil Next state name (string), state ID (integer), or nil for auto-chain
---@field nextframe? integer Frame number for named next state (default 1)

---@class StateDefs
---@field [string] StateFrame[] Tables of state frames, keyed by state name

local function warn(warning)
	print("\x82WARNING:\x80 " .. tostring(warning))
end

rawset(_G, "printTable", function(data, prefix)
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
end)

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

---@param name string The object name (e.g., "Plasma")
---@param stateDefs StateDefs Table of state definitions
---@return nil
rawset(_G, "FreeDoomStates", function(name, stateDefs)
    local up     = name:upper()
    local prefix = "DOOM_" .. up

    -- Build a list of all state globals to freeslot
    local needed = {}
    for stateKey, frames in pairs(stateDefs) do
        local stU = stateKey:upper()
        for i = 1, #frames do
            needed[#needed+1] = string.format("S_%s_%s%d", prefix, stU, i)
        end
    end

    -- Freeslot all the state globals
    local slots = SafeFreeSlot(unpack(needed))

    -- Set up nextstate references properly
    for stateKey, frames in pairs(stateDefs) do
        local stU = stateKey:upper()
        for i, f in ipairs(frames) do
			local thisName = string.format("S_%s_%s%d", prefix, stU, i)

			local nextslot

			-- If user explicitly sets numeric next (like next = S_PLAY_STND)
			if type(f.next) == "number" then
				nextslot = f.next

			-- If user uses named doom-state next (like next = "move")
			elseif type(f.next) == "string" then
				local nextName = string.format(
					"S_%s_%s%d",
					prefix,
					f.next:upper(),
					tonumber(f.nextframe) or 1
				)
				nextslot = slots[nextName]

			-- Otherwise: fall back to automatic chaining
			elseif frames[i+1] then
				local nextName = string.format("S_%s_%s%d", prefix, stU, i+1)
				nextslot = slots[nextName]
			end

			f.nextstate = nextslot or S_NULL

			states[ slots[thisName] ] = {
				sprite    = f.sprite,
				frame     = f.frame,
				tics      = f.tics,
				action    = f.action,
				var1      = f.var1,
				var2      = f.var2,
				nextstate = f.nextstate
			}
        end
    end
end)

-- TODO: Port state freeslotting to FreeDoomStates
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
---@diagnostic disable-next-line: inject-field
	mobjinfo[MT].doomname = name

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

        local space = abs(mobj.floorz - mobj.ceilingz)
        if space < mdoom.height then
            mobj.height = max(space, 0)
        else
            mobj.height = mdoom.height
        end

		if mobj.tics ~= -1 then return end
		if not (mobj.doom.flags & DF_COUNTKILL) then return end
		if not (doom.respawnmonsters or doom.gameskill == 5) then return end
		mobj.movecount = ($ or 0) + 1
		if mobj.movecount < 12*TICRATE then return end
		if leveltime & 31 then return end
		if DOOM_Random() > 4 then return end
		local spawnpoint = mobj.doom.spawnpoint
        local spawnz = P_FloorzAtPos(spawnpoint.x, spawnpoint.y, INT32_MIN, 0)
        local new = P_SpawnMobj(spawnpoint.x, spawnpoint.y, spawnz, mobj.type)
        P_SpawnMobj(spawnpoint.x, spawnpoint.y, spawnz, MT_DOOM_TELEFOG)
        mobj.state = S_TELEFOG1
        --mobj.type = MT_DOOM_TELEFOG
		mobj.flags = $ & ~(MF_SHOOTABLE|MF_SOLID)
		mobj.target = nil
		new.angle = spawnpoint.angle
	end, MT)

	addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
		local attacker = source or inflictor

		if damage == 0 then return end
		DOOM_DamageMobj(target, inflictor, source, damage, damagetype)
		return true
	end, MT)
end)

local function maybeAddToRespawnTable(mo)
	if netgame and gametype != GT_DOOMDM and (mo.doom.flags & DF_DM2RESPAWN) then
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
					doom.items = ($ or 0) + 1
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
			action    = (type(frame) == "table" and frame.action) and tonumber(frame.action),
			var1      = (type(frame) == "table" and frame.var1) and tonumber(frame.var1),
			var2      = (type(frame) == "table" and frame.var2) and tonumber(frame.var2),
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
	if not player.mo then return {} end
	return doom.charSupport[player.mo.skin]
end)

rawset(_G, "P_GetMethodsForSkin", function(player)
	if not player.mo then return {} end
	local support = P_GetSupportsForSkin(player)
	return support.methods
end)

rawset(_G, "DOOM_GetWeaponDef", function(player)
	return doom.weapons[player.doom.curwep]
end)

rawset(_G, "DOOM_IsExiting", function()
	return doom.intermission or doom.textscreen.active
end)

rawset(_G, "DOOM_DamageMobj", function(target, inflictor, source, damage, damagetype, minhealth)
    if not target or not target.valid then return end
    damage = inflictor and inflictor.doom.damage or damage

    local player = target.player
    
    if player then
        -- Player-specific handling
		if DOOM_IsExiting() then return end
		if (player.pflags & PF_GODMODE) then return end
		if player.doom.powers[pw_invulnerability] then return end
        local funcs = P_GetMethodsForSkin(player)
		local health = funcs.getHealth(player)
		if health <= 0 then return end
		if funcs.shouldDealDamage then
			local returnVal = funcs.shouldDealDamage(target, inflictor, source, damage, damagetype, minhealth)
			if returnVal != nil and not returnVal then return end
		end

		if doom.gameskill == 1 then
			damage = damage / 2
		end

		if player.doom.dealtDamage then
			return
		end

		player.doom.dealtDamage = true
		local ok = false
		local success, err = pcall(function()
			ok = funcs.damage(target, damage, source, inflictor, damagetype, minhealth)
		end)
		player.doom.dealtDamage = false

		local health = funcs.getHealth(player)

		if health <= 0 then
			doom.doObituary(target, source, inflictor, damagetype)
		end

		if not success then
			print("Damage error:", err)
		end

        player.doom.damagecount = (player.doom.damagecount or 0) + damage
        if player.doom.damagecount > 100 then player.doom.damagecount = 100 end
        player.doom.attacker = source
		local num_rings
		if player.doom.damagecount > 5 then
			num_rings = (player.doom.damagecount / 5) + 5
		else
			num_rings = player.doom.damagecount
		end
		--print("Damage would have spawned " .. num_rings .. " rings")
    else
        -- Non-player (monster) handling - DOOM-style

		local attacker = (inflictor and inflictor.target) or source

		if inflictor != source
			and source.type != MT_DOOM_BULLETRAYCAST
			and source.type != MT_DOOM_LOSTSOUL
		then
			if attacker.type == target.type then
				return
			end

			if inflictor and inflictor.target
			and (
				(inflictor.target.type == MT_DOOM_HELLKNIGHT and target.type == MT_DOOM_BARONOFHELL)
			 or (inflictor.target.type == MT_DOOM_BARONOFHELL and target.type == MT_DOOM_HELLKNIGHT)
			) then
				return
			end
		end

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
            local thrust = damage * (FRACUNIT >> 3) * 100 / (target.info.mass or FRACUNIT)

            -- Make fall forwards sometimes
            if damage < 40 and damage > target.doom.health and 
               target.z - inflictor.z > 64*FRACUNIT and P_RandomChance(FRACUNIT/2) then
                ang = ang + ANGLE_180
                thrust = thrust * 4
            end

            target.momx = target.momx + FixedMul(thrust, cos(ang))
            target.momy = target.momy + FixedMul(thrust, sin(ang))
        end

        -- Apply damage
        target.doom.health = target.doom.health - damage
        if target.doom.health <= 0 then
            -- Handle death
            target.flags = $ & ~(MF_SHOOTABLE|MF_FLOAT)
			target.flags2 = $ & ~MF2_SKULLFLY
            if target.type ~= MT_DOOM_LOSTSOUL then
                target.flags = $ & ~MF_NOGRAVITY
            end
            target.doom.flags = $ | DF_CORPSE|DF_DROPOFF
            target.height = $ >> 2

            -- Handle kill counting
            if source and source.player then
                if target.doom.flags & DF_COUNTKILL then
                    source.player.doom.killcount = ($ or 0) + 1
					local funcs = P_GetMethodsForSkin(source.player)
					if funcs.onKill then
						funcs.onKill(source.player, target)
					end
				end
            elseif not multiplayer and (target.doom.flags & DF_COUNTKILL) then
                consoleplayer.doom.killcount = ($ or 0) + 1
				local funcs = P_GetMethodsForSkin(consoleplayer)
				if funcs.onKill then
					funcs.onKill(consoleplayer, target)
				end
            end

            -- Set death state
            if target.doom.health < -target.info.spawnhealth and target.info.xdeathstate then
                target.state = target.info.xdeathstate
            else
                target.state = target.info.deathstate
            end

			if not (target and target.valid) then return end

            target.tics = $ - (DOOM_Random() & 3)
            if target.tics < 1 then target.tics = 1 end

            -- Handle item drops
            local itemtype = doom.dropTable[target.type]

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
	wepDef = wepDef.states
	if not wepDef then error("No 'states' table for current weapon!") end
	wepDef = wepDef[state]
	if not wepDef then error("Invalid state " .. tostring(state) .. "!") end
	wepDef = wepDef[frame]
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
	player.mo.state = S_DOOM_PLAYER_ATTACK1
end)

rawset(_G, "deepcopy", function(orig)
	local orig_type = type(orig)
	if orig_type ~= 'table' then
		return orig
	end
	local copy = {}
	for k, v in next, orig, nil do
		copy[deepcopy(k)] = deepcopy(v)
	end
	return copy
end)

doom.thinkerlist = doom.thinkerlist or {}
doom.thinkermap  = doom.thinkermap  or {}

-- Add thinker: append to numeric list and set map
rawset(_G, "DOOM_AddThinker", function(any, thinkingType)
    if not any or thinkingType == nil then return end

    -- Disallow duplicates (emulate original behavior)
    if doom.thinkermap[any] then return end

    local data = deepcopy(thinkingType)
    local entry = { key = any, data = data, active = true }
    local idx = #doom.thinkerlist + 1
    doom.thinkerlist[idx] = entry
    doom.thinkermap[any] = idx
end)

-- Stop thinker: mark inactive and remove mapping
rawset(_G, "DOOM_StopThinker", function(any)
    if not any then return end
    local idx = doom.thinkermap[any]
    if not idx then return end
    local entry = doom.thinkerlist[idx]
    if entry then
        entry.active = false      -- mark for skipping
        entry.data   = nil        -- free payload
        entry.key    = nil
    end
end)

-- Compatibility proxy so old code can still do doom.thinkers[any] = nil
-- and doom.thinkers[any] to read. Important: don't rely on pairs() on this table.
do
    local proxy = {}
    local mt = {}

    mt.__index = function(_, any)
        local idx = doom.thinkermap[any]
        if idx then
            return doom.thinkerlist[idx] and doom.thinkerlist[idx].data or nil
        end
        return nil
    end

    mt.__newindex = function(_, any, val)
        -- writing nil -> means "stop thinker" (compatibility)
        if val == nil then
            DOOM_StopThinker(any)
            return
        end
        -- writing non-nil -> replace/create thinker data (rare for your code; prefer DOOM_AddThinker)
        local idx = doom.thinkermap[any]
        if idx then
            doom.thinkerlist[idx].data = val
            doom.thinkerlist[idx].active = true
            doom.thinkermap[any] = idx
        else
            -- append as new entry
            local entry = { key = any, data = deepcopy(val), active = true }
            local n = #doom.thinkerlist + 1
            doom.thinkerlist[n] = entry
            doom.thinkermap[any] = n
        end
    end

    -- put proxy into doom.thinkers so existing reads/writes work (but do not pairs() it)
    doom.thinkers = proxy
    setmetatable(doom.thinkers, mt)
end

rawset(_G, "DOOM_SwitchWeapon", function(player, wepname, force)
	if not (player and player.valid) then return end
	if not player.doom then return end
	if not player.doom.weapons[wepname] then return end -- player must own it
	if player.doom.curwep == wepname then return end -- Ignore if same

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

	return false -- weapon exists but wasn't found in any slot (bad config?)
end)

rawset(_G, "DOOM_DoAutoSwitch", function(player, force, ammotype)
	if not (player and player.valid and player.doom) then return end
	local funcs = P_GetMethodsForSkin(player)
	local weapon = DOOM_GetWeaponDef(player)
	local curAmmo = funcs.getCurAmmo(player)

	-- 1) If we have enough ammo for current weapon, do nothing
	if not force then
		if type(curAmmo) ~= "boolean" and curAmmo >= (weapon.shotcost or 1) then
			return true
		elseif type(curAmmo) == "boolean" and curAmmo == false then
			return true
		end
	end

	-- 2) Out of ammo → choose a new weapon
	local candidates = {}

	for name, def in pairs(doom.weapons) do
		-- Player must own weapon
		if not player.doom.weapons[name] then continue end
		-- Filter by ammo type if specified
		if ammotype and def.ammotype ~= ammotype then continue end

		local ammoCount = funcs.getAmmoFor(player, def.ammotype)
		if ammoCount < (def.shotcost or 1) then continue end

		-- Priority comes from definition, fallback = 1000
		table.insert(candidates, {name = name, priority = def.priority or 1000})
	end

	-- Sort by priority ascending (lowest = most preferred)
	table.sort(candidates, function(a, b)
		return a.priority < b.priority
	end)

	-- Pick first valid candidate, or default to fists
	local chosen
	if candidates[1] then
		chosen = candidates[1].name
	else
		-- Default fallback weapon, always available
		chosen = doom.fallbackWeapon or "fist"
	end

	return DOOM_SwitchWeapon(player, chosen)
end)

local function DOOM_WhatInter()
	if doom.isdoom1 then
		return "INTER"
	else
		return "DM2INT"
	end
end

rawset(_G, "saveStatus", function(player)
    local funcs = P_GetMethodsForSkin(player)

    player.doom = player.doom or {}
    player.mo.doom = player.mo.doom or {}
    player.doom.laststate = {}

    local mo = player.mo

    -- Prepare expected values
    local expectedValues = {
        health = funcs.getHealth and funcs.getHealth(player) or 100,
        armor = funcs.getArmor and funcs.getArmor(player) or 0,
        currentWeapon = funcs.getCurrentWeapon and funcs.getCurrentWeapon(player),
        curwep = funcs.getCurrentWeapon and funcs.getCurrentWeapon(player) or player.doom.curwep,
        curwepslot = player.doom.curwepslot,
        curwepcat = player.doom.curwepcat,
        weapons = {},
        oldweapons = player.doom.oldweapons,
        ammo = {},
        position = {x = mo.x, y = mo.y, z = mo.z},
        momentum = {x = mo.momx, y = mo.momy, z = mo.momz},
        map = gamemap
    }

	if doom.cvars.multiDontLowHealth.value then
		local multiplayerHealthBS = 50 + (player.mo.doom.health / 2)
		if expectedValues.health < multiplayerHealthBS then
			expectedValues.health = multiplayerHealthBS
		end
	end

    -- Iterate through all known weapons and call their getter
    if funcs.hasWeapon then
        for name, _ in pairs(doom.weapons) do
            local ok, val = pcall(funcs.hasWeapon, player, name)
            expectedValues.weapons[name] = ok and val or nil
        end
    end

    -- Iterate through all known ammo types and call their getter
    if funcs.getAmmoFor then
        for name, _ in pairs(doom.ammos) do
            local ok, val = pcall(funcs.getAmmoFor, player, name)
            expectedValues.ammo[name] = ok and val or 0
        end
    end

    -- Use saveState if it exists; otherwise, copy expectedValues to laststate
    if funcs.saveState then
        funcs.saveState(player, expectedValues)
    else
        -- Fallback using expectedValues
        local last = player.doom.laststate
        last.health = deepcopy(expectedValues.health)
        last.armor = deepcopy(expectedValues.armor)
        last.curwep = deepcopy(expectedValues.curwep)
        last.curwepslot = deepcopy(expectedValues.curwepslot)
        last.curwepcat = deepcopy(expectedValues.curwepcat)
        last.weapons = deepcopy(expectedValues.weapons)
        last.oldweapons = deepcopy(expectedValues.oldweapons)
        last.ammo = deepcopy(expectedValues.ammo)
        last.pos = {
            x = deepcopy(expectedValues.position.x),
            y = deepcopy(expectedValues.position.y),
            z = deepcopy(expectedValues.position.z),
        }
        last.momentum = {
            x = deepcopy(expectedValues.momentum.x),
            y = deepcopy(expectedValues.momentum.y),
            z = deepcopy(expectedValues.momentum.z),
        }
        last.map = deepcopy(expectedValues.map)
    end
end)

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
			local funcs = P_GetMethodsForSkin(player)
			if funcs.throwOutSaveState then
				funcs.throwOutSaveState(player)
			else
				player.doom.laststate = {}
			end
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
			local funcs = P_GetMethodsForSkin(player)
			player.doom.intstate = 1
			player.doom.intpause = TICRATE
			player.doom.wintime = leveltime
			if funcs.onIntermission then
				funcs.onIntermission(player)
			end
			saveStatus(player)
			if player == displayplayer then
				local charDef = P_GetSupportsForSkin(player)
				if charDef.intermusic then
					S_ChangeMusic(charDef.intermusic)
				else
					S_ChangeMusic(DOOM_WhatInter())
				end
			end
		end
		doom.intermission = true
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
	if doom.lastmap and gamemap == doom.lastmap then
		nextLev = 1100 -- aka "nextLev = TITLE" (i don't trust SRB2's constants for this)
	end
	G_SetCustomExitVars(nextLev, 1, GT_DOOM, true)
	G_ExitLevel()
end)

rawset(_G, "DOOM_DoMessage", function(player, string)
	player.doom.messageclock = TICRATE*5
	player.doom.message = DOOM_ResolveString(string)
	if player.doom.message != string then
		player.doom.message = player.doom.message
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
			an = AngleFixed(an)
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

rawset(_G, "DOOM_IsSecretLevel", function()
    doom.prndindex = (doom.prndindex+1)&0xff;
    return doom.rndtable[doom.prndindex + 1];
end)