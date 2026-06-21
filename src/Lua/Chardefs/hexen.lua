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
"sfx_sd2bfg",

"sfx_sdprel"
)

---@class doomcharproperties_t
---@field sounds table<integer, integer>? The sound properties for this charDef.

---@class doomcharsupport_t
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

doom.charSupport.johnhexenf = {
	-- Prefix used for the status bar (automap and otherwise)
	-- faceprefix = "SONIC",

	-- Custom CSS bullshit
	css = {
		name = "Baratus the Fighter",
		description = {
			"Frontline brawler built for endurance",
			"Excels in sustained melee pressure",
			"Shrugs off punishment better than most",
			"But lacks ranged flexibility and finesse"
		},
		sprite = SPR2_WALK,
		sequence = {A, 6}
	},

	properties = {
		sounds = {
			[sfx_plpain] = sfx_sd2pai,
			[sfx_pdiehi] = sfx_sd2dhi,
			[sfx_pldeth] = sfx_sd2die,
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
						{tics = 1},
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