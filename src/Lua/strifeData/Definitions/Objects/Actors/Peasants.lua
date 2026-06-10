SafeFreeSlot(
	"SPR_PEAS",
	"sfx_rebact"
)

local name = "Peasant1"

local object = {
	health = 31,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 200,
	doomednum = 3004,
	conversationid = 6,
	seesound = sfx_cacsit,
	painsound = sfx_pespna,
	deathsound = sfx_psdtha,
	disintegratesound = sfx_dsrptr,
	burningsound = sfx_burnme,
	sprite = SPR_PEAS,
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
		{action = nil,        frame = O, tics = 3},
		{action = A_DoomPain, frame = O, tics = 3, next = "chase"},
	},
	wound = {
		{action = nil,           frame = G, tics = 5},
		{action = A_DoomGetHurt, frame = H, tics = 10},
		{action = nil,           frame = I, tics = 6, next = "wound"},
	},
	die = {
		{action = nil,          frame = G, tics = 5},
		{action = A_DoomScream, frame = H, tics = 5},
		{action = nil,          frame = I, tics = 6},
		{action = A_DoomFall,   frame = J, tics = 5},
		{action = nil,          frame = K, tics = 5},
		{action = nil,          frame = L, tics = 6},
		{action = nil,          frame = M, tics = 8},
		{action = nil,          frame = N, tics = 1400},
		{action = nil,          frame = U, sprite = SPR_GIBS, tics = 5},
		{action = nil,          frame = V, sprite = SPR_GIBS, tics = 1400},
	},
}

DefineDoomActor(name, object, states)

name = "Peasant2"

object.doomednum = 130
object.conversationid = 7
object.speed = 5

DefineDoomActor(name, object, states)

name = "Peasant3"

object.doomednum = 131
object.conversationid = 8
object.speed = 5

DefineDoomActor(name, object, states)

name = "Peasant4"

object.doomednum = 65
object.conversationid = 9
object.translation = 0
object.speed = 7

DefineDoomActor(name, object, states)

name = "Peasant5"

object.doomednum = 132
object.conversationid = 10

DefineDoomActor(name, object, states)

name = "Peasant6"

object.doomednum = 133
object.conversationid = 11

DefineDoomActor(name, object, states)

name = "Peasant7"

object.doomednum = 66
object.conversationid = 12
object.translation = 2
object.speed = 8

DefineDoomActor(name, object, states)

name = "Peasant8"

object.doomednum = 134
object.conversationid = 13

DefineDoomActor(name, object, states)

name = "Peasant9"

object.doomednum = 135
object.conversationid = 14

DefineDoomActor(name, object, states)

name = "Peasant10"

object.doomednum = 67
object.conversationid = 15
object.translation = 1

DefineDoomActor(name, object, states)

name = "Peasant11"

object.doomednum = 136
object.conversationid = 16
object.translation = 1

DefineDoomActor(name, object, states)

name = "Peasant12"

object.doomednum = 137
object.conversationid = 17

DefineDoomActor(name, object, states)

name = "Peasant13"

object.doomednum = 172
object.conversationid = 18
object.translation = 3

DefineDoomActor(name, object, states)

name = "Peasant14"

object.doomednum = 173
object.conversationid = 19

DefineDoomActor(name, object, states)

name = "Peasant15"

object.doomednum = 174
object.conversationid = 20

DefineDoomActor(name, object, states)

name = "Peasant16"

object.doomednum = 175
object.conversationid = 21
object.translation = 5

DefineDoomActor(name, object, states)

name = "Peasant17"

object.doomednum = 176
object.conversationid = 22

DefineDoomActor(name, object, states)

name = "Peasant18"

object.doomednum = 177
object.conversationid = 23

DefineDoomActor(name, object, states)

name = "Peasant19"

object.doomednum = 178
object.conversationid = 24
object.translation = 4

DefineDoomActor(name, object, states)

name = "Peasant20"

object.doomednum = 179
object.conversationid = 25

DefineDoomActor(name, object, states)

name = "Peasant21"

object.doomednum = 180
object.conversationid = 26

DefineDoomActor(name, object, states)

name = "Peasant22"

object.doomednum = 181
object.conversationid = 27
object.translation = 6

DefineDoomActor(name, object, states)