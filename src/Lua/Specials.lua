/*
x1 = Once (repeatable = false)
xR = Repeatable (repeatable = true)
S = Switch/Use ("switch")
W = Walk Over ("walk")
G = Gunshot/Hit ("gunshot")
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
		type = "door", kind = "open", stay = false, owner = "sector",
		fastdoor = false, repeatable = true, activationType = "switch"
	},
	[26] = {
		type = "door", lock = doom.KEY_BLUE|doom.KEY_SKULLBLUE, kind = "open", stay = false, owner = "sector",
		fastdoor = false, repeatable = true, activationType = "switch", denyMessage = "$PD_BLUEK"
	},
	[27] = {
		type = "door", lock = doom.KEY_YELLOW|doom.KEY_SKULLYELLOW, kind = "open", stay = false, owner = "sector",
		fastdoor = false, repeatable = true, activationType = "switch", denyMessage = "$PD_YELLOWK"
	},
	[28] = {
		type = "door", lock = doom.KEY_RED|doom.KEY_SKULLRED, kind = "open", stay = false, owner = "sector",
		fastdoor = false, repeatable = true, activationType = "switch", denyMessage = "$PD_REDK"
	},
	[31] = {
		type = "door", kind = "open", stay = true, owner = "sector",
		fastdoor = false, repeatable = false, activationType = "switch"
	},
	[32] = {
		type = "door", lock = doom.KEY_BLUE|doom.KEY_SKULLBLUE, kind = "open", stay = true, owner = "sector",
		fastdoor = false, repeatable = false, activationType = "switch", denyMessage = "$PD_BLUEK"
	},
	[33] = {
		type = "door", lock = doom.KEY_RED|doom.KEY_SKULLRED, kind = "open", stay = true, owner = "sector",
		fastdoor = false, repeatable = false, activationType = "switch", denyMessage = "$PD_REDK"
	},
	[34] = {
		type = "door", lock = doom.KEY_YELLOW|doom.KEY_SKULLYELLOW, kind = "open", stay = true, owner = "sector",
		fastdoor = false, repeatable = false, activationType = "switch", denyMessage = "$PD_YELLOWK"
	},
	[46] = {
		type = "door", kind = "open", stay = true,
		fastdoor = false, repeatable = true, activationType = "gunshot"
	},
	[117] = {
		type = "door", kind = "open", stay = false, owner = "sector",
		fastdoor = true, repeatable = true, activationType = "switch"
	},
	[118] = {
		type = "door", kind = "open", stay = true, owner = "sector",
		fastdoor = true, repeatable = false, activationType = "switch"
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
		type = "door", kind = "open", stay = false, owner = "sector",
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
	[76] = {
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
	[105] = {
		type = "door", kind = "open", stay = false,
		fastdoor = true, repeatable = true, activationType = "walk"
	},
	[112] = {
		type = "door", kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch"
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
		type = "door", lock = doom.KEY_BLUE|doom.KEY_SKULLBLUE, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch", denyMessage = "$PD_BLUEO"
	},
	[99] = {
		type = "door", lock = doom.KEY_BLUE|doom.KEY_SKULLBLUE, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch", denyMessage = "$PD_BLUEO"
	},
	[135] = {
		type = "door", lock = doom.KEY_RED|doom.KEY_SKULLRED, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch", denyMessage = "$PD_REDO"
	},
	[134] = {
		type = "door", lock = doom.KEY_RED|doom.KEY_SKULLRED, kind = "open", stay = true,
		fastdoor = true, repeatable = true, activationType = "switch", denyMessage = "$PD_REDO"
	},
	[137] = {
		type = "door", lock = doom.KEY_YELLOW|doom.KEY_SKULLYELLOW, kind = "open", stay = true,
		fastdoor = true, repeatable = false, activationType = "switch", denyMessage = "$PD_YELLOWO"
	},
	[136] = {
		type = "door", lock = doom.KEY_YELLOW|doom.KEY_SKULLYELLOW, kind = "open", stay = true,
		fastdoor = true, repeatable = true, activationType = "switch", denyMessage = "$PD_YELLOWO"
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
		repeatable = true, activationType = "switch", speed = "fast"
	},
	[122] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "switch", speed = "fast"
	},
	[121] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = false, activationType = "walk", speed = "fast"
	},
	[120] = {
		type = "lift", mode = "lowerwaitraise",
		repeatable = true, activationType = "walk", speed = "fast"
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
		speed = "fast", repeatable = false, activationType = "walk"
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
	[5] = {
		type = "floor", action = "raise", target = "lowestceiling",
		repeatable = false, activationType = "walk"
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

	[24] = {
		type = "floor", action = "lower", target = "lowestceiling",
		repeatable = false, activationType = "gunshot"
	},
	[64] = {
		type = "floor", action = "lower", target = "lowestceiling",
		repeatable = true, activationType = "switch"
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

	[230] = {
		type = "elevator",
		target = "higherfloor",
		repeatable = true,
		activationType = "switch"
	},

	[234] = {
		type = "elevator",
		target = "lowerfloor",
		repeatable = true,
		activationType = "switch"
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
		repeatable = false, activationType = "switch"
	},
	[51] = {
		type = "exit", secret = true,
		repeatable = false, activationType = "switch"
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
		place = "side", repeatable = true, activationType = "always"
	},

	[253] = {
		type = "scroll", direction = "line", speed = "line",
		repeatable = true, activationType = "always",
		place = "floor", carryobjects = true, target = "tagged"
	},

	[244] = {
		type = "teleport", linetoline = true, preserveangle = true,
		crossSide = "front", activationType = "walk", repeatable = true
	}
}

/*
Detailed generalized linedef specification
Boom has added generalized linedef types that permit the parameters of linedef actions to be nearly independently chosen. Instead of looking at the linedef special as one single number which corresponds to one single type, it is divided into entire ranges of effects where parts of the numbers are used as parameters.

Effect	Start of range	End of range	Size of range 
Generalized crushers	12 160 (0x2f80)	12 287 (0x2fff)	128
Generalized stairs	12 288 (0x3000)	13 311 (0x33ff)	1024
Generalized lifts	13 312 (0x3400)	14 335 (0x37ff)	1024
Generalized locked doors	14 336 (0x3800)	15 359 (0x3bff)	1024
Generalized doors	15 360 (0x3c00)	16 383 (0x3fff)	1024
Generalized ceilings	16 384 (0x4000)	24 575 (0x5fff)	8192
Generalized floors	24 576 (0x6000)	32 767 (0x7fff)	8192
Total	12 160 (0x2f80)	32 767 (0x7fff)	20 608
The following sections define the placement and meaning of the bit fields within each linedef category. Fields in the description are listed in increasing numeric order.

Some nomenclature:

Target height designations:

H means highest, L means lowest, N means next, F means floor, C means ceiling, n means neighbor, Cr means crush, sT means shortest lower texture.

Texture change designations:

c0n - change texture, change sector type to 0, numeric model change
c0t - change texture, change sector type to 0, trigger model change
cTn - change texture only, numeric model change
cTt - change texture only, trigger model change
cSn - change texture and sector type to model's, numeric model change
cSt - change texture and sector type to model's, trigger model change
A trigger model change uses the sector on the first side of the trigger for its model. A numeric model change looks at the sectors adjoining the tagged sector at the target height, and chooses the one across the lowest numbered two sided line for its model. If no model exists, no change occurs. Note that in DOOM II v1.9, no model meant an illegal sector type was generated.

Generalized floors (8192 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
model	trig/numeric -or- nomonst/monst	1	0x0020	5
direct	down/up	1	0x0040	6
target	HnF/LnF/NnF/LnC/C/sT/24/32	3	0x0380	7
change	nochg/zero/txtonly/type	2	0x0c00	10
crush	no/yes	1	0x1000	12
DETH Nomenclature:

W1[m] F->HnF DnS [c0t] [Cr]
WR[m] F->LnF DnN [c0n]
S1[m] F->NnF DnF [cTt]
SR[m] F->LnC DnT [cTn]
G1[m] F->C   UpS [cSt]
GR[m] FbysT  UpN [cSn]
D1[m] Fby24  UpF
DR[m] Fby32  UpT
Notes:

When change is nochg, model is 1 when monsters can activate trigger otherwise monsters cannot activate it.
The change fields mean the following:
nochg - means no texture change or type change
zero - means sector type is zeroed, texture copied from model
txtonly - means sector type unchanged, texture copied from model
type - means sector type and floor texture are copied from model
down/up specifies the "normal" direction for moving. If the target specifies motion in the opposite direction, motion is instant. Otherwise it occurs at speed specified by speed field.
Speed is 1/2/4/8 units per tic
If change is nonzero then model determines which sector is copied. If model is 0 its the sector on the first side of the trigger. If model is 1 (numeric) then the model sector is the sector at destination height on the opposite side of the lowest numbered two sided linedef around the tagged sector. If it does not exist no change occurs.
Generalized ceilings (8192 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
model	trig/numeric -or- nomonst/monst	1	0x0020	5
direct	down/up	1	0x0040	6
target	HnC/LnC/NnC/HnF/F/sT/24/32	3	0x0380	7
change	nochg/zero/txtonly/type	2	0x0c00	10
crush	no/yes	1	0x1000	12
DETH Nomenclature:

W1[m] C->HnC DnS [Cr] [c0t]
WR[m] C->LnC DnN      [c0n]
S1[m] C->NnC DnF      [cTt]
SR[m] C->HnF DnT      [cTn]
G1[m] C->F   UpS      [cSt]
GR[m] CbysT  UpN      [cSn]
D1[m] Cby24  UpF
DR[m] Cby32  UpT
Notes:

When change is nochg, model is 1 when monsters can activate trigger otherwise monsters cannot activate it.
The change fields mean the following:
nochg - means no texture change or type change
zero - means sector type is zeroed, texture copied from model
txtonly - means sector type unchanged, texture copied from model
type - means sector type and ceiling texture are copied from model
down/up specifies the "normal" direction for moving. If the target specifies motion in the opposite direction, motion is instant. Otherwise it occurs at speed specified by speed field.
Speed is 1/2/4/8 units per tic
If change is nonzero then model determines which sector is copied. If model is 0 its the sector on the first side of the trigger. If model is 1 (numeric) then the model sector is the sector at destination height on the opposite side of the lowest numbered two sided linedef around the tagged sector. If it does not exist no change occurs.
Generalized doors (1024 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
kind	odc/o/cdo/c	2	0x0060	5
monster	n/y	1	0x0080	7
delay	1/4/9/30 (secs)	2	0x0300	8
DETH Nomenclature:

W1[m] OpnD{1|4|9|30}Cls S
WR[m] Opn               N
S1[m] ClsD{1|4|9|30}Opn F
SR[m] Cls               T
G1[m]
GR[m]
D1[m]
DR[m]
Notes:

The odc (Open, Delay, Close) and cdo (Close, Delay, Open) kinds use the delay field. The o (Open and Stay) and c (Close and Stay) kinds do not.
The precise delay timings in gametics are: 35/150/300/1050
Speed is 2/4/8/16 units per tic
Generalized locked doors (1024 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
kind	odc/o	1	0x0020	5
lock	any/rc/bc/yc/rs/bs/ys/all	3	0x01c0	6
sk=ck	n/y	1	0x0200	9
DETH Nomenclature:

W1[m] OpnDCls           S Any
WR[m] Opn               N R{C|S|K}
S1[m]                   F B{C|S|K}
SR[m]                   T Y{C|S|K}
G1[m]                     All{3|6}
GR[m]
D1[m]
DR[m]
Notes:

Delay for odc kind is constant at 150 gametics or about 4.333 secs
The lock field allows any key to open a door, or a specific key to open a door, or all keys to open a door.
If the sk=ck field is 0 (n) skull and cards are different keys, otherwise they are treated identically. Hence an "all" type door requires 3 keys if sk=ck is 1, and 6 keys if sk=ck is 0.
Speed is 2/4/8/16 units per tic
Generalized lifts (1024 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
monster	n/y	1	0x0020	5
delay	1/3/5/10 (secs)	2	0x00c0	6
target	LnF/NnF/LnC/LnF<->HnF(perp.)	2	0x0300	8
DETH Nomenclature:

W1[m] Lft  F->LnFD{1|3|5|10}    S
WR[m]      F->NnFD{1|3|5|10}    N
S1[m]      F->LnCD{1|3|5|10}    F
SR[m]      HnF<->LnFD{1|3|5|10} T
G1[m]
GR[m]
D1[m]
DR[m]
Notes:

The precise delay timings in gametics are: 35/105/165/350
Speed is 1/2/4/8 units per tic
If the target specified is above starting floor height, or does not exist the lift does not move when triggered. NnF is Next Lowest Neighbor Floor.
Starting a perpetual lift between lowest and highest neighboring floors locks out all other floor actions on the sector, even if it is stopped with the non-extended stop perpetual floor function.
Generalized stairs (1024 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
monster	n/y	1	0x0020	5
step	4/8/16/24	2	0x00c0	6
dir	dn/up	1	0x0100	8
igntxt	n/y	1	0x0200	9
DETH Nomenclature:

W1[m] Stair Dn s4  S [Ign]
WR[m]       Up s8  N
S1[m]          s16 F
SR[m]          s24 T
G1[m]
GR[m]
D1[m]
DR[m]
Notes:

Speed is .25/.5/2/4 units per tic
If igntxt is 1, then the staircase will not stop building when a step does not have the same texture as the previous.
A retriggerable stairs builds up and down alternately on each trigger.
Generalized crushers (128 types)
field	description	NBits	Mask	Shift 
trigger	W1/WR/S1/SR/G1/GR/P1/PR	3	0x0007	0
speed	slow/normal/fast/turbo	2	0x0018	3
monster	n/y	1	0x0020	5
silent	n/y	1	0x0040	6
DETH Nomenclature:

W1[m] Crusher S [Silent]
WR[m]         N
S1[m]         F
SR[m]         T
G1[m]
GR[m]
D1[m]
DR[m]
Notes:

Speed is 1/2/4/8 units per second, faster means slower damage as usual.
If silent is 1, the crusher is totally quiet, no start/stop sounds.	
*/

