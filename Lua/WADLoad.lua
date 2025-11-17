local LINEHEIGHT = 16

local function fnv1a(str)
	local hash = 2166136261
	for i = 1, #str do
		hash = hash ^^ string.byte(str, i)
		hash = (hash * 16777619)
	end
	return hash
end

local function hashEndoom(tbl)
	-- join into one string for stable hashing
	return fnv1a(table.concat(tbl, "\n"))
end

-- Registry of known ENDOOM hashes -> game identifiers
local EndoomRegistry = {
	srb2 = hashEndoom({
		string.char(20) .. string.char(20) .. "                         Sonic Robo Blast",
		"                                  2",
		"",
		"                         By Sonic Team Junior",
		"",
		"                      http://stjr.segasonic.net",
		"",
		"    Come to our website to download                               ________",
		"    expansion packs, other's add-ons                                       |",
		"    and instructions on how to make                                        |",
		"    your own SRB2 levels!                                                  |",
		"                                                                           |",
		"",
		"",
		"",
		"",
		"    Sonic the Hedgehog, all characters",
		"    and related indica are (c) Sega",
		"    Enterprises, Ltd. Sonic Team Jr. is",
		"    not affiliated with Sega in any way.",
		"",
		"",
		"",
		"",
		"",
	}),
	chex1 = hashEndoom({
		"",
		"",
		"",
		"                          The Mission Continues...",
		"",
		"",
		"                             www.chexquest.com",
		"",
		"",
		"                      Thanks for playing Chex(R) Quest!",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
	}),
	ultdoom = hashEndoom({
		"       " .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223),
		"                    DOOM, a hellish 3-D game by id Software.",
		"        " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
		"                       YOU ARE PLAYING THE ULTIMATE DOOM.",
		"",
		"         If you haven't paid for DOOM, you are playing illegally. That",
		"        means you owe us money. Of course, a guy like you probably owes",
		"         a lot of people money--your friends, maybe even your parents.",
		"          Stop being a freeloader and register DOOM. Call us now at",
		"                          1-800-IDGAMES. We can help!",
		"",
		"          We hope you enjoy playing DOOM. We enjoyed making it for you.",
		"             If you have any problems playing DOOM, please call our",
		"                    technical support line at (970) 522-1797.",
		"",
		"                               id SOFTWARE IS:",
		"        Programming: John Carmack, Mike Abrash, John Romero, Dave Taylor",
		"              Art: Adrian Carmack, Kevin Cloud    BIZ: Jay Wilbur",
		"        Design: Sandy Petersen, John Romero, American McGee, Shawn Green",
		"                 Technical Support: Shawn Green, American McGee",
		"",
		"                   Special Thanks: Tim Willits, John Anderson",
		"",
		"",
		"",
	}),
	shareware = hashEndoom({
		"      " .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223),
		"        DOOM: Knee-Deep in the Dead a hellish 3-D game by id Software.",
		"        " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
		"        Sure, don't order DOOM. Sit back with your milk and cookies and",
		"        let the universe go to Hell. Don't face the onslaught of demons",
		"        and spectres that await you on The Shores of Hell. Avoid the",
		"        terrifying confrontations with cacodemons and lost souls that",
		"        infest Inferno.",
		"",
		"        Or, act like a man! Slap a few shells into your shotgun and",
		"        let's kick some demonic butt. Order the entire DOOM trilogy now!",
		"        After all, you'll probably end up in Hell eventually. Shouldn't",
		"        you know your way around before you make the extended visit?",
		"",
		"        To order DOOM, call toll-free 1-800-IDGAMES. If you'd like to",
		"        purchase DOOM with a check or money order, or if you live",
		"        outside of the USA, please refer to the order information text",
		"        file (order.frm) in your DOOM directory.",
		"",
		"        DOOM, Knee-Deep in the Dead can be freely distributed. Disk",
		"        vendors should refer to the vendor information text file",
		"        (vendor.doc) in your DOOM directory.",
		"      " .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220) .. string.char(220),
		"",
		"",
	}),
	doom1 = hashEndoom({
		"       " .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223),
		"                    DOOM, a hellish 3-D game by id Software.",
		"        " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
		"                 YOU ARE PLAYING THE REGISTERED VERSION OF DOOM.",
		"         If you haven't paid for DOOM, you are playing illegally. That",
		"        means you owe us money. Of course, a guy like you probably owes",
		"         a lot of people money--your friends, maybe even your parents.",
		"          Stop being a freeloader and register DOOM. Call us now at",
		"                          1-800-IDGAMES. We can help!",
		"",
		"        If you have registered DOOM, feel confident that you have done",
		"           the right thing--not only for yourself, but for the World.",
		"          We hope you enjoy playing DOOM. We enjoyed making it for you.",
		"",
		"             If you have any problems playing DOOM, please call our",
		"                    technical support line at (214) 613-0132.",
		"",
		"                        DOOM WAS CREATED BY id SOFTWARE:",
		"              Programming: John Carmack, John Romero, Dave Taylor",
		"                         Art: Adrian Carmack, Kevin Cloud",
		"                   Design: Sandy Petersen      BIZ: Jay Wilbur",
		"                    Tech Support: Shawn Green, American McGee",
		"",
		"",
		"",
	}),
	doom2 = hashEndoom({
		"       " .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223),
		"                           DOOM II(tm), Hell on Earth",
		"        " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
		"            created by id Software and distributed by GT interactive",
		"",
		"                Thanks for purchasing DOOM II. We hope you have as",
		"           much fun playing it as we had making it. If you don't, then",
		"             something is really wrong with you and you're different",
		"              and strange. All your friends think DOOM II is great.",
		"",
		"                Of course, DOOM II is a trademark of id Software,",
		"          copyright 1994-95, so don't mess with it. Remember, if you",
		"          are playing a pirated copy of DOOM II you are going to HELL.",
		"          Buy it and avoid an eternity with all the other freeloaders.",
		"           If you have any problems playing DOOM II, please call our",
		"                  technical support line at (212) 686-9432.",
		"",
		"                       DOOM II WAS CREATED BY id SOFTWARE:",
		"              Programming: John Carmack, John Romero, Dave Taylor",
		"                         Art: Adrian Carmack, Kevin Cloud",
		"                   Design: Sandy Petersen      BIZ: Jay Wilbur",
		"                            BizAssist: Donna Jackson",
		"                 Design and Support: Shawn Green, American McGee",
		"",
		"",
	})
}

local function getMFFlagsForNumber(num)
    local result = 0
    for bitmask, flag in pairs(doom.dehackedpointers.flags) do
        if flag.type == "MF" and (num & bitmask) ~= 0 then
            result = result | bitmask
        end
    end
    return result
end

local function getMF2FlagsForNumber(num)
    local result = 0
    for bitmask, flag in pairs(doom.dehackedpointers.flags) do
        if flag.type == "MF2" and (num & bitmask) ~= 0 then
            result = result | bitmask
        end
    end
    return result
end

local function getDFFlagsForNumber(num)
    local result = 0
    for bitmask, flag in pairs(doom.dehackedpointers.flags) do
        if flag.type == "DF" and (num & bitmask) ~= 0 then
            result = result | bitmask
        end
    end
    return result
end

local function weaponStateHandler(pointers, number, data, path)
	local path = pointers.frametowepstate[number]
	local state = doom.weapons[path[1]]
	/*
		path[1] = wepname
		path[2] = wepstate
		path[3] = wepframe
		DEHACKED uses nextframe
	*/
	if not state then
		print("WARNING: INVALID WEAPON NAME '" .. tostring(path[1]) .. "'!")
		return
	end
	state = state.states[path[2]]
	if not state then
		print("WARNING: INVALID STATE '" .. tostring(path[2]) .. "' FOR WEAPON '"  .. tostring(path[1]) .. "'!")
		return
	end
	state = state[path[3]]
	if not state then
		print("WARNING: INVALID FRAME '" .. tostring(path[3]) .. "' FOR FRAME '"  .. tostring(path[2]) .. "' FOR WEAPON '"  .. tostring(path[1]) .. "'!")
		return
	end

	-- Set basic frame properties
	state.tics = data.duration or $
	state.sprite = pointers.sprites[data.spritenumber] or $
	state.frame = data.spritesubnumber or $
/*
	-- Handle nextframe if present
	if data.nextframe and data.nextframe ~= 0 then
		local nextPath = pointers.frametowepstate[data.nextframe]
		if nextPath then
			-- Allow cross-weapon transitions (e.g., chaingun -> supershotgun)
			if nextPath[1] == path[1] then
				-- Same weapon transition
				state.nextstate = nextPath[2]
				state.nextframe = nextPath[3]
				state.nextwep = nil -- Same weapon
			else
				-- Cross-weapon transition
				state.nextstate = nextPath[2]
				state.nextframe = nextPath[3]
				state.nextwep = nextPath[1] -- Different weapon
				print("NOTE: Cross-weapon transition from '" .. path[1] .. "' to '" .. nextPath[1] .. "'")
			end
		else
			-- Invalid frame - treat as state termination
			print("NOTE: DEHACKED nextframe " .. data.nextframe .. " terminates state '" .. path[2] .. "' for weapon '" .. path[1] .. "'")
			state.terminate = true -- Mark this frame as terminating the state
		end
	end
*/
end

