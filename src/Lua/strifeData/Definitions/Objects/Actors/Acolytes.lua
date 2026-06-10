SafeFreeSlot(
	"SPR_AGRD",
	"sfx_agrsee",
	"sfx_agrac1", "sfx_agrac2", "sfx_agrac3", "sfx_agrac4",
	"sfx_agrdpn",
	"sfx_agrdth"
)

local name = "AcolyteGold"

local object = {
	health = 70,
	radius = 24,
	height = 64,
	mass = 400,
	speed = 7,
	painchance = 150,
	doomednum = 148,
	conversationid = {58, 57, 58},
	translation = 4,
	seesound = sfx_agrsee,
	activesound = sfx_agrac1,
	painsound = sfx_agrdpn,
	deathsound = sfx_agrdth,
	disintegratesound = sfx_dsrptr,
	burningsound = sfx_burnme,
	sprite = SPR_AGRD,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = A_DoomTurretLook, frame = A, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 6},
		{action = A_DoomChase, frame = B, tics = 6},
		{action = A_DoomChase, frame = C, tics = 6},
		{action = A_DoomChase, frame = D, tics = 6, next = "chase"},
	},
	attack = {
		{action = A_DoomFaceTarget, frame = E, tics = 8},
		{action = A_DoomFire,       frame = F, tics = 4, var2 = 1},
		{action = A_DoomFire,       frame = E, tics = 4, var2 = 1},
		{action = A_DoomFire,       frame = F, tics = 6, var2 = 1, next = "chase"},
	},
	pain = {
		{action = nil, frame = E, tics = 3},
		{action = A_DoomPain, frame = E, tics = 3},
		{action = nil, frame = F, tics = 3, next = "chase"},
	},
	die = {
		{action = nil,          frame = G, tics = 4},
		{action = A_DoomScream, frame = H, tics = 4},
		{action = nil,          frame = I, tics = 4},
		{action = A_DoomFall,   frame = J, tics = 4},
		{action = nil,          frame = K, tics = 4},
		{action = nil,          frame = L, tics = 4},
		{action = nil,          frame = M, tics = 4},
		{action = nil,          frame = N, tics = -1},
	},
}

DefineDoomActor(name, object, states)

name = "AcolyteTan"
object.doomednum = 3002
object.translation = nil
object.conversationid = {53, 52, 53}
DefineDoomActor(name, object, states)

name = "AcolyteDGreen"
object.doomednum = 147
object.translation = 3
object.conversationid = {57, 56, 57}
DefineDoomActor(name, object, states)

name = "AcolyteGray"
object.doomednum = 146
object.translation = 2
object.conversationid = {56, 55, 56}
DefineDoomActor(name, object, states)

name = "AcolyteRed"
object.doomednum = 142
object.translation = 0
object.conversationid = {54, 53, 54}
DefineDoomActor(name, object, states)

name = "AcolyteRust"
object.doomednum = 143
object.translation = 1
object.conversationid = {55, 54, 55}
DefineDoomActor(name, object, states)

name = "AcolyteBlue"
object.doomednum = 231
object.health = 60
object.translation = 6
object.conversationid = 60
DefineDoomActor(name, object, states)

name = "AcolyteLGreen"
object.doomednum = 232
object.translation = 5
object.conversationid = 59
DefineDoomActor(name, object, states)

name = "AcolyteShadow"
object.doomednum = 58
object.translation = nil
object.conversationid = {61, 58, 59}
object.health = 70

states.chase = {
	{action = A_StrifeBeShadowyFoe, frame = A, tics = 6},
	{action = A_DoomChase, frame = A, tics = 6},
	{action = A_DoomChase, frame = B, tics = 6},
	{action = A_DoomChase, frame = C, tics = 6},
	{action = A_DoomChase, frame = D, tics = 6, next = "chase", nextframe = 3},
}

states.pain = {
	{action = A_StrifeSetShadow, frame = O, tics = 0},
	{action = A_DoomPain, frame = O, tics = 6, next = "chase"},
}

DefineDoomActor(name, object, states)