local hudtime = 0

local menustatus = {menu = "title", selection = 0}
local LINEHEIGHT = 16
local SKULLXOFF = -32

-- TODO: Make KeyDown learn what this is meant to mean
local menus = {
	menu = {
		entries = {
			{label = "newgame", patch = "M_NGAME", x = 97, y = 64, goto = "newgame"},
			-- no options! can't do that at all here
			{label = "loadgame", patch = "M_LOADG", x = 97, y = 64+LINEHEIGHT},
			{label = "savegame", patch = "M_SAVEG", x = 97, y = 64+LINEHEIGHT*2},
			{label = "readme", patch = "M_RDTHIS", x = 97, y = 64+LINEHEIGHT*3},
			{label = "quitgame", patch = "M_QUITG", x = 97, y = 64+LINEHEIGHT*4, command = "doom_endoom"}
		},
		customFunc = function(v, player)
			v.draw(94, 2, v.cachePatch("M_DOOM"))
		end,
	},
	newgame = {
		iscommandbased = true,
		default = 3,
		entries = {
			{label = "itytd", patch = "M_JKILL", x = 48, y = 63, command = {"skin johndoom", "doom_skill 1", "map map01 -f"}},
			{label = "hntr", patch = "M_ROUGH", x = 48, y = 63+LINEHEIGHT, command = {"skin johndoom", "doom_skill 2", "map map01 -f"}},
			{label = "hmp", patch = "M_HURT", x = 48, y = 63+LINEHEIGHT*2, command = {"skin johndoom", "doom_skill 3", "map map01 -f"}},
			{label = "uv", patch = "M_ULTRA", x = 48, y = 63+LINEHEIGHT*3, command = {"skin johndoom", "doom_skill 4", "map map01 -f"}},
			{label = "nightmare", patch = "M_NMARE", x = 48, y = 63+LINEHEIGHT*4, command = {"skin johndoom", "doom_skill 5", "map map01 -f"}},
		},
		customFunc = function(v, player)
			v.draw(96, 14, v.cachePatch("M_NEWG"))
			v.draw(54, 38, v.cachePatch("M_SKILL"))
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
		key_y = {command = "quit"},
		key_n = {goto = "title"}
	},
}

hud.add(function(v, player)
	hudtime = $ + 1
	if doom.isdoom1 then
		S_ChangeMusic("intro", false)
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
	local currentMenuKey = menustatus.menu
    local menuDef = menus[currentMenuKey]
    if not menuDef then return false end
	for k, entry in pairs(menuDef.entries) do
		if not entry.patch then continue end
		v.draw(entry.x or 0, entry.y or 0, v.cachePatch(entry.patch))

		if not menuDef.nocursor then 
			if k != menustatus.selection + 1 then continue end
			local skullframe = (hudtime % 30) > 15 and "M_SKULL2" or "M_SKULL1"
			v.draw((entry.x or 0) + SKULLXOFF, entry.y or 0, v.cachePatch(skullframe))
		end
	end
	if menuDef.customFunc then
		menuDef.customFunc(v, player)
	end
end, "title")

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

local function OnKeyDown(keyevent)
    -- Only handle input on the title screen and ignore repeats or tilde
    if gamestate ~= GS_TITLESCREEN or keyevent.repeated or keyevent.name == "TILDE" then
        return false
    end

    -- Special case: from "title" move to main menu on any key
    if menustatus.menu == "title" then
        menustatus.menu = "menu"
        menustatus.selection = 0
        return true
    end

    local currentMenuKey = menustatus.menu
    local menuDef = menus[currentMenuKey]
    if not menuDef then return false end

    local entryCount = #menuDef.entries

    -- Navigation logic if cursor is shown
    if not menuDef.nocursor then
        if isGameControl(keyevent, GC_SPIN) or keyevent.name == "escape" then
            -- Go back to title
            menustatus.menu = "title"
            menustatus.selection = 0
            S_StartSound(nil, sfx_swtchx)
            return true
        elseif keyevent.name == "up arrow" then
            menustatus.selection = (menustatus.selection - 1) % entryCount
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
    local selectedEntry = menuDef.entries[idx]

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

    -- Confirm/execute
    if isGameControl(keyevent, GC_JUMP) or keyevent.name == "enter" then
        if selectedEntry.command then
            local cmds = type(selectedEntry.command) == "table" and selectedEntry.command or {selectedEntry.command}
            for _, cmd in ipairs(cmds) do
                table.insert(commandBuffer, cmd)
            end
        end
        if selectedEntry.goto then
            menustatus.menu = selectedEntry.goto
            menustatus.selection = (menus[selectedEntry.goto].default or 1) - 1
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
        return true
    end

    return false
end

-- Register the hooks.
addHook("KeyDown", OnKeyDown)