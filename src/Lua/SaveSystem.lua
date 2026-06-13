local SHARED_CONFIG_FILE = "client/doomport/doom_global.cfg"
local LOCAL_PREFS_FILE   = "client/doomport/doom_local.cfg"

doom.config = doom.config or {}

local function isNetvar(data)
	return data and data.flags and ((data.flags & CV_NETVAR) ~= 0)
end

local function CV_Range(min, max)
	return { MIN = min, MAX = max }
end

local CV_Percent = CV_Range(0, 100)

-- Flag for "This convar is JohnDoom-only!"
local CV_JDONLY = 0x80000000

CV_OnOff = {
	On = 1, Off = 0,
	Yes = 1, No = 0,
	True = 1, False = 0
}

---@class doomconfigent_t
---@field commandname string The name of the console command to set this config value.
---@field default string The default value for this config entry, as a string. This is what will be used if the config file is missing or has an invalid value for this entry.
---@field helpdescription string A description of what this config entry does, shown in the console when the user types "doomcfg <entryname>" without a value.
---@field possiblevalues table? If present, this is a table describing the possible values for this config entry. It can be in one of three forms:
--- 1. A simple list of possible values, e.g. { "Vanilla", "Boom", "ZDoom" }
--- 2. A table of resolve => store pairs, e.g. { Vanilla = 1, Boom = 2, ZDoom = 3 }
--- 3. A range, e.g. { MIN = 0, MAX = 10 }
---@field flags integer? A bitfield of flags. Currently recognized flags are:
--- CV_NETVAR (0x1): This config entry is a netvar and should be synchronized across clients in multiplayer. Only the server or an admin can set this value in multiplayer, and only the server persists it to the shared config file.
--- CV_JDONLY (0x80000000): This config entry is only applicable to JohnDoom and should be hidden or disabled in other ports. This is mostly just informational, but may be used by external tools to filter config entries.

