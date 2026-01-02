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
	}),
	tnt = hashEndoom({
		"       " .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223),
		"                          Final DOOM: TNT - Evilution",
		"        " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
		"",
		"                       DOOM II was created by id Software",
		"",
		"                    TNT - Evilution was created by Team TNT:",
		"",
		"               Andre Arsenault - Christopher Buteau - Dario Casali",
		"                 Milo Casali - Jim Dethlefsen - Andrew Dowswell",
		"                 Jonathan El-Bizri - Ty Halderman - David Hill",
		"              Dean Johnson - Brian Kidby - Jim Lowell - Josh Martel",
		"                   Steve McCrea - John Minadeo - Tom Mustaine",
		"           Drake O'Brien - Robin Patenall - Jimmy Sieben - L.A. Sieben",
		"          Mark Snell - Paul Turnbull - John Wakelin - William Whitaker",
		"",
		"",
		"",
		"               If you encounter any problems playing Final DOOM,",
		"                 please call GT Interactive technical support",
		"            at (970)-522-1797. Monday - Friday 8AM - MIDNIGHT EST",
		"",
		"                  Final DOOM Copyright (C)  1996 id Software",
		"",
		"",
	}),
	plutonia = hashEndoom({
		"       " .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223) .. string.char(223),
		"                      Final DOOM: The Plutonia Experiment",
		"        " .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196) .. string.char(196),
		"",
		"                       DOOM II was created by id Software",
		"",
		"                    The Plutonia Experiment was created by:",
		"",
		"                          Dario Casali and Milo Casali",
		"",
		"                              Additional support:",
		"                    Dan Ireland - Steve Davies - Tom Heverly",
		"",
		"",
		"",
		"",
		"",
		"",
		"               If you encounter any problems playing Final DOOM,",
		"                 please call GT Interactive technical support",
		"            at (970)-522-1797. Monday - Friday 8AM - MIDNIGHT EST",
		"",
		"                  Final DOOM Copyright (C)  1996 id Software",
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
	-- path[1] = wepname
	-- path[2] = wepstate
	-- path[3] = wepframe
	-- DEHACKED uses nextframe
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
	state.tics = data.duration or state.tics
	if data.spritenumber != nil then
		state.sprite = pointers.sprites[(data.spritenumber or 0) + 1] or state.sprite
	end
	state.frame = data.spritesubnumber or state.frame
end

