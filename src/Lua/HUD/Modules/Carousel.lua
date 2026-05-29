local SCREENWIDTH = 320

local distance

local function CalcOffset()
	if distance then
		local delta = 1000 / TICRATE

		if delta < 125 then
			local x = FRACUNIT - delta / 125
			return (FixedMul(distance, FixedMul(x, x)) + FRACUNIT/2) / FRACUNIT
		end

		distance = 0
	end

	return 0
end

local wpi_none = -1
local wpi_regular = 0
local wpi_selected = 1
local wpi_disabled = 2

/*
boolean G_WeaponSelectable(weapontype_t weapon)
{
    // Can't select the super shotgun in Doom 1.

    if (weapon == wp_supershotgun && !ALLOW_SSG)
    {
        return false;
    }

    // These weapons aren't available in shareware.

    if ((weapon == wp_plasma || weapon == wp_bfg)
        && gamemission == doom && gamemode == shareware)
    {
        return false;
    }

    // Can't select a weapon if we don't own it.

    if (!players[consoleplayer].weaponowned[weapon])
    {
        return false;
    }

    // Can't select the fist if we have the chainsaw, unless
    // we also have the berserk pack.

    if ((demo_compatibility || (!demo_compatibility && doom_weapon_cycle))
        && weapon == wp_fist
        && players[consoleplayer].weaponowned[wp_chainsaw]
        && !players[consoleplayer].powers[pw_strength])
    {
        return false;
    }

    return true;
}
*/

---@param player player_t
---@param wepname string
local function G_WeaponSelectable(player, wepname)
	if not player.doom.weapons[wepname] then
		return false
	end

	return true
end

/*
weapontype_t G_AdjustSelection(weapontype_t weapon)
{
    if (!demo_compatibility && !doom_weapon_cycle)
    {
        return weapon;
    }

    const player_t *player = &players[consoleplayer];

    if (weapon == wp_fist && player->weaponowned[wp_chainsaw]
        && (player->nextweapon != wp_chainsaw || !player->powers[pw_strength]))
    {
        weapon = wp_chainsaw;
    }
    else if (ALLOW_SSG && weapon == wp_shotgun
             && player->weaponowned[wp_supershotgun]
             && player->nextweapon != wp_supershotgun)
    {
        weapon = wp_supershotgun;
    }

    return weapon;
}
*/

local function G_AdjustSelection(player, wepname)
	return wepname
end

---@param v videolib
local function DrawIcon(v, x, y, elem, icon)
	local lump = "\0"
	local name
	local targiconname = doom.weapons[icon.weapon].carouselicon
	if targiconname and v.patchExists(targiconname .. 1) then
		name = targiconname
	else
		name = "SMUNKN"
	end

	local prefix = (icon.state == wpi_selected and 1 or 0)
	local patchName = name .. prefix

	local patch = v.cachePatch(patchName)

	local cr = icon.state == wpi_disabled and v.getColormap(nil, nil, "COLORMAPROW16") or nil

	v.draw(x, y, patch, V_PERPLAYER|V_SNAPTOTOP, cr)
end

local function wepToIcondef(player, wepname)
	local state = wpi_none

	local activewep = player.doom.wishwep or player.doom.curwep
	if activewep == "" then
		activewep = player.doom.curwep
	end

	if G_WeaponSelectable(player, wepname) then
		if activewep == wepname then
			state = wpi_selected
		elseif G_AdjustSelection(player, wepname) ~= wepname then
			state = wpi_disabled
		else
			state = wpi_regular
		end
	elseif player.doom.weapons[wepname] then
		state = wpi_disabled
	end

	if state ~= wpi_none then
		return {
			weapon = wepname,
			state = state,
		}
	end
end

local function ST_UpdateCarousel(player)

end

addHook("PlayerThink", function(player)

end)

local function G_GetWeaponOrder(player, offset)
	if not player.doom or not player.doom.curwepcat then
		return nil
	end

	local function firstAvailableInSlot(player, slot)
		if not doom.weaponnames[slot] then return nil end
		for order, wep in ipairs(doom.weaponnames[slot]) do
			if player.doom.weapons[wep] then
				return order
			end
		end
		return nil
	end

	local function findNextWeapon(player, direction, baseSlot, baseOrder)
		local currentSlot = baseSlot
		local currentOrder = baseOrder
		local totalSlots = #doom.weaponnames

		if totalSlots == 0 then
			return currentSlot, currentOrder
		end

		if direction == 1 then
			for order = currentOrder + 1, #doom.weaponnames[currentSlot] do
				local weapon = doom.weaponnames[currentSlot][order]
				if player.doom.weapons[weapon] then
					return currentSlot, order
				end
			end
		else
			for order = currentOrder - 1, 1, -1 do
				local weapon = doom.weaponnames[currentSlot][order]
				if player.doom.weapons[weapon] then
					return currentSlot, order
				end
			end
		end

		local startSlot = currentSlot

		local function wrapSlot(slot, total)
			if slot < 1 then
				return total
			elseif slot > total then
				return 1
			end
			return slot
		end

		local slot = wrapSlot(currentSlot + direction, totalSlots)

		local checkedSlots = 0
		local totalSlots = 50

		while slot ~= startSlot and checkedSlots < totalSlots do
			checkedSlots = $ + 1
			local firstOrder = firstAvailableInSlot(player, slot)
			if firstOrder then
				if direction == 1 then
					return slot, firstOrder
				else
					local highestOrder = firstOrder
					for order = firstOrder + 1, #doom.weaponnames[slot] do
						if player.doom.weapons[doom.weaponnames[slot][order]] then
							highestOrder = order
						end
					end
					return slot, highestOrder
				end
			end

			slot = (slot + direction - 1) % totalSlots + 1
		end

		return currentSlot, currentOrder
	end

	-- Base position (carousel preview if active, otherwise real weapon)
	local baseSlot = player.doom.wepcarousel and player.doom.wepcarousel.showtimer
		and player.doom.wepcarousel.curwepcat
		or player.doom.curwepcat

	local baseOrder = player.doom.wepcarousel and player.doom.wepcarousel.showtimer
		and player.doom.wepcarousel.curwepslot
		or player.doom.curwepslot

	local slot = baseSlot
	local order = baseOrder

	if offset == 0 then
		return doom.weaponnames[slot][order]
	end

	local direction = (offset > 0) and 1 or -1

	for i = 1, abs(offset) do
		slot, order = findNextWeapon(player, direction, slot, order)
	end

	return doom.weaponnames[slot][order]
end

---@param v videolib
---@param player player_t
local function ST_DrawCarousel(v, player, x, y, elem)
	if not player.doom.wepcarousel then return end
	if not player.doom.wepcarousel.showtimer then
		return
	end

	local offset = SCREENWIDTH / 2 + CalcOffset()

	for i = -2, 2 do
		local wepname = G_GetWeaponOrder(player, i)
		if wepname then
			local icon = wepToIcondef(player, wepname)
			if icon then
				DrawIcon(v, offset + i*64, y, elem, icon)
			end
		end
	end
end

return ST_DrawCarousel