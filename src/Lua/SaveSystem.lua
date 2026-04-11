local PREFS_FILE = "client/doomport/prefs.txt"

local function CV_Range(min, max)
	return { MIN = min, MAX = max }
end

local CV_Percent = CV_Range(0, 100)

-- Flag for "This convar is JohnDoom-only!"
local CV_JDONLY = 0x80000000

local CV_OnOff = {
	On = 1, Off = 0,
	Yes = 1, No = 0,
	True = 1, False = 0
}

doom.CV_OnOff = CV_OnOff

-- TODO: Maybe cut the keys down if they're too long? Should be better on NetXCmd
-- Also maybe grouping (under player.doom.prefs.value.subvalue)
doom.configents = {
	-- Gameplay
	autorun = {commandname = "doom_alwaysrun", default = "No", helpdescription = "Automatically run", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	monster_infiniteheight = {commandname = "doom_infiniteheightmonsters", default = "No", helpdescription = "Infinite Height Monsters", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	alwayspistolstart = {commandname = "doom_alwayspistolstart", default = "No", helpdescription = "Always Pistol Start", possiblevalues = CV_OnOff, flags = CV_NETVAR|CV_JDONLY},
	verticalaim = {commandname = "doom_verticalaim", default = "Yes", helpdescription = "Vertical Aiming", possiblevalues = CV_OnOff, flags = CV_NETVAR|CV_JDONLY},
	fastmonsters = {commandname = "doom_fastmonsters", default = "No", helpdescription = "Fast Monsters", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	monsterrespawn = {commandname = "doom_monsterrespawn", default = "No", helpdescription = "Monster Respawn", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	autoaimbehavior = {commandname = "doom_autoaimbehavior", default = "Original", helpdescription = "Auto-Aim Behavior", possiblevalues = {Off = 0, Original = 1, IgnoreBarrels = 2}, flags = CV_NETVAR|CV_JDONLY},

	-- MP
	dm_dropweapon					= {commandname = "doom_dropweaponspref", default = "Held", helpdescription = "DM Weapon Dropping", possiblevalues = {Nothing = 0, Held = 1, All = 2}, flags = CV_NETVAR},
	dm_weaponsstay					= {commandname = "doom_dm_weaponsstay", default = "Yes", helpdescription = "DM Weapons Stay When Picked Up", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	dm_respawninvulntime			= {commandname = "doom_dm_respawninvulntime", default = "3", helpdescription = "DM Respawn Invuln Time", possiblevalues = CV_Range(0, 10), flags = CV_NETVAR},
	coop_spawnmultiplayerthings		= {commandname = "doom_coop_spawnmultiplayerthings", default = "Yes", helpdescription = "Coop Monster Spawning", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_spawnmultiplayeritems		= {commandname = "doom_coop_spawnmultiplayeritems", default = "Yes", helpdescription = "Coop Item Spawning", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_spawnmultiplayerweapons	= {commandname = "doom_coop_spawnmultiplayerweapons", default = "Yes", helpdescription = "Coop Weapon Spawning", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_sharekeys					= {commandname = "doom_coop_sharekeys", default = "Yes", helpdescription = "Coop Share Keys", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	coop_shootthroughplayers		= {commandname = "doom_friendlyfire", default = "Yes", helpdescription = "Friendly Fire", possiblevalues = CV_OnOff, flags = CV_NETVAR},
	timelimit						= {commandname = "doom_timelimit", default = "0", helpdescription = "Time Limit (minutes)", possiblevalues = CV_Range(0, 60), flags = CV_NETVAR},
	fraglimit						= {commandname = "doom_fraglimit", default = "0", helpdescription = "Frag Limit", possiblevalues = CV_Range(0, 100), flags = CV_NETVAR},

	-- Automap
	automaprotation = {commandname = "doom_automaprotation", default = "No", helpdescription = "Automap Rotates", possiblevalues = CV_OnOff},
	automapoverlay = {commandname = "doom_automapoverlay", default = "No", helpdescription = "Automap Overlay", possiblevalues = CV_OnOff},
	automaprotateprefangle = {commandname = "doom_automaprotatepreferenceangle", default = "0", helpdescription = "Automap Rotation Prefangle", possiblevalues = CV_Range(0, 360)},
	automapshowghostlines = {commandname = "doom_showghostlines", default = "No", helpdescription = "Show Ghost Lines On Automap", possiblevalues = CV_OnOff},

	-- HUD
	statusbaropacity = {commandname = "doom_statusbaropacity", default = "0", helpdescription = "Status Bar Opacity", possiblevalues = CV_Range(0, 10)},
	hudstyle   = {commandname = "doom_hudpreference", default = "Original", helpdescription = "HUD Style Preference", possiblevalues = {Original = 1, BOOMStacked = 2, BOOMStacked_NS = 3, BOOMDistributed = 4, BOOMDistributed_NS = 5, Woof = 6, Woof_Mugshot = 7}, flags = CV_JDONLY},
	hudColorization = {commandname = "doom_vanillahudcolorization", default = "No", helpdescription = "Vanilla HUD Colorization", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	hudGrayPercenting = {commandname = "doom_vanillahudgraypercenting", default = "No", helpdescription = "Vanilla HUD Gray Percent", possiblevalues = CV_OnOff, flags = CV_JDONLY},
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
	hudFlashes = {commandname = "doom_hudflashes", default = "Yes", helpdescription = "HUD Flashes", possiblevalues = CV_OnOff},
	autoswitch = {commandname = "doom_allowautoswitch", default = "Yes", helpdescription = "Allow Auto-Switching", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	weaponbob = {commandname = "doom_weaponbob", default = "Yes", helpdescription = "Weapon Bobbing", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	centerweapononfire = {commandname = "doom_firecentering", default = "Yes", helpdescription = "Weapon Centering On Fire", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	messagepriority = {commandname = "doom_messagepriority", default = "Status", helpdescription = "Message Priority", possiblevalues = {Pickups = 3, Obituary = 2, Status = 1, Off = 0}},
	secretnotify = {commandname = "doom_secretnotify", default = "Yes", helpdescription = "Secret Found Notifications", possiblevalues = CV_OnOff},
	showobituaries = {commandname = "doom_showobituaries", default = "Yes", helpdescription = "Show Obituaries", possiblevalues = CV_OnOff},
	ouchfacebug = {commandname = "doom_ouchfacebug", default = "Yes", helpdescription = "Ouch Face Bug", possiblevalues = CV_OnOff, flags = CV_JDONLY},
	weaponlightupbehavior = {commandname = "doom_weaponlightsbehavior", default = "AllWeapons", helpdescription = "Weapon Number Behavior", possiblevalues = {Original = 0, AllWeapons = 1}, flags = CV_JDONLY},
	nosecrets = {commandname = "doom_nosecrets", default = "No", helpdescription = "Display Stats On HUD", possiblevalues = CV_OnOff, flags = CV_JDONLY},
}

local function displayHelp(player, commandname)
	if player ~= consoleplayer then return end

	local def = doom.configents[commandname]
	if not def then
		CONS_Printf(player, "Unknown command: " .. commandname)
		return
	end
	CONS_Printf(player, "Usage: " .. doom.configents[commandname].commandname .. " <value>")
	CONS_Printf(player, def.helpdescription)
	CONS_Printf(player, "Possible values:")
	local alreadyDid = {}
	local pv = def.possiblevalues
	if pv.MIN and pv.MAX then
		CONS_Printf(player, "  " .. pv.MIN .. " to " .. pv.MAX)
	elseif pv == CV_OnOff then
		CONS_Printf(player, "  On, Off, Yes, No, True, False")
	else
		-- Collect entries
		local sorted = {}
		for k, v in pairs(pv) do
			-- Prevent "0 = 0"
			if tostring(k) != tostring(v) then
				table.insert(sorted, {k = k, v = v})
			end
		end

		-- Sort by numeric value (ascending)
		table.sort(sorted, function(a, b)
			return a.v < b.v
		end)

		-- Print in order, avoiding duplicates
		for _, entry in ipairs(sorted) do
			if alreadyDid[entry.v] then continue end
			CONS_Printf(player, "  " .. entry.k .. " = " .. entry.v)
			alreadyDid[entry.v] = true
		end
	end

	CONS_Printf(player, "Current value: " .. tostring(player.doom.prefs[commandname]))

	if def.flags and def.flags & CV_JDONLY != 0 then
		if player.mo.skin != "johndoom" then
			CONS_Printf(player, "(This command may not have an effect on your current character)")
		end
	end
end

local function maybeCoerceToNumber(value)
	local tonum = tonumber(value)
	if tonum != nil then return tonum end
	return value
end

local function getStoreValue(data, input)
    if not data.possiblevalues then return input end

    local pv = data.possiblevalues

    -- RANGE SUPPORT
    if pv.MIN and pv.MAX then
        local num = maybeCoerceToNumber(input)
        if num and num >= pv.MIN and num <= pv.MAX then
            return tostring(num)
        end
        return nil
    end

    -- keyed table (resolve → store)
    if pv[input] ~= nil then
        return tostring(pv[input])
    end

    -- array fallback
    for _, v in ipairs(pv) do
        if v == input then return maybeCoerceToNumber(v) end
    end

    return nil
end

local function normalizeValue(data, value)
    if not data.possiblevalues then return value end

    local pv = data.possiblevalues

    if pv.MIN and pv.MAX then
        local num = maybeCoerceToNumber(value)
        if num and num >= pv.MIN and num <= pv.MAX then
            return num
        end
        return nil
    end

    -- accept either "Original" or "1"
    for resolve, store in pairs(pv) do
        if tostring(resolve) == tostring(value) or tostring(store) == tostring(value) then
            return resolve
        end
    end

    return nil
end

local function getResolveValue(data, stored)
    if not data.possiblevalues then return stored end

    local pv = data.possiblevalues

    -- RANGE SUPPORT
    if pv.MIN and pv.MAX then
        local num = maybeCoerceToNumber(stored)
        if num and num >= pv.MIN and num <= pv.MAX then
            return num
        end
        return nil
    end

    -- keyed table (resolve → store)
    for resolve, store in pairs(pv) do
        if tostring(store) == tostring(stored) then
            return resolve
        end
    end

    -- array fallback
    for _, v in ipairs(pv) do
        if tostring(v) == tostring(stored) then return maybeCoerceToNumber(v) end
    end

    return nil
end

local function isValidValue(data, value)
    return getResolveValue(data, value) ~= nil
end

local function savePrefs(player)
    if player ~= consoleplayer then return end
	local targ
	if not player then
		targ = doom.prefs
	else
		targ = player.doom and player.doom.prefs
	end
    if targ then return end

    local file = io.openlocal(PREFS_FILE, "w")
    if not file then
        CONS_Printf(player, "Failed to open prefs file for writing")
        return
    end

    for k, v in pairs(targ) do
		local storeval = getStoreValue(doom.configents[k], v)
        file:write(tostring(k) .. "=" .. tostring(storeval) .. "\n")
    end

    file:close()
end

-- Command to set preferences (networked)
COM_AddCommand("doomcfg", function(player, key, value)
    if not key or not value then return end

    if not player.doom then player.doom = {} end
    if not player.doom.prefs then player.doom.prefs = {} end

    player.doom.prefs[key] = maybeCoerceToNumber(value)
end)

-- Get the store value for a given player + cvar
-- Opposite to the resolve value, which is already in
-- p.doom.prefs[cvar]
rawset(_G, "DOOM_GetConfigStoreValue", function(player, cvar)
	local cvardef = doom.configents[cvar]
	if not cvardef then return nil end

	local raw = player.doom and player.doom.prefs and player.doom.prefs[cvar]
	if raw == nil then return nil end

	local normalized = normalizeValue(cvardef, raw)
	if normalized == nil then return nil end

	return maybeCoerceToNumber(getStoreValue(cvardef, normalized))
end)

-- Opposite of above
rawset(_G, "DOOM_GetConfigResolveValue", function(player, cvar)
	local targ
	if not player then
		targ = doom.prefs
	else
		targ = player.doom and player.doom.prefs
	end
    if targ then return end
	local resolve = targ[cvar]
	return maybeCoerceToNumber(resolve)
end)

for internalName, data in pairs(doom.configents) do
	-- Helper: resolves numeric value to its string alias
	local function resolveAlias(data, input)
		local num = tonumber(input)
		if num then
			-- look for a key whose value matches the number
			for k, v in pairs(data.possiblevalues) do
				if type(k) == "string" and v == num then
					return k
				end
			end
		end
		return input -- fallback: return original input if no match
	end

	if data.flags and (data.flags & CV_NETVAR) then
		COM_AddCommand(data.commandname, function(player, value)
			if multiplayer then
				local isAdmin = player == server
				if not isAdmin then
					isAdmin = IsPlayerAdmin(player)
				end
				if isAdmin then
					CONS_Printf(player, "This command can only be used by the server in multiplayer!")
					return
				end
			end
			if not value then
				displayHelp(player, internalName)
				return
			end

			if not player.doom then player.doom = {} end
			if not player.doom.prefs then player.doom.prefs = {} end

			-- Coerce to number if possible
			local numericValue = maybeCoerceToNumber(value)
			player.doom.prefs[internalName] = numericValue

			-- Resolve numeric input to string alias
			local alias = resolveAlias(data, value)

			CONS_Printf(player, "Set " .. internalName .. " to " .. tostring(alias))
			savePrefs(player)
		end)
	else
		COM_AddCommand(data.commandname, function(player, value)
			if not value then
				displayHelp(player, internalName)
				return
			end

			if not player.doom then player.doom = {} end
			if not player.doom.prefs then player.doom.prefs = {} end

			-- Coerce to number if possible
			local numericValue = maybeCoerceToNumber(value)
			player.doom.prefs[internalName] = numericValue

			-- Resolve numeric input to string alias
			local alias = resolveAlias(data, value)

			CONS_Printf(player, "Set " .. internalName .. " to " .. tostring(alias))
			savePrefs(player)
		end)
	end
end

local function loadPrefs(player)
    if player ~= consoleplayer then return end
    if not player.doom then player.doom = {} end
    if not player.doom.prefs then player.doom.prefs = {} end

    local file = io.openlocal(PREFS_FILE, "r")

    if file then
        -- File exists, load it
        for line in file:lines() do
            local k, v = line:match("([^=]+)=(.*)")
            if k and v then
				local resolved = getStoreValue(doom.configents[k], v)
				if resolved then
					player.doom.prefs[k] = maybeCoerceToNumber(resolved)
				else
					CONS_Printf(player, "Invalid value in prefs for key " .. k .. ": " .. v)
				end
            end
        end
        file:close()
    else
        -- File does NOT exist → populate defaults immediately
        for key, data in pairs(doom.configents) do
			local resolved = getResolveValue(data, data.default)
            player.doom.prefs[key] = maybeCoerceToNumber(resolved)
        end

        -- Create the file with defaults
        savePrefs(player)
    end

    -- Ensure all config entries exist + push them
    for key, data in pairs(doom.configents) do
        local value = player.doom.prefs[key]

        -- Fix invalid/missing values
        if not isValidValue(data, value) then
            value = data.default
            player.doom.prefs[key] = maybeCoerceToNumber(value)
        end

		local resolved = getResolveValue(data, value)
		if resolved then
			COM_BufInsertText(player, "doomcfg " .. key .. " " .. resolved)
		end
    end
end

-- Hook to load prefs on player spawn
addHook("PlayerSpawn", loadPrefs)

-- Also expose
rawset(_G, "DOOM_SavePrefs", savePrefs)
rawset(_G, "DOOM_LoadPrefs", loadPrefs)