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
"sfx_pistol", "sfx_shotgn", "sfx_secret", "sfx_itmbk",
"MT_TROOPSHOT", "S_DOOM_IMPFIRE", "SPR_BAL1", "sfx_firsht", "sfx_bgact", "sfx_bgdth1", "sfx_bgdth2", "sfx_bgsit1", "sfx_bgsit2", "sfx_claw",
"sfx_podth1", "sfx_podth2", "sfx_podth3", "sfx_popain", "sfx_posact", "sfx_posit1", "sfx_posit2", "sfx_posit3", "MT_DOOM_TELEFOG", "SPR_TFOG", "sfx_telept",
"MT_DOOM_ROCKETPROJ", "sfx_firxpl", "S_DOOM_IMPEXPLODE1", "sfx_bossit")

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
	flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}

addHook("MobjThinker", function(mobj)
	P_MoveOrigin(mobj, mobj.x, mobj.y, mobj.z+FRACUNIT)
end, MT_DOOM_BULLETPUFF)

/*
gtdesc_t gametypedesc[NUMGAMETYPES] =
{
	{{ 54,  54}, "Play through the single-player campaign with your friends, teaming up to beat Dr Eggman's nefarious challenges!"},
	{{103, 103}, "Speed your way through the main acts, competing in several different categories to see who's the best."},
	{{190, 190}, "There's not much to it - zoom through the level faster than everyone else."},
	{{ 66,  66}, "Sling rings at your foes in a free-for-all battle. Use the special weapon rings to your advantage!"},
	{{153,  37}, "Sling rings at your foes in a color-coded battle. Use the special weapon rings to your advantage!"},
	{{123, 123}, "Whoever's IT has to hunt down everyone else. If you get caught, you have to turn on your former friends!"},
	{{150, 150}, "Try and find a good hiding place in these maps - we dare you."},
	{{ 37, 153}, "Steal the flag from the enemy's base and bring it back to your own, but watch out - they could just as easily steal yours!"},
};
*/

G_AddGametype({
    name = "DOOM",
    identifier = "doom",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_CAMPAIGN|GTR_FIRSTPERSON|GTR_FRIENDLYFIRE|GTR_RESPAWNDELAY|GTR_SPAWNENEMIES|GTR_ALLOWEXIT|GTR_NOTITLECARD,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Play the classic DOOM campaign cooperatively with friends using original netplay rules -- works with any DOOM-compatible IWAD/WAD."
})

-- As in "DOOM2.EXE -deathmatch -nomonsters"
G_AddGametype({
    name = "Deathmatch (Original)",
    identifier = "doomdm",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_FIRSTPERSON|GTR_FRIENDLYFIRE|GTR_RESPAWNDELAY|GTR_ALLOWEXIT|GTR_NOTITLECARD|GTR_RINGSLINGER,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Classic DOOM deathmatch: competitive free-for-all where pickups do NOT respawn and weapons are grabbable only once per life."
})

-- As in "DOOM2.EXE -altdeath -nomonsters"
G_AddGametype({
    name = "Deathmatch 2.0",
    identifier = "doomdmtwo",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_FIRSTPERSON|GTR_FRIENDLYFIRE|GTR_RESPAWNDELAY|GTR_ALLOWEXIT|GTR_NOTITLECARD|GTR_RINGSLINGER,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Alternate DOOM deathmatch: competitive free-for-all with delayed item and weapon respawns so pickups return after a short time."
})

local function BulletHitObject(tmthing, thing)
    if tmthing.hitenemy then return false end
    if tmthing.target == thing then return false end
	if not (thing.flags & MF_SHOOTABLE) then return false end

	local damageVal = mobjinfo[tmthing.type].damage
	local damage = (DOOM_Random() % 8 + 1) * damageVal

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
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}

mobjinfo[MT_DOOM_TELETARGET] = {
spawnstate = S_PLAY_STND,
spawnhealth = 1000,
doomednum = 14,
deathstate = S_PLAY_STND,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}