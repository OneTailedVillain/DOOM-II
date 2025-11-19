local function deepcopy(orig)
	local orig_type = type(orig)
	if orig_type ~= 'table' then
		if orig_type == "boolean" then
			return orig == true
		else
			return tonumber(orig) == nil and tostring(orig) or tonumber(orig)
		end
	end
	local copy = {}
	for k, v in next, orig, nil do
		copy[deepcopy(k)] = deepcopy(v)
	end
	return copy
end


DOOM_Freeslot("sfx_doropn", "sfx_dorcls", "sfx_bdopn", "sfx_bdcls",
"sfx_stnmov")


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
        sector = sector,
        darktime = fastOrSlow,
        brighttime = STROBEBRIGHT,
        maxlight = sector.lightlevel,
        minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
        count = 0
    }
    
    -- Adjust minlight if necessary
    if (flash.minlight == flash.maxlight) then
        flash.minlight = 0
    end
    
    -- Set initial count based on sync
    if (not inSync) then
        flash.count = (DOOM_Random() & 7) + 1
    else
        flash.count = 1
    end
    
    -- Add to thinker system
    doom.subthinkers[sector] = flash
end

local function P_SpawnGlowingLight(sector)
    local glow = {
        type = "glow",
        sector = sector,
        minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
        maxlight = sector.lightlevel,
        direction = -1
    }

    doom.subthinkers[sector] = glow
end

local function P_SpawnLightFlash(sector)
    local flash = {
        type = "flash",
        sector = sector,
        maxlight = sector.lightlevel,
        minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
        maxtime = 64,
        mintime = 7,
        count   = (DOOM_Random() & 64) + 1,
    }

    doom.subthinkers[sector] = flash
end

addHook("MapLoad", function(mapid)
	doom.kills = 0
	doom.killcount = 0
	doom.items = 0
	doom.itemcount = 0
	doom.secrets = 0
	doom.secretcount = 0
	doom.textscreen.active = false
	for mobj in mobjs.iterate() do
		local mthing = mobj.spawnpoint
		if not mthing then
			continue
		end
		if (mthing.z & 1) then
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
	doom.thinkers = {}
	doom.torespawn = {}
	doom.sectorspecials = {}
	doom.sectorbackups = {}
	doom.switches = {}

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

	for line in lines.iterate do
		if line.special <= 940 then continue end
		doom.linespecials[line] = line.special - 941
		if doom.linespecials[line] == 48 then
			DOOM_AddThinker(line, doom.lineActions[48])
		end
		-- line.special = 0
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

	for player in players.iterate do
		player.doom = $ or {}
		player.doom.killcount = 0
	end

	local mthingReplacements = {
		[5] = MT_DOOM_BLUEKEYCARD,
		[6] = MT_DOOM_YELLOWKEYCARD,
		[8] = MT_DOOM_BACKPACK,
		[9] = MT_DOOM_SHOTGUNNER,
		[10] = MT_DOOM_BLOODYMESS,
		[13] = MT_DOOM_REDKEYCARD,
		[14] = MT_DOOM_TELETARGET,
		[15] = MT_DOOM_CORPSE,
		[16] = MT_DOOM_CYBERDEMON,
		[31] = MT_DOOM_SHORTGREENPILLAR,
	}

	for mthing in mapthings.iterate do
		if (mthing.z & 1) then
			continue
		end
		if mthingReplacements[mthing.type] then
			local x = mthing.x*FRACUNIT
			local y = mthing.y*FRACUNIT
			local z
			if mthing.mobj and (mthing.mobj.info.flags & MF_SPAWNCEILING) then
				z = P_CeilingzAtPos(x, y, 0, 0)
			else
				z = P_FloorzAtPos(x, y, 0, 0)
			end
			local teleman = P_SpawnMobj(x, y, z, mthingReplacements[mthing.type])
			teleman.angle = FixedAngle(mthing.angle*FRACUNIT)
		end
		if mthing.mobj and ((mthing.mobj.info.doomflags or 0) & DF_COUNTKILL) then
			doom.killcount = ($ or 0) + 1
			print(tostring(doom.killcount) .. " enemies total")
		end
		if mthing.mobj and ((mthing.mobj.info.doomflags or 0) & DF_COUNTITEM) then
			doom.itemcount = ($ or 0) + 1
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
}

