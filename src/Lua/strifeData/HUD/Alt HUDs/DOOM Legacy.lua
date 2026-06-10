local FLASH_COLOR = 0x72

local cv_pickupflash = true

local patchcache = {}

local function getPatch(v, name)
	local p = patchcache[name]
	if not p then
		p = v.cachePatch(name)
		patchcache[name] = p
	end
	return p
end

local function clamp0(n)
	if n < 0 then
		return 0
	end
	return n
end

local function getBool(v)
	if type(v) == "boolean" then
		return v
	end
	if type(v) == "table" and v.value ~= nil then
		return v.value ~= 0
	end
	return not not v
end

--  Draw a number, scaled, over the view
--  Always draw the number completely since it's overlay
--
--   x, y: right-aligned position
local function ST_drawOverlayNum(v, x, y, num, numpat, percent, pickup_flash)
	local font0 = (numpat and numpat[0]) or getPatch(v, "STTNUM0")
	local hf = font0.height
	local wf = font0.width
	local neg = false

	if pickup_flash and getBool(cv_pickupflash) then
		v.drawFill(x - (wf * 3), y, wf * 3, hf, FLASH_COLOR)
	end

	-- Special case: zero still draws a zero
	if num == 0 then
		v.draw(x - wf, y, font0)
		return
	end

	if num < 0 then
		neg = true
		num = -num
	end

	while num > 0 do
		local digit = num % 10
		x = $ - wf

		if numpat and numpat[digit] then
			v.draw(x, y, numpat[digit])
		else
			v.draw(x, y, getPatch(v, "STTNUM" .. digit))
		end

		num = $ / 10
	end

	if neg then
		local minus = (numpat and numpat[10]) or getPatch(v, "STTMINUS")
		v.draw(x - minus.width, y, minus)
	end
end

local function ST_drawOverlayKeys(v, x, y, cards, pickup_flash)
	local keyPatches = {
		getPatch(v, "STKEYS0"),
		getPatch(v, "STKEYS1"),
		getPatch(v, "STKEYS2"),
		getPatch(v, "STKEYS3"),
		getPatch(v, "STKEYS4"),
		getPatch(v, "STKEYS5"),
	}

	-- bitfield layout:
	-- 0x01/0x02/0x04 = cards
	-- 0x08/0x10/0x20 = skulls
	local xinc = 8
	local yinc = 6
	local yh = y

	if (cards & 0x38) ~= 0 then
		yh = y - yinc
	end

	if pickup_flash and getBool(cv_pickupflash) then
		v.drawFill(x - (xinc * 3), yh, (xinc * 3), y - yh + yinc, FLASH_COLOR)
	end

	for i = 1, 3 do
		x = $ - xinc

		if (cards & (1 << (i + 2))) ~= 0 then
			v.draw(x, y, keyPatches[i + 3])
		end

		if (cards & (1 << (i - 1))) ~= 0 then
			v.draw(x, yh, keyPatches[i])
		end
	end
end

local function getTotalKills()
	return doom.killcount or 0
end

local function getTotalSecrets()
	return doom.secretcount or 0
end

-- TODO!
-- Currently just a DOOM Legacy-themed SRB2 hud
local srb2hud = {
	keys = function(v, player, keys)
		keys = keys or 0
		ST_drawOverlayKeys(v, 318, 174, keys, false)
	end,

	ammo = function(v, player, ammo, weapon)
		if ammo ~= false then
			local myWep = doom.weapons[weapon]
			local myAmmoType = myWep and myWep.ammotype

			doom.drawInFont(v, 234 * FRACUNIT, 182 * FRACUNIT, FRACUNIT, "STT", tostring(ammo), V_PERPLAYER, "right")

			local myAmmoDef = doom.ammos[myAmmoType]
			if myAmmoDef and myAmmoDef.icon then
			    v.draw(236, 182, getPatch(v, myAmmoDef.icon))
			end
		end
	end,

	health = function(v, player, health)
		v.draw(16, 42, getPatch(v, "SBOHEALT"))
		doom.drawInFont(v, 112 * FRACUNIT, 40 * FRACUNIT, FRACUNIT, "STT", tostring(clamp0(health - 1)), V_PERPLAYER, "right")
	end,

	armor = function(v, player, armor)
		v.draw(17, 26, getPatch(v, "SBOARMOR"))
		doom.drawInFont(v, 112 * FRACUNIT, 24 * FRACUNIT, FRACUNIT, "STT", tostring(clamp0(armor)), V_PERPLAYER, "right")
	end,

	frags = function(v, player, frags)
		v.draw(16, 10, getPatch(v, "SBOFRAGS"))
		doom.drawInFont(v, 128 * FRACUNIT, 9 * FRACUNIT, FRACUNIT, "STT", tostring(clamp0(frags or 0)), V_PERPLAYER, "right")
	end
}

return srb2hud