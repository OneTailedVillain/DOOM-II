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

local function drawWeapon(v, player, offset)
	local bobAngle = ((128 * leveltime) & 8191) << 19
	local bobx = FixedMul((player.hl1wepbob or 0), cos(bobAngle))
	bobAngle = ((128 * leveltime) & 4095) << 19
	local boby = FixedMul((player.hl1wepbob or 0), sin(bobAngle))
	local preScaledOffset = (player.doom.deadtimer or player.deadtimer) + (player.doom and player.doom.switchtimer or 0)
	boby = $ + 6*FRACUNIT * preScaledOffset
	local sprite = doom.weapons[player.doom.curwep].sprite
	local whatFrame = doom.weapons[player.doom.curwep].states[player.doom.wepstate][player.doom.wepframe].frame
	local patch = v.getSpritePatch(sprite, whatFrame)
	local sector = R_PointInSubsector(player.mo.x, player.mo.y).sector

	local extraflag = (player.mo.doom.flags & DF_SHADOW) and V_MODULATE or 0
		local colormap = IsAboveVersion(202, 13)
			and v.getSectorColormap(sector, player.mo.x, player.mo.y, player.mo.z, sector.lightlevel)
			or nil

	v.drawScaled(bobx, boby + offset * FRACUNIT, FRACUNIT, patch, V_PERPLAYER|extraflag, colormap)
end

local function DrawStatusBarNumbers(v, player)
	local funcs = P_GetMethodsForSkin(player)
	local myHealth = funcs.getHealth(player) or 0
	local myArmor = funcs.getArmor(player) or 0
	local myAmmo = funcs.getCurAmmo(player)

	local percentPatch = v.cachePatch("STTNUM0")
	local percentsOffset = percentPatch.width

	if myAmmo != false then
		drawInFont(v, 44*FRACUNIT, 171*FRACUNIT, FRACUNIT, "STT", tostring(myAmmo), V_PERPLAYER, "right")
	end
	drawInFont(v, (90 + percentsOffset)*FRACUNIT, 171*FRACUNIT, FRACUNIT, "STT", myHealth .. "%", V_PERPLAYER, "right")
	drawInFont(v, (221 + percentsOffset)*FRACUNIT, 171*FRACUNIT, FRACUNIT, "STT", myArmor .. "%", V_PERPLAYER, "right")
	local ammosToIndex = {
		"bullets",
		"shells",
		"rockets",
		"cells"
	}
	for i = 0, 3 do
		local whatToIndex = ammosToIndex[i + 1]
		drawInFont(v, 288*FRACUNIT, (173 + (i * 6))*FRACUNIT, FRACUNIT, "STYSNUM", player.doom.ammo[whatToIndex], V_PERPLAYER, "right")
	end
	for i = 0, 3 do
		local whatToIndex = ammosToIndex[i + 1]
		drawInFont(v, 314*FRACUNIT, (173 + (i * 6))*FRACUNIT, FRACUNIT, "STYSNUM", doom.ammos[whatToIndex].max, V_PERPLAYER, "right")
	end
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
		local doIHaveIt = player.doom.weapons[whatToIndex]
		local whatFont = doIHaveIt and "STYSNUM" or "STGNUM"
		drawInFont(v, (111 + (i%3 * 12))*FRACUNIT, (172 + (i/3 * 10))*FRACUNIT, FRACUNIT, whatFont, i + 2, V_PERPLAYER, "left")
	end
end

local function drawFace(v, player)
	local index = player.doom.faceindex + 1
	local patch = st_faces[index]
	if patch != nil then
		v.draw(143, 168, v.cachePatch(patch), V_PERPLAYER)
	else
		print(index .. " IS MISSING AN ASSOCIATED ENTRY! MOD SUCKS PLS FIX")
	end
end

