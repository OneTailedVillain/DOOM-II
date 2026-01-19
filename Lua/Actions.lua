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

function A_DoomLook(actor)
	local secdata = doom.sectordata and doom.sectordata[actor.subsector.sector]
	local targ = secdata and secdata.soundtarget
	actor.threshold = 0 // any shot will wake up

	local gotoseeyou = false

	if (targ and targ.valid) and (targ.flags & MF_SHOOTABLE) then
		actor.target = targ

		if (actor.flags2 & MF2_AMBUSH) then
			if P_CheckSight(actor, actor.target) then
				gotoseeyou = true
			end
		else
			gotoseeyou = true
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
/*
		if actor.type == MT_SPIDER or actor.type == MT_CYBORG then
			S_StartSound(nil, sound) -- full volume
		else
			S_StartSound(actor, sound)
		end
*/
		S_StartSound(actor, sound)
	end

	actor.state = actor.info.seestate
	actor.reactiontime = 8
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
    if (dist > 200)
	dist = 200;
	end

    if (actor.type == MT_DOOM_CYBERDEMON and dist > 160) then
		dist = 160;
	end

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

		-- convert both to fixed degrees
		local a = AngleFixed(actor.angle)
		local target = AngleFixed(actor.movedir << 29)

		local delta = a - target

		-- turn 45 degrees toward desired direction
		if delta > 0 then
			actor.angle = FixedAngle(a - 45*FRACUNIT)
		elseif delta < 0 then
			actor.angle = FixedAngle(a + 45*FRACUNIT)
		end
	end

	// No valid target
	if not actor.target or not (actor.target.flags & MF_SHOOTABLE) then
		if DOOM_LookForPlayers(actor, true) then
			return
		end

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
		S_StartSound (actor, actor.info.painsound)
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

function A_DoomPunch(actor, var1, var2, weapon)
	local player = actor.player
	if player == nil then return end
	local mult = player.doom.powers[pw_strength] and 10 or 1
	DOOM_Fire(player, MELEERANGE, 0, 0, 1, 2 * mult, 20 * mult, nil, nil, nil, nil, nil, weapon.hitsound)
	P_NoiseAlert(actor, actor)
end

function A_SawHit(actor, var1, var2, weapon)
	local player = actor.player
	if player == nil then return end
	A_ChainSawSound(actor, sfx_sawful)
	A_DoomPunch(actor, var1, var2, weapon)
end

-- Cut-down definitions for SPECIFICALLY enemies
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
		firesound = sfx_rocket,
		shootmobj = MT_DOOM_ROCKETPROJ,
	},
}

function A_DoomFire(actor, isPlayer, weaponDef, weapon)
    -- Determine if this is a player or enemy
    local isPlayerActor = actor.player ~= nil
    local player = actor.player
    
    if isPlayerActor then
		local wepProperties = weaponDef or {}
        -- Player logic
		--P_NoiseAlert(actor, actor)
        local funcs = P_GetMethodsForSkin(player)
        local curAmmo = funcs.getCurAmmo(player)
        local curType = funcs.getCurAmmoType(player)

		if type(curAmmo) != "boolean" then
			if curAmmo - weapon.shotcost < 0 then return end
		end

		if weapon.firesound then
			S_StartSound(actor, weapon.firesound)
		end

		P_NoiseAlert(actor, actor)

		if not wepProperties.noFlash and weapon.states.flash then
			player.doom.flashframe = 1
			player.doom.flashtics = weapon.states.flash[1].tics
			actor.state = S_DOOM_PLAYER_FLASH1
			local nextDef = weapon.states.flash[1]
			if nextDef.action then
				nextDef.action(player.mo, nextDef.var1, nextDef.var2, DOOM_GetWeaponDef(player))
			end
		end

        local spread

        if weapon.noinitfirespread and not player.doom.refire then
            spread = {horiz = 0, vert = 0}
        else
            spread = weapon.spread
        end

        funcs.setAmmoFor(player, curType, curAmmo - weapon.shotcost)

        DOOM_Fire(player, weapon.maxdist or MISSILERANGE, weapon.spread.horiz or 0, weapon.spread.vert or 0, weapon.pellets or 1, weapon.damage[1], weapon.damage[2], weapon.damage[3], weapon.shootmobj, weapon.shootflags2, weapon.shootfuse, weapon.firefunc, weapon.hitsound)
    else
		local weapon = doom.predefinedWeapons[weaponDef or 1]
        -- Enemy logic
        S_StartSound(actor, weapon.firesound)
        DOOM_Fire(actor, weapon.maxdist or MISSILERANGE, weapon.spread and weapon.spread.horiz or 0, weapon.spread and weapon.spread.vert or 0, weapon.pellets or 1, weapon.damage[1], weapon.damage[2], weapon.damage[3], weapon.shootmobj, weapon.shootflags2, weapon.shootfuse, weapon.firefunc, weapon.hitsound)
    end
end

