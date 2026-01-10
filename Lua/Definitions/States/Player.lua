local function FreeDoomStates(name, stateDefs)
    local up     = name:upper()
    local prefix = "DOOM_" .. up

    -- Build a list of all state globals to freeslot
    local needed = {}
    for stateKey, frames in pairs(stateDefs) do
        local stU = stateKey:upper()
        for i = 1, #frames do
            needed[#needed+1] = string.format("S_%s_%s%d", prefix, stU, i)
        end
    end

    -- Freeslot all the state globals
    local slots = SafeFreeSlot(unpack(needed))

    -- Set up nextstate references properly
    for stateKey, frames in pairs(stateDefs) do
        local stU = stateKey:upper()
        for i, f in ipairs(frames) do
			local thisName = string.format("S_%s_%s%d", prefix, stU, i)

			local nextslot

			-- If user explicitly sets numeric next (like next = S_PLAY_STND)
			if type(f.next) == "number" then
				print("NEXT STATE FOR " .. thisName .. " IS CONSTANT")
				nextslot = f.next

			-- If user uses named doom-state next (like next = "move")
			elseif type(f.next) == "string" then
				local nextName = string.format(
					"S_%s_%s%d",
					prefix,
					f.next:upper(),
					tonumber(f.nextframe) or 1
				)
				nextslot = slots[nextName]

			-- Otherwise: fall back to automatic chaining
			elseif frames[i+1] then
				local nextName = string.format("S_%s_%s%d", prefix, stU, i+1)
				nextslot = slots[nextName]
			end

			f.nextstate = nextslot or S_NULL

			states[ slots[thisName] ] = {
				sprite    = f.sprite or (objData and objData.sprite),
				frame     = f.frame,
				tics      = f.tics,
				action    = f.action,
				var1      = f.var1,
				var2      = f.var2,
				nextstate = f.nextstate
			}
        end
    end
end

SafeFreeSlot("SPR2_DYIN", "SPR2_FLSH", "SPR2_GIBN", "SPR2_GIBD")

local playerstates = {
	stand = {
		{sprite = SPR_PLAY, frame = SPR2_STND, tics = -1},
	},
	move = {
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4},
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4},
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4},
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4, next = "move"},
	},
	attack = {
		{sprite = SPR_PLAY, frame = SPR2_FIRE, tics = 12, next = "stand"},
	},
	flash = {
		{sprite = SPR_PLAY, frame = SPR2_FLSH|FF_FULLBRIGHT, tics = 6, next = "attack"},
	},
	pain = {
		{sprite = SPR_PLAY, frame = SPR2_PAIN, tics = 6},
		{sprite = SPR_PLAY, frame = SPR2_PAIN, tics = 6, action = A_DoomPain, next = "stand"},
	},
	die = {
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10, action = A_DoomPlayerScream},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10, action = A_DoomFall},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DEAD, tics = -1},
	},
	gib = {
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5, A_DoomXScream},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5, A_DoomFall},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBD, tics = -1},
	},
}

local freedSprites = FreeDoomStates("Player", playerstates)