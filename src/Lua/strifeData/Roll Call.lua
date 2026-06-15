dofile(doom.currentGame .. "Data/Definitions/Inventory/Ammo.lua")
dofile(doom.currentGame .. "Data/Definitions/Inventory/Weps.lua")
dofile(doom.currentGame .. "Data/Definitions/Inventory/Doomweps.lua")

dofile(doom.currentGame .. "Data/Definitions/Objects/Effects/Gibs.lua")

dofile(doom.currentGame .. "Data/Definitions/Objects/Items/Gold.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/ClipOfBullets.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/BoxOfBullets.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/MiniMissiles.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/CrateOfMissiles.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/EnergyPod.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/MedPatch.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/MedicalKit.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Items/OfferingChalice.lua")

dofile(doom.currentGame .. "Data/Definitions/Objects/Deco.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Actors/Beggars.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Actors/Peasants.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Actors/Rebels.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Actors/Acolytes.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Actors/Alarm.lua")
dofile(doom.currentGame .. "Data/Definitions/Objects/Actors/Macil.lua")

dofile(doom.currentGame .. "Data/HUD/HUD.lua")

freeslot("sfx_rifle")
---@type table<integer, shortweapondef_t>
doom.predefinedWeapons = {
	{
		damage = {3, 15},
		pellets = 1,
		firesound = sfx_rifle,
		spread = {
			horiz = FRACUNIT*8,
			vert = 0,
		},
	},
}