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

SafeFreeSlot("SPR_SOUL", "sfx_getpow")
local name = "SoulSphere"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2013,
	deathsound = sfx_getpow,
	sprite = SPR_SOUL,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP
}

local states = {
		{frame = A, tics = 6},
		{frame = B, tics = 6},
		{frame = C, tics = 6},
		{frame = D, tics = 6},
		{frame = C, tics = 6},
		{frame = B, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player)
	player.doom.bonuscount = 32
	funcs.setHealth(player, min(health + 100, 200))
	DOOM_DoMessage(player, "GOTSUPER")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_MEGA")
local name = "MegaSphere"

local object = {
	radius = 20,
	height = 16,
	doomednum = 83,
	deathsound = sfx_getpow,
	sprite = SPR_MEGA,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP
}

local states = {
		{frame = A, tics = 6},
		{frame = B, tics = 6},
		{frame = C, tics = 6},
		{frame = D, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player)
	local armor = funcs.getArmor(player)
	if health == 200 and armor == 200 then return true end
	player.doom.bonuscount = 32
	funcs.setHealth(player, 200)
	funcs.setArmor(player, 200)
	DOOM_DoMessage(player, "GOTMSPHERE")
end

DefineDoomItem(name, object, states, onPickup)