SafeFreeSlot("SPR_FLGR", "sfx_itemup")

local name = "SVETalismanRed"
local object = {
	radius = 16,
	height = 16,
	doomednum = 7966,
	deathsound = sfx_itemup,
	sprite = SPR_FLGR,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A|FF_FULLBRIGHT, tics = -1},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "talismanred", 1, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$MSG_TALISMANRED")
end
DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.talismanred = 1


SafeFreeSlot("SPR_FLGG")

local name = "SVETalismanGreen"
local object = {
	radius = 16,
	height = 16,
	doomednum = 7967,
	deathsound = sfx_itemup,
	sprite = SPR_FLGG,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A|FF_FULLBRIGHT, tics = -1},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "talismangreen", 1, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$MSG_TALISMANGREEN")
end
DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.talismangreen = 1


SafeFreeSlot("SPR_FLGB")

local name = "SVETalismanBlue"
local object = {
	radius = 16,
	height = 16,
	doomednum = 7968,
	deathsound = sfx_itemup,
	sprite = SPR_FLGB,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A|FF_FULLBRIGHT, tics = -1},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "talismanblue", 1, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$MSG_TALISMANBLUE")
end
DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.talismanblue = 1