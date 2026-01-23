local function MakeWeaponPickup(def)
	-- def = {
	--   weapon = "shotgun",
	--   message = "$GOTSHOTGUN",
	--   blockDuplicatesInDM = true/false
	-- }

	return function(item, mobj)
		-- Never run vanilla pickup logic
		if not mobj.player then
			return true
		end

		local player = mobj.player
		local funcs = P_GetMethodsForSkin(player)

		if gametype == GT_DOOMDM then
			if funcs.hasWeapon(player, def.weapon) then
				return true
			end
		end

		local result = funcs.giveWeapon(player, def.weapon, item.doom.flags or 0)
		if not result then
			return true
		end

		DOOM_DoMessage(player, def.message)

		if gametype == GT_DOOMDM then
			return true
		end
	end
end


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

SafeFreeSlot("SPR_CSAW", "sfx_wpnup")
local name = "Chainsaw"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2005,
	deathsound = sfx_wpnup,
	sprite = SPR_CSAW,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "chainsaw",
		message = "$GOTCHAINSAW",
	}
)

SafeFreeSlot("SPR_SHOT", "sfx_wpnup")
local name = "Shotgun"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2001,
	deathsound = sfx_wpnup,
	sprite = SPR_SHOT,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "shotgun",
		message = "$GOTSHOTGUN"
	}
)

SafeFreeSlot("SPR_SGN2")
local name = "SuperShotgun"

local object = {
	radius = 20,
	height = 16,
	doomednum = 82,
	deathsound = sfx_wpnup,
	sprite = SPR_SGN2,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "supershotgun",
		message = "$GOTSHOTGUN2",
	}
)

SafeFreeSlot("SPR_LAUN", "sfx_wpnup")
local name = "RPG"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2003,
	deathsound = sfx_wpnup,
	sprite = SPR_LAUN,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "rocketlauncher",
		message = "$GOTLAUNCHER",
	}
)

SafeFreeSlot("SPR_MGUN", "sfx_wpnup")
local name = "Chaingun"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2002,
	deathsound = sfx_wpnup,
	sprite = SPR_MGUN,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "chaingun",
		message = "$GOTCHAINGUN",
	}
)

SafeFreeSlot("SPR_PLAS", "sfx_wpnup")
local name = "PlasmaRifle"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2004,
	deathsound = sfx_wpnup,
	sprite = SPR_PLAS,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "plasmarifle",
		message = "$GOTPLASMA",
	}
)

SafeFreeSlot("SPR_BFUG", "sfx_wpnup")
local name = "BFG9000"

local object = {
	radius = 20,
	height = 16,
	doomednum = 2006,
	deathsound = sfx_wpnup,
	sprite = SPR_BFUG,
	doomflags = DF_COUNTITEM|DF_DMRESPAWN
}

local states = {
	{frame = A, tics = 6},
}

DefineDoomItem(name, object, states,
	MakeWeaponPickup{
		weapon = "bfg9000",
		message = "$GOTBFG9000",
	}
)