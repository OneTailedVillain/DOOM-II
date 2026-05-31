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

SafeFreeSlot("SPR_PINS")
local name = "BlurSphere"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2024,
	deathsound = sfx_getpow,
	sprite = SPR_PINS,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
		{frame = A, tics = 6},
		{frame = B, tics = 6},
		{frame = C, tics = 6},
		{frame = D, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	
	if funcs.doPowerUp then
		funcs.doPowerUp(player, "invisibility")
	else
		player.doom.powers[pw_invisibility] = 60*TICRATE
	end
	
	DOOM_DoMessage(player, "$GOTINVIS")
	return false
end

DefineDoomItem(name, object, states, onPickup)