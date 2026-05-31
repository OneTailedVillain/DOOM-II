hud.add(function(v, player)
	local targetHudDraw = doom.hudDraw[player.doom.customHudPref or doom.currentGame]
	if targetHudDraw then
		targetHudDraw(v, player)
	end
end)