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

SafeFreeSlot("SPR_BON1")
local name = "HealthBonus"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2014,
	deathsound = sfx_itemup,
	sprite = SPR_BON1,
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
	funcs.setHealth(player, min(health + 1, 200))
	DOOM_DoMessage(player, "GOTHTHBONUS")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_MEDI")
local name = "Medikit"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2012,
	deathsound = sfx_itemup,
	sprite = SPR_MEDI,
	doomflags = DF_ALWAYSPICKUP
}

local states = {
		{frame = A, tics = INT32_MAX},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player)
	if health >= 100 then return true end
	player.doom.bonuscount = 32
	funcs.setHealth(player, min(health + 25, 100))
	if health < 25 then
		DOOM_DoMessage(player, "GOTMEDINEED")
	else
		DOOM_DoMessage(player, "GOTMEDIKIT")
	end
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_STIM")
local name = "Stimpack"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2011,
	deathsound = sfx_itemup,
	sprite = SPR_STIM,
	doomflags = DF_ALWAYSPICKUP
}

local states = {
		{frame = A, tics = INT32_MAX},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player)
	if health >= 100 then return true end
	player.doom.bonuscount = 32
	funcs.setHealth(player, min(health + 10, 100))
	DOOM_DoMessage(player, "GOTSTIM")
end

DefineDoomItem(name, object, states, onPickup)