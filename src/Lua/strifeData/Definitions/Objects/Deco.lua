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

SafeFreeSlot("SPR_BAR1")

local name = "BarricadeColumn"


local object = {
	radius = 16,
	height = 128,
	doomednum = 69,
	conversationid = 273,
	sprite = SPR_BAR1,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_BUSH")

local name = "ShortBush"


local object = {
	radius = 15,
	height = 40,
	doomednum = 60,
	sprite = SPR_BUSH,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_SHRB")

local name = "TallBush"


local object = {
	radius = 20,
	height = 64,
	conversationid = 271,
	doomednum = 62,
	sprite = SPR_SHRB,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TRCH")

local name = "SmallTorchLit"


local object = {
	radius = 3,
	height = 16,
	doomednum = 107,
	sprite = SPR_TRCH,
	flags = MF_NOBLOCKMAP,
}

local states = {
	{frame = A, tics = 4},
	{frame = B, tics = 4},
	{frame = C, tics = 4},
	{frame = D, tics = 4},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TLMP")

local name = "TechLampBrass"


local object = {
	radius = 8,
	height = 64,
	doomednum = 197,
	conversationid = 281,
	sprite = SPR_TLMP,
	flags = MF_SOLID,
}

local states = {
	{frame = B, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_LOGG", "sfx_wriver")

local name = "StickInWater"

local object = {
	radius = 3,
	height = 1,
	doomednum = 215,
	conversationid = 254,
	activesound = sfx_wriver,
	sprite = SPR_LOGG,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}

local function A_LoopActiveSound(actor)
	if not S_SoundPlaying(actor, actor.info.activesound) then
		S_StartSound(actor, actor.info.activesound)
	end
end

local states = {
	{frame = A, tics = 5, action = A_LoopActiveSound},
	{frame = B, tics = 5, action = A_LoopActiveSound},
	{frame = C, tics = 5, action = A_LoopActiveSound},
	{frame = D, tics = 5, action = A_LoopActiveSound},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_STOL")

local name = "Stool"


local object = {
	radius = 6,
	height = 24,
	doomednum = 189,
	conversationid = 276,
	sprite = SPR_STOL,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_BOTR")

local name = "RebelBoots"


local object = {
	radius = 1,
	height = 1,
	doomednum = 217,
	conversationid = 285,
	sprite = SPR_BOTR,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_MUGG")

local name = "Mug"

local object = {
	radius = 1,
	height = 1,
	doomednum = 164,
	conversationid = 132,
	sprite = SPR_MUGG,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_WATR")

local name = "WaterBottle"

local object = {
	radius = 1,
	height = 1,
	doomednum = 2014,
	conversationid = 131,
	sprite = SPR_WATR,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_LITS")

local name = "LightSilverFluorescent"

local object = {
	radius = 3,
	height = 16,
	doomednum = 95,
	conversationid = 206,
	sprite = SPR_LITS,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_LITB")

local name = "LightBrownFluorescent"

local object = {
	radius = 3,
	height = 16,
	doomednum = 96,
	conversationid = 207,
	sprite = SPR_LITB,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_LITG")

local name = "LightGoldFluorescent"

local object = {
	radius = 3,
	height = 16,
	doomednum = 97,
	conversationid = 208,
	sprite = SPR_LITG,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_SPLH", "sfx_wfall")

local name = "WaterfallSplash"

local object = {
	radius = 1,
	height = 1,
	doomednum = 104,
	conversationid = 225,
	sprite = SPR_SPLH,
	activesound = sfx_wfall
}

local states = {
	{frame = A, tics = 4},
	{frame = B, tics = 4},
	{frame = C, tics = 4},
	{frame = D, tics = 4},
	{frame = E, tics = 4},
	{frame = F, tics = 4},
	{frame = G, tics = 4},
	{frame = H, tics = 4, action = A_LoopActiveSound},
}

DefineDoomDeco(name, object, states, onPickup)