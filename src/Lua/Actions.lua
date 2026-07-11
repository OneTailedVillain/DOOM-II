local sk_nightmare = 5

/*
void A_Look (mobj_t* actor)
{
    mobj_t*	targ;

    actor->threshold = 0;	// any shot will wake up
    targ = actor->subsector->sector->soundtarget;

    if (targ
	&& (targ->flags & MF_SHOOTABLE) )
    {
	actor->target = targ;

	if ( actor->flags & MF_AMBUSH )
	{
	    if (P_CheckSight (actor, actor->target))
		goto seeyou;
	}
	else
	    goto seeyou;
    }


    if (!P_LookForPlayers (actor, false) )
	return;

    // go into chase state
  seeyou:
    if (actor->info->seesound)
    {
	int		sound;

	switch (actor->info->seesound)
	{
	  case sfx_posit1:
	  case sfx_posit2:
	  case sfx_posit3:
	    sound = sfx_posit1+P_Random()%3;
	    break;

	  case sfx_bgsit1:
	  case sfx_bgsit2:
	    sound = sfx_bgsit1+P_Random()%2;
	    break;

	  default:
	    sound = actor->info->seesound;
	    break;
	}

	if (actor->type==MT_SPIDER
	    || actor->type == MT_CYBORG)
	{
	    // full volume
	    S_StartSound (NULL, sound);
	}
	else
	    S_StartSound (actor, sound);
    }

    P_SetMobjState (actor, actor->info->seestate);
}
*/

local function DOOM_EnterSeeState(actor)
    if actor.state == actor.info.seestate then
        return false
    end

    if actor.doom then
        if actor.doom.sightedplayer == true or actor.doom.sightedplayer == leveltime then
            print("WARNING: Actor tried to A_Look while already sighting a player!")
            return false
        end

        actor.doom.sightedplayer = true
    end

    actor.state = actor.info.seestate
    actor.reactiontime = actor.info.reactiontime or 8
	actor.threshold = 10
    return true
end

function A_DoomLook(actor)
	if not doom then return end
	local secdata = doom.sectordata and doom.sectordata[actor.subsector.sector]
	local targ = secdata and secdata.soundtarget
	actor.threshold = 0 // any shot will wake up

	local gotoseeyou = false

	-- Players are automatically friendly
	local isFriendly = actor.doom.flags & DF_FRIENDLY and (targ.doom.flags & DF_FRIENDLY or targ.type == MT_PLAYER)

	local player = targ and targ.player
	local playerAlive = true

	if player then
		local funcs = P_GetMethodsForSkin(player)
		if funcs.getHealth(player) <= 0 then playerAlive = false end
	elseif targ then
		if targ.doom.health == nil then targ.doom.health = 0 end
		if targ.doom.health <= 0 then playerAlive = false end
	end

	if (targ and targ.valid) and (targ.flags & MF_SHOOTABLE) and isFriendly and playerAlive then
		actor.target = targ

		if (actor.flags2 & MF2_AMBUSH) then
			if P_CheckSight(actor, actor.target) then
				gotoseeyou = true
				if actor.target and actor.target.valid and actor.target.player then
					local funcs = P_GetMethodsForSkin(actor.target.player)
					if funcs and funcs.shouldEnemySight then
						if funcs.shouldEnemySight(actor.target.player, actor, "sound") then
							actor.target = nil
							gotoseeyou = false
						end
					end
				end
			end
		else
			gotoseeyou = true
			if actor.target and actor.target.valid and actor.target.player then
				local funcs = P_GetMethodsForSkin(actor.target.player)
				if funcs and funcs.shouldEnemySight then
					if funcs.shouldEnemySight(actor.target.player, actor, "sound") then
						actor.target = nil
						gotoseeyou = false
					end
				end
			end
		end
	end

	if not gotoseeyou then
		if not DOOM_LookForPlayers(actor, false) then
			return
		end
	end

	-- seeyou:
	local sound = nil
	if actor.info.seesound then
		local seesound = actor.info.seesound
		if seesound == sfx_posit1 or seesound == sfx_posit2 or seesound == sfx_posit3 then
			sound = sfx_posit1 + DOOM_Random()%3
		elseif seesound == sfx_bgsit1 or seesound == sfx_bgsit2 then
			sound = sfx_bgsit1 + DOOM_Random()%2
		else
			sound = seesound
		end

		if actor.type == MT_DOOM_SPIDERMASTERMIND or actor.type == MT_DOOM_CYBERDEMON then
			S_StartSound(nil, sound) -- full volume
		else
			S_StartSound(actor, sound)
		end
	end

	DOOM_EnterSeeState(actor)
end

function A_DoomTurretLook(actor)
	local secdata = doom.sectordata and doom.sectordata[actor.subsector.sector]
	local targ = secdata and secdata.soundtarget
	actor.threshold = 0 // any shot will wake up

	local gotoseeyou = false

	-- Players are automatically friendly
	local isFriendly = actor.doom.flags & DF_FRIENDLY and (targ.doom.flags & DF_FRIENDLY or targ.type == MT_PLAYER)

	local player = targ and targ.player
	local playerAlive = true

	if player then
		local funcs = P_GetMethodsForSkin(player)
		if funcs.getHealth(player) <= 0 then playerAlive = false end
	elseif targ then
		if targ.doom.health == nil then targ.doom.health = 0 end
		if targ.doom.health <= 0 then playerAlive = false end
	end

	if targ and (targ.flags & MF_SHOOTABLE) and not isFriendly and playerAlive then
		actor.target = targ
	else
		actor.target = nil
	end

	if not actor.target then return end

	-- seeyou:
	local sound = nil
	if actor.info.seesound then
		local seesound = actor.info.seesound
		if seesound == sfx_posit1 or seesound == sfx_posit2 or seesound == sfx_posit3 then
			sound = sfx_posit1 + DOOM_Random()%3
		elseif seesound == sfx_bgsit1 or seesound == sfx_bgsit2 then
			sound = sfx_bgsit1 + DOOM_Random()%2
		else
			sound = seesound
		end

		S_StartSound(actor, sound)
	end

	DOOM_EnterSeeState(actor)
end