-- put a specified group of generalized specials into doom.lineActions
local function applyGroupConfig(groupConfig, baseSpecial, baseEntry)
	if not groupConfig.size then
		-- Missing, we have to !diy it
		local maxBit = 0
		for _, field in ipairs(groupConfig.fields) do
			local fieldMax = (1 << field.bits) - 1
			if field.shift + field.bits > maxBit then
				maxBit = field.shift + field.bits
			end
		end
		groupConfig.size = 1 << maxBit
	end
	for i = 0, groupConfig.size - 1 do
		local action = deepcopy(groupConfig.baseEntry or baseEntry or {})
		for _, field in ipairs(groupConfig.fields) do
			local fieldValue = (i >> field.shift) & ((1 << field.bits) - 1)
			-- If field value breaches the allotted bits, RUN!!!
			if fieldValue >= (1 << field.bits) then
				error(string.format("Field value %d exceeds allotted bits for field %s", fieldValue, field.description))
			end
			local fieldConfig = groupConfig[field.description][fieldValue]
			if not fieldConfig then
				error("Missing config for "..field.description.."="..fieldValue)
			end
			for key, value in pairs(fieldConfig) do
				action[key] = value
			end
		end
		doom.lineActions[baseSpecial + i] = action
	end
end

-- Generalized crusher mapping
-- Only stores what CHANGES between each value setting!!
-- You'll need to combine the fields to get a valid thinker back
local generalizedCrusherConfig = {
	fields = {
		{bits = 3, shift = 0, description = "trigger"},
		{bits = 2, shift = 3, description = "speed"},
		{bits = 1, shift = 5, description = "monster"},
		{bits = 1, shift = 6, description = "silent"}
	},
	trigger = {
		[0]={activationType="walk",repeatable=false}, -- W1
		[1]={activationType="walk",repeatable=true},  -- WR
		[2]={activationType="switch",repeatable=false}, -- S1
		[3]={activationType="switch",repeatable=true},  -- SR
		[4]={activationType="gunshot",repeatable=false}, -- G1
		[5]={activationType="gunshot",repeatable=true},  -- GR
		[6]={activationType="push",repeatable=false}, -- P1
		[7]={activationType="push",repeatable=true},  -- PR
	},
	speed = {
		[0] = {speed = "slow"},
		[1] = {speed = "normal"},
		[2] = {speed = "fast"},
		[3] = {speed = "turbo"}
	},
	monster = {
		[0] = {monsters = false},
		[1] = {monsters = true}
	},
	silent = {
		[0] = {silent = false},
		[1] = {silent = true}
	},
	baseEntry = {
		type = "crusher", mode = "start"
	}
}

