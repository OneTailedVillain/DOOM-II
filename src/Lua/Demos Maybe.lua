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
ticcmd_t
This userdata type represents a player's current button information, i.e., what buttons are being pressed currently. In the examples below, cmd is used as the name of the ticcmd_t variable. An access to a variable var of ticcmd_t is written as cmd.var.

General
Accessibility	Read+Write
Allows custom variables	No
[hide]ticcmd_t structure
Name	Type	Accessibility	Description/Notes
forwardmove	SINT8	Read+Write	Value related to forwards/backwards buttons; positive values move the player forward, negative values move the player backwards. Ranges from -50 to 50.
sidemove	SINT8	Read+Write	Value related to strafe left/right buttons; positive values move the player right, negative values move the player left. Ranges from -50 to 50.
angleturn	INT16	Read+Write	Value related to turn left/right buttons; to use as angle_t this needs to be shifted up by 16 bits (cmd.angleturn<<16 or cmd.angleturn*65536).
aiming	INT16	Read+Write	Value related to look up/down buttons; to use as angle_t this needs to be shifted up by 16 bits (cmd.aiming<<16 or cmd.aiming*65536).
buttons	UINT16	Read+Write	Contains flags representing buttons currently pressed (BT_* constants should be used).
latency	UINT8	Read-only	The amount of tics it took to receive the player's ticcmd up to 12 tics.
*/

/*
Format:
[1] = buttons
[2] = forwardmove
[3] = sidemove
[4] = angleturn
[5] = aiming
*/

local function to_byte(n)
    n = n % 256
    if n < 0 then n = n + 256 end
    return n
end

-- SRB2 does not natively have these, so reimplement them
local function normalize_u32(n)
    return n & 0xFFFFFFFF
end

local function write_le(num, size)
    local out = {}

    -- force into unsigned range
    local max = 1 << (size * 8)
    num = num % max

    for i = 1, size do
        out[i] = string.char((num >> (8 * (i - 1))) & 0xFF)
    end

    return table.concat(out)
end

local function read_le(str, pos, size)
    local num = 0
    for i = 0, size - 1 do
        num = num | (string.byte(str, pos + i) << (8 * i))
    end
    return num
end

local function read_signed_le(str, pos, size)
    local num = read_le(str, pos, size)
    if size == 4 then
        if num >= 0x80000000 then num = num - 0x100000000 end
    elseif size == 2 then
        if num >= 0x8000 then num = num - 0x10000 end
    end
    return num
end

