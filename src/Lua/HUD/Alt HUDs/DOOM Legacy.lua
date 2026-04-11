local FLASH_COLOR = 0x72

local cv_pickupflash = true

--  Draw a number, scaled, over the view
--  Always draw the number completely since it's overlay
--
--   x, y: scaled position, right border!
---@param v videolib
local function ST_drawOverlayNum(v, x, y, num, numpat, percent, pickup_flash)
	local pf = v.cachePatch("STTNUM0")
	local hf = pf.height
	local wf = pf.width
	local neg

	if pickup_flash and cv_pickupflash then
		v.drawFill(x - (wf * 3), y, wf*3, hf, FLASH_COLOR)
	end

	if num == 0 then
		v.draw(x - wf, y, pf)
	end

	neg = num < 0

	if neg then
		num = -num
	end

	while num > 0 do
		x = $ - wf
		v.draw(x, y, v.cachePatch("STTNUM" .. (num % 10)))
		num = $ / 10
	end

	if neg then
		v.draw(x - 8, y, v.cachePatch("STTMINUS"))
	end
end

local srb2hud = {
	keys = function(v, player, keys)
		keys = $ or 0
		local c = 1

		local keyOrder = {
			{doom.KEY_SKULLRED,    v.cachePatch("STKEYS5")},
			{doom.KEY_SKULLBLUE,   v.cachePatch("STKEYS3")},
			{doom.KEY_SKULLYELLOW, v.cachePatch("STKEYS4")},
			{doom.KEY_RED,         v.cachePatch("STKEYS2")},
			{doom.KEY_BLUE,        v.cachePatch("STKEYS0")},
			{doom.KEY_YELLOW,      v.cachePatch("STKEYS1")},
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
			-- FIXME: SRB2 SIGSEGVs whenever we cache a patch like SBOAMMO1?? Reserving the patch doesn't fix it
			-- Weirder is that the other SBO patches don't do this??
			local funcs = P_GetMethodsForSkin(player)
			local myWep = doom.weapons[weapon]
			local myAmmoType = myWep.ammotype
			local myAmmoDef = doom.ammos[myAmmoType]
			local myAmmoIcon = myAmmoDef.icon
			--local myIconPatch = v.cachePatch(myAmmoIcon)
			--v.draw(236, 198, myIconPatch)
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

return srb2hud