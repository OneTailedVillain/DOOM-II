 local hudtime = 0

local menustatus = {menu = "title", selection = 0}
local LINEHEIGHT = 16
local SKULLXOFF = -32
local showTitleMenu = false
local pendingSkinChange = nil

addHook("MapChange", function(mapid)
	-- refresh this
	menustatus = {menu = "title", selection = 0}
	showTitleMenu = false
	if multiplayer then return end
	-- Apply pending skin change after map load
	if pendingSkinChange then
		local player = consoleplayer
		local funcs = P_GetMethodsForSkin(player)
		if funcs.throwOutSaveState then
			funcs.throwOutSaveState(player)
		else
			player.doom.laststate = {}
		end
		R_SetPlayerSkin(consoleplayer, pendingSkinChange)
		pendingSkinChange = nil
		local funcs = P_GetMethodsForSkin(player)
		if funcs.throwOutSaveState then
			funcs.throwOutSaveState(player)
		else
			player.doom.laststate = {}
		end
	end
	F_StopCast()
	doom.curcutscene = ""
end)

local function IsTitleMode(checkInMenu)
	if checkInMenu then
		-- Check if we're in a menu along with "are we able to titlescreen"
		local titlescreenable = (gamestate == GS_TITLESCREEN)
			or ((not multiplayer) and doom.midGameTitlescreen)
			or showTitleMenu
		return titlescreenable and menustatus.menu ~= "title"
	end
	return (gamestate == GS_TITLESCREEN)
		or ((not multiplayer) and doom.midGameTitlescreen)
		or showTitleMenu
end

doom.IsTitleMode = IsTitleMode

/*
//
//      Menu Functions
//
void
M_DrawThermo
( int	x,
  int	y,
  int	thermWidth,
  int	thermDot )
{
    int		xx;
    int		i;

    xx = x;
    V_DrawPatchDirect (xx,y,0,W_CacheLumpName("M_THERML",PU_CACHE));
    xx += 8;
    for (i=0;i<thermWidth;i++)
    {
	V_DrawPatchDirect (xx,y,0,W_CacheLumpName("M_THERMM",PU_CACHE));
	xx += 8;
    }
    V_DrawPatchDirect (xx,y,0,W_CacheLumpName("M_THERMR",PU_CACHE));

    V_DrawPatchDirect ((x+8) + thermDot*8,y,
		       0,W_CacheLumpName("M_THERMO",PU_CACHE));
}
*/

doom.prefs = doom.prefs or {}

---@param v videolib
local function M_DrawThermo(v, x, y, thermWidth, thermDot)
	local xx
	local i
	xx = x
	v.draw(xx, y, v.cachePatch("M_THERML"))
	xx = xx + 8
	for i = 1, thermWidth do
		v.draw(xx, y, v.cachePatch("M_THERMM"))
		xx = xx + 8
	end
	v.draw(xx, y, v.cachePatch("M_THERMR"))
	v.draw((x + 8) + thermDot * 8, y, v.cachePatch("M_THERMO"))
end

local function isConfigRange(def)
	return def and def.possiblevalues and def.possiblevalues.MIN ~= nil and def.possiblevalues.MAX ~= nil
end

local function getConfigResolved(player, key)
	local def = doom.configents and doom.configents[key]
	if not def then return nil end

	if DOOM_GetConfigResolveValue then
		local v = DOOM_GetConfigResolveValue(player, key)
		if v ~= nil then return v end
	end

	if player and player.doom and player.doom.prefs and player.doom.prefs[key] ~= nil then
		return player.doom.prefs[key]
	end

	if doom.prefs and doom.prefs[key] != nil then
		return doom.prefs[key]
	end

	return def.default
end

