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

SafeFreeSlot("SPR_PINV", "sfx_getpow")
local name = "InvulnSphere"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2022,
	deathsound = sfx_getpow,
	sprite = SPR_PINV,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 6},
	{frame = B|FF_FULLBRIGHT, tics = 6},
	{frame = C|FF_FULLBRIGHT, tics = 6},
	{frame = D|FF_FULLBRIGHT, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	
	if funcs.doPowerUp then
		funcs.doPowerUp(player, "invulnerability")
	else
		player.doom.powers[pw_invulnerability] = 30*TICRATE
	end
	
	DOOM_DoMessage(player, "$GOTINVUL")
	return false
end

DefineDoomItem(name, object, states, onPickup)