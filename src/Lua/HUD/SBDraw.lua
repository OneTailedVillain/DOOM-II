local function IsAboveVersion(major, sub)
	return (VERSION > major) or (VERSION == major and SUBVERSION >= sub)
end

---@param v videolib
local function drawWeaponState(v, player, slot, bobx, boby, offset)
    local wepDef = DOOM_GetWeaponDef(player)
    if not wepDef then return false end

    local psp = player.doom.psprites and player.doom.psprites[slot]
    if not psp then return false end

    if slot == PSP_FLASH and (psp.frame or 0) < 1 then
        return false
    end

    local stateDef = DOOM_ResolveStateDef(wepDef, psp.state, psp.frame)
    if not stateDef then return false end

    local sprite = stateDef.sprite
    if not sprite then
        sprite = (slot == PSP_WEAPON) and wepDef.sprite or wepDef.flashsprite
    end

    local whatFrame = stateDef.frame or A
    if whatFrame < 0 then return false end

    local spriteflags = whatFrame & ~FF_FRAMEMASK
    whatFrame = $ & FF_FRAMEMASK

    local patch = v.getSpritePatch(sprite, whatFrame)
    if not patch then return false end

    local stateOffsetX = 0
    local stateOffsetY = 0

    if type(stateDef.offset) == "number" then
        stateOffsetY = stateDef.offset
    elseif type(stateDef.offset) == "table" then
        if type(stateDef.offset[1]) == "number" or type(stateDef.offset[2]) == "number" then
            stateOffsetX = stateDef.offset[1] or 0
            stateOffsetY = stateDef.offset[2] or 0
        else
            stateOffsetX = stateDef.offset.x or stateDef.offsetX or 0
            stateOffsetY = stateDef.offset.y or stateDef.offsetY or 0
        end
    else
        stateOffsetX = stateDef.offsetx or stateDef.offsetX or 0
        stateOffsetY = stateDef.offsety or stateDef.offsetY or 0
    end

    local sector = R_PointInSubsector(player.mo.x, player.mo.y).sector
    local extraflag = (player.mo.doom.flags & DF_SHADOW) and (V_ADD|V_10TRANS) or 0
    local lightlevel = sector.lightlevel

    if spriteflags & FF_FULLBRIGHT then
        lightlevel = 255
    elseif spriteflags & FF_FULLDARK then
        lightlevel = 0
    end

    local colormap = IsAboveVersion(202, 14)
        and v.getSectorColormap(sector, player.mo.x, player.mo.y, player.mo.z, lightlevel)
        or nil

    local invuln = player.doom.powers[pw_invulnerability] or 0
    if invuln > 4 * 32 or invuln & 8 then
        colormap = v.getColormap(nil, nil, "COLORMAPROW33")
    end

    local finalX = bobx + stateOffsetX
    local finalY = boby + stateOffsetY + (offset or 0) * FRACUNIT

    v.drawScaled(finalX, finalY, stateDef.scale or FRACUNIT, patch, V_PERPLAYER|extraflag|V_SNAPTOBOTTOM, colormap)
    return true
end

local function drawWeapon(v, player, offset)
    if player.mo.doom.health > 0 then
        if camera.chase then return end
    end

    local weaponYOffset = player.doom and player.doom.switchtimer or 0
    local bobx = player.doom.bobx
    local boby = player.doom.boby + (weaponYOffset * FRACUNIT)

    drawWeaponState(v, player, PSP_WEAPON, bobx, boby, offset)
    drawWeaponState(v, player, PSP_FLASH, bobx, boby, offset)
end

function doom.drawStatusBar(v, player)
	local targetHudDraw = doom.hudDraw[player.doom.customHudPref or doom.currentGame]
	if targetHudDraw then
		targetHudDraw(v, player, true)
	end
end

local doAutomap, keyState = dofile("HUD/Modules/Automap.lua")
local DrawFlashes = dofile("HUD/Modules/Fallback Flashes.lua")
local ST_DrawCarousel = dofile("HUD/Modules/Carousel.lua")

local whatRenderer = "opengl"

