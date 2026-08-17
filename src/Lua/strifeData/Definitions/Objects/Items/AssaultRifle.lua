SafeFreeSlot("SPR_RIFL")
local name = "MiniMissiles"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2002,
	conversationid = {188, 182, 186},
	deathsound = sfx_wpnup,
	sprite = SPR_RIFL,
	doomflags = DF_COUNTITEM|DF_DM2RESPAWN
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveWeapon(player, "assaultgun", item.doom.flags)
	if not result then return true end
	
	DOOM_DoMessage(player, "$TXT_ASSAULTGUN")
end
DefineDoomItem(name, object, states, onPickup)