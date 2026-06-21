--#ifdef UNFINISHEDCLASSES
local function drawNumber(v, x, y, num, len, flags)
	local str = string.format("%0" .. len .. "d", num)
	for i = 1, #str do
		local byte = string.byte(str, i, i)
		local num = byte - 48
		if num > 9 or num < 0 then
			error("drawNumber: Input is not a valid number")
		end
		local offset = (i - 1) * 8
		v.draw(1 + x + offset, y, v.cachePatch("ZSNESHUDNUM" .. num), flags)
	end
end

local function drawMagicMeter(v, x, y, fill, flags, colormap)
	for i = 2, fill + 1 do
		local patch = "ZSNESHUDMM"
		if i == fill + 1 then
			patch = $ .. "TOP"
		end
		v.draw(x, y - i, v.cachePatch(patch), flags, colormap or v.getColormap(nil, doom.FindSkinColorIndex("GREEN")))
	end
end

local function drawHearts(v, x, y, curHealth, maxHealth, hearts, perRow, flags)
	if curHealth < 0 then curHealth = 0 end
	local hW = maxHealth / hearts
	local hhW = hW / 2
	local width = min(hearts, perRow) * 8
	for i = 1, hearts do
		local hN = i - 1
		local row = hN / perRow
		local hV = curHealth - (hN * hW)
		if hV > hW then hV = hW end
		local curPatch = "ZSNESHUDEMPTHEART"
		if hV > hhW then
			curPatch = "ZSNESHUDFULLHEART"
		elseif hV > 0 then
			curPatch = "ZSNESHUDHALFHEART"
		end
		local o = (hN * 8) - (row * width)
		v.draw(1 + x + o, y + (row * 8), v.cachePatch(curPatch), flags)
	end
end

hud.add(function(v, player)
	if not player.mo then return end
	if player.mo.skin != "dpecalttp" then return end
	if doom.dontDrawHUDCondits() then return end
	local leftpiece = v.cachePatch("ZSNESHUDCURITEM")
	local centpiece = v.cachePatch("ZSNESHUDCENTERALIGN")
	local rightpiece = v.cachePatch("ZSNESHUDRIGHTALIGN")

	local rupeeAmmo = player.doom.ammo and player.doom.ammo["rupees"] or 0
	local arrowAmmo = player.doom.ammo and player.doom.ammo["arrows"] or 0
	local bombAmmo = player.doom.ammo and player.doom.ammo["bombs"] or 0
	local magicAmmo = player.doom.ammo and player.doom.ammo["magic"] or 0

	local mult = 1
	if player.doom.backpack then
		mult = $ << 1
	end

	if player.doom.zsnes_pieceofpower then
		mult = $ << 1
	end

	v.draw(-16, 0, leftpiece, V_SNAPTOTOP|V_SNAPTOLEFT)
	v.draw(64 - 8, 15, v.cachePatch("ZSNESHUDRUPEEICON"), V_SNAPTOTOP|V_SNAPTOLEFT)
	v.draw(8, 3 * 8, v.cachePatch("ZSNESHUDMAGICMETER" .. mult), V_SNAPTOTOP|V_SNAPTOLEFT)
	drawNumber(v, 64 - 16, 24, rupeeAmmo, 3, V_SNAPTOTOP|V_SNAPTOLEFT)
	drawMagicMeter(v, 3 * 8 - 16, 7 * 8, (magicAmmo * 32) / (mult * 100), V_SNAPTOTOP|V_SNAPTOLEFT)
	v.draw(-16, 0, centpiece, V_SNAPTOTOP|V_SNAPTOLEFT)
	drawNumber(v, 128 - 48, 24, bombAmmo, 2, V_SNAPTOTOP|V_SNAPTOLEFT)
	drawNumber(v, 128 + 24 - 48, 24, arrowAmmo, 2, V_SNAPTOTOP|V_SNAPTOLEFT)
	v.draw(64 - 8, 0, rightpiece, V_SNAPTOTOP|V_SNAPTORIGHT)
	drawHearts(v, 64 + 128 + 32 - 8, 24, player.mo.doom.health, player.mo.doom.maxhealth, player.mo.doom.maxhealth / 10, 10, V_SNAPTOTOP|V_SNAPTORIGHT)
	v.draw(64 + 128 + 16 + (12 * 8), 3 * 8, v.cachePatch("ZSNESHUDMAGICMETER1"), V_SNAPTOTOP|V_SNAPTORIGHT)

	local skincolor = doom.FindSkinColorIndex("GREEN")
	if player.mo.doom.armorefficiency >= FRACUNIT*3/4 then
		skincolor = doom.FindSkinColorIndex("BTRED")
	elseif player.mo.doom.armorefficiency >= FRACUNIT/2 then
		skincolor = doom.FindSkinColorIndex("BOOMBLUE")
	end

	drawMagicMeter(v, 64 + 128 + 16 + (12 * 8), 7 * 8, (min(player.mo.doom.armor, 100) * 32) / 100, V_SNAPTOTOP|V_SNAPTORIGHT, v.getColormap(nil, skincolor))

	-- This is sm BULLLSHIIIIT!! but we can do it later
	-- (unintentionally dooming those socks to stiffen by the time they dry)
	if doom.zsnes_keycardexistent then
		local wishval = doom.KEY_BLUE
		local patchname = "ZSNESHUDBKEY"
		if (player.doom.keys & (wishval)) != wishval then
			patchname = "ZSNESHUDNKEY"
		end
		v.draw(32 + 96 + 40 + 16, 15, v.cachePatch(patchname), V_SNAPTOTOP)
		local wishval = doom.KEY_YELLOW
		local patchname = "ZSNESHUDYKEY"
		if (player.doom.keys & (wishval)) != wishval then
			patchname = "ZSNESHUDNKEY"
		end
		v.draw(32 + 96 + 40 + 16 + 8, 15, v.cachePatch(patchname), V_SNAPTOTOP)
		local wishval = doom.KEY_RED
		local patchname = "ZSNESHUDRKEY"
		if (player.doom.keys & (wishval)) != wishval then
			patchname = "ZSNESHUDNKEY"
		end
		v.draw(32 + 96 + 40 + 16 + 16, 15, v.cachePatch(patchname), V_SNAPTOTOP)
	end

	if doom.zsnes_skullkeyexistent then
		local wishval = doom.KEY_SKULLBLUE
		local patchname = "ZSNESHUDBSKEY"
		if (player.doom.keys & (wishval)) != wishval then
			patchname = "ZSNESHUDNSKEY"
		end
		v.draw(32 + 96 + 40 + 16, 15 + 8, v.cachePatch(patchname), V_SNAPTOTOP)
		local wishval = doom.KEY_SKULLYELLOW
		local patchname = "ZSNESHUDYSKEY"
		if (player.doom.keys & (wishval)) != wishval then
			patchname = "ZSNESHUDNSKEY"
		end
		v.draw(32 + 96 + 40 + 16 + 8, 15 + 8, v.cachePatch(patchname), V_SNAPTOTOP)
		local wishval = doom.KEY_SKULLRED
		local patchname = "ZSNESHUDRSKEY"
		if (player.doom.keys & (wishval)) != wishval then
			patchname = "ZSNESHUDNSKEY"
		end
		v.draw(32 + 96 + 40 + 16 + 16, 15 + 8, v.cachePatch(patchname), V_SNAPTOTOP)
	end
end)
--#endif