local function DrawKeys(v, player)
	local keyColors = {"BLUE", "YELLOW", "RED"} -- In order of how DOOM draws these
	local keyX = { 239, 239, 239 }
	local keyY = { 171, 181, 191 }

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
				keys[bitNums[doom[keyBit]]] -- ts so mid
			)
		end
	end
end

local function drawStatusBar(v, player)
	v.draw(0, 168, v.cachePatch("STBAR"), V_PERPLAYER)
	v.draw(104, 168, v.cachePatch("STARMS"), V_PERPLAYER)
	if netgame then
		v.draw(143, 169, v.cachePatch("STFB0"), V_PERPLAYER, v.getColormap("johndoom", player.mo.color))
	end

	DrawStatusBarNumbers(v, player)
	DrawKeys(v, player)
	drawFace(v, player)

	drawInFont(v, 0, 0, FRACUNIT, "STCFN", player.doom.message)
end
local whatRenderer = "opengl"

rawset(_G, "DOOM_IsPaletteRenderer", function()
	return whatRenderer == "software" or (whatRenderer == "opengl" and CV_FindVar("gr_paletterendering").value == 1) 
end)

local function DrawFlashes(v, ply)
	if splitscreen then return end
	if DOOM_IsPaletteRenderer() then return end

	local color_flash = 0
	local color_flash_intensity = 0
	local damage_flash = ply.doom.damagecount
    local bzc = 0

    if ply.doom.powers[pw_strength] and ply.doom.powers[pw_strength] > 0 then
        bzc = 12 - (ply.doom.powers[pw_strength] >> 6)
        if bzc > damage_flash then
            damage_flash = bzc
        end
    end
	damage_flash = ($ + 7) >> 3

	local bonus_flash = (ply.doom.bonuscount + 7) >> 3
	local hazardsuit_flash = 0
	if ply.doom.powers[pw_ironfeet] and ((ply.doom.powers[pw_ironfeet] > (4 * 32)) or (ply.doom.powers[pw_ironfeet] & 8)) then
		hazardsuit_flash = 4
	end

	if damage_flash then
		color_flash = 176
		color_flash_intensity = min(damage_flash, 5)
	elseif bonus_flash then
		color_flash = 160
		color_flash_intensity = min(bonus_flash, 4)
	elseif hazardsuit_flash then
		color_flash = 116
		color_flash_intensity = hazardsuit_flash
	end
	
	if color_flash then
		v.fadeScreen(color_flash, max(min(color_flash_intensity, 10), 0))
	end
end

-- srb2 march 2000 prototype defaults to "kahmf"

local srb2hud = {
	keys = function(v, player, keys)
		keys = $ or 0
		local c = 1

		local keyOrder = {
			{doom.KEY_SKULLRED,    v.cachePatch("STKEYS3")},
			{doom.KEY_SKULLBLUE,   v.cachePatch("STKEYS4")},
			{doom.KEY_SKULLYELLOW, v.cachePatch("STKEYS5")},
			{doom.KEY_RED,         v.cachePatch("STKEYS0")},
			{doom.KEY_BLUE,        v.cachePatch("STKEYS1")},
			{doom.KEY_YELLOW,      v.cachePatch("STKEYS2")},
		}

		for _, k in ipairs(keyOrder) do
			local keyBit  = k[1]
			local patch   = k[2]

			if (keys & keyBit) != 0 then
				v.draw(
					318 - c * 8,
					198 - 24,
					patch
				)
				c = $ + 1
			end
		end
	end,
	ammo = function(v, player, ammo, weapon)
		if ammo != false then
			/*
			-- FIXME: SRB2 SIGSEGVs whenever we cache a patch like SBOAMMO1?? Reserving the patch doesn't fix it
			-- Weirder is that the other SBO patches don't do this??
			local myWep = doom.weapons[weapon]
			local myAmmoType = myWep.ammotype
			local myAmmoDef = doom.ammos[myAmmoType]
			local myAmmoIcon = myAmmoDef.icon
			local myIconPatch = v.cachePatch("BRDR_B")
			v.draw(236, 198, myIconPatch)
			*/
			drawInFont(v, 234*FRACUNIT, 182*FRACUNIT, FRACUNIT, "STT", tostring(ammo), V_PERPLAYER, "right")
		end
	end,
	health = function(v, player, health)
		v.draw(16, 42, v.cachePatch("SBOHEALT"))
		drawInFont(v, 112*FRACUNIT, 40*FRACUNIT, FRACUNIT, "STT", tostring(max(health - 1, 0)), V_PERPLAYER, "right")
	end,
	armor = function(v, player, armor)
		v.draw(17, 26, v.cachePatch("SBOARMOR"))
		drawInFont(v, 112*FRACUNIT, 24*FRACUNIT, FRACUNIT, "STT", tostring(max(armor, 0)), V_PERPLAYER, "right")
	end,
	frags = function(v, player, frags)
		v.draw(16, 10, v.cachePatch("SBOFRAGS"))
		drawInFont(v, 128*FRACUNIT, 9*FRACUNIT, FRACUNIT, "STT", tostring(max((frags or 0), 0)), V_PERPLAYER, "right")
	end,
}

