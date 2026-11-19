local PLATWAIT = 3
local PLATSPEED = FRACUNIT

DOOM_Freeslot("sfx_doropn", "sfx_dorcls", "sfx_bdopn", "sfx_bdcls",
"sfx_stnmov")

local function stop_plats_by_tag(tag)
	if tag == nil then return end
	for _, entry in ipairs(doom.thinkerlist) do
		local v = entry.data
		if entry.active and v and v.type == "floor" and v.isPlatLike and v.tag == tag then
			v.stasis = true
		end
	end
end

local function resume_plats_by_tag(tag)
	if tag == nil then return end
	for _, entry in ipairs(doom.thinkerlist) do
		local v = entry.data
		if entry.active and v and v.type == "floor" and v.isPlatLike and v.tag == tag then
			v.stasis = false
		end
	end
end

local function getNextSector(line, sector)
	if line.frontsector == sector then
		return line.backsector
	elseif line.backsector == sector then
		return line.frontsector
	end
	return nil
end

local function P_FindMinSurroundingLight(sector, max)
	local min = max

	for i = 0, #sector.lines-1 do
		local line = sector.lines[i]
		local check = getNextSector(line, sector)

		if check and check.lightlevel < min then
			min = check.lightlevel
		end
	end

	return min
end

local GLOWSPEED = 8
local STROBEBRIGHT = 5
local FASTDARK = 15
local SLOWDARK = 35

local function P_SpawnStrobeFlash(sector, fastOrSlow, inSync)

	local flash = {
		type = "strobe",
		darktime = fastOrSlow,
		brighttime = STROBEBRIGHT,
		maxlight = sector.lightlevel,
		minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
		count = 0
	}

	if flash.minlight == flash.maxlight then
		flash.minlight = 0
	end

	flash.count = inSync and 1 or ((DOOM_Random() & 7) + 1)

	doom.addThinker(sector, flash)
end

doom.mapSaveStates = {}

-- Dump likely necessary non-player object data into doom.mapSaveStates[gamemap]
-- Shitty, but needed for Strife: Quest for the Sigil, as SRB2 doesn't have
-- Something akin to is all on it's lonesome. This is because SRB2 sucks as a
-- Game engine and should never have anything fun done to it ever again.
local function toStudyForADrugTestSheTookAllOfTheDrugs(gamemap)
	doom.mapSaveStates[gamemap] = {}
	for mobj in mobjs.iterate() do
		if mobj.type == MT_PLAYER then continue end
		table.insert(doom.mapSaveStates[gamemap], {
			doom = mobj.doom,
			state = mobj.state,
			tics = mobj.tics,
			sprite = mobj.sprite,
			frame = mobj.frame,
			movedir = mobj.movedir,
			movecount = mobj.movecount,
			target = mobj.target,
			tracer = mobj.tracer,
			reactiontime = mobj.reactiontime,
			threshold = mobj.threshold,
			fuse = mobj.fuse,
			scale = mobj.scale,
			destscale = mobj.destscale,
			scalespeed = mobj.scalespeed,
			spawnpoint = mobj.spawnpoint, -- Likely needed? Will see in netgame testing
			skin = mobj.skin,
			color = mobj.color,
			flags = mobj.flags,
			flags2 = mobj.flags2,
			eflags = mobj.eflags,
			momx = mobj.momx,
			momy = mobj.momy,
			momz = mobj.momz,
			radius = mobj.radius,
			height = mobj.height,
			alpha = mobj.alpha,
			renderflags = mobj.renderflags,
			sprite2 = mobj.sprite2,
			x = mobj.x,
			y = mobj.y,
			z = mobj.z,
			angle = mobj.angle,
			type = mobj.type
		})
	end
end

-- Turn all non-players into lost media and replace them with the abov
local function P_RestoreMapState(gamemap)
	if not (doom.mapSaveStates and doom.mapSaveStates[gamemap]) then
		return
	end

	local curSave = doom.mapSaveStates[gamemap]
	local fuckingMobjArrayToReuseShitIn = {}

	for mobj in mobjs.iterate() do
		if mobj.type == MT_PLAYER then continue end
		P_RemoveMobj(mobj)
	end

	for _, data in pairs(doom.mapSaveStates[gamemap]) do
		local mobj = P_SpawnMobj(data.x, data.y, data.z, data.type)
		if not mobj then print("P_SpawnMobj failed!") continue end

		mobj.doom = data.doom
		mobj.state = data.state
		mobj.tics = data.tics
		mobj.sprite = data.sprite
		mobj.frame = data.frame
		mobj.movedir = data.movedir
		mobj.movecount = data.movecount
		mobj.target = data.target
		mobj.tracer = data.tracer
		mobj.reactiontime = data.reactiontime
		mobj.threshold = data.threshold
		mobj.fuse = data.fuse
		mobj.scale = data.scale
		mobj.destscale = data.destscale
		mobj.scalespeed = data.scalespeed
		mobj.spawnpoint = data.spawnpoint -- Likely needed? Will see in netgame testing
		if data.skin then mobj.skin = data.skin end
		mobj.color = data.color
		mobj.flags = data.flags
		mobj.flags2 = data.flags2
		mobj.eflags = data.eflags
		mobj.momx = data.momx
		mobj.momy = data.momy
		mobj.momz = data.momz
		mobj.radius = data.radius
		mobj.height = data.height
		mobj.alpha = data.alpha
		mobj.renderflags = data.renderflags
		mobj.sprite2 = data.sprite2
		P_SetOrigin(mobj, data.x, data.y, data.z)
	end

end

local SCROLL_SHIFT = 5
local CARRYFACTOR = FRACUNIT*15/16
local ORIG_FRICTION = 0xE800

doom.onMaploadHandlers = {
	scroll = function(line, data)
		if type(data.direction) == "string" then
			if data.direction == "left" then
				data.scrx = -FRACUNIT
				data.scry = 0

			elseif data.direction == "right" then
				data.scrx = FRACUNIT
				data.scry = 0

			elseif data.direction == "line" then
				// Preserve sign manually
				local sx = (line.dx < 0) and -1 or 1
				local sy = (line.dy < 0) and -1 or 1

				local adx = abs(line.dx)
				local ady = abs(line.dy)

				data.scrx = (adx >> SCROLL_SHIFT) * sx
				data.scry = (ady >> SCROLL_SHIFT) * sy
			end

			data.carryx = FixedMul(data.scrx, CARRYFACTOR)
			data.carryy = FixedMul(data.scry, CARRYFACTOR)
		end
	end,

	---@param line line_t
	transparency = function(line, data)
		-- yeah nice FUCKING gate for no reason SRB2
		/*
		if line.tag == 0 then
			line.alpha = FRACUNIT/2
		else
			for line in lines.tagged(line.tag) do
				line.alpha = FRACUNIT/2
			end
		end
		*/
	end
}

local function P_SpawnGlowingLight(sector)

	local glow = {
		type = "glow",
		minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
		maxlight = sector.lightlevel,
		direction = -1
	}

	doom.addThinker(sector, glow)
end

local function P_SpawnLightFlash(sector)

	local flash = {
		type = "flash",
		maxlight = sector.lightlevel,
		minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
		maxtime = 64,
		mintime = 7,
		count   = (DOOM_Random() & 64) + 1,
	}

	doom.addThinker(sector, flash)
end

local function SkillMaskFor(skill)
	if skill <= 2 then
		return 1
	elseif skill == 3 then
		return 2
	end
	return 4
end

