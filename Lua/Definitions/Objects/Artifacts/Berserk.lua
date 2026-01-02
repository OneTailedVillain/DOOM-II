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

SafeFreeSlot("SPR_PSTR")
local name = "Berserk"

local object = {
	radius = 20,
	height = 46,
	doomednum = 2023,
	deathsound = sfx_getpow,
	sprite = SPR_PSTR,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	
	if funcs.doPowerUp then
		funcs.doPowerUp(player, "berserk")
	else
		-- Fallback to original behavior
		local health = funcs.getHealth(player)
		if health and health < 100 then
			funcs.setHealth(player, 100)
		end
		player.doom.powers[pw_strength] = 1
		DOOM_SwitchWeapon(player, "brassknuckles")
	end
	
	DOOM_DoMessage(player, "$GOTBERSERK")
	return false
end

DefineDoomItem(name, object, states, onPickup)