SafeFreeSlot(
	"SPR_LEDR",
	"SPR_LEAD",
	"sfx_rebact"
)

local name = "Macil1"

local object = {
	health = 95,
	radius = 20,
	height = 56,
	mass = 100,
	speed = 8,
	painchance = 250,
	doomednum = 64,
	conversationid = {49, 48, 49},
	seesound = sfx_cacsit,
	painsound = sfx_pespna,
	deathsound = sfx_psdtha,
	disintegratesound = sfx_dsrptr,
	burningsound = sfx_burnme,
	sprite = SPR_LEDR,
}

local states = {
	stand = {
		{action = A_DoomLook2, frame = C, tics = 5, next = "stand", nextframe = 1},
		{action = nil,         frame = A, tics = 8, next = "stand", nextframe = 2},
		{action = nil,         frame = B, tics = 8, next = "stand", nextframe = 3},
		{action = nil,         frame = A, tics = 6, next = "stand", nextframe = 4}
	},
	chase = {
		{sprite = SPR_LEAD, action = A_DoomChase, frame = A, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = A, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = B, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = B, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = C, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = C, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = D, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomChase, frame = D, tics = 3, next = "chase"},
	},
	missile = {
		{sprite = SPR_LEAD, action = A_DoomFaceTarget, frame = E, tics = 2},
		{sprite = SPR_LEAD, action = A_DoomFire,       frame = F|FF_FULLBRIGHT, tics = 2, var2 = 1},
		{sprite = SPR_LEAD, action = A_CPosRefire,     frame = E, tics = 1, next = "missile"},
	},
	pain = {
		{sprite = SPR_LEAD, action = nil,        frame = Y, tics = 3},
		{sprite = SPR_LEAD, action = A_DoomPain, frame = Y, tics = 3, next = "chase"},
	},
	die = {
		{sprite = SPR_LEAD, action = A_DoomFaceTarget, frame = E, tics = 2},
		{sprite = SPR_LEAD, action = A_DoomFire,       frame = F|FF_FULLBRIGHT, tics = 2, var2 = 1},
		{sprite = SPR_LEAD, action = A_CPosRefire,     frame = E, tics = 1, next = "missile"},
	},
}

DefineDoomActor(name, object, states)

name = "Macil2"

object.doomednum = 200
object.conversationid = {50, 49, 50}
object.deathsound = sfx_slop

states.missile = {
	{sprite = SPR_LEAD, action = A_DoomFaceTarget, frame = E, tics = 4},
	{sprite = SPR_LEAD, action = A_DoomFire,       frame = F|FF_FULLBRIGHT, tics = 4, var2 = 1},
	{sprite = SPR_LEAD, action = A_CPosRefire,     frame = E, tics = 2, next = "missile"},
}

states.die = {
	{sprite = SPR_LEAD, action = nil,          frame = G, tics = 5},
	{sprite = SPR_LEAD, action = A_DoomScream, frame = H, tics = 5},
	{sprite = SPR_LEAD, action = nil,          frame = I, tics = 4},
	{sprite = SPR_LEAD, action = nil,          frame = J, tics = 4},
	{sprite = SPR_LEAD, action = nil,          frame = K, tics = 3},
	{sprite = SPR_LEAD, action = A_DoomFall,   frame = L, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = M, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = N, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = O, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = P, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = Q, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = R, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = S, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = T, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = U, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = V, tics = 3},
	{sprite = SPR_LEAD, action = nil,          frame = W, tics = 3}, -- A_SpawnItemEx("AlienSpectre4", 0, 0, 0, 0, 0, random[spectrespawn](0, 255)*0.0078125, 0, SXF_NOCHECKPOSITION)
	{sprite = SPR_LEAD, action = nil,          frame = X, tics = -1},
}

DefineDoomActor(name, object, states)