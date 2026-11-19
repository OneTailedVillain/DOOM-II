SafeFreeSlot(
    "SPR_FATB","SPR_FBXP",
    "sfx_skeatk","sfx_barexp",
    "MT_DOOM_REVENANT_PROJECTILE"
)

local TRACEANGLE = 0x0C000000
local MELEERANGE = 64*FRACUNIT

local function AngleDiff(a, b)
	return ((a - b + 0x80000000) & 0xFFFFFFFF) - 0x80000000
end

local function SpawnPuff(x, y, z)
	z = z + (P_RandomByte() - P_RandomByte()) * 1024 -- vanilla: (P_Random()-P_Random())<<10

	local puff = P_SpawnMobj(x, y, z, MT_DOOM_BULLETPUFF)
	if not (puff and puff.valid) then return end

	if doom.attackrange ~= nil and doom.attackrange == MELEERANGE then
		puff.state = S_DOOM_BPUFF_PUFF3
	else
		puff.state = S_DOOM_BPUFF_PUFF1
	end

	puff.momz = FRACUNIT
	puff.tics = puff.tics - (P_RandomByte() & 3)
	if puff.tics < 1 then puff.tics = 1 end

	return puff
end

---@param actor mobj_t The projectile
function A_DoomTracer(actor)
	if (leveltime & 3) ~= 0 then return end

	SpawnPuff(actor.x, actor.y, actor.z)

	local smoke = P_SpawnMobj(actor.x - actor.momx, actor.y - actor.momy, actor.z, MT_DOOM_REVENANT_TRACER)
	if smoke and smoke.valid then
		smoke.momz = FRACUNIT
		smoke.tics = smoke.tics - (P_RandomByte() & 3)
		if smoke.tics < 1 then smoke.tics = 1 end
	end

	local dest = actor.tracer
	if not (dest and dest.valid) or dest.health <= 0 then return end

	local exact = R_PointToAngle2(actor.x, actor.y, dest.x, dest.y)
	if exact ~= actor.angle then
		if AngleDiff(exact, actor.angle) < 0 then
			actor.angle = actor.angle - TRACEANGLE
			if AngleDiff(exact, actor.angle) >= 0 then
				actor.angle = exact
			end
		else
			actor.angle = actor.angle + TRACEANGLE
			if AngleDiff(exact, actor.angle) < 0 then
				actor.angle = exact
			end
		end
	end

	local speed = actor.info.speed
	actor.momx = FixedMul(speed, cos(actor.angle))
	actor.momy = FixedMul(speed, sin(actor.angle))

	local dist = P_AproxDistance(dest.x - actor.x, dest.y - actor.y)
	if speed ~= 0 then
		dist = dist / speed
	end
	if dist < 1 then dist = 1 end

	local slope = (dest.z + 40*FRACUNIT - actor.z) / dist

	if slope < actor.momz then
		actor.momz = actor.momz - FRACUNIT/8
	else
		actor.momz = actor.momz + FRACUNIT/8
	end
end

local tracerstates = {
    shot = {
        {sprite = SPR_FATB, frame = A|FF_FULLBRIGHT, tics = 2, action = A_DoomTracer},
        {sprite = SPR_FATB, frame = B|FF_FULLBRIGHT, tics = 2, action = A_DoomTracer, next = "shot"},
    },

    explode = {
        {sprite = SPR_FBXP, frame = A|FF_FULLBRIGHT, tics = 8},
        {sprite = SPR_FBXP, frame = B|FF_FULLBRIGHT, tics = 6},
        {sprite = SPR_FBXP, frame = C|FF_FULLBRIGHT, tics = 4},
    },
}

FreeDoomStates("RevenantProj", tracerstates)

mobjinfo[MT_DOOM_REVENANT_PROJECTILE] = {
    spawnstate = S_DOOM_REVENANTPROJ_SHOT1,
    seesound   = sfx_skeatk,
    deathsound = sfx_barexp,
    deathstate = S_DOOM_REVENANTPROJ_EXPLODE1,
    speed      = 10*FRACUNIT,
    radius     = 11*FRACUNIT,
    height     = 8*FRACUNIT,
    damage     = 10,
    dispoffset = 5,

    flags = MF_NOGRAVITY|MF_MISSILE,
    doomflags = DF_DROPOFF,
}

mobjinfo[MT_DOOM_REVENANT_PROJECTILE].doomname = "RevenantFireball"