rawset(_G, "DOOM_IsPaletteRenderer", function()
	local palrender = CV_FindVar("gr_paletterendering") or {value = 0}
	return whatRenderer == "software" or (whatRenderer == "opengl" and palrender.value == 1)
end)

hud.add(function(v, player)
	hud.disable("score")
	hud.disable("time")
	hud.disable("rings")
	hud.disable("lives")
	hud.disable("tabemblems")
	hud.disable("tokens")
	hud.disable("teamscores")
	hud.disable("rankings")
	hud.disable("coopemeralds")

	if keyState.automap then
		doAutomap(v, player, true)
		return
	end

	ST_DrawCarousel(v, player, 160, 24)

	if doom.noIwadChecks(v) then
		doom.drawInFont(v, 0, 0, FRACUNIT, "STCFN", "YOU PROBABLY DON'T HAVE AN IWAD ACTIVE!\nMAKE SURE YOU LOAD THAT AFTER THE ENGINE!", V_PERPLAYER|V_ALLOWLOWERCASE|V_SNAPTOTOP|V_SNAPTOLEFT)
	end
	whatRenderer = v.renderer()
	local support = P_GetSupportsForSkin(player)
	if player.doom.message and player.doom.messageclock then
		doom.drawInFont(v, 0, 0, FRACUNIT, "STCFN", player.doom.message, V_PERPLAYER|V_ALLOWLOWERCASE|V_SNAPTOTOP|V_SNAPTOLEFT)
	end
	if support.noHUD or (support.properties and support.properties.noHUD) then
		if not support.noWeapons then
			drawWeapon(v, player, 38)
		end
		DrawFlashes(v, player)
		return
	end

	if not player.mo then DrawFlashes(v, player) return end

	local override = doom.callHook("GetHudDraw", doom.hookTypes.lastfunc, player)
	local target = override or player.doom.customHudPref or doom.currentGame
	local targetHudDraw = doom.hudDraw[target]
	if targetHudDraw then
		targetHudDraw(v, player)
	else
		print("Invalid target '" .. tostring(target) .. "'")
	end

	DrawFlashes(v, player)
end)

rawset(_G, "drawWeapon", drawWeapon)

local patchcache = {}

local function getPatch(v, name)
	local p = patchcache[name]
	if not p then
		p = v.cachePatch(name)
		patchcache[name] = p
	end
	return p
end

local function getWeaponSelectYOffset(delay)
	local q = delay or 0
	local del = 0
	local p = 16

	while q > 0 do
		if q > p then
			del = $ + p
			q = (q - p) / 2
			if p > 1 then
				p = p / 2
			end
		else
			del = $ + q
			break
		end
	end

	return del
end

local function getCurrentWeaponDelay(player)
	local psp = DOOM_GetPSprite(player, PSP_WEAPON)
	local wepDef = DOOM_GetWeaponDef(player)

	if not psp or not wepDef then
		return 0
	end

	-- Only animate the cursor while the weapon is in its attack state.
	if psp.state ~= "attack" then
		return 0
	end

	local attack = wepDef.states and wepDef.states.attack
	if not attack then
		return 0
	end

	local delay = psp.tics or 0
	local frame = (psp.frame or 1) + 1

	for i = frame, #attack do
		delay = $ + (attack[i].tics or 0)
	end

	return delay
end

local function drawWeaponSelect(v, xoffs, y, delay)
	local del = getWeaponSelectYOffset(delay)
	v.draw(6 + xoffs, y - 2 - (del / 2), v.cachePatch("CURWEAP"), V_PERPLAYER|V_SNAPTOBOTTOM)
end

