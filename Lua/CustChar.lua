local function resolvePlayerAndMobj(target)
	-- Accept either player_t or mobj (caller may pass either).
	-- Returns: player, mobj (mobj may be nil if not available)
	if not target then return nil, nil end
	if target.player then -- it's an mobj
		return target.player, target
	end
	-- assume it's a player_t
	return target, target.mo
end

local baseMethods = {
	getHealth = function(player)
		if not player or not player.mo then return nil end
		return (player.mo.doom and player.mo.doom.health) or nil
	end,

	setHealth = function(player, health)
		if not player or not player.mo then return false end
		if player.mo.doom then
			player.mo.doom.health = health
			return true
		end
		return false
	end,

	getArmor = function(player)
		if not player or not player.mo then return nil end
		if player.mo.doom and player.mo.doom.armor ~= nil then
			return player.mo.doom.armor
		end
		return nil
	end,

	setArmor = function(player, armor, efficiency)
		if not player or not player.mo then return false end
		if not player.mo.doom then return false end

		local doom = player.mo.doom
		local prevArmor = doom.armor or 0

		doom.armor = armor

		-- If efficiency was explicitly passed, use it
		if efficiency ~= nil then
			doom.armorefficiency = efficiency
		-- If armor was raised from 0 → >0 and efficiency wasn't passed, default it
		elseif prevArmor <= 0 and armor > 0 then
			doom.armorefficiency = FRACUNIT/3
		end

		return true
	end,

	getCurAmmo = function(player)
		if not player then return nil end
		if player.doom then
			local weapon = player.doom.curwep
			local wpnStats = doom.weapons[weapon] or {}
			local ammoType = wpnStats.ammotype
			if not ammoType then return nil end
			local ammoCount = player.doom.ammo[ammoType]
			if ammoCount <= -1 then
				return false
			end
			return ammoCount
		end
		return false
	end,

	getCurAmmoType = function(player)
		if not player then return nil end
		if player.doom then
			local weapon = player.doom.curwep
			local wpnStats = doom.weapons[weapon] or {}
			local ammoType = wpnStats.ammotype
			return ammoType
		end
		return nil
	end,

	getAmmoFor = function(player, aType, amount)
		if not player or not player.doom or not aType then return false end
		return player.doom.ammo[aType]
	end,

	setAmmoFor = function(player, aType, amount)
		if not player or not player.doom or not aType then return false end
		player.doom.ammo[aType] = amount
		return true
	end,

	getMaxFor = function(player, aType)
		if not player or not aType then return nil end
		if player.doom then
			if player.doom.backpack and doom.ammos[aType] then
				return doom.ammos[aType].backpackmax
			elseif doom.ammos[aType] then
				return doom.ammos[aType].max
			end
		end
		return nil
	end,

	giveWeapon = function(player, weapon)
		if not player or not player.doom or not weapon then
			return false
		end

		local hadWeapon = player.doom.weapons[weapon] or false
		local weaponAdded = false
		local ammoGiven = false

		-- Give weapon if not already owned
		if not hadWeapon then
			player.doom.weapons[weapon] = true
			weaponAdded = true
		end

		-- Attempt to give starting ammo
		local methods = P_GetMethodsForSkin(player)
		if methods and methods.giveAmmoFor then
			local ammoResult = methods.giveAmmoFor(player, weapon, 0)
			if ammoResult then
				ammoGiven = true
			end
		end

		if weaponAdded then
			DOOM_SwitchWeapon(player, weapon)
		end

		-- Return true if *either* new weapon OR ammo was given
		return weaponAdded or ammoGiven
	end,

	hasWeapon = function(player, weapon)
		if not player or not player.doom or not weapon then return false end
		return player.doom.weapons[weapon]
	end,

	giveAmmoFor = function(player, source, dflags)
		local tables = {
			clip           = {"bullets", 10},
			clipbox        = {"bullets", 50},
			shells         = {"shells", 4},
			shellbox       = {"shells", 20},
			rocket         = {"rockets", 1},
			rocketbox      = {"rockets", 5},
			cell           = {"cells", 20},
			cellpack       = {"cells", 100},
			pistol         = {"bullets", 20},
			chaingun       = {"bullets", 20},
			shotgun        = {"shells", 8},
			supershotgun   = {"shells", 8},
			rocketlauncher = {"rockets", 2},
			plasmarifle    = {"cells", 40},
			bfg9000        = {"cells", 40},
		}

		if not player or not player.doom then return false end

		local entry = tables[source]
		if not entry then return false end

		local aType, addAmount = entry[1], entry[2]

		if doom.skill == 1 or doom.skill == 5 then
			entry[2] = $ * 2
		end
		if (dflags & DF_DROPPED) then
			entry[2] = $ / 2
		end

		local curAmmo = player.doom.ammo[aType] or 0
		local maxAmmo = P_GetMethodsForSkin(player).getMaxFor(player, aType)

		player.doom.ammo[aType] = min(curAmmo + addAmount, maxAmmo)
		return curAmmo ~= player.doom.ammo[aType]
	end,

	damage = function(player, damage, attacker, proj, damageType, minhealth)
		local player, mobj = resolvePlayerAndMobj(player)
		if not player or not mobj then return false end
		if (player.playerstate or PST_LIVE) == PST_DEAD then return false end

		-- doom-style with armor efficiency
		if player.mo.doom then
			local efficiency = player.mo.doom.armorefficiency or 0
			local damageToHealth = FixedMul(damage, efficiency)
			local damageToArmor  = FixedMul(damage, FRACUNIT - efficiency)

			player.mo.doom.health = player.mo.doom.health - damageToHealth
			player.mo.doom.armor  = player.mo.doom.armor  - damageToArmor

			if player.mo.doom.armor < 0 then
				player.mo.doom.health = player.mo.doom.health + player.mo.doom.armor
				player.mo.doom.armor = 0
			end

			if minhealth and player.mo.doom.health < minhealth then
				player.mo.doom.health = minhealth
			end

			if player.mo.doom.health < 1 and player.playerstate == PST_LIVE then
				P_KillMobj(mobj, proj, attacker, damageType)
			else
				P_PlayRinglossSound(mobj)
			end
			return true
		end

		return false
	end,
}