function A_DoomLook2(actor)
    local secdata = doom.sectordata and doom.sectordata[actor.subsector.sector]
    local targ = secdata and secdata.soundtarget
    actor.threshold = 0

	targ = $ or {flags = 0, doom = {flags = 0}}
	if not targ.doom then targ.doom = {} end
	-- Players are automatically friendly
	local isFriendly = actor.doom.flags & DF_FRIENDLY and (targ.doom.flags & DF_FRIENDLY or targ.type == MT_PLAYER)

	local player = targ and targ.player
	local playerAlive = true

	if player then
		local funcs = P_GetMethodsForSkin(player)
		if funcs.getHealth(player) <= 0 then playerAlive = false end
	elseif targ then
		if targ.doom.health == nil then targ.doom.health = 0 end
		if targ.doom.health <= 0 then playerAlive = false end
	end

    if targ and (targ.flags & MF_SHOOTABLE) and not isFriendly and playerAlive then
        actor.target = targ
        if actor.info.seesound then
            local seesound = actor.info.seesound
            local sound
            if seesound == sfx_posit1 or seesound == sfx_posit2 or seesound == sfx_posit3 then
                sound = sfx_posit1 + DOOM_Random()%3
            elseif seesound == sfx_bgsit1 or seesound == sfx_bgsit2 then
                sound = sfx_bgsit1 + DOOM_Random()%2
            else
                sound = seesound
            end
            S_StartSound(actor, sound)
        end
		DOOM_EnterSeeState(actor)
        return
    end

    local mi = mobjinfo[actor.type]
    local s1 = mi.user_idleanim1 or mi.spawnstate
    local s2 = mi.user_idleanim2 or mi.user_idleanim1 or s1
    local s3 = mi.user_idleanim3 or mi.user_idleanim2 or s2

    local standstill = (actor.doom.flags & (DF_STANDSTILL or 0))

	if DOOM_Random() < 30 then
		actor.state = (DOOM_Random() & 1) == 0 and s1 or s2
	end

	if not standstill and DOOM_Random() < 40 then
		actor.state = s3
	end
end

local CHF_FASTCHASE = 1
local CHF_NOPLAYACTIVE = 2
local CHF_NIGHTMAREFAST = 4
local CHF_RESURRECT = 8
local CHF_DONTMOVE = 16
local CHF_NORANDOMTURN = 32
local CHF_NODIRECTIONTURN = 64
local CHF_NOPOSATTACKTURN = 128
local CHF_STOPIFBLOCKED = 256
local CHF_DONTIDLE = 512
local CHF_DONTLOOKALLAROUND = 1024

local function P_TryWalk(actor)
	if not P_Move(actor, actor.info.speed / FRACUNIT) then
		return false
	end
	actor.movecount = DOOM_Random() & 15
	return true
end

local function P_RandomChaseDir(actor)
	local olddir = actor.movedir or DI_NODIR
	local turnaround = opposite and opposite[olddir] or DI_NODIR
	local turndir

	-- TODO: ZDOOM: Make some actors follow the player!!

	-- sometimes continue forward
	if DOOM_Random() < 150 then
		if P_TryWalk(actor) then
			return
		end
	end

	-- pick a turning direction
	turndir = ((DOOM_Random() & 1) ~= 0) and -1 or 1

	if olddir == DI_NODIR then
		olddir = DOOM_Random() & 7
	end

	-- try all directions except turnaround
	local tdir = (olddir + turndir) & 7
	while tdir ~= olddir do
		if tdir ~= turnaround then
			actor.movedir = tdir
			if P_TryWalk(actor) then
				return
			end
		end

		tdir = (tdir + turndir) & 7
	end

	-- last resort: try turnaround
	if turnaround ~= DI_NODIR then
		actor.movedir = turnaround
		if P_TryWalk(actor) then
			actor.movecount = DOOM_Random() & 15
			return
		end
	end

	-- stuck
	actor.movedir = DI_NODIR
end

-- Ensure these flags exist even if not yet officially declared
local DF_INCOMBAT = DF_INCOMBAT or 0
local DF_INCONVERSATION = DF_INCONVERSATION or 0
local DF_STANDSTILL = DF_STANDSTILL or 0

function A_DoomWander(actor, flags)
	-- clears combat state (Strife-like behavior)
	if actor.flags4 then
		actor.flags4 = actor.flags4 & ~DF_INCOMBAT
	end

	-- don't act while in conversation
	if actor.doom.flags and (actor.doom.flags & DF_INCONVERSATION) then
		return
	end

	-- don't move if forced to stand still
	if actor.doom.flags and (actor.doom.flags & DF_STANDSTILL) then
		return
	end

	-- reaction delay
	if actor.reactiontime and actor.reactiontime > 0 then
		actor.reactiontime = $ - 1
		return
	end

	-- turn toward movement direction if allowed
	if not (flags & CHF_NODIRECTIONTURN) and actor.movedir > DI_NODIR then
		-- snap angle to nearest 45 sector
		actor.angle = $ & (7<<29)

		-- convert to degrees
		local target = actor.movedir << 29

		-- Lugent didn't MR this! But credits to them
		local delta = FixedInt(AngleFixed(target - actor.angle))
		if delta < 45 or delta > 315 then
			actor.angle = target
		elseif delta < 180 then
			actor.angle = $ + ANGLE_45
		else
			actor.angle = $ - ANGLE_45
		end
	end

	-- movement / random turning logic
	local moved = P_Move(actor, actor.info.speed / FRACUNIT)

	if ((actor.movecount and (actor.movecount - 1 < 0)) and not (flags & CHF_NORANDOMTURN))
		or (not moved and not (flags & CHF_STOPIFBLOCKED))
	then
		P_RandomChaseDir(actor)
		actor.movecount = (actor.movecount or 0) + 5
	else
		actor.movecount = (actor.movecount or 0) - 1
	end
end

/*
//
// A_Chase
// Actor has a melee attack,
// so it tries to close as fast as possible
//
void A_Chase (mobj_t*	actor)
{
    int		delta;

    if (actor->reactiontime)
	actor->reactiontime--;


    // modify target threshold
    if  (actor->threshold)
    {
	if (!actor->target
	    || actor->target->health <= 0)
	{
	    actor->threshold = 0;
	}
	else
	    actor->threshold--;
    }

    // turn towards movement direction if not there yet
    if (actor->movedir < 8)
    {
	actor->angle &= (7<<29);
	delta = actor->angle - (actor->movedir << 29);

	if (delta > 0)
	    actor->angle -= ANG90/2;
	else if (delta < 0)
	    actor->angle += ANG90/2;
    }

    if (!actor->target
	|| !(actor->target->flags&MF_SHOOTABLE))
    {
	// look for a new target
	if (P_LookForPlayers(actor,true))
	    return; 	// got a new target

	P_SetMobjState (actor, actor->info->spawnstate);
	return;
    }

    // do not attack twice in a row
    if (actor->flags & MF_JUSTATTACKED)
    {
	actor->flags &= ~MF_JUSTATTACKED;
	if (gameskill != sk_nightmare && !fastparm)
	    P_NewChaseDir (actor);
	return;
    }

    // check for melee attack
    if (actor->info->meleestate
	&& P_CheckMeleeRange (actor))
    {
	if (actor->info->attacksound)
	    S_StartSound (actor, actor->info->attacksound);

	P_SetMobjState (actor, actor->info->meleestate);
	return;
    }

    // check for missile attack
    if (actor->info->missilestate)
    {
	if (gameskill < sk_nightmare
	    && !fastparm && actor->movecount)
	{
	    goto nomissile;
	}

	if (!P_CheckMissileRange (actor))
	    goto nomissile;

	P_SetMobjState (actor, actor->info->missilestate);
	actor->flags |= MF_JUSTATTACKED;
	return;
    }

    // ?
  nomissile:
    // possibly choose another target
    if (netgame
	&& !actor->threshold
	&& !P_CheckSight (actor, actor->target) )
    {
	if (P_LookForPlayers(actor,true))
	    return;	// got a new target
    }

    // chase towards player
    if (--actor->movecount<0
	|| !P_Move (actor))
    {
	P_NewChaseDir (actor);
    }

    // make active sound
    if (actor->info->activesound
	&& P_Random () < 3)
    {
	S_StartSound (actor, actor->info->activesound);
    }
}
*/

