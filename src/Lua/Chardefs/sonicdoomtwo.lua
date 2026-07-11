---@type doommethods_t
local methods = deepcopy(doom.characterDefsBaseMethods)

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
"sfx_sd2bfg",

"sfx_sdprel"
)

---@class doomcharproperties_t
---@field sounds table<integer, integer>? The sound properties for this charDef.

---@class doomcharacterDefs_t
---@field properties doomcharproperties_t?

local function ClipSys_OnTryFire(player, wepdef, curammo)
	if not curammo then
		if wepdef.reloadstep then
			DOOM_SetState(player, "reload_start", 1)
		else
			DOOM_SetState(player, "reload", 1)
		end
	end
end

local function ClipSys_PreStateChange(player, curstate, curframe, targetstate, targetframe, slot, wdef)
	if slot != PSP_WEAPON then return end
	local funcs = P_GetMethodsForSkin(player)

	local ctype = wdef.ammotype
	local rtype = wdef.clipammotype

	-- Handle reload loop logic
	if curstate == "reload_loop" and wdef.reloadstep then
		local cammo = funcs.getAmmoFor(player, rtype) or 0
		local clip = player.doom.ammo[ctype] or 0

		-- Stop if full or no reserve ammo
		if clip >= wdef.clipsize or cammo <= 0 then
			return "reload_end", 1
		end

		-- Load one step
		local step = wdef.reloadstep
		local needed = wdef.clipsize - clip
		local load = step

		if load > needed then load = needed end
		if load > cammo then load = cammo end

		player.doom.ammo[ctype] = clip + load
		player.doom.ammo[rtype] = $ - load

		-- Stay in loop
		return "reload_loop", 1
	end

	-- single-step reload
	if targetstate == "idle" then
		if curstate == "reload" then
			local cammo = funcs.getAmmoFor(player, rtype) or 0
			local clip = player.doom.ammo[ctype] or 0

			local needed = wdef.clipsize - clip
			if needed <= 0 then return end

			if cammo >= needed then
				player.doom.ammo[ctype] = clip + needed
				player.doom.ammo[rtype] = $ - needed
			else
				player.doom.ammo[ctype] = clip + cammo
				player.doom.ammo[rtype] = 0
			end
		elseif not player.doom.ammo[wdef.ammotype] then
			if wdef.reloadstep then
				return "reload_start", 1
			else
				return "reload", 1
			end
		end
	end
end

function A_FillClipOrIdle(actor, var1, var2, wdef)
	if not actor.player then return end
	if not wdef then return end

	local player = actor.player

	local funcs = P_GetMethodsForSkin(player)

	local ctype = wdef.ammotype
	local rtype = wdef.clipammotype

	local clip = player.doom.ammo[ctype] or 0
	local cammo = player.doom.ammo[rtype] or 0

	local needed = wdef.clipsize - clip

	-- already full or nothing to load
	if needed <= 0 then
		DOOM_SetState(player, "idle", 1)
		return
	end

	-- not enough reserve to fully fill, go idle
	if wdef.requirefullclip then
		if cammo < needed then
			DOOM_SetState(player, "idle", 1)
			return
		end
	end

	-- enough ammo, reload
	player.doom.ammo[ctype] = clip + needed
	player.doom.ammo[rtype] = $ - needed
end

function A_DoomCheckReload_ClipAware(actor, var1, var2, weapon)
	if not actor.player then return end
	local player = actor.player

	local funcs = P_GetMethodsForSkin(player)

	local ctype = weapon.ammotype
	local rtype = weapon.clipammotype

	local clip = player.doom.ammo[ctype] or 0
	local reserve = player.doom.ammo[rtype] or 0

	-- Not enough in clip to fire
	if clip - weapon.shotcost < 0 then
		-- If reserve exists, reload instead of switching
		if reserve > 0 then
			if weapon.reloadstep then
				DOOM_SetState(player, "reload_start", 1)
			else
				DOOM_SetState(player, "reload", 1)
			end
		else
			DOOM_DoAutoSwitch(player)
		end
	end
