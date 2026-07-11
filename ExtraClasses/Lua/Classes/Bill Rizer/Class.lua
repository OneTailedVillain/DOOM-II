freeslot("sfx_brdead", "sfx_brglif")

---@type doommethods_t
local methods = deepcopy(doom.characterDefsBaseMethods)
-- How many kills are needed to get an extra life
local KILLSFORLIFE = 40

-- How much damage colliding with an enemy will deal
local INVULNCONTACTDAMAGE = 1000

methods.onKill = function(player, victim)
	if not (victim.doom.flags & DF_FRIENDLY) then
		player.doom.bill_kills = ($ or 0) + 1
	end
	if player.doom.bill_kills >= KILLSFORLIFE then
		player.doom.bill_lives = $ + 1
		S_StartSound(nil, sfx_brglif, player)
		player.doom.bill_kills = 0
	end
end

methods.onSoulsphere = function(player)
	player.doom.bill_lives = $ + 1
	S_StartSound(nil, sfx_brglif, player)
end

local function Valid(userdataa)
	return userdataa and userdataa.valid
end

methods.damage = function(player, damage, attacker, proj, damageType, minhealth)
	local player, mobj = doom.resolvePlayerAndMobj(player)
	if not player or not mobj then return false end
	if (player.playerstate or PST_LIVE) == PST_DEAD then return false end

	-- lower damagefactor if attacker and proj are both nil
	-- (likely means it's a damaging sector)
	if not (Valid(attacker) and Valid(proj)) then
		player.doom.properties.damagefactor.all = FRACUNIT
	else
		player.doom.properties.damagefactor.all = FRACUNIT*3
	end

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
			P_InstaThrust(player.mo, player.mo.angle - ANGLE_180, 4*FRACUNIT)
			P_SetObjectMomZ(player.mo, FixedDiv(69*FRACUNIT,10*FRACUNIT), false)
			mobj.momx = $*3/2
			mobj.momy = $*3/2
			mobj.momz = $*3/2
			mobj.doom.health = 0
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
	if not player.mo then return end
	if player.mo.skin != "dpecbillrizer" then return end
	if player.doom.bill_ogheight == nil then player.doom.bill_ogheight = player.height end
	if player.doom.bill_lives == nil then player.doom.bill_lives = 3 end
	if player.doom.bill_hurtflash then
		player.doom.bill_hurtflash = $ - 1
	end
end)

doom.characterDefs.dpecbillrizer = {
	noHUD = true,

	useDoomMovement = true,
    methods = methods,

	st_damagesteps = 4,
	st_faces = {
		-- Pain offset 0
		"BILL-STFST00", "BILL-STFST01", "BILL-STFST02",
		"BILL-STFKILL0", "BILL-STFKILL0",
		"BILL-STFKILL0",
		"BILL-STFEVL0",
		"BILL-STFKILL0",

		-- Pain offset 1
		"BILL-STFST10", "BILL-STFST11", "BILL-STFST12",
		"BILL-STFKILL0", "BILL-STFKILL0",
		"BILL-STFKILL0",
		"BILL-STFEVL0",
		"BILL-STFKILL0",

		-- Pain offset 2
		"BILL-STFST20", "BILL-STFST21", "BILL-STFST22",
		"BILL-STFKILL0", "BILL-STFKILL0",
		"BILL-STFKILL0",
		"BILL-STFEVL0",
		"BILL-STFKILL0",

		-- Pain offset 3
		"BILL-STFST30", "BILL-STFST31", "BILL-STFST32",
		"BILL-STFKILL0", "BILL-STFKILL0",
		"BILL-STFKILL0",
		"BILL-STFEVL0",
		"BILL-STFKILL0",

		-- God face
		"BILL-STFGOD0",

		-- Dead face
		"BILL-STFDEAD0"
	},

	css = {
		name = "Bill Rizer",
		description = {
			"Burns through hordes with ease",
			"Using less ammo than others",
			"But his low health leaves",
			"No room for mistakes",
			"Once the bullets fly"
		},
		sprite = SPR2_WALK,
		sequence = {A, 6}
	},

	properties = {
		damagefactor = {
			all = FRACUNIT*3,
		},

		movefactor = 2300, -- How fast the player will move in DOOM movement. Default is 2048.
		walkfactor = FRACUNIT*2/3, -- How much of the movefactor the player will use while walking in DOOM movement. Default is FRACUNIT/2.
		mass = 100, -- Player mass. Only relevant for explosion pushback.

		starthealth = 96,
		maxhealth = 96,

		maxarmor = 96,

		armorproperties = { -- DOOMPort behavior makes it so security and combat armors ignore the armor property, which works in our favor for making the armors the blue and red tunics while preventing too much power by way of armor bonuses.
			armorclassmult = 96, -- How much armor each class is worth (green armor is class 1, blue armor is class 2)
			armorclass1prot = FRACUNIT/3, -- Blue tunic protects this much in source game
			armorclass2prot = FRACUNIT/2, -- Red tunic protects this much in source game
		},

		
		startweapon = "bill-rifle",
		startweapons = {
			["bill-rifle"] = true
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