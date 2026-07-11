SafeFreeSlot(
    "SPR_BFS1","SPR_BFE1",
    "MT_DOOM_BFGBALL",
	"sfx_rxplod"
)

local plasmastates = {
    shot = {
        {sprite = SPR_BFS1, frame = A|FF_FULLBRIGHT, tics = 4},
        {sprite = SPR_BFS1, frame = B|FF_FULLBRIGHT, tics = 4, next = "shot"},
    },

    explode = {
        {sprite = SPR_BFE1, frame = A|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BFE1, frame = B|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BFE1, frame = C|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BFE1, frame = D|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BFE1, frame = E|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_BFE1, frame = F|FF_FULLBRIGHT, tics = 8},
    },
}

local states = FreeDoomStates("BFGBall", plasmastates)

mobjinfo[MT_DOOM_BFGBALL] = {
    spawnstate = states.shot[1],
    --seesound   = sfx_firsht,
    deathsound = sfx_rxplod,
    deathstate = states.explode[1],

    speed      = 25*FRACUNIT,
    radius     = 13*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 100,

    flags = MF_NOGRAVITY|MF_MISSILE,
}

mobjinfo[MT_DOOM_ARCHNOTRONPLASMA].doomname = "BFGBall"