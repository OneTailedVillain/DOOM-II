doom.hexenLineActions = {
	[10] = {
		name = "Door_Close", -- Cashing this in early
		/*
		    tag: Tag of affected sector
    speed: How quickly the door closes
    lighttag: Tag of sector to perform a gradual lighting effect in

Lowers the ceiling of all affected sectors to the floor. If tag is 0, then the sector on the line's back side is used.

If lighttag is non-zero a gradual lighting effect is done in the tagged sectors. The light is gradually changed between the darkest neighboring sector when the door is fully closed and the brightest neighboring sector when the door is fully open. 
*/
		---@param line line_t
		action = function(line, tag, speed, lighttag, arg4, arg5)
			if tag == 0 then
				doom.addThinker(line.backside.sector, {type = "door", action = "close", speed = speed})
			else
				for sector in sectors.tagged(tag) do
					doom.addThinker(sector, {type = "door", action = "close", speed = speed})
				end
			end
/*
			not yet
			if lighttag != 0 then
				for sector in sectors.tagged(lighttag) do
					doom.addThinker(sector, {type = "light", action = "sectorgradual", sector = line.backsector, minheight = line.backsector.floorheight, maxheight = line.backsector.ceilingheight, minlight = line.backsector.lightlevel, maxlight = line.frontsector.lightlevel})
				end
			end
*/
		end
	},

	[11] = {
		name = "Door_Open",
		/*
		    tag: Tag of affected sector
	speed: How quickly the door opens
	lighttag: Tag of sector to perform a gradual lighting effect in the tagged sectors. The light is gradually changed between the darkest neighboring sector when the door is fully closed and the brightest neighboring sector when the door is fully open.
	*/
		---@param line line_t
		action = function(line, tag, speed, lighttag, arg4, arg5)
			if tag == 0 then
				doom.addThinker(line.backside.sector, {type = "door", action = "open", speed = speed})
			else
				for sector in sectors.tagged(tag) do
					doom.addThinker(sector, {type = "door", action = "open", speed = speed})
				end
			end
		end
	},

	[12] = {
		name = "Door_Raise",
		/*
		    tag: Tag of affected sector
    speed: How quickly the door raises
    lighttag: Tag of sector to perform a gradual lighting effect in
*/
		---@param line line_t
		action = function(line, tag, speed, lighttag, arg4, arg5)
			if tag == 0 then
				doom.addThinker(line.backside.sector, {type = "door", action = "opendcls", speed = speed})
			else
				for sector in sectors.tagged(tag) do
					doom.addThinker(sector, {type = "door", action = "opendcls", speed = speed})
				end
			end
		end
	},
}
