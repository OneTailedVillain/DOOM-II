SafeFreeSlot("SPR_ROKT", "sfx_itemup")
local name = "CrateOfMissiles"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2046,
	conversationid = {182, 176, 180},
	deathsound = sfx_itemup,
	sprite = SPR_ROKT,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "crateofmissiles", item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_CRATEOFMISSILES")
end
DefineDoomItem(name, object, states, onPickup)