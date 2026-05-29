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

local OGSoundPlay = S_StartSound
rawset(_G, "S_StartSound", function(origin, soundnum, player)
	if origin and origin.player then
		local def = P_GetSupportsForSkin(origin)
		if def then
			def = def.sounds
		end
		if def then
			def = def[soundnum]
		end
		if def then
			soundnum = def
		end
	elseif player then
		local def = P_GetSupportsForSkin(player)
		if def then
			def = def.sounds
		end
		if def then
			def = def[soundnum]
		end
		if def then
			soundnum = def
		end
	end
	OGSoundPlay(origin, soundnum, player)
end)

addHook("PostThinkFrame", function()
	for player in players.iterate() do
		if not player.doom.oldskin then player.doom.oldskin = player.skin end
		if player.skin != player.doom.oldskin then
			CONS_Printf(player, "Your skin will change on the next respawn.")
			player.doom.oldskin = player.skin
			player.doom.wishskin = player.skin
		end
	end
end)