-- TODO: Maybe cut the keys down if they're too long? Should be better on NetXCmd
-- Also maybe grouping (under player.doom.prefs.value.subvalue)
---@type table<string, doomconfigent_t>
doom.configents = {
	-- Gameplay
	autorun = {commandname = "doom_alwaysrun", default = "0", helpdescription = "Automatically run", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	monster_infiniteheight = {commandname = "doom_infiniteheightmonsters", default = "Off", helpdescription = "Infinite Height Monsters", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	alwayspistolstart = {commandname = "doom_alwayspistolstart", default = "Off", helpdescription = "Always Pistol Start", possiblevalues = CV_OnOff, flags = CV_NETVAR|CV_JDONLY},
	verticalaim = {commandname = "doom_verticalaim", default = "On", helpdescription = "Vertical Aiming", possiblevalues = CV_OnOff, flags = CV_NETVAR|CV_JDONLY},
	fastmonsters = {commandname = "doom_fastmonsters", default = "Off", helpdescription = "Fast Monsters", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	monsterrespawn = {commandname = "doom_monsterrespawn", default = "Off", helpdescription = "Monster Respawn", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	autoaimbehavior = {commandname = "doom_autoaimbehavior", default = "Original", helpdescription = "Auto-Aim Behavior", possiblevalues = {Off = 0, Original = 1, IgnoreBarrels = 2}, flags = CV_NETVAR|CV_JDONLY},

	-- MP
	dm_dropweapon = {commandname = "doom_dropweaponspref", default = "On", helpdescription = "Deathmatch Weapon Dropping Preference", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	dm_weaponsstay = {commandname = "doom_dm_weaponsstay", default = "Off", helpdescription = "Deathmatch Weapons Stay When Picked Up", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	dm_respawninvulntime = {commandname = "doom_dm_respawninvulntime", default = "3", helpdescription = "Deathmatch Respawn Invulnerability Time (seconds)", possiblevalues = CV_Range(0, 10), flags = CV_NETVAR},
	coop_spawnmultiplayerthings = {commandname = "doom_coop_spawnmultiplayerthings", default = "On", helpdescription = "Coop Spawn Multiplayer Things", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_spawnmultiplayeritems = {commandname = "doom_coop_spawnmultiplayeritems", default = "On", helpdescription = "Coop Spawn Multiplayer Items", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_spawnmultiplayerweapons = {commandname = "doom_coop_spawnmultiplayerweapons", default = "On", helpdescription = "Coop Spawn Multiplayer Weapons", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_sharekeys = {commandname = "doom_coop_sharekeys", default = "Off", helpdescription = "Coop Share Keys", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_shootthroughplayers = {commandname = "doom_friendlyfire", default = "On", helpdescription = "Friendly Fire", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	timelimit = {commandname = "doom_timelimit", default = "0", helpdescription = "Time Limit (minutes)", possiblevalues = CV_Range(0, 60), flags = CV_NETVAR},
	fraglimit = {commandname = "doom_fraglimit", default = "0", helpdescription = "Frag Limit", possiblevalues = CV_Range(0, 100), flags = CV_NETVAR},

	-- Automap
	automaprotation = {commandname = "doom_automaprotation", default = "On", helpdescription = "Automap Rotation By Player Angle", possiblevalues = CV_OnOff},
	automapoverlay = {commandname = "doom_automapoverlay", default = "On", helpdescription = "Automap Overlay", possiblevalues = CV_OnOff},
	automaprotateprefangle = {commandname = "doom_automaprotatepreferenceangle", default = "45", helpdescription = "Automap Rotation Preference Angle", possiblevalues = CV_Range(0, 360)},
	automapshowghostlines = {commandname = "doom_showghostlines", default = "On", helpdescription = "Show Ghost Lines On Automap", possiblevalues = CV_OnOff},

	-- HUD
	statusbaropacity = {commandname = "doom_statusbaropacity", default = "0", helpdescription = "Status Bar Opacity", possiblevalues = CV_Range(0, 10)},
	hudstyle   = {commandname = "doom_hudpreference", default = "Original", helpdescription = "HUD Style Preference", possiblevalues = {Original = 1, BOOMStacked = 2, BOOMStacked_Nostats = 3, BOOMDistributed = 4, BOOMDistributed_Nostats = 5, Woof = 6, Woof_Mugshot = 7, DoomLegacy = 8}, flags = CV_JDONLY},
	hudColorization = {commandname = "doom_vanillahudcolorization", default = "Off", helpdescription = "Vanilla HUD Colorization", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	hudGrayPercenting = {commandname = "doom_vanillahudgraypercenting", default = "Off", helpdescription = "Vanilla HUD Gray Percent", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	t_ammo_red = {commandname = "doom_hudthresholds_ammo_red", default = "25", helpdescription = "Ammo HUD Red Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_ammo_yellow = {commandname = "doom_hudthresholds_ammo_yellow", default = "50", helpdescription = "Ammo HUD Yellow Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_health_red = {commandname = "doom_hudthresholds_health_red", default = "25", helpdescription = "Health HUD Red Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_health_yellow = {commandname = "doom_hudthresholds_health_yellow", default = "50", helpdescription = "Health HUD Yellow Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_health_green = {commandname = "doom_hudthresholds_health_green", default = "100", helpdescription = "Health HUD Green Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_armor_red = {commandname = "doom_hudthresholds_armor_red", default = "25", helpdescription = "Armor HUD Red Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_armor_yellow = {commandname = "doom_hudthresholds_armor_yellow", default = "50", helpdescription = "Armor HUD Yellow Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	t_armor_green = {commandname = "doom_hudthresholds_armor_green", default = "100", helpdescription = "Armor HUD Green Threshold", possiblevalues = CV_Percent, flags = CV_JDONLY},
	-- Port of con_textsize
	textSize = {commandname = "doom_textsize", default = "0", helpdescription = "Text Size", possiblevalues = {Huge = 0, Large = 768, Medium = 512, Small = 256}},
	textRows = {commandname = "doom_textrows", default = "1", helpdescription = "Text Rows", possiblevalues = CV_Range(1, 20)},
	textDuration = {commandname = "doom_textduration", default = "5", helpdescription = "Text Duration (seconds)", possiblevalues = CV_Range(1, 60)},
	hudFlashes = {commandname = "doom_hudflashes", default = "On", helpdescription = "HUD Flashes", possiblevalues = CV_OnOff},
	autoswitch = {commandname = "doom_allowautoswitch", default = "On", helpdescription = "Allow Auto-Switching", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	weaponbob = {commandname = "doom_weaponbob", default = "On", helpdescription = "Weapon Bobbing", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	centerweapononfire = {commandname = "doom_firecentering", default = "On", helpdescription = "Weapon Centering On Fire", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	messagepriority = {commandname = "doom_messagepriority", default = "On", helpdescription = "Message Priority", possiblevalues = {Pickups = 3, Obituary = 2, Status = 1, Off = 0}},
	secretnotify = {commandname = "doom_secretnotify", default = "On", helpdescription = "Secret Found Notifications", possiblevalues = CV_OnOff},
	showobituaries = {commandname = "doom_showobituaries", default = "On", helpdescription = "Show Obituaries", possiblevalues = CV_OnOff},
}

local function maybeCoerceToNumber(value)
	local tonum = tonumber(value)
	if tonum ~= nil then return tonum end
	return value
end

local function normalizeValue(data, value)
	if not data.possiblevalues then
		return maybeCoerceToNumber(value)
	end

	local pv = data.possiblevalues

	if pv.MIN != nil and pv.MAX != nil then
		local num = maybeCoerceToNumber(value)
		if num != nil and num >= pv.MIN and num <= pv.MAX then
			return num
		end
		return nil
	end

	for resolve, store in pairs(pv) do
		if tostring(resolve) == tostring(value) or tostring(store) == tostring(value) then
			return resolve
		end
	end

	for _, v in ipairs(pv) do
		if tostring(v) == tostring(value) then
			return maybeCoerceToNumber(v)
		end
	end

	return nil
end

local function getStoreValue(data, value)
	if not data.possiblevalues then
		return maybeCoerceToNumber(value)
	end

	local pv = data.possiblevalues

	if pv.MIN != nil and pv.MAX != nil then
		local num = maybeCoerceToNumber(value)
		if num != nil and num >= pv.MIN and num <= pv.MAX then
			return num
		end
		return nil
	end

	for resolve, store in pairs(pv) do
		if tostring(resolve) == tostring(value) then
			return store
		end
		if tostring(store) == tostring(value) then
			return store
		end
	end

	for _, v in ipairs(pv) do
		if tostring(v) == tostring(value) then
			return maybeCoerceToNumber(v)
		end
	end

	return nil
end

local function getResolveValue(data, stored)
	if not data.possiblevalues then
		return maybeCoerceToNumber(stored)
	end

	local pv = data.possiblevalues

	if pv.MIN != nil and pv.MAX != nil then
		local num = maybeCoerceToNumber(stored)
		if num != nil and num >= pv.MIN and num <= pv.MAX then
			return num
		end
		return nil
	end

	for resolve, store in pairs(pv) do
		if tostring(store) == tostring(stored) or tostring(resolve) == tostring(stored) then
			return resolve
		end
	end

	for _, v in ipairs(pv) do
		if tostring(v) == tostring(stored) then
			return maybeCoerceToNumber(v)
		end
	end

	return nil
end

local function getDefaultStoreValue(data)
	return getStoreValue(data, data.default)
end

local function backfillDefaults(store, wantNetvar)
	if not store then return false end

	local changed = false

	for key, data in pairs(doom.configents) do
		if isNetvar(data) == wantNetvar and store[key] == nil then
			local def = getDefaultStoreValue(data)
			if def ~= nil then
				store[key] = def
				changed = true
			end
		end
	end

	return changed
end

local function canWriteShared(player)
	return player == server
end

local function canTouchNetvars(player, data)
	if not isNetvar(data) then
		return true
	end

	if player == server then
		return true
	end

	return IsPlayerAdmin(player)
end

local function getNetvarStore()
	doom.config = doom.config or {}
	return doom.config
end

local function getLocalStore(player)
	if not player then return nil end
	if not player.doom then player.doom = {} end
	if not player.doom.prefs then player.doom.prefs = {} end
	return player.doom.prefs
end

local function writeStore(path, store, wantNetvar)
	local file = io.openlocal(path, "w")
	if not file then
		return false
	end

	for key, data in pairs(doom.configents) do
		if isNetvar(data) == wantNetvar then
			local raw = store and store[key]

			if raw == nil then
				raw = getDefaultStoreValue(data)
			end

			local stored = getStoreValue(data, raw)
			if stored ~= nil then
				file:write(tostring(key) .. "=" .. tostring(stored) .. "\n")
			end
		end
	end

	file:close()
	return true
end

local function savePrefs(player)
	if player and player ~= consoleplayer and player ~= server then
		return
	end

	-- Only the actual server player may write the shared netvar file.
	if player == server then
		writeStore(SHARED_CONFIG_FILE, doom.config, true)
	end

	-- Local prefs are per-client and can be written by the local player.
	if player == consoleplayer then
		local localstore = getLocalStore(player)
		if localstore then
			writeStore(LOCAL_PREFS_FILE, localstore, false)
		end
	end
end

local function loadStore(path, store, wantNetvar)
	local file = io.openlocal(path, "r")

	if file then
		for line in file:lines() do
			local k, v = line:match("([^=]+)=(.*)")
			local def = k and doom.configents[k] or nil

			if k and v and def and isNetvar(def) == wantNetvar then
				local stored = getStoreValue(def, v)
				if stored ~= nil then
					store[k] = stored
				else
					CONS_Printf(consoleplayer, "Invalid value in " .. path .. " for key " .. k .. ": " .. v)
				end
			end
		end

		file:close()
	end

	local changed = backfillDefaults(store, wantNetvar)
	return changed
end

local function loadPrefs(player)
	player.doom = $ or {}
	player.doom.prefs = $ or {}

	if player ~= consoleplayer and player ~= server then
		return
	end

	if player == server then
		local changed = loadStore(SHARED_CONFIG_FILE, getNetvarStore(), true)
		if changed then
			writeStore(SHARED_CONFIG_FILE, getNetvarStore(), true)
		end
	end

	if player == consoleplayer then
		local localstore = getLocalStore(player)
		if localstore then
			local changed = loadStore(LOCAL_PREFS_FILE, localstore, false)
			if changed then
				writeStore(LOCAL_PREFS_FILE, localstore, false)
			end
		end
	end
end

local function displayHelp(player, commandname)
	if player ~= consoleplayer and player ~= server then return end

	local def = doom.configents[commandname]
	if not def then
		CONS_Printf(player, "Unknown command: " .. commandname)
		return
	end

	CONS_Printf(player, "Usage: " .. def.commandname .. " <value>")
	CONS_Printf(player, def.helpdescription)
	CONS_Printf(player, "Possible values:")

	local alreadyDid = {}
	local pv = def.possiblevalues

	if pv ~= nil and pv.MIN != nil and pv.MAX != nil then
		CONS_Printf(player, "  " .. pv.MIN .. " to " .. pv.MAX)
	elseif pv == CV_OnOff then
		CONS_Printf(player, "  On, Off, Yes, No, True, False")
	else
		local sorted = {}
		for k, v in pairs(pv) do
			if tostring(k) ~= tostring(v) then
				table.insert(sorted, {k = k, v = v})
			end
		end

		table.sort(sorted, function(a, b)
			return a.v < b.v
		end)

		for _, entry in ipairs(sorted) do
			if alreadyDid[entry.v] then continue end
			CONS_Printf(player, "  " .. entry.k .. " = " .. entry.v)
			alreadyDid[entry.v] = true
		end
	end

	local store = isNetvar(def) and doom.config or (player.doom and player.doom.prefs)
	local currentRaw = store and store[commandname] or nil

	if currentRaw == nil then
		currentRaw = getDefaultStoreValue(def)
	end

	local currentResolved = getResolveValue(def, currentRaw)
	CONS_Printf(player, "Current value: " .. tostring(currentResolved))
end

COM_AddCommand("doomcfg", function(player, key, value)
	if not key or not value then return end

	local data = doom.configents[key]
	if not data then
		CONS_Printf(player, "Unknown command: " .. tostring(key))
		return
	end

	if not canTouchNetvars(player, data) then
		CONS_Printf(player, "This command can only be used by the server or an admin in multiplayer!")
		return
	end

	local normalized = normalizeValue(data, value)
	if normalized == nil then
		CONS_Printf(player, "Invalid value for " .. tostring(key))
		displayHelp(player, key)
		return
	end

	if isNetvar(data) then
		local netstore = getNetvarStore()
		netstore[key] = normalized
		CONS_Printf(player, "Set " .. key .. " to " .. tostring(normalized))

		-- Only the server player persists shared config.
		if canWriteShared(player) then
			writeStore(SHARED_CONFIG_FILE, netstore, true)
		end
	else
		local localstore = getLocalStore(player)
		if not localstore then return end
		localstore[key] = normalized
		CONS_Printf(player, "Set " .. key .. " to " .. tostring(normalized))

		if player == consoleplayer then
			writeStore(LOCAL_PREFS_FILE, localstore, false)
		end
	end
end)

for internalName, data in pairs(doom.configents) do
	COM_AddCommand(data.commandname, function(player, value)
		if not value then
			displayHelp(player, internalName)
			return
		end

		if not canTouchNetvars(player, data) then
			CONS_Printf(player, "This command can only be used by the server or an admin in multiplayer!")
			return
		end

		local normalized = normalizeValue(data, value)
		if normalized == nil then
			CONS_Printf(player, "Invalid value for " .. tostring(internalName))
			displayHelp(player, internalName)
			return
		end

		if isNetvar(data) then
			local netstore = getNetvarStore()
			netstore[internalName] = normalized
			CONS_Printf(player, "Set " .. internalName .. " to " .. tostring(normalized))

			-- Do not touch the shared file unless this is the real server player.
			if canWriteShared(player) then
				writeStore(SHARED_CONFIG_FILE, netstore, true)
			end
		else
			local localstore = getLocalStore(player)
			if not localstore then return end
			-- TODO: Kinda sucks
			localstore[internalName] = getStoreValue(data, value)
			CONS_Printf(player, "Set " .. internalName .. " to " .. tostring(normalized))

			if player == consoleplayer then
				writeStore(LOCAL_PREFS_FILE, localstore, false)
			end
		end
	end)
end

rawset(_G, "DOOM_GetConfigStoreValue", function(player, cvar)
	local cvardef = doom.configents[cvar]
	if not cvardef then return nil end

	local store = isNetvar(cvardef)
		and doom.config
		or (player and player.doom and player.doom.prefs)

	local raw = store and store[cvar]

	if raw == nil then
		raw = getDefaultStoreValue(cvardef)
	end

	return maybeCoerceToNumber(raw)
end)

rawset(_G, "DOOM_GetConfigResolveValue", function(player, cvar)
	local cvardef = doom.configents[cvar]
	if not cvardef then return nil end

	local store = isNetvar(cvardef)
		and doom.config
		or (player and player.doom and player.doom.prefs)

	local raw = store and store[cvar]

	if raw == nil then
		raw = getDefaultStoreValue(cvardef)
	end

	return maybeCoerceToNumber(getResolveValue(cvardef, raw))
end)

addHook("PlayerSpawn", loadPrefs)

rawset(_G, "DOOM_SavePrefs", savePrefs)
rawset(_G, "DOOM_LoadPrefs", loadPrefs)