applyGroupConfig(generalizedCrusherConfig, 0x2f80)

local generalizedStairConfig = {
	fields = {
		{bits = 3, shift = 0, description = "trigger"},
		{bits = 2, shift = 3, description = "speed"},
		{bits = 1, shift = 5, description = "monster"},
		{bits = 2, shift = 6, description = "step"},
		{bits = 1, shift = 8, description = "dir"},
		{bits = 1, shift = 9, description = "igntxt"}
	},
	trigger = {
		[0]={activationType="walk",repeatable=false}, -- W1
		[1]={activationType="walk",repeatable=true},  -- WR
		[2]={activationType="switch",repeatable=false}, -- S1
		[3]={activationType="switch",repeatable=true},  -- SR
		[4]={activationType="gunshot",repeatable=false}, -- G1
		[5]={activationType="gunshot",repeatable=true},  -- GR
		[6]={activationType="push",repeatable=false}, -- P1
		[7]={activationType="push",repeatable=true},  -- PR
	},
	speed = {
		[0] = {speed = "slow"},
		[1] = {speed = "normal"},
		[2] = {speed = "fast"},
		[3] = {speed = "turbo"}
	},
	monster = {
		[0] = {monsters = false},
		[1] = {monsters = true}
	},
	step = {
		[0] = {step = 4},
		[1] = {step = 8},
		[2] = {step = 16},
		[3] = {step = 24}
	},
	dir = {
		[0] = {dir = "down"},
		[1] = {dir = "up"}
	},
	igntxt = {
		[0] = {igntxt = false},
		[1] = {igntxt = true}
	},
	baseEntry = {
		type = "stair"
		-- Action SHOULD be determined by dir
		-- Maybe, hopefully??
	}
}

