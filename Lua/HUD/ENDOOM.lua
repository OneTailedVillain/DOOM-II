local endmtimer = TICRATE*3
local width = 4
local height = 8

local bgclrs = {
	0,
	202,
	119,
	115,
	181,
	252,
	164,
	86,
	104,
	197,
	115,
	194,
	26,
	250,
	249,
	4
}

local function endoom(v, player)
	if not doom.showendoom then return end
    v.drawFill(0, 0, 320, 200, 0)  -- Fill screen with black

    -- Draw ENDOOM text with proper colors
    for y = 1, #doom.endoom.text do
        local line = doom.endoom.text[y]
        local color_line = doom.endoom.colors[y] or {}
        
        local x_pos = 0
        local char_index = 1
        
        -- Process RLE segments directly
		for _, segment in ipairs(color_line) do
			local attr, count = segment[1], segment[2]
			
			local fg = attr & 0x0F
			local bg = (attr >> 4) & 0x07
			local blink = (attr & 0x80) ~= 0
			local show_char = not blink or (leveltime % 32) < 16
			local bg_color = bgclrs[bg+1]
			
			-- Draw background
			v.drawFill(x_pos, (y-1)*height, width * count, height, bg_color)
			
			-- Draw characters
			if show_char then
				for i = 1, count do
					if char_index <= #line then
						local char = string.byte(line, char_index)
						if char ~= 32 then
							char = string.format("%03d", $)
							print(char)
							v.drawScaled(x_pos*FRACUNIT, (y-1)*height*FRACUNIT, FRACUNIT/2, v.cachePatch("DSFNT" .. char), 0, v.getColormap(nil, nil, "DOSPROMPT" .. fg))
						end
						char_index = char_index + 1
					end
					x_pos = x_pos + width
				end
			else
				x_pos = x_pos + width * count
				char_index = char_index + count
			end
		end
    end
end

hud.add(endoom, "game")
hud.add(endoom, "title")

addHook("ThinkFrame", function()
	if not doom.showendoom then return end
	endmtimer = $ - 1
	if endmtimer <= 0 then
		COM_BufInsertText(player, "quit")
	end
end)