-- "This sink is so hard to clean, if only there was an easier way!"
local function doDehacked()
	if doom and doom.dehacked then
		print("applying DEHACKED fields...")
		local deh = doom.dehacked
		local pointers = doom.dehackedpointers
		if deh.ammo then
			if deh.ammo[0] then
				doom.ammos["bullets"].max = deh.ammo[0].maxammo or doom.ammos["bullets"].max
			end
			if deh.ammo[1] then
				doom.ammos["shells"].max = deh.ammo[1].maxammo or doom.ammos["shells"].max
			end
			if deh.ammo[2] then
				doom.ammos["cells"].max = deh.ammo[2].maxammo or doom.ammos["cells"].max
			end
			if deh.ammo[3] then
				doom.ammos["rockets"].max = deh.ammo[3].maxammo or doom.ammos["rockets"].max
			end
		end
		if deh.misc then
			local misc = deh.misc[0]
			doom.pistolstartstate.maxhealth = misc.maxhealth or doom.pistolstartstate.maxhealth
			doom.pistolstartstate.maxarmor = misc.maxarmor or doom.pistolstartstate.maxarmor
			doom.soulspheregrant = misc.soulspherehealth or doom.soulspheregrant
			doom.maxsoulsphere = misc.maxsoulsphere or doom.maxsoulsphere
			doom.megaspheregrant = misc.megaspherehealth or doom.megaspheregrant
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
					info.doomednum = data["id #"] or info.doomednum
					if info.doomednum <= 32 then
						doom.mthingReplacements[info.doomednum] = pointers.things[number]
					end
					info.spawnstate = pointers.frames[data.initialframe] or info.spawnstate
					info.deathstate = pointers.frames[data.deathframe] or info.deathstate
					info.seestate = pointers.frames[data.firstmovingframe] or info.seestate
					info.spawnhealth = data.hitpoints or info.spawnhealth
					info.speed = (data.speed and data.speed * FRACUNIT) or info.speed
					info.radius = data.width or info.radius
					info.height = data.height or info.height
					info.mass = data.mass or info.mass
					info.seesound = pointers.frames[data.alertsound] or info.seesound
					info.activesound = pointers.frames[data.actionsound] or info.activesound
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
					weaponStateHandler(pointers, number, data)
				else
					if pointers.frames[number] then
						local frame = states[pointers.frames[number]]
						local sprite = pointers.sprites[(data.spritenumber or 0) + 1]
						if data.spritenumber != nil then
							if sprite == nil then
								print("WARNING: SPRITE # " .. tostring(data.spritenumber) .. " HAS NOT BEEN FREESLOTTED YET!")
							else
								frame.sprite = sprite
							end
						end
						
						if data.spritesubnumber != nil then
							frame.frame = data.spritesubnumber
						end
						if data.duration != nil then
							frame.tics = data.duration
						end
						if pointers.frames[data.nextframe] != nil then
							frame.nextstate = pointers.frames[data.nextframe]
						end
					else
						print("NOTICE: DEHACKED FRAME # " .. tostring(number) .. " DOESN'T HAVE AN ASSOCIATED POINTER!")
					end
				end
			end
		end
		if deh.pointers then
			for number, data in pairs(deh.pointers) do
				local frameIndex = data.codepframe
				if frameIndex ~= nil then
					local stateIndex = pointers.frames[number]
					if stateIndex ~= nil then
						local state = states[stateIndex]
						if state.action ~= nil then
							-- Apply the new action/code pointer
							state.action = frameIndex
						else
							print("NOTICE: DEHACKED Pointer # " .. tostring(number) ..
								  " tries to assign an action to a state that doesn't have one!")
						end
					else
						print("NOTICE: DEHACKED Pointer # " .. tostring(number) ..
							  " doesn't have an associated frame pointer!")
					end
				else
					print("NOTICE: DEHACKED Pointer # " .. tostring(number) .. " has no codepframe defined!")
				end
			end
		end
	end
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
			[17] = {text = "$E2TEXT", secret = false, bg = "EP2CUTSC"},
			[26] = {text = "$E3TEXT", secret = false, bg = "EP3CUTSC"},
			[35] = {text = "$E4TEXT", secret = false, bg = "EP4CUTSC"},
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

	-- Load the appropriate strings based on the detected game
	if matchedGame == "srb2" then
		-- Autopatch SRB2 March 2000 Prototype
		doom.gamemode = "registered"
		doom.defaultgravity = FRACUNIT/2
		doom.issrb2 = true

		local inf = mobjinfo[MT_DOOM_REDPILLARWITHSKULL]
		inf.radius = 64*FRACUNIT
		inf.height = 1*FRACUNIT
		inf.flags = MF_SOLID|MF_FLOAT|MF_NOGRAVITY|MF_NOSECTOR
		inf.mass = 10000000
		states[S_DOOM_REDPILLARWITHSKULL_1].sprite = SPR_NULL

		local inf = mobjinfo[MT_DOOM_HEALTHBONUS]
		inf.flags = inf.flags|MF_NOGRAVITY
		
		-- Load SRB2 strings
		doom.loadStrings("srb2")
		
	elseif matchedGame == "ultdoom"
		or matchedGame == "shareware"
		or matchedGame == "doom1"
		or matchedGame == "doom2"
		or matchedGame == "tnt"
		or matchedGame == "plutonia"
	then
		if matchedGame == "doom2" or matchedGame == "tnt" or matchedGame == "plutonia" then
			doom.gamemode = "commercial"
			if matchedGame == "tnt" then
				doom.mapString = "THUSTR_"
			elseif matchedGame == "plutonia" then
				doom.mapString = "PHUSTR_"
			end
		elseif matchedGame == "ultdoom" then
			doom.gamemode = "retail"
		elseif matchedGame != "shareware" then
			doom.gamemode = "registered"
		else
			doom.gamemode = "shareware"
		end
		
		-- Load Doom strings
		doom.loadStrings("doom")
		
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
	elseif matchedGame == "chex1" then
		-- Chex Quest (hopefully counts for Chex Quest 2 aswell)
		doom.gamemode = "registered"

		-- Load Chex Quest strings
		doom.loadStrings("chex")
		
		doom.textscreenmaps = {[5] = {text = "$CHEXWIN", secret = false, bg = "EP1CUTSC"}}
		doom.titlemenus.menu.entries[1].goto = "newgame"
		doom.dropTable = {}
		doom.lastmap = 5
	end
end

local function aaa()
	doLoadingShit()
	doDehacked()
end

addHook("AddonLoaded", aaa)
aaa()