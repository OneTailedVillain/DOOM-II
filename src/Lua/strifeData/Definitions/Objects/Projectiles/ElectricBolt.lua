SafeFreeSlot(
    "SPR_AROW",
	"SPR_ZAP1",
	"MT_STRIFE_ELECTRICBOLT",
	"sfx_swish",
	"sfx_firxpl"
)

local plasmastates = {
    shot = {
        {sprite = SPR_AROW, frame = B|FF_FULLBRIGHT, tics = 10, action = A_LoopActiveSound, next = "shot"},
    },
	explode = {
        {sprite = SPR_ZAP1, frame = A, tics = 3, action = A_DoomAlertMonsters},
        {sprite = SPR_ZAP1, frame = B, tics = 3},
        {sprite = SPR_ZAP1, frame = C, tics = 3},
        {sprite = SPR_ZAP1, frame = D, tics = 3},
        {sprite = SPR_ZAP1, frame = E, tics = 3},
        {sprite = SPR_ZAP1, frame = F, tics = 3},
        {sprite = SPR_ZAP1, frame = E, tics = 3},
        {sprite = SPR_ZAP1, frame = D, tics = 2},
        {sprite = SPR_ZAP1, frame = C, tics = 2},
        {sprite = SPR_ZAP1, frame = B, tics = 2},
        {sprite = SPR_ZAP1, frame = A, tics = 1},
	}
}

local states = FreeDoomStates("ElectricBolt", plasmastates)

mobjinfo[MT_STRIFE_ELECTRICBOLT] = {
    spawnstate = states.shot[1],
    seesound   = sfx_swish,
	activesound = sfx_swish,
    deathsound = sfx_firxpl,
    deathstate = states.explode[1],

    speed      = 25*FRACUNIT,
    radius     = 13*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 100,

    flags = MF_NOGRAVITY|MF_MISSILE|MF_NOBLOCKMAP,
}

mobjinfo[MT_STRIFE_ELECTRICBOLT].doomname = "ElectricBolt"