local function DOOM_CheckMissileRange(actor)
    local dist;

    if not P_CheckSight(actor, actor.target) then
	return false;
	end

    if ( actor.doom.flags & DF_JUSTHIT )
	// the target just hit the enemy,
	// so fight back!
	actor.doom.flags = $ & ~DF_JUSTHIT;
	return true;
    end

    if (actor.reactiontime)
	return false;	// do not attack yet
	end

    // OPTIMIZE: get this from a global checksight
    dist = P_AproxDistance ( actor.x - actor.target.x,
			     actor.y - actor.target.y) - 64*FRACUNIT;

    if (not actor.info.meleestate) then
	dist = $ - 128*FRACUNIT;	// no melee attack, so fire more
	end

    dist = $ >> FRACBITS;

	--#ifdef DOOM
    if (actor.type == MT_DOOM_ARCHVILE)
		if (dist > 14*64)
			return false;	// too far away
		end
	end

    if (actor.type == MT_DOOM_ARCHVILE)
		if (dist < 196)
			return false;	// close for fist attack
		end
		dist = $ >> 1;
    end

    if actor.type == MT_DOOM_CYBERDEMON
	or actor.type == MT_DOOM_SPIDERMASTERMIND
	or actor.type == MT_DOOM_LOSTSOUL then
		dist = $ >> 1;
    end
	--#endif
    if (dist > 200)
	dist = 200;
	end

	--#ifdef DOOM
    if (actor.type == MT_DOOM_CYBERDEMON and dist > 160) then
		dist = 160;
	end
	--#endif

	if (DOOM_Random() < dist) then
		return false;
	end

    return true;
end

function A_DoomChase(actor)
	local delta

	if actor.reactiontime and actor.reactiontime > 0 then
		actor.reactiontime = $ - 1
	end

	// Modify target threshold
	if actor.threshold then
		if not actor.target or actor.target.doom.health <= 0 then
			actor.threshold = 0
		else
			actor.threshold = $ - 1
		end
	end

	// Turn toward movement direction if not there yet
	if actor.movedir < 8 then
		-- snap angle to nearest 45 sector
		actor.angle = $ & (7<<29)

		-- convert to degrees
		local target = actor.movedir << 29

		-- Lugent didn't MR this! But credits to them
		local delta = FixedInt(AngleFixed(target - actor.angle))
		if delta < 45 or delta > 315 then
			actor.angle = target
		elseif delta < 180 then
			actor.angle = $ + ANGLE_45
		else
			actor.angle = $ - ANGLE_45
		end
	end

	local player = actor.target and actor.target.player
	local playerAlive = true

	if player then
		local funcs = P_GetMethodsForSkin(player)
		if funcs.getHealth(player) <= 0 then playerAlive = false end
	end

	// No valid target
	if not actor.target or not (actor.target.flags & MF_SHOOTABLE) or not playerAlive then
		if DOOM_LookForPlayers(actor, true) then
			return
		end

		actor.doom.sightedplayer = leveltime
		actor.state = actor.info.spawnstate
		return
	end

	// Prevent attacking twice in a row
	if (actor.flags2 & MF2_JUSTATTACKED) then
		actor.flags2 = $ & ~MF2_JUSTATTACKED
		if doom.gameskill ~= sk_nightmare and not fastparm then
			P_NewChaseDir(actor)
		end
		return
	end

	// Melee attack check
	if actor.info.meleestate and P_CheckMeleeRange(actor) then
		if actor.info.attacksound then
			S_StartSound(actor, actor.info.attacksound)
		end
		actor.state = actor.info.meleestate
		return
	end

	// Missile attack check
	local doMissile = true
	if actor.info.missilestate then
		if doom.gameskill < sk_nightmare and not fastparm and actor.movecount then
			doMissile = false
		end

		if doMissile and DOOM_CheckMissileRange(actor) then
			actor.state = actor.info.missilestate
			actor.flags2 = $ | MF2_JUSTATTACKED
			return
		end
	end

	// Possibly choose another target if in netgame and can't see player
	if netgame and actor.threshold == 0 and not P_CheckSight(actor, actor.target) then
		if DOOM_LookForPlayers(actor, true) then
			return
		end
	end

	// Chase toward player
	actor.movecount = $ - 1
	local moved = true
	if actor.movecount < 0 then
		moved = false
	else
		moved = P_Move(actor, actor.info.speed / FRACUNIT)
	end
	if not moved then
		P_NewChaseDir(actor)
	end

	// Play active sound
	if actor.info.activesound and DOOM_Random() < 3 then
		S_StartSound(actor, actor.info.activesound)
	end
end

/*
void A_FaceTarget (mobj_t* actor)
{
    if (!actor->target)
	return;

    actor->flags &= ~MF_AMBUSH;

    actor->angle = R_PointToAngle2 (actor->x,
				    actor->y,
				    actor->target->x,
				    actor->target->y);

    if (actor->target->flags & MF_SHADOW)
	actor->angle += (P_Random()-P_Random())<<21;
}
*/

function A_DoomFaceTarget(actor)
    if (not actor.target) then return end

    actor.flags2 = $ & ~MF2_AMBUSH

    actor.angle = R_PointToAngle2(actor.x,
				    actor.y,
				    actor.target.x,
				    actor.target.y)

    if (actor.target.doom.flags & DF_SHADOW) then
		actor.angle = $ + (DOOM_Random()-DOOM_Random())<<21
	end
end

