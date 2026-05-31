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
		if doom.weapons[weaponName] and doom.weapons[weaponName].noshareware then
			if doom.gamemode == "shareware" then continue end
		end
		doom.giveWeapon(player, weaponMap[i])
	end
	if not doom.isdoom1 then
		doom.giveWeapon(player, "supershotgun")
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

-- Command to display text screens by episode/level number
COM_AddCommand("doom_dotextscreen", function(player, arg)
	local funcs = P_GetMethodsForSkin(player)

	-- Check if arg is provided
	if not arg or arg == "" then
		DOOM_DoMessage(player, "Usage: doom_dotextscreen <episode/level> (e.g., doomtext e1, doomtext 8)")
		return
	end

	arg = string.lower(arg)
	local textScreen = nil

	-- Handle episode format (e1, e2, e3, e4) for DOOM 1
	if doom.isdoom1 then
		if arg == "e1" then
			textScreen = doom.textscreenmaps[8]  -- E1M8 text
		elseif arg == "e2" then
			textScreen = doom.textscreenmaps[17] -- E2M8 text
		elseif arg == "e3" then
			textScreen = doom.textscreenmaps[26] -- E3M8 text
		elseif arg == "e4" then
			textScreen = doom.textscreenmaps[35] -- E4M8 text
		else
			-- Try direct level number
			local levelNum = tonumber(arg)
			if levelNum then
				textScreen = doom.textscreenmaps[levelNum]
			end
		end
	else -- DOOM 2
		if arg == "c1" or arg == "map06" or arg == "6" then
			textScreen = doom.textscreenmaps[6]   -- MAP06 text
		elseif arg == "c2" or arg == "map11" or arg == "11" then
			textScreen = doom.textscreenmaps[11]  -- MAP11 text
		elseif arg == "c3" or arg == "map20" or arg == "20" then
			textScreen = doom.textscreenmaps[20]  -- MAP20 text
		elseif arg == "c4" or arg == "map30" or arg == "30" then
			textScreen = doom.textscreenmaps[30]  -- MAP30 text
		elseif arg == "c5" or arg == "map15" or arg == "15" then
			textScreen = doom.textscreenmaps[15]  -- MAP15 text (secret)
		elseif arg == "c6" or arg == "map31" or arg == "31" then
			textScreen = doom.textscreenmaps[31]  -- MAP31 text (secret)
		else
			-- Try direct level number
			local levelNum = tonumber(arg)
			if levelNum then
				textScreen = doom.textscreenmaps[levelNum]
			end
		end
	end

	-- Display the text screen if found
	if textScreen then
		-- Create a copy of the text screen data
		local screenData = {
			text = textScreen.text,
			bg = textScreen.bg
		}

		-- Call the existing text screen function
		DOOM_StartTextScreen(screenData)

		-- Optional: Notify the player
		if textScreen.secret then
			DOOM_DoMessage(player, "Showing secret text screen...")
		else
			DOOM_DoMessage(player, "Showing text screen...")
		end
	else
		-- List available options if no match found
		DOOM_DoMessage(player, "Text screen not found! Available:")
		if doom.isdoom1 then
			DOOM_DoMessage(player, "doomtext e1 (E1M8), doomtext e2 (E2M8), doomtext e3 (E3M8), doomtext e4 (E4M8)")
			DOOM_DoMessage(player, "Or use level numbers: 8, 17, 26, 35")
		else
			DOOM_DoMessage(player, "doomtext c1/c2/c3/c4/c5/c6 or map numbers: 6,11,15,20,30,31")
		end
	end
end)

-- This is the ugliest code to date. Whatever!
COM_AddCommand("idbehold", function(player, arg)
	local funcs = P_GetMethodsForSkin(player)
	if funcs.shouldDoCheat then
		if funcs.shouldDoCheat(player, "idbehold", arg) then return end
	end
	if arg == "v" then
		if funcs.hasPowerUp(player, "invulnerability") then
			funcs.takePowerUp(player, "invulnerability")
		else
			funcs.doPowerUp(player, "invulnerability")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "a" then
		if funcs.hasPowerUp(player, "allmap") then
			funcs.takePowerUp(player, "allmap")
		else
			funcs.doPowerUp(player, "allmap")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "s" then
		if funcs.hasPowerUp(player, "berserk") then
			funcs.takePowerUp(player, "berserk")
		else
			funcs.doPowerUp(player, "berserk")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "i" then
		if funcs.hasPowerUp(player, "invisibility") then
			funcs.takePowerUp(player, "invisibility")
		else
			funcs.doPowerUp(player, "invisibility")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "r" then
		if funcs.hasPowerUp(player, "ironfeet") then
			funcs.takePowerUp(player, "ironfeet")
		else
			funcs.doPowerUp(player, "ironfeet")
		end
		DOOM_DoMessage(player, "$STSTR_BEHOLDX")
	elseif arg == "l" then
		if funcs.hasPowerUp(player, "infrared") then
			funcs.takePowerUp(player, "infrared")
		else
			funcs.doPowerUp(player, "infrared")
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
	if netgame then
		if not IsPlayerAdmin(player) or player == server then
			DOOM_DoMessage(player, "This is restricted to admins only.")
			return
		end
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
	doom.giveWeapon(player, "chainsaw")

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
/*
CV_RegisterVar({
	name = "doom_alwaysrun",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})
*/
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
/*
doom.cvars.user_hudpref = CV_RegisterVar({
	name = "doom_hudpreference",
	defaultvalue = "Original",
	flags = CV_SAVE,
	PossibleValue = {Original = 1, BOOMStacked = 2, BOOMStacked_Nostats = 3, BOOMDistributed = 4, BOOMDistributed_Nostats = 5, Woof_NoSBGraphic = 6}
})

doom.cvars.user_numbercolorization = CV_RegisterVar({
	name = "doom_vanillahudcolorization",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

doom.cvars.user_graypercent = CV_RegisterVar({
	name = "doom_vanillahudgraypercent",
	defaultvalue = "Off",
	flags = CV_SAVE,
	PossibleValue = CV_OnOff
})

---@class colorpref_nogreenthreshold
---@field red consvar_t
---@field yellow consvar_t

---@class colorpref
---@field red consvar_t
---@field yellow consvar_t
---@field green consvar_t

---@class doomusercolorpreferences
---@field ammo colorpref_nogreenthreshold
---@field health colorpref
---@field armor colorpref

local CV_Percent = {MIN = 0, MAX = 100}

---@type doomusercolorpreferences
doom.cvars.user_colorthresholds = {
	ammo = {
		red = CV_RegisterVar({
			name = "doom_hudthresholds_ammo_red",
			defaultvalue = 25,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
		yellow = CV_RegisterVar({
			name = "doom_hudthresholds_ammo_yellow",
			defaultvalue = 50,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
	},
	health = {
		red = CV_RegisterVar({
			name = "doom_hudthresholds_health_red",
			defaultvalue = 25,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
		yellow = CV_RegisterVar({
			name = "doom_hudthresholds_health_yellow",
			defaultvalue = 50,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
		green = CV_RegisterVar({
			name = "doom_hudthresholds_health_green",
			defaultvalue = 100,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
	},
	armor = {
		red = CV_RegisterVar({
			name = "doom_hudthresholds_armor_red",
			defaultvalue = 25,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
		yellow = CV_RegisterVar({
			name = "doom_hudthresholds_armor_yellow",
			defaultvalue = 50,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
		green = CV_RegisterVar({
			name = "doom_hudthresholds_armor_green",
			defaultvalue = 100,
			flags = CV_SAVE,
			PossibleValue = CV_Percent
		}),
	},
}
*/