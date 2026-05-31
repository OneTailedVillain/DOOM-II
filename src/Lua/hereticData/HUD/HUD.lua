local colorlettertotranslation = {
	G = "BOOMCRGREEN",
	B = "BOOMCRBLUE2",
	R = "BOOMCRRED",
	Y = "BOOMCRGOLD",
	A = "BOOMCRGRAY"
}

-- Too lazy to actually build fonts proper,
-- So get this hardcode instead
local fontToPatch = {
	STT = {
		[string.byte("-")] = "STTMINUS",
		[string.byte("%")] = "STTPRCNT",
	}
}

for i = 0, 9 do
	fontToPatch.STT[i + 48] = "STTNUM" .. i
end

---@param v videolib
local function drawMonospaceFont(v, x, y, scale, font, str, flags, alignment, monospacepx, colors)
	local strlen = #str
	local strwidth = strlen * monospacepx * scale
	if alignment == "right" then
		x = $ - strwidth
	elseif alignment == "center" then
		x = $ - (strwidth / 2)
	end

	local drawX = x

	for i = 1, strlen do
		local letter = str:byte(i, i)
		local translation = str.char(colors:byte(i, i))
		if letter == nil then continue end
		local patchname = fontToPatch[font][letter]
		local colormap = v.getColormap(nil, nil, colorlettertotranslation[translation])
		if type(patchname) != "string" then
			print("Unexpected type for font " .. font .. " char " .. string.char(letter))
		else
			v.drawScaled(drawX, y, scale, v.cachePatch(patchname), flags, colormap)
		end
		drawX = $ + (monospacepx * scale)
	end
end

---@param num number|string
---@param digitColor string
---@param percentColor string
---@param includePercent boolean
local function buildColorString(num, digitColor, percentColor, includePercent)
	local str = tostring(num)
	local len = #str

	-- Build digit portion
	local result = ""
	for i = 1, len do
		result = $ + digitColor
	end

	-- Add percent color if needed
	if includePercent then
		result = $ + percentColor
	end

	return result
end

local function drawBigNum(v, x, y, num, maxnum, thresholdset, flags, percent, player)
    num = tonumber(num) or 0
    maxnum = tonumber(maxnum) or 0

    local fx = x * FRACUNIT
    local fy = y * FRACUNIT

    local offsetpatch = v.cachePatch("STTNUM0")
    local offset = offsetpatch.width

	local digitColor = "R"
    local numberColorization
    local grayPercenting
	local numpct
	local t_red, t_yellow, t_green = 0, 0, 0

	if not maxnum or not thresholdset then
		numberColorization = 0
		grayPercenting = 0
	else
		-- Calculate percent for color thresholds
		numpct = (maxnum == 0) and 100 or (num * 100) / maxnum

		-- Access HUD threshold config via new system
		if thresholdset == "ammo" then
			t_red    = DOOM_GetConfigResolveValue(player, "t_ammo_red") or 25
			t_yellow = DOOM_GetConfigResolveValue(player, "t_ammo_yellow") or 50
		elseif thresholdset == "health" then
			t_red    = DOOM_GetConfigResolveValue(player, "t_health_red") or 25
			t_yellow = DOOM_GetConfigResolveValue(player, "t_health_yellow") or 50
			t_green  = DOOM_GetConfigResolveValue(player, "t_health_green") or 100
		elseif thresholdset == "armor" then
			t_red    = DOOM_GetConfigResolveValue(player, "t_armor_red") or 25
			t_yellow = DOOM_GetConfigResolveValue(player, "t_armor_yellow") or 50
			t_green  = DOOM_GetConfigResolveValue(player, "t_armor_green") or 100
		end

		numberColorization = DOOM_GetConfigResolveValue(player, "hudColorization") or 0
		grayPercenting = DOOM_GetConfigResolveValue(player, "hudGrayPercenting") or 0
	end

    if numberColorization ~= 0 then
        if t_green then
            if numpct < t_red then
                digitColor = "R"
            elseif numpct < t_yellow then
                digitColor = "Y"
            elseif numpct <= t_green then
                digitColor = "G"
            else
                digitColor = "B"
            end
        else
            if numpct < t_red then
                digitColor = "R"
            elseif numpct < t_yellow then
                digitColor = "Y"
            else
                digitColor = "G"
            end
        end
    end

    local percentColor = (grayPercenting ~= 0) and "A" or digitColor
    local colors = buildColorString(tostring(num), digitColor, percentColor, percent)

    if percent then
        drawMonospaceFont(
            v,
            fx + (offset * FRACUNIT),
            fy,
            FRACUNIT,
            "STT",
            tostring(num) .. "%",
            flags,
            "right",
            offset,
            colors
        )
    else
        drawMonospaceFont(
            v,
            fx,
            fy,
            FRACUNIT,
            "STT",
            tostring(num),
            flags,
            "right",
            offset,
            colors
        )
    end
