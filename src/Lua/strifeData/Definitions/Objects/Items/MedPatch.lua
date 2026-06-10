SafeFreeSlot("SPR_STMP", "sfx_itemup")
local name = "MedPatch"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2011,
	conversationid = {125, 121, 124},
	deathsound = sfx_itemup,
	sprite = SPR_STMP,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "medpatch", 1, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_MEDPATCH")
end
DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.medpatch = 20