/*
void A_TroopAttack (mobj_t* actor)
{
    int		damage;

    if (!actor->target)
	return;

    A_FaceTarget (actor);
    if (P_CheckMeleeRange (actor))
    {
	S_StartSound (actor, sfx_claw);
	damage = (P_Random()%8+1)*3;
	P_DamageMobj (actor->target, actor, actor, damage);
	return;
    }


    // launch a missile
    P_SpawnMissile (actor, actor->target, MT_TROOPSHOT);
}
*/

function A_DoomTroopAttack(actor)
    local damage

    if (not actor.target) then
		return
	end

    A_FaceTarget(actor);
    if (P_CheckMeleeRange (actor)) then
		S_StartSound (actor, sfx_claw);
		damage = (DOOM_Random()%8+1)*3;
		DOOM_DamageMobj(actor.target, actor, actor, damage);
		return
    end


    // launch a missile
    DOOM_SpawnMissile(actor, actor.target, MT_TROOPSHOT)
end

/*
void A_Pain (mobj_t* actor)
{
    if (actor->info->painsound)
	S_StartSound (actor, actor->info->painsound);
}
*/

function A_DoomPain(actor)
    if (actor.info.painsound)
		local painsound = actor.info.painsound
		if painsound == sfx_pespna
		or painsound == sfx_pespnb
		or painsound == sfx_pespnc
		or painsound == sfx_pespnd then
			painsound = sfx_pespna + DOOM_Random()%4
		end
		S_StartSound (actor, painsound)
	end
end

/*
void A_Scream (mobj_t* actor)
{
    int		sound;

    switch (actor->info->deathsound)
    {
      case 0:
	return;

      case sfx_podth1:
      case sfx_podth2:
      case sfx_podth3:
	sound = sfx_podth1 + P_Random ()%3;
	break;

      case sfx_bgdth1:
      case sfx_bgdth2:
	sound = sfx_bgdth1 + P_Random ()%2;
	break;

      default:
	sound = actor->info->deathsound;
	break;
    }

    // Check for bosses.
    if (actor->type==MT_SPIDER
	|| actor->type == MT_CYBORG)
    {
	// full volume
	S_StartSound (NULL, sound);
    }
    else
	S_StartSound (actor, sound);
}

*/
function A_DoomScream(actor)
    local sound

	if not actor.info.deathsound then
		return
	elseif actor.info.deathsound == sfx_podth1 or actor.info.deathsound == sfx_podth2 or actor.info.deathsound == sfx_podth3 then
		sound = sfx_podth1 + DOOM_Random()%3
	elseif actor.info.deathsound == sfx_bgdth1 or actor.info.deathsound == sfx_bgdth2 then
		sound = sfx_bgdth1 + DOOM_Random()%2
	else
		sound = actor.info.deathsound
	end
/*
    // Check for bosses.
	-- TODO: CREATE THESE TWO!!! Slacker.
    if (actor.type==MT_SPIDER or actor.type == MT_CYBORG)
		// full volume
		S_StartSound (NULL, sound)
    else
		S_StartSound (actor, sound)
	end
*/
	S_StartSound(actor, sound)
end

/*
void A_Fall (mobj_t *actor)
{
    // actor is on ground, it can be walked over
    actor->flags &= ~MF_SOLID;

    // So change this if corpse objects
    // are meant to be obstacles.
}
*/

function A_DoomFall(actor)
    // actor is on ground, it can be walked over
    actor.flags = $ & ~MF_SOLID

    // So change this if corpse objects
    // are meant to be obstacles.
end

/*
void A_XScream (mobj_t* actor)
{
    S_StartSound (actor, sfx_slop);
}
*/

function A_DoomXScream(actor)
    S_StartSound(actor, sfx_slop)
end

local soundblocks = 0

local function P_LineOpening(line)
	local openrange
	local opentop
	local openbottom
	local lowfloor
    if line.sidenum[1] == -1 then
	// single sided line
	openrange = 0;
	return;
	end

    local front = line.frontsector;
    local back = line.backsector;

    if (front.ceilingheight < back.ceilingheight) then
	opentop = front.ceilingheight;
    else
	opentop = back.ceilingheight;
	end

    if (front.floorheight > back.floorheight) then
	openbottom = front.floorheight;
	lowfloor = back.floorheight;
    else
	openbottom = back.floorheight;
	lowfloor = front.floorheight;
	end

	openrange = opentop - openbottom
    return openrange -- nonzero = open
end

local function P_IterativeSound(start_sec, start_soundblocks, emitter)
    local queue = {}
    local visited = {} -- Track sectors we've already processed

    table.insert(queue, {
        sec = start_sec,
        soundblocks = start_soundblocks
    })

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local sec = current.sec
        local soundblocks = current.soundblocks

        doom.sectordata[sec] = $ or {validcount = -999, soundtraversed = -999}
        local data = doom.sectordata[sec]

        -- Skip if we've already visited with better or equal soundblocks
        if data.validcount == doom.validcount and data.soundtraversed <= soundblocks + 1 then
            continue
        end

        -- Mark as visited and update data
        visited[sec] = true
        data.validcount = doom.validcount
        data.soundtraversed = soundblocks + 1
        data.soundtarget = emitter

        -- Process all lines from this sector
        for i = 0, #sec.lines - 1 do
            local line = sec.lines[i]
            if not (line.flags & ML_TWOSIDED) then continue end

            local openrange = P_LineOpening(line)
            if openrange <= 0 then continue end

            local other = nil
            if line.frontsector == sec then
                other = line.backsector
            else
                other = line.frontsector
            end

            -- Skip if we've already visited this sector
            if visited[other] then continue end

            if (line.flags & DML_SOUNDBLOCK) ~= 0 then
                if soundblocks == 0 then
                    table.insert(queue, {
                        sec = other,
                        soundblocks = 1
                    })
                end
            else
                table.insert(queue, {
                    sec = other,
                    soundblocks = soundblocks
                })
            end
        end
    end
end

rawset(_G, "P_NoiseAlert", function(target, emitter)
	doom.validcount = $ + 1
	soundblocks = 0
	P_IterativeSound(emitter.subsector.sector, soundblocks, target)
end)

function A_ChainSawSound(actor, sfx)
	local sawsounds = {sfx_sawidl, sfx_sawful, sfx_sawup, sfx_sawhit}
	for _, sound in ipairs(sawsounds) do
		S_StopSoundByID(actor, sound)
	end
	S_StartSound(actor, sfx)
