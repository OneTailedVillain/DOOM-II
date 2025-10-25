local TEXTSPEED = 3
local TEXTWAIT = 250

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
		DOOM_NextLevel()
	end
end)