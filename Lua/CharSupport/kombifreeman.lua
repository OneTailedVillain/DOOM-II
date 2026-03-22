-- Kombifreeman character support definition
-- Relies on the base methods exported by base.lua

local baseMethods = doom.charSupportBaseMethods

-- helper originally from CustChar.lua
local function normalizeAmmoType(aType)
    if type(aType) == "string" then
        local t = {}
        for ammo in aType:gmatch("[^+]+") do
            table.insert(t, ammo)
        end
        return t
    elseif type(aType) == "table" then
        return aType
    else
        return {}
    end
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

        if id:sub(1,7) == "weapon_" then
            local owned = player.hlinv.weapons[id]
            local weapon = HLItems[id]
            
            if not owned then
                -- Base boost for unowned weapons
                weight = weight + (bonusFactor * 2)

                -- Check ammo situation for this weapon
				if weapon then
					-- collect actual ammo types this weapon uses (only if ammo has a defined max)
					local ammoTypesList = {}
					if weapon.primary and weapon.primary.ammo then
						local a = weapon.primary.ammo
						local ammax = HLItems[a] and HLItems[a].max or 0
						if ammax > 0 then table.insert(ammoTypesList, a) end
					end
					if weapon.secondary and weapon.secondary.ammo then
						local a = weapon.secondary.ammo
						local ammax = HLItems[a] and HLItems[a].max or 0
						if ammax > 0 then table.insert(ammoTypesList, a) end
					end

					-- only consider orphan logic if there is at least one ammo type
					if #ammoTypesList > 0 then
						local anyOwnedUsesAmmo = false
						-- if player owns ANY weapon that uses ANY of these ammo types, we are not 'orphaned'
						for _, ammoType in ipairs(ammoTypesList) do
							for wepName, isOwned in pairs(player.hlinv.weapons) do
								if isOwned and HLItems[wepName] then
									local other = HLItems[wepName]
									if (other.primary    and other.primary.ammo    == ammoType) or
									   (other.secondary  and other.secondary.ammo  == ammoType)
									then
										anyOwnedUsesAmmo = true
										break
									end
								end
							end
							if anyOwnedUsesAmmo then break end
						end

						if not anyOwnedUsesAmmo then
							-- compute an average "orphan ammo ratio score" across ammo types (1..4 per type)
							local totalScore = 0
							for _, ammoType in ipairs(ammoTypesList) do
								local currentAmmo = player.hlinv.ammo[ammoType] or 0
								local ammoMax = HLItems[ammoType] and HLItems[ammoType].max or 0
								local score = 0
								if ammoMax > 0 then
									local ammoRatio = FixedDiv(currentAmmo * FRACUNIT, ammoMax * FRACUNIT)
									if ammoRatio > FRACUNIT * 3 / 4 then
										score = 4
									elseif ammoRatio > FRACUNIT / 2 then
										score = 3
									elseif ammoRatio > FRACUNIT / 4 then
										score = 2
									elseif currentAmmo > 0 then
										score = 1
									end
								end
								totalScore = totalScore + score
							end

							local orphanAvg = totalScore / #ammoTypesList -- 0..4
							weight = weight + (bonusFactor * 2) + (orphanAvg * min(bonusFactor / 2, 1))
						end
					end
				end
            else
                -- Player owns this weapon - check if they're low on ammo for it
                if weapon then
                    local totalAmmoDeficit = 0
                    local ammoTypes = 0
                    
                    if weapon.primary and weapon.primary.ammo then
                        local ammoType = weapon.primary.ammo
                        local currentAmmo = player.hlinv.ammo[ammoType] or 0
                        local ammoMax = HLItems[ammoType] and HLItems[ammoType].max or 0
                        
                        if ammoMax > 0 then
                            -- Use FixedDiv for fixed-point arithmetic
                            local ammoRatio = FixedDiv(currentAmmo * FRACUNIT, ammoMax * FRACUNIT)
                            
                            if ammoRatio < FRACUNIT/10 then  -- < 10%
                                totalAmmoDeficit = totalAmmoDeficit + 3
                            elseif ammoRatio < FRACUNIT/4 then  -- < 25%
                                totalAmmoDeficit = totalAmmoDeficit + 2
                            elseif ammoRatio < FRACUNIT/2 then  -- < 50%
                                totalAmmoDeficit = totalAmmoDeficit + 1
                            end
                            ammoTypes = ammoTypes + 1
                        end
                    end
                    
                    -- Apply small boost for weapons the player owns but is low on ammo for
                    if ammoTypes > 0 and totalAmmoDeficit > 0 then
                        local deficitBonus = FixedMul(FixedDiv(totalAmmoDeficit * FRACUNIT, ammoTypes * FRACUNIT), bonusFactor * (FRACUNIT / 2))
                        weight = weight + (deficitBonus) / FRACUNIT
                    end
                end
            end
        elseif id:sub(1,5) == "ammo_" then
            if neededAmmo[id] then
                local current = player.hlinv.ammo[id] or 0
                local ammax = HLItems[id] and HLItems[id].max or 0
                local heldWepBoost = 1
                
                -- Tiered boosting based on scarcity (using fixed-point for consistency)
                if current <= 0 then
                    -- Desperately needed - massive boost
                    weight = weight + (bonusFactor * 3)
                    heldWepBoost = 4
                else
                    local ammoRatio = FixedDiv(current * FRACUNIT, ammax * FRACUNIT)
                    if ammoRatio < FRACUNIT/4 then -- Less than 25%
                        -- Very low - strong boost
                        weight = weight + (bonusFactor * 2)
                        heldWepBoost = 3
                    elseif ammoRatio < FRACUNIT/2 then -- Less than 50%
                        -- Low - moderate boost
                        weight = weight + bonusFactor
                        heldWepBoost = 2
                    end
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

