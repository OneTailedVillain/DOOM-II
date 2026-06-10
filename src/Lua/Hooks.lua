local PLATWAIT = 3
local PLATSPEED = FRACUNIT

DOOM_Freeslot("sfx_doropn", "sfx_dorcls", "sfx_bdopn", "sfx_bdcls",
"sfx_stnmov")

local function stop_plats_by_tag(tag)
	if not tag then return end
	for sec, v in pairs(doom.thinkers) do
		if type(v) == "table" and (v.action == "oscillate" or v.action == "oscillate_stop" or v.isPlatLike) then
			if v.tag and v.tag == tag then
				doom.stopThinker(sec)
			end
		end
	end
end

local function getNextSector(line, sector)
	-- check front/back sector relation
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
	for mobj in mobjs.iterate() do
		local mthing = mobj.spawnpoint
		if not mthing then
			continue
		end
		if (mthing.z & 1) and not multiplayer then
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
		deathmatch = {}
	}

	for i = 1, doom.playerStarts do
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

	for line in lines.iterate do
		if line.special <= 940 then doom.linespecials[line] = 0 continue end

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

	for mthing in mapthings.iterate do
		if (mthing.z & 1) and not multiplayer then
			continue
		end

		local needed = SkillMaskFor(doom.gameskill)
		if not (mthing.options & needed) then
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

		local override = doom.callHook(
			"MapThingSpawn",
			doom.hookTypes.lastfunc,
			mthing
		)

		if override == false then
			continue -- block spawn completely
		elseif override != nil then
			mthing.type = override -- override doomednum
		end

		if doom.mthingReplacements[mthing.type] then
			if not (gametyperules & GTR_SPAWNENEMIES) then
				local objinfo = mobjinfo[doom.mthingReplacements[mthing.type]]
				if (objinfo.flags & MF_ENEMY) then
					continue
				end
			end

			local x = mthing.x*FRACUNIT
			local y = mthing.y*FRACUNIT
			local z
			if mthing.mobj and (mthing.mobj.info.flags & MF_SPAWNCEILING) then
				z = P_CeilingzAtPos(x, y, 0, 0)
			else
				z = P_FloorzAtPos(x, y, 0, 0)
			end
			local teleman = P_SpawnMobj(x, y, z, doom.mthingReplacements[mthing.type])
			teleman.angle = FixedAngle(mthing.angle*FRACUNIT)
			if teleman and ((teleman.info and teleman.info.doomflags or 0) & DF_COUNTKILL) then
				doom.killcount = ($ or 0) + 1
			end
			if teleman and ((teleman.info and teleman.info.doomflags or 0) & DF_COUNTITEM) then
				doom.itemcount = ($ or 0) + 1
			end
		end

		-- Player starts
		if mthing.type >= 1 and mthing.type <= doom.playerStarts then
			table.insert(doom.spawnpoints.player[mthing.type], {
				x = mthing.x * FRACUNIT,
				y = mthing.y * FRACUNIT,
				z = P_FloorzAtPos(x, y, 0, 0),
				angle = FixedAngle(mthing.angle * FRACUNIT),
				mthing = mthing
			})
		-- Deathmatch starts
		elseif mthing.type == doom.deathmatchDoomEdNum then
			table.insert(doom.spawnpoints.deathmatch, {
				x = mthing.x * FRACUNIT,
				y = mthing.y * FRACUNIT,
				z = P_FloorzAtPos(x, y, 0, 0),
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

		local function getPlayerSpawn(preferred)
			for i = 0, 3 do
				local slot = ((preferred - 1 + i) % 4) + 1
				local list = doom.spawnpoints.player[slot]

				if list and list[#list] then
					return list[#list]
				end
			end
		end

		if (gametyperules & GTR_RINGSLINGER) then
			local matchspawncount = #doom.spawnpoints.deathmatch
			if matchspawncount > 0 then
				local pspawn_index = P_RandomKey(matchspawncount) + 1
				local pspawn = doom.spawnpoints.deathmatch[pspawn_index]

				P_SetOrigin(player.mo, pspawn.x, pspawn.y, pspawn.z)
				player.mo.angle = pspawn.angle
				player.drawangle = pspawn.angle
			end
		else
			local pnum = #player
			local preferred = (pnum % 4) + 1
			local pspawn = getPlayerSpawn(preferred)

			if pspawn then
				P_SetOrigin(player.mo, pspawn.x, pspawn.y, pspawn.z)
				player.mo.angle = pspawn.angle
				player.drawangle = pspawn.angle
			end
		end
	end
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

local expectedUserdatas = {
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
}

local function sectorHasUnfittableObject(a, b, c, d)
	-- resolve args to bounds
	local minx, maxx, miny, maxy

	if a and a.lines then
		-- 'a' is a sector_t, compute bounding box from its lines
		minx = INT32_MAX
		maxx = INT32_MIN
		miny = INT32_MAX
		maxy = INT32_MIN

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
local function BuildStairs(startsec, stairsize, speed)
	if not startsec then return { created = 0, sectors = {} } end

	local queue = {}
	local head, tail = 1, 1
	-- queue entries are { sec = <sector>, step = <int> }
	queue[tail] = { sec = startsec, step = 1 }

	-- visited keyed by sector object to avoid duplicates
	local visited = {}
	visited[startsec] = true

	local created = 0
	local created_list = {}

	local base_height = startsec.floorheight or 0

	local MAX_ENQUEUED = 20000 -- safety cap (tweak or remove if you want)
	while head <= tail do
		if (tail - head) > MAX_ENQUEUED then
			break -- safety bail-out
		end

		local entry = queue[head]; head = head + 1
		local sec = entry.sec
		local step = entry.step
		local dest = base_height + (step * stairsize)

		-- create floor thinker for this sector
		local floorTemplate = {
			type = "floor",   -- thinker type
			speed = speed,
			target = dest,	-- final floor height
			action = "raise", -- default action
		}

		-- doom.addThinker allows multiple thinkers, no need for doom.thinkers[sec]
		doom.addThinker(sec, floorTemplate)
		created = created + 1
		created_list[#created_list + 1] = sec

		-- enqueue neighbor sectors to form stairs
		for i = 0, #sec.lines - 1 do
			local line = sec.lines[i]

			-- skip one-sided lines
			if (line.flags & ML_TWOSIDED) == 0 then continue end

			-- must be frontsector
			if line.frontsector ~= sec then continue end

			local backsec = line.backsector

			-- require same floor texture
			if backsec.floorpic ~= sec.floorpic then continue end

			-- skip if already enqueued
			if visited[backsec] then continue end

			-- enqueue neighbor
			tail = tail + 1
			queue[tail] = { sec = backsec, step = step + 1 }
			visited[backsec] = true
		end
	end

	return { created = created, sectors = created_list }
end

local function FindNextHighestFromBackups(sec, curHeight)
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
	return true
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

				if data.lock and not (player.doom.keys & data.lock) then
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
		local openTarget = P_FindLowestCeilingSurrounding(sector) - 4*FRACUNIT
		local closedTarget = sector.floorheight
		local speed = data.fastdoor and 8*FRACUNIT or 2*FRACUNIT

		-- init
		if not data.direction then
			-- default = open first
			data.direction = data.closewaitopen and -1 or 1
		end

		-- moving upward
		if data.direction == 1 then
			if not data.init then
				if data.fastdoor then
					S_StartSound(sector, sfx_bdopn)
				else
					S_StartSound(sector, sfx_doropn)
				end
				data.init = true
			end

			sector.ceilingheight = $ + speed

			if sector.ceilingheight >= openTarget then
				sector.ceilingheight = openTarget
				data.lastDirection = 1

				if data.stay or data.closewaitopen then
					doom.stopThinker(sector)

					if data.repeatable then
						data.direction = nil
						data.waitClock = nil
						data.init = nil
					end
				else
					data.direction = 0
					data.waitClock = data.delay or 150
				end
			end

		-- moving downward
		elseif data.direction == -1 then
			if data.init then
				if data.fastdoor then
					S_StartSound(sector, sfx_bdcls)
				else
					S_StartSound(sector, sfx_dorcls)
				end
				data.init = false
			end

			sector.ceilingheight = $ - speed

			-- crush check:
			-- only regular doors bounce back up
			if sectorHasUnfittableObject(sector) and not data.closewaitopen then
				if data.fastdoor then
					S_StartSound(sector, sfx_bdopn)
				else
					S_StartSound(sector, sfx_doropn)
				end

				data.direction = 1
				sector.ceilingheight = $ + speed
				return
			end

			if sector.ceilingheight <= closedTarget then
				sector.ceilingheight = closedTarget
				data.lastDirection = -1

				if data.closewaitopen then
					data.direction = 0
					data.waitClock = data.delay or 150
				else
					doom.stopThinker(sector)

					if data.repeatable then
						data.direction = nil
						data.waitClock = nil
						data.init = nil
					end
				end
			end

		-- waiting
		elseif data.direction == 0 then
			if data.stay then return end

			data.waitClock = $ - 1

			if data.waitClock <= 0 then
				-- resume opposite direction
				if data.closewaitopen then
					data.direction = 1
				else
					data.direction = -1
				end
			end
		end
	end,

	lift = function(sector, data)
		-- opening
		if not data.reachedGoal then
			local target = P_FindLowestFloorSurrounding(sector)
			local speed = data.speed == "fast" and 8*FRACUNIT or 4*FRACUNIT

			if not data.init then
				S_StartSound(sector, sfx_pstart)
				data.init = true
			end

			sector.floorheight = $ - speed

			if sector.floorheight <= target then
				S_StartSound(sector, sfx_pstop)
				sector.floorheight = target
				data.reachedGoal = true
				data.waitClock = data.delay or 150
			end

		-- waiting
		elseif data.waitClock and data.waitClock > 0 then
			data.waitClock = $ - 1

		-- closing
		else
			local target = doom.sectorbackups[sector].floor or 0
			local speed = data.speed == "fast" and 8*FRACUNIT or 4*FRACUNIT

			if data.init then
				S_StartSound(sector, sfx_pstart)
				data.init = false
			end

			sector.floorheight = $ + speed

			if sector.floorheight >= target then
				S_StartSound(sector, sfx_pstop)
				sector.floorheight = target

				-- remove thinker
				doom.stopThinker(sector)

				-- if repeatable, reset any flags for next trigger
				if data.repeatable then
					data.reachedGoal = false
					data.waitClock = nil
				end
			end
		end
	end,

	crusher = function(sector, data)
		if not data.silent then
			if not (leveltime & 7) then
				S_StartSound(sector, sfx_stnmov)
			end
		end

		local function calculateBounds(sector)
			local lowestX = INT32_MAX
			local highestX = INT32_MIN
			local lowestY = INT32_MAX
			local highestY = INT32_MIN

			for linenum = 0, #sector.lines - 1 do
				local line = sector.lines[linenum]
				for i = 1, 2 do
					local xPos = line["v" .. i].x
					local yPos = line["v" .. i].y

					if xPos < lowestX then lowestX = xPos end
					if xPos > highestX then highestX = xPos end
					if yPos < lowestY then lowestY = yPos end
					if yPos > highestY then highestY = yPos end
				end
			end

			return lowestX, highestX, lowestY, highestY
		end

		-- Helper: check if point is inside bounding box
		local function insideBounds(mobj, minx, maxx, miny, maxy)
			if not mobj or not mobj.valid then return false end

			local r = mobj.radius or 0

			if (mobj.x + r) < minx then return false end
			if (mobj.x - r) > maxx then return false end

			if (mobj.y + r) < miny then return false end
			if (mobj.y - r) > maxy then return false end

			return true
		end

		-- Iterate all mobjs and only act on those inside the calculated rectangle.
		-- This avoids relying on searchBlockmap's refmobj behavior.
		local lowestX, highestX, lowestY, highestY = calculateBounds(sector)

		-- Iterate all mobjs and act on those inside the calculated rectangle
		for mobj in mobjs.iterate() do
			if mobj and mobj.valid and insideBounds(mobj, lowestX, highestX, lowestY, highestY) then
				PIT_ChangeSector(mobj, true)
			end
		end

		if not data.goingUp then
			local target = (doom.sectorbackups[sector].floor or 0) + 8*FRACUNIT
			local speed = data.speed == "fast" and 4*FRACUNIT or 1*FRACUNIT
			if data.speed != "fast" and data.caughtObject then
				speed = $ / 8
			end

			if not (sector and sector.valid) then return end

			sector.ceilingheight = $ - speed

			if sector.ceilingheight <= target then
				S_StartSound(sector, sfx_pstop)
				sector.ceilingheight = target
				data.caughtObject = false
				data.goingUp = true
			end
		else
			local target = doom.sectorbackups[sector].ceil or 0
			local speed = data.speed == "fast" and 4*FRACUNIT or 1*FRACUNIT
			if data.speed != "fast" and data.caughtObject then
				speed = $ / 8
			end

			sector.ceilingheight = $ + speed

			if sector.ceilingheight >= target then
				S_StartSound(sector, sfx_pstop)
				sector.ceilingheight = target
				data.caughtObject = false
				data.goingUp = false
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
		side.textureoffset = $ + data.scrx
		side.rowoffset = $ + data.scry
	end,

	sectorscroll = function(sector, data)
		if data.place == "floor" then
			sector.floorxoffset = $ - data.scrx
			sector.flooryoffset = $ + data.scry
		end
	end,

	strobe = function(sector, data)
		if (data.count > 0) then
			data.count = data.count - 1
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
		if data.count > 0 then
			data.count = data.count - 1
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

		local stepSize = data.amount * FRACUNIT
		local speed = data.speed == "fast" and FRACUNIT*4 or FRACUNIT/4
		BuildStairs(sector, stepSize, speed)

		doom.stopThinker(sector)
	end,

	elevator = function(sector, data)
		-- Determine actual numeric targets if target is a string
		if type(data.target) == "string" then
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
			-- sector went away or invalid: remove thinker
			doom.stopThinker(sector)
			return
		end

		-- base speeds: keep compatibility with your existing logic
		local BASE_SPEED = type(data.speed) == "number" and data.speed or PLATSPEED
		local spd = (data.speed == "fast") and (BASE_SPEED * 4) or BASE_SPEED

		-- Infer action if caller didn't provide one
		if not data.action then
			if type(data.target) == "number" then
				-- Floor height target, but how do we deal with it?
				if data.target > sector.floorheight then
					data.action = "raise"
				elseif data.target < sector.floorheight then
					data.action = "lower"
				else
					doom.stopThinker(sector)
					return
				end
			elseif type(data.target) == "string" then
				if data.target == "lowest" then
					data.action = "lower"
				elseif data.target == "highest" or data.target == "8abovehighest" then
					data.action = "lower"
				else
					data.action = "raise"
				end
			else
				print("floor thinker: missing action and target")
				doom.stopThinker(sector)
				return
			end
		end

		-- Convenience fields used for platform-like behavior
		if data.action == "oscillate" and not data.init then
			-- init plat-like thinker (perpetualRaise / plat behaviour)
			data.isPlatLike = true
			-- determine low/high bounds if not provided
			data.low = data.low or P_FindLowestFloorSurrounding(sector)
			if data.low > sector.floorheight then data.low = sector.floorheight end
			data.high = data.high or P_FindHighestFloorSurrounding(sector)
			if data.high < sector.floorheight then data.high = sector.floorheight end
			-- default wait time (matches C: plat->wait = 35*PLATWAIT roughly)
			data.wait = data.wait or (35)
			-- status: up/down (randomize as in C if not provided)
			if not data.status then
				data.status = (DOOM_Random() & 1) == 1 and "up" or "down"
			end
			data.init = true
			S_StartSound(sector, sfx_pstart)
		end

		-- Immediate stop-plat action: remove existing plat thinkers that share the tag
		if data.action == "oscillate_stop" then
			stop_plats_by_tag(data.tag)
			-- remove this stop-thinker immediately (it is a single-shot command)
			doom.stopThinker(sector)
			return
		end

		-- Platform-like "oscillate" state machine (perpetual platforms, DWUS, blazeDWUS)
		if data.action == "oscillate" or data.action == "downWaitUpStay" or data.action == "blazeDWUS" or data.isPlatLike then
			-- map some possible names to internal behavior
			local speedMultiplier = 1
			if data.action == "downWaitUpStay" then
				speedMultiplier = 4
			elseif data.action == "blazeDWUS" then
				speedMultiplier = 8
			elseif data.speed == "fast" then
				speedMultiplier = 4
			end
			local platspd = spd * speedMultiplier

			-- ensure low/high exist (safety)
			data.low = data.low or P_FindLowestFloorSurrounding(sector)
			if data.low > sector.floorheight then data.low = sector.floorheight end
			data.high = data.high or sector.floorheight

			-- status: up / down / waiting
			if data.status == "up" then
				doom.sectorbackups[sector].lastTicFloorHeight = sector.floorheight
				sector.floorheight = sector.floorheight + platspd
				if sector.floorheight >= data.high then
					sector.floorheight = data.high
					data.status = "wait"
					data.waitClock = data.wait or 35
					S_StartSound(sector, sfx_pstop)
				end

			elseif data.status == "down" then
				sector.floorheight = sector.floorheight - platspd
				if sector.floorheight <= data.low then
					sector.floorheight = data.low
					data.status = "wait"
					data.waitClock = data.wait or 35
					S_StartSound(sector, sfx_pstop)
				end

			elseif data.status == "wait" then
				-- tick wait clock down
				data.waitClock = (data.waitClock or 0) - 1
				if data.waitClock <= 0 then
					-- toggle direction when wait expires
					if data.lastDir == "up" then
						data.status = "down"
						data.lastDir = "down"
					else
						data.status = "up"
						data.lastDir = "up"
					end
					-- play start sound for movement
					S_StartSound(sector, sfx_pstart)
				end
			end

			-- play movement sound occasionally like the C code (every 8 tics)
			if not data.isPlatLike then
				if not (leveltime & 7) then
					S_StartSound(sector, sfx_stnmov)
				end
			end

			-- persist: this thinker stays until externally stopped (unless you've requested single-shot)
			return
		end

		-- Standard raise/lower actions ------------------------------------------------
		if data.action == "raise" or data.action == "lower" then
			-- compute target
			local target = nil
			local dir = (data.action == "raise") and "up" or "down"

			if type(data.target) == "number" then
				target = data.target
			elseif data.target == "nextfloor" then
				target = FindNextHighestFromBackups(sector, sector.floorheight)
			elseif data.target == "highest" then
				target = P_FindHighestFloorSurrounding(sector); dir = "down"
			elseif data.target == "8abovehighest" then
				target = P_FindHighestFloorSurrounding(sector) + (8 * FRACUNIT)
				dir = "down"
			elseif data.target == "lowestceiling" then
				-- Also consider current ceiling height
				-- TODO: Does the source code actually do this?
				local curSecCeil = sector.ceilingheight
				target = P_FindLowestCeilingSurrounding(sector)
				if curSecCeil < target then
					target = curSecCeil
				end
				dir = "up"
			elseif data.target == "8belowceiling" then
				target = P_FindLowestCeilingSurrounding(sector) - (8 * FRACUNIT)
			elseif data.target == "lowest" then
				target = P_FindLowestFloorSurrounding(sector); dir = "down"
			elseif data.target == "shortestlowertex" then
				-- re-use your previous implementation for shortest lower texture
				local DEFAULT_TARGET = 32000 * FRACUNIT
				local best = DEFAULT_TARGET
				for i = 0, #sector.lines - 1 do
					local line = sector.lines[i]
					local othersec, texnum
					if line.frontsector == sector and line.backsector then
						othersec = line.backsector
						texnum = line.backside and line.backside.bottomtexture or 0
					elseif line.backsector == sector and line.frontsector then
						othersec = line.frontsector
						texnum = line.frontside and line.frontside.bottomtexture or 0
					end
					if othersec and texnum ~= 0 then
						local candidate = othersec.floorheight
						local tex = doom.texturesByNum[texnum]
						if tex and tex.height and tex.height > 0 then
							candidate = othersec.floorheight + (tex.height * FRACUNIT)
						end
						if candidate < best then best = candidate end
					end
				end
				target = best
			else
				-- unknown target
				print("floor thinker: unknown target '" .. tostring(data.target) .. "'")
				doom.stopThinker(sector)
				return
			end

			-- move sector toward target
			if dir == "up" then
				sector.floorheight = sector.floorheight + spd
			else
				sector.floorheight = sector.floorheight - spd
			end

			if not (leveltime & 7) then
				S_StartSound(sector, sfx_stnmov)
			end

			-- check if reached target
			if dir == "up" then
				if sector.floorheight >= target then
					sector.floorheight = target
					-- set sector backup and stop thinker
					local newfloor = deepcopy(sector.floorheight)
					doom.sectorbackups[sector].floor = newfloor
					-- handle "changes" (texture change) if caller provided newfloorpic
					if data.changes then
						if data.newfloorpic then
							sector.floorpic = data.newfloorpic
						end
						-- Can potentially be 0
						if data.newSectorSpecial != nil then
							sector.special = data.newSectorSpecial
						end
					end
					-- play stop sound
					S_StartSound(sector, sfx_pstop)
					-- crush behavior
					if data.crush then
						-- mark sector special if desired (C sets sec->special sometimes)
						sector.special = sector.special or 0
					end
					-- remove thinker
					doom.stopThinker(sector)
				end
			else
				if sector.floorheight <= target then
					sector.floorheight = target
					local newfloor = deepcopy(sector.floorheight)
					doom.sectorbackups[sector].floor = newfloor
					if data.changes and data.newfloorpic then
						sector.floorpic = data.newfloorpic
					end
					S_StartSound(sector, sfx_pstop)
					doom.stopThinker(sector)
				end
			end

			return
		end

		-- LIFT-style wait/return behaviour handled in the lift thinker.
		-- If we get something we don't recognize, remove the thinker.
		print("floor thinker: unhandled action '" .. tostring(data.action) .. "'")
		doom.stopThinker(sector)
	end,

	ceiling = function(sector, data)
		local target
		local dir = 1
		local FLOORSPEED = 2*FRACUNIT
		if data.target == "nextfloor" then
			target = FindNextHighestFromBackups(sector, sector.ceilingheight)
		elseif data.target == "lowestceiling" then
			target = P_FindLowestCeilingSurrounding(sector)
		elseif data.target == "highest" then
			target = P_FindHighestCeilingSurrounding(sector)
			dir = -1
		elseif data.target == "8belowceiling" then
			target = P_FindLowestCeilingSurrounding(sector) - 8 * FRACUNIT
		else
			print("No defined target for '" .. tostring(data.target) .. "'!")
			doom.stopThinker(sector)
			return
		end

		local speed = data.speed == "fast" and FLOORSPEED*4 or FLOORSPEED
		sector.ceilingheight = $ - (speed * dir)

		if type(target) == "string" then
			print("Bad target data '" .. tostring(target) .. "' for ceiling thinker, stopping...")
			doom.stopThinker(sector)
			return
		end

		if not (leveltime & 7) then
			S_StartSound(sector, sfx_stnmov)
		end

		if dir >= 1 then
			if sector.ceilingheight <= target then
				sector.ceilingheight = target
				doom.stopThinker(sector)
				local newfloor = sector.ceilingheight
				doom.sectorbackups[sector].ceil = newfloor
				S_StartSound(sector, sfx_pstop)
			end
		elseif dir <= -1 then
			if sector.ceilingheight >= target then
				sector.ceilingheight = target
				doom.stopThinker(sector)
				local newfloor = sector.ceilingheight
				doom.sectorbackups[sector].ceil = newfloor
				S_StartSound(sector, sfx_pstop)
			end
		end

		for i = 0, #sector.lines-1 do

		end
	end,

	light = function(sector, data)
		if type(data.target) == "string" then
			if data.target == "brightest_adjacent" then
				local brightest = INT32_MIN
				for linenum = 0, #sector.lines - 1 do
					---@type line_t
					local line = sector.lines[linenum]
					local frontside = sides[line.sidenum[0]]
					local backside = sides[line.sidenum[1]]
					local target
					if not backside then
						target = frontside.sector
					else
						if frontside.sector == sector then
							target = backside.sector
						else
							target = frontside.sector
						end
					end
					if target.lightlevel > brightest then
						brightest = target.lightlevel
					end
				end
				sector.lightlevel = brightest
			end
			print("Bad target data '" .. tostring(data.target) .. "' for light thinker, stopping...")
			doom.stopThinker(sector)
			return
		end
		sector.lightlevel = data.target or 35
		doom.stopThinker(sector)
	end,
}

local function thinkFrameIterator(any, data, thinkertable)
		if not (any and any.valid) then doom.stopThinker(any) return end
		if data == nil then return end
		local expected = expectedUserdatas[data.type]
		local actual = userdataType(any)

		if not expected then
			error("Unknown thinker type '" .. tostring(data.type) .. "'!")
		end

		if actual ~= expected then
			error("Incorrect userdata type for '" .. data.type .. "'! (" .. expected .. " expected, got " .. actual .. ")")
		end

		local fn = thinkers[data.type]
		if not fn then
			error("No thinker function defined for '" .. data.type .. "'!")
		end

		fn(any, data)
end

local function restartDoorOpposite(sector, data)
	-- If we're waiting, use the last real movement direction.
	-- Otherwise, flip the current movement direction.
	local dir = data.direction
	if dir == 0 or dir == nil then
		dir = data.lastDirection or (data.closewaitopen and -1 or 1)
	end

	data.lastDirection = dir
	data.direction = -dir
	data.waitClock = nil

	-- Force the correct startup sound for the new direction on the next tick.
	-- open  = init false
	-- close = init true
	data.init = (data.direction == -1)
end

local onThinkerRepeat = {
	door = function(sector, data)
		restartDoorOpposite(sector, data)
	end
}

doom.thinkerlist = doom.thinkerlist or {}

function doom.addThinker(any, thinkTable)
    if not any or thinkTable == nil then return end

    -- Check for existing thinker with same userdata and type
    for i, thinker in ipairs(doom.thinkerlist) do
        if thinker.userdata == any and thinker.data.type == thinkTable.type then
            -- Found duplicate - probably call onThinkerRepeat and return existing index without adding new one
			local onTR = onThinkerRepeat[thinker.data.type]
			if onTR then
				onTR(thinker.userdata, thinker.data)
			end
            return i
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
			if not P_GetSupportsForSkin(player).noPartialInvisEffect then
				player.mo.frame = $ | FF_ADD | FF_TRANS10
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
			if doom.cvars.techniColorCorpses.value then
				mobj.color = P_RandomKey(#doom.oolors)
			end
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
	local baseMessage = (source.name .. ": " .. msg):upper()

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