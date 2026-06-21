---@type doommethods_t
local methods = deepcopy(doom.charSupportBaseMethods)

doom.charSupport.dpecmegaman = {
	noHUD = true,

	useDoomMovement = true,
    methods = methods,

	css = {
		name = "Mega Man",
		description = {
			"Ouch, I *stubbed* my toe!"
		},
		sprite = SPR2_WALK,
		sequence = {A, 4}
	},

	properties = {
		movefactor = 2300, -- How fast the player will move in DOOM movement. Default is 2048.
		walkfactor = FRACUNIT*2/3, -- How much of the movefactor the player will use while walking in DOOM movement. Default is FRACUNIT/2.
		mass = 100, -- Player mass. Only relevant for explosion pushback.

		starthealth = 28*4, -- TODO: start with 16!
		maxhealth = 28*4,

		maxarmor = 28*4,

		armorproperties = { -- DOOMPort behavior makes it so security and combat armors ignore the armor property, which works in our favor for making the armors the blue and red tunics while preventing too much power by way of armor bonuses.
			armorclassmult = 28*4, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/3, -- Blue tunic protects this much in source game
			armorclass2prot = FRACUNIT/2, -- Red tunic protects this much in source game
		},

		
		startweapon = "megabuster",
		startweapons = {
			["megabuster"] = true
		},

		weaponremapping = {
			shotgun = "bill-spreadgun",
			chaingun = "bill-machinegun",
		}
	},

	vanillaoverrides = {
		strings = {
			GOTCHAINSAW = "You got the Homing Gun!  Find some aliens!",
			GOTSHOTGUN = "You got the Spread Gun!",
			GOTSHOTGUN2 = "You got the Flame Thrower!",
			GOTCHAINGUN = "You got the Machine Gun!",
			GOTLAUNCHER = "You got the Crush Gun!",
			GOTPLASMA = "You got the Laser!",
			GOTBFG9000 = "You got the Prototype Weapon!  Oh, yes.",
			GOTBERSERK = "Powerup token! Rapid Fire!"
		},
	}
}