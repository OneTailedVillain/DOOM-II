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

SafeFreeSlot("SPR_VILE", "sfx_vilatk", "sfx_flamst", "sfx_vildth", "sfx_vipain", "sfx_flame")
local name = "Archvile"

local object = {
	health = 700,
	radius = 20,
	height = 56,
	mass = 500,
	speed = 15,
	painchance = 200,
	doomednum = 64,
	seesound = sfx_bgsit1,
	activesound = sfx_bgact,
	painsound = sfx_popain,
	deathsound = sfx_vildth,
	sprite = SPR_VILE,
	doomflags = DF_COUNTKILL
}

function A_DoomVileAttack(actor)
	local fire
	local an

	if not actor.target then return end
	A_DoomFaceTarget(actor)

	if not (P_CheckSight(actor, actor.target)) then return end
	S_StartSound(actor, sfx_barexp)
	DOOM_DamageMobj(actor.target, actor, actor, 20)
	actor.target.momz = 1000*FRACUNIT/actor.target.info.mass

	an = actor.angle
	fire = actor.tracer
	if not fire then return end

	// move the fire between the vile and the player
	local targetX = actor.target.x - FixedMul(24*FRACUNIT, cos(an))
	local targetY = actor.target.y - FixedMul(24*FRACUNIT, sin(an))
	P_MoveOrigin(fire, targetX, targetY, fire.z)
	DOOM_RadiusAttack(fire, actor, 70)
end

/* PIT_VileCheck
//
// PIT_VileCheck
// Detect a corpse that could be raised.
//
mobj_t*		corpsehit;
mobj_t*		vileobj;
fixed_t		viletryx;
fixed_t		viletryy;

boolean PIT_VileCheck (mobj_t*	thing)
{
    int		maxdist;
    boolean	check;
	
    if (!(thing->flags & MF_CORPSE) )
	return true;	// not a monster
    
    if (thing->tics != -1)
	return true;	// not lying still yet
    
    if (thing->info->raisestate == S_NULL)
	return true;	// monster doesn't have a raise state
    
    maxdist = thing->info->radius + mobjinfo[MT_VILE].radius;
	
    if ( abs(thing->x - viletryx) > maxdist
	 || abs(thing->y - viletryy) > maxdist )
	return true;		// not actually touching
		
    corpsehit = thing;
    corpsehit->momx = corpsehit->momy = 0;
    corpsehit->height <<= 2;
    check = P_CheckPosition (corpsehit, corpsehit->x, corpsehit->y);
    corpsehit->height >>= 2;

    if (!check)
	return true;		// doesn't fit here
		
    return false;		// got one, so stop checking
}
*/

/* A_VileChase
//
// A_VileChase
// Check for ressurecting a body
//
void A_VileChase (mobj_t* actor)
{
    int			xl;
    int			xh;
    int			yl;
    int			yh;
    
    int			bx;
    int			by;

    mobjinfo_t*		info;
    mobj_t*		temp;
	
    if (actor->movedir != DI_NODIR)
    {
	// check for corpses to raise
	viletryx =
	    actor->x + actor->info->speed*xspeed[actor->movedir];
	viletryy =
	    actor->y + actor->info->speed*yspeed[actor->movedir];

	xl = (viletryx - bmaporgx - MAXRADIUS*2)>>MAPBLOCKSHIFT;
	xh = (viletryx - bmaporgx + MAXRADIUS*2)>>MAPBLOCKSHIFT;
	yl = (viletryy - bmaporgy - MAXRADIUS*2)>>MAPBLOCKSHIFT;
	yh = (viletryy - bmaporgy + MAXRADIUS*2)>>MAPBLOCKSHIFT;
	
	vileobj = actor;
	for (bx=xl ; bx<=xh ; bx++)
	{
	    for (by=yl ; by<=yh ; by++)
	    {
		// Call PIT_VileCheck to check
		// whether object is a corpse
		// that canbe raised.
		if (!P_BlockThingsIterator(bx,by,PIT_VileCheck))
		{
		    // got one!
		    temp = actor->target;
		    actor->target = corpsehit;
		    A_FaceTarget (actor);
		    actor->target = temp;
					
		    P_SetMobjState (actor, S_VILE_HEAL1);
		    S_StartSound (corpsehit, sfx_slop);
		    info = corpsehit->info;
		    
		    P_SetMobjState (corpsehit,info->raisestate);
		    corpsehit->height <<= 2;
		    corpsehit->flags = info->flags;
		    corpsehit->health = info->spawnhealth;
		    corpsehit->target = NULL;

		    return;
		}
	    }
	}
    }

    // Return to normal attack.
    A_Chase (actor);
}
*/

