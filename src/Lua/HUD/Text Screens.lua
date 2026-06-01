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

hud.add(function(v, player)
    if not doom.textscreen.active then return end

	if doom.midGameTitlescreen then
		if doom.textscreen.postgraphic then
			v.draw(0, 0, v.cachePatch(doom.textscreen.postgraphic))
		end
		return
	end

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
    doom.drawInFont(v,
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
			if not doom.midGameTitlescreen then
				if doom.textscreen.postcutscene then
					doom.curcutscene = doom.textscreen.postcutscene
				end
				doom.midGameTitlescreen = true
			end
		end
	end
end)