hud.add(function(v, player)
	whatRenderer = v.renderer()
	local support = P_GetSupportsForSkin(player)
	drawInFont(v, 0, 0, FRACUNIT, "STCFN", player.doom.message)
	if support.noHUD then DrawFlashes(v, player) return end

	local funcs = P_GetMethodsForSkin(player)
	local myHealth = funcs.getHealth(player) or 0
	local myArmor = funcs.getArmor(player) or 0
	local myAmmo = funcs.getCurAmmo(player)

	hud.disable("score")
	hud.disable("time")
	hud.disable("rings")
	hud.disable("lives")
	hud.disable("crosshair")

	if doom.issrb2 then
		drawWeapon(v, player, 38)
		srb2hud.keys(v, player, player.doom.keys)
		srb2hud.ammo(v, player, myAmmo)
		srb2hud.health(v, player, myHealth)
		srb2hud.armor(v, player, myArmor)
		srb2hud.frags(v, player, player.doom.frags)
		return
	end

	drawWeapon(v, player, 16)
	drawStatusBar(v, player)
-- 	print(player.doom.curwep, player.doom.curwepcat, player.doom.curwepslot)

	DrawFlashes(v, player)
end, "game")

-- basically think of this in "how many mapunits is in one pixel"
local automapzoom = FRACUNIT*5
local automaplocked = true
local mapcenterx = 0
local mapcentery = 0

