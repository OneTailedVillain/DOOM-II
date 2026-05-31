freeslot("SPR_LINK_SSG", "SPR_LINK_FIREROD", "sfx_lttpbd", "sfx_lttpbb", "sfx_lttpaf",
"sfx_lttplh", "sfx_lttpld")

---@type doommethods_t
local methods = deepcopy(doom.charSupportBaseMethods)

-- Except this since we want vanilla behavior for EVERYTHING but berserk pack
-- Berserk gives a temporary double magic and 2x damage to all weapons
-- Will last off after one minute or exiting a level
methods.doPowerUp = function (player, powername)
	local durationMap = {
		berserk         = 1,
		invisibility    = 120 * TICRATE,
		invulnerability = 30 * TICRATE,
		ironfeet        = 60 * TICRATE,
	}
	local ptypeMap = {
		berserk         = pw_strength,
		invisibility    = pw_invisibility,
		invulnerability = pw_invulnerability,
		ironfeet        = pw_ironfeet,
	}
	local duration = durationMap[powername]
	local ptype = ptypeMap[powername]
	if not duration or not ptype then print("FAIL! on base doPowerup method", powername, duration, ptype) return false end

	if powername == "berserk" then
		player.doom.zsnes_pieceofpower = 60*TICRATE
		player.doom.ammo["magic"] = $ * 2
		player.doom.properties.dealdamagefactor = ($ or FRACUNIT) * 2
		P_PlayJingleMusic(player, "ZGBPOW", 0, true)
	elseif powername == "invisibility" then
		doom.giveInventory(player, "magiccape")
	elseif powername == "invulnerability" then
		doom.giveInventory(player, "caneofbyrna")
	else
		player.doom.powers[ptype] = duration
	end

	return true
end

local function SkillMaskFor(skill)
	if skill <= 2 then
		return 1
	elseif skill == 3 then
		return 2
	end
	return 4
end

addHook("MapLoad", function()
	local toCheckFor = {
		keycards = {MT_DOOM_BLUEKEYCARD, MT_DOOM_YELLOWKEYCARD, MT_DOOM_REDKEYCARD},
		skulls = {MT_DOOM_BLUESKULL, MT_DOOM_YELLOWSKULL, MT_DOOM_REDSKULL},
	}

	doom.zsnes_keycardexistent = false
	doom.zsnes_skullkeyexistent = false

	for mthing in mapthings.iterate do
		if (mthing.z & 1) and not multiplayer then
			continue
		end

		local needed = SkillMaskFor(doom.gameskill)
		if not (mthing.options & needed) then
			continue
		end

		-- "unfortunately the game is an asshole and sets"
		-- "[the multiplayer] spawnpoint mapthing IDs to zero, ambiguating them"
		-- There is literally no way to know exactly what mapthing ID is what,
		-- So they're all mapthing 33 now :3
		if not tth_doombuild then
			if mthing.type == 0 then
				mthing.type = 34
			end
		end

		local override = doom.callHook(
			"MapThingSpawn",
			doom.hookTypes.lastfunc,
			mthing
		)

		if override == false then
			continue -- block spawn completely
		elseif override != nil then
			mthing.type = override -- override doomednum
		end

		for k, v in ipairs(toCheckFor.keycards) do
			if mthing.type == mobjinfo[v].doomednum then
				doom.zsnes_keycardexistent = true
			end
		end

		for k, v in ipairs(toCheckFor.skulls) do
			if mthing.type == mobjinfo[v].doomednum then
				doom.zsnes_skullkeyexistent = true
			end
		end
	end
end)

methods.getMaxFor = function(player, aType)
	if not player or not aType then return nil end
	local properties = P_GetPlayerSkinProperties(player)
	local maxammo
	if properties and properties.maxammo != nil then
		if player.doom.backpack then
			local maxbpa = properties.maxbackpackammo
			local maxa = properties.maxammo
			local numax = maxbpa and maxbpa[aType]
			if numax == nil then
				numax = maxa and maxa[aType]
				if numax != nil then
					numax = $ * 2
				end
			end
			if numax == nil then
				print("Ammo type " .. tostring(aType) .. " is unsupported by this skin!")
			end
			maxammo = numax
		else
			maxammo = properties.maxammo[aType]
		end
	elseif player.doom then
		if player.doom.backpack and doom.ammos[aType] then
			maxammo = doom.ammos[aType].backpackmax
		elseif doom.ammos[aType] then
			maxammo = doom.ammos[aType].max
		end
	end

	-- Magic: Double again if the Piece of Power is active
	if aType == "magic" then
		if player.doom.zsnes_pieceofpower then
			maxammo = $ * 2
		end
	end
	return maxammo