end

local function DrawStatusBarNumbers(v, player, noSBar)
	local funcs = P_GetMethodsForSkin(player)
	local myHealth = funcs.getHealth(player) or 0
	local myMaxHealth = funcs.getMaxHealth(player) or 0
	local myArmor = funcs.getArmor(player) or 0
	local myMaxArmor = funcs.getMaxArmor(player) or 0
	local myAmmo = funcs.getCurAmmo(player)
	local myMaxAmmo = funcs.getMaxFor(player, funcs.getCurAmmoType(player))

	local xFlags = 0
	if noSBar then
		xFlags = V_SNAPTOLEFT
	end

	if myAmmo != false then
		drawBigNum(v, 44, 171, myAmmo, myMaxAmmo, "ammo", V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, false, player)
	end

	drawBigNum(v, 90, 171, myHealth, myMaxHealth, "health", V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, true, player)

	if not G_RingSlingerGametype() then
		if player.doom.prefs.weaponlightupbehavior == "Original" then
			local whatToCheck = {
				"brassknuckles",
				"pistol",
				"shotgun",
				"chaingun",
				"rocketlauncher",
				"plasmarifle",
				"bfg9000"
			}
			for i = 0, 5 do
				local whatToIndex = whatToCheck[i + 2]
				local doIHaveIt = funcs.hasWeapon(player, whatToIndex)
				local whatFont = doIHaveIt and "STYSNUM" or "STGNUM"
				drawInFont(v, (111 + (i%3 * 12))*FRACUNIT, (172 + (i/3 * 10))*FRACUNIT, FRACUNIT, whatFont, i + 2, V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, "left")
			end
		else
			local wepcats = {
				[2] = {},
				[3] = {},
				[4] = {},
				[5] = {},
				[6] = {},
				[7] = {}
			}

			---@param wepdef weapondef_t
			for wepname, wepdef in pairs(doom.weapons) do
				if wepdef.weaponslot and wepdef.weaponslot >= 2 and wepdef.weaponslot <= 7 then
					wepcats[wepdef.weaponslot][wepname] = true
				end
			end

			for i = 0, 5 do
				local whatToIndex = i + 2
				local doIHaveAWeaponInThisSlot = false
				for wepname, _ in pairs(wepcats[whatToIndex]) do
					if funcs.hasWeapon(player, wepname) then
						doIHaveAWeaponInThisSlot = true
						break
					end
				end
				local whatFont = doIHaveAWeaponInThisSlot and "STYSNUM" or "STGNUM"
				drawInFont(v, (111 + (i%3 * 12))*FRACUNIT, (172 + (i/3 * 10))*FRACUNIT, FRACUNIT, whatFont, i + 2, V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, "left")
			end
		end
	else
		drawBigNum(v, 138, 171, doom.getFrags(player), false, nil, V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, false, player)
	end

	if noSBar then
		xFlags = V_SNAPTORIGHT
	end

	drawBigNum(v, 221, 171, myArmor, myMaxArmor,  "armor", V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, true, player)

	local ammosToIndex = {
		"bullets",
		"shells",
		"rockets",
		"cells"
	}
	for i = 0, 3 do
		local whatToIndex = ammosToIndex[i + 1]
		local curAmmo = funcs.getAmmoFor(player, whatToIndex)
		local whatFont = curAmmo != false and "STYSNUM" or "STGNUM"
		curAmmo = $ or 0
		drawInFont(v, 288*FRACUNIT, (173 + (i * 6))*FRACUNIT, FRACUNIT, whatFont, curAmmo, V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, "right")
	end
	for i = 0, 3 do
		local whatToIndex = ammosToIndex[i + 1]
		local maxAmmo = funcs.getMaxFor(player, whatToIndex)
		local whatFont = maxAmmo != false and "STYSNUM" or "STGNUM"
		maxAmmo = $ or 0
		drawInFont(v, 314*FRACUNIT, (173 + (i * 6))*FRACUNIT, FRACUNIT, whatFont, maxAmmo, V_PERPLAYER|V_SNAPTOBOTTOM|xFlags, "right")
	end
