DOOM_Freeslot("sfx_pistol", "sfx_sgcock")

doom.doom1Pars = {
	{30, 75, 120, 90, 165, 180, 180, 30, 165},
	{0, 30, 75, 120, 90, 165, 180, 180, 30, 165},
	{0, 90, 90, 90, 120, 90, 360, 240, 30, 170},
	{0, 90, 45, 90, 150, 90, 90, 165, 30, 135},
}

doom.doom2Pars = {
	30, 90, 120, 120, 90, 150, 120, 120, 270, 90,
	210, 150, 150, 150, 210, 150, 320, 150, 210, 150,
	240, 150, 180, 150, 150, 300, 330, 420, 300, 180,
	120, 30
}

-- Modern mapes use DeHackEd or MAPINFO

-- Build mapping from global MAP number -> (episode, map) using 9 maps per episode.
doom.Doom2MapToDoom1 = {}
do
	-- canonical mapping for MAP01..MAP36 (E1M1..E4M9)
	for n = 1, 36 do
		local ep = ((n - 1) / 9) + 1
		local mp = ((n - 1) % 9) + 1
		doom.Doom2MapToDoom1[n] = { ep = ep, map = mp }
	end
end

rawset(_G, "DOOM_Doom2MapIDToDoom1MapID", function(map)
	local index = doom.Doom2MapToDoom1[map]
	return "E" .. tostring(index.ep or 0) .. "M" .. tostring(index.map or 0)
end)

/*
SECRET EXITS (new MAP numbering):
E1M3 -> E1M9
E2M5 -> E2M9
E3M6 -> E3M9
E4M2 -> E4M9
Legacy DOOM II secret mappings (MAP15->MAP31, MAP31->MAP32) are kept below
where applicable. Secret exits outside of the above maps restart the current map.
*/

-- TODO: MAPINFO has these set, usually... Make sure to add support for those sometime in the future
doom.secretExits = $ or {
	-- DOOM 1
	[3]  = 9,
	[13] = 18,
	[22] = 27,
	[26] = 36,

	-- DOOM II
	[15] = 31,
	[31] = 32,
}

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
			local Doom1Map = doom.Doom2MapToDoom1[gamemap]
			local ep = Doom1Map.ep
			local mis = Doom1Map.map
			parTarg = doom.doom1Pars[ep] and doom.doom1Pars[ep][mis] or 0
		else
			parTarg = doom.doom2Pars[gamemap] or $
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
		local funcs = P_GetMethodsForSkin(player)
		if funcs.onNowEntering then
			funcs.onNowEntering(player)
		end
		S_StartSound(nil, sfx_sgcock, player)
		player.doom.intstate = $ + 1
		-- I don't actually have a surefire way to get this done during THIS specific intstate,
		-- So defer to an intstate not present originally
		if doom.isdoom1 then
			player.doom.intpause = 4*TICRATE
		else
			player.doom.intpause = 2*TICRATE
		end
	elseif player.doom.intstate == 12 then
		player.doom.intpause = TICRATE
		if doom.intermission then
			player.doom.notrigger = true
			DOOM_NextLevel()
		end
	elseif (player.doom.intstate & 1) then
		player.doom.intpause = ($ or 1) - 1
		if not player.doom.intpause then
			player.doom.intstate = $ + 1
			player.doom.intpause = TICRATE
		end
		player.doom.bcnt = 0
	end
	player.doom.bcnt = ($ or 0) + 1
end)