-- BuildStairs: iterative stair builder using DOOM_AddThinker
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

    local newt = {
        type = "floor",
        speed = speed,
        target = startsec.floorheight + stairsize,
        -- any stair-only fields you want
    }
	doom.thinkers[startsec] = newt

    local created = 0
    local created_list = {}

    local base_height = startsec.floorheight or 0

    local MAX_ENQUEUED = 20000 -- safety cap (tweak or remove if you want)
    while head <= tail do
        if (tail - head) > MAX_ENQUEUED then
            -- safety bail-out to avoid pathological levels
            break
        end

        local entry = queue[head]; head = head + 1
        local sec = entry.sec
        local step = entry.step
        local dest = base_height + (step * stairsize)

        -- If sector already has a thinker, skip creating another; DOOM_AddThinker also checks this,
        -- but avoiding unnecessary template allocs is nice.
        if not doom.thinkers[sec] then
            -- prepare a template for the floor thinker; DOOM_AddThinker will deepcopy it
            local floorTemplate = {
                type = "floor",    -- your code expects data.type == "floor"
                speed = speed,
                target = dest,     -- your floor thinker reads `data.target`
                -- you can add any other default fields your thinker needs
            }
            DOOM_AddThinker(sec, floorTemplate)
            created = created + 1
            created_list[#created_list + 1] = sec
        end

        -- iterate lines on this sector and enqueue valid backsides
        for i = 0, #sec.lines - 1 do
            local line = sec.lines[i]
            -- skip one-sided lines
            if (line.flags & ML_TWOSIDED) == 0 then
                continue
            end

            -- DOOM-style orientation check: current sector must be the frontsector
            if line.frontsector ~= sec then
                continue
            end

            local backsec = line.backsector
            -- require same floor texture (as in DOOM)
            if backsec.floorpic ~= sec.floorpic then
                continue
            end

            -- skip if already moving / has thinker
            if doom.thinkers[backsec] then
                continue
            end

            -- skip if we've already enqueued it
            if visited[backsec] then
                continue
            end

            -- enqueue neighbor with step+1
            tail = tail + 1
            queue[tail] = { sec = backsec, step = step + 1 }
            visited[backsec] = true
        end
    end

    return { created = created, sectors = created_list }
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
				data.allowOff = data.allowOff or data.\repeatable
				data.onSound = data.onSound or sfx_swtchn
				data.offSound = data.offSound or sfx_swtchx
				data.delay = data.delay or TICRATE
			end
		end

		local player = data.switcher.player

		if data.lock and not (player.doom.keys & data.lock) then
			DOOM_DoMessage(player, data.denyMessage or "YOU FORGOT TO SET A MESSAGE FOR THIS!")
			S_StartSound(data.switcher, sfx_noway)
			doom.thinkers[line] = nil
			return
		end

		if not data.started then
			if data.victimTextureArea then
				S_StartSound(data.switcher, data.onSound)
				line.frontside[data.victimTextureArea] = data.onTexture
			end
			if not data.owner then
				for sector in sectors.tagged(data.victimTag) do
					DOOM_AddThinker(sector, data.victimData)
				end
			else
				DOOM_AddThinker(data.victimLine.backsector, data.victimData)
			end
			data.started = true
		end

		-- if not data.victimData.repeatable...
		-- Effectively locks out using the switch again
		if not data.allowOff then return end

		-- The semi-animation for when the switch is repeatable
		-- Questionable name? Sure, why the hell not!
		if data.delay then
			data.delay = $ - 1
		else
			if data.victimTextureArea then
				S_StartSound(data.switcher, data.onSound)
				line.frontside[data.victimTextureArea] = data.offTexture
			end
			doom.thinkers[line] = nil
		end
	end,

	door = function(sector, data)
		-- opening
		if not data.reachedGoal then
			local target = P_FindLowestCeilingSurrounding(sector) - 4*FRACUNIT
			local speed = data.fastdoor and 8*FRACUNIT or 2*FRACUNIT

			if not data.init then
				if data.fastdoor then
					S_StartSound(sector, sfx_bdopn)
				else
					S_StartSound(sector, sfx_doropn)
				end
				data.init = true
			end

			sector.ceilingheight = $ + speed

			if sector.ceilingheight >= target then
				sector.ceilingheight = target
				data.reachedGoal = true
				data.waitClock = data.delay or 150
			end

		-- waiting
		elseif data.waitClock and data.waitClock > 0 then
			if data.stay then return end
			data.waitClock = $ - 1

		-- closing
		else
			local target = sector.floorheight
			local speed = data.fastdoor and 8*FRACUNIT or 2*FRACUNIT

			if data.init then
				if data.fastdoor then
					S_StartSound(sector, sfx_bdcls)
				else
					S_StartSound(sector, sfx_dorcls)
				end
				data.init = false
			end

			sector.ceilingheight = $ - speed

			if sector.ceilingheight <= target then
				sector.ceilingheight = target

				-- remove thinker
				doom.thinkers[sector] = nil

				-- if repeatable, reset any flags for next trigger
				if data.repeatable then
					data.reachedGoal = false
					data.waitClock = nil
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
				doom.thinkers[sector] = nil

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

		if not data.goingUp then
			local target = (doom.sectorbackups[sector].floor or 0) + 8*FRACUNIT
			local speed = data.speed == "fast" and 4*FRACUNIT or 1*FRACUNIT

			if not (sector and sector.valid) then return end

			sector.ceilingheight = $ - speed

			if sector.ceilingheight <= target then
				S_StartSound(sector, sfx_pstop)
				sector.ceilingheight = target
				data.goingUp = true
			end
		else
			local target = doom.sectorbackups[sector].ceil or 0
			local speed = data.speed == "fast" and 4*FRACUNIT or 1*FRACUNIT

			sector.ceilingheight = $ + speed

			if sector.ceilingheight >= target then
				S_StartSound(sector, sfx_pstop)
				sector.ceilingheight = target
				data.goingUp = false
			end
		end
	end,
	
	scroll = function(line, data)
		local side = sides[line.sidenum[0]]
		if data.direction == "left" then
			side.textureoffset = $ + FRACUNIT
		else
			side.textureoffset = $ - FRACUNIT
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
		local stepSize = data.amount * FRACUNIT
		local speed = data.speed == "fast" and FRACUNIT*4 or FRACUNIT/4
		BuildStairs(sector, stepSize, speed)
	end,
	
	floor = function(sector, data)
		local target
		local dir = "up"
		local FLOORSPEED = type(data.speed) == "number" and data.speed or 2*FRACUNIT
		if not (sector and sector.valid) then return end
		if type(data.target) == "number" then
			target = data.target
		elseif data.target == "nextfloor" then
			target = P_FindNextHighestFloor(sector, sector.floorheight)
		elseif data.target == "highest" then
			target = P_FindHighestFloorSurrounding(sector)
			dir = "down"
		elseif data.target == "8abovehighest" then
			target = P_FindHighestFloorSurrounding(sector) + 8 * FRACUNIT
		elseif data.target == "lowestceiling" then
			target = P_FindLowestCeilingSurrounding(sector)
		elseif data.target == "8belowceiling" then
			target = P_FindLowestCeilingSurrounding(sector) - 8 * FRACUNIT
		elseif data.target == "lowest" then
			target = P_FindLowestFloorSurrounding(sector)
			dir = "down"
		elseif data.target == "shortestlowertex" then
			-- wiki fallback value when no surrounding lower texture exists
			local DEFAULT_TARGET = 32000 * FRACUNIT

			local best = DEFAULT_TARGET

			-- iterate the linedefs touching this sector
			for i = 0, #sector.lines - 1 do
				local line = sector.lines[i]
				-- determine which side is the "other" side (the side not belonging to `sector`)
				local othersec, texnum

				if line.frontsector == sector and line.backsector then
					othersec = line.backsector
					texnum = line.backside and line.backside.bottomtexture or 0
				elseif line.backsector == sector and line.frontsector then
					othersec = line.frontsector
					texnum = line.frontside and line.frontside.bottomtexture or 0
				end

				-- only consider this boundary if there *is* a lower texture on the opposite side
				if othersec and texnum ~= 0 then
					-- Simple candidate: neighbouring floor height
					local candidate = othersec.floorheight

					-- If we have a texture object and it reports a .height (in pixels), use it
					-- to get a more accurate "texture bottom" height: othersec.floor + texture.height.
					local tex = doom.texturesByNum[texnum]
					if tex and tex.height and tex.height > 0 then
						candidate = othersec.floorheight + (tex.height * FRACUNIT)
					end

					-- keep the smallest candidate (shortest)
					if candidate < best then
						best = candidate
					end
				end
			end

			target = best
		else
			print("No defined target for '" .. tostring(data.target) .. "'!")
			doom.thinkers[sector] = nil
			return
		end
		
		local speed = data.speed == "fast" and FLOORSPEED*4 or FLOORSPEED
		if dir == "up" then
			sector.floorheight = $ + speed
		else
			sector.floorheight = $ - speed
		end
		
		if not (leveltime & 7) then
			S_StartSound(sector, sfx_stnmov)
		end

		if dir == "up" then
			if sector.floorheight >= target then
				sector.floorheight = target
				doom.thinkers[sector] = nil
				local newfloor = deepcopy(sector.floorheight)
				doom.sectorbackups[sector].floor = newfloor
				S_StartSound(sector, sfx_pstop)
			end
		else
			if sector.floorheight <= target then
				sector.floorheight = target
				doom.thinkers[sector] = nil
				local newfloor = deepcopy(sector.floorheight)
				doom.sectorbackups[sector].floor = newfloor
				S_StartSound(sector, sfx_pstop)
			end
		end
	end,
	
	ceiling = function(sector, data)
		local target
		local dir = 1
		local FLOORSPEED = 2*FRACUNIT
		if data.target == "nextfloor" then
			target = P_FindNextHighestFloor(sector, sector.floorheight)
		elseif data.target == "lowestceiling" then
			target = P_FindLowestCeilingSurrounding(sector)
		elseif data.target == "8belowceiling" then
			target = P_FindLowestCeilingSurrounding(sector) - 8 * FRACUNIT
		else
			print("No defined target for '" .. tostring(data.target) .. "'!")
			return
		end
		
		local speed = data.speed == "fast" and FLOORSPEED*4 or FLOORSPEED
		sector.floorheight = $ + speed
		
		if not (leveltime & 7) then
			S_StartSound(sector, sfx_stnmov)
		end
		
		if sector.floorheight >= target then
			sector.floorheight = target
			doom.thinkers[sector] = nil
			local newfloor = deepcopy(sector.floorheight)
			doom.sectorbackups[sector].floor = newfloor
			S_StartSound(sector, sfx_pstop)
		end
		
		for i = 0, #sector.lines-1 do
			
		end
	end,
	
	light = function(sector, data)
		sector.lightlevel = data.target or 35
		doom.thinkers[sector] = nil
	end,
}

