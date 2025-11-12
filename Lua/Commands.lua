local ammoMap = {
	"bullets",
	"shells",
	"rockets",
	"cells"
}

local weaponMap = {
	"chainsaw",
	"brassknuckles",
	"pistol",
	"shotgun",
	"chaingun",
	"rocketlauncher",
	"plasmarifle",
	"bfg9000"
}

local function giveWeaponsArmorAndAmmo(player)
	local funcs = P_GetMethodsForSkin(player)
	funcs.setArmor(player, 200, FRACUNIT/2)
	for i = 1, 4 do
		local aType = ammoMap[i]
		local max = funcs.getMaxFor(player, aType)
		funcs.setAmmoFor(player, aType, max)
	end
	for i = 1, #weaponMap do
		funcs.giveWeapon(player, weaponMap[i])
	end
	if not doom.isdoom1 then
		funcs.giveWeapon(player, "supershotgun")
	end
end

COM_AddCommand("idkfa", function(player, victim)
	player.doom.keys = doom.KEY_RED|doom.KEY_BLUE|doom.KEY_YELLOW|doom.KEY_SKULLRED|doom.KEY_SKULLBLUE|doom.KEY_SKULLYELLOW
	DOOM_DoMessage(player, "$STSTR_KFAADDED")
	giveWeaponsArmorAndAmmo(player)
end)

COM_AddCommand("idfa", function(player, victim)
	DOOM_DoMessage(player, "$STSTR_FAADDED")
	giveWeaponsArmorAndAmmo(player)
end)

COM_AddCommand("idclip", function(player, victim)
	player.pflags = $ ^^ PF_NOCLIP
	if (player.pflags & PF_NOCLIP) then
		DOOM_DoMessage(player, "$STSTR_NCON")
	else
		DOOM_DoMessage(player, "$STSTR_NCOFF")
	end
end)

COM_AddCommand("doom_skill", function(player, victim)

end)

COM_AddCommand("doom_endoom", function(player, level)
	doom.showendoom = true
end, COM_ADMIN)

COM_AddCommand("doom_doblursphere", function(player, victim)
	player.doom.powers[pw_invisibility] = 60*TICRATE
end)

COM_AddCommand("doom_doinvincibility", function(player, victim)
	player.doom.powers[pw_invulnerability] = 30*TICRATE
end)

COM_AddCommand("doom_dotextscreen", function(player, text)
	--DOOM_StartTextScreen("$E1TEXT")
	DOOM_StartTextScreen({text = "$E1TEXT", bg = "EP1CUTSC"})
end)

COM_AddCommand("doom_exitlevel", function()
	DOOM_ExitLevel()
end)

doom.cvars = {}
CV_RegisterVar({
	name = "doom_rotateautomap",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

CV_RegisterVar({
	name = "doom_autorotateprefangle",
	defaultvalue = 0,
	flags = CV_SAVE|CV_FLOAT,
	PossibleValue = {MIN = INT32_MIN, MAX = INT32_MAX}
})

CV_RegisterVar({
	name = "doom_alwaysshowlines",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

CV_RegisterVar({
	name = "doom_hiresautomap",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

CV_RegisterVar({
	name = "doom_disableflashes",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})