doom.charSupport.kombifreeman = {
	noWeapons = true, -- Disable the DOOM port's weapons
	noHUD = true, -- Get rid of the DOOM port's HUD
	customDamage = true, -- If this skin also uses MobjDamage

	css = {
		name = "Gordon Freeman",
		sprite = SPR2_WALK,
		sequence = {A, 8, 3}
	},

	-- TODO: Re-make this! Slowpoke.
	methods = {
		hasPowerUp = baseMethods.hasPowerUp,
		saveState = baseMethods.saveState,
		throwOutSaveState = baseMethods.throwOutSaveState,
		takePowerUp = baseMethods.takePowerUp,

		getHealth = function(player)
			if not player or not player.mo then return nil end
			local curHealth = (player.mo.hl and player.mo.hl.health)
			if curHealth == nil then return nil end
			return curHealth
		end,

		setHealth = function(player, health)
			if not player or not player.mo then return false end
			if player.mo.hl then
				player.mo.hl.health = health
				return true
			end
			return false
		end,

		getMaxHealth = function(player)
			if not player or not player.mo then return nil end
			local curHealth = player.mo.doom and player.mo.doom.maxhealth
			if curHealth == nil then return nil end
			return curHealth
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

		doBackpack = function(player)
			player.hl1doubleammo = true
			local ammoGives = {
				ammo_9mm = 17,
				ammo_357 = 6,
				ammo_argrenade = 2,
				ammo_buckshot = 4,
				ammo_bolt = 5,
				ammo_rocket = 1,
				ammo_uranium = 20,
			}
			for ammotype, amount in pairs(ammoGives) do
				if doom.gameskill == 1 or doom.gameskill == 5 then
					amount[2] = $ * 2
				end
				HL_ApplyPickupStats(player, { ammo = {type = ammotype, give = amount} })
			end
			return true
		end,

		getMaxArmor = function(player)
			if not player or not player.mo then return nil end
			if player.mo.doom and player.mo.doom.maxarmor ~= nil then
				return player.mo.doom.maxarmor
			end
			return nil
		end,

		getCurAmmo = function(player)
			if not player then return nil end
			local ammoType = HLItems[player.hl.curwep].primary.ammo
			local ammoCount = (player.hlinv.ammo[ammoType] or 0) + max((player.hlinv.wepclips[player.hl.curwep].primary or -1), 0)
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

			local doomToHl = {
				bullets = {"ammo_9mm"},
				shells = {"ammo_buckshot", "ammo_357", "ammo_bolt"},  -- include all relevant shell ammo
				rockets = {"ammo_rocket", "ammo_argrenade", "ammo_snark", "ammo_satchel", "ammo_tripmine", "ammo_grenade"},          -- combined rocket types
				cells = {"ammo_uranium"},                             -- single type here
			}

			local ammoTypes = normalizeAmmoType(doomToHl[aType])
			local total = 0

			for _, ammo in ipairs(ammoTypes) do
				local hlAmmo = ammo
				local curAmmo = player.hlinv.ammo[hlAmmo]

				if curAmmo then
					local found = false

					-- Add ammo from clips for all owned weapons that use this ammo
					for wepName, owned in pairs(player.hlinv.weapons) do
						if owned and HLItems[wepName] then
							local wep = HLItems[wepName]

							local primaryAmmoType = wep.primary and wep.primary.ammo
							local secondaryAmmoType = wep.secondary and wep.secondary.ammo

							if hlAmmo == primaryAmmoType or hlAmmo == secondaryAmmoType then
								found = true
							else
								continue
							end

							-- Helper to get clip safely
							local function clipCount(weapon, slot)
								local clip = (player.hlinv.wepclips[weapon] or {})[slot] or 0
								if clip == -1 then clip = 0 end -- skip WEAPON_NOCLIP
								return clip
							end

							if primaryAmmoType == hlAmmo then
								total = total + clipCount(wepName, "primary")
							end
							if secondaryAmmoType == hlAmmo then
								total = total + clipCount(wepName, "secondary")
							end
						end
					end

					if found then
						total = total + curAmmo
					end
				end
			end

			return total != 0 and total or false
		end,

		setAmmoFor = function(player, aType, amount)
			if not player or not aType then return false end
			player.hlinv.ammo[aType] = amount
			return true
		end,

		getMaxFor = function(player, aType)
			if not player or not aType then return nil end

			local doomToHl = {
				bullets = {"ammo_9mm"},
				shells = {"ammo_buckshot", "ammo_357", "ammo_bolt"},
				rockets = {"ammo_rocket", "ammo_argrenade", "ammo_snark", "ammo_satchel", "ammo_tripmine", "ammo_grenade"},
				cells = {"ammo_uranium"},
			}

			local ammoTypes = normalizeAmmoType(doomToHl[aType])
			local totalMax = 0

			for _, ammo in ipairs(ammoTypes) do
				local hlAmmo = ammo
				if HLItems[hlAmmo] then
					local maxVal = HLItems[hlAmmo].max
					if player.hl1doubleammo then
						maxVal = HLItems[hlAmmo].backpackmax or (maxVal * 2)
					end

					local found = false

					-- Add ammo from clips for all owned weapons that use this ammo
					for wepName, owned in pairs(player.hlinv.weapons) do
						if owned and HLItems[wepName] then
							local wep = HLItems[wepName]

							local primaryAmmoType = wep.primary and wep.primary.ammo
							local secondaryAmmoType = wep.secondary and wep.secondary.ammo

							if hlAmmo == primaryAmmoType or hlAmmo == secondaryAmmoType then
								found = true
							else
								continue
							end

							-- Helper to get clip safely
							local function clipCount(weapon, slot)
								local clip = wep[slot].clipsize
								if clip == -1 then clip = 0 end -- skip WEAPON_NOCLIP
								return clip
							end

							if primaryAmmoType == hlAmmo then
								maxVal = maxVal + clipCount(wepName, "primary")
							end
							if secondaryAmmoType == hlAmmo then
								maxVal = maxVal + clipCount(wepName, "secondary")
							end
						end
					end

					if found then
						totalMax = totalMax + maxVal
					end
				end
			end

			return totalMax != 0 and totalMax or false
		end,

		giveAmmoFor = function(player, source, dflags)
			if not player or not source then return false end
			local tables = {
				chainsaw = {
					{"ammo_hornet", 8, 1},
					small = true,
				},
				shotgun = {
					{"ammo_buckshot", 12, 1},
					small = true,
				},
				supershotgun = {
					{"ammo_357", 6, 6},
					{"ammo_bolt", 5, 6},
					small = true,
				},
				chaingun = {
					{"ammo_9mm", 25, 1},
					small = true,
				},
				rocketlauncher = {
					{"ammo_rocket", 1, 1},
					small = true,
				},
				plasmarifle = {
					{"ammo_uranium", 20, 1},
					small = true,
				},
				bfg9000 = {
					{"ammo_uranium", 20, 1},
					small = true,
				},
				clip = {
					{"ammo_9mm", 17, 1},
					small = true,
				},
				clipbox = {
					{"ammo_9mm", 50, 1}
				},
				shells = {
					{"ammo_357", 6, 9},
					{"ammo_bolt", 5, 9},
					{"ammo_buckshot", 4, 9},
					small = true,
				},
				shellbox = {
					{"ammo_357", 12, 9},
					{"ammo_bolt", 10, 9},
					{"ammo_buckshot", 20, 9},
				},
				rocket = {
					{"ammo_argrenade", 2, 3},
					{"ammo_rocket", 1, 2},
					--{"ammo_snark", 5, 12},
					{"weapon_satchel", 4},
					{"weapon_handgrenade", 4},
					{"weapon_tripmine", 4},
					small = true,
				},
				rocketbox = {
					{"ammo_argrenade", 4, 12},
					{"ammo_rocket", 3, 9},
					--{"ammo_snark", 10, 12},
					{"ammo_satchel", 2, 8},
					{"ammo_tripmine", 2, 8},
					{"ammo_grenade", 10, 8},
				},
				cell = {
					{"ammo_uranium", 20, 1},
					small = true,
				},
				cellpack = {
					{"ammo_uranium", 60, 1}
				},
			}

			-- Adjust for SSG's existence
			if doom.isdoom1 then
				for _, v in ipairs(tables.supershotgun) do
					table.insert(tables.shotgun, v)
				end
			end

			for k, defs in pairs(tables) do
				for _, v in pairs(defs) do
					if type(v) != "table" then continue end
					if doom.gameskill == 1 or doom.gameskill == 5 then
						v[2] = $ * 2
					end
					if gametype == GT_DOOMDM and k.small then
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
				brassknuckles = {
					{"weapon_crowbar", 1}
				},
				pistol = {
					{"weapon_9mmhandgun", 1}
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
				chainsaw = {"weapon_hivehand"},
				brassknuckles = {"weapon_crowbar"},
				pistol = {"weapon_9mmhandgun"},
				shotgun = {"weapon_shotgun"},
				supershotgun = {"weapon_357", "weapon_crossbow"},
				chaingun = {"weapon_mp5"},
				rocketlauncher = {"weapon_rpg"},
				plasmarifle = {"weapon_egon"},
				bfg9000 = {"weapon_gauss"},
			}
			
			local weaponsToCheck = wepRemaps[weapon]
			if not weaponsToCheck then
				return false
			end
			
			for _, weaponName in ipairs(weaponsToCheck) do
				if player.hlinv.weapons[weaponName] then
					return true
				end
			end
			
			return false
		end,

		damage = function(player, damage, attacker, proj, damageType, minhealth)
		if (player.playerstate or PST_LIVE) == PST_DEAD then return false end

		local player, mobj = doom.resolvePlayerAndMobj(player)
		P_DamageMobj(mobj, proj, attacker, damage, damageType)
		end,
	},
}