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
		local weaponName = weaponMap[i]
		if doom.weapons[weaponName].noshareware then
			if doom.gamemode == "shareware" then continue end
		end
		funcs.giveWeapon(player, weaponMap[i])
	end
	if not doom.isdoom1 then
		funcs.giveWeapon(player, "supershotgun")
	end
end

COM_AddCommand("idkfa", function(player)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		local returnVal = funcs.shouldDoCheat(player, "idkfa")
		if returnVal then return end
	end
	player.doom.keys = doom.KEY_RED|doom.KEY_BLUE|doom.KEY_YELLOW|doom.KEY_SKULLRED|doom.KEY_SKULLBLUE|doom.KEY_SKULLYELLOW
	DOOM_DoMessage(player, "$STSTR_KFAADDED")
	giveWeaponsArmorAndAmmo(player)
	if funcs.onCheat then
		local returnVal = funcs.onCheat(player, "idkfa")
	end
end)

COM_AddCommand("idfa", function(player)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		local returnVal = funcs.shouldDoCheat(player, "idfa")
		if returnVal then return end
	end
	DOOM_DoMessage(player, "$STSTR_FAADDED")
	giveWeaponsArmorAndAmmo(player)
	if funcs.onCheat then
		local returnVal = funcs.onCheat(player, "idfa")
	end
end)

COM_AddCommand("idclip", function(player)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		local returnVal = funcs.shouldDoCheat(player, "idclip")
		if returnVal then return end
	end
	player.pflags = player.pflags ^^ PF_NOCLIP
	if (player.pflags & PF_NOCLIP) then
		DOOM_DoMessage(player, "$STSTR_NCON")
	else
		DOOM_DoMessage(player, "$STSTR_NCOFF")
	end
	if funcs.onCheat then
		local returnVal = funcs.onCheat(player, "idclip")
	end
end)

-- This is the ugliest code to date. Whatever!
COM_AddCommand("idbehold", function(player, arg)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		if funcs.shouldDoCheat(player, "idbehold", arg) then return end
	end
	if arg == "v" then
		if funcs.hasPowerup(player, "invulnerability") then
			funcs.takePowerUp(player, "invulnerability")
		else
			funcs.doPowerUp(player, "invulnerability")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "a" then
		if funcs.hasPowerup(player, "allmap") then
			funcs.takePowerUp(player, "allmap")
		else
			funcs.doPowerUp(player, "allmap")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "s" then
		if funcs.hasPowerup(player, "berserk") then
			funcs.takePowerUp(player, "berserk")
		else
			funcs.doPowerUp(player, "berserk")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "i" then
		if funcs.hasPowerup(player, "invisibility") then
			funcs.takePowerUp(player, "invisibility")
		else
			funcs.doPowerUp(player, "invisibility")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "r" then
		if funcs.hasPowerup(player, "ironfeet") then
			funcs.takePowerUp(player, "ironfeet")
		else
			funcs.doPowerUp(player, "ironfeet")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "l" then
		if funcs.hasPowerup(player, "lightamp") then
			funcs.takePowerUp(player, "lightamp")
		else
			funcs.doPowerUp(player, "lightamp")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	else
		DOOM_DoMessage(player, "$STSTR_BEHOLD")
	end
end)

COM_AddCommand("idclev", function(player, arg)
	local funcs = P_GetMethodsForSkin(player)

	-- If player is promoted or has the same userdata reference as the server...
	-- Don't specify "command" vs "cheat" here, as we don't know whether we got here
	-- via the console or the typed-in cheats,
	if not IsPlayerAdmin(player) or player == server then
		DOOM_DoMessage(player, "This is restricted to admins only.")
		return
	end

	if funcs.shouldDoCheat then
		if funcs.shouldDoCheat(player, "idclev", arg) then return end
	end

	local num = tonumber(arg)
	if not num then return end

	if doom.isdoom1 then
		local ep = num / 10
		local mp = num % 10
		if ep < 1 or ep > 4 or mp < 1 or mp > 9 then return end
		COM_BufInsertText(player, string.format("map e%dm%d", ep, mp))
	else
		if num < 1 or num > 32 then return end
		COM_BufInsertText(player, string.format("map map%02d", num))
	end

	if funcs.onCheat then
		funcs.onCheat(player, "idclev", arg)
	end
end)

COM_AddCommand("idmus", function(player, arg)
	local funcs = P_GetMethodsForSkin(player)

	if funcs.shouldDoCheat then
		if funcs.shouldDoCheat(player, "idmus", arg) then return end
	end

	local num = tonumber(arg)
	if not num then DOOM_DoMessage(player, "$STSTR_NOMUS") return end

	local mh

	if doom.isdoom1 then
		local ep = num / 10
		local mp = num % 10
		if ep < 1 or ep > 4 or mp < 1 or mp > 9 then DOOM_DoMessage(player, "$STSTR_NOMUS") return end

		local index = (ep - 1) * 9 + mp
		mh = mapheaderinfo[index]
	else
		if num < 1 or num > 32 then DOOM_DoMessage(player, "$STSTR_NOMUS") return end
		mh = mapheaderinfo[num]
	end

	if not mh or not mh.musname then DOOM_DoMessage(player, "$STSTR_NOMUS") return end

	COM_BufInsertText(player, "tunes " .. mh.musname)

	if funcs.onCheat then
		funcs.onCheat(player, "idmus", arg)
	end
end)

COM_AddCommand("iddqd", function(player)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		local returnVal = funcs.shouldDoCheat(player, "iddqd")
		if returnVal then return end
	end
	player.doom.cheats = player.doom.cheats ^^ CF_GODMODE
	if player.doom.cheats & CF_GODMODE then
		funcs.setHealth(player, 100)
		DOOM_DoMessage(player, "$STSTR_DQDON")
	else
		DOOM_DoMessage(player, "$STSTR_DQDOFF")
	end
	if funcs.onCheat then
		local returnVal = funcs.onCheat(player, "iddqd")
	end
end)

COM_AddCommand("idchoppers", function(player)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		local returnVal = funcs.shouldDoCheat(player, "idchoppers")
		if returnVal then return end
	end
	funcs.giveWeapon(player, "chainsaw")

	DOOM_DoMessage(player, "$STSTR_CHOPPERS")
	if funcs.onCheat then
		local returnVal = funcs.onCheat(player, "idchoppers")
	end
end)

local gameSkillStrings = {
	"$SKILL_BABY",
	"$SKILL_EASY",
	"$SKILL_NORMAL",
	"$SKILL_HARD",
	"$SKILL_NIGHTMARE",
}

COM_AddCommand("doom_skill", function(player, skill)
	skill = tonumber(skill)
	if skill < 1 or skill > 5 then
		CONS_Printf(player, "Invalid skill level '" .. skill .. "'!")
	end
	if gamestate == GS_LEVEL and skill != doom.gameskill then
		local curSkillName = DOOM_ResolveString(gameSkillStrings[skill]) or ("Unknown skill level '" .. skill .. "'")
		local message = "Game skill has been set to '" .. curSkillName .. "'. Changes will apply on the next map."
		message = message:upper()
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

doom.cvars.dmExit = CV_RegisterVar({
	name = "doom_allowdmexitlevel",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

doom.cvars.multiDontLowHealth = CV_RegisterVar({
	name = "doom_preventlowhealthspawnsinmultiplayer",
	defaultvalue = "On",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

doom.cvars.techniColorCorpses = CV_RegisterVar({
	name = "doom_technicolorcorpses",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})