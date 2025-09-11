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

SafeFreeSlot("SPR_CSAW", "sfx_wpnup")
local name = "Chainsaw"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2005,
	deathsound = sfx_wpnup,
	sprite = SPR_CSAW,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "chainsaw", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTCHAINSAW")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_SHOT", "sfx_wpnup")
local name = "Shotgun"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2001,
	deathsound = sfx_wpnup,
	sprite = SPR_SHOT,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "shotgun", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTSHOTGUN")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_SGN2")
local name = "SuperShotgun"

local object = {
	radius = 20,
	height = 16,
	doomednum = 82,
	deathsound = sfx_wpnup,
	sprite = SPR_SGN2,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "supershotgun", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTSHOTGUN2")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_LAUN", "sfx_wpnup")
local name = "RPG"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2003,
	deathsound = sfx_wpnup,
	sprite = SPR_LAUN,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "rocketlauncher", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTLAUNCHER")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_MGUN", "sfx_wpnup")
local name = "Chaingun"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2002,
	deathsound = sfx_wpnup,
	sprite = SPR_MGUN,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "chaingun", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTCHAINGUN")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_PLAS", "sfx_wpnup")
local name = "PlasmaRifle"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2004,
	deathsound = sfx_wpnup,
	sprite = SPR_PLAS,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "plasmarifle", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTPLASMA")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_BFUG", "sfx_wpnup")
local name = "BFG9000"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2006,
	deathsound = sfx_wpnup,
	sprite = SPR_BFUG,
	doomflags = DF_COUNTITEM
}

local states = {
	{frame = A, tics = 6},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end -- Early exit WITHOUT doing vanilla special item stuff (Why is our second argument mobj_t and not player_t???)
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "bfg9000", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTBFG9000")
end

DefineDoomItem(name, object, states, onPickup)