local function thinkFrameIterator(any, data, thinkertable)
		if not (any and any.valid) then doom[thinkertable][any] = nil return end
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

addHook("ThinkFrame", function()
	for any, data in pairs(doom.thinkers) do
		thinkFrameIterator(any, data, "thinkers")
	end

	for any, data in pairs(doom.subthinkers) do
		thinkFrameIterator(any, data, "subthinkers")
	end

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
		if player.mo.doom.flags & DF_SHADOW then
			player.mo.frame = $ | FF_MODULATE
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
		mobj.doom.maxhealth = mobj.info.spawnhealth or 10
		mobj.doom.health = mobj.doom.maxhealth
		mobj.doom.flags = mobj.info.doomflags or 0
		if MFE_DOOMENEMY then
			mobj.eflags = $ | MFE_DOOMENEMY
		end
	end
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

-- "SIGMA PLAYER: THIS IS MY SIGMA MESSAGE!"
-- force caps lock because its funny
addHook("PlayerMsg", function(source, type, target, msg)
	if doom.isdoom1 then
		S_StartSound(nil, sfx_tink)
	else
		S_StartSound(nil, sfx_radio)
	end
	local baseMessage = source.name .. ":\n" .. msg
	baseMessage = $:upper()
	if type == 0 then
		for player in players.iterate do
			DOOM_DoMessage(player, baseMessage)
		end
	elseif type == 1 then
		for player in players.iterate do
			if player.ctfteam != source.ctfteam then continue end
			DOOM_DoMessage(player, "[TEAM] " .. baseMessage)
		end
	elseif type == 2 then
		DOOM_DoMessage(player, "[PRIVATE] " .. baseMessage)
	end
	return true
end)