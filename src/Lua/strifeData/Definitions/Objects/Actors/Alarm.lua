SafeFreeSlot(
	"SPR_KLAX", "sfx_alarm"
)

local name = "Alarm"

local object = {
	health = 20,
	radius = 5,
	height = 10,
	mass = 100,
	speed = 8,
	painchance = 128,
	doomednum = 24,
	conversationid = 121,
	sprite = SPR_KLAX,
	doomflags = DF_COUNTKILL,
	flags = MF_NOGRAVITY|MF_SPAWNCEILING
}

function A_DoomKlaxonBlare(actor)
	S_StartSound(actor, sfx_alarm)
end

local states = {
	stand = {
		{action = A_DoomTurretLook, frame = A, tics = 5, next = "stand"}
	},
	chase = {
		{action = A_DoomKlaxonBlare, frame = B, tics = 6},
		{action = nil,               frame = C, tics = 60, next = "chase"},
	},
}

DefineDoomActor(name, object, states)