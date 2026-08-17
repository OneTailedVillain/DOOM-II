local automaplocked = true
local mapcenterx = 0
local mapcentery = 0

local PLAYERRADIUS = 16*FRACUNIT

local automapzoom = nil
local automapminzoom = FRACUNIT
local automapmaxzoom = FRACUNIT

local mapminx, mapminy, mapmaxx, mapmaxy

local cvRotate      = CV_FindVar("doom_rotateautomap")
local cvRotateAngle = CV_FindVar("doom_autorotateprefangle")
local cvShowLines   = CV_FindVar("doom_alwaysshowlines")
local cvHiRes       = CV_FindVar("doom_hiresautomap")

local lineData = {}

local function recalcAutomapZoom(screenWidth, screenHeight)
	local mapwidth  = max(1, abs(mapmaxx - mapminx))
	local mapheight = max(1, abs(mapmaxy - mapminy))

	local f_w = screenWidth * FRACUNIT
	local f_h = screenHeight * FRACUNIT

	local a = FixedDiv(f_w, mapwidth)
	local b = FixedDiv(f_h, mapheight)

	automapminzoom = min(a, b)
	if automapminzoom < FRACUNIT then
		automapminzoom = FRACUNIT
	end
	automapmaxzoom = FixedDiv(f_h, 2*PLAYERRADIUS)

	if automapzoom == nil then
		automapzoom = FixedDiv(automapminzoom, (7*FRACUNIT)/10)
		if automapzoom > automapmaxzoom then
			automapzoom = automapminzoom
		end
	end
end

local screenWidth = 320
local screenHeight = 200

