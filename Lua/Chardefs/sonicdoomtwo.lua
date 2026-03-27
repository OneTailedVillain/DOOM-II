---@type doommethods_t
local methods = deepcopy(doom.charSupportBaseMethods)

freeslot("SPR_SD2_SONICBFG",
"SPR_SD2_SONICFISTS",
"SPR_SD2_SONICPISTOL",
"SPR_SD2_SONICSAW",
"SPR_SD2_SONICSHOTGUN",
"SPR_SD2_SONICSSG")

freeslot(
"MT_DOOM_SD2PLASMASHOT",
"sfx_sd2pnc",
"sfx_sd2pis",
"sfx_sd2sht",
"sfx_sd2rla",
"sfx_sd2bfg"
)

doom.charSupport.sonic = {
	-- Prefix used for the status bar (automap and otherwise)
	faceprefix = "SONIC",

	-- Custom CSS bullshit
	css = {
		name = "Sonic the Hedgehog",
		description = {
			"Able to fire weapons faster",
			"than everyone else",
			"However has weaker defense",
			"And lowered attacking power"
		},
		sprite = SPR2_WALK,
		sequence = {A, 8}
	},

	properties = {
		sounds = {
			--[sfx_plpain] = sfx_sd2pai,
			--[sfx_pdiehi] = sfx_sd2dhi,
			--[sfx_pldeth] = sfx_sd2die,
		},

		dealdamagefactor = FRACUNIT*3/4,

		damagefactor = {
			all = FRACUNIT*5/4,
		},

		movefactor = 2048 + 512,
		walkfactor = FRACUNIT/2,
		jumpfactor = FRACUNIT,
		mass = 70,

		starthealth = 75,

		-- "maxsoulsphere" will be derived by (maxhealth*2)
		-- If it's unspecified
		maxhealth = 75,

		-- The maximum value that Armor Bonuses
		-- And Megaspheres can get Armor to
		armormax = 200,

		armorproperties = {
			armorclassmult = 100, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/4, -- How much armor protection armor class 1 gives you
			armorclass2prot = FRACUNIT/3, -- How much armor protection armor class 2 (and up, as for some reason DOOM considers armor classes > 2 as 50% protection) gives you
		},

		-- Ammo is only valid for characters under the vanilla
		-- DOOM system
		startammo = {
			bullets = 30,
			shells = 0,
			cells = 0,
			rockets = 0,
		},

		maxammo = {
			bullets = 150,
			shells = 40,
			cells = 200,
			rockets = 40,
		},

		-- Multipliers of what pick-ups will give to the player
		-- "all" and a specific type will multiply the type factor with the "all" multiplier
		pickupfactors = {
			ammo = {
				all = FRACUNIT,
				bullets = FRACUNIT,
				shells = FRACUNIT,
				cells = FRACUNIT,
				rockets = FRACUNIT,
			},
			health = {
				all = FRACUNIT,
				medikit = FRACUNIT,
				stimpack = FRACUNIT
			},
			powerups = {
				all = FRACUNIT,
				invisibility = FRACUNIT,
				infrared = FRACUNIT,
				radsuit = FRACUNIT,
				invulnerability = FRACUNIT
			},
		},
	},

	-- Vanilla overrides
	-- Only valid if you're using vanilla stuff
	vanillaoverrides = {
		ammo = {
			bullets = {max = 100},
			shells  = {max = 30},
			cells   = {max = 150},
			rockets = {max = 30}
		},
		soulspheregive = 127,
		megaspheregive = 400,

		weapons = {
			brassknuckles = {
				hitsound = sfx_sd2pnc,
				sprite = SPR_SD2_SONICFISTS,
				states = {
					attack = {
						{tics = 3},
					}
				}
			},

			pistol = {
				firesound = sfx_sd2pis,
				sprite = SPR_SD2_SONICPISTOL,
				states = {
					attack = {
						{tics = 1},
					},
					flash = {
						{tics = 1},
					}
				}
			},

			shotgun = {
				firesound = sfx_sd2sht,
				sprite = SPR_SD2_SONICSHOTGUN,
				states = {
					attack = {
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
					},
					flash = {
						{tics = 1},
						{tics = 1},
					}
				}
			},

			supershotgun = {
				sprite = SPR_SD2_SONICSSG,
				states = {
					attack = {
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
						{tics = 1},
					},
					flash = {
						{tics = 1},
						{tics = 1},
					}
				}
			},

			chaingun = {
				firesound = sfx_sd2pis,
				states = {
					attack = {
						{tics = 1},
					},
					flash = {
						{tics = 1},
					}
				}
			},

			rocketlauncher = {
				firesound = sfx_sd2rla,
				states = {
					attack = {
						{tics = 2},
					},
					flash = {
						{tics = 1},
					}
				}
			},

			chainsaw = {
				sprite = SPR_SD2_SONICSAW,
				states = {
					idle = {
						{tics = 1},
					},
					attack = {
						{tics = 1},
					}
				}
			},

			plasmarifle = {
				shootmobj = MT_DOOM_SD2PLASMASHOT,
				states = {
					attack = {
						{tics = 1},
						{tics = 10},
					},
					flash = {
						{tics = 1},
					}
				}
			},

			bfg9000 = {
				firesound = sfx_sd2bfg,
				sprite = SPR_SD2_SONICBFG,
				states = {
					attack = {
						{tics = 5},
					},
					flash = {
						{tics = 5},
					}
				}
			},
		}
	},
	useDoomMovement = true,
	forceDisableJump = true,
    methods = methods
}

