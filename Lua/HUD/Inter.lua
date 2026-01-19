local timer = 0

local anims_by_eps = {
	-- epsd 0 (index 0)
	[0] = {
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={224,104} },
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={184,160} },
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={112,136} },
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={72,112}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={88,96}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={64,48}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={192,40} },
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={136,16} },
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={80,16}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={64,24}	},
	},

	-- epsd 1 (index 1)
	[1] = {
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=1 },
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=2 },
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=3 },
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=4 },
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=5 },
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=6 },
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=7 },
		{ type="LEVEL", period=TICRATE/3, nanims=3, loc={192,144}, data1=8 }, -- j=7
		{ type="LEVEL", period=TICRATE/3, nanims=1, loc={128,136}, data1=8 }, -- j=8 (note DOOM special hack uses j=4 frames)
	},

	-- epsd 2 (index 2)
	[2] = {
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={104,168} },
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={40,136}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={160,96}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={104,80}	},
		{ type="ALWAYS", period=TICRATE/3, nanims=3, loc={120,32}	},
		{ type="ALWAYS", period=TICRATE/4, nanims=3, loc={40,0}		}, -- note different period
	}
}

local youAreHere = {
		// Episode 0 World Map
		{
	{ 185, 164 },	// location of level 0 (CJ)
	{ 148, 143 },	// location of level 1 (CJ)
	{ 69, 122 },	// location of level 2 (CJ)
	{ 209, 102 },	// location of level 3 (CJ)
	{ 116, 89 },	// location of level 4 (CJ)
	{ 166, 55 },	// location of level 5 (CJ)
	{ 71, 56 },	// location of level 6 (CJ)
	{ 135, 29 },	// location of level 7 (CJ)
	{ 71, 24 }	// location of level 8 (CJ)
		},

		// Episode 1 World Map should go here
		{
	{ 254, 25 },	// location of level 0 (CJ)
	{ 97, 50 },	// location of level 1 (CJ)
	{ 188, 64 },	// location of level 2 (CJ)
	{ 128, 78 },	// location of level 3 (CJ)
	{ 214, 92 },	// location of level 4 (CJ)
	{ 133, 130 },	// location of level 5 (CJ)
	{ 208, 136 },	// location of level 6 (CJ)
	{ 148, 140 },	// location of level 7 (CJ)
	{ 235, 158 }	// location of level 8 (CJ)
		},

		// Episode 2 World Map should go here
		{
	{ 156, 168 },	// location of level 0 (CJ)
	{ 48, 154 },	// location of level 1 (CJ)
	{ 174, 95 },	// location of level 2 (CJ)
	{ 265, 75 },	// location of level 3 (CJ)
	{ 130, 48 },	// location of level 4 (CJ)
	{ 279, 23 },	// location of level 5 (CJ)
	{ 198, 48 },	// location of level 6 (CJ)
	{ 140, 25 },	// location of level 7 (CJ)
	{ 281, 136 }	// location of level 8 (CJ)
		}

}

local epsAnims = {}

-- Call once when starting the intermission for the current internalEpisode:
local function init_eps_anims(v)
    for _, a in ipairs(epsAnims) do
        a.ctr = 0
        if a.type == "ALWAYS" then
            a.nexttic = timer + 1 + (v.RandomByte() % a.period) -- approximate Doom's random phase
        elseif a.type == "RANDOM" then
            -- data1 = period deviation, data2 = base pause like Doom
            a.nexttic = timer + 1 + (a.data2 or 0) + (v.RandomRange(0, (a.data1 or 1)-1))
        elseif a.type == "LEVEL" then
            a.nexttic = timer + 1
        end
    end
end

