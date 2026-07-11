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

function doom.invalidateCache()
	cacheShit = {
		colormaps = {},
		patches = {},
		fonts = {},
		lastwarned = {
			flag = {
				typemismatch = {}
			}
		}
	}
end

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

local function b(char)
	return string.byte(char, 1, 1)
end

local function manualBuildS2FONT(v)
	local fontTable = {}
	local patches = {
		S2FONTMINUS  = b("-"),
		S2FONT0      = b("0"),
		S2FONT1      = b("1"),
		S2FONT2      = b("2"),
		S2FONT3      = b("3"),
		S2FONT4      = b("4"),
		S2FONT5      = b("5"),
		S2FONT6      = b("6"),
		S2FONT7      = b("7"),
		S2FONT8      = b("8"),
		S2FONT9      = b("9"),
		S2FONTPERC   = b("%"),
		S2FONTCOLON  = b(":"),
		S2FONTPERIOD = b("."),
	}
	local width = v.cachePatch("S2FONT0").width
	for patch, code in pairs(patches) do
		local pdata = v.cachePatch(patch)
		fontTable[code] = {
			patch = pdata,
			patchname = patch,
			width = width,
		}
	end
	cacheShit.fonts["S2FONT"] = fontTable
end

local function manualBuildINVFON(v, font)
	local fontTable = {}
	local patches = {}
	for i = 0, 9 do
		patches["INVFON" .. tostring(font) .. i] = 48 + i
	end
	patches["INVFON" .. tostring(font) .. "_"] = 37
	local zeroPatch = v.cachePatch("INVFON"..font.."0")
	for patch, code in pairs(patches) do
		local pdata = v.cachePatch(patch)
		if v.patchExists(patch) then
			local width = zeroPatch.width + 1
			fontTable[code] = {
				patch = pdata,
				patchname = patch,
				width = width,
			}
		else
			print("Warning: patch '" .. patch .. "' not found!")
		end
	end
	cacheShit.fonts["INVFON" .. tostring(font)] = fontTable
end

-- Either creates or caches a fontset
local function cacheFont(v, font, force)
	if not cacheShit.fonts[font] or force then
		if font == "STT" then
			manualBuildSTT(v)
		elseif font == "AMMNUM" then
			manualBuildAMMNUM(v, font)
		elseif font == "IN" then
			manualBuildAMMNUM(v, font)
		elseif font == "S2FONT" then
			manualBuildS2FONT(v, font)
		elseif font == "STYSNUM" then
			manualBuildAMMNUM(v, font)
		elseif font == "STGNUM" then
			manualBuildAMMNUM(v, font)
		elseif font == "WI" then
			manualBuildWI(v, font)
		elseif font == "INVFONY" then
			manualBuildINVFON(v, "Y")
		elseif font == "INVFONG" then
			manualBuildINVFON(v, "G")
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
end

