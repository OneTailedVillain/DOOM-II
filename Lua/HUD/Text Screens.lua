-- Some cache stuff so that SRB2 doesn't immediately forget what we just cachePatch'ed
local cacheShit = {
	colormaps = {},
	patches = {},
	fonts = {},
	lastwarned = {
		flag = {
			typemismatch = {}
		}
	}
}

local TEXTSPEED = 3
local TEXTWAIT = 250
local function drawInFont(v, x, y, scale, font, str, flags, alignment, cmap, maxChars, lineHeight)
    str = tostring(str)
	if type(flags) != "number" then
		if not cacheShit.lastwarned.flag.typemismatch[tostring(flags)] then
			print("\82WARNING:\80 Flag type mismatch! (number expected, got " .. type(flags))
			cacheShit.lastwarned.flag.typemismatch[tostring(flags)] = true
		end
		flags = 0
	end
    if not ((flags or 0) & V_ALLOWLOWERCASE) then
		str = str:upper()
	end
    flags = flags & ~V_ALLOWLOWERCASE

    -- Grab the relevant info (or build if new)
    local ftable = cacheFont(v, font)

    -- Find maximum character height for line stepping, if line height was not already defined
	if not lineHeight then
		lineHeight = 0
		for _, info in pairs(ftable) do
			if info.patch then
				lineHeight = max(lineHeight, info.patch.height * FRACUNIT)
			end
		end
	else
		lineHeight = $ * scale
	end

    local maxWidth = 320*FRACUNIT

    local lines = {}
    for line in str:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local wrappedLines = {}
    
    -- Function to measure string width
    local function getWidth(str)
        local totalWidth = 0
        for i = 1, #str do
            local info = ftable[str:byte(i)]
            if info then
                totalWidth = totalWidth + FixedMul(info.width * FRACUNIT, scale)
            end
        end
        return totalWidth
    end

    for _, line in ipairs(lines) do
        local words = {}
        for w in line:gmatch("%S+") do 
            table.insert(words, w) 
        end

        local current = ""
        for _, w in ipairs(words) do
            local test = (current == "" and w) or (current .. " " .. w)
            if getWidth(test) <= maxWidth then
                current = test
            else
                table.insert(wrappedLines, current)
                current = w
            end
        end

        if current ~= "" then
            table.insert(wrappedLines, current)
        end
    end

    -- Apply maxChars limit if specified
    if maxChars and maxChars > 0 then
        local charCount = 0
        local newWrapped = {}
        local done = false

        for _, line in ipairs(wrappedLines) do
            if done then break end
            local keep = ""
            for i = 1, #line do
                if charCount >= maxChars then
                    done = true
                    break
                end
                keep = keep .. line:sub(i, i)
                charCount = charCount + 1
            end

            if #keep > 0 then
                table.insert(newWrapped, keep)
            elseif not done then
                table.insert(newWrapped, "")
            end
        end
        wrappedLines = newWrapped
    end

    -- Draw all wrapped lines (keeping the original rendering logic)
    for _, line in ipairs(wrappedLines) do
        -- compute total width for alignment
        local totalWidth = 0
        for i = 1, #line do
            local info = ftable[line:byte(i)]
            if info then
                totalWidth = totalWidth + FixedMul(info.width * FRACUNIT, scale)
            end
        end

        -- adjust x for alignment
        local xpos = x
        if alignment == "center" then
            xpos = xpos - totalWidth / 2
        elseif alignment == "right" then
            xpos = xpos - totalWidth
        end

        -- draw each char
        for i = 1, #line do
            local code = line:byte(i)
            local info = ftable[code]
            if info then
                local pname = info.patchname
                if pname and patchExists(v, tostring(pname)) then
                    v.drawScaled(xpos, y, scale, info.patch, flags, cmap)
                end
                xpos = xpos + FixedMul(info.width * FRACUNIT, scale)
                
                -- DOOM-style: stop if we hit screen edge
                if xpos > maxWidth then
                    break
                end
            end
        end

        -- Move to next line
        y = y + FixedMul(lineHeight, scale)
    end
end

hud.add(function(v, player)
    if not doom.textscreen.active then return end
    
    local screenWidth = v.width()
    local screenHeight = v.height()
    local hudScaleInt, hudScaleFixed = v.dupx()
    local maybeTrueWidth = screenWidth / hudScaleInt
    local maybeTrueHeight = screenHeight / hudScaleInt

    -- Draw background border
    local centerBorderPatch = v.cachePatch(doom.textscreen.bg or "EP1CUTSC")
    local centerBorderWidth = centerBorderPatch.width
    local centerBorderHeight = centerBorderPatch.height
    local centerBorderRepeats = (maybeTrueWidth / centerBorderWidth)
    local centerBorderVertRepeats = (maybeTrueHeight / centerBorderHeight)

    for i = -1, centerBorderVertRepeats do
        for j = 0, centerBorderRepeats do
            v.draw(j * centerBorderWidth, i * centerBorderHeight + (centerBorderHeight / 2), centerBorderPatch, V_SNAPTOLEFT|V_SNAPTOTOP)
        end
    end

    -- Draw the text using current state
    drawInFont(v, 
        doom.textscreen.x * FRACUNIT, 
        doom.textscreen.y * FRACUNIT, 
        FRACUNIT, 
        "STCFN", 
        doom.textscreen.text, 
        V_SNAPTOLEFT, 
        "left", 
        nil, 
        doom.textscreen.elapsed / TEXTSPEED, 
        doom.textscreen.lineHeight
    )
end)

addHook("ThinkFrame", function()
	if not doom.textscreen.active then return end
	doom.textscreen.elapsed = ($ or 0) + 1
	if doom.textscreen.elapsed >= (#doom.textscreen.text  * TEXTSPEED) + TEXTWAIT then
		if (not doom.isdoom1) or multiplayer then
			DOOM_NextLevel()
		else
			doom.midGameTitlescreen = true
		end
	end
end)