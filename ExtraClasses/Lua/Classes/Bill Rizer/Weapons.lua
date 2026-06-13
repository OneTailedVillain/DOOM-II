SafeFreeSlot(
	"SPR_BILL_RIFLE"
)

doom.addWeapon("bill-rifle", {
	sprite = SPR_BILL_RIFLE,
	weaponslot = 1,
	order = 10,
	priority = 1900,
	damage = {8, 16},
	noinitfirespread = true,
	pellets = 1,
	firesound = sfx_pistol,
	shotcost = 0,
	spread = {
		horiz = FRACUNIT*59/10,
		vert = 0,
	},
	carouselicon = "SMFSWD",
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
			{frame = 1, tics = 2, action = A_DoomFirePistol},
			{frame = 2, tics = 2},
			{frame = 0, tics = 0, action = A_DoomReFire}
		}
	},
	ammotype = "none",
})