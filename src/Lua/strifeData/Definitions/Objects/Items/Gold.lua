SafeFreeSlot("SPR_COIN", "sfx_itemup")
local name = "Coin"
local object = {
	radius = 20,
	height = 16,
	doomednum = 93,
	conversationid = {168, 161, 165},
	deathsound = sfx_itemup,
	sprite = SPR_COIN,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "gold", 1, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_COIN")
end
DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_CRED")
name = "Gold10"
object.doomednum = 138
object.conversationid = {169, 162, 166}
object.sprite = SPR_CRED
states = {
	{frame = A, tics = 6},
}

function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "gold", 10, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_10GOLD")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_SACK")
name = "Gold25"
object.doomednum = 139
object.conversationid = {170, 163, 167}
object.sprite = SPR_SACK
states = {
	{frame = A, tics = 6},
}

function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "gold", 25, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_25GOLD")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_CHST")
name = "Gold50"
object.doomednum = 140
object.conversationid = {171, 164, 168}
object.sprite = SPR_CHST
states = {
	{frame = A, tics = 6},
}

function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "gold", 50, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_50GOLD")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_TOKN")
name = "Gold300"
object.doomednum = -1
object.conversationid = 172
object.sprite = SPR_TOKN
states = {
	{frame = A, tics = 6},
}

function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "gold", 300, item.doom.flags)
	if not result then return true end

	doom.questflags = $ | QF_QUEST3
	DOOM_DoMessage(player, "$TXT_300GOLD")
end

DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.gold = 0x7fffffff