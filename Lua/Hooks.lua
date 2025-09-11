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
    DOOM_AddThinker(sector, flash)
end

local function P_SpawnGlowingLight(sector)
    local glow = {
        type = "glow",
        sector = sector,
        minlight = P_FindMinSurroundingLight(sector, sector.lightlevel),
        maxlight = sector.lightlevel,
        direction = -1
    }

    DOOM_AddThinker(sector, glow)

    sector.special = 0
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

    DOOM_AddThinker(sector, flash)
end

addHook("MapLoad", function(mapid)
	doom.kills = 0
	doom.killcount = 0
	doom.items = 0
	doom.itemcount = 0
	doom.secrets = 0
	doom.secretcount = 0
	for mobj in mobjs.iterate() do
		mobj.flags2 = $ & ~MF2_OBJECTFLIP
		mobj.eflags = $ & ~MFE_VERTICALFLIP
		if not (mobj.info.flags & MF_SPAWNCEILING) then
			mobj.z = P_FloorzAtPos(mobj.x, mobj.y, mobj.z, 0) -- mobj.floorz
		end
	end
	doom.linespecials = {}
	doom.linebackups = {}
	doom.thinkers = {}
	for line in lines.iterate do
		if line.special == 940 then continue end
		doom.linespecials[line] = line.special - 941
		if doom.linespecials[line] == 48 then
			DOOM_AddThinker(line, doom.lineActions[48])
		end
		-- line.special = 0
	end
	doom.sectorspecials = {}
	doom.sectorbackups = {}

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
		sector.gravity = -doom.defaultgravity
	end

	gravity = -doom.defaultgravity

	for player in players.iterate do
		player.doom.killcount = 0
	end

	local mthingReplacements = {
		[5] = MT_DOOM_BLUEKEYCARD,
		[6] = MT_DOOM_YELLOWKEYCARD,
		[9] = MT_DOOM_SHOTGUNNER,
		[10] = MT_DOOM_BLOODYMESS,
		[13] = MT_DOOM_REDKEYCARD,
		[14] = MT_DOOM_TELETARGET,
		[15] = MT_DOOM_CORPSE,
		[31] = MT_DOOM_SHORTGREENPILLAR,
	}

	for mthing in mapthings.iterate do
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
		end
		if mthing.mobj and ((mthing.mobj.info.doomflags or 0) & DF_COUNTITEM) then
			doom.itemcount = ($ or 0) + 1
		end
		if (mthing.z & 1) and mthing.mobj then
			P_RemoveMobj(mthing.mobj)
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
}

local thinkers = {
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
			local speed = data.fastdoor and 8*FRACUNIT or 4*FRACUNIT

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
		if not data.goingUp then
			local target = (doom.sectorbackups[sector].floor or 0) + 8*FRACUNIT
			local speed = data.speed == "fast" and 4*FRACUNIT or 1*FRACUNIT

			if not data.init then
				S_StartSound(sector, sfx_pstart)
				data.init = true
			end

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

			if data.init then
				S_StartSound(sector, sfx_pstart)
				data.init = false
			end

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
	
	floor = function(sector, data)
		local target
		local dir = "up"
		local FLOORSPEED = 2*FRACUNIT
		if not (sector and sector.valid) then return end
		if data.target == "nextfloor" then
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
	end,
}

addHook("ThinkFrame", function()
	for any, data in pairs(doom.thinkers) do
		if any == nil then doom.thinkers[any] = nil continue end
		if data == nil then continue end
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