local function doAutomap(v, player, noHUD)
	v.drawFill(nil, nil, nil, nil, 0)

	local hudScaleInt, hudScaleFixed = v.dupx()

	screenWidth = v.width()
	screenHeight = v.height()
	local statusBarScreenHeight = v.cachePatch("STBAR").height
	local flags = V_SNAPTOLEFT|V_SNAPTOTOP

	local rotate   = cvRotate.value ~= 0
	local dohires  = cvHiRes.value ~= 0
	local showlines = cvShowLines.value ~= 0
	local rotang   = cvRotateAngle.value

	if not dohires then
		screenWidth = $ / hudScaleInt
		screenHeight = $ / hudScaleInt
	end

	local VIEW_XMIN, VIEW_YMIN = 0, 0
	local VIEW_XMAX, VIEW_YMAX = screenWidth, screenHeight
	if not noHUD then
		VIEW_YMAX = $ - statusBarScreenHeight
		screenHeight = $ - statusBarScreenHeight
	end

	recalcAutomapZoom(screenWidth, screenHeight)

	local scale = (automapzoom or 2) / 2

	if dohires then
		flags = V_NOSCALEPATCH|V_NOSCALESTART
		scale = FixedDiv($, hudScaleFixed)
	end

    scale = max($, 1)

	if automaplocked and displayplayer and displayplayer.mo then
		mapcenterx = displayplayer.mo.x
		mapcentery = displayplayer.mo.y
	end

	local VIEW_CX = (VIEW_XMIN + VIEW_XMAX) * FRACUNIT / 2
	local VIEW_CY = (VIEW_YMIN + VIEW_YMAX) * FRACUNIT / 2

	local VXMIN = VIEW_XMIN * FRACUNIT
	local VYMIN = VIEW_YMIN * FRACUNIT
	local VXMAX = VIEW_XMAX * FRACUNIT
	local VYMAX = VIEW_YMAX * FRACUNIT

    -- Outcode flags
    local INSIDE, LEFT, RIGHT, BOTTOM, TOP = 0, 1, 2, 4, 8

    -- Clips a line to the viewport (fixed_t coords in px-space). Returns fixed_t coords or nil.
	local function clipLine(x1, y1, x2, y2)
		local dx = x2 - x1
		local dy = y2 - y1

		local t0 = 0
		local t1 = FRACUNIT

		local function clipTest(p, q)
			if p == 0 then
				-- Line is parallel to this boundary; reject only if it's outside.
				return q >= 0
			end

			local r = FixedDiv(q, p)

			if p < 0 then
				if r > t1 then
					return false
				end
				if r > t0 then
					t0 = r
				end
			else
				if r < t0 then
					return false
				end
				if r < t1 then
					t1 = r
				end
			end

			return true
		end

		-- Left / right / top / bottom
		if not clipTest(-dx, x1 - VXMIN) then return nil end
		if not clipTest( dx, VXMAX - x1) then return nil end
		if not clipTest(-dy, y1 - VYMIN) then return nil end
		if not clipTest( dy, VYMAX - y1) then return nil end

		if t1 < t0 then
			return nil
		end

		local cx1 = x1 + FixedMul(dx, t0)
		local cy1 = y1 + FixedMul(dy, t0)
		local cx2 = x1 + FixedMul(dx, t1)
		local cy2 = y1 + FixedMul(dy, t1)

		return cx1, cy1, cx2, cy2
	end

    -- precompute player angle cos/sin for map rotation if needed
    local playerAngle = displayplayer.mo.angle + ANGLE_90 + FixedAngle(rotang)
    local mapCos, mapSin = -cos(playerAngle), sin(playerAngle)

	local function worldToScreen(wx, wy, scale, viewCX, viewCY, rotate, mapCos, mapSin)
		local rx = wx - mapcenterx
		local ry = mapcentery - wy

		if rotate then
			local rxr = FixedMul(rx, mapCos) + FixedMul(ry, mapSin)
			local ryr = FixedMul(-rx, mapSin) + FixedMul(ry, mapCos)
			return FixedDiv(rxr, scale) + viewCX, FixedDiv(ryr, scale) + viewCY
		end

		return FixedDiv(rx, scale) + viewCX, FixedDiv(ry, scale) + viewCY
	end

	-- Compute viewport world bounds
	local corners = {
		{0, 0},
		{screenWidth*FRACUNIT, 0},
		{0, screenHeight*FRACUNIT},
		{screenWidth*FRACUNIT, screenHeight*FRACUNIT}
	}
	local vwMinX, vwMaxX = INT32_MAX, INT32_MIN
	local vwMinY, vwMaxY = INT32_MAX, INT32_MIN

	for _, corner in ipairs(corners) do
		local sx, sy = corner[1], corner[2]
		local dx = FixedMul((sx - VIEW_CX), scale)
		local dy = FixedMul((sy - VIEW_CY), scale)
		local wx, wy
		if rotate then
			wx = mapcenterx + FixedMul(dx, mapCos) - FixedMul(dy, mapSin)
			wy = mapcentery - (FixedMul(dx, mapSin) + FixedMul(dy, mapCos))
		else
			wx = mapcenterx + dx
			wy = mapcentery - dy
		end
		if wx < vwMinX then vwMinX = wx end
		if wx > vwMaxX then vwMaxX = wx end
		if wy < vwMinY then vwMinY = wy end
		if wy > vwMaxY then vwMaxY = wy end
	end

	-- Expand slightly to avoid clipping edges
	local EPSILON = 2*FRACUNIT
	vwMinX = vwMinX - EPSILON
	vwMaxX = vwMaxX + EPSILON
	vwMinY = vwMinY - EPSILON
	vwMaxY = vwMaxY + EPSILON

	for _, ld in ipairs(lineData) do
		if ld.maxx < vwMinX or ld.minx > vwMaxX or ld.maxy < vwMinY or ld.miny > vwMaxY then
			continue   -- entirely outside
		end

		-- Now transform the line
		local wx1, wy1 = ld.x1, ld.y1
		local wx2, wy2 = ld.x2, ld.y2

		local line = ld.line

		if not line.v1 or not line.v2 then
			continue
		end

		local sx1, sy1 = worldToScreen(wx1, wy1, scale, VIEW_CX, VIEW_CY, rotate, mapCos, mapSin)
		local sx2, sy2 = worldToScreen(wx2, wy2, scale, VIEW_CX, VIEW_CY, rotate, mapCos, mapSin)

		local cx1, cy1, cx2, cy2 = clipLine(sx1, sy1, sx2, sy2)
		if cx1 ~= nil then
			local color = 0

			if not line.backsector then
				color = 35
			else
				local fs, bs = line.frontsector, line.backsector
				if fs.floorheight ~= bs.floorheight then
					color = 228
				elseif fs.ceilingheight ~= bs.ceilingheight then
					color = 73
				else
					if showlines then
						color = 3
					else
						continue
					end
				end
			end

			minimapDrawLine(v, cx1, cy1, cx2, cy2, color, flags)
		end
	end

	local arrowCoords = {
		{FRACUNIT * -7 / 8, 0, FRACUNIT * 1, 0},
		{FRACUNIT * 1, 0, FRACUNIT * 1 / 2, FRACUNIT * 1 / 4},
		{FRACUNIT * 1, 0, FRACUNIT * 1 / 2, FRACUNIT * -1 / 4},
		{FRACUNIT * -7 / 8, 0, FRACUNIT * -9 / 8, FRACUNIT * -1 / 4},
		{FRACUNIT * -7 / 8, 0, FRACUNIT * -9 / 8, FRACUNIT * 1 / 4},
		{FRACUNIT * -5 / 8, 0, FRACUNIT * -7 / 8, FRACUNIT * -1 / 4},
		{FRACUNIT * -5 / 8, 0, FRACUNIT * -7 / 8, FRACUNIT * 1 / 4}
	}

	for p in players.iterate() do
		local p_mo = p.mo
		if p_mo then
			local arrowWorldScale = FixedMul(p_mo.radius, p_mo.scale)
			arrowWorldScale = FixedMul(arrowWorldScale, FixedDiv(8*FRACUNIT, 7*FRACUNIT))

			local angle
			if rotate then
				angle = ANGLE_270 + FixedAngle(rotang)
			else
				angle = p_mo.angle
			end

			local cosAng = cos(angle)
			local sinAng = sin(angle)

			local arrowColor = 4
			if multiplayer then
				arrowColor = skincolors[p_mo.color].ramp[7]
			end

			for _, coord in ipairs(arrowCoords) do
				local x1, y1, x2, y2 = coord[1], coord[2], coord[3], coord[4]
				x1, y1 = FixedMul(x1, arrowWorldScale), FixedMul(y1, arrowWorldScale)
				x2, y2 = FixedMul(x2, arrowWorldScale), FixedMul(y2, arrowWorldScale)

				local rx1 = FixedMul(x1, cosAng) - FixedMul(y1, sinAng)
				local ry1 = FixedMul(x1, sinAng) + FixedMul(y1, cosAng)
				local rx2 = FixedMul(x2, cosAng) - FixedMul(y2, sinAng)
				local ry2 = FixedMul(x2, sinAng) + FixedMul(y2, cosAng)

				local px1, py1 = worldToScreen(p_mo.x + rx1, p_mo.y + ry1, scale, VIEW_CX, VIEW_CY, rotate, mapCos, mapSin)
				local px2, py2 = worldToScreen(p_mo.x + rx2, p_mo.y + ry2, scale, VIEW_CX, VIEW_CY, rotate, mapCos, mapSin)

				local ax1, ay1, ax2, ay2 = clipLine(px1, py1, px2, py2)
				if ax1 ~= nil then
					minimapDrawLine(v, ax1, ay1, ax2, ay2, arrowColor, flags)
				end
			end
		end
	end
