-- basically think of this in "how many mapunits is in one pixel"
--local automapzoom = FRACUNIT*5
local automapzoom = FRACUNIT
local automaplocked = true
local mapcenterx = 0
local mapcentery = 0

local function doAutomap(v, player, noHUD)
    v.drawFill(nil, nil, nil, nil, 0)

	local hudScaleInt, hudScaleFixed = v.dupx()

	local screenWidth = v.width()
	local screenHeight = v.height()
	local statusBarScreenHeight = v.cachePatch("STBAR").height
	local flags = V_SNAPTOLEFT|V_SNAPTOTOP
	local scale = automapzoom or FRACUNIT

	local dohires = CV_FindVar("doom_hiresautomap")

	if dohires.value then
		statusBarScreenHeight = FixedMul($, hudScaleFixed)
		flags = V_NOSCALEPATCH|V_NOSCALESTART
		scale = FixedDiv($, hudScaleFixed)
	else
		screenWidth = $ / hudScaleInt
		screenHeight = $ / hudScaleInt
	end

    scale = max($, 1)

    -- update map center only if locked
    if automaplocked and displayplayer and displayplayer.mo then
        mapcenterx = displayplayer.mo.x
        mapcentery = displayplayer.mo.y
    end

    -- whether to rotate the automap (rotate map under a fixed arrow)
    local cv = CV_FindVar("doom_rotateautomap")
    local rotate = cv and cv.value ~= 0

    -- screen extents in pixels (integers)
    local VIEW_XMIN, VIEW_YMIN = 0, 0
    local VIEW_XMAX, VIEW_YMAX = screenWidth, screenHeight
	if not noHUD then
		VIEW_YMAX = $ - statusBarScreenHeight
	end
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

            if not line.backsector or (line.flags & DML_SECRET) then
                color = 176
            else
                local fs, bs = line.frontsector, line.backsector
                if fs.floorheight ~= bs.floorheight then
                    color = 165
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
            minimapDrawLine(v, cx1, cy1, cx2, cy2, color, flags, scale)
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
            minimapDrawLine(v, cx1, cy1, cx2, cy2, 4, flags, scale)
        end
    end

	local gamemap = gamemap
	if doom.isdoom1 then
		gamemap = DOOM_Doom2MapIDToDoom1MapID($)
	end

    doom.drawStatusBar(v, displayplayer)
	-- doom.mapString
	drawInFont(v,
	0, 160*FRACUNIT,
	FRACUNIT,
	"STCFN",
	DOOM_ResolveString("$" .. doom.mapString .. gamemap),
	V_SNAPTOBOTTOM|V_SNAPTOLEFT)
end

local zooming = 0
local movingx = 0
local movingy = 0

-- track state directly
local keyState = {
	automap = false,
	left  = false,
	right = false,
	up    = false,
	down  = false,
	zoomIn  = false,
	zoomOut = false,
}

local function AutomapThinkerDown(keyevent)
	local name = keyevent.name:lower()
	if name == "tab"         then keyState.automap = true end
	if name == "left arrow"  then keyState.left  = true; return keyState.automap end
	if name == "right arrow" then keyState.right = true; return keyState.automap end
	if name == "up arrow"    then keyState.up    = true; return keyState.automap end
	if name == "down arrow"  then keyState.down  = true; return keyState.automap end
	if name == "="           then keyState.zoomIn  = true; return keyState.automap end
	if name == "-"           then keyState.zoomOut = true; return keyState.automap end
	if name == "f" and input.gameControlDown(GC_SCORES) then
		automaplocked = not automaplocked
		DOOM_DoMessage(consoleplayer, automaplocked and "AMSTR_FOLLOWON" or "AMSTR_FOLLOWOFF")
	end
end

local function AutomapThinkerUp(keyevent)
	local name = keyevent.name:lower()
	if name == "tab"         then keyState.automap = false end
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

	automapzoom = $ + ((FRACUNIT/8) * zooming)
	automapzoom = max($, (FRACUNIT*5)/16)
	automapzoom = min($, (FRACUNIT*918)/8)

	if automaplocked then return end
	mapcenterx = $ + (FixedMul(FRACUNIT*3, automapzoom) * -movingx)
	mapcentery = $ + (FixedMul(FRACUNIT*3, automapzoom) * movingy)
end)

rawset(_G, "DOOM_InAutomap", function()
	return keyState.automap
end)

return doAutomap, keyState