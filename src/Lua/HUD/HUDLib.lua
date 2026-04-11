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

-- Either get or create a colormap
-- Actually remembers what it created, however I don't really think this
-- Boosts performance like the proprietary cachePatch function does
local function getColormap(v, skin, color, cmap)
	-- Coerce keys to strings to avoid nil indexes
	-- Can't believe i #forgotthis... #AWKWARD!
	skin  = tostring(skin)
	color = tostring(color)
	cmap  = tostring(cmap)

	-- Ensure nested tables exist
	if not cacheShit.colormaps[skin] then
		cacheShit.colormaps[skin] = {}
	end
	if not cacheShit.colormaps[skin][color] then
		cacheShit.colormaps[skin][color] = {}
	end
	if not cacheShit.colormaps[skin][color][cmap] then
		cacheShit.colormaps[skin][color][cmap] = v.getColormap(skin, color, cmap)
	end

	return cacheShit.colormaps[skin][color][cmap]
end

-- Variant of v.cachePatch which actually remembers what it just cached
-- Preferrably you should use this if you're concerned of the amount of patches
-- You cache each frame, as from my non-existent testing using this instead
-- Seems to have boosted performance
rawset(_G, "cachePatch", function(v, patch)
	if not cacheShit.patches[patch] then
		cacheShit.patches[patch] = v.cachePatch(patch)
	end
	return cacheShit.patches[patch]
end)

rawset(_G, "patchExists", function(v, patch)
	if not cacheShit.patches[patch] then
		-- Not in our database, use the vanilla function and add it to our cache
		if v.patchExists(patch) then
			cacheShit.patches[patch] = v.cachePatch(patch)
			return true
		end
	else
		return true
	end
	return false
end)

local function manualBuildSTT(v)
	local fontTable = {}
	local patches = {
		STTMINUS = 45,
		STTNUM0 = 48,
		STTNUM1 = 49,
		STTNUM2 = 50,
		STTNUM3 = 51,
		STTNUM4 = 52,
		STTNUM5 = 53,
		STTNUM6 = 54,
		STTNUM7 = 55,
		STTNUM8 = 56,
		STTNUM9 = 57,
		STTPRCNT = 37
	}
	local width = v.cachePatch("STTNUM0").width
	for patch, code in pairs(patches) do
		local pdata = v.cachePatch(patch)
		fontTable[code] = {
			patch = pdata,
			patchname = patch,
			width = width,
		}
	end
	cacheShit.fonts["STT"] = fontTable
end

local function manualBuildWI(v)
	local fontTable = {}
	local patches = {
		WIMINUS = 45,
		WINUM0 = 48,
		WINUM1 = 49,
		WINUM2 = 50,
		WINUM3 = 51,
		WINUM4 = 52,
		WINUM5 = 53,
		WINUM6 = 54,
		WINUM7 = 55,
		WINUM8 = 56,
		WINUM9 = 57,
		WIPCNT = 37
	}
	local width = v.cachePatch("WINUM0").width
	for patch, code in pairs(patches) do
		local pdata = v.cachePatch(patch)
		fontTable[code] = {
			patch = pdata,
			patchname = patch,
			width = width,
		}
	end
	cacheShit.fonts["WI"] = fontTable
end

local function manualBuildAMMNUM(v, font)
	local fontTable = {}
	local patches = {}
	for i = 0, 9 do
		patches[tostring(font) .. i] = 48 + i
	end
	for patch, code in pairs(patches) do
		local pdata = v.cachePatch(patch)
		local width = pdata.width
		fontTable[code] = {
			patch = pdata,
			patchname = patch,
			width = width,
		}
	end
	cacheShit.fonts[font] = fontTable
end

-- Either creates or caches a fontset
rawset(_G, "cacheFont", function(v, font)
	if not cacheShit.fonts[font] then
		if font == "STT" then
			manualBuildSTT(v)
		elseif font == "AMMNUM" then
			manualBuildAMMNUM(v, font)
		elseif font == "STYSNUM" then
			manualBuildAMMNUM(v, font)
		elseif font == "STGNUM" then
			manualBuildAMMNUM(v, font)
		elseif font == "WI" then
			manualBuildWI(v, font)
		else
			local fontTable = {}
			for code = 0, 255 do
				-- Also try zero-pad for fonts that use it for some reason
				local patch_name       = font .. code
				local patch_name_zpad  = font .. string.format("%03d", code)

				local patch
				local patchname
				if patchExists(v, patch_name) then
					patch = cachePatch(v, patch_name)
					patchname = patch_name
				elseif patchExists(v, patch_name_zpad) then
					patch = cachePatch(v, patch_name_zpad)
					patchname = patch_name_zpad
				end

				if patch then
					fontTable[code] = {
						patch = patch,
						patchname = patchname,
						width = patch.width,
					}
					-- Also store in patch cache in case it’s raw-cached later
					cacheShit.patches[patch_name]      = patch
					cacheShit.patches[patch_name_zpad] = patch
				elseif tostring(code) == "32" then
					fontTable[code] = {
						width = 4,
					}
				end
			end
			cacheShit.fonts[font] = fontTable
		end
	end
	return cacheShit.fonts[font]
end)

-- TODO: maybe extend this a bit?
/*
drawInFont(v,
x, y,
scale,
font,
str,
flags, alignment, cmap,
maxChars,
lineHeight)
*/
rawset(_G, "drawInFont", function(v, x, y, scale, font, str, flags, alignment, cmap, maxChars, lineHeight)
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
end)

-- Bresenham-based line drawing (with bailout)
rawset(_G, "minimapDrawLine", function(v, x1, y1, x2, y2, color, flags, scale)
    color = color or 8
    flags = flags or 0
    scale = scale or FRACUNIT

    -- Convert from fixed_t px-space to integer screen coords with proper rounding
    local sx1 = (x1 / scale)
    local sy1 = (y1 / scale)
    local sx2 = (x2 / scale)
    local sy2 = (y2 / scale)

    local dx = abs(sx2 - sx1)
    local dy = abs(sy2 - sy1)
    local sx = (sx1 < sx2) and 1 or -1
    local sy = (sy1 < sy2) and 1 or -1
    local err = dx - dy

    -- Special case: vertical line
    if dx == 0 then
        local yStart = min(sy1, sy2)
        local yEnd = max(sy1, sy2)
        v.drawFill(sx1, yStart, 1, yEnd - yStart + 1, color|flags)
        return
    end

    -- Special case: horizontal line  
    if dy == 0 then
        local xStart = min(sx1, sx2)
        local xEnd = max(sx1, sx2)
        v.drawFill(xStart, sy1, xEnd - xStart + 1, 1, color|flags)
        return
    end

    -- Simplified approach without run batching for diagonal lines
    -- This ensures every pixel is drawn exactly once
    local x, y = sx1, sy1
    local maxSteps = dx + dy  -- Maximum possible steps
    local steps = 0
    
    while steps <= maxSteps do
        -- Always draw the current pixel
        v.drawFill(x, y, 1, 1, color|flags)
        
        -- Break if we've reached the end point
        if x == sx2 and y == sy2 then
            break
        end
        
        local e2 = err * 2
        
        if e2 > -dy then
            err = err - dy
            x = $ + sx
        end
        
        if e2 < dx then
            err = err + dx
            y = $ + sy
        end
        
        steps = $ + 1
    end
end)