local function doLoadingShit()
	print("Checking current add-ons...", doom.basewad)
	doom.patchesLoaded = false -- We'll have to run this back anyhow...

	if HL then
		HL.disableTitleScreen = true
	end

	if doom.isdoom1 then
		doom.titlemenus.menu.entries[1].goto = "episelect"
	end

	-- "This sink is so hard to clean, if only there was an easier way!"
	if doom and doom.dehacked then
		print("applying DEHACKED fields...")
		local deh = doom.dehacked
		local pointers = doom.dehackedpointers
		if deh.ammo then
			if deh.ammo[0] then
				doom.ammos["bullets"].max = deh.ammo[0].maxammo or $
			end
			if deh.ammo[1] then
				doom.ammos["shells"].max = deh.ammo[1].maxammo or $
			end
			if deh.ammo[2] then
				doom.ammos["cells"].max = deh.ammo[2].maxammo or $
			end
			if deh.ammo[3] then
				doom.ammos["rockets"].max = deh.ammo[3].maxammo or $
			end
		end
		if deh.misc then
			local misc = deh.misc[0]
			doom.pistolstartstate.maxhealth = misc.maxhealth or $
			doom.pistolstartstate.maxarmor = misc.maxarmor or $
			doom.soulspheregrant = misc.soulspherehealth or $
			doom.maxsoulsphere = misc.maxsoulsphere or $
			doom.megaspheregrant = misc.megaspherehealth or $
		end
		if deh.things then
			for number, data in pairs(deh.things) do
				local mobjtype = pointers.things[number]
				if mobjtype != nil and mobjinfo[mobjtype] then
					local info = mobjinfo[mobjtype]
					if data.bits then
						info.flags = getMFFlagsForNumber(data.bits)
						info.doomflags = getDFFlagsForNumber(data.bits)
						local mf2flags = getMF2FlagsForNumber(data.bits)
						if mf2flags then
							print("WARNING: DEHACKED THING # " .. tostring(number) .. " HAS BITS CORRESPONDING TO MF2 FLAGS!")
						end
					end
					info.spawnstate = pointers.frames[data.initialframe] or $
					info.deathstate = pointers.frames[data.deathframe] or $
					info.seestate = pointers.frames[data.firstmovingframe] or $
					info.health = data.hitpoints or $
					info.health = (data.speed and data.speed * FRACUNIT) or $
					info.radius = data.width or $
					info.height = data.height or $
					info.mass = data.mass or $
					info.seesound = pointers.frames[data.alertsound] or $
					info.activesound = pointers.frames[data.actionsound] or $
				else
					if mobjtype == nil then
						print("NOTICE: DEHACKED THING # " .. tostring(number) .. " DOESN'T HAVE AN ASSOCIATED POINTER!")
					else
						print("NOTICE: DEHACKED THING # " .. tostring(number) .. " HAS AN INVALID MOBJINFO!")
					end
				end
			end
		end
		if deh.frames then
			for number, data in pairs(deh.frames) do
				if pointers.frametowepstate[number] then
					weaponStateHandler(pointers, number, data, path)
				else
					if pointers.frames[number] then
					
					else
						print("NOTICE: DEHACKED FRAME # " .. tostring(number) .. " DOESN'T HAVE AN ASSOCIATED POINTER!")
					end
				end
			end
		end
	end

	local currentHash = hashEndoom(doom.endoom.text or {})

	-- Match hash against registry
	local matchedGame
	for id, hash in pairs(EndoomRegistry) do
		if currentHash == hash then
			matchedGame = id
			break
		end
	end

	if doom.isdoom1 then
		doom.textscreenmaps = {
			[8]  = {text = "$E1TEXT", secret = false, bg = "EP1CUTSC"},
			[16] = {text = "$E2TEXT", secret = false, bg = "EP2CUTSC"},
			[24] = {text = "$E3TEXT", secret = false, bg = "EP3CUTSC"},
			[32] = {text = "$E4TEXT", secret = false, bg = "EP4CUTSC"},
		}
	else
		doom.textscreenmaps = {
			[6]  = {text = "$C1TEXT", secret = false, bg = "M06CUTSC"},
			[11] = {text = "$C2TEXT", secret = false, bg = "M11CUTSC"},
			[20] = {text = "$C3TEXT", secret = false, bg = "M20CUTSC"},
			[30] = {text = "$C4TEXT", secret = false, bg = "M30CUTSC"},
			[15] = {text = "$C5TEXT", secret = true,  bg = "M15CUTSC"},
			[31] = {text = "$C6TEXT", secret = true,  bg = "M31CUTSC"},
		}
	end

	if matchedGame == "srb2" then
		-- Autopatch SRB2 March 2000 Prototype
		doom.defaultgravity = FRACUNIT/2
		doom.issrb2 = true

		local inf = mobjinfo[MT_DOOM_REDPILLARWITHSKULL]
		inf.radius = 64*FRACUNIT
		inf.height = 1*FRACUNIT
		inf.flags = MF_SOLID|MF_FLOAT|MF_NOGRAVITY|MF_NOSECTOR
		inf.mass = 10000000
		states[S_DOOM_REDPILLARWITHSKULL_1].sprite = SPR_NULL

		local inf = mobjinfo[MT_DOOM_HEALTHBONUS]
		inf.flags = $|MF_NOGRAVITY

		doom.strings = {
			D_DEVSTR = "Development mode ON.\n",
			D_CDROM = "CD-ROM Version: default.cfg from c:\\doomdata\n",
			PRESSKEY = "press a key.",
			PRESSYN = "press y or n.",
			LOADNET = "only the server can do a load net game!\n\npress a key.",
			QLOADNET = "you can't quickload during a netgame!\n\npress a key.",
			QSAVESPOT = "you haven't picked a quicksave slot yet!\n\npress a key.",
			SAVEDEAD = "you can't save if you aren't playing!\n\npress a key.",
			QSPROMPT = "quicksave over your game named\n\n'%s'?\n\npress y or n.",
			QLPROMPT = "do you want to quickload the game named\n\n'%s'?\n\npress y or n.",
			NEWGAME = "you can't start a new game\nwhile in a network game.\n\n",
			NIGHTMARE = "are you sure? this skill level\nisn't even remotely fair.\n\npress y or n.",
			SWSTRING = "this is the shareware version of doom.\n\nyou need to order the entire trilogy.\n\npress a key.",
			MSGOFF = "Messages OFF",
			MSGON = "Messages ON",
			NETEND = "you can't end a netgame!\n\npress a key.",
			ENDGAME = "are you sure you want to end the game?\n\npress y or n.",
			DOSY = "%s\n\n(press y to quit to dos.)",
			DETAILHI = "High detail",
			DETAILLO = "Low detail",
			GAMMALVL0 = "Gamma correction OFF",
			GAMMALVL1 = "Gamma correction level 1",
			GAMMALVL2 = "Gamma correction level 2",
			GAMMALVL3 = "Gamma correction level 3",
			GAMMALVL4 = "Gamma correction level 4",
			EMPTYSTRING = "empty slot",
			GOTARMOR = "Picked up the armor.",
			GOTMEGA = "Picked up the MegaArmor!",
			GOTHTHBONUS = "Picked up a health bonus.",
			GOTARMBONUS = "Picked up an armor bonus.",
			GOTSTIM = "Picked up a stimpack.",
			GOTMEDINEED = "Picked up a medikit that you REALLY need!",
			GOTMEDIKIT = "Picked up a medikit.",
			GOTSUPER = "You found a chaos emerald!",
			GOTBLUECARD = "Picked up a blue keycard.",
			GOTYELWCARD = "Picked up a yellow keycard.",
			GOTREDCARD = "Picked up a red keycard.",
			GOTBLUESKUL = "Picked up a blue skull key.",
			GOTYELWSKUL = "Picked up a yellow skull key.",
			GOTREDSKULL = "Picked up a red skull key.",
			GOTINVUL = "Invincibility!",
			GOTBERSERK = "Berserk!",
			GOTINVIS = "Partial Invisibility",
			GOTSUIT = "Radiation Shielding Suit",
			GOTMAP = "Computer Area Map",
			GOTVISOR = "Light Amplification Visor",
			GOTMSPHERE = "MegaSphere!",
			GOTCLIP = "Picked up a clip.",
			GOTCLIPBOX = "Picked up a box of bullets.",
			GOTROCKET = "Picked up a rocket.",
			GOTROCKBOX = "Picked up a box of rockets.",
			GOTCELL = "Picked up an energy cell.",
			GOTCELLBOX = "Picked up an energy cell pack.",
			GOTSHELLS = "Picked up 4 shotgun shells.",
			GOTSHELLBOX = "Picked up a box of shotgun shells.",
			GOTBACKPACK = "Picked up a backpack full of ammo!",
			GOTBFG9000 = "You got the BFG9000!  Oh, yes.",
			GOTCHAINGUN = "You got the chaingun!",
			GOTCHAINSAW = "A chainsaw!  Find some meat!",
			GOTLAUNCHER = "You got the rocket launcher!",
			GOTPLASMA = "You got the plasma gun!",
			GOTSHOTGUN = "You got the shotgun!",
			GOTSHOTGUN2 = "You got the super shotgun!",
			PD_BLUEO = "You need a blue key to activate this object",
			PD_REDO = "You need a red key to activate this object",
			PD_YELLOWO = "You need a yellow key to activate this object",
			PD_BLUEK = "You need a blue key to open this door",
			PD_REDK = "You need a red key to open this door",
			PD_YELLOWK = "You need a yellow key to open this door",
			GGSAVED = "game saved.",
			HUSTR_MSGU = "[Message unsent]",
			HUSTR_E1M1 = "E1M1: Hangar",
			HUSTR_E1M2 = "E1M2: Nuclear Plant",
			HUSTR_E1M3 = "E1M3: Toxin Refinery",
			HUSTR_E1M4 = "E1M4: Command Control",
			HUSTR_E1M5 = "E1M5: Phobos Lab",
			HUSTR_E1M6 = "E1M6: Central Processing",
			HUSTR_E1M7 = "E1M7: Computer Station",
			HUSTR_E1M8 = "E1M8: Phobos Anomaly",
			HUSTR_E1M9 = "E1M9: Military Base",
			HUSTR_E2M1 = "E2M1: Deimos Anomaly",
			HUSTR_E2M2 = "E2M2: Containment Area",
			HUSTR_E2M3 = "E2M3: Refinery",
			HUSTR_E2M4 = "E2M4: Deimos Lab",
			HUSTR_E2M5 = "E2M5: Command Center",
			HUSTR_E2M6 = "E2M6: Halls of the Damned",
			HUSTR_E2M7 = "E2M7: Spawning Vats",
			HUSTR_E2M8 = "E2M8: Tower of Babel",
			HUSTR_E2M9 = "E2M9: Fortress of Mystery",
			HUSTR_E3M1 = "E3M1: Hell Keep",
			HUSTR_E3M2 = "E3M2: Slough of Despair",
			HUSTR_E3M3 = "E3M3: Pandemonium",
			HUSTR_E3M4 = "E3M4: House of Pain",
			HUSTR_E3M5 = "E3M5: Unholy Cathedral",
			HUSTR_E3M6 = "E3M6: Mt. Erebus",
			HUSTR_E3M7 = "E3M7: Limbo",
			HUSTR_E3M8 = "E3M8: Dis",
			HUSTR_E3M9 = "E3M9: Warrens",
			HUSTR_E4M1 = "E4M1: Hell Beneath",
			HUSTR_E4M2 = "E4M2: Perfect Hatred",
			HUSTR_E4M3 = "E4M3: Sever The Wicked",
			HUSTR_E4M4 = "E4M4: Unruly Evil",
			HUSTR_E4M5 = "E4M5: They Will Repent",
			HUSTR_E4M6 = "E4M6: Against Thee Wickedly",
			HUSTR_E4M7 = "E4M7: And Hell Followed",
			HUSTR_E4M8 = "E4M8: Unto The Cruel",
			HUSTR_E4M9 = "E4M9: Fear",
			HUSTR_1 = "Greenflower Zone Act 1",
			HUSTR_2 = "Greenflower Zone Act 2",
			HUSTR_3 = "Greenflower Zone Act 3",
			HUSTR_4 = "Techno Hill Zone Act 1",
			HUSTR_5 = "Techno Hill Zone Act 2",
			HUSTR_6 = "Techno Hill Zone Act 3",
			HUSTR_7 = "Deep Sea Zone Act 1",
			HUSTR_8 = "Deep Sea Zone Act 2",
			HUSTR_9 = "Deep Sea Zone Act 3",
			HUSTR_10 = "Mine Maze Zone Act 1",
			HUSTR_11 = "Mine Maze Zone Act 2",
			HUSTR_12 = "Mine Maze Zone Act 3",
			HUSTR_13 = "Rocky Mountain Zone Act 1",
			HUSTR_14 = "Rocky Mountain Zone Act 2",
			HUSTR_15 = "Rocky Mountain Zone Act 3",
			HUSTR_16 = "Red Volcano Zone Act 1",
			HUSTR_17 = "Red Volcano Zone Act 2",
			HUSTR_18 = "Red Volcano Zone Act 3",
			HUSTR_19 = "Dark City Zone Act 1",
			HUSTR_20 = "Dark City Zone Act 2",
			HUSTR_21 = "Dark City Zone Act 3",
			HUSTR_22 = "Doomship Zone Act 1",
			HUSTR_23 = "Doomship Zone Act 2",
			HUSTR_24 = "Doomship Zone Act 3",
			HUSTR_25 = "Robotnirock Zone Act 1",
			HUSTR_26 = "Robotnirock Zone Act 2",
			HUSTR_27 = "Robotnirock Zone Act 3",
			HUSTR_28 = "The Final Fight Zone!",
			HUSTR_29 = "Wood Zone",
			HUSTR_30 = "Dust Hill Zone",
			HUSTR_31 = "Speed Highway at Dawn",
			HUSTR_32 = "Hidden Palace Zone",
			PHUSTR_1 = "level 1: congo",
			PHUSTR_2 = "level 2: well of souls",
			PHUSTR_3 = "level 3: aztec",
			PHUSTR_4 = "level 4: caged",
			PHUSTR_5 = "level 5: ghost town",
			PHUSTR_6 = "level 6: baron's lair",
			PHUSTR_7 = "level 7: caughtyard",
			PHUSTR_8 = "level 8: realm",
			PHUSTR_9 = "level 9: abattoire",
			PHUSTR_10 = "level 10: onslaught",
			PHUSTR_11 = "level 11: hunted",
			PHUSTR_12 = "level 12: speed",
			PHUSTR_13 = "level 13: the crypt",
			PHUSTR_14 = "level 14: genesis",
			PHUSTR_15 = "level 15: the twilight",
			PHUSTR_16 = "level 16: the omen",
			PHUSTR_17 = "level 17: compound",
			PHUSTR_18 = "level 18: neurosphere",
			PHUSTR_19 = "level 19: nme",
			PHUSTR_20 = "level 20: the death domain",
			PHUSTR_21 = "level 21: slayer",
			PHUSTR_22 = "level 22: impossible mission",
			PHUSTR_23 = "level 23: tombstone",
			PHUSTR_24 = "level 24: the final frontier",
			PHUSTR_25 = "level 25: the temple of darkness",
			PHUSTR_26 = "level 26: bunker",
			PHUSTR_27 = "level 27: anti-christ",
			PHUSTR_28 = "level 28: the sewers",
			PHUSTR_29 = "level 29: odyssey of noises",
			PHUSTR_30 = "level 30: the gateway of hell",
			PHUSTR_31 = "level 31: cyberden",
			PHUSTR_32 = "level 32: go 2 it",
			THUSTR_1 = "level 1: system control",
			THUSTR_2 = "level 2: human bbq",
			THUSTR_3 = "level 3: power control",
			THUSTR_4 = "level 4: wormhole",
			THUSTR_5 = "level 5: hanger",
			THUSTR_6 = "level 6: open season",
			THUSTR_7 = "level 7: prison",
			THUSTR_8 = "level 8: metal",
			THUSTR_9 = "level 9: stronghold",
			THUSTR_10 = "level 10: redemption",
			THUSTR_11 = "level 11: storage facility",
			THUSTR_12 = "level 12: crater",
			THUSTR_13 = "level 13: nukage processing",
			THUSTR_14 = "level 14: steel works",
			THUSTR_15 = "level 15: dead zone",
			THUSTR_16 = "level 16: deepest reaches",
			THUSTR_17 = "level 17: processing area",
			THUSTR_18 = "level 18: mill",
			THUSTR_19 = "level 19: shipping/respawning",
			THUSTR_20 = "level 20: central processing",
			THUSTR_21 = "level 21: administration center",
			THUSTR_22 = "level 22: habitat",
			THUSTR_23 = "level 23: lunar mining project",
			THUSTR_24 = "level 24: quarry",
			THUSTR_25 = "level 25: baron's den",
			THUSTR_26 = "level 26: ballistyx",
			THUSTR_27 = "level 27: mount pain",
			THUSTR_28 = "level 28: heck",
			THUSTR_29 = "level 29: river styx",
			THUSTR_30 = "level 30: last call",
			THUSTR_31 = "level 31: pharaoh",
			THUSTR_32 = "level 32: caribbean",
			HUSTR_CHATMACRO1 = "I'm ready to kick ro-butt!",
			HUSTR_CHATMACRO2 = "I'm OK.",
			HUSTR_CHATMACRO3 = "I'm not looking too good!",
			HUSTR_CHATMACRO4 = "Help!",
			HUSTR_CHATMACRO5 = "You stink!",
			HUSTR_CHATMACRO6 = "Next time I'll win!",
			HUSTR_CHATMACRO7 = "Come here!",
			HUSTR_CHATMACRO8 = "I'll take care of it.",
			HUSTR_CHATMACRO9 = "Yes",
			HUSTR_CHATMACRO0 = "No",
			HUSTR_TALKTOSELF1 = "You mumble to yourself",
			HUSTR_TALKTOSELF2 = "Who's there?",
			HUSTR_TALKTOSELF3 = "You scare yourself",
			HUSTR_TALKTOSELF4 = "You start to rave",
			HUSTR_TALKTOSELF5 = "You've lost it...",
			HUSTR_MESSAGESENT = "[Message Sent]",
			AMSTR_FOLLOWON = "Follow Mode ON",
			AMSTR_FOLLOWOFF = "Follow Mode OFF",
			AMSTR_GRIDON = "Grid ON",
			AMSTR_GRIDOFF = "Grid OFF",
			AMSTR_MARKEDSPOT = "Marked Spot",
			AMSTR_MARKSCLEARED = "All Marks Cleared",
			STSTR_MUS = "Music Change",
			STSTR_NOMUS = "IMPOSSIBLE SELECTION, you stupid-head!",
			STSTR_DQDON = "Degreelessness Mode On",
			STSTR_DQDOFF = "Degreelessness Mode Off",
			STSTR_KFAADDED = "Gun Cheat Added",
			STSTR_FAADDED = "Ammo (no keys) Added",
			STSTR_NCON = "No Clipping Mode ON",
			STSTR_NCOFF = "No Clipping Mode OFF",
			STSTR_BEHOLD = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp",
			STSTR_BEHOLDX = "Power-up Toggled",
			STSTR_CHOPPERS = "... doesn't suck - GM",
			STSTR_CLEV = "Changing Level...",
			E1TEXT = "Once you beat the big badasses and\nclean out the moon base you're supposed\nto win, aren't you? Aren't you? Where's\nyour fat reward and ticket home? What\nthe hell is this? It's not supposed to\nend this way!\n\nIt stinks like rotten meat, but looks\nlike the lost Deimos base.  Looks like\nyou're stuck on The Shores of Hell.\nThe only way out is through.\n\nTo continue the DOOM experience, play\nThe Shores of Hell and its amazing\nsequel, Inferno!\n",
			E2TEXT = "You've done it! The hideous cyber-\ndemon lord that ruled the lost Deimos\nmoon base has been slain and you\nare triumphant! But ... where are\nyou? You clamber to the edge of the\nmoon and look down to see the awful\ntruth.\n\nDeimos floats above Hell itself!\nYou've never heard of anyone escaping\nfrom Hell, but you'll make the bastards\nsorry they ever heard of you! Quickly,\nyou rappel down to  the surface of\nHell.\n\nNow, it's on to the final chapter of\nDOOM! -- Inferno.",
			E3TEXT = "The loathsome spiderdemon that\nmasterminded the invasion of the moon\nbases and caused so much death has had\nits ass kicked for all time.\n\nA hidden doorway opens and you enter.\nYou've proven too tough for Hell to\ncontain, and now Hell at last plays\nfair -- for you emerge from the door\nto see the green fields of Earth!\nHome at last.\n\nYou wonder what's been happening on\nEarth while you were battling evil\nunleashed. It's good that no Hell-\nspawn could have come through that\ndoor with you ...",
			E4TEXT = "the spider mastermind must have sent forth\nits legions of hellspawn before your\nfinal confrontation with that terrible\nbeast from hell.  but you stepped forward\nand brought forth eternal damnation and\nsuffering upon the horde as a true hero\nwould in the face of something so evil.\n\nbesides, someone was gonna pay for what\nhappened to daisy, your pet rabbit.\n\nbut now, you see spread before you more\npotential pain and gibbitude as a nation\nof demons run amok among our cities.\n\nnext stop, hell on earth!",
			C1TEXT = "YOU HAVE ENTERED DEEPLY INTO THE INFESTED\nSTARPORT. BUT SOMETHING IS WRONG. THE\nMONSTERS HAVE BROUGHT THEIR OWN REALITY\nWITH THEM, AND THE STARPORT'S TECHNOLOGY\nIS BEING SUBVERTED BY THEIR PRESENCE.\n\nAHEAD, YOU SEE AN OUTPOST OF HELL, A\nFORTIFIED ZONE. IF YOU CAN GET PAST IT,\nYOU CAN PENETRATE INTO THE HAUNTED HEART\nOF THE STARBASE AND FIND THE CONTROLLING\nSWITCH WHICH HOLDS EARTH'S POPULATION\nHOSTAGE.",
			C2TEXT = "YOU HAVE WON! YOUR VICTORY HAS ENABLED\nHUMANKIND TO EVACUATE EARTH AND ESCAPE\nTHE NIGHTMARE.  NOW YOU ARE THE ONLY\nHUMAN LEFT ON THE FACE OF THE PLANET.\nCANNIBAL MUTATIONS, CARNIVOROUS ALIENS,\nAND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS.\nYOU SIT BACK AND WAIT FOR DEATH, CONTENT\nTHAT YOU HAVE SAVED YOUR SPECIES.\n\nBUT THEN, EARTH CONTROL BEAMS DOWN A\nMESSAGE FROM SPACE: \nSENSORS HAVE LOCATED\nTHE SOURCE OF THE ALIEN INVASION. IF YOU\nGO THERE, YOU MAY BE ABLE TO BLOCK THEIR\nENTRY.  THE ALIEN BASE IS IN THE HEART OF\nYOUR OWN HOME CITY, NOT FAR FROM THE\nSTARPORT.\n SLOWLY AND PAINFULLY YOU GET\nUP AND RETURN TO THE FRAY.",
			C3TEXT = "YOU ARE AT THE CORRUPT HEART OF THE CITY,\nSURROUNDED BY THE CORPSES OF YOUR ENEMIES.\nYOU SEE NO WAY TO DESTROY THE CREATURES'\nENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR\nTEETH AND PLUNGE THROUGH IT.\n\nTHERE MUST BE A WAY TO CLOSE IT ON THE\nOTHER SIDE. WHAT DO YOU CARE IF YOU'VE\nGOT TO GO THROUGH HELL TO GET TO IT?",
			C4TEXT = "THE HORRENDOUS VISAGE OF THE BIGGEST\nDEMON YOU'VE EVER SEEN CRUMBLES BEFORE\nYOU, AFTER YOU PUMP YOUR ROCKETS INTO\nHIS EXPOSED BRAIN. THE MONSTER SHRIVELS\nUP AND DIES, ITS THRASHING LIMBS\nDEVASTATING UNTOLD MILES OF HELL'S\nSURFACE.\n\nYOU'VE DONE IT. THE INVASION IS OVER.\nEARTH IS SAVED. HELL IS A WRECK. YOU\nWONDER WHERE BAD FOLKS WILL GO WHEN THEY\nDIE, NOW. WIPING THE SWEAT FROM YOUR\nFOREHEAD YOU BEGIN THE LONG TREK BACK\nHOME. REBUILDING EARTH OUGHT TO BE A\nLOT MORE FUN THAN RUINING IT WAS.\n",
			C5TEXT = "CONGRATULATIONS, YOU'VE FOUND THE SECRET\nLEVEL! LOOKS LIKE IT'S BEEN BUILT BY\nHUMANS, RATHER THAN DEMONS. YOU WONDER\nWHO THE INMATES OF THIS CORNER OF HELL\nWILL BE.",
			C6TEXT = "CONGRATULATIONS, YOU'VE FOUND THE\nSUPER SECRET LEVEL!  YOU'D BETTER\nBLAZE THROUGH THIS ONE!\n",
			T1TEXT = "You've fought your way out of the infested\nexperimental labs.   It seems that UAC has\nonce again gulped it down.  With their\nhigh turnover, it must be hard for poor\nold UAC to buy corporate health insurance\nnowadays..\n\nAhead lies the military complex, now\nswarming with diseased horrors hot to get\ntheir teeth into you. With luck, the\ncomplex still has some warlike ordnance\nlaying around.",
			T2TEXT = "You hear the grinding of heavy machinery\nahead.  You sure hope they're not stamping\nout new hellspawn, but you're ready to\nream out a whole herd if you have to.\nThey might be planning a blood feast, but\nyou feel about as mean as two thousand\nmaniacs packed into one mad killer.\n\nYou don't plan to go down easy.",
			T3TEXT = "The vista opening ahead looks real damn\nfamiliar. Smells familiar, too -- like\nfried excrement. You didn't like this\nplace before, and you sure as hell ain't\nplanning to like it now. The more you\nbrood on it, the madder you get.\nHefting your gun, an evil grin trickles\nonto your face. Time to take some names.",
			T4TEXT = "Suddenly, all is silent, from one horizon\nto the other. The agonizing echo of Hell\nfades away, the nightmare sky turns to\nblue, the heaps of monster corpses start \nto evaporate along with the evil stench \nthat filled the air. Jeeze, maybe you've\ndone it. Have you really won?\n\nSomething rumbles in the distance.\nA blue light begins to glow inside the\nruined skull of the demon-spitter.",
			T5TEXT = "What now? Looks totally different. Kind\nof like King Tut's condo. Well,\nwhatever's here can't be any worse\nthan usual. Can it?  Or maybe it's best\nto let sleeping gods lie..",
			T6TEXT = "Time for a vacation. You've burst the\nbowels of hell and by golly you're ready\nfor a break. You mutter to yourself,\nMaybe someone else can kick Hell's ass\nnext time around. Ahead lies a quiet town,\nwith peaceful flowing water, quaint\nbuildings, and presumably no Hellspawn.\n\nAs you step off the transport, you hear\nthe stomp of a cyberdemon's iron shoe.",
			CC_ZOMBIE = "CRAWLA",
			CC_SHOTGUN = "SUPER CRAWLA",
			CC_HEAVY = "MINI B-EGGMAN",
			CC_IMP = "MINVS",
			CC_DEMON = "DRILLAKILLA",
			CC_LOST = "ROCKBOT",
			CC_CACO = "CACODEMON",
			CC_HELL = "HELL KNIGHT",
			CC_BARON = "BARON OF HELL",
			CC_ARACH = "ARACHNOTRON",
			CC_PAIN = "DETON",
			CC_REVEN = "REVENANT",
			CC_MANCU = "MANCUBUS",
			CC_ARCH = "ARCH-VILE",
			CC_SPIDER = "THE SPIDER MASTERMIND",
			CC_CYBER = "THE CYBERDEMON",
			CC_HERO = "OUR HERO",
			QUITMSG = "Eggman's tied explosives\nto your girlfriend, and\nwill activate them if\nyou press the 'Y' key!\nPress 'N' to save her!",
			QUITMSG1 = "What would Tails say if\nhe saw you quitting the game?",
			QUITMSG2 = "Hey!\nWhere do ya think you're goin'?",
			QUITMSG3 = "Forget your studies!\nPlay some more!",
			QUITMSG4 = "You're trying to say you\nlike Sonic Adventure better than\nthis, right?",
			QUITMSG5 = "don't leave yet -- there's a\nsuper emerald around that corner!",
			QUITMSG6 = "You'd rather work than play?",
			QUITMSG7 = "go ahead and leave. see if i care...\n*sniffle*",
			QUIT2MSG = "If you leave now,\nEggman will take over the world!",
			QUIT2MSG1 = "Don't quit!\nThere are animals\nto save!",
			QUIT2MSG2 = "Aw c'mon, just bop\na few more robots!",
			QUIT2MSG3 = "Just because you can't\nget that Chaos Emerald...",
			QUIT2MSG4 = "If you leave, i'll use\nmy spin attack on you!",
			QUIT2MSG5 = "Don't go!\nYou might find the hidden\nlevels!",
			QUIT2MSG6 = "Hit the 'N' key sonic!\nThe 'N' key!",
			FLOOR4_8 = "FLOOR4_8",
			SFLR6_1 = "SFLR6_1",
			MFLR8_4 = "MFLR8_4",
			MFLR8_3 = "MFLR8_3",
			SLIME16 = "SLIME16",
			RROCK14 = "RROCK14",
			RROCK07 = "RROCK07",
			RROCK17 = "RROCK17",
			RROCK13 = "RROCK13",
			RROCK19 = "RROCK19",
			CREDIT = "CREDIT",
			HELP2 = "HELP2",
			VICTORY2 = "VICTORY2",
			ENDPIC = "ENDPIC",
			MODIFIED = "===========================================================================\n                       Sonic Robo Blast II!\n                       by Sonic Team Junior\n                http://ssrg.emulationzone.org/stjr/\n      This is a modified version. Go to our site for the original.\n===========================================================================\n",
			SHAREWARE = "===========================================================================\n                                Shareware!\n===========================================================================\n",
			COMERCIAL = "===========================================================================\n                   We hope you enjoy this game as\n                     much as we did making it!\n===========================================================================\n",
			AUSTIN = "Austin Virtual Gaming: Levels will end after 20 minutes\n",
			M_LOAD = "M_LoadDefaults: Load system defaults.\n",
			Z_INIT = "Z_Init: Init zone memory allocation daemon. \n",
			W_INIT = "W_Init: Init WADfiles.\n",
			M_INIT = "M_Init: Init miscellaneous info.\n",
			R_INIT = "R_Init: Init DOOM refresh daemon - ",
			P_INIT = "\nP_Init: Init Playloop state.\n",
			I_INIT = "I_Init: Setting up machine state.\n",
			D_CHECKNET = "D_CheckNetGame: Checking network game status.\n",
			S_SETSOUND = "S_Init: Setting up sound.\n",
			HU_INIT = "HU_Init: Setting up heads up display.\n",
			ST_INIT = "ST_Init: Init status bar.\n",
			STATREG = "External statistics registered.\n",
			DOOM2WAD = "doom2.wad",
			DOOMUWAD = "doomu.wad",
			DOOMWAD = "doom.wad",
			DOOM1WAD = "doom1.wad",
			CDROM_DIR = "c:\\doomdata",
			CDROM_DEF = "c:/doomdata/default.cfg",
			/*
			CDROM_SAVE = "c:\\doomdata\\"SAVEGAMENAME"%c.dsg",
			NORM_SAVE = SAVEGAMENAME"%c.dsg",
			CDROM_SAVEI = "c:\\doomdata\\"SAVEGAMENAME"%d.dsg",
			NORM_SAVEI = SAVEGAMENAME"%d.dsg",
			*/
			DOOM2TITLE = "Sonic Robo Blast 2: v1.00",
			DOOMUTITLE = "The Ultimate DOOM Startup",
			DOOMTITLE = "DOOM Registered Startup",
			DOOM1TITLE = "DOOM Shareware Startup",
		}
	end

	if matchedGame == "ultdoom" or matchedGame == "shareware" or matchedGame == "doom1" or matchedGame == "doom2" then
	doom.strings = {
		SWSTRING      = "this is the shareware version of doom.\n\nyou need to order the entire trilogy.\n\npress a key.",

		// DOOM1
		QUITMSG       = "are you sure you want to\nquit this great game?",
		QUITMSG1      = "please don't leave, there's more\ndemons to toast!",
		QUITMSG2      = "let's beat it -- this is turning\ninto a bloodbath!",
		QUITMSG3      = "i wouldn't leave if i were you.\ndos is much worse.",
		QUITMSG4      = "you're trying to say you like dos\nbetter than me, right?",
		QUITMSG5      = "don't leave yet -- there's a\ndemon around that corner!",
		QUITMSG6      = "ya know, next time you come in here\ni'm gonna toast ya.",
		QUITMSG7      = "go ahead and leave. see if i care.",

		// QuitDOOM II messages
		QUITMSG8      = "you want to quit?\nthen, thou hast lost an eighth!",
		QUITMSG9      = "don't go now, there's a \ndimensional shambler waiting\nat the dos prompt!",
		QUITMSG10     = "get outta here and go back\nto your boring programs.",
		QUITMSG11     = "if i were your boss, i'd \n deathmatch ya in a minute!",
		QUITMSG12     = "look, bud. you leave now\nand you forfeit your body count!",
		QUITMSG13     = "just leave. when you come\nback, i'll be waiting with a bat.",
		QUITMSG14     = "you're lucky i don't smack\nyou for thinking about leaving.",

		-- P_inter.C
		GOTARMOR      = "Picked up the armor.",
		GOTMEGA       = "Picked up the MegaArmor!",
		GOTHTHBONUS   = "Picked up a health bonus.",
		GOTARMBONUS   = "Picked up an armor bonus.",
		GOTSTIM       = "Picked up a stimpack.",
		GOTMEDINEED   = "Picked up a medikit that you REALLY need!",
		GOTMEDIKIT    = "Picked up a medikit.",
		GOTSUPER      = "Supercharge!",

		GOTBLUECARD   = "Picked up a blue keycard.",
		GOTYELWCARD   = "Picked up a yellow keycard.",
		GOTREDCARD    = "Picked up a red keycard.",
		GOTBLUESKUL   = "Picked up a blue skull key.",
		GOTYELWSKUL   = "Picked up a yellow skull key.",
		GOTREDSKULL   = "Picked up a red skull key.",

		GOTINVUL      = "Invulnerability!",
		GOTBERSERK    = "Berserk!",
		GOTINVIS      = "Partial Invisibility",
		GOTSUIT       = "Radiation Shielding Suit",
		GOTMAP        = "Computer Area Map",
		GOTVISOR      = "Light Amplification Visor",
		GOTMSPHERE    = "MegaSphere!",

		GOTCLIP       = "Picked up a clip.",
		GOTCLIPBOX    = "Picked up a box of bullets.",
		GOTROCKET     = "Picked up a rocket.",
		GOTROCKBOX    = "Picked up a box of rockets.",
		GOTCELL       = "Picked up an energy cell.",
		GOTCELLBOX    = "Picked up an energy cell pack.",
		GOTSHELLS     = "Picked up 4 shotgun shells.",
		GOTSHELLBOX   = "Picked up a box of shotgun shells.",
		GOTBACKPACK   = "Picked up a backpack full of ammo!",

		GOTBFG9000    = "You got the BFG9000!  Oh, yes.",
		GOTCHAINGUN   = "You got the chaingun!",
		GOTCHAINSAW   = "A chainsaw!  Find some meat!",
		GOTLAUNCHER   = "You got the rocket launcher!",
		GOTPLASMA     = "You got the plasma gun!",
		GOTSHOTGUN    = "You got the shotgun!",
		GOTSHOTGUN2   = "You got the super shotgun!",

		-- P_Doors.C
		PD_BLUEO      = "You need a blue key to activate this object",
		PD_REDO       = "You need a red key to activate this object",
		PD_YELLOWO    = "You need a yellow key to activate this object",
		PD_BLUEK      = "You need a blue key to open this door",
		PD_REDK       = "You need a red key to open this door",
		PD_YELLOWK    = "You need a yellow key to open this door",

		-- G_game.C
		GGSAVED       = "game saved.",

		-- HU_stuff.C
		HUSTR_MSGU    = "[Message unsent]",

		HUSTR_E1M1    = "E1M1: Hangar",
		HUSTR_E1M2    = "E1M2: Nuclear Plant",
		HUSTR_E1M3    = "E1M3: Toxin Refinery",
		HUSTR_E1M4    = "E1M4: Command Control",
		HUSTR_E1M5    = "E1M5: Phobos Lab",
		HUSTR_E1M6    = "E1M6: Central Processing",
		HUSTR_E1M7    = "E1M7: Computer Station",
		HUSTR_E1M8    = "E1M8: Phobos Anomaly",
		HUSTR_E1M9    = "E1M9: Military Base",

		HUSTR_E2M1    = "E2M1: Deimos Anomaly",
		HUSTR_E2M2    = "E2M2: Containment Area",
		HUSTR_E2M3    = "E2M3: Refinery",
		HUSTR_E2M4    = "E2M4: Deimos Lab",
		HUSTR_E2M5    = "E2M5: Command Center",
		HUSTR_E2M6    = "E2M6: Halls of the Damned",
		HUSTR_E2M7    = "E2M7: Spawning Vats",
		HUSTR_E2M8    = "E2M8: Tower of Babel",
		HUSTR_E2M9    = "E2M9: Fortress of Mystery",

		HUSTR_E3M1    = "E3M1: Hell Keep",
		HUSTR_E3M2    = "E3M2: Slough of Despair",
		HUSTR_E3M3    = "E3M3: Pandemonium",
		HUSTR_E3M4    = "E3M4: House of Pain",
		HUSTR_E3M5    = "E3M5: Unholy Cathedral",
		HUSTR_E3M6    = "E3M6: Mt. Erebus",
		HUSTR_E3M7    = "E3M7: Limbo",
		HUSTR_E3M8    = "E3M8: Dis",
		HUSTR_E3M9    = "E3M9: Warrens",

		HUSTR_E4M1    = "E4M1: Hell Beneath",
		HUSTR_E4M2    = "E4M2: Perfect Hatred",
		HUSTR_E4M3    = "E4M3: Sever The Wicked",
		HUSTR_E4M4    = "E4M4: Unruly Evil",
		HUSTR_E4M5    = "E4M5: They Will Repent",
		HUSTR_E4M6    = "E4M6: Against Thee Wickedly",
		HUSTR_E4M7    = "E4M7: And Hell Followed",
		HUSTR_E4M8    = "E4M8: Unto The Cruel",
		HUSTR_E4M9    = "E4M9: Fear",

		HUSTR_1       = "level 1: entryway",
		HUSTR_2       = "level 2: underhalls",
		HUSTR_3       = "level 3: the gantlet",
		HUSTR_4       = "level 4: the focus",
		HUSTR_5       = "level 5: the waste tunnels",
		HUSTR_6       = "level 6: the crusher",
		HUSTR_7       = "level 7: dead simple",
		HUSTR_8       = "level 8: tricks and traps",
		HUSTR_9       = "level 9: the pit",
		HUSTR_10      = "level 10: refueling base",
		HUSTR_11      = "level 11: 'o' of destruction!",

		HUSTR_12      = "level 12: the factory",
		HUSTR_13      = "level 13: downtown",
		HUSTR_14      = "level 14: the inmost dens",
		HUSTR_15      = "level 15: industrial zone",
		HUSTR_16      = "level 16: suburbs",
		HUSTR_17      = "level 17: tenements",
		HUSTR_18      = "level 18: the courtyard",
		HUSTR_19      = "level 19: the citadel",
		HUSTR_20      = "level 20: gotcha!",

		HUSTR_21      = "level 21: nirvana",
		HUSTR_22      = "level 22: the catacombs",
		HUSTR_23      = "level 23: barrels o' fun",
		HUSTR_24      = "level 24: the chasm",
		HUSTR_25      = "level 25: bloodfalls",
		HUSTR_26      = "level 26: the abandoned mines",
		HUSTR_27      = "level 27: monster condo",
		HUSTR_28      = "level 28: the spirit world",
		HUSTR_29      = "level 29: the living end",
		HUSTR_30      = "level 30: icon of sin",

		HUSTR_31      = "level 31: wolfenstein",
		HUSTR_32      = "level 32: grosse",

		PHUSTR_1      = "level 1: congo",
		PHUSTR_2      = "level 2: well of souls",
		PHUSTR_3      = "level 3: aztec",
		PHUSTR_4      = "level 4: caged",
		PHUSTR_5      = "level 5: ghost town",
		PHUSTR_6      = "level 6: baron's lair",
		PHUSTR_7      = "level 7: caughtyard",
		PHUSTR_8      = "level 8: realm",
		PHUSTR_9      = "level 9: abattoire",
		PHUSTR_10     = "level 10: onslaught",
		PHUSTR_11     = "level 11: hunted",

		PHUSTR_12     = "level 12: speed",
		PHUSTR_13     = "level 13: the crypt",
		PHUSTR_14     = "level 14: genesis",
		PHUSTR_15     = "level 15: the twilight",
		PHUSTR_16     = "level 16: the omen",
		PHUSTR_17     = "level 17: compound",
		PHUSTR_18     = "level 18: neurosphere",
		PHUSTR_19     = "level 19: nme",
		PHUSTR_20     = "level 20: the death domain",

		PHUSTR_21     = "level 21: slayer",
		PHUSTR_22     = "level 22: impossible mission",
		PHUSTR_23     = "level 23: tombstone",
		PHUSTR_24     = "level 24: the final frontier",
		PHUSTR_25     = "level 25: the temple of darkness",
		PHUSTR_26     = "level 26: bunker",
		PHUSTR_27     = "level 27: anti-christ",
		PHUSTR_28     = "level 28: the sewers",
		PHUSTR_29     = "level 29: odyssey of noises",
		PHUSTR_30     = "level 30: the gateway of hell",

		PHUSTR_31     = "level 31: cyberden",
		PHUSTR_32     = "level 32: go 2 it",

		THUSTR_1      = "level 1: system control",
		THUSTR_2      = "level 2: human bbq",
		THUSTR_3      = "level 3: power control",
		THUSTR_4      = "level 4: wormhole",
		THUSTR_5      = "level 5: hanger",
		THUSTR_6      = "level 6: open season",
		THUSTR_7      = "level 7: prison",
		THUSTR_8      = "level 8: metal",
		THUSTR_9      = "level 9: stronghold",
		THUSTR_10     = "level 10: redemption",
		THUSTR_11     = "level 11: storage facility",

		THUSTR_12     = "level 12: crater",
		THUSTR_13     = "level 13: nukage processing",
		THUSTR_14     = "level 14: steel works",
		THUSTR_15     = "level 15: dead zone",
		THUSTR_16     = "level 16: deepest reaches",
		THUSTR_17     = "level 17: processing area",
		THUSTR_18     = "level 18: mill",
		THUSTR_19     = "level 19: shipping/respawning",
		THUSTR_20     = "level 20: central processing",

		THUSTR_21     = "level 21: administration center",
		THUSTR_22     = "level 22: habitat",
		THUSTR_23     = "level 23: lunar mining project",
		THUSTR_24     = "level 24: quarry",
		THUSTR_25     = "level 25: baron's den",
		THUSTR_26     = "level 26: ballistyx",
		THUSTR_27     = "level 27: mount pain",
		THUSTR_28     = "level 28: heck",
		THUSTR_29     = "level 29: river styx",
		THUSTR_30     = "level 30: last call",

		THUSTR_31     = "level 31: pharaoh",
		THUSTR_32     = "level 32: caribbean",

		HUSTR_CHATMACRO1 = "I'm ready to kick butt!",
		HUSTR_CHATMACRO2 = "I'm OK.",
		HUSTR_CHATMACRO3 = "I'm not looking too good!",
		HUSTR_CHATMACRO4 = "Help!",
		HUSTR_CHATMACRO5 = "You suck!",
		HUSTR_CHATMACRO6 = "Next time, scumbag...",
		HUSTR_CHATMACRO7 = "Come here!",
		HUSTR_CHATMACRO8 = "I'll take care of it.",
		HUSTR_CHATMACRO9 = "Yes",
		HUSTR_CHATMACRO0 = "No",

		HUSTR_TALKTOSELF1 = "You mumble to yourself",
		HUSTR_TALKTOSELF2 = "Who's there?",
		HUSTR_TALKTOSELF3 = "You scare yourself",
		HUSTR_TALKTOSELF4 = "You start to rave",
		HUSTR_TALKTOSELF5 = "You've lost it...",

		HUSTR_MESSAGESENT = "[Message Sent]",

		HUSTR_PLRGREEN = "Green: ",
		HUSTR_PLRINDIGO = "Indigo: ",
		HUSTR_PLRBROWN = "Brown: ",
		HUSTR_PLRRED   = "Red: ",

		HUSTR_KEYGREEN  = "g",
		HUSTR_KEYINDIGO = "i",
		HUSTR_KEYBROWN  = "b",
		HUSTR_KEYRED    = "r",

		-- AM_map.C
		AMSTR_FOLLOWON    = "Follow Mode ON",
		AMSTR_FOLLOWOFF   = "Follow Mode OFF",

		AMSTR_GRIDON      = "Grid ON",
		AMSTR_GRIDOFF     = "Grid OFF",

		AMSTR_MARKEDSPOT  = "Marked Spot",
		AMSTR_MARKSCLEARED= "All Marks Cleared",

		-- ST_stuff.C
		STSTR_MUS       = "Music Change",
		STSTR_NOMUS     = "IMPOSSIBLE SELECTION",
		STSTR_DQDON     = "Degreelessness Mode On",
		STSTR_DQDOFF    = "Degreelessness Mode Off",

		STSTR_KFAADDED  = "Very Happy Ammo Added",
		STSTR_FAADDED   = "Ammo (no keys) Added",

		STSTR_NCON      = "No Clipping Mode ON",
		STSTR_NCOFF     = "No Clipping Mode OFF",

		STSTR_BEHOLD    = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp",
		STSTR_BEHOLDX   = "Power-up Toggled",

		STSTR_CHOPPERS  = "... doesn't suck - GM",
		STSTR_CLEV      = "Changing Level...",

		E1TEXT = "Once you beat the big badasses and\nclean out the moon base you're supposed\nto win, aren't you? Aren't you? Where's\nyour fat reward and ticket home? What\nthe hell is this? It's not supposed to\nend this way!\n\nIt stinks like rotten meat, but looks\nlike the lost Deimos base.  Looks like\nyou're stuck on The Shores of Hell.\nThe only way out is through.\n\nTo continue the DOOM experience, play\nThe Shores of Hell and its amazing\nsequel, Inferno!\n",
		E2TEXT = "You've done it! The hideous cyber-\ndemon lord that ruled the lost Deimos\nmoon base has been slain and you\nare triumphant! But ... where are\nyou? You clamber to the edge of the\nmoon and look down to see the awful\ntruth.\n\nDeimos floats above Hell itself!\nYou've never heard of anyone escaping\nfrom Hell, but you'll make the bastards\nsorry they ever heard of you! Quickly,\nyou rappel down to  the surface of\nHell.\n\nNow, it's on to the final chapter of\nDOOM! -- Inferno.",
		E3TEXT = "The loathsome spiderdemon that\nmasterminded the invasion of the moon\nbases and caused so much death has had\nits ass kicked for all time.\n\nA hidden doorway opens and you enter.\nYou've proven too tough for Hell to\ncontain, and now Hell at last plays\nfair -- for you emerge from the door\nto see the green fields of Earth!\nHome at last.\n\nYou wonder what's been happening on\nEarth while you were battling evil\nunleashed. It's good that no Hell-\nspawn could have come through that\ndoor with you ...",
		E4TEXT = "the spider mastermind must have sent forth\nits legions of hellspawn before your\nfinal confrontation with that terrible\nbeast from hell.  but you stepped forward\nand brought forth eternal damnation and\nsuffering upon the horde as a true hero\nwould in the face of something so evil.\n\nbesides, someone was gonna pay for what\nhappened to daisy, your pet rabbit.\n\nbut now, you see spread before you more\npotential pain and gibbitude as a nation\nof demons run amok among our cities.\n\nnext stop, hell on earth!",
		C1TEXT = "YOU HAVE ENTERED DEEPLY INTO THE INFESTED\nSTARPORT. BUT SOMETHING IS WRONG. THE\nMONSTERS HAVE BROUGHT THEIR OWN REALITY\nWITH THEM, AND THE STARPORT'S TECHNOLOGY\nIS BEING SUBVERTED BY THEIR PRESENCE.\n\nAHEAD, YOU SEE AN OUTPOST OF HELL, A\nFORTIFIED ZONE. IF YOU CAN GET PAST IT,\nYOU CAN PENETRATE INTO THE HAUNTED HEART\nOF THE STARBASE AND FIND THE CONTROLLING\nSWITCH WHICH HOLDS EARTH'S POPULATION\nHOSTAGE.",
		C2TEXT = "YOU HAVE WON! YOUR VICTORY HAS ENABLED\nHUMANKIND TO EVACUATE EARTH AND ESCAPE\nTHE NIGHTMARE.  NOW YOU ARE THE ONLY\nHUMAN LEFT ON THE FACE OF THE PLANET.\nCANNIBAL MUTATIONS, CARNIVOROUS ALIENS,\nAND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS.\nYOU SIT BACK AND WAIT FOR DEATH, CONTENT\nTHAT YOU HAVE SAVED YOUR SPECIES.\n\nBUT THEN, EARTH CONTROL BEAMS DOWN A\nMESSAGE FROM SPACE: \"SENSORS HAVE LOCATED\nTHE SOURCE OF THE ALIEN INVASION. IF YOU\nGO THERE, YOU MAY BE ABLE TO BLOCK THEIR\nENTRY.  THE ALIEN BASE IS IN THE HEART OF\nYOUR OWN HOME CITY, NOT FAR FROM THE\nSTARPORT.\" SLOWLY AND PAINFULLY YOU GET\nUP AND RETURN TO THE FRAY.",
		C3TEXT = "YOU ARE AT THE CORRUPT HEART OF THE CITY,\nSURROUNDED BY THE CORPSES OF YOUR ENEMIES.\nYOU SEE NO WAY TO DESTROY THE CREATURES'\nENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR\nTEETH AND PLUNGE THROUGH IT.\n\nTHERE MUST BE A WAY TO CLOSE IT ON THE\nOTHER SIDE. WHAT DO YOU CARE IF YOU'VE\nGOT TO GO THROUGH HELL TO GET TO IT?",
		C4TEXT = "THE HORRENDOUS VISAGE OF THE BIGGEST\nDEMON YOU'VE EVER SEEN CRUMBLES BEFORE\nYOU, AFTER YOU PUMP YOUR ROCKETS INTO\nHIS EXPOSED BRAIN. THE MONSTER SHRIVELS\nUP AND DIES, ITS THRASHING LIMBS\nDEVASTATING UNTOLD MILES OF HELL'S\nSURFACE.\n\nYOU'VE DONE IT. THE INVASION IS OVER.\nEARTH IS SAVED. HELL IS A WRECK. YOU\nWONDER WHERE BAD FOLKS WILL GO WHEN THEY\nDIE, NOW. WIPING THE SWEAT FROM YOUR\nFOREHEAD YOU BEGIN THE LONG TREK BACK\nHOME. REBUILDING EARTH OUGHT TO BE A\nLOT MORE FUN THAN RUINING IT WAS.\n",
		C5TEXT = "CONGRATULATIONS, YOU'VE FOUND THE SECRET\nLEVEL! LOOKS LIKE IT'S BEEN BUILT BY\nHUMANS, RATHER THAN DEMONS. YOU WONDER\nWHO THE INMATES OF THIS CORNER OF HELL\nWILL BE.",
		C6TEXT = "CONGRATULATIONS, YOU'VE FOUND THE\nSUPER SECRET LEVEL!  YOU'D BETTER\nBLAZE THROUGH THIS ONE!\n",
		T1TEXT = "You've fought your way out of the infested\nexperimental labs.   It seems that UAC has\nonce again gulped it down.  With their\nhigh turnover, it must be hard for poor\nold UAC to buy corporate health insurance\nnowadays..\n\nAhead lies the military complex, now\nswarming with diseased horrors hot to get\ntheir teeth into you. With luck, the\ncomplex still has some warlike ordnance\nlaying around.",
		T2TEXT = "You hear the grinding of heavy machinery\nahead.  You sure hope they're not stamping\nout new hellspawn, but you're ready to\nream out a whole herd if you have to.\nThey might be planning a blood feast, but\nyou feel about as mean as two thousand\nmaniacs packed into one mad killer.\n\nYou don't plan to go down easy.",
		T3TEXT = "The vista opening ahead looks real damn\nfamiliar. Smells familiar, too -- like\nfried excrement. You didn't like this\nplace before, and you sure as hell ain't\nplanning to like it now. The more you\nbrood on it, the madder you get.\nHefting your gun, an evil grin trickles\nonto your face. Time to take some names.",
		T4TEXT = "Suddenly, all is silent, from one horizon\nto the other. The agonizing echo of Hell\nfades away, the nightmare sky turns to\nblue, the heaps of monster corpses start \nto evaporate along with the evil stench \nthat filled the air. Jeeze, maybe you've\ndone it. Have you really won?\n\nSomething rumbles in the distance.\nA blue light begins to glow inside the\nruined skull of the demon-spitter.",
		T5TEXT = "What now? Looks totally different. Kind\nof like King Tut's condo. Well,\nwhatever's here can't be any worse\nthan usual. Can it?  Or maybe it's best\nto let sleeping gods lie..",
		T6TEXT = "Time for a vacation. You've burst the\nbowels of hell and by golly you're ready\nfor a break. You mutter to yourself,\nMaybe someone else can kick Hell's ass\nnext time around. Ahead lies a quiet town,\nwith peaceful flowing water, quaint\nbuildings, and presumably no Hellspawn.\n\nAs you step off the transport, you hear\nthe stomp of a cyberdemon's iron shoe.",
	}
	end

	-- Chex Quest (hopefully counts for Chex Quest 2 aswell)
	if matchedGame == "chex1" then
		-- Autopatch Chex strings
	doom.strings = {
		-- P_inter.C
		GOTARMOR      = "Picked up the Chex(R) Armor.",
		GOTMEGA       = "Picked up the Super Chex(R) Armor!",
		GOTHTHBONUS   = "Picked up a glass of water.",
		GOTARMBONUS   = "Picked up slime repellent.",
		GOTSTIM       = "Picked up a bowl of fruit.",
		GOTMEDINEED   = "Picked up some needed vegetables!",
		GOTMEDIKIT    = "Picked up a bowl of vegetables.",
		GOTSUPER      = "Supercharge Breakfast!",

		GOTBLUECARD   = "Picked up a blue key.",
		GOTYELWCARD   = "Picked up a yellow key.",
		GOTREDCARD    = "Picked up a red key.",
		GOTBLUESKUL   = "Picked up a blue skull key.",
		GOTYELWSKUL   = "Picked up a yellow skull key.",
		GOTREDSKULL   = "Picked up a red skull key.",

		GOTINVUL      = "Invulnerability!",
		GOTBERSERK    = "Berserk!",
		GOTINVIS      = "Partial Invisibility",
		GOTSUIT       = "Slimeproof Suit",
		GOTMAP        = "Computer Area Map",
		GOTVISOR      = "Light Amplification Visor",
		GOTMSPHERE    = "MegaSphere!",

		GOTCLIP       = "Picked up a mini zorch recharge.",
		GOTCLIPBOX    = "Picked up a mini zorch pack.",
		GOTROCKET     = "Picked up a zorch propulsor recharge.",
		GOTROCKBOX    = "Picked up a zorch propulsor pack.",
		GOTCELL       = "Picked up a phasing zorcher recharge.",
		GOTCELLBOX    = "Picked up a phasing zorcher pack.",
		GOTSHELLS     = "Picked up a large zorcher recharge.",
		GOTSHELLBOX   = "Picked up a large zorcher pack.",
		GOTBACKPACK   = "Picked up a Zorchpak!",

		GOTBFG9000    = "You got the LAZ Device!",
		GOTCHAINGUN   = "You got the Rapid Zorcher!",
		GOTCHAINSAW   = "You got the Super Bootspork!",
		GOTLAUNCHER   = "You got the Zorch Propulsor!",
		GOTPLASMA     = "You got the Phasing Zorcher!",
		GOTSHOTGUN    = "You got the Large Zorcher!",
		GOTSHOTGUN2   = "You got the Super Large Zorcher!",

		-- P_Doors.C
		PD_BLUEO      = "You need a blue key to activate this object",
		PD_REDO       = "You need a red key to activate this object",
		PD_YELLOWO    = "You need a yellow key to activate this object",
		PD_BLUEK      = "You need a blue key to open this door",
		PD_REDK       = "You need a red key to open this door",
		PD_YELLOWK    = "You need a yellow key to open this door",

		-- G_game.C
		GGSAVED       = "game saved.",

		-- HU_stuff.C
		HUSTR_MSGU    = "[Message unsent]",

		HUSTR_E1M1    = "E1M1: Landing Zone",
		HUSTR_E1M2    = "E1M2: Storage Facility",
		HUSTR_E1M3    = "E1M3: Experimental Lab",
		HUSTR_E1M4    = "E1M4: Arboretum",
		HUSTR_E1M5    = "E1M5: Caverns of Bazoik",
		HUSTR_E1M6    = "E1M6: Central Processing",
		HUSTR_E1M7    = "E1M7: Computer Station",
		HUSTR_E1M8    = "E1M8: Phobos Anomaly",
		HUSTR_E1M9    = "E1M9: Military Base",

		HUSTR_E2M1    = "E2M1: Deimos Anomaly",
		HUSTR_E2M2    = "E2M2: Containment Area",
		HUSTR_E2M3    = "E2M3: Refinery",
		HUSTR_E2M4    = "E2M4: Deimos Lab",
		HUSTR_E2M5    = "E2M5: Command Center",
		HUSTR_E2M6    = "E2M6: Halls of the Damned",
		HUSTR_E2M7    = "E2M7: Spawning Vats",
		HUSTR_E2M8    = "E2M8: Tower of Babel",
		HUSTR_E2M9    = "E2M9: Fortress of Mystery",

		HUSTR_E3M1    = "E3M1: Hell Keep",
		HUSTR_E3M2    = "E3M2: Slough of Despair",
		HUSTR_E3M3    = "E3M3: Pandemonium",
		HUSTR_E3M4    = "E3M4: House of Pain",
		HUSTR_E3M5    = "E3M5: Unholy Cathedral",
		HUSTR_E3M6    = "E3M6: Mt. Erebus",
		HUSTR_E3M7    = "E3M7: Limbo",
		HUSTR_E3M8    = "E3M8: Dis",
		HUSTR_E3M9    = "E3M9: Warrens",

		HUSTR_E4M1    = "E4M1: Hell Beneath",
		HUSTR_E4M2    = "E4M2: Perfect Hatred",
		HUSTR_E4M3    = "E4M3: Sever The Wicked",
		HUSTR_E4M4    = "E4M4: Unruly Evil",
		HUSTR_E4M5    = "E4M5: They Will Repent",
		HUSTR_E4M6    = "E4M6: Against Thee Wickedly",
		HUSTR_E4M7    = "E4M7: And Hell Followed",
		HUSTR_E4M8    = "E4M8: Unto The Cruel",
		HUSTR_E4M9    = "E4M9: Fear",

		HUSTR_CHATMACRO1 = "I'm ready to zorch!",
		HUSTR_CHATMACRO2 = "I'm feeling great!",
		HUSTR_CHATMACRO3 = "I'm getting pretty gooed up!",
		HUSTR_CHATMACRO4 = "Somebody help me!",
		HUSTR_CHATMACRO5 = "Go back to your own dimension!",
		HUSTR_CHATMACRO6 = "Stop that Flemoid",
		HUSTR_CHATMACRO7 = "I think I'm lost!",
		HUSTR_CHATMACRO8 = "I'll get you out of this gunk.",
		HUSTR_CHATMACRO9 = "Yes",
		HUSTR_CHATMACRO0 = "No",

		HUSTR_TALKTOSELF1 = "I'm feeling great.",
		HUSTR_TALKTOSELF2 = "I think I'm lost.",
		HUSTR_TALKTOSELF3 = "Oh No...",
		HUSTR_TALKTOSELF4 = "Gotta break free.",
		HUSTR_TALKTOSELF5 = "Hurry!",

		HUSTR_MESSAGESENT = "[Message Sent]",

		HUSTR_PLRGREEN = "Green: ",
		HUSTR_PLRINDIGO = "Indigo: ",
		HUSTR_PLRBROWN = "Brown: ",
		HUSTR_PLRRED   = "Red: ",

		HUSTR_KEYGREEN  = "g",
		HUSTR_KEYINDIGO = "i",
		HUSTR_KEYBROWN  = "b",
		HUSTR_KEYRED    = "r",

		-- AM_map.C
		AMSTR_FOLLOWON    = "Follow Mode ON",
		AMSTR_FOLLOWOFF   = "Follow Mode OFF",

		AMSTR_GRIDON      = "Grid ON",
		AMSTR_GRIDOFF     = "Grid OFF",

		AMSTR_MARKEDSPOT  = "Marked Spot",
		AMSTR_MARKSCLEARED= "All Marks Cleared",

		-- ST_stuff.C
		STSTR_MUS       = "Music Change",
		STSTR_NOMUS     = "IMPOSSIBLE SELECTION",
		STSTR_DQDON     = "Invincible Mode On",
		STSTR_DQDOFF    = "Invincible Mode Off",

		STSTR_KFAADDED  = "Super Zorch Added",
		STSTR_FAADDED   = "Zorch Added",

		STSTR_NCON      = "No Clipping Mode ON",
		STSTR_NCOFF     = "No Clipping Mode OFF",

		STSTR_BEHOLD    = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp",
		STSTR_BEHOLDX   = "Power-up Toggled",

		STSTR_CHOPPERS  = "... Eat Chex(R)!",
		STSTR_CLEV      = "Changing Level...",
		
		CHEXWIN         = [[Mission accomplished.

						Are you prepared for the next mission?






						Press the escape key to continue...]]
	}
	
	doom.textscreenmaps = {[5] = {text = "$CHEXWIN", secret = false, bg = "EP1CUTSC"}}
	doom.titlemenus.menu.entries[1].goto = "newgame"
	doom.dropTable = {}
	doom.lastmap = 5
	end
	-- Shareware DOOM
	if matchedGame == "shareware" then
		doom.lastmap = 8
		doom.titlemenus.episelect.entries = {
			{label = "episode1", patch = "M_EPI1", x = 48, y = 63,              goto = "newgame", episode = 1},
			{label = "episode2", patch = "M_EPI2", x = 48, y = 63+LINEHEIGHT,   goto = "sharewaredeny", episode = 2},
			{label = "episode3", patch = "M_EPI3", x = 48, y = 63+LINEHEIGHT*2, goto = "sharewaredeny", episode = 3},
		}
	end

	-- Registered DOOM
	if matchedGame == "doom1" then
		doom.lastmap = 24
		doom.titlemenus.episelect.entries = {
			{label = "episode1", patch = "M_EPI1", x = 48, y = 63,              goto = "newgame", episode = 1},
			{label = "episode2", patch = "M_EPI2", x = 48, y = 63+LINEHEIGHT,   goto = "newgame", episode = 2},
			{label = "episode3", patch = "M_EPI3", x = 48, y = 63+LINEHEIGHT*2, goto = "newgame", episode = 3},
		}
	end

	if matchedGame == "doom1" or matchedGame == "shareware" or matchedGame == "ultdoom" then
		doom.quitStrings = {
			"$QUITMSG", "$QUITMSG1", "$QUITMSG2", "$QUITMSG3", "$QUITMSG4", "$QUITMSG5", "$QUITMSG6", "$QUITMSG7",
		}
	elseif matchedGame == "doom2" then
		doom.quitStrings = {
			"$QUITMSG", "$QUITMSG1", "$QUITMSG2", "$QUITMSG3", "$QUITMSG4", "$QUITMSG5", "$QUITMSG6", "$QUITMSG7",
                   "$QUITMSG8", "$QUITMSG9", "$QUITMSG10", "$QUITMSG11", "$QUITMSG12", "$QUITMSG13", "$QUITMSG14"
		}
	end
end

addHook("AddonLoaded", doLoadingShit)
doLoadingShit()