/* A_VileStart
//
// A_VileStart
//
void A_VileStart (mobj_t* actor)
{
    S_StartSound (actor, sfx_vilatk);
}


//
// A_Fire
// Keep fire in front of player unless out of sight
//
void A_Fire (mobj_t* actor);

void A_StartFire (mobj_t* actor)
{
    S_StartSound(actor,sfx_flamst);
    A_Fire(actor);
}

void A_FireCrackle (mobj_t* actor)
{
    S_StartSound(actor,sfx_flame);
    A_Fire(actor);
}

void A_Fire (mobj_t* actor)
{
    mobj_t*	dest;
    unsigned	an;
		
    dest = actor->tracer;
    if (!dest)
	return;
		
    // don't move it if the vile lost sight
    if (!P_CheckSight (actor->target, dest) )
	return;

    an = dest->angle >> ANGLETOFINESHIFT;

    P_UnsetThingPosition (actor);
    actor->x = dest->x + FixedMul (24*FRACUNIT, finecosine[an]);
    actor->y = dest->y + FixedMul (24*FRACUNIT, finesine[an]);
    actor->z = dest->z;
    P_SetThingPosition (actor);
}
*/

local corpsehit
local vileobj
local viletryx
local viletryy

local function PIT_VileCheck(thing)
	local maxdist
	local check

	if not (thing.doom.flags & DF_CORPSE) then
		return true // not a monster
	end

	if thing.tics != -1 then
		return true // not lying still yet
	end

	if thing.info.raisestate == S_NULL then
		return true // monster doesn't have a raise state
	end

	maxdist = thing.info.radius + mobjinfo[MT_DOOM_ARCHVILE].radius

	if (abs(thing.x - viletryx) > maxdist) or (abs(thing.y - viletryy) > maxdist) then
		return true // not actually touching
	end

	corpsehit = thing
	corpsehit.momx = 0
	corpsehit.momy = 0

	corpsehit.height = $ << 2

	check = P_CheckPosition(corpsehit, corpsehit.x, corpsehit.y)
	corpsehit.height = $ >> 2

	if not check then
		return true // doesn't fit here
	else
		return false // got one, so stop checking
	end
end

local xspeed = {FRACUNIT,47000,0,-47000,-FRACUNIT,-47000,0,47000}
local yspeed = {0,47000,FRACUNIT,47000,0,-47000,-FRACUNIT,-47000}

local MAXRADIUS = 32*FRACUNIT

function A_DoomVileChase(actor)
	local xl
	local xh
	local yl
	local yh

	local bx
	local by

	local info
	local temp

	if actor.movedir != DI_NODIR and actor.movedir != nil then
		// check for corpses to raise
		viletryx =
			actor.x + object.speed*xspeed[actor.movedir + 1]
		viletryy =
			actor.y + object.speed*yspeed[actor.movedir + 1]

		searchBlockmap("objects", function(refmobj, foundmobj)
			if not PIT_VileCheck(foundmobj) then return true end
		end, actor,
					viletryx - MAXRADIUS*2, viletryx + MAXRADIUS*2,
					viletryy - MAXRADIUS*2, viletryy + MAXRADIUS*2)
/*
		    temp = actor->target;
		    actor->target = corpsehit;
		    A_FaceTarget (actor);
		    actor->target = temp;
					
		    P_SetMobjState (actor, S_VILE_HEAL1);
		    S_StartSound (corpsehit, sfx_slop);
		    info = corpsehit->info;
		    
		    P_SetMobjState (corpsehit,info->raisestate);
		    corpsehit->height <<= 2;
		    corpsehit->flags = info->flags;
		    corpsehit->health = info->spawnhealth;
		    corpsehit->target = NULL;
*/
		// got one!
		if corpsehit then
			local temp = actor.target
			actor.target = corpsehit
			A_DoomFaceTarget(actor)
			actor.target = temp
			actor.state = S_DOOM_ARCHVILE_HEAL1
			S_StartSound(corpsehit, sfx_slop)
			info = corpsehit.info
			corpsehit.state = info.raisestate
			corpsehit.height = corpsehit.height << 2
			corpsehit.doom.flags = info.flags
			corpsehit.health = info.spawnhealth
		end
	end

	// Return to normal attack.
	A_DoomChase(actor)