end
/*
function A_DoomPunch(actor, var1, var2, weapon)
	local player = actor.player
	if player == nil then return end
	local mult = player.doom.powers[pw_strength] and 10 or 1
	DOOM_Fire(player, MELEERANGE, 0, 0, 1, 2 * mult, 20 * mult, nil, nil, nil, nil, nil, weapon.hitsound)
	P_NoiseAlert(actor, actor)
end
*/
function A_SawHit(actor, var1, var2, weapon)
	local player = actor.player
	if player == nil then return end
	A_ChainSawSound(actor, sfx_sawful)
	A_DoomPunch(actor, var1, var2, weapon)
end

-- Cut-down definitions for SPECIFICALLY enemies
-- This is the DEFAULT ENEMY WEAPON DEFINITION TABLE,
-- any idTech 1 data should overwrite this if this is inaccurate
---@type table<integer, shortweapondef_t>
doom.predefinedWeapons = {
	{
		damage = {3, 15},
		pellets = 1,
		firesound = sfx_pistol,
		spread = {
			horiz = FRACUNIT*59/10,
			vert = 0,
		},
	},
	{
		damage = {3, 15},
		pellets = 3,
		firesound = sfx_shotgn,
		spread = {
			horiz = FRACUNIT*59/10,
			vert = 0,
		},
	},
	{
		damage = {3, 15},
		pellets = 1,
		firesound = sfx_shotgn,
		spread = {
			horiz = FRACUNIT*59/10,
			vert = 0,
		},
	},
	{
		damage = {20, 160},
		pellets = 1,
		shootmobj = MT_DOOM_ROCKETPROJ,
	},
}

function A_NotDoomFire(actor)
    local weapon = (actor.player and DOOM_GetWeaponDef(actor.player))
    if not weapon then return end

    local player = actor.mo and actor or actor.player
    if not player then return end

    local funcs = P_GetMethodsForSkin(player)
    local curAmmo = funcs.getCurAmmo(player)
    local curType = funcs.getCurAmmoType(player)

    local shouldDecrease = true
    if curAmmo ~= false and weapon.shotcost ~= 0 then
        if curAmmo - weapon.shotcost < 0 then return end
    else
        shouldDecrease = false
    end

    if weapon.firesound then
        S_StartSound(actor, weapon.firesound)
    end

    P_NoiseAlert(actor, actor)

    if weapon.states and weapon.states.flash then
        A_DoomGunFlash(actor)
    end

    local spread
    if weapon.noinitfirespread and not player.doom.refire then
        spread = {horiz = 0, vert = 0}
    else
        spread = weapon.spread
    end

    if shouldDecrease then
        funcs.setAmmoFor(player, curType, curAmmo - weapon.shotcost)
    end

    DOOM_Fire(player, weapon.maxdist or MISSILERANGE,
        spread and spread.horiz or 0,
        spread and spread.vert or 0,
        weapon.pellets or 1,
        weapon.damage[1], weapon.damage[2], weapon.damage[3],
        weapon.shootmobj, weapon.shootflags2, weapon.shootfuse,
        weapon.firefunc, weapon.hitsound)
end

function A_DoomFire(actor, var1, weaponDef, weapon)
    -- Determine if this is a player or enemy
    local player = actor.mo and actor or actor.player

    if player then
		local wepProperties = type(weaponDef) == "table" and weaponDef or {}
        -- Player logic
        local funcs = P_GetMethodsForSkin(player)
        local curAmmo = funcs.getCurAmmo(player)
        local curType = funcs.getCurAmmoType(player)
		local shouldDecrease = true

		if curAmmo != false and weapon.shotcost != 0 then
			if curAmmo - weapon.shotcost < 0 then return end
		else shouldDecrease = false
		end

		if weapon.firesound and not wepProperties.noFireSound then
			S_StartSound(actor, weapon.firesound)
		end

		P_NoiseAlert(actor, actor)

		if not wepProperties.noFlash and weapon.states.flash then
			A_DoomGunFlash(actor)
		end

        local spread

        if weapon.noinitfirespread and not player.doom.refire then
            spread = {horiz = 0, vert = 0}
        else
            spread = weapon.spread
        end

		if shouldDecrease then
    	    funcs.setAmmoFor(player, curType, curAmmo - weapon.shotcost)
		end

        DOOM_Fire(player, weapon.maxdist or MISSILERANGE, spread and spread.horiz or 0, spread and spread.vert or 0, weapon.pellets or 1, weapon.damage[1], weapon.damage[2], weapon.damage[3], weapon.shootmobj, weapon.shootflags2, weapon.shootfuse, weapon.firefunc, weapon.hitsound)
    else
		A_DoomFaceTarget(actor)

		local weapon = doom.predefinedWeapons[weaponDef or 1]
        -- Enemy logic
		if weapon.firesound then
			S_StartSound(actor, weapon.firesound)
		end
        DOOM_Fire(actor, weapon.maxdist or MISSILERANGE, weapon.spread and weapon.spread.horiz or 0, weapon.spread and weapon.spread.vert or 0, weapon.pellets or 1, weapon.damage[1], weapon.damage[2], weapon.damage[3], weapon.shootmobj, weapon.shootflags2, weapon.shootfuse, weapon.firefunc, weapon.hitsound)
    end
end

local function DOOM_GetFrameDef(weapon, stateName, frame)
	local def = DOOM_ResolveStateDef(weapon, stateName, frame)
	return def
end

function A_DoomGunFlash(actor, var1, var2, weapon)
	local player = actor.player
	if not weapon then
		weapon = DOOM_GetWeaponDef(player)
	end
	if not weapon then return end

	local flashDef = DOOM_GetFrameDef(weapon, "flash", 1)
	if not flashDef then return end

	DOOM_SetFlashState(player, "flash")

	actor.state = S_DOOM_PLAYER_FLASH1
end

/*
void A_ReFire
( player_t*	player,
  pspdef_t*	psp )
{

    // check for fire
    //  (if a weaponchange is pending, let it go through instead)
    if ( (player->cmd.buttons & BT_ATTACK)
	 && player->pendingweapon == wp_nochange
	 && player->health)
    {
	player->refire++;
	P_FireWeapon (player);
    }
    else
    {
	player->refire = 0;
	P_CheckAmmo (player);
    }
}
*/

function A_DoomReFire(actor)
	local player = actor.player
	if not player then return end

	local funcs = P_GetMethodsForSkin(player)
	local health = funcs.getHealth(player)

	local wepDef = DOOM_GetWeaponDef(player)
	local curWepAmmo = player.doom.ammo[wepDef.ammotype] or 0
	local ammoNeeded = wepDef.shotcost

	-- Rough equivalent of "pendingweapon == wp_nochange"
	local noPendingSwitch =
		(not player.doom.switchingweps)
		and (
			not player.doom.wepcarousel.active
			or player.doom.wepcarousel.curwep == player.doom.curwep
		)
		and (
			not player.doom.wishwep
			or player.doom.wishwep == ""
			or player.doom.wishwep == player.doom.curwep
		)

	if (player.cmd.buttons & BT_ATTACK) ~= 0
	--and max(curWepAmmo, 0) >= ammoNeeded
	and noPendingSwitch
	and health > 0
	then
		player.doom.refire = (player.doom.refire or 0) + 1
		DOOM_FireWeapon(player)
	else
		player.doom.refire = 0
		DOOM_DoAutoSwitch(player)
	end
