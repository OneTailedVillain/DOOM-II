SafeFreeSlot("SPR_BLIT", "sfx_itemup")
local name = "ClipOfBullets"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2007,
	conversationid = {179, 173, 177},
	deathsound = sfx_itemup,
	sprite = SPR_BLIT,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "clipofbullets", item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_CLIPOFBULLETS")
end
DefineDoomItem(name, object, states, onPickup)