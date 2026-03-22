 local hudtime = 0

local menustatus = {menu = "title", selection = 0}
local LINEHEIGHT = 16
local SKULLXOFF = -32

addHook("MapLoad", function(mapid)
	-- refresh this
	menustatus = {menu = "title", selection = 0}
end)

local function IsTitleMode()
	return (gamestate == GS_TITLESCREEN)
		or ((not multiplayer) and doom.midGameTitlescreen)
end

doom.titlemenus = {
	menu = {
		entries = {
			{label = "newgame", patch = "M_NGAME", x = 97, y = 64, goto = "cssselect"},
			-- no options! can't do that at all here
			{label = "loadgame", patch = "M_LOADG", x = 97, y = 64},
			{label = "savegame", patch = "M_SAVEG", x = 97, y = 64},
			{label = "readme", patch = "M_RDTHIS", x = 97, y = 64},
			{label = "quitgame", patch = "M_QUITG", x = 97, y = 64, goto = "quitgame"}
		},
		customFunc = function(v, player)
			v.draw(94, 2, v.cachePatch("M_DOOM"))
		end,
	},
	cssselect = {
		default = 1,
		lineheight = 20,
		x = 40,
		y = 50,

		entries = function()
			return doom.buildCSSMenu()
		end,

		customFunc = function(v)
			drawInFont(v, 160*FRACUNIT, 20*FRACUNIT, FRACUNIT, "STCFN", "SELECT CHARACTER", 0, "center")
		end
	},
	newgame = {
		iscommandbased = true,
		default = 3,
		entries = {
			{label = "itytd", patch = "M_JKILL", x = 48, y = 63, command = {"doom_skill 1", "map map01 -f"}},
			{label = "hntr", patch = "M_ROUGH", x = 48, y = 63, command = {"doom_skill 2", "map map01 -f"}},
			{label = "hmp", patch = "M_HURT", x = 48, y = 63, command = {"doom_skill 3", "map map01 -f"}},
			{label = "uv", patch = "M_ULTRA", x = 48, y = 63, command = {"doom_skill 4", "map map01 -f"}},
			{label = "nightmare", patch = "M_NMARE", x = 48, y = 63, command = {"doom_skill 5", "map map01 -f"}},
		},
		customFunc = function(v, player)
			v.draw(96, 14, v.cachePatch("M_NEWG"))
			v.draw(54, 38, v.cachePatch("M_SKILL"))
		end,
	},
	episelect = {
		iscommandbased = true,
		default = 1,
		-- Episode selection for Doom 1
		entries = {
			{label = "episode1", patch = "M_EPI1", x = 48, y = 63,	goto = "newgame", episode = 1},
			{label = "episode2", patch = "M_EPI2", x = 48, y = 63,	goto = "newgame", episode = 2},
			{label = "episode3", patch = "M_EPI3", x = 48, y = 63,	goto = "newgame", episode = 3},
			{label = "episode4", patch = "M_EPI4", x = 48, y = 63,	goto = "newgame", episode = 4},
		},
		customFunc = function(v, player)
			v.draw(54, 38, v.cachePatch("M_EPISOD"))
		end,
	},
	loadgame = {
		entries = {
			{label = "save1", command = "doom_loadsave 1"},
			{label = "save2", command = "doom_loadsave 2"},
			{label = "save3", command = "doom_loadsave 3"},
			{label = "save4", command = "doom_loadsave 4"},
			{label = "save5", command = "doom_loadsave 5"},
			{label = "save6", command = "doom_loadsave 6"},
		},
	},
	savegame = {
		validkeys = "any",
		nocursor = true,
		key_any = {goto = "title"}
	},
	quitgame = {
		validkeys = {"y", "n"},
		nocursor = true,
		key_y = {command = "doom_endoom"},
		key_n = {goto = "title"},
		--key_any = {goto = "title"},
		customFunc = function(v, player)
			local toDraw = DOOM_ResolveString(menustatus.special and menustatus.special.quitgamestring or "$QUITMSG").."\n\n(press y to quit)"
			local _, offset = toDraw:gsub("\n", "")
			offset = ($ + 1) * 4
			drawInFont(v, 160 * FRACUNIT, (100 - offset) * FRACUNIT, FRACUNIT, "STCFN", toDraw, 0, "center")
		end,
		onEnter = function()
			menustatus.special = $ or {}
			menustatus.special.quitgamestring = doom.quitStrings[P_RandomRange(1, #doom.quitStrings)]
		end
	},
	-- This is the shareware version of DOOM.
	-- You need to order the entire trilogy.
	sharewaredeny = {
		validkeys = "any",
		nocursor = true,
		key_any = {goto = "episelect"},
		customFunc = function(v, player)
			-- Y starts at 100, but gets offset by
			-- Half of the actual drawn length
			-- To make it centered
			local toDraw = DOOM_ResolveString("$SWSTRING")
			local _, offset = toDraw:gsub("\n", "")
			offset = ($ + 1) * 4
			drawInFont(v, 160 * FRACUNIT, (100 - offset) * FRACUNIT, FRACUNIT, "STCFN", toDraw, 0, "center")
		end,
	},
}

local function resolveEntries(menuDef)
	local entries = menuDef.entries

	-- Allow dynamic builders (like CSS)
	if type(entries) == "function" then
		entries = entries()
	end

	-- Normalize old entries into new format
	for _, entry in ipairs(entries or {}) do
		if not entry.drawtype then
			if entry.patch then
				entry.drawtype = "patch"
			else
				entry.drawtype = "text"
				entry.text = entry.text or entry.label
			end
		end
	end

	return entries or {}
end

local selectedEpisode = 1

---@param v videolib
local function drawMenuEntry(v, entry, x, y)
	if entry.drawtype == "patch" then
		v.draw(x, y, v.cachePatch(entry.patch))

	elseif entry.drawtype == "text" then
		drawInFont(v,
			(x + 160) * FRACUNIT,
			y * FRACUNIT,
			FRACUNIT,
			"STCFN",
			DOOM_ResolveString(entry.text),
			0,
			"center"
		)

	elseif entry.drawtype == "css" then
		local seq = entry.sequence
		local base = seq[1]
		local count = seq[2] or 1
		local tics = seq[3] or 4

		local frame = ((hudtime / tics) % count)
		local vf = 0
		local sprite2 = entry.nonselectedsprite2 or SPR2_STND
		frame = frame + base

		-- Adjust frame based on highlight state
		if entry.highlight == "current" then
			frame = frame -- could keep normal animation
			y = 112
			sprite2 = entry.sprite2
		elseif entry.highlight == "up" then
			frame = entry.nonselectedframe
			y = 50
			vf = V_SNAPTOTOP
		elseif entry.highlight == "down" then
			frame = entry.nonselectedframe
			y = 175
			vf = V_SNAPTOBOTTOM
		else
			return
		end

		local patch = v.getSprite2Patch(entry.skin, sprite2, frame)

		if patch then
			v.drawScaled(
				(x + 32) * FRACUNIT,
				(y + 8) * FRACUNIT,
				skins[entry.skin].highresscale,
				patch,
				vf,
				v.getColormap(entry.skin, skins[entry.skin].prefcolor)
			)
		end

		if entry.highlight == "current" then
			drawInFont(v,
				(x + 72) * FRACUNIT,
				(y - 48) * FRACUNIT,
				FRACUNIT,
				"STCFN",
				entry.name,
				vf,
				"left"
			)

			-- Normalize description to a table
			local lines = {}
			if type(entry.description) == "string" then
				for line in entry.description:gmatch("[^\n]+") do
					table.insert(lines, line)
				end
			elseif type(entry.description) == "table" then
				lines = entry.description
			end

			-- Draw up to 6 lines
			for i = 1, min(6, #lines) do
				drawInFont(v,
					(x + 72) * FRACUNIT,
					(y - 40 + (i * 8)) * FRACUNIT,
					FRACUNIT,
					"STCFN",
					lines[i],
					vf,
					"left"
				)
			end
		end
	end
end

local function DrawTitleScreen(v, player)
	hudtime = hudtime + 1

	local currentMenuKey = menustatus.menu
	local menuDef = doom.titlemenus[currentMenuKey]
	if not menuDef then return end

	if menuDef.customFunc then
		menuDef.customFunc(v, player)
	end

	if menuDef.entries then
		local entries = resolveEntries(menuDef)
		local entryCount = #entries

		-- Compute the three indices for CSS menus
		local selIndex = menustatus.selection + 1
		local upIndex = ((menustatus.selection - 1 + entryCount) % entryCount) + 1
		local downIndex = ((menustatus.selection + 1) % entryCount) + 1

		for k, entry in ipairs(entries) do
			local baseX = entry.x or menuDef.x or 48
			local baseY = entry.y or menuDef.y or 64
			local y = baseY + (k-1)*(menuDef.lineheight or LINEHEIGHT)

			-- Determine highlight state for CSS entries
			if entry.drawtype == "css" then
				if k == selIndex then
					entry.highlight = "current"
				elseif k == upIndex then
					entry.highlight = "up"
				elseif k == downIndex then
					entry.highlight = "down"
				else
					entry.highlight = nil
				end
			end

			drawMenuEntry(v, entry, baseX, y)

			-- Draw skull cursor for normal menus
			if not menuDef.nocursor and k == selIndex then
				local skullframe = (hudtime % 30) > 15 and "M_SKULL2" or "M_SKULL1"
				v.draw(baseX + SKULLXOFF, y, v.cachePatch(skullframe))
			end
		end
	end
end

hud.add(function(v, player)
	if IsTitleMode() then
		if doom.isdoom1 then
			S_ChangeMusic("introa", false)
		else
			S_ChangeMusic("dm2ttl", false)
		end

		v.drawFill()

		local titlePatch
		if hudtime <= 10*TICRATE then
			titlePatch = v.cachePatch("TITLEPIC")
		else
			titlePatch = v.cachePatch("CREDIT")
		end
		v.draw(0, 0, titlePatch)

		DrawTitleScreen(v, player)
	end
end, "title")

hud.add(function(v, player)
	if IsTitleMode() then
		DrawTitleScreen(v, player)
	end
end, "game")

local function isGameControl(keyevent, gamecontrol)
	if input.keyNumToName(input.gameControlToKeyNum(gamecontrol)) == keyevent.name then
		return true
	end
	return false
end

local commandBuffer = {}

addHook("ThinkFrame", function()
    if #commandBuffer > 0 then
        for _, cmd in ipairs(commandBuffer) do
            COM_BufInsertText(consoleplayer, cmd)
        end
        commandBuffer = {}
    end
end)

local function resolveNewGameTarget()
	-- Decide destination once
	local targetMenu = "newgame"

	if doom.isdoom1 and doom.matchedGame != "chex1" then
		targetMenu = "episelect"
	end

	return targetMenu
end

local function OnKeyDown(keyevent)
    -- Only handle input on the title screen and ignore repeats or tilde
    if not IsTitleMode() or keyevent.repeated or keyevent.name == "TILDE" then
        return false
    end

    -- Special case: from "title" move to main menu on any key
    if menustatus.menu == "title" then
        menustatus.menu = "menu"
        menustatus.selection = 0
		S_StartSound(nil, sfx_swtchn)
        return true
    end

    local currentMenuKey = menustatus.menu
    local menuDef = doom.titlemenus[currentMenuKey]
    if not menuDef then return false end

	local entries = resolveEntries(menuDef)
	local entryCount = #entries

    -- Navigation logic if cursor is shown
    if not menuDef.nocursor then
        if isGameControl(keyevent, GC_SPIN) or keyevent.name == "escape" then
            -- Go back to title
            menustatus.menu = "title"
            menustatus.selection = 0
            S_StartSound(nil, sfx_swtchx)
            return true
        elseif keyevent.name == "up arrow" then
            menustatus.selection = (menustatus.selection - 1 + entryCount) % entryCount
            S_StartSound(nil, sfx_pstop)
            return true
        elseif keyevent.name == "down arrow" then
            menustatus.selection = (menustatus.selection + 1) % entryCount
            S_StartSound(nil, sfx_pstop)
            return true
        end
    end

    -- Determine selected entry (first if nocursor)
    local idx = menuDef.nocursor and 1 or (menustatus.selection + 1)
    local selectedEntry = entries[idx]

    -- If custom validkeys, only allow those
    if menuDef.validkeys then
        local allowed = menuDef.validkeys == "any"
        if not allowed and type(menuDef.validkeys) == "table" then
            for _, key in ipairs(menuDef.validkeys) do
                if keyevent.name:lower() == key:lower() then allowed = true break end
            end
        end
        if not allowed then return false end
    end

    -- Number-driven selection for command-based menus
    if menuDef.iscommandbased and tonumber(keyevent.name) then
        local num = tonumber(keyevent.name)
        menustatus.selection = (num - 1) % entryCount
    end

    -- Handle episode selection - store the selected episode
    if currentMenuKey == "episelect" and selectedEntry.episode then
        selectedEpisode = selectedEntry.episode
    end

    -- Confirm/execute
    if not menuDef.nocursor and (isGameControl(keyevent, GC_JUMP) or keyevent.name == "enter") then
        -- For episode selection, we need to update the newgame commands with the proper map
        if currentMenuKey == "episelect" and selectedEntry.episode then
            -- Calculate the starting map for the selected episode (maps are 9 apart)
            local startMapNum = (selectedEpisode - 1) * 9 + 1
            local startMap = "map" .. (startMapNum < 10 and "0" .. startMapNum or startMapNum)
            
            -- Update all newgame entries to use the correct episode map
			local newgameEntries = resolveEntries(doom.titlemenus.newgame)
			for i, skillEntry in ipairs(newgameEntries) do
                skillEntry.command = {
                    "doom_skill " .. i,
                    "map " .. startMap .. " -f"
                }
            end
        end
        
        if selectedEntry and selectedEntry.command then
            local cmds = type(selectedEntry.command) == "table" and selectedEntry.command or {selectedEntry.command}
            for _, cmd in ipairs(cmds) do
                table.insert(commandBuffer, cmd)
            end
        end
        if selectedEntry and selectedEntry.goto then
			local target = selectedEntry.goto
		
			if target == "__newgame_router" then
				target = resolveNewGameTarget()
			end
	
            menustatus.menu = target
            menustatus.selection = (doom.titlemenus[menustatus.menu].default or 1) - 1
			local nextMenu = doom.titlemenus[menustatus.menu]
			if nextMenu and nextMenu.onEnter then
				nextMenu.onEnter()
			end
        end
        S_StartSound(nil, sfx_pistol)
        return true
    end

	-- Handle specific key responses (like key_y, key_n in quitgame)
	local keyHandler = menuDef["key_" .. keyevent.name:lower()]
	if keyHandler then
		if keyHandler.command then
			table.insert(commandBuffer, keyHandler.command)
		end
		if keyHandler.goto then
			menustatus.menu = keyHandler.goto
			menustatus.selection = (doom.titlemenus[keyHandler.goto].default or 1) - 1
		end
		-- Call onEnter for the current menu when a valid key is pressed
		if menuDef.onEnter then
			menuDef.onEnter()
		end
		S_StartSound(nil, sfx_pistol)
		return true
	end

	-- Handle any-key menus (nocursor)
	if menuDef.nocursor and menuDef.key_any then
		if menuDef.key_any.command then
			table.insert(commandBuffer, menuDef.key_any.command)
		end
		menustatus.menu = menuDef.key_any.goto or menustatus.menu
		if menuDef.onEnter then
			menuDef.onEnter()
		end
		return true
	end

    return false
end

-- Register the hooks.
addHook("KeyDown", OnKeyDown)