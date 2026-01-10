local function FreeDoomStates(name, stateDefs)
    local up     = name:upper()
    local prefix = "DOOM_" .. up

    -- Build a list of all state globals to freeslot
    local needed = {}
    for stateKey, frames in pairs(stateDefs) do
        local stU = stateKey:upper()
        for i = 1, #frames do
            needed[#needed+1] = string.format("S_%s_%s%d", prefix, stU, i)
        end
    end

    -- Freeslot all the state globals
    local slots = SafeFreeSlot(unpack(needed))

    -- Set up nextstate references properly
    for stateKey, frames in pairs(stateDefs) do
        local stU = stateKey:upper()
        for i, f in ipairs(frames) do
			local thisName = string.format("S_%s_%s%d", prefix, stU, i)

			local nextslot

			-- If user explicitly sets numeric next (like next = S_PLAY_STND)
			if type(f.next) == "number" then
				print("NEXT STATE FOR " .. thisName .. " IS CONSTANT")
				nextslot = f.next

			-- If user uses named doom-state next (like next = "move")
			elseif type(f.next) == "string" then
				local nextName = string.format(
					"S_%s_%s%d",
					prefix,
					f.next:upper(),
					tonumber(f.nextframe) or 1
				)
				nextslot = slots[nextName]

			-- Otherwise: fall back to automatic chaining
			elseif frames[i+1] then
				local nextName = string.format("S_%s_%s%d", prefix, stU, i+1)
				nextslot = slots[nextName]
			end

			print(thisName .. " NEXT SLOT: " .. tostring(nextslot))

			f.nextstate = nextslot or S_NULL

			states[ slots[thisName] ] = {
				sprite    = f.sprite or (objData and objData.sprite),
				frame     = f.frame,
				tics      = f.tics,
				action    = f.action,
				var1      = f.var1,
				var2      = f.var2,
				nextstate = f.nextstate
			}
        end
    end
end

SafeFreeSlot(
    "SPR_PLSS","SPR_PLSE",
    "sfx_plasma","sfx_firxpl",
    "MT_DOOM_PLASMASHOT"
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

local function A_Tracer(actor)
	if leveltime & 3 then return end

	P_SpawnMobj(actor.x, actor.y, actor.z, MT_NULL)
end

local plasmastates = {
    shot = {
        {sprite = SPR_PLSS, frame = A, tics = 6},
        {sprite = SPR_PLSS, frame = B, tics = 6, next = "shot"},
    },

    explode = {
        {sprite = SPR_PLSE, frame = A, tics = 4},
        {sprite = SPR_PLSE, frame = B, tics = 4},
        {sprite = SPR_PLSE, frame = C, tics = 4},
        {sprite = SPR_PLSE, frame = D, tics = 4},
        {sprite = SPR_PLSE, frame = E, tics = 4},
    },
}

FreeDoomStates("Plasma", plasmastates)

mobjinfo[MT_DOOM_PLASMASHOT] = {
    spawnstate = S_DOOM_PLASMA_SHOT1,
    seesound   = sfx_plasma,
    deathsound = sfx_firxpl,
    deathstate = S_DOOM_PLASMA_EXPLODE1,

    speed      = 25*FRACUNIT,
    radius     = 13*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 5,
    dispoffset = 5,

    flags = MF_NOGRAVITY|MF_MISSILE,
}