hud.add(function(v, player)
    v.drawFill(nil, nil, nil, nil, 0)

    -- update map center only if locked
    if automaplocked and displayplayer and displayplayer.mo then
        mapcenterx = displayplayer.mo.x
        mapcentery = displayplayer.mo.y
    end

    local scale = automapzoom or FRACUNIT --FRACUNIT * 12
    scale = max($, 1)

    -- whether to rotate the automap (rotate map under a fixed arrow)
    local cv = CV_FindVar("doom_rotateautomap")
    local rotate = cv and cv.value ~= 0

    -- screen extents in pixels (integers)
    local VIEW_XMIN, VIEW_YMIN = 0, 0
    local VIEW_XMAX, VIEW_YMAX = 320, 168
    local VIEW_CX = (VIEW_XMIN + VIEW_XMAX) / 2
    local VIEW_CY = (VIEW_YMIN + VIEW_YMAX) / 2

    -- fixed_t versions we will use:
    local VCX = VIEW_CX * FRACUNIT  -- used to compute VIEW_CX*scale as FixedMul(VCX,scale)
    local VCY = VIEW_CY * FRACUNIT

    -- clip bounds must be in the same 'px' (scale-space) as the values passed to minimapDrawLine:
    local VXMIN = FixedMul(VIEW_XMIN * FRACUNIT, scale)
    local VYMIN = FixedMul(VIEW_YMIN * FRACUNIT, scale)
    local VXMAX = FixedMul(VIEW_XMAX * FRACUNIT, scale)
    local VYMAX = FixedMul(VIEW_YMAX * FRACUNIT, scale)

    -- precomputed center multiplied by scale (VIEW_CX*scale in fixed_t)
    local CENTER_SCALED_X = FixedMul(VCX, scale)
    local CENTER_SCALED_Y = FixedMul(VCY, scale)

    -- Outcode flags
    local INSIDE, LEFT, RIGHT, BOTTOM, TOP = 0, 1, 2, 4, 8

    local function computeOutCode(x, y)
		-- snap very-near-inside coords back into the box
		if abs(x - VXMIN) < FRACUNIT then x = VXMIN end
		if abs(x - VXMAX) < FRACUNIT then x = VXMAX end
		if abs(y - VYMIN) < FRACUNIT then y = VYMIN end
		if abs(y - VYMAX) < FRACUNIT then y = VYMAX end
        local code = INSIDE
        if x < VXMIN then code = code | LEFT
        elseif x > VXMAX then code = code | RIGHT end
        if y < VYMIN then code = code | TOP
        elseif y > VYMAX then code = code | BOTTOM end
        return code
    end

    -- Clips a line to the viewport (fixed_t coords in px-space). Returns fixed_t coords or nil.
	local function clipLine(x1, y1, x2, y2)
		local outcode1 = computeOutCode(x1, y1)
		local outcode2 = computeOutCode(x2, y2)
		local accept = false
		local iters = 0

		while true do
			iters = $ + 1
			if iters > 16 then
				print("WARNING: clipLine time-out! What are you doing to cause that?!")
				break
			end
			
			if (outcode1 | outcode2) == 0 then
				accept = true
				break
			elseif (outcode1 & outcode2) ~= 0 then
				break
			else
				local x, y
				local outcodeOut = outcode1 ~= 0 and outcode1 or outcode2

				if (outcodeOut & TOP) ~= 0 then
					x = x1 + FixedMul(x2 - x1, FixedDiv(VYMIN - y1, y2 - y1))
					y = VYMIN
				elseif (outcodeOut & BOTTOM) ~= 0 then
					x = x1 + FixedMul(x2 - x1, FixedDiv(VYMAX - y1, y2 - y1))
					y = VYMAX
				elseif (outcodeOut & RIGHT) ~= 0 then
					y = y1 + FixedMul(y2 - y1, FixedDiv(VXMAX - x1, x2 - x1))
					x = VXMAX
				elseif (outcodeOut & LEFT) ~= 0 then
					y = y1 + FixedMul(y2 - y1, FixedDiv(VXMIN - x1, x2 - x1))
					x = VXMIN
				end

				if outcodeOut == outcode1 then
					x1, y1 = x, y
					outcode1 = computeOutCode(x1, y1)
				else
					x2, y2 = x, y
					outcode2 = computeOutCode(x2, y2)
				end
			end
		end

		if accept then
			return x1, y1, x2, y2
		end
		return nil
	end

	local rotang = CV_FindVar("doom_autorotateprefangle").value

    -- precompute player angle cos/sin for map rotation if needed
    local playerAngle = displayplayer.mo.angle + ANGLE_90 + FixedAngle(rotang)
    local mapCos, mapSin = -cos(playerAngle), sin(playerAngle)

	local function worldToScreen(wx, wy)
		local rx = wx - mapcenterx
		local ry = mapcentery - wy

		if rotate then
			local rxr = FixedMul(rx, mapCos) + FixedMul(ry, mapSin)
			local ryr = FixedMul(-rx, mapSin) + FixedMul(ry, mapCos)

			-- scale rxr/ryr into px-space, then add center (which is already center*scale)
			local px = rxr + CENTER_SCALED_X
			local py = ryr + CENTER_SCALED_Y
			return px, py
		else
			-- scale rx/ry into px-space
			local px = rx + CENTER_SCALED_X
			local py = ry + CENTER_SCALED_Y
			return px, py
		end
	end

	local showlines = CV_FindVar("doom_alwaysshowlines").value

    for line in lines.iterate do
        local wx1, wy1 = line.v1.x, line.v1.y
        local wx2, wy2 = line.v2.x, line.v2.y

        local sx1, sy1 = worldToScreen(wx1, wy1)
        local sx2, sy2 = worldToScreen(wx2, wy2)

        local cx1, cy1, cx2, cy2 = clipLine(sx1, sy1, sx2, sy2)
        if cx1 != nil then
            local color = 0

            if not line.backsector then
                color = 176
            else
                local fs, bs = line.frontsector, line.backsector
                if fs.floorheight ~= bs.floorheight then
                    color = 144
                elseif fs.ceilingheight ~= bs.ceilingheight then
                    color = 231
                else
					if showlines then
						color = 3
					else
						continue
					end
                end
            end

            -- now pass px coords and scale; minimapDrawLine divides px/scale to get pixel coords
            minimapDrawLine(v, cx1, cy1, cx2, cy2, color, 0, scale)
        end
		i = $ + 1
    end

    -- Draw player arrow at the center.
    -- We compute arrow offsets in 'pixel' units (FRACUNIT-based), then convert to px-space by scaling by 'scale'.
    local arrowScale = FixedMul(displayplayer.mo.radius, displayplayer.mo.scale)
    local arrowSize = FixedDiv(arrowScale, scale) -- used to scale FRACUNIT-based arrow coords to pixel units

    local arrowCoords = {
        {FRACUNIT * -7 / 8, 0, FRACUNIT * 1, 0},
        {FRACUNIT * 1, 0, FRACUNIT * 1 / 2, FRACUNIT * 1 / 4},
        {FRACUNIT * 1, 0, FRACUNIT * 1 / 2, FRACUNIT * -1 / 4},
        {FRACUNIT * -7 / 8, 0, FRACUNIT * -9 / 8, FRACUNIT * -1 / 4},
        {FRACUNIT * -7 / 8, 0, FRACUNIT * -9 / 8, FRACUNIT * 1 / 4},
        {FRACUNIT * -5 / 8, 0, FRACUNIT * -7 / 8, FRACUNIT * -1 / 4},
        {FRACUNIT * -5 / 8, 0, FRACUNIT * -7 / 8, FRACUNIT * 1 / 4}
    }

    -- If rotating the map, keep arrow pointing up on screen.
    -- The arrow graphic faces east (0); ANG90 will rotate it to point up.
    local angle
	if rotate then
		angle = (ANGLE_270 + FixedAngle(rotang))
	else
		angle = displayplayer.mo.angle + ANGLE_180
	end

    local cosAng = -cos(angle)
    local sinAng = sin(angle)

    for _, coord in ipairs(arrowCoords) do
		local player_px, player_py = worldToScreen(displayplayer.mo.x, displayplayer.mo.y)
        local x1, y1, x2, y2 = coord[1], coord[2], coord[3], coord[4]

        -- scale the FRACUNIT-based arrow coords down to pixel units (still fixed_t)
        x1 = FixedMul(x1, arrowSize)
        y1 = FixedMul(y1, arrowSize)
        x2 = FixedMul(x2, arrowSize)
        y2 = FixedMul(y2, arrowSize)

        -- rotate arrow by 'angle' (either player angle or fixed ANG90)
        local rx1 = FixedMul(x1, cosAng) - FixedMul(y1, sinAng)
        local ry1 = FixedMul(x1, sinAng) + FixedMul(y1, cosAng)
        local rx2 = FixedMul(x2, cosAng) - FixedMul(y2, sinAng)
        local ry2 = FixedMul(x2, sinAng) + FixedMul(y2, cosAng)

        -- Convert rotated FRACUNIT-based pixel offsets into px-space (px = (VIEW_CX + pixel_offset) * scale)
		local px1 = player_px + FixedMul(rx1, scale)
		local py1 = player_py + FixedMul(ry1, scale)
		local px2 = player_px + FixedMul(rx2, scale)
		local py2 = player_py + FixedMul(ry2, scale)

        local cx1, cy1, cx2, cy2 = clipLine(px1, py1, px2, py2)
        if cx1 != nil then
            minimapDrawLine(v, cx1, cy1, cx2, cy2, 4, 0, scale)
        end
    end

    drawStatusBar(v, displayplayer)
end, "scores")

