---@type videolib
local v

local function ST_drawLine(x, y, len, color, flags)
	flags = $ or 0
	v.drawFill(x, y, len, 1, color|flags)
end

local function DrawStatusBarNumbers(v, player)
	local funcs = P_GetMethodsForSkin(player)
	local myHealth = funcs.getHealth(player) or 0
	local myMaxHealth = funcs.getMaxHealth(player) or 0
	local myArmor = funcs.getArmor(player) or 0
	local myAmmo = funcs.getCurAmmo(player)

	local percentPatch = v.cachePatch("STTNUM0")
	local percentsOffset = percentPatch.width

	if myAmmo != false then
		doom.drawInFont(v, (303 + percentsOffset)*FRACUNIT, 162*FRACUNIT, FRACUNIT, "INVFONG", myAmmo, V_PERPLAYER|V_SNAPTOBOTTOM, "right")
	end
	doom.drawInFont(v, (72 + percentsOffset)*FRACUNIT, 162*FRACUNIT, FRACUNIT, "INVFONG", myHealth, V_PERPLAYER|V_SNAPTOBOTTOM, "right")

	myHealth = ($ * 100) / myMaxHealth
	local lifecolor1
	if myHealth < 11 then
		lifecolor1 = 64
	elseif myHealth < 21
		lifecolor1 = 80
	else
		lifecolor1 = 96
	end

	if player.doom.cheats & CF_GODMODE then
		lifecolor1 = 226
	end

    local barlength = myHealth
    if barlength > 100 then
    	barlength = 200 - myHealth
	end
    barlength = $ * 2;

	local lifecolor2 = lifecolor1 + 3

    ST_drawLine(49, 172, barlength, lifecolor1, V_SNAPTOBOTTOM);
	ST_drawLine(49, 173, barlength, lifecolor2, V_SNAPTOBOTTOM);
    ST_drawLine(49, 175, barlength, lifecolor1, V_SNAPTOBOTTOM);
    ST_drawLine(49, 176, barlength, lifecolor2, V_SNAPTOBOTTOM);

	if myHealth > 100 then
		lifecolor1 = 112
		lifecolor2 = lifecolor1 + 3

		local oldbarlength = barlength
		barlength = 200 - barlength

		ST_drawLine(49 + oldbarlength, 172, barlength, lifecolor1, V_SNAPTOBOTTOM)
		ST_drawLine(49 + oldbarlength, 173, barlength, lifecolor2, V_SNAPTOBOTTOM)
		ST_drawLine(49 + oldbarlength, 175, barlength, lifecolor1, V_SNAPTOBOTTOM)
		ST_drawLine(49 + oldbarlength, 176, barlength, lifecolor2, V_SNAPTOBOTTOM)
	end

	-- TODO: V_DrawPatch(2, 177, invarmor[plyr->armortype - 1]);
	doom.drawInFont(v, 20*FRACUNIT, 191*FRACUNIT, FRACUNIT, "INVFONY", myArmor, V_PERPLAYER|V_SNAPTOBOTTOM, "right")
end

COM_AddCommand("doom_sethealth", function(player, health)
	local funcs = P_GetMethodsForSkin(player)
	funcs.setHealth(player, tonumber(health) or 1)
end)

---@param drawer videolib
local function drawStatusBar(drawer, player)
	v = drawer
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
		v.draw(i * centerBorderWidth, 168, centerBorderPatch, V_SNAPTOLEFT|V_SNAPTOBOTTOM)
	end

	for i = 0, bottomBorderRepeats do
		v.draw(i * bottomBorderWidth, 168, bottomBorderPatch, V_SNAPTOLEFT|V_SNAPTOBOTTOM)
	end

	v.draw(0, 168, v.cachePatch("INVBACK"), V_PERPLAYER|V_SNAPTOBOTTOM)
	v.draw(0, 160, v.cachePatch("INVTOP"), V_PERPLAYER|V_SNAPTOBOTTOM)

	DrawStatusBarNumbers(v, player)
end

doom.hudDraw["strife"] = function(v, player)
	drawWeapon(v, player, 38)
	drawStatusBar(v, player, 1)
end