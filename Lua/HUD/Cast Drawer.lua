local SKIN_DOOM = "johndoom"

local function F_CastPrint(v, text)
    text = DOOM_ResolveString(text)
    drawInFont(v, 160*FRACUNIT, 180*FRACUNIT, FRACUNIT,
        "STCFN", text, 0, "center")
end

local castorder = {
    {name = "$CC_ZOMBIE", type = MT_DOOM_ZOMBIEMAN},
    {name = "$CC_SHOTGUN", type = MT_DOOM_SHOTGUNNER},
    {name = "$CC_HEAVY", type = MT_DOOM_CHAINGUNNER},
    {name = "$CC_IMP", type = MT_DOOM_IMP},
    {name = "$CC_DEMON", type = MT_DOOM_DEMON},
    {name = "$CC_LOST", type = MT_DOOM_LOSTSOUL},
    {name = "$CC_CACO", type = MT_DOOM_CACODEMON},
    {name = "$CC_HELL", type = MT_DOOM_HELLKNIGHT},
    {name = "$CC_BARON", type = MT_DOOM_BARONOFHELL},
    {name = "$CC_ARACH", type = MT_DOOM_ARACHNOTRON},
	/*
    {name = "$CC_PAIN", type = MT_DOOM_PAINELEMENTAL},
	*/
    {name = "$CC_REVEN", type = MT_DOOM_REVENANT},
    {name = "$CC_MANCU", type = MT_DOOM_MANCUBUS},
	/*
    {name = "$CC_ARCH", type = MT_DOOM_ARCHVILE},
	*/
    {name = "$CC_SPIDER", type = MT_DOOM_SPIDERMASTERMIND},
    {name = "$CC_CYBER", type = MT_DOOM_CYBERDEMON},
    {name = "$CC_HERO", type = MT_PLAYER},
}

local castnum = 1
local caststate
local casttics = 0
local castdeath = false
local castframes = 0
local castonmelee = 0
local castattacking = false

local cast_use_sprite2 = false
local cast_sprite = nil
local cast_frame = 0
local cast_sprite2 = nil
local cast_sprite2frame = 0

local function updateCastSpriteVars()
    if not caststate then
        cast_use_sprite2 = false
        cast_sprite = nil
        cast_frame = 0
        cast_sprite2 = nil
        cast_sprite2frame = 0
        return
    end

    local typ = castorder[castnum].type
    local rawframe = caststate.frame or 0
    local masked_frame = rawframe & FF_FRAMEMASK

    if typ == MT_PLAYER then
        cast_use_sprite2 = true
        cast_sprite = caststate.sprite or SPR_PLAY
        -- detect if sprite2 changed
        if cast_sprite2 ~= masked_frame then
            cast_sprite2 = masked_frame -- new SPR2_ constant
            cast_sprite2frame = 0     -- reset frame index on new sprite2
		else
			cast_sprite2frame = $ + 1
        end
    else
        cast_use_sprite2 = false
        cast_sprite = caststate.sprite
        cast_frame = masked_frame
        cast_sprite2 = nil
        cast_sprite2frame = 0
    end
end

rawset(_G, "F_StartCast", function()
    castnum = 1
    local t = castorder[castnum].type
    caststate = states[mobjinfo[t].seestate]
	if mobjinfo[t].seesound then
		S_StartSound(nil, mobjinfo[t].seesound)
	end
    casttics = caststate.tics
    castdeath = false
    castframes = 0
    castonmelee = 0
    castattacking = false
end)

local function CastSoundHack(st)
	local sfx = nil

	-- PLAYER shotgun
	if st == S_DOOM_PLAYER_ATTACK1 then
		sfx = sfx_dshtgn

	-- Zombieman pistol
	elseif st == S_DOOM_ZOMBIEMAN_MISSILE2 then
		sfx = sfx_pistol

	-- Shotgun guy
	elseif st == S_DOOM_SHOTGUNNER_MISSILE2 then
		sfx = sfx_shotgn
/*
	-- Archvile
	elseif st == S_DOOM_ARCHVILE_MISSILE2 then
		sfx = sfx_vilatk
*/
	-- Revenant melee / missile
	elseif st == S_DOOM_REVENANT_MELEE2 then
		sfx = sfx_skeswg
	elseif st == S_DOOM_REVENANT_MELEE4 then
		sfx = sfx_skepch
	elseif st == S_DOOM_REVENANT_MISSILE2 then
		sfx = sfx_skeatk

	-- Mancubus triple fire
	elseif st == S_DOOM_MANCUBUS_MISSILE2
	   or st == S_DOOM_MANCUBUS_MISSILE5
	   or st == S_DOOM_MANCUBUS_MISSILE8 then
		sfx = sfx_firsht

	-- Chaingunner burst
	elseif st == S_DOOM_CHAINGUNNER_MISSILE2
	   or st == S_DOOM_CHAINGUNNER_MISSILE3
	   or st == S_DOOM_CHAINGUNNER_MISSILE4 then
		sfx = sfx_shotgn

	-- Imp claw
	elseif st == S_DOOM_IMP_ATTACK3 then
		sfx = sfx_claw

	-- Demon bite
	elseif st == S_DOOM_DEMON_MELEE2 then
		sfx = sfx_sgtatk

	-- Barons / Hell Knight / Caco fireball
	elseif st == S_DOOM_BARONOFHELL_ATTACK2
	   or st == S_DOOM_HELLKNIGHT_ATTACK2
	   or st == S_DOOM_CACODEMON_ATTACK2 then
		sfx = sfx_firsht

