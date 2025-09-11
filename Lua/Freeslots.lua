local function SafeFreeSlot(...)
    local ret = {}
    for _, name in ipairs({...}) do
        -- If already freed, just use the existing slot
        if rawget(_G, name) ~= nil then
            ret[name] = _G[name]
        else
            -- Otherwise, safely freeslot it and return the value
            ret[name] = freeslot(name)
        end
    end
    return ret
end

SafeFreeSlot("sfx_swtchn", "sfx_swtchx", "sfx_slop", "sfx_noway", "sfx_oof",
"sfx_pistol", "sfx_shotgn", "sfx_secret",
"MT_TROOPSHOT", "S_DOOM_IMPFIRE", "SPR_BAL1", "sfx_firsht", "sfx_bgact", "sfx_bgdth1", "sfx_bgdth2", "sfx_bgsit1", "sfx_bgsit2", "sfx_claw",
"sfx_podth1", "sfx_podth2", "sfx_podth3", "sfx_popain", "sfx_posact", "sfx_posit1", "sfx_posit2", "sfx_posit3", "MT_DOOM_TELEFOG", "SPR_TFOG", "sfx_telept")

SafeFreeSlot(
"S_TELEFOG1",
"S_TELEFOG2",
"S_TELEFOG3",
"S_TELEFOG4",
"S_TELEFOG5",
"S_TELEFOG6",
"S_TELEFOG7",
"S_TELEFOG8",
"S_TELEFOG9",
"S_TELEFOG10",
"S_TELEFOG11",
"S_TELEFOG12",
"TOL_DOOM",
"MT_DOOM_TELETARGET",
"MT_DOOM_BULLETPUFF",
"S_DOOM_PUFF1",
"S_DOOM_PUFF2",
"S_DOOM_PUFF3",
"S_DOOM_PUFF4",
"S_DOOM_BLOOD1",
"S_DOOM_BLOOD2",
"S_DOOM_BLOOD3",
"S_DOOM_BLOOD4",
"SPR_PUFF"
)

states[S_DOOM_PUFF1] = {
    sprite = SPR_PUFF,
    frame = A,
    tics = 4,
    nextstate = S_DOOM_PUFF2
}

states[S_DOOM_PUFF2] = {
    sprite = SPR_PUFF,
    frame = B,
    tics = 4,
    nextstate = S_DOOM_PUFF3
}

states[S_DOOM_PUFF3] = {
    sprite = SPR_PUFF,
    frame = C,
    tics = 4,
    nextstate = S_DOOM_PUFF4
}

states[S_DOOM_PUFF4] = {
    sprite = SPR_PUFF,
    frame = D,
    tics = 4,
    nextstate = S_NULL
}

states[S_DOOM_BLOOD1] = {
    sprite = SPR_BLUD,
    frame = A,
    tics = 4,
    nextstate = S_DOOM_BLOOD2
}

states[S_DOOM_BLOOD2] = {
    sprite = SPR_BLUD,
    frame = B,
    tics = 4,
    nextstate = S_DOOM_BLOOD3
}

states[S_DOOM_BLOOD3] = {
    sprite = SPR_BLUD,
    frame = C,
    tics = 4,
    nextstate = S_DOOM_BLOOD4
}

states[S_DOOM_BLOOD4] = {
    sprite = SPR_BLUD,
    frame = D,
    tics = 4,
    nextstate = S_NULL
}

mobjinfo[MT_DOOM_BULLETPUFF] = {
	spawnstate = S_DOOM_PUFF1,
	spawnhealth = 1000,
	deathstate = S_NULL,
	radius = 1*FRACUNIT,
	height = 1*FRACUNIT,
	dispoffset = 5,
	flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP,
}

addHook("MobjThinker", function(mobj)
	P_MoveOrigin(mobj, mobj.x, mobj.y, mobj.z+FRACUNIT)
end, MT_DOOM_BULLETPUFF)

G_AddGametype({
    name = "DOOM",
    identifier = "doom",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_CAMPAIGN|GTR_FIRSTPERSON|GTR_FRIENDLYFIRE|GTR_RESPAWNDELAY|GTR_SPAWNENEMIES|GTR_ALLOWEXIT|GTR_NOTITLECARD,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Ouggggghhhh I'm dooming it. I'm dooming it so good."
})

-- Idak how DOOM does this so this is the closest you'll get from me
local hardcodedDamageVals = {
	[MT_TROOPSHOT] = {3, 24}
}

local function BulletHitObject(tmthing, thing)
	-- print("Collision!")
    if tmthing.hitenemy then return false end
	-- print(tmthing.target, thing, tmthing.target == thing, thing.type != MT_METALSONIC_BATTLE)
    if tmthing.target == thing then return false end
	-- print(thing.type, thing.type == MT_METALSONIC_BATTLE)
	if not (thing.flags & MF_SHOOTABLE) then return false end

	local damageVals = hardcodedDamageVals[tmthing.type]
	local damage = (DOOM_Random() % (damageVals[2] / damageVals[1]) + 1) * damageVals[1]

	tmthing.hitenemy = true
    DOOM_DamageMobj(thing, tmthing, tmthing.target, damage, damagetype)
	P_KillMobj(tmthing)
	return false
end

local projectiles = {
	MT_TROOPSHOT,
}

for _, mt in ipairs(projectiles) do
    addHook("MobjMoveCollide", BulletHitObject, mt)
end

states[S_TELEFOG1] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|A,
    tics = 6,
	action = A_PlaySound,
	var1 = sfx_telept,
	var2 = 1,
    nextstate = S_TELEFOG2
}

states[S_TELEFOG2] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|B,
    tics = 6,
    nextstate = S_TELEFOG3
}

states[S_TELEFOG3] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|A,
    tics = 6,
    nextstate = S_TELEFOG4
}

states[S_TELEFOG4] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|B,
    tics = 6,
    nextstate = S_TELEFOG5
}

states[S_TELEFOG5] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|C,
    tics = 6,
    nextstate = S_TELEFOG6
}

states[S_TELEFOG6] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|D,
    tics = 6,
    nextstate = S_TELEFOG7
}

states[S_TELEFOG7] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|E,
    tics = 6,
    nextstate = S_TELEFOG8
}

states[S_TELEFOG8] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|F,
    tics = 6,
    nextstate = S_TELEFOG9
}

states[S_TELEFOG9] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|G,
    tics = 6,
    nextstate = S_TELEFOG10
}

states[S_TELEFOG10] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|H,
    tics = 6,
    nextstate = S_TELEFOG11
}

states[S_TELEFOG11] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|I,
    tics = 6,
    nextstate = S_TELEFOG12
}

states[S_TELEFOG12] = {
    sprite = SPR_TFOG,
    frame = FF_FULLBRIGHT|J,
    tics = 6,
    nextstate = S_NULL
}

mobjinfo[MT_DOOM_TELEFOG] = {
spawnstate = S_TELEFOG1,
spawnhealth = 1000,
deathstate = S_TELEFOG1,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP,
}

mobjinfo[MT_DOOM_TELETARGET] = {
spawnstate = S_PLAY_STND,
spawnhealth = 1000,
doomednum = 14,
deathstate = S_PLAY_STND,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP,
}