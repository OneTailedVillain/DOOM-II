freeslot("sfx_lttpds")

addHook("PlayerThink", function(player)
	local funcs = P_GetMethodsForSkin(player)
	if not funcs.hasWeapon(player, "pegasusboots") then return end
	if not (player.cmd.buttons & BT_FIRENORMAL) then
		player.doom.pegasuschargelock = false
		player.doom.pegasuscharging = false
		return
	elseif not player.doom.pegasuscharging then
		if player.doom.pegasuschargelock then return end
		player.doom.pegasuschargetime = TICRATE + 1
		player.doom.pegasuscharging = true
		player.doom.pegasuschargeangle = player.mo.angle
		S_StartSound(player.mo, sfx_lttpds)
	end

	player.doom.pegasuschargetime = $ - 1
	player.mo.angle = player.doom.pegasuschargeangle
	local ct = player.doom.pegasuschargetime
	if not (ct % 4) then
		S_StartSound(player.mo, sfx_lttpds)
	end

	if ct < 0 then
		P_InstaThrust(player.mo, player.doom.pegasuschargeangle, 24*FRACUNIT)
	end
end)

addHook("MobjMoveBlocked", function(movingmobj, mobj, line)
	local player = movingmobj.player
	if not player.doom.pegasuscharging then return end
	if mobj then
		return
	end

	if line then
		player.doom.pegasuscharging = false
		player.doom.pegasuschargelock = true
		S_StartSound(movingmobj, sfx_lttpbd)
		P_SetObjectMomZ(movingmobj, FRACUNIT*7, false)
		P_InstaThrust(movingmobj, player.doom.pegasuschargeangle, -6*FRACUNIT)
		P_MovePlayer(player)
		return
	end
end, MT_PLAYER)