local LIGHTLEVELSHIFT = 3

addHook("PostThinkFrame", function()
	if displayplayer and displayplayer.doom then
		local lightBump = displayplayer.doom.extralight
		local fixedColormap = displayplayer.doom.fixedcolormap
		for sector in sectors.iterate do
			if not doom.sectorbackups[sector] then continue end
			doom.sectorbackups[sector].curLightTic = sector.lightlevel
			local curLight = doom.sectorbackups[sector].curLightTic
			if fixedColormap then
				sector.lightlevel = 256 - (fixedColormap << LIGHTLEVELSHIFT)
			elseif lightBump then
				sector.lightlevel = curLight + (lightBump << LIGHTLEVELSHIFT)
			else
				sector.lightlevel = curLight
			end
		end
	end
end)