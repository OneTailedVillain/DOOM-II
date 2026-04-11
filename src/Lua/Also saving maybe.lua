/*
Header:
"DMRP" (DooM RePlay)
4 bytes Replay length in tics
2 bytes Map the replay was recorded in
1 byte  Skill level of the recording
1 byte  PRND index at the start of the recording
1 byte  skinname length
N bytes skinname

Stream:
1 byte type
    0 = delta input
        1 byte  delta forwardmove
        1 byte  delta sidemove
        2 bytes delta angleturn
        2 bytes delta aiming
        2 bytes buttons XOR previous

    1 = repeat last input (1 tic)
    2 = repeat last input N times (one byte)
        1 byte  repeat count
	3 = repeat last input N times (two bytes)
		2 bytes repeat count
	4 = no-delta input snapshot
		1 byte  forwardmove
		1 byte  sidemove
		2 bytes angleturn
		2 bytes aiming
		2 bytes buttons
(Delta input is initialized to zero)

Footer:
4 bytes checksum
*/

/*
Header:
"DMSV" (DooM SaVe)
1 byte  prndindex
2 bytes map ID
1 byte  skill level
4 bytes current time (tick count)

Player state:
1 byte  skinname length
N bytes skinname
4 bytes Xposition
4 bytes Yposition
4 bytes Zposition
4 bytes Xvelocity
4 bytes Yvelocity
4 bytes Zvelocity
1 byte  owned weapon count
For each owned weapon:
	1 byte weapon name length (OR with 0x80 if weapon is currently selected)
	N bytes weapon name
	2 bytes optional weapon data length
	N bytes optional weapon data
1 byte  initialized ammo count
For each initialized ammo type:
	1 byte ammo type name length
	N bytes ammo type name
	2 bytes ammo count
2 bytes health
2 bytes armor
2 bytes armor efficiency

2 bytes actor count

For each active actor:
	2 bytes "actor config" bitfield:
		bit 0  = frame/state mismatch
		bit 1  = movedir/angle mismatch
		bit 2  = current flags/info mismatch
		bit 3  = current doomflags/info mismatch
		bit 4  = health mismatch
		bit 5  = reactiontime is 0
		bit 6  = movecount is 0
		bit 7  = target is nil
		bit 8  = tracer is nil
		bit 9  = radius mismatch
		bit 10 = height mismatch
		bit 11 = object has no fuse
		bit 12 = object does not require precise position (typically scenery)
		bit 13 = object is stationary (typically scenery)
	1 byte  "actor config"
	1 byte  actor type (Taken from DEH Pointers, -1 if invalid)
	2 bytes actor state (Taken from DEH Pointers, -1 if invalid)
	1 byte  actor state duration (aka actor tics)
	2 bytes actor health (optional, only if "actor config" bit 3 is set)
	2 bytes actor flags (optional, only if "actor config" bit 2 is set)
	2 bytes actor doomflags (optional, only if "actor config" bit 3 is set)
	2 bytes actor frame (Usually A, B, C|FF_FULLBRIGHT, etc in statedefs..., stored only if "actor config" bit 0 is not set)
	2 bytes actor radius (/ FRACUNIT, stored only if "actor config" bit 9 is not set)
	2 bytes actor height (/ FRACUNIT, stored only if "actor config" bit 10 is not set)
	2 bytes actor fuse (stored only if "actor config" bit 11 is not set)
	If bit 13 is not set:
		1 byte  move direction
		1 byte  reactiontime
		1 byte  movecount
	2 bytes actor target (optional, only if "actor config" bit 7 is not set)
	2 bytes actor tracer (optional, only if "actor config" bit 8 is not set)
	2 bytes actor angle >> 16 (optional, only if "actor config" bit 1 is set)
	If actor config bit 12 is not set:
		4 bytes Xposition
		4 bytes Yposition
		4 bytes Zposition (only if flags have nograv)
		If actor config bit 13 is not set:
			4 bytes Xvelocity
			4 bytes Yvelocity
			4 bytes Zvelocity (only if flags have nograv)
	Otherwise:
		2 bytes Xposition (>> 16)
		2 bytes Yposition (>> 16)
		2 bytes Zposition (>> 16, only if flags have nograv)
		If actor config bit 13 is not set:
			2 bytes Xvelocity (>> 16)
			2 bytes Yvelocity (>> 16)
			2 bytes Zvelocity (>> 16, only if flags have nograv)
*/