-- Call each tick before drawing
local function update_eps_anims(v, internalEpisode, player)
    for i, a in ipairs(epsAnims) do
        if timer >= a.nexttic then
            if a.type == "ALWAYS" then
                a.ctr = (a.ctr + 1) % a.nanims
                a.nexttic = timer + a.period
            elseif a.type == "RANDOM" then
                a.ctr = (a.ctr + 1)
                if a.ctr >= a.nanims then
                    a.ctr = -1
                    a.nexttic = timer + (a.data2 or 0) + v.RandomRange(0, (a.data1 or 1)-1)
                else
                    a.nexttic = timer + a.period
                end
            elseif a.type == "LEVEL" then
                -- Doom's hack: only animate if next-level matches AND not the special blocking condition
                local currentLevelIndex = ((gamemap - 1) % 8) + 1
                local animIndex = i - 1 -- if you need the 0-based index
				-- Only animate if this level matches AND we're not in the special blocking case
				local isSpecialCase = (player.doom.intstate == 12 and (i-1) == 7)
				if (not isSpecialCase) and (currentLevelIndex == a.data1) then
					if a.ctr < 0 then a.ctr = 0 end
					a.ctr = min(a.ctr + 1, a.nanims - 1)
					a.nexttic = timer + a.period
				end
            end
        end
    end
end

local WI_TITLEY = 2
local SP_STATSX	= 50
local SP_STATSY = 50
local SP_TIMEX = 16
local SP_TIMEY = 200 - 32 

local doom2MapToPatch = {
	"CWILV00",
	"CWILV01",
	"CWILV02",
	"CWILV03",
	"CWILV04",
	"CWILV05",
	"CWILV06",
	"CWILV07",
	"CWILV08",
	"CWILV09",
	"CWILV10",
	"CWILV11",
	"CWILV12",
	"CWILV13",
	"CWILV14",
	"CWILV15",
	"CWILV16",
	"CWILV17",
	"CWILV18",
	"CWILV19",
	"CWILV20",
	"CWILV21",
	"CWILV22",
	"CWILV23",
	"CWILV24",
	"CWILV25",
	"CWILV26",
	"CWILV27",
	"CWILV28",
	"CWILV29",
	"CWILV30",
	"CWILV31",
}

local doom1MapToPatch = {
	"WILV00",
	"WILV01",
	"WILV02",
	"WILV03",
	"WILV04",
	"WILV05",
	"WILV06",
	"WILV07",
	"WILV10",
	"WILV11",
	"WILV12",
	"WILV13",
	"WILV14",
	"WILV15",
	"WILV16",
	"WILV17",
	"WILV20",
	"WILV21",
	"WILV22",
	"WILV23",
	"WILV24",
	"WILV25",
	"WILV26",
	"WILV27",
	"WILV30",
	"WILV31",
	"WILV32",
	"WILV33",
	"WILV34",
	"WILV35",
	"WILV36",
	"WILV37",
}

doom1MapToPatch[41] = "WILV08"
doom1MapToPatch[42] = "WILV18"
doom1MapToPatch[43] = "WILV28"
doom1MapToPatch[43] = "WILV38"

-- Helper: draws a number with leading zeros using cached patches
local function drawNum(v, x, y, num, digits)
	-- digits = minimum digits (e.g. 2 for "09")
	local str = string.format("%0"..digits.."d", num)
	for i = #str, 1, -1 do
		local ch = str:sub(i, i)
		local patch = v.cachePatch("WINUM"..ch) -- adjust to your font prefix
		if patch then
			x = x - patch.width
			v.draw(x, y, patch)
		end
	end
	return x
end

-- Equivalent of WI_drawTime
local function WI_drawTime(v, x, y, t)
	if (t or -1) < 0 then return end

	local colon = v.cachePatch("WICOLON") -- colon graphic
	local sucks = v.cachePatch("WISUCKS") -- sucks graphic

	if t <= 61*59 then
		local div = 1
		repeat
			local n = (t / div) % 60
			x = drawNum(v, x, y, n, 2) - colon.width

			div = div * 60

			-- draw colon if needed
			if div == 60 or (t / div) > 0 then
				v.draw(x, y, colon)
			end
		until (t / div) == 0
	else
		v.draw(x - sucks.width, y, sucks)
	end
end