applyGroupConfig(generalizedStairConfig, 0x3000)

/*
Floor targets
Lowest Neighbor Floor (LnF)
This means that the floor moves to the height of the lowest neighboring floor including the floor itself. If the floor direction is up (only possible with generalized floors) motion is instant, else at the floor's speed.
Next Neighbor Floor (NnF)
This means that the floor moves up to the height of the lowest adjacent floor greater in height than the current, or down to the height of the highest adjacent floor less in height than the current, as determined by the floor's direction. Instant motion is not possible in this case. If no such floor exists, the floor does not move.
Lowest Neighbor Ceiling (LnC)
This means that the floor height changes to the height of the lowest ceiling possessed by any neighboring sector, including that floor's ceiling. If the target height is in the opposite direction to floor motion, motion is instant, otherwise at the floor action's speed.
8 Under Lowest Neighbor Ceiling (8uLnC)
This means that the floor height changes to 8 less than the height of the lowest ceiling possessed by any neighboring sector, including that floor's ceiling. If the target height is in the opposite direction to floor motion, motion is instant, otherwise at the floor action's speed.
Highest Neighbor Floor (HnF)
This means that the floor height changes to the height of the highest neighboring floor, excluding the floor itself. If no neighbor floor exists, the floor moves down to -32000. If the target height is in the opposite direction to floor motion, the motion is instant, otherwise it occurs at the floor action's speed.
8 Above Highest Neighbor Floor (8aHnF)
This means that the floor height changes to 8 above the height of the highest neighboring floor, excluding the floor itself. If no neighbor floor exists, the floor moves down to -31992. If the target height is in the opposite direction to floor motion, the motion is instant, otherwise it occurs at the floor action's speed.
Ceiling
The floor moves up until it is at ceiling height, instantly if floor direction is down (only available with generalized types), at the floor speed if the direction is up.
24 Units (24)
The floor moves 24 units in the floor action's direction. Instant motion is not possible with this linedef type.
32 Units (32)
The floor moves 32 units in the floor action's direction. Instant motion is not possible with this linedef type.
512 Units (512)
The floor moves 512 units in the floor action's direction. Instant motion is not possible with this linedef type.
Shortest Lower Texture (SLT)
The floor moves to the height of the shortest lower texture on the boundary of the sector, in the floor direction. Instant motion is not possible with this type. In the case that there is no surrounding texture the motion is to -32000 or +32000 depending on direction.
None
Some pure texture type changes are provided for changing the floor texture and/or sector type without moving the floor.

Ceiling targets
Highest Neighbor Ceiling (HnC)
This means that the ceiling moves to the height of the highest neighboring ceiling NOT including the ceiling itself. If the ceiling direction is down (only possible with generalized ceilings) motion is instant, else at the ceiling's speed. If no adjacent ceiling exists the ceiling moves to -32000 units.
Next Neighbor Ceiling (NnC)
This means that the ceiling moves up to the height of the lowest adjacent ceiling greater in height than the current, or to the height of the highest adjacent ceiling less in height than the current, as determined by the ceiling's direction. Instant motion is not possible in this case. If no such ceiling exists, the ceiling does not move.
Lowest Neighbor Ceiling (LnC)
This means that the ceiling height changes to the height of the lowest ceiling possessed by any neighboring sector, NOT including itself. If the target height is in the opposite direction to ceiling motion, motion is instant, otherwise at the ceiling action's speed. If no adjacent ceiling exists the ceiling moves to 32000 units.
Highest Neighbor Floor (HnF)
This means that the ceiling height changes to the height of the highest neighboring floor, excluding the ceiling's floor itself. If no neighbor floor exists, the ceiling moves down to -32000 or the ceiling's floor, whichever is higher. If the target height is in the opposite direction to ceiling motion, the motion is instant, otherwise it occurs at the ceiling action's speed.
Floor
The ceiling moves down until its at floor height, instantly if ceiling direction is up (only available with generalized types), at the ceiling speed if the direction is down.
8 Above Floor (8aF)
This means that the ceiling height changes to 8 above the height of the ceiling's floor. If the target height is in the opposite direction to ceiling motion, the motion is instant, otherwise it occurs at the ceiling action's speed.
24 Units (24)
The ceiling moves 24 units in the ceiling action's direction. Instant motion is not possible with this linedef type.
32 Units (32)
The ceiling moves 32 units in the ceiling action's direction. Instant motion is not possible with this linedef type.
Shortest Upper Texture (SUT)
The ceiling moves the height of the shortest upper texture on the boundary of the sector, in the ceiling direction. Instant motion is not possible with this type. In the case that there is no surrounding texture the motion is to -32000 or +32000 depending on direction.
*/

