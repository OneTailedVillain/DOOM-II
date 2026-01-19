SafeFreeSlot("SPR2_DYIN", "SPR2_FLSH", "SPR2_GIBN", "SPR2_GIBD")

local playerstates = {
	stand = {
		{sprite = SPR_PLAY, frame = SPR2_STND, tics = -1},
	},
	move = {
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4},
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4},
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4},
		{sprite = SPR_PLAY, frame = SPR2_WALK, tics = 4, next = "move"},
	},
	attack = {
		{sprite = SPR_PLAY, frame = SPR2_FIRE, tics = 12, next = "stand"},
	},
	flash = {
		{sprite = SPR_PLAY, frame = SPR2_FLSH|FF_FULLBRIGHT, tics = 6, next = "attack"},
	},
	pain = {
		{sprite = SPR_PLAY, frame = SPR2_PAIN, tics = 6},
		{sprite = SPR_PLAY, frame = SPR2_PAIN, tics = 6, action = A_DoomPain, next = "stand"},
	},
	die = {
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10, action = A_DoomPlayerScream},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10, action = A_DoomFall},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DYIN, tics = 10},
		{sprite = SPR_PLAY, frame = SPR2_DEAD, tics = -1},
	},
	gib = {
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5, A_DoomXScream},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5, A_DoomFall},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBN, tics = 5},
		{sprite = SPR_PLAY, frame = SPR2_GIBD, tics = -1},
	},
}

local freedSprites = FreeDoomStates("Player", playerstates)