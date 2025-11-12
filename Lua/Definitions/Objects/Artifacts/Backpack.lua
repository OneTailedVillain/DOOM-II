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

SafeFreeSlot("SPR_BPAK")
local name = "Backpack"

local object = {
	radius = 20,
	height = 26,
	doomednum = 8,
	deathsound = sfx_itemup,
	sprite = SPR_BPAK,
	doomflags = DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
		{frame = A, tics = -1},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)

	if funcs.doBackpack then
		funcs.doBackpack(player)
	else
		player.doom.backpack = true
		funcs.giveAmmoFor(player, "clip", item.doom.flags)
		funcs.giveAmmoFor(player, "shells", item.doom.flags)
		funcs.giveAmmoFor(player, "rocket", item.doom.flags)
		funcs.giveAmmoFor(player, "cell", item.doom.flags)
	end
	DOOM_DoMessage(player, "$GOTBACKPACK")
end

DefineDoomItem(name, object, states, onPickup)