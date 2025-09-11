local function SafeFreeSlot(...)
	local ret = {}
	for _, name in ipairs({...}) do
		if rawget(_G, name) ~= nil then
			ret[name] = _G[name]
		else
			ret[name] = freeslot(name)
		end
	end
	return ret
end

-- Clip
SafeFreeSlot("SPR_CLIP", "sfx_itemup")
local name = "Clip"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2007,
	deathsound = sfx_itemup,
	sprite = SPR_CLIP,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "clip", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTCLIP")
end
DefineDoomItem(name, object, states, onPickup)

-- ClipBox
SafeFreeSlot("SPR_AMMO", "sfx_itemup")
local name = "ClipBox"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2048,
	deathsound = sfx_itemup,
	sprite = SPR_AMMO,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "clipbox", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTCLIPBOX")
end
DefineDoomItem(name, object, states, onPickup)

-- Shells
SafeFreeSlot("SPR_SHEL", "sfx_itemup")
local name = "Shells"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2008,
	deathsound = sfx_itemup,
	sprite = SPR_SHEL,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "shells", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTSHELLS")
end
DefineDoomItem(name, object, states, onPickup)

-- ShellBox
SafeFreeSlot("SPR_SBOX", "sfx_itemup")
local name = "ShellBox"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2049,
	deathsound = sfx_itemup,
	sprite = SPR_SBOX,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "shellbox", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTSHELLBOX")
end
DefineDoomItem(name, object, states, onPickup)

-- Rocket
SafeFreeSlot("SPR_ROCK", "sfx_itemup")
local name = "Rocket"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2010,
	deathsound = sfx_itemup,
	sprite = SPR_ROCK,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "rockets", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTROCKET")
end
DefineDoomItem(name, object, states, onPickup)

-- RocketBox
SafeFreeSlot("SPR_BROK", "sfx_itemup")
local name = "RocketBox"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2046,
	deathsound = sfx_itemup,
	sprite = SPR_BROK,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "rocketbox", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTROCKBOX")
end
DefineDoomItem(name, object, states, onPickup)

-- Cell
SafeFreeSlot("SPR_CELL", "sfx_itemup")
local name = "Cell"
local object = {
	radius = 20,
	height = 16,
	doomednum = 2047,
	deathsound = sfx_itemup,
	sprite = SPR_CELL,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "cell", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTCELL")
end
DefineDoomItem(name, object, states, onPickup)

-- CellPack
SafeFreeSlot("SPR_CELP", "sfx_itemup")
local name = "CellPack"
local object = {
	radius = 20,
	height = 16,
	doomednum = 17,
	deathsound = sfx_itemup,
	sprite = SPR_CELP,
	doomflags = DF_COUNTITEM
}
local states = {
	{frame = A, tics = 6},
}
local function onPickup(item, mobj)
	if not mobj.player then return true end
	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)
	local result = funcs.giveAmmoFor(player, "cellpack", item.doom.flags)
	if not result then return true end
	player.doom.bonuscount = 32
	DOOM_DoMessage(player, "GOTCELLBOX")
end
DefineDoomItem(name, object, states, onPickup)