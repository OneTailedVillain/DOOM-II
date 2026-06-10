SafeFreeSlot(
	"SPR_BEGR",
	"sfx_pespna", "sfx_pespnb", "sfx_pespnc", "sfx_pespnd",
	"sfx_psdtha"
)

local name = "Beggar1"

local object = {
	health = 20,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 128,
	doomednum = 141,
	conversationid = {38, 37, 38},
	seesound = sfx_cacsit,
	painsound = sfx_pespna,
	deathsound = sfx_psdtha,
	disintegratesound = sfx_dsrptr,
	burningsound = sfx_burnme,
	sprite = SPR_BEGR,
	doomflags = DF_COUNTKILL
}

local states = {
	stand = {
		{action = nil, frame = A, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 3, next = "chase"},
	},
	attack = {
		{action = A_DoomFaceTarget, frame = B, tics = 8},
		{action = A_DoomFaceTarget, frame = C, tics = 8},
		{action = A_DoomHeadAttack, frame = D|FF_FULLBRIGHT, tics = 6, next = "chase"},
	},
	pain = {
		{action = nil, frame = E, tics = 3},
		{action = A_DoomPain, frame = E, tics = 3},
		{action = nil, frame = F, tics = 3, next = "chase"},
	},
	die = {
		{action = nil,          frame = F, tics = 4},
		{action = A_DoomScream, frame = G, tics = 4},
		{action = nil,          frame = H, tics = 4},
		{action = A_DoomFall,   frame = I, tics = 4},
		{action = nil,          frame = J, tics = 4},
		{action = nil,          frame = K, tics = 4},
		{action = nil,          frame = L, tics = 4},
		{action = nil,          frame = M, tics = 4},
		{action = nil,          frame = N, tics = -1},
	},
}

DefineDoomActor(name, object, states)

name = "Beggar2"
object.doomednum = 155
object.conversationid = {39, 38, 39}

DefineDoomActor(name, object, states)

name = "Beggar3"
object.doomednum = 156
object.conversationid = {40, 39, 40}

DefineDoomActor(name, object, states)

name = "Beggar4"
object.doomednum = 157
object.conversationid = {41, 40, 41}

DefineDoomActor(name, object, states)

name = "Beggar5"
object.doomednum = 158
object.conversationid = {42, 41, 42}

DefineDoomActor(name, object, states)