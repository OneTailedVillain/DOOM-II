SafeFreeSlot(
	"SPR_HMN1",
	"SPR_RGIB",
	"sfx_rebact",
	"sfx_pespna",
	"sfx_pespnb",
	"sfx_pespnc",
	"sfx_pespnd",
	"sfx_rebdth"
)

local name = "Rebel1"

local object = {
	health = 60,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 250,
	doomednum = 9,
	conversationid = {43, 42, 43},
	dropitem = MT_DOOM_CLIPOFBULLETS,
	seesound = sfx_cacsit,
	painsound = sfx_pespna,
	deathsound = sfx_rebdth,
	disintegratesound = sfx_dsrptr,
	burningsound = sfx_burnme,
	sprite = SPR_HMN1,
	doomflags = DF_FRIENDLY
}

local states = {
	stand = {
		{action = A_DoomLook2, frame = P, tics = 5, next = "stand"}
	},
	idleanim1 = {
		{action = nil, frame = Q, tics = 8, next = "stand"}
	},
	idleanim2 = {
		{action = nil, frame = R, tics = 8, next = "stand"}
	},
	idleanim3 = {
		{action = A_DoomWander, frame = A, tics = 6},
		{action = A_DoomWander, frame = B, tics = 6},
		{action = A_DoomWander, frame = C, tics = 6},
		{action = A_DoomWander, frame = D, tics = 6, next = "stand"},
	},
	chase = {
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = A, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = B, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = C, tics = 3},
		{action = A_DoomChase, frame = D, tics = 3},
		{action = A_DoomChase, frame = D, tics = 3, next = "chase"},
	},
	missile = {
		{action = A_FaceTarget, frame = E,               tics = 10,      var2 = 1},
		{action = A_DoomFire,   frame = F|FF_FULLBRIGHT, tics = 3,       var2 = 1},
		{action = A_DoomFire,   frame = E, tics = 3,     next = "chase", var2 = 1},
	},
	pain = {
		{action = nil,        frame = O, tics = 3},
		{action = A_DoomPain, frame = O, tics = 3, next = "chase"},
	},
	die = {
		{action = nil,          frame = G, tics = 5},
		{action = A_DoomScream, frame = H, tics = 5},
		{action = nil,          frame = I, tics = 3},
		{action = A_DoomFall,   frame = J, tics = 4},
		{action = nil,          frame = K, tics = 3},
		{action = nil,          frame = L, tics = 3},
		{action = nil,          frame = M, tics = 3},
		{action = nil,          frame = N, tics = -1},
	},
	gib = {
		{sprite = SPR_RGIB, action = A_DoomTossGib, frame = A, tics = 4},
		{sprite = SPR_RGIB, action = A_DoomXScream, frame = B, tics = 4},
		{sprite = SPR_RGIB, action = A_DoomFall,    frame = C, tics = 3},
		{sprite = SPR_RGIB, action = A_DoomTossGib, frame = D, tics = 3},
		{sprite = SPR_RGIB, action = nil,           frame = E, tics = 3},
		{sprite = SPR_RGIB, action = nil,           frame = F, tics = 3},
		{sprite = SPR_RGIB, action = nil,           frame = G, tics = 3},
		{sprite = SPR_RGIB, action = nil,           frame = H, tics = 1400},
	},
}

DefineDoomActor(name, object, states)

name = "Rebel2"

object.doomednum = 144
object.conversationid = {44, 43, 44}
object.dropitem = nil

DefineDoomActor(name, object, states)

name = "Rebel3"

object.doomednum = 145
object.conversationid = {45, 44, 45}
object.dropitem = nil

DefineDoomActor(name, object, states)

name = "Rebel4"

object.doomednum = 149
object.conversationid = {46, 45, 46}
object.dropitem = nil

DefineDoomActor(name, object, states)

name = "Rebel5"

object.doomednum = 150
object.conversationid = {47, 46, 47}
object.dropitem = nil

DefineDoomActor(name, object, states)

name = "Rebel6"

object.doomednum = 151
object.conversationid = {48, 47, 48}
object.dropitem = nil

DefineDoomActor(name, object, states)