end

local SONIC_DAMAGEFACTOR = FRACUNIT + 45667
local SONIC_MOVEFACTOR = 3072

addHook("PlayerThink", function(player)
	if not player.mo then return end
	if player.mo.skin != "sonic" then return end
	local psp = player.doom.psprites[1]
	if psp.state == "reload" then
		-- Additional damage factor if hit during reload
		player.doom.properties.damagefactor.all = SONIC_DAMAGEFACTOR * 3/2
		-- ...Plus REALLY SLIGHT move bonus
		-- 9/8ths of movefactor will turn resulting speed of 22 to ~26
		player.doom.properties.movefactor = SONIC_MOVEFACTOR * 17/16
	else
		player.doom.properties.damagefactor.all = SONIC_DAMAGEFACTOR
		player.doom.properties.movefactor = SONIC_MOVEFACTOR
	end
end)

doom.addAmmo("clip_pistol", {
	icon = "SBOAMMO1",
	pickupamount = 1,
	max = 12,
	maxbackpackammo = 12,
	smallpickupName = "p",
	bigpickupName = "pp"
})

doom.addAmmo("clip_shotgun", {
	icon = "SBOAMMO2",
	pickupamount = 1,
	max = 12,
	maxbackpackammo = 12,
	smallpickupName = "s",
	bigpickupName = "sp"
})

doom.addAmmo("clip_ssg", {
	icon = "SBOAMMO2",
	pickupamount = 1,
	max = 6,
	maxbackpackammo = 6,
	smallpickupName = "g",
	bigpickupName = "gp"
})

doom.addAmmo("clip_chaingun", {
	icon = "SBOAMMO1",
	pickupamount = 1,
	max = 100,
	maxbackpackammo = 100,
	smallpickupName = "c",
	bigpickupName = "cp" -- CoD points... totally
})

doom.addAmmo("clip_plasma", {
	icon = "SBOAMMO5",
	pickupamount = 1,
	max = 60,
	maxbackpackammo = 60,
	smallpickupName = "r",
	bigpickupName = "rp"
})