local function drawIntermission(v, player)
	local inter = player.doom.intstate
	local levPatch = doom.isdoom1 and doom1MapToPatch or doom2MapToPatch
	if inter >= 11 then
		levPatch = levPatch[gamemap + 1]
		local levelname = v.cachePatch("WIENTER")
		local y = WI_TITLEY
		v.draw((320 - levelname.width)/2, y, levelname)
		y = $ + (5*levelname.height)/4
		local finpatch = v.cachePatch(levPatch)
		v.draw((320 - finpatch.width)/2, y, finpatch)
		return
	end
	levPatch = levPatch[gamemap]
	local lh = (3*v.cachePatch("WINUM0").height)/2
	local levelname = v.cachePatch(levPatch)
	local y = WI_TITLEY
	v.draw((320 - levelname.width)/2, y, levelname)
	y = y + (5*levelname.height)/4
	local finpatch = v.cachePatch("WIF")
	v.draw((320 - finpatch.width)/2, y, finpatch)
	
	local killspatch = v.cachePatch("WIOSTK")
	local x = SP_STATSX
	local y = SP_STATSY
	v.draw(x, y, killspatch)
	if inter >= 2 then
		drawInFont(v, (320 - x)*FRACUNIT, y*FRACUNIT, FRACUNIT, "WI", player.cnt_kills[1] .. "%", 0, "right")
	end

	local killspatch = v.cachePatch("WIOSTI")
	y = $ + lh
	v.draw(x, y, killspatch)
	if inter >= 4 then
		drawInFont(v, (320 - x)*FRACUNIT, y*FRACUNIT, FRACUNIT, "WI", player.cnt_kills[2] .. "%", 0, "right")
	end

	local killspatch = v.cachePatch("WISCRT2")
	y = $ + lh
	v.draw(x, y, killspatch)
	if inter >= 6 then
		drawInFont(v, (320 - x)*FRACUNIT, y*FRACUNIT, FRACUNIT, "WI", player.cnt_kills[3] .. "%", 0, "right")
	end

	local time =  v.cachePatch("WITIME")
	local sucks = v.cachePatch("WISUCKS")
	local par =   v.cachePatch("WIPAR")
	
	v.draw(SP_TIMEX, SP_TIMEY, time)
	v.draw(320/2 + SP_TIMEX, SP_TIMEY, par)
	
	WI_drawTime(v, 320/2 - SP_TIMEX, SP_TIMEY, player.doom.cnt_time)
	if doom.isdoom1 and (gamemap/9) < 3 then
		WI_drawTime(v, 320 - SP_TIMEX, SP_TIMEY, player.doom.cnt_par)
	end
end

/*
    V_DrawPatch(SP_TIMEX, SP_TIMEY, FB, time);
    WI_drawTime(SCREENWIDTH/2 - SP_TIMEX, SP_TIMEY, cnt_time);

    if (wbs->epsd < 3)
    {
	V_DrawPatch(SCREENWIDTH/2 + SP_TIMEX, SP_TIMEY, FB, par);
	WI_drawTime(SCREENWIDTH - SP_TIMEX, SP_TIMEY, cnt_par);
    }
*/

hud.add(function(v, player)
	if not doom.intermission then return end
	if doom.textscreen and doom.textscreen.active then return end
	v.drawFill(nil, nil, nil, nil, 0)
	if doom.isdoom1 then
		local internalEpisode = gamemap/10
		v.draw(0, 0, v.cachePatch("WIMAP" .. internalEpisode))

		-- draw animations for the current internal episode
		epsAnims = anims_by_eps[internalEpisode] or {}
		if epsAnims[1].ctr == nil then
			init_eps_anims(v)
		end
		update_eps_anims(v, internalEpisode, player)

		for j=1, #epsAnims do
			local a = epsAnims[j]
			if a and a.ctr and a.ctr >= 0 then
				-- Doom's MONDO hack: epsd 1 and j==9 (0-based j==8) use anim 4's frames
				local drawJ = (j-1)
				if internalEpisode == 1 and (j-1) == 8 then drawJ = 4 end
				local name = string.format("WIA%d%.2d%.2d", internalEpisode, drawJ, a.ctr)
				local patch = v.cachePatch(name)
				if patch then v.draw(a.loc[1], a.loc[2], patch) end
			end
		end
	else
		v.draw(0, 0, v.cachePatch("INTERPIC"))
	end
	drawIntermission(v, player)
	timer = $ + 1
end, "game")