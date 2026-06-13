SafeFreeSlot("SPR_BRY1", "sfx_itemup")
local name = "EnergyPod"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2047,
	conversationid = {183, 177, 181},
	deathsound = sfx_itemup,
	sprite = SPR_BRY1,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "energypod", item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_ENERGYPOD")
end
DefineDoomItem(name, object, states, onPickup)