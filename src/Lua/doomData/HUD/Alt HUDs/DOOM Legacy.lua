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

-- Draw a number with the specified patch set
local function drawNumber(v, x, y, num, patches, percent, negpatch, flags)
	local font0 = (patches and patches[0]) or getPatch(v, "STTNUM0")
	local hf = font0.height
	local wf = font0.width
	local neg = false

	if num == 0 then
		v.draw(x - wf, y, font0, flags)
		return x - wf
	end

	if num < 0 then
		neg = true
		num = -num
	end

	local startx = x
	while num > 0 do
		local digit = num % 10
		x = x - wf

		if patches and patches[digit] then
			v.draw(x, y, patches[digit], flags)
		else
			v.draw(x, y, getPatch(v, "STTNUM" .. digit), flags)
		end

		num = num / 10
	end

	if neg then
		local minus = (negpatch) or getPatch(v, "STTMINUS")
		x = x - minus.width
		v.draw(x, y, minus, flags)
	end

	return x
end

-- Draw a percent value
local function drawPercent(v, x, y, num, patches, percent_patch)
	drawNumber(v, x, y, num, patches)
	if percent_patch then
		local perc = (patches and patches[10]) or percent_patch
		v.draw(x, y, perc)
	end
end

-- Draw weapon slots
local function ST_drawWeapons(v, x, y, weapons_owned, readyweapon)
	local weaponPatches = {}
	local weaponSelect = {}
	
	-- Weapon slots: pistol, shotgun, chaingun, missile, plasma, bfg
	local weaponList = {2, 3, 4, 5, 6, 7}
	
	for i, wp in ipairs(weaponList) do
		weaponPatches[i] = getPatch(v, "STGNUM" .. (wp))
		weaponSelect[i] = getPatch(v, "STYSNUM" .. (wp))
	end
	
	local armsback = getPatch(v, "STARMS")
	v.draw(x, y, armsback)
	
	for i = 1, 6 do
		local wx = x + 5 + ((i-1) % 3) * 9
		local wy = y + 6 + ((i-1) / 3) * 8
		
		if weapons_owned and weapons_owned[weaponList[i]] then
			v.draw(wx, wy, weaponPatches[i])
		end
		
		-- Highlight selected weapon
		if readyweapon == weaponList[i] then
			v.draw(wx, wy, weaponSelect[i])
		end
	end
end
/*
doom.KEY_BLUE = 1
doom.KEY_YELLOW = 2
doom.KEY_RED = 4
doom.KEY_SKULLBLUE = 8
doom.KEY_SKULLYELLOW = 16
doom.KEY_SKULLRED = 32
*/
-- Draw keys
local function ST_drawKeys(v, x, y, keys, flags)
	local keyPatches = {}
	for i = 0, 5 do
		keyPatches[i+1] = getPatch(v, "STKEYS" .. i)
	end
	
	-- Key positions: 6 keys arranged in two columns
	local keyPositions = {
		{x = 14, y = 0},   -- key 0
		{x = 7, y = 0},  -- key 1
		{x = 0, y = 0},  -- key 2
		{x = 14, y = 5},  -- key 3
		{x = 7, y = 5}, -- key 4
		{x = 0, y = 5}, -- key 5
	}
	
	for i = 0, 5 do
		if (keys & (1 << i)) ~= 0 then
			local pos = keyPositions[i+1]
			v.draw(x + pos.x, y + pos.y, keyPatches[i+1], flags)
		end
	end
end

-- Draw frags
local function ST_drawFrags(v, x, y, frags, flags)
	local frags_patch = getPatch(v, "SBOFRAGS")
	v.draw(x + 2, y, frags_patch, flags)
	drawNumber(v, x, y, frags, nil, nil, nil, flags)
end

-- Draw health
local function ST_drawHealth(v, x, y, health, flags)
	local health_patch = getPatch(v, "SBOHEALT")
	v.draw(x + 2, y, health_patch, flags)
	drawNumber(v, x, y, clamp0(health), nil, nil, nil, flags)
end

-- Draw armor
local function ST_drawArmor(v, x, y, armor, flags)
	local armor_patch = getPatch(v, "SBOARMOR")
	v.draw(x + 2, y, armor_patch, flags)
	drawNumber(v, x, y, clamp0(armor), nil, nil, nil, flags)
end

-- Draw ammo
local function ST_drawAmmo(v, x, y, ammo, ammo_type, weapon, flags)
	local ammoPics = {
		bullets = "SBOAMMO1",
		shells = "SBOAMMO2",
		rockets = "SBOAMMO4",
		cells = "SBOAMMO5",
	}
	
	local ammoPic = ammoPics[ammo_type] or "SBOAMMO1"
	local patch = getPatch(v, ammoPic)
	
	drawNumber(v, x, y, ammo or 0, nil, nil, nil, flags)
	v.draw(x + 2, y, patch, flags)
end