doom.characterDefs.sonic = {
	-- Prefix used for the status bar (automap and otherwise)
	faceprefix = "SONIC",

	-- Custom CSS bullshit
	css = {
		name = "Sonic the Hedgehog",
		description = {
			"Able to fire weapons faster",
			"than everyone else",
			"However getting caught",
			"Off-guard when it matters",
			"Can get him killed"
		},
		sprite = SPR2_WALK,
		sequence = {A, 8}
	},

	properties = {
		sounds = {
			plpain = sfx_sd2pai,
			pdiehi = sfx_sd2dhi,
			pldeth = sfx_sd2die,
			noway = sfx_itemup,
		},

		dealdamagefactor = FRACUNIT,

		damagefactor = {
			all = FRACUNIT,
		},

		movefactor = SONIC_MOVEFACTOR,
		walkfactor = FRACUNIT/2,
		jumpfactor = FRACUNIT,
		mass = 70,

		starthealth = 85,

		-- "maxsoulsphere" will be derived by (maxhealth*2)
		-- If it's unspecified
		maxhealth = 85,

		-- The maximum value that Armor Bonuses
		-- And Megaspheres can get Armor to
		maxarmor = 126,

		armorproperties = {
			armorclassmult = 126/2, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/4, -- How much armor protection armor class 1 gives you
			armorclass2prot = FRACUNIT/3, -- How much armor protection armor class 2 (and up, as for some reason DOOM considers armor classes > 2 as 50% protection) gives you
		},

		-- Ammo is only valid for characters under the vanilla
		-- DOOM system
		startammo = {
			clip_pistol = 12,
			clip_shotgun = 12,
			clip_ssg = 2,
			clip_chaingun = 100,
			clip_plasma = 0,
			bullets = 30,
			shells = 0,
			cells = 0,
			rockets = 0,
		},

		maxammo = {
			bullets = 150,
			shells = 48,
			cells = 160,
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
				ammotype = "clip_pistol",
				clipammotype = "bullets",
				clipsize = 12,
				firesound = sfx_sd2pis,
				sprite = SPR_SD2_SONICPISTOL,
				states = {
					reload = {
						{frame = A, tics = 20},
						{frame = A, tics = 6, action = S_StartSound, var1 = sfx_sdprel, goto = "idle"}
					},
					raise = {tics = 1, action = A_DoomRaise},
					lower = {tics = 1, action = A_DoomLower},
					attack = {
						{tics = 2},
						{tics = 2},
						{tics = 2},
						{tics = 2},
					},
					flash = {
						{tics = 4},
					}
				},

				ontryfire = ClipSys_OnTryFire,
				prestatechange = ClipSys_PreStateChange,
			},

			shotgun = {
				firesound = sfx_sd2sht,
				sprite = SPR_SD2_SONICSHOTGUN,
				ammotype = "clip_shotgun",
				clipammotype = "shells",
				clipsize = 12,
				states = {
					reload = {
						{frame = A, tics = 20},
						{frame = A, tics = 6, action = S_StartSound, var1 = sfx_sdprel, goto = "idle"}
					},
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
				},

				ontryfire = ClipSys_OnTryFire,
				prestatechange = ClipSys_PreStateChange,
			},

			supershotgun = {
				sprite = SPR_SD2_SONICSSG,
				ammotype = "clip_ssg",
				clipammotype = "shells",
				clipsize = 2,
				requirefullclip = true,
				states = {
					raise = {tics = 1, action = A_DoomRaise},
					attack = {
						{tics = 2, action = A_None},
						{tics = 2, action = A_DoomFireShotgun2},
						{tics = 2, action = A_None},
						{tics = 2, action = A_None},
						{tics = 2, action = A_None},
						{tics = 2, action = A_FillClipOrIdle},
						{tics = 2},
						{tics = 2},
						{tics = 2},
						{tics = 2},
						{tics = 2},
						{tics = 2},
					},
					flash = {
						{tics = 2},
						{tics = 2},
					}
				}
			},

			-- Maybe ref Opposing Force's M249 Squad Automatic Weapon
			-- For the reload?
			chaingun = {
				firesound = sfx_sd2pis,
				ammotype = "clip_chaingun",
				clipammotype = "bullets",
				clipsize = 100,
				states = {
					reload = {
						{frame = A, tics = 35},
						{frame = A, tics = 6, action = S_StartSound, var1 = sfx_sdprel, goto = "idle"}
					},
					idle = {
						{frame = A, tics = 1},
					},
					attack = {
						{frame = A, tics = 3},
						{removeFrame = true}, -- This was the forced extra shot
						{frame = A}
					},
					flash = {
						{frame = A|FF_FULLBRIGHT, tics = 4},
						{removeFrame = true},
					}
				},

				ontryfire = ClipSys_OnTryFire,
				prestatechange = ClipSys_PreStateChange,
			},

			rocketlauncher = {
				firesound = sfx_sd2rla,
				states = {
					reload = {
						{frame = A, tics = 29},
						{frame = A, tics = 6, action = S_StartSound, var1 = sfx_sdprel, goto = "idle"}
					},
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

			-- TODO: HEAT SYSTEM!!
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
/*
freeslot("SPR_SD2_TAILSFISTS",
"SPR_SD2_TAILSPISTOL",
"SPR_SD2_TAILSSAW",
"SPR_SD2_TAILSSHOTGUN")

doom.characterDefs.tails = {
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
		maxarmor = 250,
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

doom.characterDefs.knuckles = {
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
		maxarmor = 250,
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

doom.characterDefs.metalsonic = {
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
		maxarmor = 150,
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
*/