---@type videolib
local v

local hudflags = V_SNAPTOLEFT|V_SNAPTOBOTTOM

local charToFrame = {
	["-"] = 10,
}

-- SRB2 automatically truncates with no chance of proper ceiling,
-- so we have to do it ourselves
local function FakeCeilingDiv(a, b)
	return (a + b - 1) / b
end

---@param drawer videolib
---@param player player_t
hud.add(function(drawer, player)
	if v == nil then
		v = drawer
	end
	if DOOM_InAutomap() then return end
	if not player.mo then return end
	if player.mo.skin != "dpecmegaman" then return end
	if doom.dontDrawHUDCondits() then return end

	local pmdoom = player.mo.doom
	local health = FakeCeilingDiv(pmdoom.health, 4)
	local maxhealth = FakeCeilingDiv(pmdoom.maxhealth, 4)

	local maxpips = maxhealth
	if health > maxpips then maxpips = health end
	for i = 1, maxpips do
		v.draw(30, 120 - (i * 2), v.cachePatch("MM-BARTICK"))
		if i > health then
			v.draw(30, 120 - (i * 2), v.cachePatch("MM-BARTICK"), V_SUBTRACT)
		end
	end
end)