end

local ANGLETOFINESHIFT = 19

function A_DoomVileStart(actor)
	S_StartSound(actor, sfx_vilatk)
end

function A_DoomFire(actor)
	local dest = actor.tracer
	if not dest then return end

	// don't move it if the vile lost sight
	if not P_CheckSight(actor.target, dest) then return end

	local an = dest.angle >> ANGLETOFINESHIFT

	P_SetOrigin(actor, dest.x + FixedMul(24*FRACUNIT, cos(an)), dest.y + FixedMul(24*FRACUNIT, sin(an)), dest.z)
end

/*
//
// A_VileTarget
// Spawn the hellfire
//
void A_VileTarget (mobj_t*	actor)
{
    mobj_t*	fog;
	
    if (!actor->target)
	return;

    A_FaceTarget (actor);

    fog = P_SpawnMobj (actor->target->x,
		       actor->target->x,
		       actor->target->z, MT_FIRE);
    
    actor->tracer = fog;
    fog->target = actor;
    fog->tracer = actor->target;
    A_Fire (fog);
}
*/

function A_DoomVileTarget(actor)
	if not actor.target then return end

	A_DoomFaceTarget(actor)

	local fog = P_SpawnMobj(actor.target.x, actor.target.y, actor.target.z, MT_DOOM_ARCHVILEFIRE)
	actor.tracer = fog
	fog.target = actor
	fog.tracer = actor.target
	A_DoomFire(fog)
end

local states = {
	stand = {
		{action = A_DoomLook, frame = A, tics = 10},
		{action = A_DoomLook, frame = B, tics = 10, next = "stand"}
	},
	chase = {
		{action = A_DoomVileChase, frame = A, tics = 3},
		{action = A_DoomVileChase, frame = A, tics = 3},
		{action = A_DoomVileChase, frame = B, tics = 3},
		{action = A_DoomVileChase, frame = B, tics = 3},
		{action = A_DoomVileChase, frame = C, tics = 3},
		{action = A_DoomVileChase, frame = C, tics = 3},
		{action = A_DoomVileChase, frame = D, tics = 3},
		{action = A_DoomVileChase, frame = D, tics = 3},
		{action = A_DoomVileChase, frame = E, tics = 3},
		{action = A_DoomVileChase, frame = E, tics = 3},
		{action = A_DoomVileChase, frame = F, tics = 3},
		{action = A_DoomVileChase, frame = F, tics = 3, next = "chase"},
	},
	attack = {
		{action = A_DoomVileStart, frame = E, tics = 8},
		{action = A_DoomFaceTarget, frame = E, tics = 8},
		{action = A_DoomVileTarget, frame = F, tics = 8},
		{action = A_DoomFaceTarget, frame = G, tics = 8},
		{action = A_DoomFaceTarget, frame = H, tics = 8},
		{action = A_DoomFaceTarget, frame = I, tics = 8},
		{action = A_DoomFaceTarget, frame = J, tics = 8},
		{action = A_DoomFaceTarget, frame = K, tics = 8},
		{action = A_DoomFaceTarget, frame = L, tics = 8},
		{action = A_DoomFaceTarget, frame = M, tics = 8},
		{action = A_DoomFaceTarget, frame = N, tics = 8},
		{action = A_DoomVileAttack, frame = O, tics = 6},
		{action = nil, frame = P, tics = 20, next = "chase"},
	},
	pain = {
		{action = nil,        frame = Q, tics = 5},
		{action = A_DoomPain, frame = Q, tics = 5, next = "chase"},
	},
	die = {
		{action = nil,          frame = Q, tics = 7},
		{action = A_DoomScream, frame = R, tics = 7},
		{action = A_DoomFall,   frame = S, tics = 7},
		{action = nil,          frame = T, tics = 7},
		{action = nil,          frame = U, tics = 7},
		{action = nil,          frame = V, tics = 7},
		{action = nil,          frame = W, tics = 7},
		{action = nil,          frame = X, tics = 7},
		{action = nil,          frame = Y, tics = 7},
		{action = nil,          frame = Z, tics = -1},
	},
	heal = {
		{action = nil, frame = R_Char2Frame("0")|FF_FULLBRIGHT, tics = 10},
		{action = nil, frame = R_Char2Frame("1")|FF_FULLBRIGHT, tics = 10},
		{action = nil, frame = R_Char2Frame("2")|FF_FULLBRIGHT, tics = 10},
	},
}