/*
	-- Lost soul charge
	elseif st == S_DOOM_LOSTSOUL_MISSILE2 then
		sfx = sfx_sklatk
*/
	-- Spider Mastermind volley
	elseif st == S_DOOM_SPIDERMASTERMIND_MISSILE2
	   or st == S_DOOM_SPIDERMASTERMIND_MISSILE3 then
		sfx = sfx_shotgn

	-- Arachnotron plasma
	elseif st == S_DOOM_ARACHNOTRON_MISSILE2 then
		sfx = sfx_plasma

	-- Cyberdemon rockets
	elseif st == S_DOOM_CYBERDEMON_MISSILE2
	   or st == S_DOOM_CYBERDEMON_MISSILE4
	   or st == S_DOOM_CYBERDEMON_MISSILE6 then
		sfx = sfx_rlaunc
/*
	-- Pain elemental attack cough
	elseif st == S_DOOM_PAINELEMENTAL_MISSILE3 then
		sfx = sfx_sklatk
*/
	end

	if sfx then
		S_StartSound(nil, sfx)
	end
end

local function F_CastTicker()
    if not caststate then return end

    -- tick down
    casttics = $ - 1
    if casttics > 0 then return end

    if caststate.tics == -1 or caststate.nextstate == S_NULL then
        -- switch to next monster
        castnum = castnum + 1
        if not castorder[castnum] then
            castnum = 1
        end

        local t = castorder[castnum].type
        castdeath = false
        caststate = states[mobjinfo[t].seestate]
		if mobjinfo[t].seesound then
			S_StartSound(nil, mobjinfo[t].seesound)
		end
        castframes = 0
        updateCastSpriteVars()
    else
		local nextstate = caststate.nextstate
		if nextstate == S_PLAY_STND then
			nextstate = S_DOOM_PLAYER_MOVE1
		end
        -- sound hack for the next state
        CastSoundHack(nextstate)

        -- advance animation
        caststate = states[nextstate]
        castframes = $ + 1
        updateCastSpriteVars()
    end

    -- go into attack frame after 12 frames (same logic as Doom)
    if castframes == 12 then
        castattacking = true
        local t = castorder[castnum].type
        if castonmelee == 1 then
			CastSoundHack(mobjinfo[t].meleestate)
            caststate = states[mobjinfo[t].meleestate]
        else
			CastSoundHack(mobjinfo[t].missilestate)
            caststate = states[mobjinfo[t].missilestate]
        end
        castonmelee = $ ^^ 1
        updateCastSpriteVars()

        if caststate == states[S_NULL] then
            local t = castorder[castnum].type
            caststate = states[mobjinfo[t].seestate]
            updateCastSpriteVars()
        end
    end

    if castattacking then
        local t = castorder[castnum].type
        if castframes == 24 or caststate == states[mobjinfo[t].seestate] then
            castattacking = false
            castframes = 0
            caststate = states[mobjinfo[t].seestate]
            updateCastSpriteVars()
        end
    end

    casttics = caststate.tics
    if casttics == -1 then
        casttics = 15
    end
end

hud.add(function(v, player)
    if not caststate then return end

    -- background
    if v.patchExists("BOSSBACK") then
        v.draw(0, 0, v.cachePatch("BOSSBACK"))
    end

    F_CastPrint(v, castorder[castnum].name)

    -- Choose the right patch getter depending on sprite2 usage
    if cast_use_sprite2 and cast_sprite2 then
        -- sprite2 path: pass skin, sprite2 id, super? false, frame, rotation=0
        local patch, flip = v.getSprite2Patch(SKIN_DOOM, cast_sprite2, false, cast_sprite2frame, 0)
        if not patch then
			cast_sprite2frame = 0
            local fallback, fflip = v.getSprite2Patch(SKIN_DOOM, cast_sprite2, false, 0, 0)
            if fallback then
                local flags = 0
                if fflip then flags = flags | V_FLIP end
                v.draw(160, 170, fallback, flags)
            end
            return
        end

        local flags = 0
        if flip then flags = flags | V_FLIP end
        v.draw(160, 170, patch, flags)
    else
        -- normal sprite (non-player)
        local patch, flip = v.getSpritePatch(cast_sprite, cast_frame, 0)
        if not patch then return end
        local flags = 0
        if flip then flags = flags | V_FLIP end
        v.draw(160, 170, patch, flags)
    end
end, "game")

local function F_CastResponder(keyevent)
	if not caststate then return end

    if keyevent.repeated or keyevent.name == "TILDE" then
        return false
    end

    if castdeath then
        return true
    end

    local t = castorder[castnum].type
    castdeath = true
    caststate = states[mobjinfo[t].deathstate]
    casttics = caststate.tics
    castframes = 0
    castattacking = false
	if mobjinfo[t].deathsound then
		S_StartSound(nil, mobjinfo[t].deathsound)
	end
    return true
end

addHook("KeyDown", F_CastResponder)

addHook("ThinkFrame", function()
	if not caststate then return end

	F_CastTicker()
end)