end

/*
void A_CPosRefire (mobj_t* actor)
{
    // keep firing unless target got out of sight
    A_FaceTarget (actor);

    if (P_Random () < 40)
	return;

    if (!actor->target
	|| actor->target->health <= 0
	|| !P_CheckSight (actor, actor->target) )
    {
	P_SetMobjState (actor, actor->info->seestate);
    }
}
*/

function A_CPosRefire(actor)
    A_DoomFaceTarget(actor)

	if DOOM_Random() < 40 then return end

	if not actor.target or actor.target.doom.health <= 0 or not P_CheckSight(actor, actor.target) then
		actor.state = actor.info.seestate
	end
end

/*
void A_SpidRefire (mobj_t* actor)
{
    // keep firing unless target got out of sight
    A_FaceTarget (actor);

    if (P_Random () < 10)
	return;

    if (!actor->target
	|| actor->target->health <= 0
	|| !P_CheckSight (actor, actor->target) )
    {
	P_SetMobjState (actor, actor->info->seestate);
    }
}
*/

function A_SpidRefire(actor)
    A_DoomFaceTarget(actor)

	if DOOM_Random() < 10 then return end

	if not actor.target or actor.target.doom.health <= 0 or not P_CheckSight(actor, actor.target) then
		actor.state = actor.info.seestate
	end
end

/*
void A_SargAttack (mobj_t* actor)
{
    int		damage;

    if (!actor->target)
	return;

    A_FaceTarget (actor);
    if (P_CheckMeleeRange (actor))
    {
	damage = ((P_Random()%10)+1)*4;
	P_DamageMobj (actor->target, actor, actor, damage);
    }
}
*/

function A_DoomSargAttack(actor)
	if not actor.target then return end
	A_DoomFaceTarget(actor)
	if P_CheckMeleeRange(actor) then
		local damage = ((DOOM_Random()%10)+1)*4
		DOOM_DamageMobj(actor.target, actor, actor, damage)
	end
end

local function DOOM_ChebyshevDistance(x1, y1, x2, y2)
    local deltaX = abs(x2 - x1)
    local deltaY = abs(y2 - y1)

    if deltaX > deltaY then
        return deltaX
    else
        return deltaY
    end
end

local function DOOM_GetDistance(obj1, obj2) -- same as below but closer to source (essentially a wrapper... a pawrappa the wrappa if you will)
	if not obj1 or not obj2 then return 0 end -- Ensure both objects exist

	return DOOM_ChebyshevDistance(obj1.x, obj1.y, obj2.x, obj2.y)
	-- and yes, i'm making the radius infinitely high
end

local function HL_GetDistance(obj1, obj2) -- get distance between two objects; useful for things like explosion damage calculation
	if not obj1 or not obj2 then return 0 end -- Ensure both objects exist

	local dx = obj1.x - obj2.x
	local dy = obj1.y - obj2.y
	local dz = obj1.z - obj2.z

	return FixedHypot(FixedHypot(dx, dy), dz) -- 3D distance calculationd
end
rawset(_G, "DOOM_RadiusAttack", function(actor, source, range)
	if not (actor and actor.valid) then return end -- Ensure the actor exists

	actor.doom.preferselfdamage = false

	local function DamageAndBoostNearby(refmobj, foundmobj)
		refmobj.ignoredamagedef = true
		local dist = DOOM_GetDistance(refmobj, foundmobj)
		if dist > range then return end -- Only affect objects within range

		if not foundmobj or foundmobj == refmobj then return end -- Skip if no object or self
		if not P_CheckSight(refmobj, foundmobj) then return end -- Skip if we don't have a clear view
		if not (foundmobj.flags & MF_SHOOTABLE) then return end -- Don't attempt to hurt things that shouldn't be hurt

		-- Recheck in case it died from thrust or other edge case
		if not foundmobj then return end

		local damage = (range - dist) / FRACUNIT
		DOOM_DamageMobj(foundmobj, actor, (source and source.valid) and source or actor, damage, doom.damagetypes.explodesplash)
	end

	-- Process nearby objects
	searchBlockmap("objects", DamageAndBoostNearby,
		actor,
		actor.x - range, actor.x + range,
		actor.y - range, actor.y + range
	)
end)

function A_DoomExplode(actor)
	if not (actor and actor.valid) then return end
	DOOM_RadiusAttack(actor, actor.target, 128*FRACUNIT)
end

function A_MaybeRespawn(actor)

end

function A_DoomBrainAwake(actor)
	S_StartSound(nil, sfx_bossit)
end

local WEAPONBOTTOM = 128
local WEAPONTOP = 0
local LOWERSPEED = 6
local RAISESPEED = 6

function A_DoomLower(mobj)
    local S_NULL_STATE_NAME = "null"            -- fallback name for 'no weapon' psprite state

    -- advance the psprite vertical offset
    mobj.player.doom.switchtimer = ($ or 0) + LOWERSPEED

    -- if still not fully down, just return (do nothing else)
    if mobj.player.doom.switchtimer < WEAPONBOTTOM then
        return
    end

	-- Keep our weapon at WEAPONBOTTOM
	mobj.player.doom.switchtimer = WEAPONBOTTOM

    -- if mobj has no health, keep the weapon off-screen
    if not mobj.doom.health or mobj.doom.health <= 0 then
        return
    end

    -- At this point the old weapon has been lowered off-screen.
    -- Transfer "pending" / "wish" weapon to ready/current and start the raise sequence.
    if mobj.player.doom.wishwep then
		local upsound = doom.weapons[mobj.player.doom.wishwep].upsound
		if upsound then
			S_StartSound(mobj, upsound)
		end
        DOOM_SwitchWeapon(mobj.player, mobj.player.doom.wishwep, true)
    end

    -- start bringing the weapon up
    DOOM_SetState(mobj.player, "raise", 1)
end