end

local function DrawKeys(v, player, noSBar)
	local keyColors = {"BLUE", "YELLOW", "RED"} -- In order of how DOOM draws these
	local keyX = { 239, 239, 239 }
	local keyY = { 171, 181, 191 }

	local xFlags = 0
	if noSBar then
		xFlags = V_SNAPTORIGHT
	end

	local keys = {
		v.cachePatch("STKEYS2"),
		v.cachePatch("STKEYS0"),
		v.cachePatch("STKEYS1"),
		v.cachePatch("STKEYS5"),
		v.cachePatch("STKEYS3"),
		v.cachePatch("STKEYS4"),
	}

	local bitNums = {
		[1]   = 1,
		[2]   = 2,
		[4]   = 3,
		[8]   = 4,
		[16]  = 5,
		[32]  = 6,
		[64]  = 7,
		[128] = 8,
		[256] = 9,
		[512] = 10,
	}

	for i, color in ipairs(keyColors) do
		local skullKeyName  = "KEY_SKULL" .. color
		local normalKeyName = "KEY_" .. color
		local keyBit = nil

		-- prefer skull variant
		if (player.doom.keys or 0) & doom[skullKeyName] != 0 then
			keyBit = skullKeyName
		elseif (player.doom.keys or 0) & doom[normalKeyName] != 0 then
			keyBit = normalKeyName
		end

		if keyBit then
			v.draw(
				keyX[i],
				keyY[i],
				keys[bitNums[doom[keyBit]]], -- ts so mid
				V_PERPLAYER|V_SNAPTOBOTTOM|xFlags
			)
		end
	end
end


local function drawStatusBar(v, player, hudPref)
	local sbpatch = hudPref != 6 and hudPref != 7
	if sbpatch then
		local screenWidth = v.width()
		local hudScaleInt, hudScaleFixed = v.dupx()
		local maybeTrueWidth = screenWidth / hudScaleInt

		local bottomBorderPatch = v.cachePatch("BRDR_B")
		local bottomBorderWidth = bottomBorderPatch.width
		local bottomBorderRepeats = (maybeTrueWidth / bottomBorderWidth)

		local centerBorderPatch = v.cachePatch("BRDR_C")
		local centerBorderWidth = centerBorderPatch.width
		local centerBorderRepeats = (maybeTrueWidth / centerBorderWidth)

		for i = 0, centerBorderRepeats do
			v.draw(i * centerBorderWidth, 168, centerBorderPatch, V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_PERPLAYER)
		end

		for i = 0, bottomBorderRepeats do
			v.draw(i * bottomBorderWidth, 168, bottomBorderPatch, V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_PERPLAYER)
		end

		local statusBarPatch = v.cachePatch("STBAR")
		local xOffset = 0
		if statusBarPatch.width == 426 then
			xOffset = -53
		end
		v.draw(xOffset, 168, statusBarPatch, V_PERPLAYER|V_SNAPTOBOTTOM)
		if not G_RingSlingerGametype() then
			v.draw(104, 168, v.cachePatch("STARMS"), V_PERPLAYER|V_SNAPTOBOTTOM)
		end
	end
	if netgame then
		v.draw(143, 169, v.cachePatch("STFB0"), V_PERPLAYER|V_SNAPTOBOTTOM, v.getColormap("johndoom", player.mo.color))
	end

	DrawStatusBarNumbers(v, player, not sbpatch)
	DrawKeys(v, player, not sbpatch)
end

doom.hudDraw["heretic"] = function(v, player)
	local funcs = P_GetMethodsForSkin(player)
	local myHealth = funcs.getHealth(player) or 0
	local myArmor = funcs.getArmor(player) or 0
	local myAmmo = funcs.getCurAmmo(player)

	if doom.issrb2 then
		drawWeapon(v, player, 38)
		srb2hud.keys(v, player, player.doom.keys)
		srb2hud.ammo(v, player, myAmmo, player.doom.curwep)
		srb2hud.health(v, player, myHealth)
		srb2hud.armor(v, player, myArmor)
		srb2hud.frags(v, player, player.doom.frags)
		return
	end

	local hudPref = tonumber(DOOM_GetConfigStoreValue(player, "hudstyle")) or 1
	local isActuallyBoom = hudPref <= 5 and hudPref > 1

	drawWeapon(v, player, doom.hudWeaponOffsets[hudPref] or 38)

	drawStatusBar(v, player, hudPref)
end