-- Helper to shallow-merge override table onto base
local function mergeMethods(base, overrides)
	local out = {}
	for k,v in pairs(base) do out[k] = v end
	if overrides then
		for k,v in pairs(overrides) do out[k] = v end
	end
	return out
end

-- Simple weighted pick for list-style defs (array of arrays)
local function SimpleWeightedPick(list)
    local candidates = {}
    local total = 0

    for _, entry in ipairs(list) do
        local w = entry[#entry] -- last element is the weight
        if type(w) == "number" and w > 0 then
            table.insert(candidates, {entry = entry, weight = w})
            total = total + w
        end
    end

    if total == 0 then return nil end

    -- probabilistic selection using P_RandomChance + FixedDiv
    for i = 1, #candidates do
        local chance = FixedDiv(candidates[i].weight * FRACUNIT, total * FRACUNIT)
        if P_RandomChance(chance) then
            return candidates[i].entry
        end
    end

    return candidates[#candidates].entry
end

-- Convert a simple def entry into the HL-style stats table
local function SimpleDefToStats(entry)
    if not entry or type(entry[1]) ~= "string" then return nil end
    local id = entry[1]

    if id:sub(1,7) == "weapon_" then
        return { weapon = id }
    elseif id:sub(1,5) == "ammo_" then
        local count = entry[2] or 0
        if type(count) == "table" then
            return { ammo = { type = { id }, give = count } }
        else
            return { ammo = { type = { id }, give = { count } } }
        end
    else
        return nil
    end
end

-- Public helper: pick from simple defs and return ready-to-apply stats
-- defs: array of entries, each entry either {"weapon_x", weight} or {"ammo_y", count, weight}
-- player: player_t
-- bonusFactor: multiplier for items the player doesn't have (default 3)
local function RandomizeFromSimpleDefs(defs, player, bonusFactor)
    bonusFactor = bonusFactor or 3

    -- Precompute which ammo types are needed by owned weapons
    local neededAmmo = {}
    for weaponName, isOwned in pairs(player.hlinv.weapons) do
        if isOwned and HLItems[weaponName] then
            local weapon = HLItems[weaponName]
            if weapon.primary and weapon.primary.ammo then
                neededAmmo[weapon.primary.ammo] = true
            end
            if weapon.secondary and weapon.secondary.ammo then
                neededAmmo[weapon.secondary.ammo] = true
            end
        end
    end

    -- Create a temporary weighted list adjusted for missing items
    local adjustedDefs = {}
    for _, entry in ipairs(defs) do
        local id = entry[1]
        local baseWeight = entry[#entry]
        local weight = baseWeight

        if id:sub(1,7) == "weapon_" and not player.hlinv.weapons[id] then
            local owned = player.hlinv.weapons[id]
            if not owned then
                -- Boost unowned weapons significantly
                weight = weight + (bonusFactor * 2)

                -- Extra bump if there is already ammo for this weapon
                local weapon = HLItems[id]
                if weapon then
                    local hasAmmo = false
                    if weapon.primary and weapon.primary.ammo and (player.hlinv.ammo[weapon.primary.ammo] or 0) > 0 then
                        hasAmmo = true
                    elseif weapon.secondary and weapon.secondary.ammo and (player.hlinv.ammo[weapon.secondary.ammo] or 0) > 0 then
                        hasAmmo = true
                    end

                    if hasAmmo then
                        weight = weight + (bonusFactor >> 1)
                    end
                end
            end
        elseif id:sub(1,5) == "ammo_" then
            if neededAmmo[id] then
                local current = player.hlinv.ammo[id] or 0
                local ammax = HLItems[id] and HLItems[id].max or 0
				local heldWepBoost = 1
                
                -- Tiered boosting based on scarcity
                if current <= 0 then
                    -- Desperately needed - massive boost
                    weight = weight + (bonusFactor * 3)
					heldWepBoost = 4
                elseif current < (ammax >> 2) then -- Less than 25%
                    -- Very low - strong boost
                    weight = weight + (bonusFactor * 2)
					heldWepBoost = 3
                elseif current < (ammax >> 1) then -- Less than 50%
                    -- Low - moderate boost
                    weight = weight + bonusFactor
					heldWepBoost = 2
                end

				-- Additional tiny boost if holding a weapon that uses this ammo
				local curWeapon = player.hlinv.curwep
				if curWeapon and HLItems[curWeapon] then
					local wep = HLItems[curWeapon]
					local usesAmmo = (wep.primary and wep.primary.ammo == id) or
									 (wep.secondary and wep.secondary.ammo == id)
					if usesAmmo then
						weight = weight + heldWepBoost
					end
				end
            else
                -- Ammo not needed by any owned weapon - reduce weight
                weight = max(1, weight - bonusFactor)
            end
        end

        local newEntry = {}
        for i=1,#entry-1 do newEntry[i] = entry[i] end
        newEntry[#entry] = weight
        table.insert(adjustedDefs, newEntry)
    end

    local picked = SimpleWeightedPick(adjustedDefs)
    return SimpleDefToStats(picked)
end

-- Build doom.charSupport using baseMethods and per-char overrides
doom.charSupport = {
	kombifreeman = {
		noWeapons = true,
		noHUD = true,
		customDamage = true,
		-- TODO: Re-make this! Slowpoke.
		methods = {
			getHealth = function(player)
				if not player or not player.mo then return nil end
				return (player.mo.hl and player.mo.hl.health) or nil
			end,

			setHealth = function(player, health)
				if not player or not player.mo then return false end
				if player.mo.hl then
					player.mo.hl.health = health
					return true
				end
				return false
			end,

			getArmor = function(player)
				if not player or not player.mo then return nil end
				if player.mo.doom and player.mo.doom.armor ~= nil then
					return player.mo.hl.armor / FRACUNIT
				end
				return nil
			end,

			setArmor = function(player, armor, efficiency)
				if not player or not player.mo then return false end
				if not player.mo.hl then return false end

				player.mo.hl.armor = armor*FRACUNIT

				return true
			end,

			getCurAmmo = function(player)
				if not player then return nil end
				local ammoType = HLItems[player.hl.curwep].primary.ammo
				local ammoCount = player.hlinv.ammo[ammoType] + max((player.hlinv.wepclips[player.hl.curwep].primary or -1), 0)
				if ammoCount <= -1 then
					return false
				end
				return ammoCount
			end,

			getCurAmmoType = function(player)
				if not player then return nil end
				if player.hlinv then
					local weapon = player.doom.curwep
					local wpnStats = doom.weapons[weapon] or {}
					local ammoType = wpnStats.ammotype
					return ammoType
				end
				return nil
			end,

			getAmmoFor = function(player, aType, amount)
				if not player or not aType then return false end
				return player.hlinv.ammo[aType]
			end,

			setAmmoFor = function(player, aType, amount)
				if not player or not aType then return false end
				player.hlinv.ammo[aType] = amount
				return true
			end,

			getMaxFor = function(player, aType)
				if not player or not aType then return nil end
				if player.doom then
					if player.doom.backpack and doom.ammos[aType] then
						return doom.ammos[aType].backpackmax
					elseif doom.ammos[aType] then
						return doom.ammos[aType].max
					end
				end
				return nil
			end,

			giveAmmoFor = function(player, source, dflags)
				if not player or not source then return false end
				local tables = {
					chainsaw = {
						{"ammo_hornet", 8, 1}
					},
					shotgun = {
						{"ammo_buckshot", 12, 1}
					},
					supershotgun = {
						{"ammo_357", 6, 3},
						{"ammo_bolt", 5, 9},
					},
					chaingun = {
						{"ammo_9mm", 25, 1}
					},
					rocketlauncher = {
						{"ammo_rocket", 1, 1}
					},
					plasmarifle = {
						{"ammo_uranium", 20, 1}
					},
					bfg9000 = {
						{"ammo_uranium", 20, 1}
					},
					clip = {
						{"ammo_9mm", 17, 1}
					},
					clipbox = {
						{"ammo_9mm", 50, 1}
					},
					shells = {
						{"ammo_357", 6, 9},
						{"ammo_bolt", 5, 9},
						{"ammo_buckshot", 4, 9},
					},
					shellbox = {
						{"ammo_357", 12, 9},
						{"ammo_bolt", 10, 9},
						{"ammo_buckshot", 20, 9},
					},
				}

				-- Adjust for SSG's existence
				if doom.isdoom1 then
					for _, v in ipairs(tables.supershotgun) do
						table.insert(tables.shotgun, v)
					end
				end

				for k, defs in pairs(tables) do
					for k, v in pairs(defs) do
						if doom.skill == 1 or doom.skill == 5 then
							v[2] = $ * 2
						end
						if (dflags & DF_DROPPED) then
							v[2] = $ / 2
						end
					end
				end
				local toGive = RandomizeFromSimpleDefs(tables[source], player, 1)
				return HL_ApplyPickupStats(player, toGive)
			end,

			giveWeapon = function(player, weapon)
				local tables = {
					chainsaw = {
						{"weapon_hornetgun", 1}
					},
					shotgun = {
						{"weapon_shotgun", 1}
					},
					supershotgun = {
						{"weapon_357", 3},
						{"weapon_crossbow", 9},
					},
					chaingun = {
						{"weapon_mp5", 1}
					},
					rocketlauncher = {
						{"weapon_rpg", 1}
					},
					plasmarifle = {
						{"weapon_gauss", 1}
					},
					bfg9000 = {
						{"weapon_egon", 1}
					},
				}

				-- Adjust for SSG's existence
				if doom.isdoom1 then
					for _, v in ipairs(tables.supershotgun) do
						table.insert(tables.shotgun, v)
					end
				end

				local toGive = RandomizeFromSimpleDefs(tables[weapon], player, 1)
				return HL_ApplyPickupStats(player, toGive)
			end,

			hasWeapon = function(player, weapon)
				local wepRemaps = {
					pistol = "weapon_9mmhandgun",
					shotgun = "weapon_shotgun",
					supershotgun = "weapon_357",
					chaingun = "weapon_mp5",
					rocketlauncher = "weapon_rpg",
					plasmarifle = "weapon_egon",
					bfg9000 = "weapon_gauss",
				}
				return player.hlinv.weapons[wepRemaps[weapon]]
			end,

			damage = function(player, damage, attacker, proj, damageType, minhealth)
				if (player.playerstate or PST_LIVE) == PST_DEAD then return false end
				local player, mobj = resolvePlayerAndMobj(player)
				P_DamageMobj(mobj, proj, attacker, damage, damageType)
			end,
		},
	},
	other = {
		methods = baseMethods
	}
}

setmetatable(doom.charSupport, {
	__index = function(t, key) return t.other end
})