---@param player player_t
local function playerStateToBytestream(player)
    local buffer = {}
    table.insert(buffer, string.char(#player.mo.skin))
    table.insert(buffer, player.mo.skin)
    table.insert(buffer, string.pack("i4", player.mo.x))
	table.insert(buffer, string.pack("i4", player.mo.y))
	table.insert(buffer, string.pack("i4", player.mo.z))
	table.insert(buffer, string.pack("i4", player.mo.momx))
	table.insert(buffer, string.pack("i4", player.mo.momy))
	table.insert(buffer, string.pack("i4", player.mo.momz))

    local ownedWeapons = {}
    for wepname, owned in pairs(player.doom.weapons) do
        if owned then table.insert(ownedWeapons, {name = wepname, selected = player.doom.curwep == wepname, data = ""}) end
    end
    table.insert(buffer, string.char(#ownedWeapons))

    for _, w in ipairs(ownedWeapons) do
        local lengthByte = #w.name + (w.selected and 0x80 or 0)
        table.insert(buffer, string.char(lengthByte))
        table.insert(buffer, w.name)
        local wdata = w.data or ""
        table.insert(buffer, string.pack("i2", #wdata))
        table.insert(buffer, wdata)
    end

	-- Count how many ammo types being serialized
	local ammoTypes = {}
	for ammotype, count in pairs(player.doom.ammo) do
		table.insert(ammoTypes, {type = ammotype, count = count})
	end

	-- Write the count of ammo types (1 byte)
	table.insert(buffer, string.char(#ammoTypes))

	-- Then write each ammo type
	for _, ammo in ipairs(ammoTypes) do
		table.insert(buffer, string.char(#ammo.type))
		table.insert(buffer, ammo.type)
		table.insert(buffer, string.pack("i2", ammo.count))
	end

    return table.concat(buffer)
end

local function readString(bytestream, offset)
    local length = string.byte(bytestream, offset)
    offset = offset + 1
    local str = string.sub(bytestream, offset, offset + length - 1)
    return str, offset + length
end

local function bytestreamToPlayerState(bytestream)
    local playerState = {}
    local offset = 1

    local skinnameLength = string.byte(bytestream, offset)
    offset = offset + 1

    playerState.skinname = string.sub(bytestream, offset, offset + skinnameLength - 1)
    offset = offset + skinnameLength

    playerState.x, offset = string.unpack("i4", bytestream, offset)
    playerState.y, offset = string.unpack("i4", bytestream, offset)
    playerState.z, offset = string.unpack("i4", bytestream, offset)
    playerState.velx, offset = string.unpack("i4", bytestream, offset)
    playerState.vely, offset = string.unpack("i4", bytestream, offset)
    playerState.velz, offset = string.unpack("i4", bytestream, offset)

    local ownedWeaponCount = string.byte(bytestream, offset)
    offset = offset + 1

    playerState.weapons = {}
    for i = 1, ownedWeaponCount do
        local weaponNameLength = string.byte(bytestream, offset)
        offset = offset + 1

        local nameLen = weaponNameLength & 0x7F
        local weaponName = string.sub(bytestream, offset, offset + nameLen - 1)
        local weaponSelected = (weaponNameLength & 0x80) ~= 0
        offset = offset + nameLen

        local weaponDataLength
        weaponDataLength, offset = string.unpack("i2", bytestream, offset)

        local weaponData = string.sub(bytestream, offset, offset + weaponDataLength - 1)
        offset = offset + weaponDataLength

        table.insert(playerState.weapons, {
            name = weaponName,
            selected = weaponSelected,
            data = weaponData
        })
    end

    local ammoTypeCount = string.byte(bytestream, offset)
    offset = offset + 1

    playerState.ammo = {}
    for i = 1, ammoTypeCount do
        local ammoTypeLength = string.byte(bytestream, offset)
        offset = offset + 1

        local ammoType = string.sub(bytestream, offset, offset + ammoTypeLength - 1)
        offset = offset + ammoTypeLength

        local ammoValue
        ammoValue, offset = string.unpack("i2", bytestream, offset)

        playerState.ammo[ammoType] = ammoValue
    end

    return playerState
end

---@param player player_t
COM_AddCommand("savestate", function(player)
	local bytestream = playerStateToBytestream(player)
	CONS_Printf(player, "Player state bytestream:")
	for i = 1, #bytestream do
		CONS_Printf(player, string.format("%02X ", string.byte(bytestream, i)))
	end
	CONS_Printf(player, "Source values:")
	local pdoom = player.doom
	local wepdefs = doom.weapons
	-- CONS_Printf doesn't automatically format,
	-- So we need to string.format it
	CONS_Printf(player, string.format("Skinname: %s", player.mo.skin))
	CONS_Printf(player, string.format("Position: (%d, %d, %d)", player.mo.x, player.mo.y, player.mo.z))
	CONS_Printf(player, string.format("Velocity: (%d, %d, %d)", player.mo.momx, player.mo.momy, player.mo.momz))
	CONS_Printf(player, "Owned weapons:")
	for weaponname, hasit in pairs(player.doom.weapons) do
		CONS_Printf(player, string.format("- %s%s", weaponname, player.doom.curwep == weaponname and " (selected)" or ""))
	end
	CONS_Printf(player, "Ammo counts:")
	for ammotype, count in pairs(player.doom.ammo) do
		CONS_Printf(player, string.format("- %s: %d", ammotype, count))
	end
	CONS_Printf(player, "Deserialized values:")
	local deserializedState = bytestreamToPlayerState(bytestream)
	CONS_Printf(player, string.format("Skinname: %s", deserializedState.skinname))
	CONS_Printf(player, string.format("Position: (%d, %d, %d)", deserializedState.x, deserializedState.y, deserializedState.z))
	CONS_Printf(player, string.format("Velocity: (%d, %d, %d)", deserializedState.velx, deserializedState.vely, deserializedState.velz))
	CONS_Printf(player, "Owned weapons:")
	for i, weapon in ipairs(deserializedState.weapons) do
		CONS_Printf(player, string.format("- %s%s", weapon.name, weapon.selected and " (selected)" or ""))
	end
	CONS_Printf(player, "Ammo counts:")
	for ammotype, count in pairs(deserializedState.ammo) do
		CONS_Printf(player, string.format("- %s: %d", ammotype, count))
	end
	player.doom.savestate = bytestream
end)

---@param player player_t
COM_AddCommand("loadstate", function(player)
	if not player.doom.savestate then
		CONS_Printf(player, "No save state found!")
		return
	end
	local state = bytestreamToPlayerState(player.doom.savestate)
	player.mo.skin = state.skinname
	P_SetOrigin(player.mo, state.x, state.y, state.z)
	player.mo.momx = state.velx
	player.mo.momy = state.vely
	player.mo.momz = state.velz
	player.doom.weapons = {}
	for _, w in ipairs(state.weapons) do
		player.doom.weapons[w.name] = true
		if w.selected then player.doom.curwep = w.name end
		-- Now search to find wep slotname to apply to playerdoom
		-- curwepcat is slot,
		for k, v in ipairs(doom.weaponnames) do
			if v == w.name then
				player.doom.curwepcat = k
				break
			end
		end
		-- This should be weporder
		player.doom.curwepslot = 2
	end

	player.doom.ammo = state.ammo
end)

---@param mobj mobj_t
local function objectStateToBytestream(mobj)
	local bytestream = ""

	-- Initialize bitfield bits
	local bits = {}
	for i = 0, 13 do bits[i] = false end

	local stateDef = states[mobj.state]

	-- 0: frame/state mismatch
	if mobj.frame ~= stateDef.frame then bits[0] = true end

	-- 1: movedir/angle mismatch
	local expectedAngle = mobj.movedir << 29
	if mobj.angle ~= expectedAngle then bits[1] = true end

	-- 2: current flags/info mismatch
	-- 3: current doomflags/info mismatch
	if mobj.flags ~= mobj.info.flags then bits[2] = true end
	if mobj.doomflags ~= mobj.info.doomflags then bits[3] = true end

	-- 4: health mismatch
	if mobj.doom.health ~= mobj.info.spawnhealth then bits[4] = true end

	-- 5: reactiontime is 0
	if mobj.reactiontime == 0 then bits[5] = true end

	-- 6: movecount is 0
	if mobj.movecount == 0 then bits[6] = true end

	-- 7: target is nil
	if mobj.target == nil then bits[7] = true end

	-- 8: tracer is nil
	if mobj.tracer == nil then bits[8] = true end

	-- 9: radius mismatch
	if mobj.radius ~= mobj.spawnRadius then bits[9] = true end

	-- 10: height mismatch
	if mobj.height ~= mobj.spawnHeight then bits[10] = true end

	-- 11: object has no fuse
	if not mobj.fuse then bits[11] = true end

	-- 12: object does not require precise position (scenery)
	if (mobj.flags & MF_SCENERY) then bits[12] = true end

	-- 13: object is stationary (scenery)
	if mobj.monx == 0 and mobj.mony == 0 and mobj.momz == 0 then bits[13] = true end

	-- Pack 14-bit field into two bytes
	local config = 0
	for i = 0, 13 do
		if bits[i] then
			config = config | (1 << i)
		end
	end
	bytestream = bytestream .. string.pack("I2", config)

	-- Actor type
	bytestream = bytestream .. string.char(mobj.type or 0xFF)

	-- Actor state
	bytestream = bytestream .. string.pack("I2", mobj.state or 0xFFFF)

	-- State duration
	bytestream = bytestream .. string.char(mobj.tics or 0)

	-- Optional health (bit 4)
	if bits[4] then
		bytestream = bytestream .. string.pack("I2", mobj.health)
	end

	-- Optional flags (bit 2)
	if bits[2] then
		bytestream = bytestream .. string.pack("I2", mobj.flags)
	end

	-- Optional doomflags (bit 3)
	if bits[3] then
		bytestream = bytestream .. string.pack("I2", mobj.doomflags)
	end

	-- Optional frame (bit 0)
	if not bits[0] then
		bytestream = bytestream .. string.pack("I2", mobj.frame)
	end

	-- Optional radius and height
	if not bits[9] then bytestream = bytestream .. string.pack("I2", mobj.radius >> 16) end
	if not bits[10] then bytestream = bytestream .. string.pack("I2", mobj.height >> 16) end

	-- Optional fuse
	if not bits[11] then bytestream = bytestream .. string.pack("I2", mobj.fuse or 0) end

	-- Move dir, reactiontime, movecount (if not stationary)
	if not bits[13] then
		bytestream = bytestream .. string.char(mobj.movedir or 0)
		bytestream = bytestream .. string.char(mobj.reactiontime or 0)
		bytestream = bytestream .. string.char(mobj.movecount or 0)
	end

	if not bits[7] then
		bytestream = bytestream .. string.pack("I2", mobj.target or 0xFFFF)
	end
	if not bits[8] then
		bytestream = bytestream .. string.pack("I2", mobj.tracer or 0xFFFF)
	end

	-- Optional angle (bit 1)
	if bits[1] then
		bytestream = bytestream .. string.pack("I2", mobj.angle >> 16)
	end

	-- Optional position & velocity
	if not bits[12] then
		bytestream = bytestream .. string.pack("i4i4", mobj.x, mobj.y)
		if mobj.flags & MF_NOGRAVITY ~= 0 then bytestream = bytestream .. string.pack("i4", mobj.z) end
		if not bits[13] then
			bytestream = bytestream .. string.pack("i4i4", mobj.momx, mobj.momy)
			if mobj.flags & MF_NOGRAVITY ~= 0 then bytestream = bytestream .. string.pack("i4", mobj.momz) end
		end
	else
		-- Compact position & velocity for scenery
		bytestream = bytestream .. string.pack("I2I2", mobj.x >> 16, mobj.y >> 16)
		if mobj.flags & MF_NOGRAVITY ~= 0 then bytestream = bytestream .. string.pack("I2", mobj.z >> 16) end
		if not bits[13] then
			bytestream = bytestream .. string.pack("I2I2", mobj.momx >> 16, mobj.momy >> 16)
			if mobj.flags & MF_NOGRAVITY ~= 0 then bytestream = bytestream .. string.pack("I2", mobj.momz >> 16) end
		end
	end

	return bytestream
end