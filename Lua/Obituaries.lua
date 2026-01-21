

local weapon_aliases = {
	rocketlauncher_friendlyfire = { "rocketlauncher", "weapon_rpg", "rpg", "rl", "rocket" },
	bfg9000_friendlyfire        = { "bfg9000", "bfg", "weapon_bfg", "bfg_mk2" },
}

local function choose_obit_key(weapon_string)
	if not weapon_string then return "generic" end
	local w = weapon_string:lower()
	for key, aliaslist in pairs(weapon_aliases) do
		for _, alias in ipairs(aliaslist) do
			if w:find(alias, 1, true) then  -- plain substring match (or use regex)
				return key
			end
		end
	end
	return "generic"
end

local function printOutObituary(obitID, victimPlayer, assailantPlayer)
	local setname = doom.obitstringset or "default"
	local entry = doom.obitStrings[setname]
		and doom.obitStrings[setname][obitID]
		or doom.obitStrings.default[obitID]

	local toPrint = ""

	if type(entry) == "table" then
		-- entry is an array; pick a random element
		local index = P_RandomKey(#entry) + 1
		toPrint = entry[index]
	else
		toPrint = entry
	end

	if toPrint == nil then
		print("OBITID " .. obitID .. " DOESN'T HAVE A STRING!")
		return
	end

	-- Resolve names safely
	local victimName = (victimPlayer and victimPlayer.name) or "SOMEONE"
	local killerName = (assailantPlayer and assailantPlayer.name) or "SOMEONE"

	-- Replace placeholders
	toPrint = toPrint:gsub("%%o", victimName)
	toPrint = toPrint:gsub("%%k", killerName)

	print(toPrint)
end

local function getName(mobj)
	return mobjinfo[mobj.type].doomname
end

local function getVictimWeapon(vplayer)
	local funcs = P_GetMethodsForSkin(vplayer)
	local victimWep
	if funcs.getCurWeapon then
		victimWep = funcs.getCurWeapon(vplayer)
	else
		victimWep = vplayer.doom.curwep
	end
	return victimWep
end

local function getAssailantWeapon(aplayer)
	local funcs = P_GetMethodsForSkin(aplayer)
	local assailantWep
	if funcs.getCurWeapon then
		assailantWep = funcs.getCurWeapon(aplayer)
	else
		assailantWep = aplayer.doom.curwep
	end
	return assailantWep
end

local function tryWeaponCombinationObituary(victimWep, assailantWep, vplayer, aplayer)
	if not victimWep or not assailantWep then return false end
	
	local victimKey = choose_obit_key(victimWep)
	local assailantKey = choose_obit_key(assailantWep)
	
	if victimKey == "generic" or assailantKey == "generic" then return false end
	
	-- Try the combination: victim_weapon_assailant_weapon
	local combinationKey = victimKey .. "_" .. assailantKey
	local setname = doom.obitstringset or "default"
	local entry = doom.obitStrings[setname]
		and doom.obitStrings[setname][combinationKey]
		or doom.obitStrings.default[combinationKey]
	
	if entry then
		printOutObituary(combinationKey, vplayer, aplayer)
		return true
	end
	
	return false
end

local function maybePrefixWrongTarget(obitID, vplayer, source)
	if not source.target.player then
		printOutObituary("monster_infighting", vplayer)
	end

	if source.target != vplayer.mo then
		printOutObituary(obitID .. "_wrongtarget", vplayer)
	else
		printOutObituary(obitID, vplayer)
	end
end

local function doPVPObituary(vplayer, aplayer, inflictor)
	if vplayer == aplayer then
		print("Victim was self!!! This wasn't part of the plan")
	end

	if (gametyperules & GTR_FRIENDLYFIRE) then
		local funcs = P_GetMethodsForSkin(aplayer)
		local obitWep
		if funcs.getCurWeapon then
			obitWep = choose_obit_key(funcs.getCurWeapon(aplayer))
		else
			obitWep = choose_obit_key(aplayer.doom.curwep)
		end
		if obitWep != "generic" then
			printOutObituary(obitWep, vplayer, aplayer)
		else
			printOutObituary("friendlyfire", vplayer, aplayer)
		end
	else
		local inflictorName = getName(inflictor)
		if inflictorName then
			inflictorName = inflictorName:lower()
			if inflictorName == "barrel" then
				maybePrefixWrongTarget("barrel_player", vplayer, source)
			end
		else
			-- Try weapon combination obituary first
			local victimWep = getVictimWeapon(vplayer)
			local assailantWep = getAssailantWeapon(aplayer)
			
			if not tryWeaponCombinationObituary(victimWep, assailantWep, vplayer, aplayer) then
				-- Fall back to assailant's weapon only
				printOutObituary(assailantWep, vplayer, aplayer)
			end
		end
	end
end

local function maybeDoSpecialObits(vplayer, source, inflictor)
	local funcs = P_GetMethodsForSkin(vplayer)
	local hasInvuln = funcs.hasPowerup(vplayer, "invulnerability")
	local hasPartialInvis = funcs.hasPowerup(vplayer, "invisibility")
	local isProjectile = source != inflictor
	local isBullet = inflictor.type == MT_DOOM_BULLETRAYCAST
	if isBullet then isProjectile = false end

	if hasPartialInvis then
		if isProjectile then
			local assailantName = getName(source)
			if assailantName == "mancubus" then
				printOutObituary("pinv_mancubus", vplayer)
			elseif assailantName == "revenant" then
				printOutObituary("pinv_revenant", vplayer)
			else
				printOutObituary("pinv_projectile", vplayer)
			end
		else
				printOutObituary("pinv_default", vplayer)
		end
	end
end

local function doPVEObituary(vplayer, source, inflictor)
	local assailantName = getName(source)
	local inflictorName = getName(inflictor)
	if inflictorName then
		inflictorName = inflictorName:lower()
	end
	if assailantName then
		assailantName = assailantName:lower()
	end
	if maybeDoSpecialObits(vplayer, source, inflictor) then
		return
	end
	if source.target == vplayer.mo then
		if inflictor == source then
			maybePrefixWrongTarget(assailantName .. "_melee", vplayer, source)
		elseif inflictorName  == "barrel" then
			if source.player then
				maybePrefixWrongTarget("barrel_player", vplayer, source)
			else
				maybePrefixWrongTarget("barrel_monster", vplayer, source)
			end
		else
			maybePrefixWrongTarget(assailantName, vplayer, source)
		end
	end
end

local function doSelfObituary(vplayer, source, inflictor, dtype)
	if source != inflictor and dtype == doom.damagetypes.explodesplash then
		printOutObituary("rocket_splash_self", vplayer)
	elseif inflictor then
		local assailantName = getName(inflictor)
		local funcs = P_GetMethodsForSkin(vplayer)
		local hasInvuln = funcs.hasPowerup(vplayer, "invulnerability")
		if inflictor == vplayer.mo then
			if hasInvuln then
				printOutObituary("invuln_self", vplayer)
			else
				printOutObituary("self", vplayer)
			end
		elseif assailantName then
			assailantName = assailantName:lower()
			printOutObituary(assailantName, vplayer)
		else
			printOutObituary("self", vplayer)
		end
	else
		printOutObituary("self", vplayer)
	end
end

local function doSourcelessObituary(vplayer, _, _, dtype)
	if dtype == doom.damagetypes.fall then
		printOutObituary("fall", vplayer)
	elseif dtype == doom.damagetypes.crush then
		printOutObituary("crush", vplayer)
	elseif dtype == doom.damagetypes.slime then
		printOutObituary("slime", vplayer)
	elseif dtype == doom.damagetypes.fire then
		printOutObituary("fire", vplayer)
	elseif dtype == doom.damagetypes.exit then
		printOutObituary("exit", vplayer)
	else
		printOutObituary("generic", vplayer)
	end
end

function doom.doObituary(target, source, inflictor, dtype)
	if not target.player then return end

	local vplayer = target.player

	if not source then
		doSourcelessObituary(vplayer, source, inflictor, dtype)
		return
	end

	if source.player then
		if dtype == doom.damagetypes.telefrag then
			local funcs = P_GetMethodsForSkin(vplayer)
			local hasInvuln = funcs.hasPowerup(vplayer, "invulnerability")
			if hasInvuln then
				printOutObituary("invuln_telefrag_player", target.player, source.player)
			else
				printOutObituary("telefrag_player", target.player, source.player)
			end
		elseif source.player == target.player then
			doSelfObituary(target.player, source, inflictor, dtype)
		else
			doPVPObituary(target.player, source.player, inflictor, dtype)
		end
	elseif type(source) == "userdata" and userdataType(source) == "mobj_t" then
			local funcs = P_GetMethodsForSkin(vplayer)
			local hasInvuln
			if funcs.hasPowerup then
				hasInvuln = funcs.hasPowerup(vplayer, "invulnerability")
			else
				hasInvuln = vplayer.doom.powers[pw_invulnerability] > 0
			end
		if dtype == doom.damagetypes.telefrag then
			if hasInvuln then
				printOutObituary("invuln_telefrag", target.player, source.player)
			else
				printOutObituary("telefrag", target.player, source.player)
			end
		else
			doPVEObituary(target.player, source, inflictor, dtype)
		end
	end
end