local hudDir = "HUD/Alt HUDs/"

local doBOOMHud = dofile(hudDir .. "Boom.lua")
local srb2hud = dofile(hudDir .. "SRB2.lua")

-- Table of face sprite names in Doom IWAD order
local st_faces = {
	-- Pain offset 0
	"STFST00", "STFST01", "STFST02",  -- straight ahead
	"STFTL00", "STFTR00",             -- turn left/right
	"STFOUCH0",                        -- ouch
	"STFEVL0",                         -- evil grin
	"STFKILL0",                        -- rampage

	-- Pain offset 1
	"STFST10", "STFST11", "STFST12",
	"STFTL10", "STFTR10",
	"STFOUCH1",
	"STFEVL1",
	"STFKILL1",

	-- Pain offset 2
	"STFST20", "STFST21", "STFST22",
	"STFTL20", "STFTR20",
	"STFOUCH2",
	"STFEVL2",
	"STFKILL2",

	-- Pain offset 3
	"STFST30", "STFST31", "STFST32",
	"STFTL30", "STFTR30",
	"STFOUCH3",
	"STFEVL3",
	"STFKILL3",

	-- Pain offset 4
	"STFST40", "STFST41", "STFST42",
	"STFTL40", "STFTR40",
	"STFOUCH4",
	"STFEVL4",
	"STFKILL4",

	-- God face
	"STFGOD0",

	-- Dead face
	"STFDEAD0"
}

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

    -- Calculate percent for color thresholds
    local numpct = (maxnum == 0) and 100 or (num * 100) / maxnum

    -- Access HUD threshold config via new system
    local t_red, t_yellow, t_green = 0, 0, 0
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

    local digitColor = "R"
    local numberColorization = DOOM_GetConfigResolveValue(player, "hudColorization") or 0
    local grayPercenting = DOOM_GetConfigResolveValue(player, "hudGrayPercenting") or 0

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
		for wepname, wepdef in ipairs(doom.weapons) do
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

local function drawFace(v, player)
	local chardef = P_GetSupportsForSkin(player)
	local index = player.doom.faceindex + 1
	if index > #st_faces then index = #st_faces end
	local patch
	if chardef.st_faces then
		patch = chardef.st_faces[index]
	else
		patch = st_faces[index]
	end
	local prefixmaybe = chardef.faceprefix or ""
	if patch != nil then
		v.draw(143, 168, v.cachePatch(prefixmaybe .. patch), V_PERPLAYER|V_SNAPTOBOTTOM)
	else
		print("STATUS FACE INDEX " .. index .. " IS MISSING AN ASSOCIATED TABLE ENTRY! MOD SUCKS PLS FIX")
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
		v.draw(104, 168, v.cachePatch("STARMS"), V_PERPLAYER|V_SNAPTOBOTTOM)
	end
	if netgame then
		v.draw(143, 169, v.cachePatch("STFB0"), V_PERPLAYER|V_SNAPTOBOTTOM, v.getColormap("johndoom", player.mo.color))
	end

	DrawStatusBarNumbers(v, player, not sbpatch)
	DrawKeys(v, player, not sbpatch)
	if hudPref != 6 then
		drawFace(v, player)
	end
end

doom.drawStatusBar = drawStatusBar

local doAutomap, keyState = dofile("HUD/Modules/Automap.lua")
local DrawFlashes = dofile("HUD/Modules/Fallback Flashes.lua")
local ST_DrawCarousel = dofile("HUD/Modules/Carousel.lua")

local whatRenderer = "opengl"

rawset(_G, "DOOM_IsPaletteRenderer", function()
	local palrender = CV_FindVar("gr_paletterendering") or {value = 0}
	return whatRenderer == "software" or (whatRenderer == "opengl" and palrender.value == 1)
end)

doom.hudWeaponOffsets = {
	[0] = 38,
	[1] = 16,
	[2] = 38,
	[3] = 38,
	[4] = 38,
	[5] = 38,
	[6] = 38,
	[7] = 38,
}

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

	local cdef = P_GetSupportsForSkin(player)
	local automapthirdargument = false

	if cdef.nohudinautomap != nil then
		automapthirdargument = cdef.nohudinautomap
	elseif cdef.personalhudheight != nil then
		automapthirdargument = cdef.personalhudheight
	end

	if keyState.automap then
		doAutomap(v, player, cdef.nohudinautomap)
		return
	end

	ST_DrawCarousel(v, player, 160, 24)

	if not v.patchExists("STFST01") or not v.patchExists("PLAYA1") then
		drawInFont(v, 0, 0, FRACUNIT, "STCFN", "YO! YOU DON'T HAVE A VALID IWAD LOADED YET!\nGRAB YOUR COPY OF DOOM, DOOM II, OR FREEDOOM\nAND LOAD THAT FIRST!", V_PERPLAYER|V_ALLOWLOWERCASE|V_SNAPTOTOP|V_SNAPTOLEFT)
		return
	end
	whatRenderer = v.renderer()
	local support = P_GetSupportsForSkin(player)
	if player.doom.message and player.doom.messageclock then
		drawInFont(v, 0, 0, FRACUNIT, "STCFN", player.doom.message, V_PERPLAYER|V_ALLOWLOWERCASE|V_SNAPTOTOP|V_SNAPTOLEFT)
	end
	if support.noHUD then
		DrawFlashes(v, player)
		if not support.noWeapons then
			drawWeapon(v, player, 38)
		end
		return
	end

	if not player.mo then DrawFlashes(v, player) return end

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


	local hudPref = DOOM_GetConfigStoreValue(player, "hudstyle") or 0
	local isActuallyBoom = hudPref <= 5 and hudPref > 1

	drawWeapon(v, player, doom.hudWeaponOffsets[hudPref])

	if isActuallyBoom then
		doBOOMHud(v, player)
	elseif
		drawStatusBar(v, player, hudPref)
	end
	DrawFlashes(v, player)
end, "game")

hud.add(function(v, player)
	if doom.patchesLoaded then return end
	for i = 0, INT32_MAX do
		if R_CheckTextureNameForNum(i) == "-" then break end -- Probably at the end of list
		doom.texturesByNum[i] = v.cachePatch(R_TextureNameForNum(i))
	end
	doom.patchesLoaded = true
end, "game")