local generalizedLiftConfig = {
	fields = {
		{bits = 3, shift = 0, description = "trigger"},
		{bits = 2, shift = 3, description = "speed"},
		{bits = 1, shift = 5, description = "monster"},
		{bits = 2, shift = 6, description = "delay"},
		{bits = 2, shift = 8, description = "target"}
	},
	trigger = {
		[0]={activationType="walk",repeatable=false}, -- W1
		[1]={activationType="walk",repeatable=true},  -- WR
		[2]={activationType="switch",repeatable=false}, -- S1
		[3]={activationType="switch",repeatable=true},  -- SR
		[4]={activationType="gunshot",repeatable=false}, -- G1
		[5]={activationType="gunshot",repeatable=true},  -- GR
		[6]={activationType="push",repeatable=false}, -- P1
		[7]={activationType="push",repeatable=true},  -- PR
	},
	speed = {
		[0] = {speed = "slow"},
		[1] = {speed = "normal"},
		[2] = {speed = "fast"},
		[3] = {speed = "turbo"}
	},
	monster = {
		[0] = {monsters = false},
		[1] = {monsters = true}
	},
	delay = {
		[0] = {delay = 35}, -- 1 sec
		[1] = {delay = 105}, -- 3 sec
		[2] = {delay = 175}, -- 5 sec
		[3] = {delay = 350} -- 10 sec
	},
	target = {
		[0] = {target = "lowestfloor"},
		[1] = {target = "nextlowestfloor"},
		[2] = {target = "lowestceiling"},
		[3] = {target = "perpendicular"}
	},
	baseEntry = {
		type = "lift"
	}
}

applyGroupConfig(generalizedLiftConfig, 0x3400)