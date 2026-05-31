local colorlettertotranslation = {
	G = "BOOMCRGREEN",
	B = "BOOMCRBLUE2",
	R = "BOOMCRRED",
	Y = "BOOMCRGOLD",
	A = "BOOMCRGRAY"
}

-- Too lazy to actually build fonts proper,
-- So get this hardcode instead
local fontToPatch = {IN = {}}

for i = 0, 9 do
	fontToPatch.IN[i + 48] = "IN" .. i
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
            "IN",
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
            "IN",
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

	if myAmmo != false then
		drawBigNum(v, 109, 162, myAmmo, myMaxAmmo, "ammo", V_PERPLAYER|V_SNAPTOBOTTOM, false, player)
	end

	drawBigNum(v, 61, 170, myHealth, nil, nil, V_PERPLAYER|V_SNAPTOBOTTOM, false, player)


	drawBigNum(v, 224, 170, myArmor, myMaxArmor,  "armor", V_PERPLAYER|V_SNAPTOBOTTOM, false, player)
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

local function DrawCommonBar(v, player)
	local chainY = player.doom.h_chainy or 190
	local healthPos = player.doom.h_healthpos or 0

	v.draw(0, 148, v.cachePatch("LTFCTOP"), V_SNAPTOBOTTOM|V_PERPLAYER)
	v.draw(290, 148, v.cachePatch("RTFCTOP"), V_SNAPTOBOTTOM|V_PERPLAYER)

	v.draw(0, 190, v.cachePatch("CHAINBAC"), V_SNAPTOBOTTOM|V_PERPLAYER)
	v.draw(2+(healthPos%17), chainY, v.cachePatch("CHAIN"), V_SNAPTOBOTTOM|V_PERPLAYER)
	v.draw(17+healthPos, chainY, v.cachePatch("LIFEGEM2"), V_SNAPTOBOTTOM|V_PERPLAYER)
	v.draw(0, 190, v.cachePatch("LTFACE"), V_SNAPTOBOTTOM|V_PERPLAYER)
	v.draw(276, 190, v.cachePatch("RTFACE"), V_SNAPTOBOTTOM|V_PERPLAYER)
end

local ChainWiggle = 0

addHook("PlayerThink", function(player)
	local funcs = P_GetMethodsForSkin(player)
	local curHealth = funcs.getHealth(player)
	if player.doom.h_healthmarker == nil then
		player.doom.h_healthmarker = curHealth
	end

	local delta
	if leveltime%1 then
		ChainWiggle = DOOM_Random()&1
	end

	if curHealth < 0 then
		curHealth = 0
	end

	if curHealth < player.doom.h_healthmarker then
		delta = (player.doom.h_healthmarker-curHealth)>>2
		if delta < 1 then
			delta = 1
		elseif delta > 8 then
			delta = 8
		end
		player.doom.h_healthmarker = $ - delta
	elseif curHealth < player.doom.h_healthmarker then
		delta = (curHealth-player.doom.h_healthmarker)>>2
		if delta < 1 then
			delta = 1
		elseif delta > 8 then
			delta = 8
		end
		player.doom.h_healthmarker = $ + delta
	end
end)

addHook("PlayerThink", function(player)
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player)
	if player.doom.h_oldhealth != player.doom.h_healthmarker or (player.doom.h_oldhealth == nil) then
		player.doom.h_oldhealth = player.doom.h_healthmarker
		player.doom.h_healthpos = player.doom.h_healthmarker
		if player.doom.h_healthpos < 0 then
			player.doom.h_healthpos = 0
		elseif player.doom.h_healthpos > 100 then
			player.doom.h_healthpos = 100
		end
		player.doom.h_healthpos = $*256/100
		player.doom.h_chainy = player.doom.h_healthmarker == health and 191 or 191+ChainWiggle
	end
end)

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

		v.draw(0, 158, v.cachePatch("BARBACK"), V_SNAPTOBOTTOM|V_PERPLAYER)
		if (player.pflags & PF_GODMODE) then
			v.draw(16, 167, v.cachePatch("GOD1"), V_SNAPTOBOTTOM|V_PERPLAYER)
			v.draw(287, 167, v.cachePatch("GOD1"), V_SNAPTOBOTTOM|V_PERPLAYER)
		end
		DrawCommonBar(v, player)
	end

	if netgame then
		v.draw(143, 169, v.cachePatch("STFB0"), V_PERPLAYER|V_SNAPTOBOTTOM, v.getColormap("johndoom", player.mo.color))
	end

	DrawStatusBarNumbers(v, player, not sbpatch)
	DrawKeys(v, player, not sbpatch)
end

doom.hudDraw["heretic"] = function(v, player)
	drawWeapon(v, player, 38)
	drawStatusBar(v, player, 1)
end