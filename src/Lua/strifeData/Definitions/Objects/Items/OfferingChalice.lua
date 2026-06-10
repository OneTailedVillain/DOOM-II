SafeFreeSlot("SPR_RELC", "sfx_itemup")
local name = "OfferingChalice"
local object = {
	radius = 20,
	height = 16,
	doomednum = 205,
	conversationid = {174, 166, 170},
	deathsound = sfx_itemup,
	sprite = SPR_RELC,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "offeringchalice", 1, item.doom.flags)
	if not result then return true end

	doom.questflags = $ | QF_QUEST2
	DOOM_DoMessage(player, "$TXT_OFFERINGCHALICE")
end
DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.offeringchalice = 1