function doom.drawInFont(v, x, y, scale, font, str, flags, alignment, cmap, maxChars, lineHeight)
	str = tostring(str)

	-- Validate flags
	if type(flags) != "number" then
		if not cacheShit.lastwarned.flag.typemismatch[tostring(flags)] then
			print("\82WARNING:\80 Flag type mismatch! (number expected, got " .. type(flags))
			cacheShit.lastwarned.flag.typemismatch[tostring(flags)] = true
		end
		flags = 0
	end

	-- Handle lowercase
	if not (flags & V_ALLOWLOWERCASE) then
		str = str:upper()
	end
	flags = flags & ~V_ALLOWLOWERCASE

	-- Get font
	local ftable = cacheFont(v, font)
	if not ftable then return end

	-- Cache line height per font (do this once)
	if not cacheShit.fontHeights then cacheShit.fontHeights = {} end
	if not cacheShit.fontHeights[font] then
		local h = 0
		for _, info in pairs(ftable) do
			if info.patch and info.patch.valid then
				h = max(h, info.patch.height)
			end
		end
		cacheShit.fontHeights[font] = h * FRACUNIT
	end

	lineHeight = lineHeight and (lineHeight * scale) or cacheShit.fontHeights[font]

	local maxWidth = 320*FRACUNIT

	-- Precompute glyph advances
	if not cacheShit.fontAdvance then cacheShit.fontAdvance = {} end
	if not cacheShit.fontAdvance[font] then
		local adv = {}
		for code, info in pairs(ftable) do
			if info.width then
				adv[code] = info.width * FRACUNIT
			end
		end
		cacheShit.fontAdvance[font] = adv
	end
	local advance = cacheShit.fontAdvance[font]

	-- Helper: measure word once
	local function measureWord(word)
		local w = 0
		for i = 1, #word do
			local a = advance[word:byte(i)]
			if a then
				w = $ + FixedMul(a, scale)
			end
		end
		return w
	end

	-- Split lines
	local rawLines = {}
	for line in str:gmatch("[^\n]+") do
		rawLines[#rawLines+1] = line
	end

	-- Wrap lines efficiently
	local wrapped = {}
	for _, line in ipairs(rawLines) do
		local currentWords = {}
		local currentWidth = 0

		for word in line:gmatch("%S+") do
			local wWidth = measureWord(word)
			local spaceWidth = advance[32] and FixedMul(advance[32], scale) or 0

			local newWidth = currentWidth
			if #currentWords > 0 then
				newWidth = $ + spaceWidth
			end
			newWidth = $ + wWidth

			if newWidth <= maxWidth then
				currentWords[#currentWords+1] = word
				currentWidth = newWidth
			else
				if #currentWords > 0 then
					wrapped[#wrapped+1] = currentWords
				end
				currentWords = {word}
				currentWidth = wWidth
			end
		end

		if #currentWords > 0 then
			wrapped[#wrapped+1] = currentWords
		end
	end

	-- Apply maxChars limit
	if maxChars and maxChars > 0 then
		local count = 0
		local newWrapped = {}
		local done = false

		for _, words in ipairs(wrapped) do
			if done then break end

			local newWords = {}
			for _, word in ipairs(words) do
				if done then break end

				local cut = ""
				for i = 1, #word do
					if count >= maxChars then
						done = true
						break
					end
					cut = cut .. word:sub(i,i)
					count = $ + 1
				end

				if #cut > 0 then
					newWords[#newWords+1] = cut
				end
			end

			if #newWords > 0 then
				newWrapped[#newWrapped+1] = newWords
			end
		end

		wrapped = newWrapped
	end

	-- === RENDER ===
	for _, words in ipairs(wrapped) do
		-- Compute total width once
		local totalWidth = 0
		local spaceWidth = advance[32] and FixedMul(advance[32], scale) or 0

		for i = 1, #words do
			totalWidth = $ + measureWord(words[i])
			if i < #words then
				totalWidth = $ + spaceWidth
			end
		end

		-- Alignment
		local xpos = x
		if alignment == "center" then
			xpos = xpos - totalWidth/2
		elseif alignment == "right" then
			xpos = xpos - totalWidth
		end

		-- Draw words/characters
		for wi = 1, #words do
			local word = words[wi]

			for i = 1, #word do
				local code = word:byte(i)
				local info = ftable[code]

				if info and info.patch then
					v.drawScaled(xpos, y, scale, info.patch, flags, cmap)
					xpos = xpos + FixedMul(advance[code], scale)
				end

				if xpos > maxWidth then break end
			end

			-- Space between words
			if wi < #words then
				xpos = xpos + spaceWidth
			end
		end

		y = y + FixedMul(lineHeight, scale)
	end
end

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

    -- Diagonal line: batch consecutive pixels on same row to reduce draw calls
    local x, y = sx1, sy1
    local currentY = y
    local runStart = x
    local runEnd = x

    while true do
        -- If Y changed, flush the accumulated run
        if y ~= currentY then
            local width = abs(runEnd - runStart) + 1
            local minX = min(runStart, runEnd)
            v.drawFill(minX, currentY, width, 1, color|flags)
            currentY = y
            runStart = x
        end
        
        runEnd = x
        
        -- Check if we've reached the endpoint
        if x == sx2 and y == sy2 then
            -- Flush final run
            local width = abs(runEnd - runStart) + 1
            local minX = min(runStart, runEnd)
            v.drawFill(minX, currentY, width, 1, color|flags)
            break
        end
        
        -- Advance to next pixel
        local e2 = err * 2
        
        if e2 > -dy then
            err = err - dy
            x = $ + sx
        end
        
        if e2 < dx then
            err = err + dx
            y = $ + sy
        end
    end
end)