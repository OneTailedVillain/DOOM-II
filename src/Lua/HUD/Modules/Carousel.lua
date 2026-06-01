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

---@param player player_t
---@param wepname string
local function wepToIcondef(player, wepname)
	local state = wpi_none

	local activewep = player.doom.wishwep or player.doom.curwep
	if activewep == "" then
		activewep = player.doom.curwep
	end

	if doom.G_WeaponSelectable(player, wepname) then
		if activewep == wepname then
			state = wpi_selected
		elseif doom.G_AdjustSelection(player, wepname) ~= wepname then
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
		slot, order = doom.findNextWeapon(player, direction, slot, order)
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