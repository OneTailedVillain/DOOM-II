DOOM_Freeslot(
"SPR_PNCH"
)

function A_StrifeJabDagger(actor)
	local player = actor.player
	if not player then print("No player") return end

	local damage = 0

	if doom.findInInventory(player, "SVETalismanPowerup") then
		damage = 1000
	else
		local power = min(10, player.doom.strife_stamina / 10)
		damage = (DOOM_Random() % (power + 7)) * (power + 2)

		if player.doom.powers[pw_strength] then
			damage = $ * 10
		end
	end

	print(damage)
	A_DoomFire(actor, 0, {forceDamage = {damage, damage}})
end

doom.addWeapon("punchdagger", {
	sprite = SPR_PNCH,
	weaponslot = 1,
	order = 1,
	priority = 3700,
	damage = {5, 15},
	raycaster = true,
	wimpyweapon = true,
	misssound = sfx_punch,
	hitsound = sfx_punch,
	pellets = 1,
	shotcost = 0,
	carouselicon = "SMFIST",
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
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
			{frame = B, tics = 4},
			{frame = C, tics = 4, action = A_StrifeJabDagger},
			{frame = D, tics = 5},
			{frame = C, tics = 4},
			{frame = B, tics = 5, action = A_DoomReFire},
		},
	},
	ammotype = "none",
})

local function AccuracyFactor(player)
	if player.doom.strife_accuracy == nil then player.doom.strife_accuracy = 0 end
	return FRACUNIT / (1 << (player.doom.strife_accuracy * 5 / 100))
end

freeslot("SPR_XBOW", "sfx_xbow")

function A_StrifeFireArrow(actor, projectileType, var2, weapon)
	local player = actor.player
	if not player then return end

	local pd = player.doom
	if pd.ammo[weapon.ammotype] <= 0 then return end

	local spread = FixedMul(FRACUNIT*45/8, AccuracyFactor(player))

	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	S_StartSound(actor, sfx_xbow)
	local mi = mobjinfo[projectileType]
	DOOM_Fire(actor, INT32_MAX, spread, 0, 1, mi.damage, mi.damage * 4, 10, projectileType)
end

local function DOOM_GetFrameDef(weapon, stateName, frame)
	local def = DOOM_ResolveStateDef(weapon, stateName, frame)
	return def
end

function A_StrifeShowElectricFlash(actor, var1, var2, weapon)
	local player = actor.player
	if not player then return end

	local pd = player.doom
	if not pd then return end


    local psp = pd.psprites and pd.psprites[PSP_FLASH]
    if psp then return end


	local flashDef = DOOM_GetFrameDef(weapon, "flash", 1)
	if not flashDef then return end

	DOOM_SetFlashState(player, "flash")
end

-- MT_STRIFE_ELECTRICBOLT
doom.addWeapon("crossbow", {
	sprite = SPR_XBOW,
	weaponslot = 1,
	order = 3,
	priority = 3700,
	damage = {5, 15},
	raycaster = true,
	pellets = 1,
	shotcost = 1,
	ammotype = "bullets",
	carouselicon = "SMSHOT",
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = A, tics = 0, action = A_StrifeShowElectricFlash},
			{frame = A, tics = 1, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = A, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = A, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{frame = A, tics = 3, action = A_StrifeClearFlash},
			{frame = B, tics = 6, action = A_StrifeFireArrow, var1 = MT_STRIFE_ELECTRICBOLT},
			{frame = C, tics = 4},
			{frame = D, tics = 6},
			{frame = E, tics = 3},
			{frame = F, tics = 5},
			{frame = G, tics = 0, action = A_StrifeShowElectricFlash},
			{frame = G, tics = 5, action = A_DoomCheckReload},
		},
		flash = {
			{frame = K, tics = 5},
			{frame = L, tics = 5},
			{frame = M, tics = 5, goto = "flash"},
		}
	},
})

---@param actor mobj_t
function A_StrifeFireAssaultGun(actor, var1, var2, weapon)
	print("Attempting call")
	local player = actor.player
	if not player then print("No player") return end

	local pd = player.doom
	if pd.ammo[weapon.ammotype] <= 0 then return end

	local spread = 0

	if pd.refire then
		spread = FixedMul(FRACUNIT*45/2, AccuracyFactor(player))
	end
	DOOM_Fire(actor, MISSILERANGE, spread, 0, 1, 3, 12)
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	S_StartSound(actor, sfx_rifle)
	A_DoomGunFlash(actor)
end

DOOM_Freeslot("SPR_RIFG", "SPR_RIFF", "sfx_rifle")

doom.addWeapon("assaultgun", {
	sprite = SPR_RIFG,
	weaponslot = 1,
	order = 3,
	priority = 3700,
	damage = {5, 15},
	raycaster = true,
	pellets = 1,
	shotcost = 1,
	ammotype = "bullets",
	carouselicon = "SMMGUN",
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	states = {
		idle = {
			{frame = A, tics = 1, action = A_DoomWeaponReady},
		},
		lower = {
			{frame = B, tics = 1, action = A_DoomLower}
		},
		raise = {
			{frame = A, tics = 1, action = A_DoomRaise}
		},
		attack = {
			{sprite = SPR_RIFF, frame = A, tics = 3, action = A_StrifeFireAssaultGun},
			{sprite = SPR_RIFF, frame = B, tics = 3, action = A_StrifeFireAssaultGun},
			{frame = D, tics = 3, action = A_StrifeFireAssaultGun},
			{frame = C, tics = 0, action = A_DoomReFire},
			{frame = B, tics = 2, action = A_DoomLight0},
		},
	},
})