local zooming = 0
local movingx = 0
local movingy = 0

-- track state directly
local keyState = {
	left  = false,
	right = false,
	up    = false,
	down  = false,
	zoomIn  = false,
	zoomOut = false,
}

local function AutomapThinkerDown(keyevent)
	local name = keyevent.name:lower()
	if name == "left arrow"  then keyState.left  = true; return true end
	if name == "right arrow" then keyState.right = true; return true end
	if name == "up arrow"    then keyState.up    = true; return true end
	if name == "down arrow"  then keyState.down  = true; return true end
	if name == "="           then keyState.zoomIn  = true end
	if name == "-"           then keyState.zoomOut = true end
	if name == "f" and input.gameControlDown(GC_SCORES) then
		automaplocked = not automaplocked
		DOOM_DoMessage(consoleplayer, automaplocked and "AMSTR_FOLLOWON" or "AMSTR_FOLLOWOFF")
	end
end

local function AutomapThinkerUp(keyevent)
	local name = keyevent.name:lower()
	if name == "left arrow"  then keyState.left  = false end
	if name == "right arrow" then keyState.right = false end
	if name == "up arrow"    then keyState.up    = false end
	if name == "down arrow"  then keyState.down  = false end
	if name == "="           then keyState.zoomIn  = false end
	if name == "-"           then keyState.zoomOut = false end
