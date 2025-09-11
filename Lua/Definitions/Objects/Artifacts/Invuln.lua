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
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 6},
	{frame = B|FF_FULLBRIGHT, tics = 6},
	{frame = C|FF_FULLBRIGHT, tics = 6},
	{frame = D|FF_FULLBRIGHT, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	player.doom.powers[pw_invulnerability] = 30*TICRATE
	DOOM_DoMessage(player, "GOTINVUL")
end

DefineDoomItem(name, object, states, onPickup)