end

if not doom.automapHooksRegistered then

addHook("MapLoad", function()
	mapminx, mapminy = INT32_MAX, INT32_MAX
	mapmaxx, mapmaxy = INT32_MIN, INT32_MIN

	for vertex in vertexes.iterate do
		if vertex.x < mapminx then mapminx = vertex.x
		elseif vertex.x > mapmaxx then mapmaxx = vertex.x end
		if vertex.y < mapminy then mapminy = vertex.y
		elseif vertex.y > mapmaxy then mapmaxy = vertex.y end
	end

    lineData = {}
    for line in lines.iterate do
        if line.v1 and line.v2 then
            local x1, y1 = line.v1.x, line.v1.y
            local x2, y2 = line.v2.x, line.v2.y
            local minx = min(x1, x2)
            local maxx = max(x1, x2)
            local miny = min(y1, y2)
            local maxy = max(y1, y2)
            table.insert(lineData, {
                minx = minx, maxx = maxx,
                miny = miny, maxy = maxy,
                x1 = x1, y1 = y1,
                x2 = x2, y2 = y2,
                line = line   -- keep reference for sector access
            })
        end
    end

	automapzoom = nil
end)

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
	if name == "f" and keyState.automap then
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
	consoleplayer.doom.ks = keyState
	if not keyState.automap then return end

	movingx = (keyState.left and 1 or 0) - (keyState.right and 1 or 0)
	movingy = (keyState.up   and 1 or 0) - (keyState.down  and 1 or 0)
	zooming = (keyState.zoomIn and 1 or 0) - (keyState.zoomOut and 1 or 0)

	recalcAutomapZoom(screenWidth, screenHeight)
	if zooming != 0 then
		automapzoom = ($ or 0) + ((FRACUNIT/8) * zooming)
		automapzoom = max($, automapminzoom)
		automapzoom = min($, automapmaxzoom)
	end

	if automaplocked then return end
	mapcenterx = $ + (FixedMul(FRACUNIT*3, automapzoom) * -movingx)
	mapcentery = $ + (FixedMul(FRACUNIT*3, automapzoom) * movingy)
end)

rawset(_G, "DOOM_InAutomap", function()
	return keyState.automap
end)

doom.automapHooksRegistered = keyState

hud.add(function(v, player)
	doAutomap(v, player, true)
end, "scores")
end

return doAutomap, doom.automapHooksRegistered