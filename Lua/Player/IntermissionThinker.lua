DOOM_Freeslot("sfx_pistol", "sfx_sgcock")

local doom1Pars = {
	{30, 75, 120, 90, 165, 180, 180, 30, 165},
	{0, 30, 75, 120, 90, 165, 180, 180, 30, 165},
	{0, 90, 90, 90, 120, 90, 360, 240, 30, 170},
	{0, 90, 45, 90, 150, 90, 90, 165, 30, 135},
}

local doom2Pars = {
	30, 90, 120, 120, 90, 150, 120, 120, 270, 90,
	210, 150, 150, 150, 210, 150, 320, 150, 210, 150,
	240, 150, 180, 150, 150, 300, 330, 420, 300, 180,
	120, 30
}

-- Modern mapes use DeHackEd or MAPINFO

local Doom2MapToDoom1 = {
	-- Episode 1
	[1]  = {ep = 1, map = 1},
	[2]  = {ep = 1, map = 2},
	[3]  = {ep = 1, map = 3},
	[4]  = {ep = 1, map = 4},
	[5]  = {ep = 1, map = 5},
	[6]  = {ep = 1, map = 6},
	[7]  = {ep = 1, map = 7},
	[8]  = {ep = 1, map = 8},
	[41] = {ep = 1, map = 9}, -- secret
	
	-- Episode 2
	[9]  = {ep = 2, map = 1},
	[10] = {ep = 2, map = 2},
	[11] = {ep = 2, map = 3},
	[12] = {ep = 2, map = 4},
	[13] = {ep = 2, map = 5},
	[14] = {ep = 2, map = 6},
	[15] = {ep = 2, map = 7},
	[16] = {ep = 2, map = 8},
	[42] = {ep = 2, map = 9}, -- secret
	
	-- Episode 3
	[17] = {ep = 3, map = 1},
	[18] = {ep = 3, map = 2},
	[19] = {ep = 3, map = 3},
	[20] = {ep = 3, map = 4},
	[21] = {ep = 3, map = 5},
	[22] = {ep = 3, map = 6},
	[23] = {ep = 3, map = 7},
	[24] = {ep = 3, map = 8},
	[43] = {ep = 3, map = 9}, -- secret
	
	-- Episode 4
	[25] = {ep = 4, map = 1},
	[26] = {ep = 4, map = 2},
	[27] = {ep = 4, map = 3},
	[28] = {ep = 4, map = 4},
	[29] = {ep = 4, map = 5},
	[30] = {ep = 4, map = 6},
	[31] = {ep = 4, map = 7},
	[32] = {ep = 4, map = 8},
	[44] = {ep = 4, map = 9}, -- secret
}

/*
SECRET EXITS:
E1M3 = E1M9
E2M5 = E2M9
E3M6 = E3M9
E4M2 = E4M9
MAP15 = MAP31
MAP31 = MAP32
Secret exits outside of the above maps restart the current map.
*/

-- TODO: MAPINFO has these set, usually... Make sure to add support for those sometime in the future
doom.secretExits = $ or {
	-- DOOM 1
	[3] = 41,
	[13] = 42,
	[22] = 43,
	[26] = 44,

	-- DOOM II
	[15] = 31,
	[31] = 32,
}

-- print( .. "% KILLS")
addHook("PlayerThink", function(player)
	if not doom.intermission or player.doom.intstate < 0 then
		player.doom.cnt_time = 0
		player.doom.cnt_par = 0
		player.cnt_kills = {1, 1, 1}
		return
	end
	if player.doom.intstate == 2 then
		player.cnt_kills[1] = $ + 2
		local max
		if doom.killcount <= 0 then
			max = 100
		else
			max = (player.doom.killcount * 100) / (doom.killcount)
		end

		if not (player.doom.bcnt & 3) then
			S_StartSound(nil, sfx_pistol, player)
		end
		
		if player.cnt_kills[1] >= max then
			player.cnt_kills[1] = max
			S_StartSound(nil, sfx_barexp)
			player.doom.intstate = $ + 1
		end
	elseif player.doom.intstate == 4 then
		player.cnt_kills[2] = $ + 2
		local max
		if doom.itemcount <= 0 then
			max = 100
		else
			max = (doom.items * 100) / (doom.itemcount)
		end

		if not (player.doom.bcnt & 3) then
			S_StartSound(nil, sfx_pistol, player)
		end
		
		if player.cnt_kills[2] >= max then
			player.cnt_kills[2] = max
			S_StartSound(nil, sfx_barexp, player)
			player.doom.intstate = $ + 1
		end
	elseif player.doom.intstate == 6 then
		player.cnt_kills[3] = $ + 2
		local max
		if doom.secretcount <= 0 then
			max = 100
		else
			max = (doom.secrets * 100) / (doom.secretcount)
		end

		if not (player.doom.bcnt & 3) then
			S_StartSound(nil, sfx_pistol, player)
		end
		
		if player.cnt_kills[3] >= max then
			player.cnt_kills[3] = max
			S_StartSound(nil, sfx_barexp, player)
			player.doom.intstate = $ + 1
		end
	elseif player.doom.intstate == 8 then
		player.doom.cnt_time = ($ or 0) + 3
		player.doom.cnt_par = ($ or 0) + 3
		local parTarg = 0

		if player.doom.cnt_time >= player.doom.wintime / TICRATE then
			player.doom.cnt_time = player.doom.wintime / TICRATE
		end

		if not (player.doom.bcnt & 3) then
			S_StartSound(nil, sfx_pistol, player)
		end

		if doom.isdoom1 then
			local Doom1Map = Doom2MapToDoom1[gamemap]
			local ep = Doom1Map.ep
			local mis = Doom1Map.map
			parTarg = doom1Pars[ep] and doom1Pars[ep][mis] or 0
		else
			parTarg = doom2Pars[gamemap] or $
		end
		if player.doom.cnt_par >= parTarg then
			player.doom.cnt_par = parTarg
			if player.doom.cnt_time >= player.doom.wintime / TICRATE then
				player.doom.cnt_time = player.doom.wintime / TICRATE
				S_StartSound(nil, sfx_barexp, player)
				player.doom.intstate = $ + 1
			end
		end
	elseif player.doom.intstate == 10 then
		S_StartSound(nil, sfx_sgcock, player)
		-- I don't actually have a surefire way to get this done during THIS specific intstate,
		-- So defer to an intstate not present originally
		if not doom.isdoom1 then
			player.doom.intpause = 2*TICRATE
			player.doom.intstate = $ + 1
		else
			player.doom.intpause = 4*TICRATE
			player.doom.intstate = $ + 1
		end
	elseif player.doom.intstate == 12 then
		player.doom.intpause = TICRATE
		player.doom.intstate = -1
		doom.intermission = false
		player.doom.notrigger = true
		local nextLev
		if doom.didSecretExit then
			nextLev = doom.secretExits[gamemap]
		else
			nextLev = mapheaderinfo[gamemap].nextlevel or gamemap + 1
		end
		G_SetCustomExitVars(nextLev, 1, GT_DOOM, true)
		G_ExitLevel()
	elseif (player.doom.intstate & 1) then
		player.doom.intpause = ($ or 1) - 1
		if not player.doom.intpause
			player.doom.intstate = $ + 1
			player.doom.intpause = TICRATE
		end
		player.doom.bcnt = 0
	end
	player.doom.bcnt = ($ or 0) + 1
end)