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

			print(thisName .. " NEXT SLOT: " .. tostring(nextslot))

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

SafeFreeSlot(
    "SPR_BAL7",
    "sfx_firsht","sfx_firxpl",
    "MT_DOOM_BARONFIREBALL"
)

local plasmastates = {
    shot = {
        {sprite = SPR_BAL7, frame = A, tics = 4},
        {sprite = SPR_BAL7, frame = B, tics = 4, next = "shot"},
    },

    explode = {
        {sprite = SPR_BAL7, frame = C, tics = 6},
        {sprite = SPR_BAL7, frame = D, tics = 6},
        {sprite = SPR_BAL7, frame = E, tics = 6},
    },
}

FreeDoomStates("BaronFireball", plasmastates)

mobjinfo[MT_DOOM_BARONFIREBALL] = {
    spawnstate = S_DOOM_BARONFIREBALL_SHOT1,
    seesound   = sfx_firsht,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_BARONFIREBALL_EXPLODE1,

    speed      = 15*FRACUNIT,
    radius     = 6*FRACUNIT,
    height     = 16*FRACUNIT,
    damage     = 8,

    flags = MF_NOGRAVITY|MF_MISSILE,
}

mobjinfo[MT_DOOM_BARONFIREBALL].fastspeed = 20*FRACUNIT