-- Raise the current weapon; when fully raised, set it to the ready/idle state.
function A_DoomRaise(mobj, psp)
    local RAISESPEED = RAISESPEED or 6        -- analogous to C RAISESPEED
    local WEAPONTOP = WEAPONTOP or 0          -- psprite top offset

    -- move psprite up toward WEAPONTOP
    mobj.player.doom.switchtimer = (mobj.player.doom.switchtimer or 0) - RAISESPEED

    -- if still above top, exit and let raising continue next tick
    if mobj.player.doom.switchtimer > WEAPONTOP then
        return
    end

    -- clamp to exact top
    mobj.player.doom.switchtimer = WEAPONTOP

    -- raising finished: clear any switchtimer gating
	mobj.player.doom.switchingweps = false
    mobj.player.doom.switchtimer = nil

    DOOM_SetState(mobj.player)
end

function A_DoomHeadAttack(actor)
	if P_CheckMeleeRange(actor) then
		S_StartSound (actor, sfx_claw);
		local damage = (DOOM_Random()%6+1)*10;
		DOOM_DamageMobj(actor.target, actor, actor, damage);
		return
	end

	DOOM_SpawnMissile(actor, actor.target, MT_DOOM_CACODEMONSHOT)
end

function A_DoomWeaponReady(actor, action, actionvars, weapondef)
	local player = actor.player
	local funcs = P_GetMethodsForSkin(player)
	if not funcs.getHealth then return end
	local curHealth = funcs.getHealth(player)
	weapondef = $ or {}

	if actor.state == S_DOOM_PLAYER_ATTACK1
	or actor.state == S_DOOM_PLAYER_FLASH1 then
		actor.state = S_PLAY_STND
	end

	-- Play idle sound (once when entering ready)
	if weapondef.idlesound then
		S_StartSound(actor, weapondef.idlesound)
	end

	if weapondef.idleaction then
		local ia = weapondef.idleaction
		ia.call(actor, ia.var1, ia.var2)
	end

	-- Call additional custom action if provided
	if action and type(action) == "function" then
		local var1 = actionvars and actionvars.var1
		local var2 = actionvars and actionvars.var2
		action(actor, var1, var2)
	end

	local noPendingSwitch =
		(not player.doom.switchingweps)
		and (
			not player.doom.wepcarousel.active
			or player.doom.wepcarousel.curwep == player.doom.curwep
		)
		and (
			not player.doom.wishwep
			or player.doom.wishwep == ""
			or player.doom.wishwep == player.doom.curwep
		)

	-- Only lower weapon if switching or dead
	if not noPendingSwitch or curHealth <= 0 then
		DOOM_SetState(player, "lower")
	end

	-- Weapon bobbing (always active in ready state)
	player.hl1wepbob = (FixedMul(actor.momx, actor.momx) + FixedMul(actor.momy, actor.momy)) >> 2
	if player.hl1wepbob > FRACUNIT * 16 then
		player.hl1wepbob = FRACUNIT * 16
	end

	-- Handle attack input
	local attackHeld = (player.cmd.buttons & BT_ATTACK) ~= 0
	if attackHeld and noPendingSwitch then
		-- Only fire if attack wasn’t already down, or if weapon allows auto-fire
		if not player.doom.attackdown or not weapondef.noautoswitchfire then
			player.doom.attackdown = true
			DOOM_FireWeapon(player)
			return
		end
	else
		player.doom.attackdown = false
		player.doom.refire = 0
	end

	-- Weapon bob angles
	local bobAngleX = ((128 * leveltime) & 8191) << 19
	-- DEFAULT:
	local bobAngleY = ((128 * leveltime) & 4095) << 19
	-- ALTBOB 1:
	-- local bobAngleY = ((256 * leveltime) & 8191) << 19
	-- (also halve the sin() call for this)
	player.doom.bobx = FixedMul(player.hl1wepbob or 0, cos(bobAngleX))
	player.doom.boby = FixedMul(player.hl1wepbob or 0, sin(bobAngleY))
end

function A_DoomCheckReload(actor, var1, var2, weapon)
    -- Determine if this is a player or enemy
    local isPlayerActor = actor.player ~= nil
    local player = actor.player

	local funcs = P_GetMethodsForSkin(player)
	local curAmmo = funcs.getCurAmmo(player)
	local curType = funcs.getCurAmmoType(player)

	if type(curAmmo) != "boolean" then
		if curAmmo - weapon.shotcost < 0 then DOOM_DoAutoSwitch(player) return end
	end
end

local function checkAliveTypes(targetType)
	local keenExists = 0
	local keenDead = 0
	for mobj in mobjs.iterate() do
		if mobj.type != targetType then continue end
		keenExists = $ + 1
		if mobj.doom.health <= 0 then
			keenDead = $ + 1
		end
	end
	return keenExists == keenDead
end

function A_DoomBossDeath(actor)
	if not doom.bossDeathSpecials[actor.type] then return end

	local data = doom.bossDeathSpecials[actor.type]
	local noSurvivors = checkAliveTypes(actor.type)

	if noSurvivors then
		-- Check if we have a map-specific condition
		local shouldActivate = true
		if data.map then
			if type(data.map) == "table" then
				-- Check if current map is in the table
				shouldActivate = table.contains(data.map, gamemap)
			else
				-- Single map value
				shouldActivate = (data.map == gamemap)
			end
		end

		if shouldActivate then
			for sector in sectors.tagged(data.tag) do
				doom.addThinker(sector, doom.lineActions[data.special])
			end
		end
	end
end

function A_DoomKeenDeath(actor)
	local noSurvivors = checkAliveTypes(MT_DOOM_KEEN)
	if noSurvivors then
		for sector in sectors.tagged(666) do
			doom.addThinker(sector, doom.lineActions[31])
		end
	end
end

function A_DoomLight0(actor)
	local player = actor.player
	player.doom.extralight = 0
end

function A_DoomLight1(actor)
	local player = actor.player
	player.doom.extralight = 1
end

function A_DoomLight2(actor)
	local player = actor.player
	player.doom.extralight = 2
end

function A_DoomPlayerScream(actor)
	local sound = "pldeth"
	-- Source code seems to suggest that hideth is locked to doom ii?
	-- GZDoom says otherwise, though
	if
		-- doom.gamemode == "commercial" and
		actor.doom.health < -50 then
		sound = "pdiehi"
	end

	doom.playReplaceableSound(actor, sound, actor.player)
end

local SKULLSPEED = 20 * FRACUNIT
function A_SkullAttack(actor)
	if not actor.target then return end

	local dest = actor.target
	-- Utterly UGLY hack since MF2_SKULLFLY will cause Lost Souls to stop one tic before hitting the player
	actor.doom.flags = actor.doom.flags | DF_SKULLFLY

	S_StartSound(actor, actor.info.attacksound)
	A_DoomFaceTarget(actor)
	local an = actor.angle
	actor.momx = FixedMul(SKULLSPEED, cos(an))
	actor.momy = FixedMul(SKULLSPEED, sin(an))
	local dist = P_AproxDistance(dest.x - actor.x, dest.y - actor.y)
	dist = dist / SKULLSPEED

	if dist < 1 then
		dist = 1
	end
	actor.momz = (dest.z + (dest.height >> 1) - actor.z) / dist
