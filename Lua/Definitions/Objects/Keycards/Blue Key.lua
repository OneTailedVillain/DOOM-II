local function SafeFreeSlot(...)
    local ret = {}
    for _, name in ipairs({...}) do
        -- If already freed, just use the existing slot
        if rawget(_G, name) ~= nil then
            ret[name] = _G[name]
        else
            -- Otherwise, safely freeslot it and return the value
            ret[name] = freeslot(name)
        end
    end
    return ret
end

SafeFreeSlot("SPR_BKEY")
local name = "BlueKeycard"

local object = {
	radius = 20,
	height = 16,
	doomednum = 5,
	deathsound = sfx_itemup,
	sprite = SPR_BKEY,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP
}

local states = {
	{frame = A, tics = 10},
	{frame = B|FF_FULLBRIGHT, tics = 10},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	player.doom.keys = ($ or 0)|doom.KEY_BLUE
	DOOM_DoMessage(player, "GOTBLUECARD")
end

DefineDoomItem(name, object, states, onPickup)