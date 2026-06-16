---@type videolib
local v

local hudflags = V_SNAPTOLEFT|V_SNAPTOBOTTOM

local charToFrame = {
	["-"] = 10,
}

local warnedfor = {}

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

-- SRB2 automatically truncates with no chance of proper ceiling,
-- so we have to do it ourselves
local function FakeCeilingDiv(a, b)
	return (a + b - 1) / b
end

---@param drawer videolib
---@param player player_t
hud.add(function(drawer, player)
	if v == nil then
		v = drawer
	end
	if DOOM_InAutomap() then return end
	if not player.mo then return end
	if player.mo.skin != "dpecbillrizer" then return end

	local lives = player.doom.bill_lives or 0
	local iters = lives - 1
	if iters <= 6 then
		for i = 1, iters do
			v.draw(10 + ((i - 1) * 8), 154, v.cachePatch("BILL-LIFE"), hudflags)
		end
	else
		v.draw(10 + ((3 - 1) * 8), 154, v.cachePatch("BILL-LIFESTACKED"), hudflags)
		drawNumberInPalette(10 + ((5 - 1) * 8), 154 + 24,
		iters,
		3, hudflags, nil, "left")
	end

	-- each "unit" of health is 3 actual health
	local health = FakeCeilingDiv(player.mo.doom.health, 3)
	local maxhealth = FakeCeilingDiv(player.mo.doom.maxhealth, 3)

	drawNumberInPalette(74, 178,
	health,
	3, hudflags, nil, "left")

	local maybeflash = ""
	if player.doom.bill_hurtflash then
		maybeflash = "F"
	end

	local sections = FakeCeilingDiv(maxhealth, 4)
	if sections < FakeCeilingDiv(health, 4) then sections = FakeCeilingDiv(health, 4) end
	for i = 1, sections do
		local subtract = (i - 1) * 4
		local offset = (i - 1) * 8
		local HPNum = health - subtract
		if HPNum < 0 then HPNum = 0 end
		if HPNum > 4 then HPNum = 4 end
		local initPatch = "BILL-HEALTH" .. HPNum .. maybeflash
		if not v.patchExists(initPatch) then
			initPatch = "BILL-HEALTH" .. HPNum
		end
		v.draw(74 + offset, 162, v.cachePatch(initPatch), hudflags)
	end

	local def = DOOM_GetWeaponDef(player)
	local inbetween = def.bill_icon or ""
	local patch = "BILL-WEAPON" .. inbetween .. "BASE"
	if not v.patchExists(patch) then
		if not warnedfor[patch] then
			warnedfor[patch] = true
			print("WARNING: No patch named '" .. tostring(patch) .. "'")
		end
	else
		v.draw(10, 122, v.cachePatch(patch), hudflags)
	end
	inbetween = 1
	v.draw(32, 131, v.cachePatch("BILL-RAPIDFIRE" .. inbetween), hudflags)
	--v.draw(0, 0, v.cachePatch("BILL-HUDREFERENCE"), hudflags|V_SUBTRACT)
end)