-- Metalman character support definition
-- Includes helper functions for pip/health conversion

local baseMethods = doom.charSupportBaseMethods

local conversionRate = FixedDiv(100, 28)

local function pips_to_doom_health(pips)
    return FixedMul(pips, conversionRate)
end

local function doom_health_to_pips(dhealth)
    return FixedDiv(dhealth, conversionRate)
end

local function doom_fixed_to_pips_floor(dhealth_fixed)
    local pips_fixed = FixedDiv(dhealth_fixed, conversionRate) -- fixed_t
    return pips_fixed >> 16 -- floor
end

local function doom_fixed_to_pips_ceil(dhealth_fixed)
    local pips_fixed = FixedDiv(dhealth_fixed, conversionRate) -- fixed_t
    return (pips_fixed + (FRACUNIT - 1)) >> 16 -- ceil
end

local function clamp_pips(player, pips)
    if not player or not player.megaman then return 0 end
    if pips < 0 then return 0 end
    if pips > player.megaman.maxpips then return player.megaman.maxpips end
    return pips
end

-- define table

doom.charSupport.metalman = {
    noWeapons = true,
    noHUD = true,
    customDamage = true,
    methods = {
        getCurAmmoType = baseMethods.getCurAmmoType,
        getMaxHealth = baseMethods.getMaxHealth,
        getMaxArmor = baseMethods.getMaxArmor,
        hasPowerUp = baseMethods.hasPowerUp,
        saveState = baseMethods.saveState,
        throwOutSaveState = baseMethods.throwOutSaveState,
        takePowerUp = baseMethods.takePowerUp,

        getHealth = function(player)
            if not player or not player.mo then return nil end
            local health = FixedMul(player.megaman.curpips, conversionRate) + 1
            return health
        end,

        setHealth = function(player, health)
            if not player or not player.mo or not player.megaman then return false end

            local healthFixed = health * FRACUNIT

            local curHealthFixed = FixedMul(player.megaman.curpips, conversionRate)
            local ratioFixed = FixedDiv(healthFixed, conversionRate) -- fixed_t representing pip count * FRACUNIT

            local floorPips = ratioFixed >> 16
            local ceilPips  = (ratioFixed + (FRACUNIT - 1)) >> 16

            local setto
            if healthFixed > curHealthFixed then
                -- increase: use ceil so even tiny bonuses show a pip
                setto = ceilPips
            else
                -- decrease or same: use floor
                setto = floorPips
            end

            -- clamp to valid pips range
            if setto < 0 then setto = 0 end
            --if setto > player.megaman.maxpips then setto = player.megaman.maxpips end

            player.megaman.curpips = setto
            return true
        end,

        getArmor = function(player)
            if not player or not player.mo or not player.megaman then return 0 end
            return 0
        end,

        setArmor = function(player, armor, efficiency)
            if not player or not player.mo or not player.megaman then return false end
            armor = (armor or 0)
            efficiency = (efficiency ~= nil) and efficiency or FRACUNIT

            -- convert incoming armor to fixed
            local armor_fixed = armor * FRACUNIT

            local adjusted_armor_fixed = FixedMul(armor_fixed, efficiency)

            -- convert the adjusted armor into pips (use CEIL so small armor still yields at least some pips)
            local pipGain = doom_fixed_to_pips_ceil(adjusted_armor_fixed)

            -- clamp pipGain to missing pips (do not overflow maxpips)
            local cur = player.megaman.curpips or 0
            local maxp = player.megaman.maxpips or 0
            local missing = maxp - cur

            if missing <= 0 then
                -- already full pips; store armor but award nothing
                return true
            end

            if pipGain > missing then pipGain = missing end

            -- enforce the hard minimum of 1 pip for *positive* armor pickups (unless missing == 0)
            if pipGain < 1 then pipGain = 1 end

            -- apply pips
            player.megaman.curpips = clamp_pips(player, cur + pipGain)

            return true
        end,

        getAmmoFor = function(player, aType, amount)
            return 0
        end,

        setAmmoFor = function(player, aType, amount)
            return false
        end,

        getCurAmmo = function(player, aType, amount)
            return false
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
            return false
        end,

        hasWeapon = function(player, weapon)
            return true
        end,

        giveAmmoFor = function(player, source, dflags)
            return false
        end,

        damage = function(player, damage, attacker, proj, damageType, minhealth)
            if (player.playerstate or PST_LIVE) == PST_DEAD then return false end
            local player, mobj = doom.resolvePlayerAndMobj(player)
            local damage = max(1, FixedDiv(damage, conversionRate))
            P_DamageMobj(mobj, proj, attacker, damage, damageType)
        end,
    }
}