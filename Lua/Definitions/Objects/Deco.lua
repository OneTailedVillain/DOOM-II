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

local name = "Corpse"


local object = {
	radius = 16,
	height = 20,
	doomednum = 15,
	sprite = SPR_PLAY,
}

local states = {
	{frame = N, tics = INT32_MAX},
}

DefineDoomDeco(name, object, states, onPickup)

local name = "BloodyMess"


local object = {
	radius = 12,
	height = 20,
	doomednum = 10,
	sprite = SPR_PLAY,
}

local states = {
	{frame = W, tics = INT32_MAX},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_COLU")
local name = "FloorLamp"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2028,
	sprite = SPR_COLU,
	flags = MF_SOLID,
}

local states = {
		{frame = A, tics = INT32_MAX},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TLP2")
local name = "ShortTechnoFloorLamp"

local object = {
	radius = 16,
	height = 60,
	doomednum = 86,
	sprite = SPR_TLP2,
	bulletheight = 16,
	flags = MF_SOLID,
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 4},
	{frame = B|FF_FULLBRIGHT, tics = 4},
	{frame = C|FF_FULLBRIGHT, tics = 4},
	{frame = D|FF_FULLBRIGHT, tics = 4},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_ELEC")
local name = "TallTechnoColumn"

local object = {
	radius = 16,
	height = 128,
	doomednum = 48,
	sprite = SPR_ELEC,
	bulletheight = 16,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = INT32_MAX},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TLMP")
local name = "TallTechnoFloorLamp"

local object = {
	radius = 16,
	height = 80,
	doomednum = 85,
	sprite = SPR_TLMP,
	bulletheight = 16,
	flags = MF_SOLID,
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 4},
	{frame = B|FF_FULLBRIGHT, tics = 4},
	{frame = C|FF_FULLBRIGHT, tics = 4},
	{frame = D|FF_FULLBRIGHT, tics = 4},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TGRN")
local name = "GreenTorch"

local object = {
	radius = 16,
	height = 68,
	doomednum = 45,
	sprite = SPR_TGRN,
	bulletheight = 16,
	flags = MF_SOLID,
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 4},
	{frame = B|FF_FULLBRIGHT, tics = 4},
	{frame = C|FF_FULLBRIGHT, tics = 4},
	{frame = D|FF_FULLBRIGHT, tics = 4},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TBLU")
local name = "BlueTorch"

local object = {
	radius = 16,
	height = 68,
	doomednum = 44,
	sprite = SPR_TBLU,
	bulletheight = 16,
	flags = MF_SOLID,
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = 4},
	{frame = B|FF_FULLBRIGHT, tics = 4},
	{frame = C|FF_FULLBRIGHT, tics = 4},
	{frame = D|FF_FULLBRIGHT, tics = 4},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TRE2")
local name = "BigTree"

local object = {
	radius = 16,
	height = 68,
	doomednum = 54,
	sprite = SPR_TRE2,
	bulletheight = 16,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_HDB5")
local name = "HangTLookingUp"

local object = {
	radius = 16,
	height = 64,
	doomednum = 77,
	sprite = SPR_HDB5,
	bulletheight = 16,
	flags = MF_SPAWNCEILING|MF_NOGRAVITY|MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_HDB2")
local name = "HangTLookingUp"

local object = {
	radius = 16,
	height = 88,
	doomednum = 74,
	sprite = SPR_HDB2,
	bulletheight = 16,
	flags = MF_SPAWNCEILING|MF_NOGRAVITY|MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_GOR4")
local name = "Meat4"

local object = {
	radius = 16,
	height = 68,
	doomednum = 85,
	sprite = SPR_GOR4,
	bulletheight = 16,
	flags = MF_SOLID|MF_NOGRAVITY|MF_SPAWNCEILING,
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

local name = "NonsolidMeat4"

local object = {
	radius = 20,
	height = 68,
	doomednum = 60,
	sprite = SPR_GOR4,
	bulletheight = 16,
	flags = MF_NOGRAVITY|MF_SPAWNCEILING,
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_GOR5")
local name = "Meat5"

local object = {
	radius = 16,
	height = 52,
	doomednum = 53,
	sprite = SPR_GOR5,
	bulletheight = 16,
	flags = MF_SOLID|MF_NOGRAVITY|MF_FLOAT|MF_SPAWNCEILING,
}

local states = {
	{frame = A|FF_FULLBRIGHT, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

local name = "NonsolidMeat5"

local object = {
	radius = 20,
	height = 52,
	doomednum = 62,
	sprite = SPR_GOR5,
	bulletheight = 16,
	flags = MF_NOGRAVITY|MF_FLOAT|MF_SPAWNCEILING,
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_POB1")
local name = "ColonGibs"

local object = {
	radius = 20,
	height = 4,
	doomednum = 85,
	sprite = SPR_POB1,
	flags = MF_NOBLOCKMAP,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_POB2")
local name = "SmallBloodPool"

local object = {
	radius = 20,
	height = 1,
	doomednum = 85,
	sprite = SPR_POB2,
	flags = MF_NOBLOCKMAP,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_COL6")
local name = "RedPillarWithSkull"

local object = {
	radius = 16,
	height = 40,
	doomednum = 37,
	sprite = SPR_COL6,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_TRE1")
local name = "BurntTree"

local object = {
	radius = 16,
	height = 40,
	doomednum = 43,
	sprite = SPR_TRE1,
	flags = MF_SOLID,
}

local states = {
	{frame = A, tics = -1},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_GOR1")
local name = "BloodyTwitching"

local object = {
	radius = 16,
	height = 68,
	doomednum = 49,
	sprite = SPR_GOR1,
	bulletheight = 16,
	flags = MF_SOLID|MF_NOGRAVITY|MF_SPAWNCEILING,
}

local states = {
	{frame = A, tics = 10},
	{frame = B, tics = 15},
	{frame = C, tics = 8},
	{frame = B, tics = 6},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_COL2")
local name = "ShortGreenPillar"

local object = {
	radius = 16,
	height = 40,
	doomednum = 31,
	sprite = SPR_COL2,
	flags = MF_SOLID,
}

local states = {
		{frame = A, tics = INT32_MAX},
}

DefineDoomDeco(name, object, states, onPickup)

SafeFreeSlot("SPR_COL5")
local name = "HeartColumn"

local object = {
	radius = 16,
	height = 40,
	doomednum = 36,
	sprite = SPR_COL5,
	flags = MF_SOLID,
}

local states = {
		{frame = A, tics = 14},
		{frame = B, tics = 14},
}

DefineDoomDeco(name, object, states, onPickup)