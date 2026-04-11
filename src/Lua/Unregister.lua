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