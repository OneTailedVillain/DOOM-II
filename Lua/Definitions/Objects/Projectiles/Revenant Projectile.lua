SafeFreeSlot(
    "SPR_PLSS","SPR_PLSE",
    "sfx_plasma","sfx_firxpl",
    "MT_DOOM_REVENANT_PROJECTILE"
)
/*
void A_Tracer (mobj_t* actor)
{
    angle_t	exact;
    fixed_t	dist;
    fixed_t	slope;
    mobj_t*	dest;
    mobj_t*	th;
		
    if (gametic & 3)
	return;
    
    // spawn a puff of smoke behind the rocket		
    P_SpawnPuff (actor->x, actor->y, actor->z);
	
    th = P_SpawnMobj (actor->x-actor->momx,
		      actor->y-actor->momy,
		      actor->z, MT_SMOKE);
    
    th->momz = FRACUNIT;
    th->tics -= P_Random()&3;
    if (th->tics < 1)
	th->tics = 1;
    
    // adjust direction
    dest = actor->tracer;
	
    if (!dest || dest->health <= 0)
	return;
    
    // change angle	
    exact = R_PointToAngle2 (actor->x,
			     actor->y,
			     dest->x,
			     dest->y);

    if (exact != actor->angle)
    {
	if (exact - actor->angle > 0x80000000)
	{
	    actor->angle -= TRACEANGLE;
	    if (exact - actor->angle < 0x80000000)
		actor->angle = exact;
	}
	else
	{
	    actor->angle += TRACEANGLE;
	    if (exact - actor->angle > 0x80000000)
		actor->angle = exact;
	}
    }
	
    exact = actor->angle>>ANGLETOFINESHIFT;
    actor->momx = FixedMul (actor->info->speed, finecosine[exact]);
    actor->momy = FixedMul (actor->info->speed, finesine[exact]);
    
    // change slope
    dist = P_AproxDistance (dest->x - actor->x,
			    dest->y - actor->y);
    
    dist = dist / actor->info->speed;

    if (dist < 1)
	dist = 1;
    slope = (dest->z+40*FRACUNIT - actor->z) / dist;

    if (slope < actor->momz)
	actor->momz -= FRACUNIT/8;
    else
	actor->momz += FRACUNIT/8;
}
*/

-- TRACEANGLE is the angle change per tic for tracking
local TRACEANGLE = FixedAngle(FRACUNIT*7/2) -- approximately 3.5 degrees

---@param actor mobj_t The projectile actor
local function A_Tracer(actor)
	-- Only trace every 4 tics (same as DOOM engine behavior)
	if leveltime & 3 then return end
	
	-- Spawn a tracer puff at the projectile's current position
	local puff = P_SpawnMobj(actor.x, actor.y, actor.z, MT_DOOM_REVENANT_TRACER)
	
	-- Ensure target exists and is alive
	if not actor.tracer or actor.tracer.health <= 0 then
		return
	end
	
	local dest = actor.tracer
	
	-- Calculate the exact angle toward the target
	local exact = R_PointToAngle2(actor.x, actor.y, dest.x, dest.y)
	
	-- Adjust the projectile's angle toward the target gradually
	if exact ~= actor.angle then
		local angle_diff = exact - actor.angle
		
		-- Handle angle wrapping (angles > 0x80000000 wrap around)
		if angle_diff > ANGLE_180 then
			-- Target is "behind" us, turn left
			actor.angle = actor.angle - TRACEANGLE
			if (exact - actor.angle) < ANGLE_180 then
				actor.angle = exact
			end
		else
			-- Target is "ahead", turn right
			actor.angle = actor.angle + TRACEANGLE
			if (exact - actor.angle) > ANGLE_180 then
				actor.angle = exact
			end
		end
	end
	
	-- Update the projectile's velocity based on the new angle and speed
	local speed = actor.info.speed
	actor.momx = speed * cos(actor.angle)
	actor.momy = speed * sin(actor.angle)
	
	-- Calculate distance to target for slope adjustment
	local dx = dest.x - actor.x
	local dy = dest.y - actor.y
	local dist = P_AproxDistance(dx, dy)
	
	-- Normalize distance to speed ratio
	dist = dist / speed
	if dist < FRACUNIT then
		dist = FRACUNIT
	end
	
	-- Calculate slope (z adjustment) toward the target
	-- Add 40 fracunits to account for head height
	local slope = (dest.z + 40*FRACUNIT - actor.z) / dist
	
	-- Gradually adjust vertical velocity toward the slope
	if slope < actor.momz then
		actor.momz = actor.momz - FRACUNIT/8
	else
		actor.momz = actor.momz + FRACUNIT/8
	end
end

---@type StateDefs
local plasmastates = {
    shot = {
        {sprite = SPR_PLSS, frame = A, tics = 6, action = A_Tracer},
        {sprite = SPR_PLSS, frame = B, tics = 6, action = A_Tracer, next = "shot"},
    },

    explode = {
        {sprite = SPR_PLSE, frame = A, tics = 4},
        {sprite = SPR_PLSE, frame = B, tics = 4},
        {sprite = SPR_PLSE, frame = C, tics = 4},
        {sprite = SPR_PLSE, frame = D, tics = 4},
        {sprite = SPR_PLSE, frame = E, tics = 4},
    },
}

FreeDoomStates("RevenantProj", plasmastates)

mobjinfo[MT_DOOM_REVENANT_PROJECTILE] = {
    spawnstate = S_DOOM_REVENANTPROJ_SHOT1,
    seesound   = sfx_plasma,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_REVENANTPROJ_EXPLODE1,
    speed      = 25*FRACUNIT,
    radius     = 13*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 5,
    dispoffset = 5,

    flags = MF_NOGRAVITY|MF_MISSILE,
}