function A_DoomGunFlash(actor, var1, var2, weapon)
	local player = actor.player
	if weapon.states.flash then
		player.doom.flashframe = 1
		player.doom.flashtics = weapon.states.flash[1].tics
		actor.state = S_DOOM_PLAYER_FLASH1
	end
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
		and (player.doom.wishwep == nil or player.doom.wishwep == player.doom.curwep)

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

local function HLExplode(actor, range, source)
	if not (actor and actor.valid) then return end -- Ensure the actor exists

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
		DOOM_DamageMobj(foundmobj, source, source, damage)
	end

	-- Process nearby objects
	searchBlockmap("objects", DamageAndBoostNearby,
		actor,
		actor.x - range, actor.x + range,
		actor.y - range, actor.y + range
	)
end

function A_DoomExplode(actor)
	HLExplode(actor, 128*FRACUNIT, actor.target)
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
    -- configurable fallbacks (tweak to match your environment if needed)
    local LOWERSPEED = LOWERSPEED or 6           -- analogous to C LOWERSPEED
    local WEAPONBOTTOM = WEAPONBOTTOM or 128    -- psprite bottom offset
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
    -- In your codebase the pending weapon was called `pendingweapon` in C; here we use `mobj.doom.wishwep`.
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

	DOOM_SpawnMissile(actor, actor.target, MT_TROOPSHOT)
end

/*
void
A_WeaponReady
( player_t*	player,
  pspdef_t*	psp )
{	
    statenum_t	newstate;
    int		angle;
    
    // get out of attack state
    if (player->mo->state == &states[S_PLAY_ATK1]
	|| player->mo->state == &states[S_PLAY_ATK2] )
    {
	P_SetMobjState (player->mo, S_PLAY);
    }
    
    if (player->readyweapon == wp_chainsaw
	&& psp->state == &states[S_SAW])
    {
	S_StartSound (player->mo, sfx_sawidl);
    }
    
    // check for change
    //  if player is dead, put the weapon away
    if (player->pendingweapon != wp_nochange || !player->health)
    {
	// change weapon
	//  (pending weapon should allready be validated)
	newstate = weaponinfo[player->readyweapon].downstate;
	P_SetPsprite (player, ps_weapon, newstate);
	return;	
    }
    
    // check for fire
    //  the missile launcher and bfg do not auto fire
    if (player->cmd.buttons & BT_ATTACK)
    {
	if ( !player->attackdown
	     || (player->readyweapon != wp_missile
		 && player->readyweapon != wp_bfg) )
	{
	    player->attackdown = true;
	    P_FireWeapon (player);		
	    return;
	}
    }
    else
	player->attackdown = false;
    
    // bob the weapon based on movement speed
    angle = (128*leveltime)&FINEMASK;
    psp->sx = FRACUNIT + FixedMul (player->bob, finecosine[angle]);
    angle &= FINEANGLES/2-1;
    psp->sy = WEAPONTOP + FixedMul (player->bob, finesine[angle]);
}
*/

function A_DoomWeaponReady(actor, action, actionvars, weapondef)
	local player = actor.player
	local funcs = P_GetMethodsForSkin(player)
	local curHealth = funcs.getHealth(player)

	if actor.state == S_DOOM_PLAYER_ATTACK1
	or actor.state == S_DOOM_PLAYER_FLASH1 then
		actor.state = S_PLAY_STND
	end

	-- Play idle sound (once when entering ready)
	if weapondef.idlesound then
		S_StartSound(actor, weapondef.idlesound)
	end

	-- Call additional custom action if provided
	if action and type(action) == "function" then
		local var1 = actionvars and actionvars.var1
		local var2 = actionvars and actionvars.var2
		action(actor, var1, var2)
	end
	local noPendingSwitch =
		(not player.doom.switchingweps)
		and (player.doom.wishwep == nil or player.doom.wishwep == player.doom.curwep)

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
	local bobAngleY = ((128 * leveltime) & 4095) << 19
	player.doom.bobx = FixedMul(player.hl1wepbob or 0, cos(bobAngleX))
	player.doom.boby = FixedMul(player.hl1wepbob or 0, sin(bobAngleY))
end

function A_DoomCheckReload(actor, var1, var2, weapon)
    -- Determine if this is a player or enemy
    local isPlayerActor = isPlayer or (actor.player ~= nil)
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
				DOOM_AddThinker(sector, doom.lineActions[data.special])
			end
		end
	end
end

function A_DoomKeenDeath(actor)
	local noSurvivors = checkAliveTypes(MT_DOOM_KEEN)
	if noSurvivors then
		for sector in sectors.tagged(666) do
			DOOM_AddThinker(sector, doom.lineActions[31])
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
	local sound = sfx_pldeth
	-- Source code seems to suggest that hideth is locked to doom ii?
	-- GZDoom says otherwise, though
	if
		-- doom.gamemode == "commercial" and 
		actor.doom.health < -50 then
		sound = sfx_pdiehi
	end

	S_StartSound(actor, sound)
end