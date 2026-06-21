freeslot("sfx_plpain", "sfx_pldeth", "sfx_pdiehi")

-- helper exposed for use by other modules (previously local)
function doom.resolvePlayerAndMobj(target)
    if not target then return nil, nil end
    if target.player then -- it's an mobj
        return target.player, target
    end
    return target, target.mo
end

-- base methods that most characters will inherit
local baseMethods = {
	getHealth = function(player)
		if not player or not player.mo then return nil end
		local curHealth = player.mo.doom and player.mo.doom.health
		if curHealth == nil then return nil end
		return curHealth
	end,

	setHealth = function(player, health)
		if not player or not player.mo then return false end
		if player.mo.doom then
			player.mo.doom.health = health
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

	getMaxArmor = function(player)
		if not player or not player.mo then return nil end
		local properties = P_GetPlayerSkinProperties(player)
		if properties and properties.maxarmor != nil then
			-- Max armor property is used for armor bonuses,
			-- So divide by 2 to get the actual max armor value for the player
			return properties.maxarmor / 2
		end
		if player.mo.doom and player.mo.doom.maxarmor ~= nil then
			return player.mo.doom.maxarmor
		end
		return nil
	end,

	getCurAmmo = function(player)
		if not player then return nil end
		if player.doom then
			local wpnStats = DOOM_GetWeaponDef(player)
			local ammoType = wpnStats.ammotype
			if not ammoType then return nil end
			local ammoCount = player.doom.ammo[ammoType]
			local count = (ammoCount ~= nil) and ammoCount or 0
			if count <= -1 then
				return false
			end
			return ammoCount or 0
		end
		return false
	end,

	getCurAmmoType = function(player)
		if not player then return nil end
		if player.doom then
			local wpnStats = DOOM_GetWeaponDef(player)
			local ammoType = wpnStats.ammotype
			return ammoType
		end
		return nil
	end,

	getAmmoFor = function(player, aType)
		if not player or not player.doom or not aType then return false end
		return player.doom.ammo and player.doom.ammo[aType] or 0
	end,

	setAmmoFor = function(player, aType, amount)
		if not player or not player.doom or not aType then return false end
		player.doom.ammo[aType] = amount
		return true
	end,

	getMaxFor = function(player, aType)
		if not player or not aType then return nil end
		local properties = P_GetPlayerSkinProperties(player)
		if properties and properties.maxammo != nil then
			if player.doom.backpack then
				local maxbpa = properties.maxbackpackammo
				local maxa = properties.maxammo
				local numax = maxbpa and maxbpa[aType]
				if numax == nil then
					numax = maxa and maxa[aType]
					if numax != nil then
						numax = $ * 2
					end
				end
				if numax == nil then
					if not doom.ammos[aType] then return numax end
					-- print("Ammo type " .. tostring(aType) .. " is unsupported by this skin!")
				end
				return numax
			else
				return properties.maxammo[aType]
			end
		elseif player.doom then
			if player.doom.backpack and doom.ammos[aType] then
				return doom.ammos[aType].backpackmax
			elseif doom.ammos[aType] then
				return doom.ammos[aType].max
			end
		end
		return nil
	end,

	giveWeapon = function(player, weapon, doomflags)
		if doomflags == nil then doomflags = 0 end
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
			local ammoResult = methods.giveAmmoFor(player, weapon, doomflags)
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
		if dflags == nil then dflags = 0 end
		if not player or not player.doom then return false end

		local aType, multiplier, isSingle

		-- Ammo pickups now come from the refactored lookup table
		local pickupDef = doom.ammonameToPickupDef[source]
		if pickupDef then
			aType      = pickupDef[1]
			multiplier = pickupDef[2] or 1
			isSingle   = pickupDef[3]
		else
			local weaponPickupDef = doom.weaponAmmoPickupDef and doom.weaponAmmoPickupDef[source]
			if not weaponPickupDef then return false end

			aType      = weaponPickupDef[1]
			multiplier = weaponPickupDef[2] or 1
			isSingle   = weaponPickupDef[3]
		end

		local ammoDef = doom.ammos[aType]
		if not ammoDef or ammoDef.pickupamount == nil then return false end

		-- Base amount comes from ammo definition
		local addAmount = ammoDef.pickupamount * multiplier

		-- Skill modifiers (ITYTD / NM)
		if doom.gameskill == 1 or doom.gameskill == 5 then
			addAmount = addAmount * 2
		end

		-- Dropped weapons give half ammo
		if (dflags & DF_DROPPED) then
			addAmount = addAmount / 2
		end

		-- Deathmatch single-pickup bonus
		if gametype == GT_DOOMDM and isSingle then
			addAmount = addAmount * 5
		end

		local curAmmo = player.doom.ammo[aType] or 0
		local maxAmmo = P_GetMethodsForSkin(player).getMaxFor(player, aType)
		if maxAmmo == nil then return false end

		player.doom.ammo[aType] = min(curAmmo + addAmount, maxAmmo)

		-- Auto-switch logic
		local weapon = DOOM_GetWeaponDef(player)
		if weapon.wimpyweapon then
			if curAmmo then
				return curAmmo ~= player.doom.ammo[aType]
			end
			DOOM_DoAutoSwitch(player, true, aType)
		end

		return curAmmo ~= player.doom.ammo[aType]
	end,

	damage = function(player, damage, attacker, proj, damageType, minhealth)
		local player, mobj = doom.resolvePlayerAndMobj(player)
		if not player or not mobj then return false end
		if (player.playerstate or PST_LIVE) == PST_DEAD then return false end

		-- doom-style with armor efficiency
		if player.mo.doom then
			local efficiency = player.mo.doom.armorefficiency or 0
			local damageToHealth = FixedMul(damage, efficiency)
			local damageToArmor  = damage - damageToHealth

			player.mo.doom.health = player.mo.doom.health - damageToHealth
			player.mo.doom.armor  = player.mo.doom.armor  - damageToArmor

			if player.mo.doom.armor < 0 then
				-- doing this makes me look funny DD:
				-- but it's correct in the sense of math... or whatever
				player.mo.doom.health = player.mo.doom.health + player.mo.doom.armor
				player.mo.doom.armor = 0
			end

			if minhealth and player.mo.doom.health < minhealth then
				player.mo.doom.health = minhealth
			end

			if player.mo.doom.health < 1 and player.playerstate == PST_LIVE then
				P_KillMobj(mobj, proj, attacker, damageType)
			else
				S_StartSound(player.mo, sfx_plpain)
			end
			return true
		end

		return false
	end,

	hasPowerUp = function(player, ptype)
		if ptype == "berserk" then
			return player.doom.powers[pw_strength]
		elseif ptype == "invisibility" then
			return player.doom.powers[pw_invisibility]
		elseif ptype == "invulnerability" then
			return player.doom.powers[pw_invulnerability]
		elseif ptype == "ironfeet" then
			return player.doom.powers[pw_ironfeet]
		end
	end,

	doPowerUp = function (player, powername)
		local durationMap = {
			berserk         = 1,
			invisibility    = 120 * TICRATE,
			invulnerability = 30 * TICRATE,
			ironfeet        = 60 * TICRATE,
		}
		local ptypeMap = {
			berserk         = pw_strength,
			invisibility    = pw_invisibility,
			invulnerability = pw_invulnerability,
			ironfeet        = pw_ironfeet,
		}
		local duration = durationMap[powername]
		local ptype = ptypeMap[powername]
		if not duration or not ptype then print("FAIL! on base doPowerup method", powername, duration, ptype) return false end

		if powername == "berserk" then
			DOOM_SwitchWeapon(player, "brassknuckles")
		end

		player.doom.powers[ptype] = duration
		return true
	end
}

