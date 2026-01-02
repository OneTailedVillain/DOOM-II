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

local gameSkillNames = {
	[1] = "I'm too young to die.",
	[2] = "Hey, not too rough.",
	[3] = "Hurt me plenty.",
	[4] = "Ultra-violence.",
	[5] = "Nightmare!",
}

COM_AddCommand("doom_skill", function(player, skill)
	skill = tonumber($)
	if gamestate == GS_LEVEL and skill != doom.gameskill then
		local curSkillName = gameSkillNames[skill] or "Unknown skill level '" .. skill .. "'"
		local message = "Game skill has been set to '" .. curSkillName .. "'. Changes will apply on the next map."
		message = $:upper()
		print(message)
		if doom.isdoom1 then
			S_StartSound(nil, sfx_tink)
		else
			S_StartSound(nil, sfx_radio)
		end
	end
	doom.gameskill = skill
end, COM_ADMIN)

COM_AddCommand("doom_setfixedcolormap", function(player, level)
	player.doom.fixedcolormap = level
end, COM_ADMIN)

COM_AddCommand("doom_endoom", function(player, level)
	doom.showendoom = true
end, COM_ADMIN)

COM_AddCommand("doom_exitlevel", function()
	DOOM_ExitLevel()
end)

COM_AddCommand("doom_docast", function(player, victim)
	F_StartCast()
end)

COM_AddCommand("resurrect", function(player, victim)
	player.playerstate = PST_LIVE
	player.mo.flags = $ | MF_SHOOTABLE
	player.mo.state = S_PLAY_STND
	player.mo.doom.health = 100
	player.mo.health = 1
	player.deadtimer = 0
	player.awayviewtics = 0
	player.awayviewmobj = nil
	player.doom.switchtimer = 0
	DOOM_SetState(player, "idle", 1)
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

CV_RegisterVar({
	name = "doom_alwaysrun",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})