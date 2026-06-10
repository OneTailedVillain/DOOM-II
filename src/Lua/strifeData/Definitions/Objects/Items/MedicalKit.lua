SafeFreeSlot("SPR_MDKT", "sfx_itemup")
local name = "MedicalKit"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2012,
	conversationid = {126, 122, 125},
	deathsound = sfx_itemup,
	sprite = SPR_MDKT,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveInventory(player, "medicalkit", 1, item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_MEDICALKIT")
end
DefineDoomItem(name, object, states, onPickup)

doom.maxitems = $ or {}
doom.maxitems.medicalkit = 15