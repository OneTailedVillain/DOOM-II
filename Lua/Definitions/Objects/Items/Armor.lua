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

SafeFreeSlot("SPR_BON2")
local name = "ArmorBonus"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2015,
	deathsound = sfx_itemup,
	sprite = SPR_BON2,
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
	local health = funcs.getArmor(player)
	player.doom.bonuscount = 32
	funcs.setArmor(player, min(health + 1, 200))
	DOOM_DoMessage(player, "GOTARMBONUS")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_ARM2")
local name = "CombatArmor"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2019,
	deathsound = sfx_itemup,
	sprite = SPR_ARM2,
	doomflags = DF_ALWAYSPICKUP
}

local states = {
		{frame = A, tics = 6},
		{frame = B|FF_FULLBRIGHT, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getArmor(player)
	if health >= 200 then return true end
	player.doom.bonuscount = 32
	funcs.setArmor(player, 200, FRACUNIT/2)
	DOOM_DoMessage(player, "GOTMEGA")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_ARM1")
local name = "SecurityArmor"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2018,
	deathsound = sfx_itemup,
	sprite = SPR_ARM1,
	doomflags = DF_ALWAYSPICKUP
}

local states = {
		{frame = A, tics = 6},
		{frame = B|FF_FULLBRIGHT, tics = 7},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getArmor(player)
	if health >= 100 then return true end
	player.doom.bonuscount = 32
	funcs.setArmor(player, 100, FRACUNIT/3)
	DOOM_DoMessage(player, "GOTARMOR")
end

DefineDoomItem(name, object, states, onPickup)