-- Main status bar drawer
local function ST_drawStatusBar(v, player)
	local x = 0
	local y = v.height - 32  -- Standard Doom status bar height
	
	-- Draw background
	local stbar = getPatch(v, "STBAR")
	v.draw(x, y, stbar)
	
	-- Get player data
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player) or 0
	local armor = funcs.getArmor(player) or 0
	local ammo = funcs.getCurAmmo(player) or 0
	local frags = (doom.getFrags and doom.getFrags(player)) or 0
	local weapon = player.doom and player.doom.curwep or player.readyweapon or 0
	local keys = player.doom and (player.doom.keys or 0) or 0
	
	-- Weapon ownership (simplified - assume all weapons owned for demo)
	local weapons_owned = {}
	for i = 2, 8 do
		weapons_owned[i] = true
	end
	
	-- Draw weapon slots (x: 111, y: y)
	ST_drawWeapons(v, x + 104, y, weapons_owned, weapon)
	
	-- Draw keys (x: 239, y: y)
	ST_drawKeys(v, x + 239, y, keys)
	
	-- Draw health percent (x: 90, y: y+3)
	drawPercent(v, x + 90, y + 3, health, nil)
	local perc = getPatch(v, "STTPRCNT")
	v.draw(x + 90, y + 3, perc)
	
	-- Draw armor percent (x: 221, y: y+3)
	drawPercent(v, x + 221, y + 3, armor, nil)
	v.draw(x + 221, y + 3, perc)
	
	-- Draw ammo (x: 44, y: y+3)
	local ammoType = 1  -- Default ammo type
	if weapon == 2 then ammoType = 2 end
	if weapon == 4 then ammoType = 3 end
	if weapon == 5 then ammoType = 4 end
	ST_drawAmmo(v, x + 44, y + 3, ammo, ammoType, weapon)
	
	-- Draw frags in deathmatch (x: 138, y: y+3)
	if cv_deathmatch and cv_deathmatch.value then
		drawNumber(v, x + 138, y + 3, frags, nil)
	end
end

-- Overlay drawer (the HUD when view is fullscreen)
local function ST_drawOverlay(v, player)
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player) or 0
	local armor = funcs.getArmor(player) or 0
	local ammo = funcs.getCurAmmo(player) or 0
	local frags = (doom.getFrags and doom.getFrags(player)) or 0
	local weapon = player.doom and player.doom.curwep or player.readyweapon or 0
	local keys = player.doom and (player.doom.keys or 0) or 0
	
	-- Health overlay
	local health_x = 70
	local health_y = v.height - 18
	ST_drawHealth(v, health_x, health_y, health)
	
	-- Ammo overlay
	local ammo_x = 170
	local ammo_y = v.height - 18
	ST_drawAmmo(v, ammo_x, ammo_y, ammo, 1, weapon)
	
	-- Armor overlay
	local armor_x = 270
	local armor_y = v.height - 18
	ST_drawArmor(v, armor_x, armor_y, armor)
	
	-- Keys overlay
	local keys_x = 308
	local keys_y = v.height - 10
	ST_drawKeys(v, keys_x, keys_y, keys)
	
	-- Frags overlay (top right)
	if cv_deathmatch and cv_deathmatch.value then
		local frags_x = v.width - 70
		local frags_y = 2
		ST_drawFrags(v, frags_x, frags_y, frags)
	end
end

-- Main HUD function
local function drawDoomLegacyHud(v, player)
	local funcs = P_GetMethodsForSkin(player)
	
	local myHealth = funcs.getHealth(player) or 0
	local myArmor  = funcs.getArmor(player) or 0
	local myAmmo   = funcs.getCurAmmo(player)
	local myFrags  = (doom.getFrags and doom.getFrags(player)) or 0
	local myWeapon = player.doom and (player.doom.curwep or player.readyweapon) or player.readyweapon or 0
	local myKeys   = player.doom and (player.doom.keys or 0) or 0
	
	-- Check if we should draw overlay or status bar
	local viewsize = cv_viewsize and cv_viewsize.value or 10
	local is_overlay = viewsize == 11
	local is_statusbar = viewsize < 11 or (automap and automap.active)
	
	if is_statusbar then
		ST_drawStatusBar(v, player)
	elseif is_overlay then
		ST_drawOverlay(v, player)
	end
end

local doomleghud = {
	keys = function(v, player, keys)
		ST_drawKeys(v, 296, 169, keys, V_SNAPTORIGHT|V_SNAPTOBOTTOM)
	end,
	
	ammo = function(v, player, ammo, weapon)
		local funcs = P_GetMethodsForSkin(player)
		ST_drawAmmo(v, 233, 200 - 18, ammo, funcs.getCurAmmoType(player), weapon, V_SNAPTORIGHT|V_SNAPTOBOTTOM)
	end,
	
	health = function(v, player, health)
		ST_drawHealth(v, 49, 182, health, V_SNAPTOLEFT|V_SNAPTOBOTTOM)
	end,
	
	armor = function(v, player, armor)
		ST_drawArmor(v, 299, 182, armor, V_SNAPTORIGHT|V_SNAPTOBOTTOM)
	end,
	
	frags = function(v, player, frags)
		if G_RingSlingerGametype() then
			ST_drawFrags(v, 299, 2, frags, V_SNAPTORIGHT|V_SNAPTOTOP)
		end
	end
}

return doomleghud