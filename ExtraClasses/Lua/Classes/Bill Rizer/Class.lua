freeslot("sfx_brdead")

---@type doommethods_t
local methods = deepcopy(doom.charSupportBaseMethods)

methods.onSoulsphere = function(player)
	player.doom.bill_lives = $ + 1
end

methods.damage = function(player, damage, attacker, proj, damageType, minhealth)
	local player, mobj = doom.resolvePlayerAndMobj(player)
	if not player or not mobj then return false end
	if (player.playerstate or PST_LIVE) == PST_DEAD then return false end

	-- doom-style with armor efficiency
	if player.mo.doom then
		local efficiency = player.mo.doom.armorefficiency or 0
		local damageToHealth = FixedMul(damage, efficiency)
		local damageToArmor  = damage - damageToHealth

		player.mo.doom.health = player.mo.doom.health - damageToHealth
		player.mo.doom.armor  = player.mo.doom.armor  - damageToArmor
		player.doom.bill_hurtflash = TICRATE/6

		if player.mo.doom.armor < 0 then
			-- doing this makes me look funny DD:
			-- but it's correct in the sense of math... or whatever
			player.mo.doom.health = player.mo.doom.health + player.mo.doom.armor
			player.mo.doom.armor = 0
		end

		if minhealth and player.mo.doom.health < minhealth then
			player.mo.doom.health = minhealth
		end

		if player.mo.doom.health < 1 and player.playerstate == PST_LIVE then
			--P_KillMobj(mobj, proj, attacker, damageType)
			P_InstaThrust(player.mo, player.mo.angle - ANGLE_180, 8*FRACUNIT)
			P_SetObjectMomZ(player.mo, FixedDiv(69*FRACUNIT,5*FRACUNIT), false)
			S_StartSound(player.mo, sfx_brdead)
			player.height = 16*FRACUNIT
			player.doom.bill_deathtimer = 1
		else
			S_StartSound(player.mo, sfx_plpain)
		end
		return true
	end

	return false
end

addHook("PlayerThink", function(player)
	if player.doom.bill_ogheight == nil then player.doom.bill_ogheight = player.height end
	if player.doom.bill_lives == nil then player.doom.bill_lives = 3 end
	if player.doom.bill_hurtflash then
		player.doom.bill_hurtflash = $ - 1
	end
end)

doom.charSupport.dpecbillrizer = {
	noHUD = true,

	useDoomMovement = true,
    methods = methods,

	-- Custom CSS bullshit
	css = {
		name = "Bill Rizer",
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
		damagefactor = {
			all = FRACUNIT,
		},

		movefactor = 2300, -- How fast the player will move in DOOM movement. Default is 2048.
		walkfactor = FRACUNIT*2/3, -- How much of the movefactor the player will use while walking in DOOM movement. Default is FRACUNIT/2.
		mass = 100, -- Player mass. Only relevant for explosion pushback.

		starthealth = 32,
		maxhealth = 32,

		-- The maximum value that Armor Bonuses
		-- And Megaspheres can get Armor to
		armormax = 200, -- effectively nothing (don't do 0 because of potential percenting errors)

		armorproperties = { -- DOOMPort behavior makes it so security and combat armors ignore the armor property, which works in our favor for making the armors the blue and red tunics while preventing too much power by way of armor bonuses.
			armorclassmult = 100, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/3, -- Blue tunic protects this much in source game
			armorclass2prot = FRACUNIT/2, -- Red tunic protects this much in source game
		},

		
		startweapon = "bill-rifle",
		startweapons = {
			["bill-rifle"] = true
		}
	},

	vanillaoverrides = {
		strings = {
			GOTCHAINSAW = "You got the Homing Gun!  Find some aliens!",
			GOTSHOTGUN = "You got the Spread Gun!",
			GOTSHOTGUN2 = "You learned the Flame Thrower!",
			GOTCHAINGUN = "You got the Machine Gun!",
			GOTLAUNCHER = "You got the Crush Gun!",
			GOTPLASMA = "You got the Laser!",
			GOTBFG9000 = "You got the Prototype Weapon!  Oh, yes.",
			GOTBERSERK = "Powerup token! Rapid Fire!"
		},
	}
}