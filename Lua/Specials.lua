/*
x1 = Once
xR = Repeatable
S = Switch/Use
W = Walk Over
G = Gunshot/Hit
*/

/*
OTHER:
All sectors tagged 666 will lower their floor to the lowest adjacent floor when all Barons are killed in E1M8
All sectors tagged 666 will act like Door Open Stay (Fast) when all Cyberdemons are killed in E4M6
All sectors tagged 666 will lower their floor to the lowest adjacent floor when all Spiderdemons are killed in E4M8
All sectors tagged 666 will lower their floor to the lowest adjacent floor when all Mancubi are killed in MAP07
All sectors tagged 667 will act like Floor Raise to Shortest Texture when all Arachnotrons are killed in MAP07
All sectors tagged 666 will act like Door Open Stay when all Commander Keens are killed in any map

SECRET EXITS:
E1M3 = E1M9
E2M5 = E2M9
E3M6 = E3M9
E4M2 = E4M9
MAP15 = MAP31
MAP31 = MAP32
Secret exits outside of the above maps restart the current map.
*/

doom.lineActions = {
	-- === Direct ===
	[1] = {
		type = "door", kind = "open", stay = false,
		fastdoor = false, repeatable = true, activationType = "interact"
	},
	[26] = {
		type = "door", lock = doom.KEY_BLUE, kind = "open", stay = false,
		fastdoor = false, repeatable = true, activationType = "interact"
	},
	[27] = {
		type = "door", lock = doom.KEY_YELLOW, kind = "open", stay = false,
		fastdoor = false, repeatable = true, activationType = "interact"
	},
	[28] = {
		type = "door", lock = doom.KEY_RED, kind = "open", stay = false,
		fastdoor = false, repeatable = true, activationType = "interact"
	},
	[31] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = false, activationType = "interact"
	},
	[32] = {
		type = "door", lock = doom.KEY_BLUE, kind = "open", stay = true,
		fastdoor = false, repeatable = false, activationType = "interact"
	},
	[33] = {
		type = "door", lock = doom.KEY_RED, kind = "open", stay = true,
		fastdoor = false, repeatable = false, activationType = "interact"
	},
	[34] = {
		type = "door", lock = doom.KEY_YELLOW, kind = "open", stay = true,
		fastdoor = false, repeatable = false, activationType = "interact"
	},
	[46] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = true, activationType = "gunshot"
	},
	[117] = {
		type = "door", kind = "open", stay = false,
		fastdoor = true, repeatable = true, activationType = "interact"
	},
	[118] = {
		type = "door", kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "interact"
	},

	-- === Remote ===
	[29] = {
		type = "door", kind = "open", stay = false,
		fastdoor = false, repeatable = false, activationType = "switch"
	},
	[63] = {
		type = "door", kind = "open", stay = false,
		fastdoor = false, repeatable = true, activationType = "switch"
	},
	[4] = {
		type = "door", kind = "open", stay = false,
		fastdoor = false, repeatable = false, activationType = "walk"
	},
	[90] = {
		type = "door", kind = "open", stay = false,
		fastdoor = false, repeatable = true, activationType = "walk"
	},

	[103] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = false, activationType = "switch"
	},
	[61] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = true, activationType = "switch"
	},
	[2] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = false, activationType = "walk"
	},
	[86] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = true, activationType = "walk"
	},

	[50] = {
		type = "door", kind = "close", stay = true,
		fastdoor = false, repeatable = false, activationType = "switch"
	},
	[42] = {
		type = "door", kind = "close", stay = true,
		fastdoor = false, repeatable = true, activationType = "switch"
	},
	[3] = {
		type = "door", kind = "close", stay = true,
		fastdoor = false, repeatable = false, activationType = "walk"
	},
	[75] = {
		type = "door", kind = "close", stay = true,
		fastdoor = false, repeatable = true, activationType = "walk"
	},

	[16] = {
		type = "door", kind = "closewaitopen", delay = 30*TICRATE,
		fastdoor = false, repeatable = false, activationType = "walk"
	},
	[70] = {
		type = "door", kind = "closewaitopen", delay = 30*TICRATE,
		fastdoor = false, repeatable = true, activationType = "walk"
	},

	-- Fast variants
	[111] = {
		type = "door", kind = "open", stay = false,
		fastdoor = true, repeatable = false, activationType = "switch"
	},
	[114] = {
		type = "door", kind = "open", stay = false,
		fastdoor = true, repeatable = true, activationType = "switch"
	},
	[108] = {
		type = "door", kind = "open", stay = false,
		fastdoor = true, repeatable = false, activationType = "walk"
	},
	[112] = {
		type = "door", kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "walk"
	},
	[115] = {
		type = "door", kind = "open", stay = true,
		fastdoor = true, repeatable = true, activationType = "switch"
	},
	[109] = {
		type = "door", kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "walk"
	},
	[106] = {
		type = "door", kind = "open", stay = true,
		fastdoor = true, repeatable = true, activationType = "walk"
	},

	[113] = {
		type = "door", kind = "close", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch"
	},
	[116] = {
		type = "door", kind = "close", stay = true,
		fastdoor = true, repeatable = true, activationType = "switch"
	},
	[110] = {
		type = "door", kind = "close", stay = true,
		fastdoor = true, repeatable = false, activationType = "walk"
	},
	[107] = {
		type = "door", kind = "close", stay = true,
		fastdoor = true, repeatable = true, activationType = "walk"
	},

	-- Key locked fast stays
	[133] = {
		type = "door", lock = doom.KEY_BLUE, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch"
	},
	[103] = {
		type = "door", lock = doom.KEY_BLUE, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch"
	},
	[135] = {
		type = "door", lock = doom.KEY_RED, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch"
	},
	[134] = {
		type = "door", lock = doom.KEY_RED, kind = "open", stay = true,
		fastdoor = true, repeatable = true, activationType = "switch"
	},
	[137] = {
		type = "door", lock = doom.KEY_YELLOW, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch"
	},
	[136] = {
		type = "door", lock = doom.KEY_YELLOW, kind = "open", stay = true,
		fastdoor = true, repeatable = true, activationType = "switch"
	},

	-- === Ceilings ===
	[187] = {
		type = "ceiling", action = "lower", target = "8abovefloor",
		repeatable = true, activationType = "switch"
	},
	[167] = {
		type = "ceiling", action = "lower", target = "8abovefloor",
		repeatable = false, activationType = "switch"
	},
	[72] = {
		type = "ceiling", action = "lower", target = "8abovefloor",
		repeatable = true, activationType = "walk"
	},
	[44] = {
		type = "ceiling", action = "lower", target = "8abovefloor",
		repeatable = false, activationType = "walk"
	},
	[43] = {
		type = "ceiling", action = "lower", target = "floor",
		repeatable = true, activationType = "switch"
	},
	[41] = {
		type = "ceiling", action = "lower", target = "floor",
		repeatable = false, activationType = "switch"
	},
	[152] = {
		type = "ceiling", action = "lower", target = "floor",
		repeatable = true, activationType = "walk"
	},
	[145] = {
		type = "ceiling", action = "lower", target = "floor",
		repeatable = false, activationType = "walk"
	},
	[186] = {
		type = "ceiling", action = "lower", target = "highest",
		repeatable = true, activationType = "switch"
	},
	[166] = {
		type = "ceiling", action = "lower", target = "highest",
		repeatable = false, activationType = "switch"
	},
	[151] = {
		type = "ceiling", action = "raise", target = "highest",
		repeatable = true, activationType = "walk"
	},
	[40] = {
		type = "ceiling", action = "raise", target = "highest",
		repeatable = false, activationType = "walk"
	},
	[206] = {
		type = "ceiling", action = "raise", target = "highestfloor",
		repeatable = true, activationType = "switch"
	},
	[204] = {
		type = "ceiling", action = "raise", target = "highestfloor",
		repeatable = false, activationType = "switch"
	},
	[202] = {
		type = "ceiling", action = "raise", target = "highestfloor",
		repeatable = true, activationType = "walk"
	},
	[200] = {
		type = "ceiling", action = "raise", target = "highestfloor",
		repeatable = false, activationType = "walk"
	},
	[205] = {
		type = "ceiling", action = "raise", target = "lowest",
		repeatable = true, activationType = "switch"
	},
	[203] = {
		type = "ceiling", action = "raise", target = "lowest",
		repeatable = false, activationType = "switch"
	},
	[201] = {
		type = "ceiling", action = "raise", target = "lowest",
		repeatable = true, activationType = "walk"
	},
	[199] = {
		type = "ceiling", action = "raise", target = "lowest",
		repeatable = false, activationType = "walk"
	},

	-- Crushers
	[184] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = false, repeatable = true, activationType = "switch"
	},
	[49] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = false, repeatable = false, activationType = "switch"
	},
	[73] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = false, repeatable = true, activationType = "walk"
	},
	[25] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = false, repeatable = false, activationType = "walk"
	},
	[183] = {
		type = "crusher", speed = "fast", mode = "start",
		silent = false, repeatable = true, activationType = "switch"
	},
	[164] = {
		type = "crusher", speed = "fast", mode = "start",
		silent = false, repeatable = false, activationType = "switch"
	},
	[77] = {
		type = "crusher", speed = "fast", mode = "start",
		silent = false, repeatable = true, activationType = "walk"
	},
	[6] = {
		type = "crusher", speed = "fast", mode = "start",
		silent = false, repeatable = false, activationType = "walk"
	},
	[185] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = true, repeatable = true, activationType = "switch"
	},
	[165] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = true, repeatable = false, activationType = "switch"
	},
	[150] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = true, repeatable = true, activationType = "walk"
	},
	[141] = {
		type = "crusher", speed = "slow", mode = "start",
		silent = true, repeatable = false, activationType = "walk"
	},
	[168] = {
		type = "crusher", mode = "stop",
		repeatable = false, activationType = "switch"
	},
	[188] = {
		type = "crusher", mode = "stop",
		repeatable = true, activationType = "switch"
	},
	[57] = {
		type = "crusher", mode = "stop",
		repeatable = false, activationType = "walk"
	},
	[74] = {
		type = "crusher", mode = "stop",
		repeatable = true, activationType = "walk"
	},

	-- === Lifts ===
	[21] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "switch"
	},
	[62] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = true, activationType = "switch"
	},
	[10] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "walk"
	},
	[88] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = true, activationType = "walk", monsters = true
	},
	[123] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "switch", speed = "fast"
	},
	[122] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = true, activationType = "switch", speed = "fast"
	},
	[121] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "walk", speed = "fast"
	},
	[120] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = true, activationType = "walk", speed = "fast"
	},
	[121] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "walk", speed = "fast"
	},

	-- === Floors (raise/lower, oscillating) ===
	[53] = {
		type = "floor", action = "oscillate", speed = "slow",
		repeatable = false, activationType = "walk"
	},
	[87] = {
		type = "floor", action = "oscillate", speed = "slow",
		repeatable = true, activationType = "walk"
	},
	[54] = {
		type = "floor", action = "oscillate_stop",
		repeatable = false, activationType = "walk"
	},
	[89] = {
		type = "floor", action = "oscillate_stop",
		repeatable = true, activationType = "walk"
	},

	-- Raise to next higher floor
	[18] = {
		type = "floor", action = "raise", target = "nextfloor",
		repeatable = false, activationType = "switch"
	},
	[69] = {
		type = "floor", action = "raise", target = "nextfloor",
		repeatable = true, activationType = "switch"
	},
	[119] = {
		type = "floor", action = "raise", target = "nextfloor",
		repeatable = false, activationType = "walk"
	},
	[128] = {
		type = "floor", action = "raise", target = "nextfloor",
		repeatable = true, activationType = "walk"
	},
	[131] = {
		type = "floor", action = "raise", target = "nextfloor",
		speed = "fast", repeatable = false, activationType = "switch"
	},
	[130] = {
		type = "floor", action = "raise", target = "nextfloor",
		speed = "fast", repeatable = true, activationType = "switch"
	},

	-- Raise to next higher (Changes)
	[20] = {
		type = "floor", action = "raise", target = "nextfloor",
		changes = true, repeatable = false, activationType = "switch"
	},
	[68] = {
		type = "floor", action = "raise", target = "nextfloor",
		changes = true, repeatable = true, activationType = "switch"
	},
	[22] = {
		type = "floor", action = "raise", target = "nextfloor",
		changes = true, repeatable = false, activationType = "walk"
	},
	[95] = {
		type = "floor", action = "raise", target = "nextfloor",
		changes = true, repeatable = true, activationType = "walk"
	},
	[47] = {
		type = "floor", action = "raise", target = "nextfloor",
		changes = true, repeatable = false, activationType = "gunshot"
	},

	-- Raise to ceiling variants
	[101] = {
		type = "floor", action = "raise", target = "lowestceiling",
		repeatable = false, activationType = "switch"
	},
	[91] = {
		type = "floor", action = "raise", target = "lowestceiling",
		repeatable = true, activationType = "walk"
	},

	-- Raise to 8 below ceiling
	[55] = {
		type = "floor", action = "raise", target = "8belowceiling",
		crush = true, repeatable = false, activationType = "switch"
	},
	[65] = {
		type = "floor", action = "raise", target = "8belowceiling",
		crush = true, repeatable = true, activationType = "switch"
	},
	[56] = {
		type = "floor", action = "raise", target = "8belowceiling",
		crush = true, repeatable = false, activationType = "walk"
	},
	[94] = {
		type = "floor", action = "raise", target = "8belowceiling",
		crush = true, repeatable = true, activationType = "walk"
	},

	-- Raise fixed amount
	[58] = {
		type = "floor", action = "raise", amount = 24,
		repeatable = false, activationType = "walk"
	},
	[92] = {
		type = "floor", action = "raise", amount = 24,
		repeatable = true, activationType = "walk"
	},

	[15] = {
		type = "floor", action = "raise", amount = 24,
		changes = true, repeatable = false, activationType = "switch"
	},
	[66] = {
		type = "floor", action = "raise", amount = 24,
		changes = true, repeatable = true, activationType = "switch"
	},
	[59] = {
		type = "floor", action = "raise", amount = 24,
		changes = true, repeatable = false, activationType = "walk"
	},
	[93] = {
		type = "floor", action = "raise", amount = 24,
		changes = true, repeatable = true, activationType = "walk"
	},
	[14] = {
		type = "floor", action = "raise", amount = 32,
		changes = true, repeatable = false, activationType = "switch"
	},
	[67] = {
		type = "floor", action = "raise", amount = 32,
		changes = true, repeatable = true, activationType = "switch"
	},
	[140] = {
		type = "floor", action = "raise", amount = 512,
		repeatable = false, activationType = "switch"
	},

	-- Raise by shortest lower texture
	[30] = {
		type = "floor", action = "raise", target = "shortestlowertex",
		repeatable = false, activationType = "walk"
	},
	[96] = {
		type = "floor", action = "raise", target = "shortestlowertex",
		repeatable = true, activationType = "walk"
	},

	-- Lower to floor variants
	[23] = {
		type = "floor", action = "lower", target = "lowest",
		repeatable = false, activationType = "switch"
	},
	[60] = {
		type = "floor", action = "lower", target = "lowest",
		repeatable = true, activationType = "switch"
	},
	[38] = {
		type = "floor", action = "lower", target = "lowest",
		repeatable = false, activationType = "walk"
	},
	[82] = {
		type = "floor", action = "lower", target = "lowest",
		repeatable = true, activationType = "walk"
	},
	[37] = {
		type = "floor", action = "lower", target = "lowest",
		changes = true, repeatable = false, activationType = "walk"
	},
	[84] = {
		type = "floor", action = "lower", target = "lowest",
		changes = true, repeatable = true, activationType = "walk"
	},

	-- SRB2 March 2000-specific
	[197] = {
		type = "floor", action = "lower", target = "lowest",
		repeatable = true, activationType = "walk"
	},

	[102] = {
		type = "floor", action = "lower", target = "highest",
		repeatable = false, activationType = "switch"
	},
	[45] = {
		type = "floor", action = "lower", target = "highest",
		repeatable = true, activationType = "switch"
	},
	[19] = {
		type = "floor", action = "lower", target = "highest",
		repeatable = false, activationType = "walk"
	},
	[83] = {
		type = "floor", action = "lower", target = "highest",
		repeatable = true, activationType = "walk"
	},

	[71] = {
		type = "floor", action = "lower", target = "8abovehighest",
		speed = "fast", repeatable = false, activationType = "switch"
	},
	[70] = {
		type = "floor", action = "lower", target = "8abovehighest",
		speed = "fast", repeatable = true, activationType = "switch"
	},
	[36] = {
		type = "floor", action = "lower", target = "8abovehighest",
		speed = "fast", repeatable = false, activationType = "walk"
	},
	[98] = {
		type = "floor", action = "lower", target = "8abovehighest",
		speed = "fast", repeatable = true, activationType = "walk"
	},

	-- Donut
	[9] = {
		type = "floor", action = "donut", changes = true,
		repeatable = false, activationType = "switch"
	},

	-- === Stairs ===
	[7] = {
		type = "stair", action = "raise", amount = 8,
		repeatable = false, activationType = "switch"
	},
	[8] = {
		type = "stair", action = "raise", amount = 8,
		repeatable = false, activationType = "walk"
	},
	[127] = {
		type = "stair", action = "raise", amount = 16, speed = "fast",
		repeatable = false, activationType = "switch"
	},
	[100] = {
		type = "stair", action = "raise", amount = 16, speed = "fast",
		repeatable = false, activationType = "walk"
	},

	-- === Teleports ===
	[39] = {
		type = "teleport", monsters = false,
		repeatable = false, activationType = "walk"
	},
	[97] = {
		type = "teleport", monsters = false,
		repeatable = true, activationType = "walk"
	},
	[125] = {
		type = "teleport", monsters = true,
		repeatable = false, activationType = "walk"
	},
	[126] = {
		type = "teleport", monsters = true,
		repeatable = true, activationType = "walk"
	},

	-- === Lights ===
	[35] = {
		type = "light", target = 35,
		repeatable = false, activationType = "walk"
	},
	[79] = {
		type = "light", target = 35,
		repeatable = true, activationType = "walk"
	},
	[13] = {
		type = "light", target = 255,
		repeatable = false, activationType = "walk"
	},
	[81] = {
		type = "light", target = 255,
		repeatable = true, activationType = "walk"
	},
	[12] = {
		type = "light", target = "brightest_adjacent",
		repeatable = false, activationType = "walk"
	},
	[80] = {
		type = "light", target = "brightest_adjacent",
		repeatable = true, activationType = "walk"
	},
	[104] = {
		type = "light", target = "darkest_adjacent",
		repeatable = false, activationType = "walk"
	},
	[17] = {
		type = "light", mode = "blink", blinktime = TICRATE,
		repeatable = false, activationType = "walk"
	},
	[138] = {
		type = "light", target = 255,
		repeatable = false, activationType = "switch"
	},
	[139] = {
		type = "light", target = 35,
		repeatable = false, activationType = "switch"
	},

	-- === Exits ===
	[11] = {
		type = "exit", secret = false,
		repeatable = false, activationType = "interact"
	},
	[51] = {
		type = "exit", secret = true,
		repeatable = false, activationType = "interact"
	},
	[52] = {
		type = "exit", secret = false,
		repeatable = false, activationType = "walk"
	},
	[124] = {
		type = "exit", secret = true,
		repeatable = false, activationType = "walk"
	},

	-- === Specials ===
	[48] = {
		type = "scroll", axis = "x", direction = "left",
		repeatable = true, activationType = "always"
	},
}