end

-- Piece of Power ticker
addHook("PlayerThink", function(player)
	if not player.doom.zsnes_pieceofpower then return end
	if player.doom.zsnes_pieceofpower <= 0 then return end
	print(player.doom.zsnes_pieceofpower)
	player.doom.zsnes_pieceofpower = $ - 1
	if player.doom.zsnes_pieceofpower <= TICRATE*2 then
		P_RestoreMusic(player)
	end
	if player.doom.zsnes_pieceofpower <= 0 then
		-- Revert magic when the Piece of Power has run dry
		player.doom.ammo["magic"] = $ / 2
		player.doom.properties.dealdamagefactor = $ / 2
	end
end)

methods.onSoulsphere = function(player)
	player.mo.doom.maxhealth = $ + 10
	-- Max 20 hearts
	if player.mo.doom.maxhealth > 200 then
		player.mo.doom.maxhealth = 200
	end
	player.mo.doom.health = player.mo.doom.maxhealth
end

local function A_DoomFireShotgun2(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom
	DOOM_Fire(actor, MISSILERANGE, false, FRACUNIT*71/10, 20, 5, 15)
	pd.ammo[weapon.ammotype] = $ - 10
	S_StartSound(actor, sfx_lttpbd)
	A_DoomGunFlash(actor)
end

doom.charSupport.alttplinkdpexamp = {
	noHUD = true,

	-- Custom CSS bullshit
	css = {
		name = "Link",
		description = {
			"Fighter with tools for every range",
			"Strikes hard up close and can",
			"Easily turn defense into pressure",
			"Manages ammo and magic for peak output",
			"But careless resource use leaves him exposed"
		},
		sprite = SPR2_WALK,
		sequence = {A, 4}
	},

	properties = {
		sounds = {
			[sfx_plpain] = sfx_lttplh,
			[sfx_pdiehi] = sfx_lttpld,
			[sfx_pldeth] = sfx_lttpld,
		},

		damagefactor = {
			all = FRACUNIT,
		},

		movefactor = 2300, -- How fast the player will move in DOOM movement. Default is 2048.
		walkfactor = FRACUNIT*2/3, -- How much of the movefactor the player will use while walking in DOOM movement. Default is FRACUNIT/2.
		mass = 100, -- Player mass. Only relevant for explosion pushback.

		starthealth = 100,
		maxhealth = 100,
		soulspherehealth = 100, -- How much health that health bonuses and soulspheres are able to give to the player. Will default to 2x (current max health) if left out

		-- The maximum value that Armor Bonuses
		-- And Megaspheres can get Armor to
		armormax = 1, -- effectively nothing (don't do 0 because of potential percenting errors)

		armorproperties = { -- DOOMPort behavior makes it so security and combat armors ignore the armor property, which works in our favor for making the armors the blue and red tunics while preventing too much power by way of armor bonuses.
			armorclassmult = 50, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/2, -- Blue tunic protects this much in source game
			armorclass2prot = FRACUNIT*3/4, -- Red tunic protects this much in source game
		},

		-- Ammo is only valid for characters under the vanilla
		-- DOOM system
		startammo = {
			arrows = 30,
			magic = 25
		},

		maxammo = {
			arrows = 80,
			rupees = 250,
			bombs = 25,
			magic = 100 -- doing this significantly reduces precision loss due to SRB2's truncation in division (which is necessary for percenting)
		},

		startweapon = "bow",
		startweapons = {
			bow = true,
			fighterssword = true
		},

		weaponremapping = {
			brassknuckles = "fighterssword",
			chainsaw = "pegasusboots",
			pistol = "bow",
			shotgun = "lamp",
			chaingun = "slingshot",
			rocketlauncher = "bomb",
			bfg9000 = "mastersword"
		}
	},

	vanillaoverrides = {
		weapons = {
			supershotgun = {
				firesound = sfx_lttpbd,
				sprite = SPR_LINK_SSG,
				flashsprite = SPR_LINK_SSG,
				ammotype = "magic",
				shotcost = 10,
				states = {
					idle = {
						{frame = A, tics = 1, action = A_DoomWeaponReady},
					},
					lower = {
						{frame = A, tics = 1, action = A_DoomLower}
					},
					raise = {
						{frame = A, tics = 1, action = A_DoomRaise}
					},
					attack = {
						{frame = A, tics = 3},
						{frame = G, tics = 0, action = A_PlaySound, var1 = sfx_lttpbb},
						{frame = G, tics = 0, action = A_PlaySound, var1 = sfx_lttpaf},
						{frame = A, tics = 7, action = A_DoomFireShotgun2},
						{frame = B, tics = 7},
						{frame = C, tics = 7, action = A_DoomCheckReload},
						{frame = D, tics = 7},--, action = A_PlaySound, var1 = sfx_dbopn, var2 = 1},
						{frame = E, tics = 7},
						{frame = F, tics = 7},--, action = A_PlaySound, var1 = sfx_dbload, var2 = 1},
						{frame = G, tics = 8},
						{frame = H, tics = 8},--, action = A_PlaySound, var1 = sfx_dbcls, var2 = 1},
						{frame = A, tics = 5, action = A_DoomReFire, goto = "idle"},
						{frame = B, tics = 7},
						{frame = A, tics = 3, goto = "lower"},
					},
					flash = {
						-- Flashframe jank
						{frame = I|FF_FULLBRIGHT, tics = 5, action = A_DoomLight1},
						{frame = J|FF_FULLBRIGHT, tics = 4, action = A_DoomLight2, goto = S_DOOM_LIGHTDONE},
					}
				},
			},
			plasmarifle = {
				ammotype = "magic",
				sprite = SPR_LINK_FIREROD,
				flashsprite = SPR_LINK_FIREROD,
				states = {
					idle = {
						{frame = 7, tics = 1, action = A_DoomWeaponReady},
					},
					lower = {
						{frame = 7, tics = 1, action = A_DoomLower}
					},
					raise = {
						{frame = 7, tics = 1, action = A_DoomRaise}
					},
					attack = {
						{frame = 7, tics = 3, action = A_DoomFirePlasma},
						{frame = 8, tics = 20, action = A_DoomReFire},
					},
					flash = {
						{frame = 5|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
						{frame = 6|FF_FULLBRIGHT, tics = 4, action = A_DoomLight1, goto = S_DOOM_LIGHTDONE},
					},
				},
			},
		},
		strings = {
			GOTCLIP = "Picked up an arrow.",
			GOTCLIPBOX = "Picked up a bundle of arrows.",
			GOTSHELLS = "Picked up a small magic jar.", -- 10% magic
			GOTSHELLBOX = "Picked up a large magic jar.", -- 40% magic (nerfed from source game's 100%)
			GOTROCKET = "Picked up a bomb.",
			GOTROCKBOX = "Picked up some bombs.",
			GOTCELL = "Picked up a blue rupee.",
			GOTCELLBOX = "Picked up a red rupee.",
			GOTCHAINSAW = "You got the Pegasus Boots! Hold altfire... then release!",
			GOTSHOTGUN = "You got the Lamp!",
			GOTSHOTGUN2 = "You learned the Magic Hands!", -- simple sprite replacement (along with fire rod)
			GOTCHAINGUN = "You got the Slingshot!",
			GOTLAUNCHER = "You got some Bombs!",
			GOTPLASMA = "You got the Fire Rod!",
			GOTBFG9000 = "You got the Master Sword!  Oh, yes.",
			GOTARMOR = "Picked up a tattered Blue Tunic.",
			GOTMEGA = "Picked up a tattered Red Tunic.",
			GOTARMBONUS = "Picked up a green rupee.",
			GOTSUPER = "You got a heart container!",
			GOTBERSERK = "Piece of Power!",
			GOTINVIS = "Magic Cape!",
			GOTINVUL = "Staff of Byrna!",
		}
	},

	useDoomMovement = true,
	forceDisableJump = true,
    methods = methods
}