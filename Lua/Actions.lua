states[S_DOOM_IMPFIRE] = {
    sprite    = SPR_BAL1,
    frame     = A|FF_ANIMATE,
	tics      = -1,
	var1      = 1,
	var2      = 4,
	nextstate = S_NULL
}

mobjinfo[MT_TROOPSHOT] = {
	spawnstate   = S_DOOM_IMPFIRE,
	seesound     = sfx_firsht,
	speed        = 10 * FRACUNIT,
	radius       = 6 * FRACUNIT,
	height       = 8 * FRACUNIT,
	flags        = MF_MISSILE|MF_NOGRAVITY,
}

local gameskill = 3
local sk_nightmare = 4

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

	if targ and (targ.flags & MF_SHOOTABLE) then
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
	
/*
    if (actor->type == MT_UNDEAD)
		if (dist < 196)	
			return false;	// close for fist attack
		end
		dist >>= 1;
    end

    if (actor->type == MT_CYBORG
	|| actor->type == MT_SPIDER
	|| actor->type == MT_SKULL)
    {
	dist >>= 1;
    }
*/  
    if (dist > 200)
	dist = 200;
	end
/*
    if (actor.type == MT_CYBORG && dist > 160)
	dist = 160;
	end
*/
if (DOOM_Random() < dist)
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
	if actor.movedir and actor.movedir < 8 then
		actor.angle = $ & ANGLE_315
		delta = actor.angle - (actor.movedir << 29)

		if delta > 0 then
			actor.angle = $ - ANGLE_45
		elseif delta < 0 then
			actor.angle = $ + ANGLE_45
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
		if gameskill ~= sk_nightmare and not fastparm then
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
		if gameskill < sk_nightmare and not fastparm and actor.movecount then
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
	if actor.movecount < 0 or not P_Move(actor, actor.info.speed / FRACUNIT) then
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

/*
action void A_ReFire(statelabel flash = null, bool autoSwitch = true)
{
	let player = player;
	bool pending;

	if (NULL == player)
	{
		return;
	}
	pending = player.PendingWeapon != WP_NOCHANGE && (player.WeaponState & WF_REFIRESWITCHOK);
	if ((player.cmd.buttons & BT_ATTACK)
		&& !player.ReadyWeapon.bAltFire && !pending && player.health > 0)
	{
		player.refire++;
		player.mo.FireWeapon(ResolveState(flash));
	}
	else if ((player.cmd.buttons & BT_ALTATTACK)
		&& player.ReadyWeapon.bAltFire && !pending && player.health > 0)
	{
		player.refire++;
		player.mo.FireWeaponAlt(ResolveState(flash));
	}
	else
	{
		player.refire = 0;
		player.ReadyWeapon.CheckAmmo (player.ReadyWeapon.bAltFire? Weapon.AltFire : Weapon.PrimaryFire, autoSwitch);
	}
}
*/

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

local function P_RecursiveSound(sec, soundblocks, emitter)
	doom.sectordata[sec] = $ or {validcount = -999, soundtraversed = -999}
	local data = doom.sectordata[sec]

    if data.validcount == doom.validcount and data.soundtraversed <= soundblocks + 1 then
        return
    end

    data.validcount = validcount
    data.soundtraversed = soundblocks + 1
    data.soundtarget = emitter

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

        if (line.flags & ML_EFFECT2) ~= 0 then
            if soundblocks == 0 then
                P_RecursiveSound(other, 1, emitter)
            end
        else
            P_RecursiveSound(other, soundblocks, emitter)
        end
    end
end

local function P_NoiseAlert(target, emitter)
	doom.validcount = $ + 1
	soundblocks = 0
	P_RecursiveSound(emitter.subsector.sector, soundblocks, target)
end

function A_ChainSawSound(actor, sfx)
	local sawsounds = {sfx_sawidl, sfx_sawful, sfx_sawup, sfx_sawhit}
	for _, sound in ipairs(sawsounds) do
		S_StopSoundByID(actor, sound)
	end
	S_StartSound(actor, sfx)
end

function A_DoomPunch(actor)
	local player = actor.player
	if player == nil then return end
	local mult = player.doom.powers[pw_strength] and 10 or 1
	DOOM_Fire(player, MELEERANGE, 0, 0, 1, 5 * mult, 15 * mult)
end

function A_SawHit(actor)
	local player = actor.player
	if player == nil then return end
	A_DoomPunch(actor)
	local mult = player.doom.powers[pw_strength] and 10 or 1
	A_ChainSawSound(actor, sfx_sawful)
	DOOM_Fire(player, MELEERANGE, 0, 0, 1, 5 * mult, 15 * mult)
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
}

function A_DoomFire(actor, isPlayer, weaponDef, weapon)
    -- Determine if this is a player or enemy
    local isPlayerActor = isPlayer or (actor.player ~= nil)
    local player = actor.player
    
    if isPlayerActor then
        -- Player logic
		--P_NoiseAlert(actor, actor)
        local funcs = P_GetMethodsForSkin(player)
        local curAmmo = funcs.getCurAmmo(player)
        local curType = funcs.getCurAmmoType(player)

        if curAmmo - weapon.shotcost < 0 then return end

		if weapon.firesound then
			S_StartSound(actor, weapon.firesound)
		end

        local spread

        if weapon.noinitfirespread and not player.doom.refire then
            spread = {horiz = 0, vert = 0}
        else
            spread = weapon.spread
        end

        funcs.setAmmoFor(player, curType, curAmmo - weapon.shotcost)

        DOOM_Fire(player, weapon.maxdist or MISSILERANGE, weapon.spread.horiz or 0, weapon.spread.vert or 0, weapon.pellets or 1, weapon.damage[1], weapon.damage[2])
    else
		local weapon = doom.predefinedWeapons[weaponDef or 1]
        -- Enemy logic
        S_StartSound(actor, weapon.firesound)
        
        -- For enemies, we need to create a mock player structure for Doom_Fire
        -- or modify Doom_Fire to accept enemy actors directly
        -- This assumes Doom_Fire can handle nil player for enemies
        DOOM_Fire(actor, weapon.maxdist or MISSILERANGE, weapon.spread.horiz or 0, weapon.spread.vert or 0, weapon.pellets or 1, weapon.damage[1], weapon.damage[2])
    end
end

function A_DoomReFire(actor)
	local player = actor.player
	if player == nil then return end

	local wepDef = DOOM_GetWeaponDef(player)
	local curWepAmmo = player.doom.ammo[wepDef.ammotype]
	local ammoNeeded = wepDef.shotcost

	if max(curWepAmmo, 0) >= ammoNeeded and (player.cmd.buttons & BT_ATTACK) and not player.doom.switchtimer and player.mo.doom.health > 0 then
		player.doom.refire = ($ or 0) + 1
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
		local dist = HL_GetDistance(refmobj, foundmobj)
		if dist > range then return end -- Only affect objects within range

		if not foundmobj or foundmobj == refmobj then return end -- Skip if no object or self
		if not P_CheckSight(refmobj, foundmobj) then return end -- Skip if we don't have a clear view
		if not (foundmobj.flags & MF_SHOOTABLE) then return end -- Don't attempt to hurt things that shouldn't be hurt

		-- Recheck in case it died from thrust or other edge case
		if not foundmobj then return end

		-- Calculate and apply damage
		-- Max damage = range / FRACUNIT, scaled by proximity
		local damage = max(1, (range / FRACUNIT) * (range - dist) / range)
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