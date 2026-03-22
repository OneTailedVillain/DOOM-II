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
		sprite = SPR2_WALK,
		sequence = {A, 8}
	},

	properties = {
		damagefactor = {
			all = FRACUNIT*5/4,
		},
		movefactor = 2048 + 512 -- Used only for doom movement
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
		maxhealth = 200,
		maxarmor = 200,
		maxsoulsphere = 400,
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
		sequence = {A, 8}
	},

	-- Vanilla overrides
	-- Only valid if you're using vanilla stuff
	vanillaoverrides = {
		maxhealth = 200,
		maxarmor = 200,
		maxsoulsphere = 400,
		soulspheregive = 127,
		megaspheregive = 400,

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
		sequence = {A, 8}
	},

	-- Vanilla overrides
	-- Only valid if you're using vanilla stuff
	vanillaoverrides = {
		maxhealth = 200,
		maxarmor = 200,
		maxsoulsphere = 400,
		soulspheregive = 127,
		megaspheregive = 400,

		weapons = {
			brassknuckles = {
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

freeslot("SPR_SD2_MECHACHAINGUN", "SPR_SD2_MECHACHAINGUNFLASH",
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
			"No soul. No hesitation.",
			"Built to surpass.",
			"Execution is inevitable."
		}
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
		maxhealth = 200,
		maxarmor = 200,
		maxsoulsphere = 400,
		soulspheregive = 127,
		megaspheregive = 400,

		weapons = {
			pistol = {
				firesound = sfx_sd2pis,
			},
			chaingun = {
				sprite = SPR_SD2_MECHACHAINGUN,
				flashsprite = SPR_SD2_MECHACHAINGUNFLASH,
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