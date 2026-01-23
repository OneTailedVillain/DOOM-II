rawset(_G, "SafeFreeSlot", function(...)
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
end)

SafeFreeSlot("sfx_swtchn", "sfx_swtchx", "sfx_slop", "sfx_noway", "sfx_oof",
"sfx_pistol", "sfx_shotgn", "sfx_rocket", "sfx_secret", "sfx_itmbk",
"MT_TROOPSHOT",
"S_DOOM_IMPFIRE1", "S_DOOM_IMPFIRE2",
"S_DOOM_IMPFIREEXPLODE1", "S_DOOM_IMPFIREEXPLODE2", "S_DOOM_IMPFIREEXPLODE3",
"SPR_BAL1",
"sfx_firsht", "sfx_bgact", "sfx_bgdth1", "sfx_bgdth2", "sfx_bgsit1", "sfx_bgsit2", "sfx_claw",
"sfx_podth1", "sfx_podth2", "sfx_podth3", "sfx_popain", "sfx_posact", "sfx_posit1", "sfx_posit2", "sfx_posit3",
"MT_DOOM_ROCKETPROJ", "sfx_firxpl", "sfx_bossit")

SafeFreeSlot(
"TOL_DOOM",
"MT_DOOM_TELETARGET",
"sfx_firxpl",
"sfx_plasma",
"SPR_PLSS",
"SPR_PLSE",
"SPR_APLS",
"SPR_APBX",
"MT_DOOM_BULLETPUFF"
)

addHook("MobjThinker", function(mobj)
	P_MoveOrigin(mobj, mobj.x, mobj.y, mobj.z+FRACUNIT)
end, MT_DOOM_BULLETPUFF)

G_AddGametype({
    name = "DOOM",
    identifier = "doom",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_CAMPAIGN|GTR_FIRSTPERSON|GTR_FRIENDLYFIRE|GTR_RESPAWNDELAY|GTR_SPAWNENEMIES|GTR_ALLOWEXIT|GTR_NOTITLECARD|GTR_FRIENDLY,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Play the classic DOOM campaign cooperatively with friends using original netplay rules -- works with any DOOM-compatible IWAD/WAD."
})

-- As in "DOOM2.EXE -deathmatch -nomonsters"
G_AddGametype({
    name = "Deathmatch (Original)",
    identifier = "doomdm",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_FIRSTPERSON|GTR_SPECTATORS|GTR_RESPAWNDELAY|GTR_ALLOWEXIT|GTR_NOTITLECARD|GTR_RINGSLINGER,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Classic DOOM deathmatch: competitive free-for-all where pickups do NOT respawn and weapons are grabbable only once per life."
})

-- As in "DOOM2.EXE -altdeath -nomonsters"
G_AddGametype({
    name = "Deathmatch 2.0",
    identifier = "doomdmtwo",
    typeoflevel = TOL_SP|TOL_DOOM,
    rules = GTR_FIRSTPERSON|GTR_SPECTATORS|GTR_RESPAWNDELAY|GTR_ALLOWEXIT|GTR_NOTITLECARD|GTR_RINGSLINGER,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Alternate DOOM deathmatch: competitive free-for-all with delayed item and weapon respawns so pickups return after a short time."
})

mobjinfo[MT_DOOM_TELETARGET] = {
spawnstate = S_INVISIBLE,
spawnhealth = 1000,
doomednum = 14,
deathstate = S_INVISIBLE,
radius = 20*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIP,
}