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

SafeFreeSlot("SPR_PUFF")

local playerstates = {
	spawn = {
		{sprite = SPR_PUFF, frame = A, tics = 4},
		{sprite = SPR_PUFF, frame = B, tics = 4},
		{sprite = SPR_PUFF, frame = A, tics = 4},
		{sprite = SPR_PUFF, frame = B, tics = 4},
		{sprite = SPR_PUFF, frame = C, tics = 4},
	},
}

local freedSprites = FreeDoomStates("RevenantTracer", playerstates)

SafeFreeSlot("MT_DOOM_REVENANTTRACER")

mobjinfo[MT_DOOM_REVENANT_TRACER] = {
    spawnstate = S_DOOM_PUFF1,
    radius = 1*FRACUNIT,
    height = 1*FRACUNIT,
    flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}