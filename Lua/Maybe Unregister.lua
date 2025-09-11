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
