---@type videolib
local v

local hudflags = V_SNAPTOLEFT|V_SNAPTOBOTTOM

local charToFrame = {
	["-"] = 10,
}

local function drawNumberInPalette(x, y, number, palette, flags, colormap, align)
	align = $ or "left"

	local str = tostring(number)
	local width = #str * 8

	if align == "center" then
		x = $ - width/2
	elseif align == "right" then
		x = $ - width
	end

	for i = 1, #str do
		local digit = tonumber(str:sub(i, i))
		if digit == nil then
			digit = charToFrame[str:sub(i, i)]
		end

		if digit != nil then
			v.drawCropped(
				(x + (i-1)*8) * FRACUNIT,
				y * FRACUNIT,
				FRACUNIT,
				FRACUNIT,
				v.cachePatch("BILL-NUMBERS"),
				flags,
				colormap,
				digit * (8*FRACUNIT),
				palette * (8*FRACUNIT),
				8*FRACUNIT,
				8*FRACUNIT
			)
		end
	end
end

---@param drawer videolib
---@param player player_t
hud.add(function(drawer, player)
	v = drawer
	if not player.mo then return end
	if player.mo.skin != "dpecbillrizer" then return end

	local lives = 5  --player.doom.bill_lives or 0
	for i = 1, lives do
		v.draw(10 + ((i - 1) * 8), 154, v.cachePatch("BILL-LIFE"), hudflags)
	end

	drawNumberInPalette(74, 178,
	player.mo.doom.health,
	3, hudflags, nil, "left")

	local maybeflash = ""
	if player.doom.bill_hurtflash then
		maybeflash = "F"
	end

	local lives = 8
	for i = 1, lives do
		local subtract = (i - 1) * 4
		local offset = (i - 1) * 8
		local HPNum = player.mo.doom.health - subtract
		if HPNum < 0 then HPNum = 0 end
		if HPNum > 4 then HPNum = 4 end
		local initPatch = "BILL-HEALTH" .. HPNum .. maybeflash
		if not v.patchExists(initPatch) then
			initPatch = "BILL-HEALTH" .. HPNum
		end
		v.draw(74 + offset, 162, v.cachePatch(initPatch), hudflags)
	end

	local inbetween = ""
	v.draw(12, 122, v.cachePatch("BILL-WEAPON" .. inbetween .. "BASE"), hudflags)
	inbetween = 1
	v.draw(34, 131, v.cachePatch("BILL-RAPIDFIRE" .. inbetween), hudflags)
	--v.draw(0, 0, v.cachePatch("BILL-HUDREFERENCE"), hudflags|V_SUBTRACT)
end)