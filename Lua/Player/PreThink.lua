addHook("PreThinkFrame", function()
	if not (displayplayer and displayplayer.doom) then return end

	for sector in sectors.iterate do
		if not (sector and sector.valid) then continue end
		if not doom.sectorbackups[sector] then continue end
		if not doom.sectorbackups[sector].curLightTic then continue end
		sector.lightlevel = doom.sectorbackups[sector].curLightTic
	end
end)