freeslot("SPR_SD2_TAILSFISTS",
"SPR_SD2_TAILSPISTOL",
"SPR_SD2_TAILSSAW",
"SPR_SD2_TAILSSHOTGUN")

doom.charSupport.tails = {
	-- Prefix used for the status bar (automap and otherwise)
	faceprefix = "TAILS",

	-- Custom CSS bullshit
	css = {
		name = 'Miles "Tails" Prower',
		sprite = SPR2_WALK,
		sequence = {A, 8},
		description = {
			"Balanced stats",
			"with higher survivability",
			"Carries more ammo than others",
			"Reliable in extended fights",
			"But lacks any",
			"strong specialization"
		}
	},

	properties = {
		mass = 100,
		starthealth = 100,
		maxhealth = 125,
		armormax = 250,
		movefactor = 2048,
		walkfactor = FRACUNIT/2,

		dealdamagefactor = FRACUNIT,
		damagefactor = {
			all = FRACUNIT,
		},

		armorproperties = {
			armorclassmult = 100,
			armorclass1prot = FRACUNIT/3,
			armorclass2prot = FRACUNIT/2,
		},

		maxammo = {
			bullets = 250,
			shells = 64,
			cells = 375,
			rockets = 64,
		},
	},

	-- Vanilla overrides
	-- Only valid if you're using vanilla stuff
	vanillaoverrides = {
		soulspheregive = 125,
		megaspheregive = 250,

		weapons = {
			brassknuckles = {
				sprite = SPR_SD2_TAILSFISTS,
				states = {idle = {{tics = 1}}}
			},

			pistol = {
				sprite = SPR_SD2_TAILSPISTOL,
				states = {idle = {{tics = 1}}}
			},

			shotgun = {
				sprite = SPR_SD2_TAILSSHOTGUN,
				states = {idle = {{tics = 1}}}
			},

			chainsaw = {
				sprite = SPR_SD2_TAILSSAW,
				states = {idle = {{tics = 1}}}
			},
		}
	},
	useDoomMovement = true,
	forceDisableJump = true,
    methods = methods
}

freeslot("SPR_SD2_KNUXFISTS",
"SPR_SD2_KNUXPISTOL",
"SPR_SD2_KNUXSAW",
"SPR_SD2_KNUXSHOTGUN")

