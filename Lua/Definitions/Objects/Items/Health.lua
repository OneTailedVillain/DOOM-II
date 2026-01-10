local function SafeFreeSlot(...)
    local ret = {}
    for _, name in ipairs({...}) do
        -- If already freed, just use the existing slot
        if rawget(_G, name) ~= nil then
            ret[name] = _G[name]
        else
            -- Otherwise, safely freeslot it and return the value
            ret[name] = freeslot(name)
        end
    end
    return ret
end

SafeFreeSlot("SPR_BON1")
local name = "HealthBonus"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2014,
	deathsound = sfx_itemup,
	sprite = SPR_BON1,
	doomflags = DF_COUNTITEM|DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
		{frame = A, tics = 6},
		{frame = B, tics = 6},
		{frame = C, tics = 6},
		{frame = D, tics = 6},
		{frame = C, tics = 6},
		{frame = B, tics = 6},
}

local function GiveHealthCompat(funcs, player, heal, clampMax)
	-- Prefer skin-provided giveHealth if available
	if funcs.giveHealth then
		-- expectedMaxHealth is used for clamping inside giveHealth
		return funcs.giveHealth(player, heal, clampMax)
	end

	-- Fallback: manual get/set
	local health = funcs.getHealth(player)
	local newhealth = min(health + heal, clampMax)

	if newhealth <= health then
		return false
	end

	funcs.setHealth(player, newhealth)
	return true
end

local function onPickup(item, mobj)
	if not mobj.player then return true end

	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)

	local maxhealth = funcs.getMaxHealth(player)
	local clampMax = maxhealth * 2

	GiveHealthCompat(funcs, player, 1, clampMax)
	DOOM_DoMessage(player, "$GOTHTHBONUS")
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_MEDI")
local name = "Medikit"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2012,
	deathsound = sfx_itemup,
	sprite = SPR_MEDI,
	doomflags = DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
		{frame = A, tics = INT32_MAX},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end

	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)

	local health = funcs.getHealth(player)
	local maxhealth = funcs.getMaxHealth(player)

	if health >= maxhealth then return true end

	local gained = GiveHealthCompat(funcs, player, 25, maxhealth)

	if gained then
		if health < 25 then
			DOOM_DoMessage(player, "$GOTMEDINEED")
		else
			DOOM_DoMessage(player, "$GOTMEDIKIT")
		end
	end
end

DefineDoomItem(name, object, states, onPickup)

SafeFreeSlot("SPR_STIM")
local name = "Stimpack"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2011,
	deathsound = sfx_itemup,
	sprite = SPR_STIM,
	doomflags = DF_ALWAYSPICKUP|DF_DM2RESPAWN
}

local states = {
		{frame = A, tics = INT32_MAX},
}

local function onPickup(item, mobj)
	if not mobj.player then return true end

	local player = mobj.player
	local funcs = P_GetMethodsForSkin(player)

	local health = funcs.getHealth(player)
	local maxhealth = funcs.getMaxHealth(player)

	if health >= maxhealth then return true end

	if GiveHealthCompat(funcs, player, 10, maxhealth) then
		DOOM_DoMessage(player, "$GOTSTIM")
	end
end

DefineDoomItem(name, object, states, onPickup)