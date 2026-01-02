addHook("PreThinkFrame", function()
	if not (displayplayer and displayplayer.doom) then return end

	for sector in sectors.iterate do
		sector.lightlevel = doom.sectorbackups[sector].curLightTic
	end
end)