function string.pack(fmt, ...)
    local args = {...}
    local pos = 1
    local out = {}

    local i = 1
    while i <= #fmt do
        local c = fmt:sub(i, i)
        local count = 1

        -- read count modifier
        local j = i + 1
        local num_str = ""
        while j <= #fmt and tonumber(fmt:sub(j, j)) do
            num_str = num_str .. fmt:sub(j, j)
            j = j + 1
        end
        if #num_str > 0 then
            count = tonumber(num_str)
            i = j - 1
        end

        if c == "b" or c == "B" then
            out[#out+1] = write_le(args[pos] & 0xFF, 1)
            pos = pos + 1

        elseif c == "h" or c == "H" then
            out[#out+1] = write_le(args[pos] & 0xFFFF, 2)
            pos = pos + 1

		elseif c == "i" or c == "I" then
			local size = (count > 1) and count or 4
			local num = args[pos]

			if c == "I" then
				-- unsigned: clamp to 0..2^size-1
				local max = 1 << (size * 8)
				num = num % max
			else
				-- signed: clamp to -2^(size*8-1) .. 2^(size*8-1)-1
				local max = 1 << (size * 8)
				local half = max >> 1
				if num < -half or num >= half then
					num = ((num + half) % max) - half
				end
			end

			out[#out+1] = write_le(num, size)
			pos = pos + 1

        elseif c == "c" then
            local str = args[pos] or ""
            if #str < count then
                str = str .. string.rep("\0", count - #str)
            else
                str = str:sub(1, count)
            end
            out[#out+1] = str
            pos = pos + 1

        else
            error("Unsupported pack format: " .. c)
        end

        i = i + 1
    end

    return table.concat(out)
end

function string.unpack(fmt, str, start)
    local pos = start or 1
    local results = {}

    local function read_bytes(n)
        if pos + n - 1 > #str then
            error("Not enough data for unpack")
        end
        local p = pos
        pos = pos + n
        return p
    end

    local i = 1
    while i <= #fmt do
        local c = fmt:sub(i, i)
        local count = 1

        -- read count modifier
        local j = i + 1
        local num_str = ""
        while j <= #fmt and tonumber(fmt:sub(j, j)) do
            num_str = num_str .. fmt:sub(j, j)
            j = j + 1
        end
        if #num_str > 0 then
            count = tonumber(num_str)
            i = j - 1
        end

        if c == "c" then
            local p = read_bytes(count)
            local s = str:sub(p, p + count - 1)
            s = s:gsub("%z+$", "")
            table.insert(results, s)

        elseif c == "b" then
            local p = read_bytes(1)
            local n = string.byte(str, p)
            if n >= 128 then n = n - 256 end
            table.insert(results, n)

        elseif c == "B" then
            local p = read_bytes(1)
            table.insert(results, string.byte(str, p))

        elseif c == "h" then
            local p = read_bytes(2)
            local n = read_le(str, p, 2)
            if n >= 32768 then n = n - 65536 end
            table.insert(results, n)

        elseif c == "H" then
            local p = read_bytes(2)
            table.insert(results, read_le(str, p, 2))

		elseif c == "i" or c == "I" then
			local size = (count > 1) and count or 4
			local p = read_bytes(size)
			local num

			-- "i" == signed
			if c == "i" then
				num = read_signed_le(str, p, size)
			else
				num = read_le(str, p, size)
			end
			
			table.insert(results, num)

        else
            error("Unsupported unpack format: " .. c)
        end

        i = i + 1
    end

    table.insert(results, pos)
    return unpack(results)
end

local curTic = {0, 0, 0, 0, 0}
local filelocation = "client/doomport/"

local inputFile = nil
local magic = "DMRP"

local function stopPlayingAndError(msg)
	doom.demoplaying = false
	if inputFile then
		inputFile:close()
	end
	error(msg)
end

local function makeHeader(name, map, length, skill , prndindex)
	local nameLength = #name
	return string.pack("c4I4I2I1I1I1", magic, length, map, skill, prndindex, nameLength) .. name
end

local function readHeader()
	local data = inputFile:read(13)
	local magicConst = magic
	if not data then return nil end
	local magic, length, map, skill, prndindex, nameLength = string.unpack("c4I4I2I1I1I1", data)
	if magic ~= magicConst then
		stopPlayingAndError("Invalid replay file!")
		return nil
	end
	local name = inputFile:read(nameLength)
	if #name ~= nameLength then
		stopPlayingAndError("Failed to read replay name! (Truncated name in header)")
		return nil
	end
	return {length, map, name, skill, prndindex}
end

local inputRepeatCount = 0

local function delta16(a, b)
    local d = a - b
    if d > 32767 then d = d - 65536 end
    if d < -32768 then d = d + 65536 end
    return d
end

local function readTic()
	if inputRepeatCount > 0 then
		-- In a repeat, so leave curTic alone
		inputRepeatCount = inputRepeatCount - 1
		return
	end
	local typeData = inputFile:read(1)
	if typeData == nil then print("End of replay") doom.demoplaying = false return end
	if typeData == "\0" then
		-- Delta input
		local data = inputFile:read(8)
		if not data then stopPlayingAndError("Failed to read tic data! (Potentially early end of stream)") return end
		local forwardmove, sidemove, angleturn, aiming, buttons = string.unpack("bbhhI2", data)

		-- Now apply delta
		curTic[1] = curTic[1] ^^ buttons
		curTic[2] = max(-50, min(50, curTic[2] + forwardmove))
		curTic[3] = max(-50, min(50, curTic[3] + sidemove))
		curTic[4] = delta16(curTic[4] + angleturn, curTic[4])
		curTic[5] = delta16(curTic[5] + aiming, curTic[5])
	elseif typeData == "\1" then
		-- Repeat last input for 1 tic, so do nothing
	elseif typeData == "\2" then
		local repeatCountData = inputFile:read(1)
		if not repeatCountData then stopPlayingAndError("Failed to read repeat count! (Potentially early end of stream)") return end
		inputRepeatCount = string.unpack("I1", repeatCountData) - 1
	elseif typeData == "\3" then
		local repeatCountData = inputFile:read(2)
		if not repeatCountData then stopPlayingAndError("Failed to read repeat count! (Potentially early end of stream)") return end
		inputRepeatCount = string.unpack("I2", repeatCountData) - 1
	elseif typeData == "\4" then
		local data = inputFile:read(8)
		if not data then stopPlayingAndError("Failed to read tic data! (Potentially early end of stream)") return end
		local forwardmove, sidemove, angleturn, aiming, buttons = string.unpack("bbhhI2", data)
		curTic[1] = buttons
		curTic[2] = forwardmove
		curTic[3] = sidemove
		curTic[4] = angleturn
		curTic[5] = aiming
	else
		stopPlayingAndError("Invalid tic type in replay file!")
		return
	end
end

local function checkForUnusedFilename()
	local i = 0
	while true do
		local filename = filelocation .. "replays/" .. gamemap .. "replay-" .. i .. ".sav2"
		local file = io.openlocal(filename, "rb")
		if not file then
			return filename
		end
		file:close()
		i = i + 1
	end
end

local function fnv1a(str)
	str = tostring(str)
	local hash = 2166136261
	for i = 1, #str do
		hash = hash ^^ string.byte(str, i)
		hash = (hash * 16777619)
	end
	return hash
end

local function hash(data)
	local hash = fnv1a(data)
	return string.pack("I4", hash)
end

local function openReplay(filename)
	inputFile = io.openlocal(filelocation .. "replays/" .. filename, "rb")
	if not inputFile then stopPlayingAndError("Failed to open replay file!") return end

	-- TODO: Push checksum into a function
	inputFile:seek("end", -4) -- Go to 4 bytes before the end of the file to read the checksum
	local expectedChecksumData = inputFile:read(4)
	if not expectedChecksumData then stopPlayingAndError("Failed to read nonexistent replay checksum!") return end
	local expectedChecksum = string.unpack("I4", expectedChecksumData)
	inputFile:seek("set", 0) -- Go back to the beginning of the file to compute the checksum
	local size = inputFile:seek("end")
	inputFile:seek("set", 0)
	local data = inputFile:read(size - 4)
	local trueChecksum = fnv1a(data)
	if trueChecksum != expectedChecksum then
		stopPlayingAndError("Replay file is corrupted (checksum mismatch)!")
		return
	end

	-- Read header
	local header = readHeader()
	if not header then stopPlayingAndError("Failed to read replay header!") return end
	print("Replay info: Name=" .. header[3] .. ", Map=" .. header[2] .. ", Length=" .. header[1] .. " tics")
	return header
end

local function startReplay(filename)
	-- Potentially in a map
	if consoleplayer.mo then
		if multiplayer then
			DOOM_DoMessage(consoleplayer, "You can't play a demo during a netgame!")
			return
		end
		DOOM_DoMessage(consoleplayer, "You can't play a demo during a map!")
		return
	end
	local header = openReplay(filename)
	if not header then return end
	COM_BufInsertText(consoleplayer, "skin " .. header[3])
	COM_BufInsertText(consoleplayer, "map " .. header[2])
	COM_BufInsertText(consoleplayer, "doom_skill " .. header[4])
	doom.prndindex = header[5]
	doom.demoplaying = true
end

-- Forcefullly set player's input
addHook("PreThinkFrame", function()
	if not doom.demoplaying then return end
	local ticcmd = consoleplayer.cmd
	if not ticcmd then return end

	readTic()

	-- Set the ticcmd values to the current tic
	ticcmd.buttons = curTic[1]
	ticcmd.forwardmove = curTic[2]
	ticcmd.sidemove = curTic[3]
	ticcmd.angleturn = curTic[4]
	ticcmd.aiming = curTic[5]
end)

-- Buffer of ticcmds to write to the file at the end of the recording
-- iirc DOOM does the same thing, except in structs
local inputs = {}

-- How many input saves between each snapshot
-- Accumulator does NOT count repeats!
-- Helpful for ensuring less desyncs in replays
local inputSnapshotInterval = 60

-- Write to a file when recording
addHook("PostThinkFrame", function()
	if not doom.demorecording then return end
	local ticcmd = consoleplayer.cmd
	if not ticcmd then return end
	table.insert(inputs, {
		buttons = ticcmd.buttons,
		forwardmove = ticcmd.forwardmove,
		sidemove = ticcmd.sidemove,
		angleturn = ticcmd.angleturn,
		aiming = ticcmd.aiming
	})
	if DOOM_IsExiting() then
		local outputFile = io.openlocal(checkForUnusedFilename(), "w+b")
		if not outputFile then stopPlayingAndError("Failed to open output file for writing!") return end

		-- Write header
		local name = consoleplayer.mo.skin
		local header = makeHeader(name, gamemap, #inputs, doom.gameskill, doom.prndindex)
		outputFile:write(header)

		local lastInput = {0, 0, 0, 0, 0}
		-- Write ticcmds
		-- 
		local i = 1
		local snapshotCounter = 0
		while i <= #inputs do
			local cmd = inputs[i]

			-- Compute repeat count from this position
			local repeatCount = 1
			for j = i + 1, #inputs do
				local nextCmd = inputs[j]
				if nextCmd.buttons != cmd.buttons
				or nextCmd.forwardmove != cmd.forwardmove
				or nextCmd.sidemove != cmd.sidemove
				or nextCmd.angleturn != cmd.angleturn
				or nextCmd.aiming != cmd.aiming then
					break
				end
				repeatCount = repeatCount + 1
			end

			local typeByte = ""
			if repeatCount == 1 then
				typeByte = "\1"
			elseif repeatCount <= 0xFF then
				typeByte = "\2" .. string.pack("B", repeatCount)
			elseif repeatCount <= 0xFFFF then
				typeByte = "\3" .. string.pack("H", repeatCount)
			else
				-- Break into multiple chunks
				local remaining = repeatCount
				
				while remaining > 0 do
					if remaining >= 0xFFFF then
						typeByte = typeByte .. "\3" .. string.pack("H", 0xFFFF)
						remaining = remaining - 0xFFFF
					elseif remaining >= 0xFF then
						typeByte = typeByte .. "\2" .. string.pack("B", 0xFF)
						remaining = remaining - 0xFF
					else
						typeByte = typeByte .. "\2" .. string.pack("B", remaining)
						remaining = 0
					end
				end
			end

			-- Delta from last written input
			local deltaButtons = cmd.buttons ^^ lastInput[1]
			local deltaForwardmove = cmd.forwardmove - lastInput[2]
			local deltaSidemove = cmd.sidemove - lastInput[3]
			local deltaAngleturn = cmd.angleturn - lastInput[4]
			local deltaAiming = cmd.aiming - lastInput[5]

			local data = ""

			if i == 1 or (deltaButtons != 0
			or deltaForwardmove != 0
			or deltaSidemove != 0
			or deltaAngleturn != 0
			or deltaAiming != 0) then
				typeByte = "\0"
				-- i == 1 always is type 4
				if snapshotCounter >= inputSnapshotInterval or i == 1 then
					-- Force a snapshot to ensure less desyncs in replays
					typeByte = "\4"
					snapshotCounter = 0
				end
				if typeByte == "\0" then
					outputFile:write(typeByte .. string.pack("bbhhI2",
						deltaForwardmove,
						deltaSidemove,
						deltaAngleturn,
						deltaAiming,
						deltaButtons
					))
				else
					outputFile:write(typeByte .. string.pack("bbhhI2",
						cmd.forwardmove,
						cmd.sidemove,
						cmd.angleturn,
						cmd.aiming,
						cmd.buttons
					))
				end
			else
				outputFile:write(typeByte)
			end

			-- Update lastInput
			lastInput = {
				cmd.buttons,
				cmd.forwardmove,
				cmd.sidemove,
				cmd.angleturn,
				cmd.aiming
			}

			-- Skip repeated inputs
			i = i + repeatCount
			snapshotCounter = snapshotCounter + 1
		end

		-- Now write the checksum with the data we wrote specifically to the file
		-- Ensures that the checksum when starting a replay doesn't have to
		-- do some bullshit to convert the data into list format or something
		outputFile:seek("set", 0) -- Go back to the beginning of the file
		local checksum = outputFile:read("*a") -- Read the entire file
		checksum = hash(checksum)
		outputFile:seek("end") -- Go back to the end of the file
		outputFile:write(checksum)

		outputFile:close()
		inputs = {}
		doom.demorecording = false
	end
end)
/*
-- TODO: Remove this after making sure everything works...
addHook("MapLoad", function()
	doom.demorecording = true
end)
*/