DefineDoomActor(name, object, states)

SafeFreeSlot("SPR_FIRE", "sfx_vilatk", "sfx_flamst", "sfx_flame")
local name = "ArchVileFire"

local object = {
	radius = 16,
	height = 32,
	doomednum = -1,
	sprite = SPR_FIRE,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPTHING
}

/*
//
// A_VileStart
//
void A_VileStart (mobj_t* actor)
{
    S_StartSound (actor, sfx_vilatk);
}


//
// A_Fire
// Keep fire in front of player unless out of sight
//
void A_Fire (mobj_t* actor);

void A_StartFire (mobj_t* actor)
{
    S_StartSound(actor,sfx_flamst);
    A_Fire(actor);
}

void A_FireCrackle (mobj_t* actor)
{
    S_StartSound(actor,sfx_flame);
    A_Fire(actor);
}

void A_Fire (mobj_t* actor)
{
    mobj_t*	dest;
    unsigned	an;
		
    dest = actor->tracer;
    if (!dest)
	return;
		
    // don't move it if the vile lost sight
    if (!P_CheckSight (actor->target, dest) )
	return;

    an = dest->angle >> ANGLETOFINESHIFT;

    P_UnsetThingPosition (actor);
    actor->x = dest->x + FixedMul (24*FRACUNIT, finecosine[an]);
    actor->y = dest->y + FixedMul (24*FRACUNIT, finesine[an]);
    actor->z = dest->z;
    P_SetThingPosition (actor);
}

*/

-- Not to be confused with A_DoomFire... heh heh... sigh
function A_DoomAFire(actor)
	local dest = actor.tracer
	if not dest then return end
	// don't move it if the vile lost sight
	if not P_CheckSight(actor.target, dest) then return end
	local an = dest.angle
	P_SetOrigin(actor, dest.x + FixedMul(24*FRACUNIT, cos(an)), dest.y + FixedMul(24*FRACUNIT, sin(an)), dest.z)
end

function A_DoomStartFire(actor)
	S_StartSound(actor, sfx_flame)
	A_DoomAFire(actor)
end

function A_DoomFireCrackle(actor)
	S_StartSound(actor, sfx_flame)
	A_DoomAFire(actor)
end

local states = {
    {frame = A|FF_FULLBRIGHT, tics = 2, action = A_DoomStartFire}, --1  (FIRE A)
    {frame = B|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --2  (FIRE B)
    {frame = A|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --3  (FIRE A)
    {frame = B|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --4  (FIRE B)
    {frame = C|FF_FULLBRIGHT, tics = 2, action = A_DoomFireCrackle},--5 (FIRE C)
    {frame = B|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --6  (FIRE B)
    {frame = C|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --7  (FIRE C)
    {frame = B|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --8  (FIRE B)
    {frame = C|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --9  (FIRE C)
    {frame = D|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --10 (FIRE D)
    {frame = C|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --11 (FIRE C)
    {frame = D|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --12 (FIRE D)
    {frame = C|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --13 (FIRE C)
    {frame = D|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --14 (FIRE D)
    {frame = E|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --15 (FIRE E)
    {frame = D|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --16 (FIRE D)
    {frame = E|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --17 (FIRE E)
    {frame = D|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --18 (FIRE D)
    {frame = E|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --19 (FIRE E)
    {frame = F|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --20 (FIRE F)
    {frame = E|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --21 (FIRE E)
    {frame = F|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --22 (FIRE F)
    {frame = E|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --23 (FIRE E)
    {frame = F|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --24 (FIRE F)
    {frame = G|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --25 (FIRE G)
    {frame = H|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --26 (FIRE H)
    {frame = G|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --27 (FIRE G)
    {frame = H|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --28 (FIRE H)
    {frame = G|FF_FULLBRIGHT, tics = 2, action = A_DoomAFire},     --29 (FIRE G)
    {frame = H|FF_FULLBRIGHT, tics = -1, action = A_DoomAFire},     --30 (FIRE H)
}

DefineDoomDeco(name, object, states, onPickup)