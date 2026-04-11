local function DrawFlashes(v, ply)
	if splitscreen then return end
	if DOOM_IsPaletteRenderer() then return end

	local color_flash = 0
	local color_flash_intensity = 0
	local damage_flash = ply.doom.damagecount
    local bzc = 0

    if ply.doom.powers[pw_strength] and ply.doom.powers[pw_strength] > 0 then
        bzc = 12 - (ply.doom.powers[pw_strength] >> 6)
        if bzc > damage_flash then
            damage_flash = bzc
        end
    end
	damage_flash = ($ + 7) >> 3

	local bonus_flash = (ply.doom.bonuscount + 7) >> 3
	local hazardsuit_flash = 0
	if ply.doom.powers[pw_ironfeet] and ((ply.doom.powers[pw_ironfeet] > (4 * 32)) or (ply.doom.powers[pw_ironfeet] & 8)) then
		hazardsuit_flash = 4
	end

	if damage_flash then
		color_flash = 176
		color_flash_intensity = min(damage_flash, 5)
	elseif bonus_flash then
		color_flash = 160
		color_flash_intensity = min(bonus_flash, 4)
	elseif hazardsuit_flash then
		color_flash = 116
		color_flash_intensity = hazardsuit_flash
	end

	if color_flash then
		v.fadeScreen(color_flash, max(min(color_flash_intensity, 10), 0))
	end
end

return DrawFlashes