local function cheat(seq, cmd, validation, minLen, maxLen)
    return {
        sequence = seq:lower(),
        pattern = true, -- Mark as pattern-based cheat
        command = cmd,
        validator = validation,
        minLength = minLen or #seq,
        maxLength = maxLen or #seq,
        progress = 0,
        buffer = ""
    }
end

local function fixedCheat(seq, cmd)
    return {
        sequence = seq:lower(),
        pattern = false,
        command = cmd,
        progress = 0
    }
end

local function doom1DigitsToEpisodeMap(num)
    -- expects exactly 2 digits: Ep + Map
    local ep = num / 10
    local mp = num % 10
    if ep < 1 or ep > 4 then return nil end
    if mp < 1 or mp > 9 then return nil end
    return ep, mp
end

local function doom1EpisodeMapToIndex(ep, mp)
    return (ep - 1) * 9 + mp
end

local function doom1IndexToMapName(ep, mp)
    return string.format("e%dm%d", ep, mp)
end

-- Music cheat handler
local function handleWarpCheat(buffer, player)
    local num = tonumber(buffer)
    if not num then return false end

    if doom.isdoom1 then
        local ep, mp = doom1DigitsToEpisodeMap(num)
        if not ep then return false end
        COM_BufInsertText(player, string.format("map e%dm%d", ep, mp))
        return true
    else
        if num < 1 or num > 32 then return false end
        COM_BufInsertText(player, string.format("map map%02d", num))
        return true
    end
end

-- Music cheat handler
local function handleMusicCheat(buffer, player)
    local num = tonumber(buffer)
    if not num then return false end

    if doom.isdoom1 then
        local ep, mp = doom1DigitsToEpisodeMap(num)
        if not ep then return false end

        local index = doom1EpisodeMapToIndex(ep, mp)
        local mh = mapheaderinfo[index]
        if not mh or not mh.musname then return false end

        -- SRB2 tunes ONLY accepts musname, not numbers
        COM_BufInsertText(player, string.format("tunes %s", mh.musname))
        return true
    else
        -- Doom 2: convert NN -> MAPNN, grab its musname instead of numeric tunes
        if num < 1 or num > 32 then return false end

        local mh = mapheaderinfo[num]
        if not mh or not mh.musname then return false end

        COM_BufInsertText(player, string.format("tunes %s", mh.musname))
        return true
    end
end

-- Power-up cheat handler
local function handlePowerupCheat(buffer, player)
    local powerups = {
        v = "idbehold v",
        a = "idbehold a",
        s = "idbehold s",
        i = "idbehold i",
        r = "idbehold r",
        l = "idbehold l"
    }
    
    local cmd = powerups[buffer:lower()]
    if cmd then
        COM_BufInsertText(player, cmd)
        return true
    end
    return false
end

local cheats = {
    -- Fixed cheats
    fixedCheat("idkfa", "idkfa"),
    fixedCheat("idfa", "idfa"),
    fixedCheat("idclip", "idclip"),
    fixedCheat("iddqd", "iddqd"),
    
	cheat("idclev",
		function(buf, player)
			COM_BufInsertText(player, "idclev " .. buf)
			return true
		end,
		function(buf)
			local n = tonumber(buf)
			return n and #buf <= 2
		end,
		8, 8),

	cheat("idmus",
		function(buf, player)
			COM_BufInsertText(player, "idmus " .. buf)
			return true
		end,
		function(buf)
			local n = tonumber(buf)
			return n and #buf <= 2
		end,
		7, 7),
    
    cheat("idbehold", handlePowerupCheat,
        function(buf)
            return #buf == 1 and buf:match("[irvsal]")
        end, 9, 9), -- "idbehold" + 1 letter
}

addHook("KeyDown", function(keyevent)
    if not (consoleplayer and consoleplayer.valid) then return end
    if gamestate ~= GS_LEVEL or keyevent.repeated or keyevent.name == "TILDE" then
        return
    end

    local keyname = keyevent.name:lower()
    
    for _, cheat in ipairs(cheats) do
        if not cheat.pattern then
            -- Original fixed cheat logic
            if keyname == cheat.sequence:sub(cheat.progress + 1, cheat.progress + 1) then
                cheat.progress = cheat.progress + 1
            else
                cheat.progress = 0
            end

            if cheat.progress >= #cheat.sequence then
                COM_BufInsertText(consoleplayer, cheat.command)
                cheat.progress = 0
            end
        else
            -- Pattern-based cheat logic
            local seqLen = #cheat.sequence
            
            if cheat.progress < seqLen then
                -- Still matching the base sequence
                if keyname == cheat.sequence:sub(cheat.progress + 1, cheat.progress + 1) then
                    cheat.progress = cheat.progress + 1
                    cheat.buffer = cheat.buffer .. keyname
                else
                    cheat.progress = 0
                    cheat.buffer = ""
                end
            else
                -- Base sequence matched, now collecting variable part
                if #cheat.buffer < cheat.maxLength then
                    cheat.buffer = cheat.buffer .. keyname
                    
                    -- Validate as we type
                    if cheat.validator and not cheat.validator(cheat.buffer:sub(seqLen + 1)) then
                        -- Invalid character for this cheat
                        cheat.progress = 0
                        cheat.buffer = ""
                    end
                end
            end
            
            -- Check if we have a complete, valid cheat
            if cheat.progress >= seqLen and #cheat.buffer >= cheat.minLength and #cheat.buffer <= cheat.maxLength then
                local variablePart = cheat.buffer:sub(seqLen + 1)
                if not cheat.validator or cheat.validator(variablePart) then
                    if type(cheat.command) == "function" then
                        if cheat.command(variablePart, consoleplayer) then
                            cheat.progress = 0
                            cheat.buffer = ""
                        end
                    else
                        COM_BufInsertText(consoleplayer, cheat.command .. variablePart)
                        cheat.progress = 0
                        cheat.buffer = ""
                    end
                end
            end
            
            -- Reset if buffer gets too long
            if #cheat.buffer > cheat.maxLength then
                cheat.progress = 0
                cheat.buffer = ""
            end
        end
    end
end)

-- Add a hook to reset cheats when level changes
addHook("MapChange", function()
    for _, cheat in ipairs(cheats) do
        cheat.progress = 0
        if cheat.buffer then
            cheat.buffer = ""
        end
    end
end)