-- make them available on doom table for other files
doom.charSupportBaseMethods = baseMethods

-- helper to shallow-merge override table onto base
function doom.mergeCharSupportMethods(base, overrides)
    local out = {}
    for k,v in pairs(base) do out[k] = v end
    if overrides then
        for k,v in pairs(overrides) do out[k] = v end
    end
    return out
end

function doom.simpleWeightedPick(list)
    local candidates = {}
    local total = 0

    for _, entry in ipairs(list) do
        local w = entry[#entry]
        if type(w) == "number" and w > 0 then
            table.insert(candidates, {entry = entry, weight = w})
            total = total + w
        end
    end

    if total == 0 then return nil end

    for i = 1, #candidates do
        local chance = FixedDiv(candidates[i].weight * FRACUNIT, total * FRACUNIT)
        if P_RandomChance(chance) then
            return candidates[i].entry
        end
    end

    return candidates[#candidates].entry
end

---@type doomcharproperties_t
doom.baseCharProperties = {
	dealdamagefactor = FRACUNIT,
	damagefactor = {all = FRACUNIT},
	movefactor = 2048,
	walkfactor = FRACUNIT/2,
	jumpfactor = FRACUNIT,
	mass = 100,
	starthealth = nil,
	maxhealth = nil,
	maxarmor = nil,
	armorproperties = {
		armorclassmult = 100,
		armorclass1prot = FRACUNIT/3,
		armorclass2prot = FRACUNIT/2,
		hexen_armor = {
			base = 15,
			armor = 15,
			shield = 15,
			helm = 15,
			amulet = 15,
		},
	},
	pickupfactors = nil
}

-- public finalize routine to merge custom methods and set fallback.
function doom.charSupportFinalize()
    for charName, charTable in pairs(doom.charSupport) do
        if charName ~= "other" and charTable.methods then
            charTable.methods = doom.mergeCharSupportMethods(doom.charSupportBaseMethods, charTable.methods)
			charTable.properties = doom.mergeCharSupportMethods(doom.baseCharProperties, charTable.properties)
        end
    end

    -- duplicate "other" for johndoom and apply metatable fallback
    doom.charSupport["johndoom"] = deepcopy(doom.charSupport.other)
	doom.charSupport["johndoom"].properties = {useDoomMovement = true}
	doom.charSupport["johndoom"].useDoomMovement = true
	doom.charSupport["johndoom"].css = {
		name = "John Doom",
		sequence = {A, 4},
		sprite = SPR2_WALK,
		description = {
		"The vanilla experience",
		"No strengths or weaknesses",
		"Reliable in any situation",
		"But has no defining advantages"
		}
	}
    setmetatable(doom.charSupport, {
        __index = function(t, key) return t.other end
    })
end