local function choiceList(def)
	local out = {}
	local seen = {}

	local function push(resolve)
		if resolve ~= nil and not seen[resolve] and def.possiblevalues[resolve] ~= nil then
			seen[resolve] = true
			out[#out+1] = resolve
		end
	end

	-- Put the default first so menus feel sensible
	push(def.default)

	local tmp = {}
	if def.possiblevalues == doom.CV_OnOff then
		tmp = {{resolve = "Yes", store = 1}, {resolve = "No", store = 0}}
	else
		for resolve, store in pairs(def.possiblevalues) do
			if type(resolve) == "string" then
				tmp[#tmp+1] = {resolve = resolve, store = store}
			end
		end
	end

	table.sort(tmp, function(a, b)
		if type(a.store) == type(b.store) and a.store ~= b.store then
			return a.store < b.store
		end
		return tostring(a.resolve) < tostring(b.resolve)
	end)

	for _, item in ipairs(tmp) do
		push(item.resolve)
	end

	return out
end

local function getPrefsTable()
	doom.prefs = doom.prefs or {}
	return doom.prefs
end

local function getConfigValue(key)
	local prefs = getPrefsTable()
	local def = doom.configents[key]
	if not def then return nil end

	local v = prefs[key]
	if v == nil then
		return def.default
	end
	return v
end

local function setConfigValue(key, value)
	local prefs = getPrefsTable()
	prefs[key] = value
	if DOOM_SavePrefs then
		DOOM_SavePrefs() -- make this save doom.prefs, not player.doom.prefs
	end
end

local function applyConfigChange(key, resolve)
	local def = doom.configents[key]
	if not def then return end

	setConfigValue(key, resolve)

	-- Only push live commands when actually in a level
	if gamestate == GS_LEVEL then
		if def.commandname then
			COM_BufInsertText(consoleplayer, def.commandname .. " " .. tostring(resolve))
		else
			COM_BufInsertText(consoleplayer, "doomcfg " .. key .. " " .. tostring(resolve))
		end
	end
end

local function makeConfigEntry(key)
	local def = doom.configents[key]
	if not def then return nil end

	local entry = {
		label = key,
		configkey = key,
		fallbackname = def.helpdescription or key,
		helpdescription = def.helpdescription,
		drawtype = "config",
	}

	if isConfigRange(def) then
		local cur = tonumber(getConfigResolved(consoleplayer, key))
		if not cur then cur = tonumber(def.default) or def.possiblevalues.MIN end

		entry.sliderprops = {
			x = 48,
			y = 64,
			min = def.possiblevalues.MIN,
			max = def.possiblevalues.MAX,
			value = cur,
			width = 10,
		}
	end

	return entry
end

local function makeConfigMenu(keys, titlePatch, lineheight, nextMenu, prevMenu)
	local rowheight = lineheight or 12

	return {
		lineheight = rowheight,
		entries = function()
			local entries = {}
			local y = 32

			for _, key in ipairs(keys) do
				local e = makeConfigEntry(key)
				if e then
					e.x = 48
					e.y = y
					e.rowheight = e.sliderprops and (rowheight * 2) or rowheight
					entries[#entries+1] = e
					if e.sliderprops then
						y = y + rowheight
					end
				end
			end

			if prevMenu then
				entries[#entries+1] = { label = "back", drawtype = "text", text = "Back", goto = prevMenu, x = 48, y = y }
			end
			if nextMenu then
				entries[#entries+1] = { label = "next", drawtype = "text", text = "Next Page", goto = nextMenu, x = 48, y = y }
			end

			return entries
		end,
		customFunc = function(v)
			if titlePatch then
				v.draw(108, 15, v.cachePatch(titlePatch))
			end
		end
	}
end

doom.titlemenus = {
	menu = {
		entries = {
			{label = "newgame", patch = "M_NGAME", fallbackname = "New Game", x = 97, y = 64, goto = "cssselect"},
			{label = "options", patch = "M_OPTION", fallbackname = "Options", x = 97, y = 64, goto = "optionmenu"},
			{label = "loadgame", patch = "M_LOADG", fallbackname = "Load Game", x = 97, y = 64},
			{label = "savegame", patch = "M_SAVEG", fallbackname = "Save Game", x = 97, y = 64},
			{label = "readme", patch = "M_RDTHIS", fallbackname = "Read This!", x = 97, y = 64},
			{label = "quitgame", patch = "M_QUITG", fallbackname = "Quit Game", x = 97, y = 64, goto = "quitgame"}
		},
		customFunc = function(v, player)
			v.draw(94, 2, v.cachePatch("M_DOOM"))
		end,
	},
	optionmenu = {
		entries = {
			{label = "sb", patch = "M_STAT", fallbackname = "Status Bar/HUD", x = 97, y = 64},
			{label = "gset", patch = "M_GSET", fallbackname = "Game Settings", x = 97, y = 64},
			{label = "multi", patch = "M_MULTI", fallbackname = "Multiplayer", x = 97, y = 64},
		},
		customFunc = function(v, player)
			v.draw(108, 15, v.cachePatch("M_OPTTTL"))
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
			{label = "itytd", patch = "M_JKILL", fallbackname = "I'm Too Young To Die", x = 48, y = 63, command = {"doom_skill 1", "map map01 -f"}},
			{label = "hntr", patch = "M_ROUGH", fallbackname = "Hurt Me Plenty", x = 48, y = 63, command = {"doom_skill 2", "map map01 -f"}},
			{label = "hmp", patch = "M_HURT", fallbackname = "Hey, Not Too Rough", x = 48, y = 63, command = {"doom_skill 3", "map map01 -f"}},
			{label = "uv", patch = "M_ULTRA", fallbackname = "Ultra-Violence", x = 48, y = 63, command = {"doom_skill 4", "map map01 -f"}},
			{label = "nightmare", patch = "M_NMARE", fallbackname = "Nightmare!", x = 48, y = 63, command = {"doom_skill 5", "map map01 -f"}},
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
			{label = "episode1", patch = "M_EPI1", fallbackname = "Episode 1", x = 48, y = 63,	goto = "newgame", episode = 1},
			{label = "episode2", patch = "M_EPI2", fallbackname = "Episode 2", x = 48, y = 63,	goto = "newgame", episode = 2},
			{label = "episode3", patch = "M_EPI3", fallbackname = "Episode 3", x = 48, y = 63,	goto = "newgame", episode = 3},
			{label = "episode4", patch = "M_EPI4", fallbackname = "Episode 4", x = 48, y = 63,	goto = "newgame", episode = 4},
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
			elseif entry.sliderprops then
				entry.drawtype = "slider"
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
		if v.patchExists(entry.patch) then
		v.draw(x, y, v.cachePatch(entry.patch))
		else
			drawInFont(v,
				x * FRACUNIT,
				(y + 4) * FRACUNIT,
				FRACUNIT*3/2,
				"STCFN",
				DOOM_ResolveString(entry.fallbackname or entry.label or "MISSING"),
				0,
				"left"
			)
		end

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

    elseif entry.drawtype == "config" then
        local label = DOOM_ResolveString(entry.fallbackname or entry.label or entry.configkey)
        local cur = getConfigResolved(consoleplayer, entry.configkey)

        if entry.sliderprops then
            local props = entry.sliderprops
            local rowheight = entry.rowheight or 24
            local sliderY = y + (rowheight / 2)

            drawInFont(v, 160 * FRACUNIT, y * FRACUNIT, FRACUNIT,
                "STCFN", label, 0, "center")

            local width = props.width or 10
            local range = props.max - props.min
            local dot = 0
            if range > 0 then
                dot = ((tonumber(cur) or props.value or props.min) - props.min) * width / range
            end

            M_DrawThermo(v, props.x or x, sliderY, width, dot)
        else
            drawInFont(v, 160 * FRACUNIT, y * FRACUNIT, FRACUNIT,
                "STCFN", label .. ": " .. tostring(cur), 0, "center")
        end
		return {y = y, skullpatch = "M_CURSOR"}

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
			frame = frame
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
				(x + 60) * FRACUNIT,
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
					(x + 60) * FRACUNIT,
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

local lastleveltime

---@param v videolib
local function DrawTitleScreen(v, player)
	if lastleveltime != leveltime then
		hudtime = hudtime + 1
		lastleveltime = leveltime
	end

	local currentMenuKey = menustatus.menu
	local menuDef = doom.titlemenus[currentMenuKey]
	if not menuDef then return end

	v.fadeScreen(0xFF00, 16)

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

            local override = drawMenuEntry(v, entry, baseX, y)

            -- Draw skull cursor
            if not menuDef.nocursor and k == selIndex then
                local skullframe = (hudtime % 30) > 15 and "M_SKULL2" or "M_SKULL1"
                local skullX = override and override.x or (baseX + SKULLXOFF)
                local skullY = override and override.y or y
                local skullPatch = override and override.skullpatch or skullframe
                v.draw(skullX, skullY, v.cachePatch(skullPatch))
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
		local width = titlePatch.width
		width = $ - 320
		width = $ / 2
		v.draw(-width, 0, titlePatch)

		DrawTitleScreen(v, consoleplayer)
	end
end, "title")

doom.DrawTitleScreen = DrawTitleScreen

hud.add(function(v, player)
	DrawTitleScreen(v, player)
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
			-- If command starts with "skin" and we're in-game,
			-- Delay until after map change
			if cmd:lower():sub(1,4) == "skin" and gamestate == GS_LEVEL then
				pendingSkinChange = cmd:sub(6)
				continue
			end
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

-- History for when the player uses backspace
local menuHistory = {}

local function executeCommands(cmds)
    if type(cmds) == "string" then cmds = {cmds} end
    for _, cmd in ipairs(cmds) do
        table.insert(commandBuffer, cmd)
    end
end

local function changeMenu(target, sound, addToHistory)
    if addToHistory then
        table.insert(menuHistory, menustatus.menu)
    end
    menustatus.menu = target
	-- Fallback for when the target menu doesn't exist
	local fallbackmenudef = {label = target, drawtype = "text", text = "MISSING MENU: "..target}
	local curDef = doom.titlemenus[target] or fallbackmenudef
    menustatus.selection = (curDef.default or 1) - 1
    if sound then S_StartSound(nil, sound) end
    local nextMenu = curDef
    if nextMenu and nextMenu.onEnter then
        nextMenu.onEnter()
    end
end

local function updateNewGameForEpisode(episode)
    selectedEpisode = episode
    local startMapNum = (episode - 1) * 9 + 1
    local startMap = "map" .. (startMapNum < 10 and "0" .. startMapNum or startMapNum)
    local newgameEntries = resolveEntries(doom.titlemenus.newgame)
    for i, skillEntry in ipairs(newgameEntries) do
        skillEntry.command = {
            "doom_skill " .. i,
            "map " .. startMap .. " -f"
        }
    end
end

local gamestateblocklist = {
	[GS_NULL] = true,
	[GS_INTERMISSION] = true,
	[GS_CONTINUING] = true,
	[GS_TIMEATTACK] = true,
	[GS_CREDITS] = true,
	[GS_EVALUATION] = true,
	[GS_GAMEEND] = true,
	[GS_INTRO] = true,
	[GS_ENDING] = true,
	[GS_CUTSCENE] = true,
	[GS_DEDICATEDSERVER] = true,
	[GS_WAITINGPLAYERS] = true
}

---@param keyevent keyevent_t
local function OnKeyDown(keyevent)
	if gamestateblocklist[gamestate] then return end
    -- Only handle input on the title screen and ignore repeats or tilde
    if keyevent.repeated or isGameControl(keyevent, GC_CONSOLE) then
        return false
    end

	if multiplayer then return end

	-- If in game, override GC_SYSTEMMENU to open the title menu instead of the pause menu
	-- Oddly, the "escape" key is hardcoded to the menu
	-- (Really, we should only do this for non-tilemodes since Episode ending screens toggle mid-game menus)
	if gamestate == GS_LEVEL and not IsTitleMode() then
		if isGameControl(keyevent, GC_SYSTEMMENU) or keyevent.name == "escape" then
			if not showTitleMenu then
				showTitleMenu = true
				changeMenu("menu", sfx_swtchn, false)
			else
				showTitleMenu = false
				changeMenu("title", sfx_swtchx, false)
			end
			return true
		elseif not showTitleMenu then
			return false
		end
	end

    -- Special case: from "title" move to main menu on any key
    if menustatus.menu == "title" then
        changeMenu("menu", sfx_swtchn, false)
        return true
    end

    local currentMenuKey = menustatus.menu
    local menuDef = doom.titlemenus[currentMenuKey]
    if not menuDef then return false end

    local entries = resolveEntries(menuDef)
    local entryCount = #entries

    if keyevent.name == "BACKSPACE" then
        if #menuHistory > 0 then
            local previous = table.remove(menuHistory)
            changeMenu(previous, sfx_swtchx, false)
        else
            changeMenu("title", sfx_swtchx, false)
        end
        return true
    end

    -- Navigation logic if cursor is shown
    if not menuDef.nocursor then
        if isGameControl(keyevent, GC_SPIN) or keyevent.name == "escape" then
            if showTitleMenu and gamestate == GS_LEVEL then
                changeMenu("title", sfx_swtchx, false)
				showTitleMenu = false
                return true
            else
                changeMenu("title", sfx_swtchx, false)
                return true
            end
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

    local selectedEntry = entries[menustatus.selection + 1]

    -- Handle config entry adjustment
    if selectedEntry and selectedEntry.drawtype == "config" then
        local def = doom.configents[selectedEntry.configkey]
        if def then
            local isLeft = keyevent.name == "left arrow"
            local isRight = keyevent.name == "right arrow"
            local isConfirm = isGameControl(keyevent, GC_JUMP) or keyevent.name == "enter"

            if isLeft or isRight or isConfirm then
                if isConfigRange(def) then
                    local cur = tonumber(getConfigResolved(consoleplayer, selectedEntry.configkey))
                    if not cur then cur = tonumber(def.default) or def.possiblevalues.MIN end

                    if isLeft then
                        cur = cur - 1
                    else
                        cur = cur + 1
                    end

                    if cur < def.possiblevalues.MIN then cur = def.possiblevalues.MIN end
                    if cur > def.possiblevalues.MAX then cur = def.possiblevalues.MAX end

                    applyConfigChange(selectedEntry.configkey, cur)
                else
                    local choices = choiceList(def)
                    if #choices > 0 then
                        local cur = tostring(getConfigResolved(consoleplayer, selectedEntry.configkey) or def.default)
                        local idx = 1

                        for i, choice in ipairs(choices) do
                            if tostring(choice) == cur then
                                idx = i
                                break
                            end
                        end

                        if isLeft then
                            idx = ((idx - 2) % #choices) + 1
                        else
                            idx = (idx % #choices) + 1
                        end

                        applyConfigChange(selectedEntry.configkey, choices[idx])
                    end
                end

                S_StartSound(nil, sfx_stnmov)
                return true
            end
        end
    end

    -- Determine selected entry (first if nocursor)
    local idx = menuDef.nocursor and 1 or (menustatus.selection + 1)
    selectedEntry = entries[idx]

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

    -- Handle episode selection
    if currentMenuKey == "episelect" and selectedEntry.episode then
        updateNewGameForEpisode(selectedEntry.episode)
    end

    -- Confirm/execute
    if not menuDef.nocursor and (isGameControl(keyevent, GC_JUMP) or keyevent.name == "enter") then
        if selectedEntry.command then
            executeCommands(selectedEntry.command)
        end
        if selectedEntry.goto then
            local target = selectedEntry.goto
            if target == "__newgame_router" then
                target = resolveNewGameTarget()
            end
            changeMenu(target, sfx_pistol, true)
        end
        return true
    end

    -- Handle specific key responses (like key_y, key_n in quitgame)
    local keyHandler = menuDef["key_" .. keyevent.name:lower()]
    if keyHandler then
        if keyHandler.command then
            executeCommands(keyHandler.command)
        end
        if keyHandler.goto then
            changeMenu(keyHandler.goto, sfx_pistol, true)
        end
        if menuDef.onEnter then
            menuDef.onEnter()
        end
        return true
    end

    -- Handle any-key menus (nocursor)
    if menuDef.nocursor and menuDef.key_any then
        if menuDef.key_any.command then
            executeCommands(menuDef.key_any.command)
        end
        menustatus.menu = menuDef.key_any.goto or menustatus.menu
        if menuDef.key_any.goto then
            table.insert(menuHistory, currentMenuKey)
        end
        if menuDef.onEnter then
            menuDef.onEnter()
        end
        return true
    end

    return false
end

-- Register the hooks.
addHook("KeyDown", OnKeyDown)

doom.titlemenus.optionmenu = {
	entries = {
		{label = "sb", patch = "M_STAT", fallbackname = "Status Bar/HUD", x = 97, y = 64, goto = "hudopts1"},
		{label = "gset", patch = "M_GSET", fallbackname = "Gameplay", x = 97, y = 64, goto = "gameplayopts"},
		{label = "multi", patch = "M_MULTI", fallbackname = "Multiplayer", x = 97, y = 64, goto = "mpopts"},
		{label = "automap", patch = "M_OPTION", fallbackname = "Automap", x = 97, y = 64, goto = "automapopts"},
	},
	customFunc = function(v, player)
		v.draw(108, 15, v.cachePatch("M_OPTTTL"))
	end,
}

doom.titlemenus.gameplayopts = makeConfigMenu({
	"autorun",
	"monster_infiniteheight",
	"alwayspistolstart",
	"verticalaim",
	"fastmonsters",
	"monsterrespawn",
	"autoaimbehavior",
}, "M_GSET", 10, "mpopts", "optionmenu")

doom.titlemenus.mpopts = makeConfigMenu({
	"dm_dropweapon",
	"dm_weaponsstay",
	"dm_respawninvulntime",
	"coop_spawnmultiplayerthings",
	"coop_spawnmultiplayeritems",
	"coop_spawnmultiplayerweapons",
	"coop_sharekeys",
	"coop_shootthroughplayers",
	"timelimit",
	"fraglimit",
}, "M_MULTI", 10, "automapopts", "optionmenu")

doom.titlemenus.automapopts = makeConfigMenu({
	"automaprotation",
	"automapoverlay",
	"automaprotateprefangle",
	"automapshowghostlines",
}, "M_OPTION", 10, "hudopts1", "optionmenu")

doom.titlemenus.hudopts1 = makeConfigMenu({
	"statusbaropacity",
	"hudstyle",
	"hudColorization",
	"hudGrayPercenting",
	"t_ammo_red",
	"t_ammo_yellow",
	"t_health_red",
	"t_health_yellow",
	"t_health_green",
	"t_armor_red",
}, "M_STAT", 10, "hudopts2", "optionmenu")

doom.titlemenus.hudopts2 = makeConfigMenu({
	"t_armor_yellow",
	"t_armor_green",
	"textSize",
	"textRows",
	"textDuration",
	"hudFlashes",
	"autoswitch",
	"weaponbob",
	"centerweapononfire",
	"messagepriority",
	"secretnotify",
	"showobituaries",
	"ouchfacebug",
	"weaponlightupbehavior",
	"nosecrets",
}, "M_STAT", 10, nil, "hudopts1")