---@param v videolib
doom.hudDraw["johnringslinger"] = function(v, player, inAutomap)
	if inAutomap then return end
	drawWeapon(v, player, 38)
	local funcs = P_GetMethodsForSkin(player)
	local ammo = funcs.getCurAmmo(player)
	local weapon = player.doom.curwep
	local weaponDelay = getCurrentWeaponDelay(player)
	local health = funcs.getHealth(player)
	local armor = funcs.getArmor(player)

	local hudflags = V_PERPLAYER|V_SNAPTOTOP|V_SNAPTOLEFT
	v.draw(17, 11, v.cachePatch("STTHEALT"), hudflags)
	doom.drawInFont(v, (100) * FRACUNIT, (11) * FRACUNIT, FRACUNIT, "S2FONT", tostring(health) .. "%", hudflags, "right")
	v.draw(17, 11 + 16, v.cachePatch("STTARMOR"), hudflags)
	doom.drawInFont(v, (100) * FRACUNIT, (11 + 16) * FRACUNIT, FRACUNIT, "S2FONT", tostring(armor) .. "%", hudflags, "right")


	if altArmsDisplay then
		doom.drawInFont(v, 248 * FRACUNIT, 176 * FRACUNIT, FRACUNIT, "SRBFN", "ARMS", V_PERPLAYER|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "left")
		if ammo ~= false then
			local myWep = doom.weapons[weapon]
			local myAmmoType = myWep and myWep.ammotype
			local myAmmoDef = doom.ammos[myAmmoType]

			doom.drawInFont(v, 32 * FRACUNIT, 176 * FRACUNIT, FRACUNIT, "SRBFN", tostring(myAmmoDef.name), V_PERPLAYER|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "left")
			doom.drawInFont(v, 48 * FRACUNIT, 184 * FRACUNIT, FRACUNIT, "SRBFN", tostring(ammo), V_PERPLAYER|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "left")
			v.draw(16 + 22, 176 + 10, getPatch(v, "STLIVEX"), V_PERPLAYER|V_SNAPTOLEFT|V_SNAPTOBOTTOM)

			if myAmmoDef and myAmmoDef.icon then
				v.draw(16, 176, getPatch(v, myAmmoDef.icon), V_PERPLAYER|V_SNAPTOLEFT|V_SNAPTOBOTTOM)
			end
		end
	else
		local shit = {
			{"matchring", "rs_brassknuckles"},
			{"automaticring"},
			{"homingring", "bouncering"},
			{"scatterring"},
			{"grenadering"},
			{"explosionring"},
			{"railring"}
		}

		local ypos = 176
		local xpos = (BASEVIDWIDTH / 2) - (7 * 10) - 6

		for slot, entries in ipairs(shit) do
			local weaponcount = 0

			for _, name in ipairs(entries) do
				local myWep = doom.weapons[name]
				if not myWep then
					continue
				end

				local myAmmoType = myWep.ammotype
				local iHasIt = player.doom.weapons[name]
				local ammolessWeapon = myWep.shotcost <= 0

				if not iHasIt and not player.doom.ammo[myAmmoType] then
					continue
				end

				local flags = V_SNAPTOBOTTOM
				local textflags = V_SNAPTOBOTTOM
				local max = funcs.getMaxFor(player, myAmmoType) or 0
				local cur = player.doom.ammo[myAmmoType] or 0

				if not ammolessWeapon then
					if cur >= max then
						textflags = $|V_YELLOWMAP
					end
				end

				if not iHasIt then
					flags = $|V_80TRANS
					textflags = $|V_TRANSLUCENT
				elseif not cur then
					flags = $|V_TRANSLUCENT
					textflags = false
				end

				if ammolessWeapon then
					textflags = false
				end

				local x = xpos + ((slot - 1) * 20)
				local y = ypos - (weaponcount * 20)

				v.draw(x, y, v.cachePatch(myWep.user_johnringslingericon), flags)

				if name == player.doom.curwep then
					drawWeaponSelect(v, x - 8, y, weaponDelay)
				end

				weaponcount = $ + 1

				if not textflags then
					continue
				end

				local translation = nil
				if (textflags & V_YELLOWMAP) then
					translation = "SRB2YELLOWMAP"
				end
				doom.drawInFont(v, (16 + x) * FRACUNIT, (y + 8) * FRACUNIT, FRACUNIT, "TNYFN", tostring(player.doom.ammo[myAmmoType]), textflags, "right", v.getColormap(nil, nil, translation))
			end
		end
	end
end