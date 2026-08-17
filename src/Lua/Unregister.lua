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

addHook("PreThinkFrame", function()
	if not multiplayer then return end
	for player in players.iterate() do
		if player.spectator then player.doom.oldskin = player.mo.skin end
		-- Had an idea to use the player's "skin" cvar, but
		-- I really don't feel like managing that desynchfest
		if player.jointime <= 17 and player.mo.skin != "sonic" then
			player.doom.properties = nil
			player.doom.properties = P_GetPlayerSkinProperties(player)
		end
		if player.jointime <= 17 then continue end
		if not player.doom.oldskin then player.doom.oldskin = player.mo.skin end
		if player.mo.skin != player.doom.oldskin then
			CONS_Printf(player, "Your skin will change on the next respawn.")
			player.doom.pendingSkinChange = player.mo.skin
			R_SetPlayerSkin(player, player.doom.oldskin)
		end
	end
end)

addHook("PlayerThink", function(player)
	if not multiplayer then return end
	if not player.doom.pendingSkinChange then return end
	if player.mo.skin == player.doom.oldskin then return end
	R_SetPlayerSkin(player, player.doom.oldskin)
end)

addHook("PostThinkFrame", function()
	if not multiplayer then return end
	for player in players.iterate() do
		---@type player_t
		local player = player
		if not player.doom.pendingSkinChange then continue end
		if player.mo.skin == player.doom.oldskin then continue end
		R_SetPlayerSkin(player, player.doom.oldskin)
	end
end)