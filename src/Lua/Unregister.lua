for i = 0, INT32_MAX do
	local def
	local ok = pcall(function() def = mobjinfo[i] end)
	if not ok or not def then
		break -- out of range
	end

	if def.doomednum and def.doomednum > -1 then
		def.doomednum = -1
	end
end

addHook("PostThinkFrame", function()
	if not multiplayer then return end
	for player in players.iterate() do
		if not player.doom.oldskin then player.doom.oldskin = player.skin end
		if player.skin != player.doom.oldskin then
			CONS_Printf(player, "Your skin will change on the next respawn.")
			player.doom.oldskin = player.skin
			player.doom.wishskin = player.skin
		end
	end
end)