doom.charSupport.knuckles = {
	-- Prefix used for the status bar (automap and otherwise)
	faceprefix = "KNUX",

	-- Custom CSS bullshit
	css = {
		name = 'Knuckles the Echidna',
		sprite = SPR2_WALK,
		sequence = {A, 8},
		description = {
			"Deals increased damage overall",
			"Higher health and durability",
			"Excels in close-range combat",
			"But slower movement",
			"limits mobility"
		}
	},

	properties = {
		mass = 120,
		starthealth = 125,
		maxhealth = 125,
		armormax = 250,
		movefactor = 1920,
		walkfactor = FRACUNIT/2,

		dealdamagefactor = FRACUNIT*5/4,
		damagefactor = {
			all = FRACUNIT,
		},

		armorproperties = {
			armorclassmult = 100,
			armorclass1prot = FRACUNIT/3,
			armorclass2prot = FRACUNIT/2,
		},
	},

	-- Vanilla overrides
	-- Only valid if you're using vanilla stuff
	vanillaoverrides = {
		soulspheregive = 125,
		megaspheregive = 250,

		weapons = {
			brassknuckles = {
				damage = {4, 40},
				sprite = SPR_SD2_KNUXFISTS,
				states = {attack = {
					{tics = 1},
					{tics = 1},
					{tics = 1},
					{tics = 1},
					{tics = 1},
				}
			}
			},

			pistol = {
				sprite = SPR_SD2_KNUXPISTOL,
				states = {idle = {{tics = 1}}}
			},

			shotgun = {
				sprite = SPR_SD2_KNUXSHOTGUN,
				states = {idle = {{tics = 1}}}
			},

			chainsaw = {
				sprite = SPR_SD2_KNUXSAW,
				states = {idle = {{tics = 1}}}
			},
		}
	},
	useDoomMovement = true,
	forceDisableJump = true,
    methods = methods
}

freeslot("SPR_SD2_MECHACHAINGUN",
"SPR_SD2_MECHAPLASMARIFLE", "SPR_SD2_MECHAPLASMARIFLEFLASH")

doom.charSupport.metalsonic = {
	-- Prefix used for the status bar (automap and otherwise)
	faceprefix = "MECHA",

	-- Custom CSS bullshit
	css = {
		name = "Metal Sonic",
		sprite = SPR2_WALK,
		sequence = {A, 1},
		description = {
			"High speed and damage output",
			"Relentless offensive pressure",
			"However takes more damage",
			"And has lower",
			"maximum survivability"
		}
	},

	properties = {
		mass = 90,
		starthealth = 90,
		maxhealth = 90,
		armormax = 150,
		movefactor = 2304,
		walkfactor = FRACUNIT/2,

		dealdamagefactor = FRACUNIT*5/4,
		damagefactor = {
			all = FRACUNIT*5/4,
		},

		armorproperties = {
			armorclassmult = 100,
			armorclass1prot = FRACUNIT/4,
			armorclass2prot = FRACUNIT/3,
		},

		maxammo = {
			bullets = 150,
			shells = 30,
			cells = 250,
			rockets = 30,
		},
	},

	-- Vanilla overrides
	-- Only valid if you're using vanilla stuff
	vanillaoverrides = {
		ammo = {
			bullets = {max = 100},
			shells  = {max = 30},
			cells   = {max = 150},
			rockets = {max = 30}
		},

		soulspheregive = 100,
		megaspheregive = 180,

		weapons = {
			pistol = {
				firesound = sfx_sd2pis,
			},
			chaingun = {
				sprite = SPR_SD2_MECHACHAINGUN,
				flashsprite = SPR_SD2_MECHACHAINGUN,
				states = {
					flash = {
						{frame = 2|FF_FULLBRIGHT, tics = 4},
						{frame = 3|FF_FULLBRIGHT, tics = 4}
					}
				}
			},

			plasmarifle = {
				sprite = SPR_SD2_MECHAPLASMARIFLE,
				flashsprite = SPR_SD2_MECHAPLASMARIFLEFLASH,
			},
		}
	},
	useDoomMovement = true,
	forceDisableJump = true,
    methods = methods
}