-- Get the spawn point for a player, based on their slot and the current map's spawnpoints
function doom.getPlayerSpawn(player)
	local spawnpoints = doom.spawnpoints

	-- Spawn selection methods
	local function getCoopSpawn()
		local count = #spawnpoints.player
		if count == 0 then return end

		local slot = #player
		for i = 0, count - 1 do
			local checkslot = ((slot - 1 + i) % count) + 1
			local list = spawnpoints.player[checkslot]
			if list and list[#list] then
				-- Get the total length of the list and spawn in voodoo dolls on all non-last entries
				for j = 1, #list - 1 do
					local spawn = list[j]
					local doll = P_SpawnMobj(
						spawn.x,
						spawn.y,
						spawn.z,
						MT_DOOM_VOODOODOLL
					)

					if doll then
						doll.angle = spawn.angle
					end
				end
				return list[#list]
			end
		end
	end

	local function getDeathmatchSpawn()
		local list = spawnpoints.deathmatch
		-- if only one deathmatch spawn exists (likely due to not being a deathmatch map), then fall out and allow the next comparison to be used instead
		if #list == 1 then
			return nil
		end

		if #list > 0 then
			return list[P_RandomKey(#list) + 1]
		end
	end

	local function getCTFSpawn()
		for _, list in pairs(spawnpoints.ctf) do
			if list and #list > 0 then
				return list[P_RandomKey(#list) + 1]
			end
		end
	end

	local function getTeamSpawn()
		local team = player.team
		local list = team and spawnpoints.ctf[team]
		if list and #list > 0 then
			return list[P_RandomKey(#list) + 1]
		end
	end

	-- Select the priority order.
	local order

	if gametyperules & GTR_TEAMS then
		order = {getTeamSpawn, getDeathmatchSpawn, getCoopSpawn}
	elseif gametyperules & GTR_RINGSLINGER then
		order = {getDeathmatchSpawn, getCTFSpawn, getCoopSpawn}
	else
		order = {getCoopSpawn, getDeathmatchSpawn, getCTFSpawn}
	end

	-- Try each spawn type in priority order.
	for _, getSpawn in ipairs(order) do
		local spawn = getSpawn()
		if spawn then
			return spawn
		end
	end

	-- No spawns exist! Just build something up based on the first mapthing
	for mthing in mapthings.iterate do
		print("WARNING: Current map has no player starts. Falling back to first thing...")
		return {
			x = mthing.x * FRACUNIT,
			y = mthing.y * FRACUNIT,
			z = P_FloorzAtPos(mthing.x * FRACUNIT, mthing.y * FRACUNIT, 0, 0),
			angle = FixedAngle(mthing.angle * FRACUNIT),
			mthing = mthing
		}
	end

		print("WARNING: Current map has no mapthings. Falling back to origin...")
		return {
			x = 0 * FRACUNIT,
			y = 0 * FRACUNIT,
			z = P_FloorzAtPos(0 * FRACUNIT, 0 * FRACUNIT, 0, 0),
			angle = FixedAngle(0 * FRACUNIT),
			mthing = nil
		}
end

addHook("MapLoad", function(mapid)
	doom.kills = 0
	doom.killcount = 0
	doom.items = 0
	doom.itemcount = 0
	doom.secrets = 0
	doom.secretcount = 0
	doom.textscreen.active = false
	doom.intermission = false
	doom.midGameTitlescreen = false

	-- Do this first so savestates get their due process
	P_RestoreMapState(mapid)
	local trustHexenData = false
	if doom.hexen_mapdata and doom.hexen_mapdata[gamemap] then
		trustHexenData = true
	end

	for mobj in mobjs.iterate() do
		local mthing = mobj.spawnpoint
		if not mthing then
			continue
		end

		-- If true, then we silently tuck this object under our boot
		local multiplayerhide = not multiplayer

		-- Who wants if statements purely dependent on other variables for dinner!!
		if not multiplayerhide then
			-- We only really care about non-deathmatch gametypes...
			-- Monsters will kill themselves on their own
			if not G_RingSlingerGametype() then
				multiplayerhide = not (mobj.doom.flags & DF_COUNTKILL)
			end
		end

		if (mthing.z & 1) and multiplayerhide then
			P_RemoveMobj(mobj)
			continue
		end

		local needed = SkillMaskFor(doom.gameskill)
		if not (mthing.options & needed) then
			P_RemoveMobj(mobj)
			continue
		end

		mobj.flags2 = $ & ~MF2_OBJECTFLIP
		mobj.eflags = $ & ~MFE_VERTICALFLIP
		if not (mobj.info.flags & MF_SPAWNCEILING) then
			mobj.z = P_FloorzAtPos(mobj.x, mobj.y, mobj.z, 0) -- mobj.floorz
		end
	end

	-- Call everything off! We won't need these in whatever map we're jumping to
	doom.linespecials = {}
	doom.hexen_linespecials = {}
	doom.hexen_lineargs = {}
	doom.linebackups = {}
	doom.thinkerlist = {}
	doom.thinkermap = {}
	doom.torespawn = {}
	doom.sectorspecials = {}
	doom.sectorbackups = {}
	doom.sectordata = {}
	doom.switches = {}

	doom.spawnpoints = {
		player = {},
		deathmatch = {},
		ctf = {},
		--#ifdef STRIFE
		rift = {},
		--#endif
	}
	local coopspawns = #doom.playerStartMap

	for i = 1, coopspawns do
		doom.spawnpoints.player[i] = {}
	end

	-- Determine episode based on game mode
	local episode = 1
	if doom.gamemode == "registered" then
		episode = 2
	elseif doom.gamemode == "commercial" then
		episode = 3
	end

	local index = 1

	-- Iterate through switch texture names
	for i, switchTex in ipairs(doom.switchTexNames) do
		-- Check for end marker (episode == 0)
		if switchTex[3] == 0 then
			doom.numswitches = (index - 1) / 2
			doom.switches[index] = -1
			break
		end

		-- Add switches for current episode or earlier
		if switchTex[3] <= episode then
			doom.switches[index] = R_TextureNumForName(switchTex[1])
			index = index + 1
			doom.switches[index] = R_TextureNumForName(switchTex[2])
			index = index + 1
		end
	end

	local prefGravity = tonumber(mapheaderinfo[gamemap].doomiigravity) or doom.defaultgravity

	local specialtospecialfortagged = {
		scroll = "sectorscroll"
	}

	local itsalmostlikeibutnotreally = -1
	for line in lines.iterate do
		itsalmostlikeibutnotreally = $ + 1
		if trustHexenData or line.special <= 940 then
			if trustHexenData then
				local short = doom.hexen_mapdata[gamemap].linedefs[itsalmostlikeibutnotreally]
				if short then
				doom.hexen_linespecials[line] = short.special
					doom.hexen_lineargs[line] = {
						short.arg1,
						short.arg2,
						short.arg3,
						short.arg4,
						short.arg5
					}
				end
			end
			doom.linespecials[line] = 0
			continue
		end

		doom.linespecials[line] = line.special - 941

		local def = doom.lineActions[doom.linespecials[line]]
		if def and def.activationType == "always" then
			if def.target == "tagged" then
				for sector in sectors.tagged(line.tag) do
					local otherdef = deepcopy(def)
					if doom.onMaploadHandlers[otherdef.type] then
						doom.onMaploadHandlers[otherdef.type](line, otherdef)
					else
						print("No handler for type " .. tostring(otherdef.type))
					end
					local tagremap = specialtospecialfortagged[otherdef.type]
					if tagremap then
						otherdef.type = tagremap
					end
					doom.addThinker(sector, otherdef)
				end
			else
				doom.onMaploadHandlers[def.type](line, def)
				doom.addThinker(line, def)
			end
		end
	end

	local lightThinkers = {
		[1] = {P_SpawnLightFlash},
		[2] = {P_SpawnStrobeFlash, FASTDARK, 0},
		[3] = {P_SpawnStrobeFlash, SLOWDARK, 0},
		[4] = {P_SpawnStrobeFlash, FASTDARK, 0},
		[8] = {P_SpawnGlowingLight},
		[12] = {P_SpawnStrobeFlash, SLOWDARK, 1},
		[13] = {P_SpawnStrobeFlash, FASTDARK, 1},
	}

	for sector in sectors.iterate do
		doom.sectorspecials[sector] = sector.special
		doom.sectorbackups[sector] = {
			light = deepcopy(sector.lightlevel),
			floor = deepcopy(sector.floorheight),
			ceil = deepcopy(sector.ceilingheight)
		}
		if sector.special == 9 then
			doom.secretcount = ($ or 0) + 1
		end
		if lightThinkers[sector.special] then
			local light = lightThinkers[sector.special]
			light[1](sector, light[2], light[3], light[4])
		end
		sector.special = 0
		sector.flags = 0
		sector.specialflags = 0
		sector.damagetype = 0
		--sector.gravity = -prefGravity
	end

	gravity = prefGravity

	-- Take out [mthing] and replace it with the MT constant [newType]
	---@param mthing mapthing_t
	local function replaceMapthing(mthing, newType)
		if not newType then return end

		local x = mthing.x*FRACUNIT
		local y = mthing.y*FRACUNIT
		local z

		if mthing.mobj and (mthing.mobj.info.flags & MF_SPAWNCEILING) then
			z = P_CeilingzAtPos(x, y, 0, 0)
		else
			z = P_FloorzAtPos(x, y, 0, 0)
		end

		local range = #mobjinfo - 1
		if newType > range then
			print("NOTICE: mobj type " .. newType .. " out of range (0 - " .. range .. ") at " .. x/FU .. ", " .. y/FU .. ", " .. z/FU)
			return
		end

		if mthing.mobj then P_RemoveMobj(mthing.mobj) end
		if not (gametyperules & GTR_SPAWNENEMIES) then
			local objinfo = mobjinfo[newType]
			if (objinfo.flags & MF_ENEMY) then
				return false
			end
		end

		local teleman = P_SpawnMobj(x, y, z, newType)
		teleman.angle = FixedAngle(mthing.angle*FRACUNIT)
		if not (teleman and teleman.valid) then
			print("replaceMapthing: Overridden object invalidated itself")
			return false
		end
		-- The overridden mapthing won't be considered for kill and item counts, so adjust those here
		if teleman and ((teleman.info and teleman.info.doomflags or 0) & DF_COUNTKILL) then
			doom.killcount = ($ or 0) + 1
		end
		if teleman and ((teleman.info and teleman.info.doomflags or 0) & DF_COUNTITEM) then
			doom.itemcount = ($ or 0) + 1
		end
		return teleman
	end

	local playerStartLookup = {}
	for slot, doomednum in ipairs(doom.playerStartMap) do
		playerStartLookup[doomednum] = slot
	end

	for mthing in mapthings.iterate do
		--#ifndef DOOM
		-- Also modify thing flags according to specification if the thing is valid. and stuff
		if mthing.mobj then
			local mobj = mthing.mobj
			local curFlags = mthing.options

			--#ifdef STRIFE
			-- For some reason, Strife decided to move Ambush on bit 5 and use bit 3 for standing still
			local MTF_AMBUSH = 0x0020
			local MTF_STANDSTILL = 0x0008
			local MTF_FRIENDLY = 0x0040
			local MTF_25TRANS = 0x0100
			local MTF_INVISIBLE = 0x0200
			if curFlags & MTF_AMBUSH then
				mobj.flags2 = $ | MF2_AMBUSH
			else
				mobj.flags2 = $ & ~MF2_AMBUSH
			end

			if curFlags & MTF_STANDSTILL then
				mobj.doom = $ or {flags = 0}
				mobj.doom.flags = $ | DF_STANDSTILL
			end
			--#endif
		end
		--#endif

		local forceZ = INT32_MIN
		if trustHexenData and mthing.mobj then
			local thingshit = doom.hexen_mapdata[gamemap].things
			if thingshit[#mapthing] then
				forceZ = thingshit[#mapthing].z
				P_SetOrigin(mapthing.mobj, mapthing.mobj.x, mapthing.mobj.y, mapthing.mobj.z + (forceZ * FU))
			end
		end

		local needed = SkillMaskFor(doom.gameskill)
		local skipThis = not (mthing.options & needed)
		if not skipThis then skipThis = (mthing.z & 1) and not multiplayer end
		--#ifdef STRIFE
		if mthing.type >= 118 and mthing.type < 128 then
			local spot = mthing.type - 118
			doom.spawnpoints.rift[spot + 1] = {
				x = mthing.x * FRACUNIT,
				y = mthing.y * FRACUNIT,
				angle = FixedAngle(mthing.angle * FRACUNIT),
				z = forceZ
			}
			skipThis = false
		end
		--#endif
		if skipThis then
			if mthing.mobj then P_RemoveMobj(mthing.mobj) end
			continue
		end

		-- "unfortunately the game is an asshole and sets"
		-- "[the multiplayer] spawnpoint mapthing IDs to zero, ambiguating them"
		-- There is literally no way to know exactly what mapthing ID is what,
		-- So they're all mapthing 34 now :3
		if not tth_doombuild then
			if mthing.type == 0 then
				mthing.type = 34
			end
		end

		-- Diagnostic: warn about thing types 1-35 that are not player starts
		-- and have no replacement entry
		if mthing.type >= 1 and mthing.type <= 35 then
			if not playerStartLookup[mthing.type] and not doom.mthingReplacements[mthing.type] then
				print(string.format("DP: Potentially missing thing type '%d' placed at (%d, %d)",
					mthing.type, mthing.x, mthing.y))
			end
		end

		local override = doom.callHook(
			"MapThingSpawn",
			doom.hookTypes.lastfunc,
			mthing
		)

		if override == false then
			continue -- block spawn completely
		elseif override ~= nil then
			mthing.type = override -- override doomednum
		end

		if not (doom.mapSaveStates and doom.mapSaveStates[gamemap]) then
			if doom.mthingReplacements[mthing.type] then
				replaceMapthing(mthing, doom.mthingReplacements[mthing.type])
			-- extrainfo eats 4 mapthing type bits, so undo that if extrainfo is present
			elseif mthing.extrainfo then
				replaceMapthing(mthing, mthing.type + (mthing.extrainfo << 4))
			end
		end

		-- Player starts
		local startslot = playerStartLookup[mthing.type]

		if startslot then
			if not doom.spawnpoints.player[startslot] then
				doom.spawnpoints.player[startslot] = {}
			end

			table.insert(doom.spawnpoints.player[startslot], {
				x = mthing.x * FRACUNIT,
				y = mthing.y * FRACUNIT,
				z = P_FloorzAtPos(mthing.x*FRACUNIT, mthing.y*FRACUNIT, 0, 0),
				angle = FixedAngle(mthing.angle * FRACUNIT),
				mthing = mthing
			})
		-- Deathmatch starts
		elseif mthing.type == doom.deathmatchDoomEdNum then
			table.insert(doom.spawnpoints.deathmatch, {
				x = mthing.x * FRACUNIT,
				y = mthing.y * FRACUNIT,
				z = P_FloorzAtPos(mthing.x*FRACUNIT, mthing.y*FRACUNIT, 0, 0),
				angle = FixedAngle(mthing.angle * FRACUNIT),
				mthing = mthing
			})
		-- CTF starts; following CTF standard
		elseif mthing.type == 5080 or mthing.type == 5081 or mthing.type == 5083 or mthing.type == 5084 then
			-- CTF 4team starts skip 5082
			local team = mthing.type - 5080 + 1
			if mthing.type > 5082 then
				team = team - 1
			end

			if not doom.spawnpoints.ctf[team] then
				doom.spawnpoints.ctf[team] = {}
			end

			table.insert(doom.spawnpoints.ctf[team], {
				x = mthing.x * FRACUNIT,
				y = mthing.y * FRACUNIT,
				z = P_FloorzAtPos(mthing.x*FRACUNIT, mthing.y*FRACUNIT, 0, 0),
				angle = FixedAngle(mthing.angle * FRACUNIT),
				mthing = mthing
			})
		end

		if mthing.mobj and ((mthing.mobj.info.doomflags or 0) & DF_COUNTKILL) then
			doom.killcount = ($ or 0) + 1
		end
		if mthing.mobj and ((mthing.mobj.info.doomflags or 0) & DF_COUNTITEM) then
			doom.itemcount = ($ or 0) + 1
		end
	end

	for player in players.iterate do
		player.doom = $ or {}
		player.doom.kills = 0
		player.doom.secrets = 0
		player.doom.items = 0
		player.doom.intstate = -1
		player.doom.notrigger = 0
		player.doom.frags = {}
		if G_RingSlingerGametype() then
			player.doom.keys = UINT32_MAX
		else
			player.doom.keys = 0
		end

		if not player.mo then continue end

		-- Place the player at their spawn point
		local pspawn

		-- Chocolate DOOM calls these rifts
		if doom.strife_spawnPlayerAtSpawn != nil then
			local spawnList = doom.spawnpoints.rift
			print("Targetting spot " .. doom.strife_spawnPlayerAtSpawn)
			pspawn = spawnList and spawnList[doom.strife_spawnPlayerAtSpawn]
		else
			pspawn = doom.getPlayerSpawn(player)
		end

		if pspawn then
			P_SetOrigin(player.mo, pspawn.x, pspawn.y, pspawn.z)
			player.mo.angle = pspawn.angle
			player.drawangle = pspawn.angle
		end
	end
	--#ifdef DOOM
	-- Spawn voodoo dolls at player starts that won't ever be used.
	for slot = 1, coopspawns do
		local list = doom.spawnpoints.player[slot]

		if list and #list > 1 then
			-- We always use the last spawn in the list.
			-- Every earlier one gets a voodoo doll.
			for i = 1, #list - 1 do
				local spawn = list[i]

				local doll = P_SpawnMobj(
					spawn.x,
					spawn.y,
					spawn.z,
					MT_DOOM_VOODOODOLL
				)

				if doll then
					doll.angle = spawn.angle
				end
			end
		end
	end
	--#endif
end)

/*

Type	Class	Effect
0		Normal
1	Light	Blink random
2	Light	Blink 0.5 second
3	Light	Blink 1.0 second
4	Both	20% damage per second plus light blink 0.5 second
5	Damage	10% damage per second
7	Damage	5% damage per second
8	Light	Oscillates
9	Secret	Player entering this sector gets credit for finding a secret
10	Door	30 seconds after level start, ceiling closes like a door
11	End	20% damage per second. The level ends when the player's health drops below 11% and is touching the floor. Player health cannot drop below 1% while anywhere in a sector with this sector type. God mode cheat (iddqd), if player has activated it, is nullified when player touches the floor for the first time.
12	Light	Blink 1.0 second, synchronized
13	Light	Blink 0.5 second, synchronized
14	Door	300 seconds after level start, ceiling opens like a door
16	Damage	20% damage per second
17	Light	Flickers randomly
*/

addHook("NetVars", function(net)
	doom.linespecials = net($)
	doom.hexen_linespecials = net($)
	doom.hexen_lineargs = net($)
	doom.prndindex = net($)
	doom.sectorbackups = net($)
	doom.gamemode = net($)
	doom.torespawn = net($)
	doom.intermission = net($)
	doom.kills = net($)
	doom.killcount = net($)
	doom.items = net($)
	doom.itemcount = net($)
	doom.secrets = net($)
	doom.secretcount = net($)
	doom.textscreen = net($)
	doom.thinkerlist = net($)
	doom.thinkermap = net($)
	doom.thinkers = net($)
	doom.defaultgravity = net($)
	doom.isdoom1 = net($)
	doom.numswitches = net($)
	doom.gameskill = net($)
	doom.switches = net($)
end)

doom.expectedUserdatas = {
	switch = "line_t",
	door = "sector_t",
	lift = "sector_t",
	crusher = "sector_t",
	scroll = "line_t",
	strobe = "sector_t",
	glow = "sector_t",
	flash = "sector_t",
	floor = "sector_t",
	ceiling = "sector_t",
	light = "sector_t",
	stair = "sector_t",
	elevator = "sector_t",
	sectorscroll = "sector_t",
	alarm = "sector_t",
	commmessage = "line_t",
	message = "sector_t",
	strife_exit = "line_t",
	justletthedefdothebehaviorlmao_line = "line_t",
	justletthedefdothebehaviorlmao_sector = "sector_t"
}

local function sectorHasUnfittableObject(a, b, c, d)
	-- resolve args to bounds
	local minx, maxx, miny, maxy

	if a and type(a) == "userdata" then
		-- 'a' is a sector_t, compute bounding box from its lines
		minx = INT32_MAX
		maxx = INT32_MIN
		miny = INT32_MAX
		maxy = INT32_MIN

		if not (a and a.valid) then print("Sector devalidated") return false end
		if not (a.lines and a.lines.valid) then print("Sector lines devalidated") return false end
		for linenum = 0, #a.lines - 1 do
			local line = a.lines[linenum]
			for i = 1, 2 do
				local vx = line["v" .. i].x
				local vy = line["v" .. i].y
				if vx < minx then minx = vx end
				if vx > maxx then maxx = vx end
				if vy < miny then miny = vy end
				if vy > maxy then maxy = vy end
			end
		end
	else
		-- expecting minx,maxx,miny,maxy
		minx = a
		maxx = b
		miny = c
		maxy = d
		-- quick safety check
		if not (minx and maxx and miny and maxy) then return false end
	end

	-- local helper: inclusive bounds check
	local function insideBounds(mobj, minx, maxx, miny, maxy)
		if not mobj or not mobj.valid then return false end

		local r = mobj.radius or 0

		if (mobj.x + r) < minx then return false end
		if (mobj.x - r) > maxx then return false end

		if (mobj.y + r) < miny then return false end
		if (mobj.y - r) > maxy then return false end

		return true
	end

	-- iterate mobjs, return true on first offending object
	for mobj in mobjs.iterate() do
		if not mobj or not mobj.valid then
			continue
		end

		if insideBounds(mobj, minx, maxx, miny, maxy) then
			-- must be shootable (players + monsters)
			if not (mobj.flags & MF_SHOOTABLE) then
				continue
			end

			-- ignore corpses
			if (mobj.doom.flags & DF_CORPSE) then
				continue
			end

			-- ignore missiles
			if (mobj.flags & MF_MISSILE) then
				continue
			end

			-- ignore noclip things
			if (mobj.flags & MF_NOCLIP) or (mobj.flags & MF_NOCLIPHEIGHT) then
				continue
			end

			local space = abs(mobj.floorz - mobj.ceilingz)
			-- if object fits, ignore; otherwise it's an offending object
			if (mobj.doom and mobj.doom.height) and mobj.doom.height >= space then
				return true
			end
		end
	end

	return false
end

-- BuildStairs: iterative stair builder using doom.addThinker
-- startsec: sector to start from (sector table)
-- stairsize: amount added per step (e.g. 8*FRACUNIT)
-- speed: floor move speed for each created thinker
-- RETURNS: table { created = <count>, sectors = { <sector>, ... } }
-- Vanilla: one sector may only host a single mover (door/floor/ceiling/lift/crusher)
local MOVER_TYPES = {
	door = true,
	floor = true,
	ceiling = true,
	lift = true,
	crusher = true,
	elevator = true
}

local function sectorHasMover(sec)
	for _, entry in ipairs(doom.thinkerlist) do
		if entry.active and entry.userdata == sec and entry.data and MOVER_TYPES[entry.data.type] then
			return true
		end
	end
	return false
end

local function BuildStairs(startsec, stairsize, speed)
	local result = { created = 0, sectors = {} }
	if not startsec then return result end
	if sectorHasMover(startsec) then return result end

	local texture = startsec.floorpic
	local height = startsec.floorheight + stairsize
	local sec = startsec
	local visited = {}
	local guard = 0

	while sec and guard < 4096 do
		guard = guard + 1
		visited[sec] = true

		doom.addThinker(sec, {
			type = "floor",
			action = (stairsize >= 0) and "raise" or "lower",
			targetheight = height,
			speed = speed
		})
		result.created = result.created + 1
		result.sectors[result.created] = sec

		local nextsec = nil
		for i = 0, #sec.lines - 1 do
			local line = sec.lines[i]
			if (line.flags & ML_TWOSIDED) ~= 0 and line.frontsector == sec then
				local tsec = line.backsector
				if tsec and tsec.floorpic == texture then
					height = height + stairsize
					if not visited[tsec] and not sectorHasMover(tsec) then
						nextsec = tsec
						break
					end
				end
			end
		end
		sec = nextsec
	end

	return result
end

local function FindNextHighestFromBackups(sec, curHeight)
	local best = nil

	for i = 0, #sec.lines-1 do
		local other = getNextSector(sec.lines[i], sec)
		if other then
			local h = doom.sectorbackups[other].lastTicFloorHeight
			if h == nil then
				h = other.floorheight
			end

			if h > curHeight and (best == nil or h < best) then
				best = h
			end
		end
	end

	if best == nil then best = curHeight end
	return best
end

local function FindHighestFromBackups(sec, curHeight)
	local best = curHeight

	for i = 0, #sec.lines-1 do
		local other = getNextSector(sec.lines[i], sec)
		if other then
			local h = doom.sectorbackups[other].lastTicFloorHeight
			if h == nil then
				h = other.floorheight
			end

			if h > best then
				best = h
			end
		end
	end

	return best
end

/*
//
// PIT_ChangeSector
//
boolean PIT_ChangeSector (mobj_t*	thing)
{
	mobj_t*	mo;

	if (P_ThingHeightClip (thing))
	{
	// keep checking
	return true;
	}


	// crunch bodies to giblets
	if (thing->health <= 0)
	{
	P_SetMobjState (thing, S_GIBS);

	thing->flags &= ~MF_SOLID;
	thing->height = 0;
	thing->radius = 0;

	// keep checking
	return true;
	}

	// crunch dropped items
	if (thing->flags & MF_DROPPED)
	{
	P_RemoveMobj (thing);

	// keep checking
	return true;
	}

	if (! (thing->flags & MF_SHOOTABLE) )
	{
	// assume it is bloody gibs or something
	return true;
	}

	nofit = true;

	if (crushchange && !(leveltime&3) )
	{
	P_DamageMobj(thing,NULL,NULL,10);

	// spray blood in a random direction
	mo = P_SpawnMobj (thing->x,
			  thing->y,
			  thing->z + thing->height/2, MT_BLOOD);

	mo->momx = (P_Random() - P_Random ())<<12;
	mo->momy = (P_Random() - P_Random ())<<12;
	}

	// keep checking (crush other things)
	return true;
}
*/

---@param thing mobj_t
local function P_ThingHeightClipCheck(thing)
	local floordelta = thing.ceilingz - thing.floorz
	if floordelta < thing.doom.height then
		return false
	end

	return true
end

local function P_SetMobjState(thing, state)
	thing.state = state
end

local function PIT_ChangeSector(thing, crushchange)
	local mo
	local nofit = false

	if P_ThingHeightClipCheck(thing) then
		// keep checking
		return true
	end

	// crunch bodies to giblets
	if thing.doom.health <= 0 then
		P_SetMobjState(thing, S_DOOM_CRUSHGIBS_1)

		thing.flags = $ & ~MF_SOLID
		thing.height = 0
		thing.radius = 0

		// keep checking
		return true
	end

	// crunch dropped items
	if (thing.doom.flags & DF_DROPPED) then
		P_RemoveMobj(thing)

		// keep checking
		return true
	end

	if not (thing.flags & MF_SHOOTABLE) then
		// assume it is bloody gibs or something
		return true
	end

	nofit = true

	if crushchange and not (leveltime&3) then
		DOOM_DamageMobj(thing, nil, nil, 10)

		// spray blood in a random direction
		mo = P_SpawnMobj(thing.x,
				thing.y,
				thing.z + thing.height/2, MT_DOOM_BLOOD)

		mo.momx = (DOOM_Random() - DOOM_Random()) << 12
		mo.momy = (DOOM_Random() - DOOM_Random()) << 12
	end

	// keep checking (crush other things)
	return true, nofit
end

local function crushThings(sector, crush)
	local minx, maxx = INT32_MAX, INT32_MIN
	local miny, maxy = INT32_MAX, INT32_MIN
	for linenum = 0, #sector.lines - 1 do
		local line = sector.lines[linenum]
		local v1, v2 = line.v1, line.v2
		if v1.x < minx then minx = v1.x end
		if v1.x > maxx then maxx = v1.x end
		if v1.y < miny then miny = v1.y end
		if v1.y > maxy then maxy = v1.y end
		if v2.x < minx then minx = v2.x end
		if v2.x > maxx then maxx = v2.x end
		if v2.y < miny then miny = v2.y end
		if v2.y > maxy then maxy = v2.y end
	end

	local nofit = false
	for mobj in mobjs.iterate() do
		if mobj and mobj.valid then
			local r = mobj.radius or 0
			if (mobj.x + r) >= minx and (mobj.x - r) <= maxx
			and (mobj.y + r) >= miny and (mobj.y - r) <= maxy then
				local _, nf = PIT_ChangeSector(mobj, crush)
				if nf then nofit = true end
			end
		end
	end
	return nofit
end

local function namedSpeed(name, base)
	if name == "half" then return base / 2 end
	if name == "normal" then return base * 2 end
	if name == "fast" then return base * 4 end
	if name == "turbo" then return base * 8 end
	return base
end

local function numericModel(sector, dest)
	for i = 0, #sector.lines - 1 do
		local line = sector.lines[i]
		if (line.flags & ML_TWOSIDED) ~= 0 then
			local other = getNextSector(line, sector)
			if other and other.floorheight == dest then
				return other.floorpic, other.special
			end
		end
	end
	return nil, nil
end

local function applyFloorChange(sector, data)
	if data.newfloorpic == nil then return end
	local ct = data.changeType
	if ct == "zero" then
		sector.floorpic = data.newfloorpic
		doom.sectorspecials[sector] = 0
	elseif ct == "texture" or ct == "txtonly" then
		sector.floorpic = data.newfloorpic
	elseif ct == "type" then
		sector.floorpic = data.newfloorpic
		doom.sectorspecials[sector] = data.newSectorSpecial or 0
	end
end

local function lowerTexHeight(side)
	if not side then return nil end
	local texnum = side.bottomtexture
	if not texnum or texnum == 0 then return nil end
	local tex = doom.texturesByNum[texnum]
	if tex and tex.height and tex.height > 0 then
		return tex.height * FRACUNIT
	end
	return nil
end

-- Get this ONCE, like Vanilla
local function floorDestination(sector, data)
	local target = data.target
	local dir = (data.action == "raise") and "up" or "down"
	local dest

	if data.targetheight ~= nil then
		dest = data.targetheight
	elseif type(target) == "number" then
		dest = sector.floorheight + target
	elseif target == "nextfloor" then
		dest = FindNextHighestFromBackups(sector, sector.floorheight)
	elseif target == "highest" then
		dest = P_FindHighestFloorSurrounding(sector)
		dir = "down"
	elseif target == "8abovehighest" then
		dest = P_FindHighestFloorSurrounding(sector)
		if dest ~= sector.floorheight then
			dest = dest + 8*FRACUNIT
		end
		dir = "down"
	elseif target == "lowest" then
		dest = P_FindLowestFloorSurrounding(sector)
		dir = "down"
	elseif target == "lowestceiling" then
		dest = P_FindLowestCeilingSurrounding(sector)
		if dest > sector.ceilingheight then dest = sector.ceilingheight end
		dir = "up"
	elseif target == "ceiling" then
		dest = sector.ceilingheight
		dir = "up"
	elseif target == "8belowceiling" then
		dest = P_FindLowestCeilingSurrounding(sector)
		if dest > sector.ceilingheight then dest = sector.ceilingheight end
		dest = dest - 8*FRACUNIT
		dir = "up"
	elseif target == "shortestlowertex" then
		-- Vanilla: own floor + shortest lower texture on either side of any two-sided line
		local minsize = 32000 * FRACUNIT
		for i = 0, #sector.lines - 1 do
			local line = sector.lines[i]
			if (line.flags & ML_TWOSIDED) ~= 0 then
				local h1 = lowerTexHeight(line.frontside)
				local h2 = lowerTexHeight(line.backside)
				if h1 and h1 < minsize then minsize = h1 end
				if h2 and h2 < minsize then minsize = h2 end
			end
		end
		dest = sector.floorheight + minsize
		dir = "up"
	elseif target == "nextneighbor" then
		local cur = sector.floorheight
		local best = nil
		for i = 0, #sector.lines - 1 do
			local other = getNextSector(sector.lines[i], sector)
			if other then
				local h = doom.sectorbackups[other].lastTicFloorHeight
				if h == nil then h = other.floorheight end
				if dir == "up" then
					if h > cur and (best == nil or h < best) then best = h end
				else
					if h < cur and (best == nil or h > best) then best = h end
				end
			end
		end
		if best == nil then return nil end
		dest = best
	else
		print("No defined target '" .. tostring(target) .. "' for floor thinker, stopping...")
		return nil
	end

	return dest, dir
end

local thinkers = {
	switch = function(line, data)
		-- Infer switch textures if not already set (for switches activated via interact raycast)
		if data.victimTextureArea == nil then
			local side = line.frontside
			if side then
				local texTop, texMid, texBot = side.toptexture, side.midtexture, side.bottomtexture

				if doom.numswitches and doom.numswitches > 0 then
					for i = 1, doom.numswitches * 2 do
						local v = doom.switches[i]
						if v == texTop then
							local partnerIndex = (i % 2 == 1) and (i + 1) or (i - 1)
							data.onTexture = doom.switches[partnerIndex]
							data.offTexture = doom.switches[i]
							data.victimTextureArea = "toptexture"
							break
						elseif v == texMid then
							local partnerIndex = (i % 2 == 1) and (i + 1) or (i - 1)
							data.onTexture = doom.switches[partnerIndex]
							data.offTexture = doom.switches[i]
							data.victimTextureArea = "midtexture"
							break
						elseif v == texBot then
							local partnerIndex = (i % 2 == 1) and (i + 1) or (i - 1)
							data.onTexture = doom.switches[partnerIndex]
							data.offTexture = doom.switches[i]
							data.victimTextureArea = "bottomtexture"
							break
						else
							data.victimTextureArea = false
						end
					end
				end

				-- Set defaults for switch fields if not already present
				data.allowOff = data.allowOff or data.repeatable
				data.onSound = data.onSound or sfx_swtchn
				data.offSound = data.offSound or sfx_swtchx
				data.delay = data.delay or TICRATE
			end
		end

		if data.switcher then
			if data.switcher.valid then
				local player = data.switcher.player

				if data.lock and not (player and (player.doom.keys & data.lock)) then
					DOOM_DoMessage(player, data.denyMessage or "YOU FORGOT TO SET A MESSAGE FOR THIS!")
					S_StartSound(data.switcher, sfx_noway)
					doom.stopThinker(line)
					return
				end
			end
		end

		if not (data.switcher and data.switcher.valid) then
			print("NOTICE: SWITCHER OBJECT BECAME INVALID! FALLING BACK TO NIL SWITCHER...")
			data.switcher = nil
		end

		if not data.started then
			-- Play sound and exit
			if data.willExit then
				if data.switcher and data.switcher.valid then
					local onSound = data.onSound or sfx_swtchn
					S_StartSound(data.switcher, onSound)
				end
				doom.stopThinker(line)
				DOOM_ExitLevel()
				return
			end

			if not data.owner then
				for sector in sectors.tagged(data.victimTag) do
					doom.addThinker(sector, data.victimData)
				end
			else
				doom.addThinker(data.victimLine.backsector, data.victimData)
			end
			data.started = true
			if data.victimTextureArea then
				S_StartSound(data.switcher, data.onSound)
				line.frontside[data.victimTextureArea] = data.onTexture
			else
				doom.stopThinker(line)
				return
			end
		end

		-- if not data.victimData.repeatable...
		-- Effectively locks out using the switch again
		if not data.allowOff then
			doom.linespecials[line] = 0
			doom.stopThinker(line)
			return
		end

		-- The semi-animation for when the switch is repeatable
		-- Questionable name? Sure, why the hell not!
		if data.delay then
			data.delay = $ - 1
		else
			if data.victimTextureArea then
				S_StartSound(data.switcher, data.onSound)
				line.frontside[data.victimTextureArea] = data.offTexture
			end
			doom.stopThinker(line)
		end
	end,

	door = function(sector, data)
		local speedInfo = {
			slow   = {speed = FRACUNIT,   blaze = false},
			normal = {speed = 2*FRACUNIT, blaze = false},
			fast   = {speed = 4*FRACUNIT, blaze = true},
			turbo  = {speed = 8*FRACUNIT, blaze = true}
		}
		local info = speedInfo[data.speed] or speedInfo.normal
		local speed = info.speed

		local startsClosed = (data.mode == "clsopn" or data.mode == "close")
		local waitsAtOpen  = (data.mode == "opndcls")
		local waitsAtClose = (data.mode == "clsopn")
		local canBounce    = (data.mode ~= "close")

		if data.direction == nil then
			data.direction = startsClosed and -1 or 1
			data.init = startsClosed
			if data.mode == "clsopn" then
				data.openTarget = sector.ceilingheight
			else
				data.openTarget = P_FindLowestCeilingSurrounding(sector) - 4*FRACUNIT
			end
		end

		local openTarget = data.openTarget
		local closedTarget = sector.floorheight

		if data.direction == 1 then
			if not data.init then
				S_StartSound(sector, info.blaze and sfx_bdopn or sfx_doropn)
				data.init = true
			end

			sector.ceilingheight = sector.ceilingheight + speed
			if sector.ceilingheight >= openTarget then
				sector.ceilingheight = openTarget
				if waitsAtOpen then
					data.direction = 0
					data.waitClock = data.delay or 150
				else
					doom.stopThinker(sector)
				end
			end

		elseif data.direction == -1 then
			if data.init then
				S_StartSound(sector, info.blaze and sfx_bdcls or sfx_dorcls)
				data.init = false
			end

			sector.ceilingheight = sector.ceilingheight - speed

			if sectorHasUnfittableObject(sector) then
				sector.ceilingheight = sector.ceilingheight + speed
				if canBounce then
					S_StartSound(sector, info.blaze and sfx_bdopn or sfx_doropn)
					data.direction = 1
					data.init = true
				end
				return
			end

			if sector.ceilingheight <= closedTarget then
				sector.ceilingheight = closedTarget
				if waitsAtClose then
					data.direction = 0
					data.waitClock = data.delay or 150
				else
					doom.stopThinker(sector)
					if info.blaze then
						S_StartSound(sector, sfx_bdcls)
					end
				end
			end

		else
			if data.waitClock == nil then
				data.waitClock = data.delay or 150
			end
			data.waitClock = data.waitClock - 1
			if data.waitClock <= 0 then
				data.waitClock = nil
				if waitsAtClose then
					data.direction = 1
					data.init = false
				else
					data.direction = -1
					data.init = true
				end
			end
		end
	end,

	lift = function(sector, data)
		if not (sector and sector.valid) then
			doom.stopThinker(sector)
			return
		end

		local lowerFirst = (data.mode ~= "raisewaitlower")
		local speed = (data.speed == "fast") and 8*FRACUNIT or 4*FRACUNIT

		if not data.started then
			data.started = true
			data.startheight = sector.floorheight
			if lowerFirst then
				data.goal = P_FindLowestFloorSurrounding(sector)
				if data.goal > sector.floorheight then data.goal = sector.floorheight end
			else
				data.goal = P_FindHighestFloorSurrounding(sector)
				if data.goal < sector.floorheight then data.goal = sector.floorheight end
			end
			S_StartSound(sector, sfx_pstart)
		end

		if not data.reachedGoal then
			if lowerFirst then
				sector.floorheight = sector.floorheight - speed
				if sector.floorheight <= data.goal then
					sector.floorheight = data.goal
					data.reachedGoal = true
				end
			else
				sector.floorheight = sector.floorheight + speed
				if sector.floorheight >= data.goal then
					sector.floorheight = data.goal
					data.reachedGoal = true
				end
			end
			if data.reachedGoal then
				data.waitClock = data.delay or (35 * PLATWAIT)
				S_StartSound(sector, sfx_pstop)
			end

		elseif data.waitClock and data.waitClock > 0 then
			data.waitClock = data.waitClock - 1
			if data.waitClock <= 0 then
				data.waitClock = 0
				S_StartSound(sector, sfx_pstart)
			end

		else
			local done = false
			if lowerFirst then
				sector.floorheight = sector.floorheight + speed
				if sector.floorheight >= data.startheight then done = true end
			else
				sector.floorheight = sector.floorheight - speed
				if sector.floorheight <= data.startheight then done = true end
			end
			if done then
				sector.floorheight = data.startheight
				doom.sectorbackups[sector].floor = sector.floorheight
				S_StartSound(sector, sfx_pstop)
				doom.stopThinker(sector)
			end
		end
	end,

	crusher = function(sector, data)
		if not (sector and sector.valid) then
			doom.stopThinker(sector)
			return
		end

		-- A "stop" line that finds no running crusher has nothing to do
		if data.mode == "stop" then
			doom.stopThinker(sector)
			return
		end

		if data.stasis then return end

		if not data.started then
			data.started = true
			data.topheight = sector.ceilingheight
			data.bottomheight = sector.floorheight + 8*FRACUNIT
			data.goingUp = false
			data.basespeed = namedSpeed(data.speed, FRACUNIT)
		end

		local speed = data.basespeed
		if data.caughtObject then
			speed = FRACUNIT / 8
		end

		if not data.silent and not (leveltime & 7) then
			S_StartSound(sector, sfx_stnmov)
		end

		if data.goingUp then
			sector.ceilingheight = sector.ceilingheight + speed
			if sector.ceilingheight >= data.topheight then
				sector.ceilingheight = data.topheight
				data.goingUp = false
				if data.silent then
					S_StartSound(sector, sfx_pstop)
				end
			end
		else
			sector.ceilingheight = sector.ceilingheight - speed
			local nofit = crushThings(sector, true)
			if nofit and not data.nocrushslow then
				data.caughtObject = true
			end
			if sector.ceilingheight <= data.bottomheight then
				sector.ceilingheight = data.bottomheight
				data.goingUp = true
				data.caughtObject = false
				if data.silent then
					S_StartSound(sector, sfx_pstop)
				end
			end
		end
	end,

	---@param line line_t
	scroll = function(line, data)
		local side = sides[line.sidenum[0]]
		if data.scrx == nil then
			print("Scroll thinker has no scrx!")
			doom.stopThinker(line)
		end
		if data.scry == nil then
			print("Scroll thinker has no scry!")
			doom.stopThinker(line)
		end

		if data.noscroll then return end
		side.textureoffset = $ + data.scrx
		side.rowoffset = $ + data.scry
	end,

	sectorscroll = function(sector, data)
		if data.place == "floor" then
			if data.noscroll then return end
			sector.floorxoffset = $ - data.scrx
			sector.flooryoffset = $ + data.scry
		end
	end,

	strobe = function(sector, data)
		data.count = data.count - 1
		if data.count > 0 then
			return
		end

		if (sector.lightlevel == data.minlight) then
			sector.lightlevel = data.maxlight
			data.count = data.brighttime
		else
			sector.lightlevel = data.minlight
			data.count = data.darktime
		end
	end,

	glow = function(sector, data)
		if data.direction == -1 then
			-- going down
			sector.lightlevel = $ - GLOWSPEED
			if sector.lightlevel <= data.minlight then
				sector.lightlevel = $ + GLOWSPEED
				data.direction = 1
			end

		elseif data.direction == 1 then
			-- going up
			sector.lightlevel = $ + GLOWSPEED
			if sector.lightlevel >= data.maxlight then
				sector.lightlevel = $ - GLOWSPEED
				data.direction = -1
			end
		end
	end,

	flash = function(sector, data)
		-- vanilla: if (--count) return;
		data.count = data.count - 1
		if data.count > 0 then
			return
		end

		if sector.lightlevel == data.maxlight then
			sector.lightlevel = data.minlight
			data.count = (DOOM_Random() & data.mintime) + 1
		else
			sector.lightlevel = data.maxlight
			data.count = (DOOM_Random() & data.maxtime) + 1
		end
	end,

	stair = function(sector, data)
		if data.started then
			return
		end
		data.started = true

		local stepSize = (data.amount or 8) * FRACUNIT
		local speed = data.speed == "fast" and FRACUNIT*4 or FRACUNIT/4
		BuildStairs(sector, stepSize, speed)

		doom.stopThinker(sector)
	end,

	elevator = function(sector, data)
		-- Determine actual numeric targets if target is a string
		if type(data.target) == "string" and not data.resolved then
			data.resolved = true
			if data.target == "lowerfloor" then
				data.floordestheight = P_FindLowestFloorSurrounding(sector)
				data.ceilingdestheight = sector.ceilingheight - (sector.floorheight - data.floordestheight)
			elseif data.target == "higherfloor" then
				data.floordestheight = P_FindHighestFloorSurrounding(sector)
				data.ceilingdestheight = sector.ceilingheight + (data.floordestheight - sector.floorheight)
			else
				print("elevator thinker: unknown string target '"..data.target.."'")
				doom.stopThinker(sector)
				return
			end
		end

		local speed = 4*FRACUNIT
		local floorDir = data.floordestheight > sector.floorheight and 1 or -1

		-- move floor
		local floorDelta = speed * floorDir
		sector.floorheight = sector.floorheight + floorDelta

		-- move ceiling at the same pace
		sector.ceilingheight = sector.ceilingheight + floorDelta

		-- stop when reached destination
		if (floorDir > 0 and sector.floorheight >= data.floordestheight) or
		(floorDir < 0 and sector.floorheight <= data.floordestheight) then
			sector.floorheight = data.floordestheight
			sector.ceilingheight = data.ceilingdestheight
			doom.stopThinker(sector)
			S_StartSound(sector, sfx_pstop)
		end
	end,

	floor = function(sector, data)
		if not (sector and sector.valid) then
			doom.stopThinker(sector)
			return
		end

		if data.stasis then return end

		local spd
		if type(data.speed) == "number" then
			spd = data.speed
		else
			spd = namedSpeed(data.speed, PLATSPEED)
		end

		-- Infer action if the definition did not give one
		if not data.action then
			if type(data.target) == "number" then
				data.action = (data.target >= 0) and "raise" or "lower"
			elseif data.target == "highest" or data.target == "lowest" or data.target == "8abovehighest" then
				data.action = "lower"
			else
				data.action = "raise"
			end
		end

		-- Donut (line special 9)
		if data.action == "donut" then
			if not data.init then
				data.init = true
				local hole = sector
				local ringsec = nil
				if #hole.lines > 0 then
					ringsec = getNextSector(hole.lines[0], hole)
				end
				if not ringsec then
					doom.stopThinker(sector)
					return
				end

				local outside = nil
				for i = 0, #ringsec.lines - 1 do
					local rl = ringsec.lines[i]
					local back = rl.backsector
					if back and back ~= hole then
						outside = back
						break
					end
				end
				if not outside then
					doom.stopThinker(sector)
					return
				end

				-- Ring rises (texture copied, special zeroed on arrival), hole lowers; both at half speed
				doom.addThinker(ringsec, {
					type = "floor",
					action = "donut_ring",
					targetheight = outside.floorheight,
					newfloorpic = outside.floorpic,
					speed = "half"
				})

				-- This thinker already owns the hole sector's mover slot, so it becomes the hole mover
				data.action = "donut_hole"
				data.targetheight = outside.floorheight
				data.speed = "half"
			end
			return
		end

		if data.action == "donut_ring" or data.action == "donut_hole" then
			local dspd = namedSpeed("half", PLATSPEED)
			local dest = data.targetheight
			local ring = (data.action == "donut_ring")
			if not data.init then
				data.init = true
			end
			if ring then
				sector.floorheight = sector.floorheight + dspd
				if not (leveltime & 7) then S_StartSound(sector, sfx_stnmov) end
				if sector.floorheight >= dest then
					sector.floorheight = dest
					sector.floorpic = data.newfloorpic
					doom.sectorspecials[sector] = 0
					doom.sectorbackups[sector].floor = dest
					S_StartSound(sector, sfx_pstop)
					doom.stopThinker(sector)
				end
			else
				sector.floorheight = sector.floorheight - dspd
				if not (leveltime & 7) then S_StartSound(sector, sfx_stnmov) end
				if sector.floorheight <= dest then
					sector.floorheight = dest
					doom.sectorbackups[sector].floor = dest
					S_StartSound(sector, sfx_pstop)
					doom.stopThinker(sector)
				end
			end
			return
		end

		if data.action == "oscillate" then
			if not data.init then
				data.isPlatLike = true
				data.low = P_FindLowestFloorSurrounding(sector)
				if data.low > sector.floorheight then data.low = sector.floorheight end
				data.high = P_FindHighestFloorSurrounding(sector)
				if data.high < sector.floorheight then data.high = sector.floorheight end
				data.wait = 35 * PLATWAIT
				data.status = ((DOOM_Random() & 1) == 1) and "up" or "down"
				data.init = true
				S_StartSound(sector, sfx_pstart)
			end

			local platspd = namedSpeed(data.speed, PLATSPEED)

			if data.status == "up" then
				doom.sectorbackups[sector].lastTicFloorHeight = sector.floorheight
				sector.floorheight = sector.floorheight + platspd
				if sector.floorheight >= data.high then
					sector.floorheight = data.high
					data.status = "wait"
					data.waitClock = data.wait
					S_StartSound(sector, sfx_pstop)
				end
			elseif data.status == "down" then
				sector.floorheight = sector.floorheight - platspd
				if sector.floorheight <= data.low then
					sector.floorheight = data.low
					data.status = "wait"
					data.waitClock = data.wait
					S_StartSound(sector, sfx_pstop)
				end
			else
				data.waitClock = data.waitClock - 1
				if data.waitClock <= 0 then
					if sector.floorheight == data.low then
						data.status = "up"
					else
						data.status = "down"
					end
					S_StartSound(sector, sfx_pstart)
				end
			end
			return
		end

		-- Stop Moving Floor (54/89)
		if data.action == "oscillate_stop" then
			stop_plats_by_tag(data.tag)
			doom.stopThinker(sector)
			return
		end

		-- Ordinary raise / lower
		if not data.started then
			data.started = true
			local dest, dir = floorDestination(sector, data)
			if dest == nil then
				doom.stopThinker(sector)
				return
			end
			data.dest = dest
			data.dir = dir

			if data.changes then
				if data.changeModel == "numeric" or data.model == "numeric" then
					local pic, special = numericModel(sector, dest)
					if pic == nil then
						data.changes = false -- no model sector: no change
					else
						data.newfloorpic = pic
						data.newSectorSpecial = special
					end
				end
				-- Raising floors change texture/special when they START (vanilla);
				-- lowerAndChange applies on arrival.
				if data.changes and dir == "up" then
					applyFloorChange(sector, data)
					data.changeDone = true
				end
			end
		end

		local dest = data.dest
		if data.dir == "up" then
			sector.floorheight = sector.floorheight + spd
		else
			sector.floorheight = sector.floorheight - spd
		end

		if not (leveltime & 7) then
			S_StartSound(sector, sfx_stnmov)
		end

		if data.crush and data.dir == "up" then
			crushThings(sector, true)
		end

		local arrived
		if data.dir == "up" then
			arrived = (sector.floorheight >= dest)
		else
			arrived = (sector.floorheight <= dest)
		end

		if arrived then
			sector.floorheight = dest
			doom.sectorbackups[sector].floor = dest
			if data.changes and not data.changeDone then
				applyFloorChange(sector, data)
			end
			S_StartSound(sector, sfx_pstop)
			doom.stopThinker(sector)
		end
	end,

	ceiling = function(sector, data)
		if not (sector and sector.valid) then
			doom.stopThinker(sector)
			return
		end

		-- The destination is decided once, when the ceiling mover spawns
		if not data.started then
			data.started = true
			local t = data.target
			local dest
			local up = (data.action == "raise")

			if t == "nextfloor" then
				dest = FindNextHighestFromBackups(sector, sector.ceilingheight)
			elseif t == "lowestceiling" or t == "lowest" then
				dest = P_FindLowestCeilingSurrounding(sector)
			elseif t == "highest" then
				dest = P_FindHighestCeilingSurrounding(sector)
				if data.action == nil then up = true end
			elseif t == "highestfloor" then
				dest = P_FindHighestFloorSurrounding(sector)
			elseif t == "floor" then
				dest = sector.floorheight
			elseif t == "8abovefloor" then
				dest = sector.floorheight + 8*FRACUNIT
			elseif t == "8belowceiling" then
				dest = P_FindLowestCeilingSurrounding(sector) - 8*FRACUNIT
			else
				print("No defined target '" .. tostring(t) .. "' for ceiling thinker, stopping...")
				doom.stopThinker(sector)
				return
			end

			data.dest = dest
			data.up = up
		end

		-- CEILSPEED is FRACUNIT
		local spd = namedSpeed(data.speed, FRACUNIT)

		if not (leveltime & 7) then
			S_StartSound(sector, sfx_stnmov)
		end

		if data.up then
			sector.ceilingheight = sector.ceilingheight + spd
			if sector.ceilingheight >= data.dest then
				sector.ceilingheight = data.dest
				doom.sectorbackups[sector].ceil = data.dest
				doom.stopThinker(sector)
			end
		else
			sector.ceilingheight = sector.ceilingheight - spd
			if sector.ceilingheight <= data.dest then
				sector.ceilingheight = data.dest
				doom.sectorbackups[sector].ceil = data.dest
				doom.stopThinker(sector)
			end
		end
	end,

	light = function(sector, data)
		-- Line special 17: start blinking lights (vanilla P_SpawnStrobeFlash(sec, SLOWDARK, 0))
		if data.mode == "blink" then
			P_SpawnStrobeFlash(sector, data.blinktime or SLOWDARK, false)
			doom.stopThinker(sector)
			return
		end

		local t = data.target
		if type(t) == "string" then
			if t == "brightest_adjacent" then
				-- Vanilla EV_LightTurnOn(line, 0): starts at 0, one-sided lines are skipped
				local brightest = 0
				for linenum = 0, #sector.lines - 1 do
					local other = getNextSector(sector.lines[linenum], sector)
					if other and other.lightlevel > brightest then
						brightest = other.lightlevel
					end
				end
				sector.lightlevel = brightest
			elseif t == "darkest_adjacent" then
				-- Vanilla EV_TurnTagLightsOff
				local darkest = sector.lightlevel
				for linenum = 0, #sector.lines - 1 do
					local other = getNextSector(sector.lines[linenum], sector)
					if other and other.lightlevel < darkest then
						darkest = other.lightlevel
					end
				end
				sector.lightlevel = darkest
			else
				print("Bad target data '" .. tostring(t) .. "' for light thinker, stopping...")
			end
			doom.stopThinker(sector)
			return
		end
		sector.lightlevel = t or 35
		doom.stopThinker(sector)
	end,

	commmessage = function(line, data)
		if data.used then return end
		-- TODO: Voice
		DOOM_DoMessage(data.triggerer, "Incoming message...")
		local id = data.id
		if id == "tag" then
			id = line.tag
		end
		print(doom.logs[id])
		if data.repeatable then
			doom.stopThinker(line)
		else
			data.used = true
		end
	end,

	message = function(sector, data)
		if not data.triggerer then doom.stopThinker(sector) return end
		DOOM_DoMessage(data.triggerer, data.message)
		S_StartSound(data.triggerer.mo, data.sound)
		doom.stopThinker(sector)
	end,

	alarm = function(sector, data)
		if not data.triggerer then doom.stopThinker(sector) return end
		P_NoiseAlert(data.triggerer.mo, data.triggerer.mo)
		doom.stopThinker(sector)
	end,

	strife_exit = function(line, data)
		if G_RingSlingerGametype() then
			doom.stopThinker(line)
			return
		end

		-- TODO: Multiplayer: Don't immediately exit the level!
		--       Needs a form of democracy instead

		local map = line.tag / 100
		local spot = line.tag % 100

		-- Sigil changes the destinations of certain maps
		if players[0].doom.strife_sigilprogression then
			if map == 3 then
				map = 30
			elseif map == 7 then
				map = 10
			end
		end

		toStudyForADrugTestSheTookAllOfTheDrugs(gamemap)

		G_SetCustomExitVars(map, 2)
		doom.strife_spawnPlayerAtSpawn = spot

		G_ExitLevel()
		doom.stopAllThinkers()
	end,

	-- Below two for one-off specials, e.g.
	-- "W1 Entity Taunt If Quest Item 24 Owned"
	justletthedefdothebehaviorlmao_line = function(line, data)
		data.fun(line, data)
	end,

	justletthedefdothebehaviorlmao_sector = function(sector, data)
		data.fun(sector, data)
	end
}

local function thinkFrameIterator(any, data, thinkertable)
		if not (any and any.valid) then doom.stopThinker(any) return end
		if data == nil then return end
		local expected = doom.expectedUserdatas[data.type]
		local actual = userdataType(any)

		if not expected then
			print("Unknown thinker type '" .. tostring(data.type) .. "'!")
			doom.stopThinker(any, data)
			return
		end

		if actual ~= expected then
			print("Incorrect userdata type for '" .. data.type .. "'! (" .. expected .. " expected, got " .. actual .. ")")
			doom.stopThinker(any, data)
			return
		end

		local fn = thinkers[data.type]
		if not fn then
			print("No thinker function defined for '" .. data.type .. "'!")
			doom.stopThinker(any, data)
			return
		end

		fn(any, data)
end

local function doorStartsClosing(data)
	return data.mode == "clsopn"
		or data.mode == "close"
end

local function restartDoorOpposite(sector, data)
	-- Vanilla only lets manual doors reverse when used again
	if data.owner ~= "sector" or not data.repeatable or data.activationType != "switch" then return end
	if data.direction == 1 then
		data.direction = -1

	elseif data.direction == -1 then
		data.direction = 1

	else -- waiting or uninitialized
		if data.mode == "clsopn" or data.mode == "close" then
			data.direction = 1      -- was waiting after closing
		else
			data.direction = -1     -- was waiting after opening
		end
	end

	data.waitClock = nil
	data.init = (data.direction == -1)
end

local onThinkerRepeat = {
	door = function(sector, data)
		restartDoorOpposite(sector, data)
	end,

	floor = function(sector, data, new)
		if not data.isPlatLike or not new then return end
		if new.action == "oscillate_stop" then
			stop_plats_by_tag(new.tag or data.tag)
		elseif new.action == "oscillate" then
			resume_plats_by_tag(new.tag or data.tag)
		end
	end,

	crusher = function(sector, data, new)
		if not new then return end
		if new.mode == "stop" then
			data.stasis = true
		elseif data.stasis then
			data.stasis = false
		end
	end
}

doom.thinkerlist = doom.thinkerlist or {}

function doom.addThinker(any, thinkTable)
	if not any or thinkTable == nil then return end

	local isMover = MOVER_TYPES[thinkTable.type]
	for i, thinker in ipairs(doom.thinkerlist) do
		local tdata = thinker.data
		if thinker.userdata == any and tdata then
			local sameType = (tdata.type == thinkTable.type)
			if sameType or (isMover and MOVER_TYPES[tdata.type]) then
				local onTR = sameType and onThinkerRepeat[tdata.type] or nil
				if onTR then
					onTR(thinker.userdata, tdata, thinkTable)
				end
				return i
			end
		end
	end

    local data = deepcopy(thinkTable)
    local entry = { userdata = any, data = data, active = true }
    local idx = #doom.thinkerlist + 1
    doom.thinkerlist[idx] = entry
    return idx
end

-- Stop thinker:
-- Usage options:
--   doom.stopThinker(index)                      -- stop by numeric index
--   doom.stopThinker(userdata, data)             -- stop single entry that matches userdata+data (table identity)
--   doom.stopThinker(userdata)                   -- if called *from inside* a thinker, stops that thinker only;
--                                                 otherwise, stops *all* thinkers for userdata
function doom.stopThinker(a, b)
    if a == nil then return end

    -- Stop by numeric index
    if type(a) == "number" then
        local idx = a
        local entry = doom.thinkerlist[idx]
        if not entry then return end
        entry.active = false
        entry.data = nil
        entry.userdata = nil
        return
    end

    local userdata = a
    local data = b

    -- If both userdata and data provided: stop the single entry matching both (table identity)
    if data ~= nil then
        for i = 1, #doom.thinkerlist do
            local entry = doom.thinkerlist[i]
            if entry and entry.active and entry.userdata == userdata and entry.data == data then
                entry.active = false
                entry.data = nil
                entry.userdata = nil
                return
            end
        end
        return
    end

    -- If called inside a thinker, try to stop the current entry only
    local current = doom._current_thinker_entry
    if current and current.userdata == userdata then
        current.active = false
        current.data = nil
        current.userdata = nil
        doom._current_thinker_entry = nil
        return
    end

    -- Otherwise: stop ALL thinkers for this userdata (backwards-compatible behavior)
    for i = 1, #doom.thinkerlist do
        local entry = doom.thinkerlist[i]
        if entry and entry.active and entry.userdata == userdata then
            entry.active = false
            entry.data = nil
            entry.userdata = nil
        end
    end
end

function doom.stopAllThinkers()
    for i = 1, #doom.thinkerlist do
        local entry = doom.thinkerlist[i]
        if entry and entry.active then
            entry.active = false
            entry.data = nil
            entry.userdata = nil
        end
    end

    doom._current_thinker_entry = nil
end

-- compact_thinkerlist: just compacts the numeric list (no single-map; multiple per userdata allowed)
local function compact_thinkerlist()
	local newlist = {}
	local n = 0
	for i = 1, #doom.thinkerlist do
		local entry = doom.thinkerlist[i]
		if entry and entry.active and entry.userdata and entry.data then
			n = n + 1
			newlist[n] = entry
		end
	end
	doom.thinkerlist = newlist
end

-- ThinkFrame: iterate entries, set current entry so doom.stopThinker(sector) inside a thinker
-- stops the current entry only (rather than all entries for that userdata).
addHook("ThinkFrame", function()
	for i = 1, #doom.thinkerlist do
		local entry = doom.thinkerlist[i]
		if entry and entry.active and entry.userdata and entry.data then
			-- set current thinker context so doom.stopThinker(userdata) can infer the right entry
			doom._current_thinker_entry = entry
			-- call the existing iterator (unchanged)
			thinkFrameIterator(entry.userdata, entry.data, "thinkers")
			doom._current_thinker_entry = nil
		end
	end

	compact_thinkerlist()
end)

addHook("ThinkFrame", function()
	for mobj, params in pairs(doom.torespawn) do
		local time = params.time
		local convar = "respawnitemtime"
		local respawntime = (CV_FindVar(convar) and CV_FindVar(convar).value or 0) * TICRATE
		if ((time + respawntime) - leveltime) <= 0 then
			local newmobj = P_SpawnMobj(params.x, params.y, params.z, params.type)
			doom.torespawn[mobj] = nil
			S_StartSound(newmobj, sfx_itmbk)
		end
	end
end)

addHook("PostThinkFrame", function()
	for player in players.iterate do
		if not player.mo then return end
		if player.mo.doom.flags & DF_SHADOW then
			if not P_GetPlayerCharDef(player).noPartialInvisEffect then
				player.mo.frame = $ | FF_TRANS80
			else
				doom.warn("deprecated.noPartialInvisEffect", "doom.characterDefs['" .. player.mo.skin .. "'].noPartialInvisEffect is deprecated and will be removed in a future version. Use properties.overridePartialInvisibilityFX instead.")
			end
		end
	end
end)

addHook("MobjSpawn", function(mobj)
	mobj.doom = {}
	if mobj.type == MT_PLAYER then
		mobj.doom.maxhealth = 100
		mobj.doom.health = 100
		mobj.doom.flags = mobj.info.doomflags or 0
	else
		if mobj.sprite == SPR_PLAY then
			mobj.skin = "johndoom"
			/*
			if doom.cvars and doom.cvars.techniColorCorpses and doom.cvars.techniColorCorpses.value then
				mobj.color = P_RandomKey(#doom.oolors)
			end
			*/
		end
		mobj.doom.maxhealth = mobj.info.spawnhealth or 10
		mobj.doom.health = mobj.doom.maxhealth
		mobj.doom.flags = mobj.info.doomflags or 0

		-- Handle skin color flags for translation
		local flags = mobj.doom.flags
		local color_flags = flags & (DF_SKINCOLOR1|DF_SKINCOLOR2)
		if color_flags ~= 0 then
			-- Determine which color combination
			local color_num
			if color_flags == (DF_SKINCOLOR1|DF_SKINCOLOR2) then
				color_num = 3  -- Both flags set
			elseif color_flags == DF_SKINCOLOR1 then
				color_num = 1  -- Only first flag
			elseif color_flags == DF_SKINCOLOR2 then
				color_num = 2  -- Only second flag
			end

			if color_num then
				-- Convert to MPCOLOR# (like "MPCOLOR1", "MPCOLOR2", etc.)
				mobj.translation = "MPCOLOR"..color_num
			end
		end
	end
	mobj.doom.height = mobj.info.height
	mobj.doom.spawnpoint = {x = mobj.x, y = mobj.y, z = mobj.z, angle = mobj.angle}
end)

addHook("MusicChange", function(_, newname, mflags, looping, position, prefade, fadein)
	if newname == "_clear" then
		if doom.isdoom1 then
			return "INTER"
		else
			return "DM2INT"
		end
	end
end)

local function playChatSound(player)
	if doom.isdoom1 then
		S_StartSound(nil, sfx_tink, player)
	else
		S_StartSound(nil, sfx_radio, player)
	end
end

-- "SIGMA PLAYER: THIS IS MY SIGMA MESSAGE!"
-- force caps lock because it's funny
addHook("PlayerMsg", function(source, type, target, msg)
	-- Play sound depending on Doom version

	-- Construct base message and force uppercase
	local baseMessage = (source.name .. ": " .. msg)--:upper()

	if type == 0 then
		-- Say to all players
		for player in players.iterate do
			playChatSound(player)
			chatprintf(player, baseMessage)
		end
	elseif type == 1 then
		-- Say to team only
		for player in players.iterate do
			if player.ctfteam != source.ctfteam then continue end
			playChatSound(player)
			chatprintf(player, "[TEAM] " .. baseMessage)
		end
	elseif type == 2 then
		-- Private message to target
		if target then
			playChatSound(target)
			local message = "[PRIVATE] " .. baseMessage
			if target == source then
				target.doom.num_nobrainers = ($ or 0) + 1
				local num_nobrainers = target.doom.num_nobrainers
				if num_nobrainers < 3 then
					message = DOOM_ResolveString("$HUSTR_TALKTOSELF1")
				elseif num_nobrainers < 6 then
					message = DOOM_ResolveString("$HUSTR_TALKTOSELF2")
				elseif num_nobrainers < 9 then
					message = DOOM_ResolveString("$HUSTR_TALKTOSELF3")
				elseif num_nobrainers < 32 then
					message = DOOM_ResolveString("$HUSTR_TALKTOSELF4")
				else
					message = DOOM_ResolveString("$HUSTR_TALKTOSELF5")
				end
				CONS_Printf(target, message)
			else
				chatprintf(target, message)
			end
		end
	else
		return
	end
	return true
end)
/*
not right now
doom.currentCommands = {}
doom.commandLookup = {}

local function SplitCommand(command)
	local space = command:find(" ", 1, true)

	if not space then
		return command, nil
	end

	return command:sub(1, space-1), command:sub(space+1)
end

function doom.registerCommand(command, func, defaultbind)
	if not command or not func then
		return
	end

	local basename, defaultarg = SplitCommand(command)

	-- Replace existing command if already registered
	local existing = doom.commandLookup[basename]
	if existing then
		existing.func = func
		return existing
	end

	local cmd = {
		name = basename,
		fullname = command,
		defaultarg = defaultarg,
		func = func
	}

	doom.commandLookup[basename] = cmd
	doom.currentCommands[#doom.currentCommands+1] = cmd

	if defaultbind then
		if type(defaultbind) == "table" then
			for i = 1, #defaultbind do
				local bindinfo = defaultbind[i]

				if type(bindinfo) == "table" then
					local fullcmd = basename

					if bindinfo[1] and bindinfo[1] ~= "" then
						fullcmd = $ .. " " .. bindinfo[1]
					end

					doom.defaultBinds[bindinfo[2]] = {
						command = basename,
						arguments = bindinfo[1]
							and {bindinfo[1]}
							or nil
					}
				else
					doom.defaultBinds[bindinfo] = {
						command = command
					}
				end
			end
		else
			doom.defaultBinds[defaultbind] = {
				command = basename,
				arguments = defaultarg and {defaultarg} or nil
			}
		end
	end

	return cmd
end

doom.registerCommand("jump", function(player, held)
	
end, "space")

doom.registerCommand("use", function(player, held)
	
end, "e")

doom.registerCommand("reload", function(player, held)
	
end, "r")

local debug = CV_RegisterVar({
	name = "doom_debug_printmissingbinds",
	PossibleValue = CV_TrueFalse,
	defaultvalue = 0
})

addHook("PlayerThink", function(player)
	player.doom.binds = $ or doom.defaultBinds

	if not player.valid then
		return
	end

	for i = 1, #doom.currentCommands do
		local cmd = doom.currentCommands[i]

		local bind, down, justpressed, held =
			doom.GetBindState(player, cmd.name)

		if down then
			cmd.func(player, not justpressed)
		end
	end
end)

function doom.BuildCommand(bind)
	if not bind or not bind.command or bind.command == "" then
		return nil
	end

	local text = tostring(bind.command)
	local args = bind.arguments or {}

	for i = 1, #args do
		local arg = args[i]
		if arg ~= nil and arg ~= "" then
			arg = tostring(arg)

			-- Quote args that contain spaces or quotes.
			if arg:find("[%s\"]") then
				arg = '"' .. arg:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
			end

			text = $ .. " " .. arg
		end
	end

	return text
end

function doom.GetBind(player, bindname)
	if not player or not player.valid then
		return nil
	end

	local doom = player.doom
	local binds = doom and doom.binds
	if not binds then
		return nil
	end

	return binds[bindname]
end

function doom.GetBindState(player, bindname)
	local bind = doom.GetBind(player, bindname)
	if not bind then
		return nil, false, false, false
	end

	local down = bind.down == true
	local justpressed = bind.pressedtic == leveltime
	local held = down and bind.heldtime and bind.heldtime > 0
		and (leveltime - bind.pressedtic) >= bind.heldtime

	return bind, down, justpressed, held
end

function doom.BindDown(player, bindname)
	local _, down  = doom.GetBindState(player, bindname)
	return down
end

function doom.BindHeld(player, bindname)
	local _, _, _, held = doom.GetBindState(player, bindname)
	return held
end

function doom.BindJustPressed(player, bindname)
	local _, _, justpressed = doom.GetBindState(player, bindname)
	return justpressed
end

COM_AddCommand("_doomkb", function(player, sentleveltime, bindname, state)
	if not player
	or not player.valid
	or not bindname
	then
		return
	end

	sentleveltime = tonumber(sentleveltime)
	state = tonumber(state)

	if sentleveltime != leveltime then
		return
	end

	player.doom = player.doom or {}
	player.doom.binds = player.doom.binds or {}

	local bind = player.doom.binds[bindname]
	if not bind then
		return
	end

	if state then
		bind.down = true
		bind.pressedtic = leveltime
		bind.justpressed = true

		local cmd = doom.BuildCommand(bind)
		if cmd then
			COM_BufInsertText(player, cmd)
		end
	else
		bind.down = false
		bind.releasedtic = leveltime
	end
end)

local function OnKeyDown(keyevent)
	if not consoleplayer then return end
	local bindIgnores = P_GetPlayerSkinProperties(consoleplayer).ignorebinds
	if bindIgnores == true then return end

	local bindEntry = consoleplayer.doom
		and consoleplayer.doom.binds
		and consoleplayer.doom.binds[keyevent.name]

	if not bindEntry then
		if debug.value then print(keyevent.name) end
		return false
	end
	if type(bindIgnores) == "table" and bindIgnores[bindEntry] then return end

	if not keyevent.repeated then
		COM_BufInsertText(
			consoleplayer,
			"_doomkb " .. leveltime .. " " .. keyevent.name .. " 1"
		)
	end

	return true
end

local function OnKeyUp(keyevent)
	if not consoleplayer then return end
	local bindIgnores = P_GetPlayerSkinProperties(consoleplayer).ignorebinds
	if bindIgnores == true then return end

	local bindEntry = consoleplayer.doom
		and consoleplayer.doom.binds
		and consoleplayer.doom.binds[keyevent.name]

	if not bindEntry then
		return false
	end
	if type(bindIgnores) == "table" and bindIgnores[bindEntry] then return end

	COM_BufInsertText(
		consoleplayer,
		"_doomkb " .. leveltime .. " " .. keyevent.name .. " 0"
	)

	return true
end

addHook("KeyDown", OnKeyDown)
addHook("KeyUp", OnKeyUp)
*/