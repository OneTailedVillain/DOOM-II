local stats = {kills = 100, items = 100, secrets = 100}

local phaseByKey = {
	kills = 2,
	items = 4,
	secrets = 6,
}

local requiresPhases = {
	kills = true,
	items = true,
	secrets = true
}

local SCALEFACTOR = FRACUNIT*5/6

-- background width is no longer scaled
local entrywidth = 320 - (12*2)
local extrablockwidth = 12

-- height still scales
local maxheight = FixedMul(12*FRACUNIT, SCALEFACTOR)/FRACUNIT

local function scaled(n)
	return FixedMul(n*FRACUNIT, SCALEFACTOR)/FRACUNIT
end

local function scaledf(n)
	return FixedMul(n*FRACUNIT, SCALEFACTOR)
end

local function MPR(v, player)
	local tab = {}

	for player in players.iterate() do
		if not player.mo then continue end

		local datab = {}
		local cnt_kills = player.cnt_kills or {}

		datab.pd = player.doom
		datab.skin = player.mo.skin
		datab.name = player.name
		datab.kills = cnt_kills[1]
		datab.items = cnt_kills[2]
		datab.secrets = cnt_kills[3]
		datab.frags = doom.getFrags(player)

		table.insert(tab, datab)
	end

	local columns

	if G_RingSlingerGametype() then
		columns = {
			{key = "frags", label = "FRAG", percent = false},
			{key = "deaths", label = "DETH", percent = false},
			{key = "ping", label = "PING", percent = false},
		}
	else
		columns = {
			{key = "kills", label = "KILL", percent = true},
			{key = "items", label = "ITEM", percent = true},
			{key = "secrets", label = "SCRT", percent = true},
		}
	end

	local tablen = #tab

	-- background stays unscaled and centered in screen pixels
	local entryx = (320 - (entrywidth + extrablockwidth)) / 2

	local maxnamewidth = FixedMul(
		v.cachePatch("STCFN088").width * 21 * FRACUNIT,
		SCALEFACTOR
	)/FRACUNIT

	local d100percwidth = v.cachePatch("STCFN049").width
	d100percwidth = $ + (v.cachePatch("STCFN048").width * 2)
	d100percwidth = $ + v.cachePatch("STCFN037").width

	-- text width still scales
	d100percwidth = FixedMul(d100percwidth*FRACUNIT, SCALEFACTOR)/FRACUNIT

	-- spacing still scales
	local padding = scaled(6)

	local y

	local function drawShit(x, text, alignment, translation)
		if not x then x = 0 end

		doom.drawInFont(
			v,
			x * FRACUNIT, -- x stays unscaled
			(y + scaled(3)) * FRACUNIT,
			SCALEFACTOR,
			"STCFN",
			text,
			V_ALLOWLOWERCASE,
			alignment,
			v.getColormap(nil, nil, translation or nil)
		)
	end

	local colWidth = d100percwidth + padding
	local colPositions = {}

	local rightEdge = entryx + entrywidth + extrablockwidth - padding

	-- build from right to left
	for i = #columns, 1, -1 do
		colPositions[i] = rightEdge
		rightEdge = $ - colWidth
	end

	-- Header row
	local basey = 100 - ((maxheight * (tablen + 1)) / 2)

	y = basey

	v.drawFill(
		entryx,
		y,
		entrywidth + extrablockwidth,
		maxheight,
		0|V_50TRANS
	)

	drawShit(entryx + padding, "NAME")

	for i, col in ipairs(columns) do
		drawShit(colPositions[i], col.label, "right")
	end

	-- Player rows
	for i, data in ipairs(tab) do
		y = basey + (i * maxheight)

		v.drawFill(
			entryx,
			y,
			entrywidth + extrablockwidth,
			maxheight,
			(i % 2) + 1|V_50TRANS
		)

		local skinPatch = v.getSprite2Patch(data.skin, SPR2_LIFE, false, A, 0)

		if skinPatch then
			v.drawScaled(
				scaledf(entryx - 6),
				scaledf(y + maxheight - 3),
				SCALEFACTOR,
				skinPatch
			)
		end

		drawShit(entryx + padding, data.name, nil, data.name == displayplayer.name and "HIGHLIGHT")

		for i, col in ipairs(columns) do
			local value = data[col.key] or 0
			local max = stats[col.key] or 1

			local text

			if requiresPhases[col.key] and phaseByKey[col.key] > data.pd.intstate then
				text = "-%"
			elseif col.percent then
				text = (value * 100 / max) .. "%"
			else
				text = tostring(value)
			end

			drawShit(colPositions[i], text, "right", data.name == displayplayer.name and "HIGHLIGHT")
		end
	end
end

return MPR