SafeFreeSlot("SPR_BBOX", "sfx_itemup")
local name = "BoxOfBullets"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2048,
	conversationid = {180, 174, 178},
	deathsound = sfx_itemup,
	sprite = SPR_BBOX,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "boxofbullets", item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_BOXOFBULLETS")
end
DefineDoomItem(name, object, states, onPickup)