end

-- Stub
-- TODO: Move as FAR AWAY from fakestates as possible! Needed for DEHACKED

/*
//
// P_BringUpWeapon
// Starts bringing the pending weapon up
// from the bottom of the screen.
// Uses player
//
void P_BringUpWeapon (player_t* player)
{
    statenum_t	newstate;

    if (player->pendingweapon == wp_nochange)
	player->pendingweapon = player->readyweapon;

    if (player->pendingweapon == wp_chainsaw)
	S_StartSound (player->mo, sfx_sawup);

    newstate = weaponinfo[player->pendingweapon].upstate;

    player->pendingweapon = wp_nochange;
    player->psprites[ps_weapon].sy = WEAPONBOTTOM;

    P_SetPsprite (player, ps_weapon, newstate);
}

//
// A_Punch
//
void
A_Punch
( player_t*	player,
  pspdef_t*	psp )
{
    angle_t	angle;
    int		damage;
    int		slope;

    damage = (P_Random ()%10+1)<<1;

    if (player->powers[pw_strength])
	damage *= 10;

    angle = player->mo->angle;
    angle += (P_Random()-P_Random())<<18;
    slope = P_AimLineAttack (player->mo, angle, MELEERANGE);
    P_LineAttack (player->mo, angle, MELEERANGE, slope, damage);

    // turn to face target
    if (linetarget)
    {
	S_StartSound (player->mo, sfx_punch);
	player->mo->angle = R_PointToAngle2 (player->mo->x,
					     player->mo->y,
					     linetarget->x,
					     linetarget->y);
    }
}
*/

function A_DoomPunch(actor)
	local angle
	local damage
	local slope

	damage = 2*(DOOM_Random()%10+1)
	angle = actor.angle
	angle = $ + (DOOM_Random()-DOOM_Random())<<18

	DOOM_Fire(actor, MELEERANGE, true, true, 1, damage, damage)
end

function A_DoomSaw(actor)
	local angle
	local damage
	local slope

	damage = 2*(DOOM_Random()%10+1)
	angle = actor.angle
	angle = $ + (DOOM_Random()-DOOM_Random())<<18

	// use meleerange + 1 se the puff doesn't skip the flash
	DOOM_Fire(actor, MELEERANGE + 1, true, true, 1, damage, damage)
end

function A_DoomFirePistol(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom
	DOOM_Fire(actor, MISSILERANGE, pd.refire == 0, true, 1, 5, 15)
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	S_StartSound(actor, sfx_pistol)
	A_DoomGunFlash(actor)
end

function A_DoomFireShotgun(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom
	DOOM_Fire(actor, MISSILERANGE, false, true, 7, 5, 15)
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	S_StartSound(actor, sfx_shotgn)
	A_DoomGunFlash(actor)
end

function A_DoomFireShotgun2(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom
	DOOM_Fire(actor, MISSILERANGE, false, FRACUNIT*71/10, 20, 5, 15)
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 2)
	S_StartSound(actor, sfx_dshtgn)
	A_DoomGunFlash(actor)
end

function A_DoomFireCGun(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom

	DOOM_Fire(actor, MISSILERANGE, pd.refire == 0, true, 1, 5, 15)
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	S_StartSound(actor, sfx_pistol)

	A_DoomGunFlash(actor)

	DOOM_SetFlashState(player, "flash", player.doom.psprites[PSP_WEAPON].frame)
end

function A_DoomFireMissile(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	if not player then return end
	local pd = player.doom
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	DOOM_Fire(actor, MISSILERANGE, true, true, 1, nil, nil, nil, MT_DOOM_ROCKETPROJ)
end

function A_DoomFirePlasma(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom

	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or 1)
	DOOM_Fire(actor, MISSILERANGE, true, true, 1, nil, nil, nil, MT_DOOM_PLASMASHOT)

	A_DoomGunFlash(actor)

	DOOM_SetFlashState(player, "flash", (DOOM_Random()&1) + 1)
end

function A_DoomFireBFG(actor, var1, var2, weapon)
	local player = actor.mo and actor or actor.player
	local pd = player.doom
	pd.ammo[weapon.ammotype] = $ - (weapon.shotcost or doom.bfgshotcost)
	DOOM_Fire(actor, MISSILERANGE, true, true, 1, nil, nil, nil, MT_DOOM_BFGBALL)
end

function A_CyberAttack(actor)
	if not actor.target then return end
	A_DoomFaceTarget(actor)
	DOOM_SpawnMissile(actor, actor.target, MT_ROCKET)
end

function A_DoomBruisAttack(actor)
    local damage

    if (not actor.target) then
		return
	end

    A_FaceTarget(actor);
    if (P_CheckMeleeRange (actor)) then
		S_StartSound (actor, sfx_claw);
		damage = (DOOM_Random()%8+1)*3;
		DOOM_DamageMobj(actor.target, actor, actor, damage);
		return
    end


    // launch a missile
    DOOM_SpawnMissile(actor, actor.target, MT_DOOM_BARONFIREBALL)
end

function A_DoomSentinelRefire(actor)
	-- TODO
	A_CPosRefire(actor)
end

function A_Hoof(actor)
	S_StartSound(actor, sfx_hoof)
	A_DoomChase(actor)
end

function A_Metal(actor)
	S_StartSound(actor, sfx_metal)
	A_DoomChase(actor)
end

function A_MBFDetonate()

end

function A_MBFMushroom()

end

function A_MBFSpawn()

end

function A_MBFTurn()

end

function A_MBFFace()

end

function A_MBFScratch()

end

function A_MBFPlaySound()

end

function A_MBFRandomJump()

end

function A_MBFLineEffect()

end

---@param actor mobj_t
function A_MBFDie(actor)
	actor.doom.health = 1
	actor.doom.armor = 0
	DOOM_DamageMobj(actor, nil, nil, 1, nil, 0)
end

function doom.getVars(actor)
	local state = doom.extradata[states[actor.state]]
	local daArray = {}
	for i = 1, 8 do
		daArray[i] = state["var" .. i]
	end
	return daArray
end

function A_MBFWeaponProjectile(actor)
	local vars = doom.getVars(actor)
	local thingId = vars[1]
	local angle = vars[2]
	local pitch = vars[3]
	local hoffset = vars[4]
	local voffset = vars[5]
end