end

addHook("KeyDown", AutomapThinkerDown)
addHook("KeyUp",   AutomapThinkerUp)

addHook("ThinkFrame", function()
	if not input.gameControlDown(GC_SCORES) then return end

	movingx = (keyState.left and 1 or 0) - (keyState.right and 1 or 0)
	movingy = (keyState.up   and 1 or 0) - (keyState.down  and 1 or 0)
	zooming = (keyState.zoomIn and 1 or 0) - (keyState.zoomOut and 1 or 0)

	automapzoom = $ + ((FRACUNIT/16) * zooming)
	automapzoom = max($, (FRACUNIT*5)/16)
	automapzoom = min($, (FRACUNIT*918)/8)

	if automaplocked then return end
	mapcenterx = $ + (FixedMul(FRACUNIT*3, automapzoom) * -movingx)
	mapcentery = $ + (FixedMul(FRACUNIT*3, automapzoom) * movingy)
end)

hud.add(function(v, player)
	if doom.patchesLoaded then return end
	for i = 0, INT32_MAX do
		if R_CheckTextureNameForNum(i) == "-" then break end -- Probably at the end of list
		doom.texturesByNum[i] = v.cachePatch(R_TextureNameForNum(i))
	end
	doom.patchesLoaded = true
end, "game")

/*

	local cnt = player.doom.damagecount
	local redpal = (cnt+7)>>3
	local bonuspal = (player.doom.bonuscount+7)>>3
	local radpal = ( player.doom.powers[pw_ironfeet] > 4*32 or player.doom.powers[pw_ironfeet]&8) and 6 or 0
	if redpal >= 0 then
		v.drawFill(0, 0, 320, 200, 176|(redpal<<V_ALPHASHIFT))
	elseif bonuspal >= 0 then
		v.drawFill(0, 0, 320, 200, 161|(bonuspal<<V_ALPHASHIFT))
	elseif radpal then
		v.drawFill(0, 0, 320, 200, 114|(radpal<<V_ALPHASHIFT))
	end
*/