doom.byeMessages = {
	"BYE!",
	"Thanks, Bye!",
	"See you later!"
}

doom.rndMessages = {
	PEASANT = {
		"PLEASE DON'T HURT ME.",

		"IF YOU'RE LOOKING TO HURT ME, I'M \n" ..
		"NOT REALLY WORTH THE EFFORT.",

		"I DON'T KNOW ANYTHING.",

		"GO AWAY OR I'LL CALL THE GUARDS!",

		"I WISH SOMETIMES THAT ALL THESE \n" ..
		"REBELS WOULD JUST LEARN THEIR \n" ..
		"PLACE AND STOP THIS NONSENSE.",

		"JUST LEAVE ME ALONE, OK?",

		"I'M NOT SURE, BUT SOMETIMES I THINK \n" ..
		"THAT I KNOW SOME OF THE ACOLYTES.",

		"THE ORDER'S GOT EVERYTHING AROUND HERE PRETTY WELL LOCKED UP TIGHT.",

		"THERE'S NO WAY THAT THIS IS JUST A \n" ..
		"SECURITY FORCE.",

		"I'VE HEARD THAT THE ORDER IS REALLY \n" ..
		"NERVOUS ABOUT THE FRONT'S \n" ..
		"ACTIONS AROUND HERE."
	},

	REBEL = {
		"THERE'S NO WAY THE ORDER WILL \n" ..
		"STAND AGAINST US.",

		"WE'RE ALMOST READY TO STRIKE. \n" ..
		"MACIL'S PLANS ARE FALLING IN PLACE.",

		"WE'RE ALL BEHIND YOU, DON'T WORRY.",

		"DON'T GET TOO CLOSE TO ANY OF THOSE BIG ROBOTS. THEY'LL MELT YOU DOWN \n" ..
		"FOR SCRAP!",

		"THE DAY OF OUR GLORY WILL SOON \n" ..
		"COME, AND THOSE WHO OPPOSE US WILL \n" ..
		"BE CRUSHED!",

		"DON'T GET TOO COMFORTABLE. WE'VE \n" ..
		"STILL GOT OUR WORK CUT OUT FOR US.",

		"MACIL SAYS THAT YOU'RE THE NEW \n" ..
		"HOPE. BEAR THAT IN MIND.",

		"ONCE WE'VE TAKEN THESE CHARLATANS DOWN, WE'LL BE ABLE TO REBUILD THIS " ..
		"WORLD AS IT SHOULD BE.",

		"REMEMBER THAT YOU AREN'T FIGHTING \n" ..
		"JUST FOR YOURSELF, BUT FOR \n" ..
		"EVERYONE HERE AND OUTSIDE.",

		"AS LONG AS ONE OF US STILL STANDS, \n" ..
		"WE WILL WIN."
	},

	AGUARD = {
		"MOVE ALONG,  PEASANT.",

		"FOLLOW THE TRUE FAITH, ONLY THEN \n" ..
		"WILL YOU BEGIN TO UNDERSTAND.",

		"ONLY THROUGH DEATH CAN ONE BE \n" ..
		"TRULY REBORN.",

		"I'M NOT INTERESTED IN YOUR USELESS \n" ..
		"DRIVEL.",

		"IF I HAD WANTED TO TALK TO YOU I \n" ..
		"WOULD HAVE TOLD YOU SO.",

		"GO AND ANNOY SOMEONE ELSE!",

		"KEEP MOVING!",

		"IF THE ALARM GOES OFF, JUST STAY OUT OF OUR WAY!",

		"THE ORDER WILL CLEANSE THE WORLD \n" ..
		"AND USHER IT INTO THE NEW ERA.",

		"PROBLEM?  NO, I THOUGHT NOT."
	},

	BEGGAR = {
		"ALMS FOR THE POOR?",

		"WHAT ARE YOU LOOKING AT, SURFACER?",

		"YOU WOULDN'T HAVE ANY EXTRA FOOD, WOULD YOU?",

		"YOU  SURFACE PEOPLE WILL NEVER \n" ..
		"                                      UNDERSTAND US.",

		"HA, THE GUARDS CAN'T FIND US.  THOSE \n" ..
		"IDIOTS DON'T EVEN KNOW WE EXIST.",

		"ONE DAY EVERYONE BUT THOSE WHO SERVE THE ORDER WILL BE FORCED TO " ..
		"JOIN US.",

		"STARE NOW,  BUT YOU KNOW THAT THIS WILL BE YOUR OWN FACE ONE DAY.",

		"THERE'S NOTHING THING MORE \n" ..
		"ANNOYING THAN A SURFACER WITH AN ATTITUDE!",

		"THE ORDER WILL MAKE SHORT WORK OF YOUR PATHETIC FRONT.",

		"WATCH YOURSELF SURFACER. WE KNOW OUR ENEMIES!"
	},

	PGUARD = {
		"WE ARE THE HANDS OF FATE. TO EARN \n" ..
		"OUR WRATH IS TO FIND OBLIVION!",

		"THE ORDER WILL CLEANSE THE WORLD \n" ..
		"OF THE WEAK AND CORRUPT!",

		"OBEY THE WILL OF THE MASTERS!",

		"LONG LIFE TO THE BROTHERS OF THE \n" ..
		"ORDER!",

		"FREE WILL IS AN ILLUSION THAT BINDS \n" ..
		"THE WEAK MINDED.",

		"POWER IS THE PATH TO GLORY. TO \n" ..
		"FOLLOW THE ORDER IS TO WALK THAT \n" ..
		"PATH!",

		"TAKE YOUR PLACE AMONG THE \n" ..
		"RIGHTEOUS, JOIN US!",

		"THE ORDER PROTECTS ITS OWN.",

		"ACOLYTES?  THEY HAVE YET TO SEE THE FULL GLORY OF THE ORDER.",

		"IF THERE IS ANY HONOR INSIDE THAT \n" ..
		"PATHETIC SHELL OF A BODY, \n" ..
		"YOU'LL ENTER INTO THE ARMS OF THE \n" ..
		"ORDER."
	}
}

for i = 0, 0x173 do
	local hex = string.format("%06x", i)
	freeslot("sfx_" + hex)
end

doom.voices = {
    PRO1 = sfx_000001,
    PRO2 = sfx_000002,
    PRO3 = sfx_000003,
    PRO4 = sfx_000004,
    PRO5 = sfx_000005,
    PRO6 = sfx_000006,
    PRO7 = sfx_000007,
    QFMRM1 = sfx_000008,
    QFMRM2 = sfx_000009,
    QFMRM3 = sfx_00000a,
    QFMRM4 = sfx_00000b,
    QFMRM5 = sfx_00000c,
    QFMRM6 = sfx_00000d,
    QFMRM7 = sfx_00000e,
    QFMRM8 = sfx_00000f,
    ADG01 = sfx_000010,
    AG301 = sfx_000011,
    AGG01 = sfx_000012,
    BBX01 = sfx_000013,
    BBX02 = sfx_000014,
    BGG01 = sfx_000015,
    BGG02 = sfx_000016,
    CTT01 = sfx_000017,
    CTT02 = sfx_000018,
    DER01 = sfx_000019,
    DER02 = sfx_00001A,
    DER03 = sfx_00001B,
    DGG01 = sfx_00001C,
    DGG02 = sfx_00001D,
    DGG03 = sfx_00001E,
    DGTBL = sfx_00001F,
    DOW01 = sfx_000020,
    DRTBL = sfx_000021,
    DWTBL = sfx_000022,
    DWW01 = sfx_000023,
    F1TBLA = sfx_000024,
    F2TBLA = sfx_000025,
    F3TBLA = sfx_000026,
    FOR01A = sfx_000027,
    FOR02A = sfx_000028,
    FOR03A = sfx_000029,
    FOR04A = sfx_00002A,
    FOTBLA = sfx_00002B,
    FP101A = sfx_00002C,
    FP102A = sfx_00002D,
    FP201A = sfx_00002E,
    FP301A = sfx_00002F,
    GEO01 = sfx_000030,
    GEO02 = sfx_000031,
    GEO03 = sfx_000032,
    GETBL = sfx_000033,
    GOTBL = sfx_000034,
    GOV01 = sfx_000035,
    GOV02 = sfx_000036,
    GOV03 = sfx_000037,
    GOV04 = sfx_000038,
    GOV05 = sfx_000039,
    GOV06 = sfx_00003A,
    GOV07 = sfx_00003B,
    GOV08 = sfx_00003C,
    GOV09 = sfx_00003D,
    GOV10 = sfx_00003E,
    GOV11 = sfx_00003F,
    GOV6A1 = sfx_000040,
    HA001 = sfx_000041,
    HA002 = sfx_000042,
    HA003 = sfx_000043,
    HA004 = sfx_000044,
    HA005 = sfx_000045,
    HA006 = sfx_000046,
    HA007 = sfx_000047,
    HATBL = sfx_000048,
    JDW01 = sfx_000049,
    JDW02 = sfx_00004A,
    JWTBL = sfx_00004B,
    KET01 = sfx_00004C,
    KET02 = sfx_00004D,
    KET03 = sfx_00004E,
    KETBL = sfx_00004F,
    KEV01 = sfx_000050,
    KEV02 = sfx_000051,
    KNTBL = sfx_000052,
    LOM03 = sfx_000053,
    LOM04 = sfx_000054,
    LOM05 = sfx_000055,
    LOM06 = sfx_000056,
    MAC01 = sfx_000057,
    MAC02 = sfx_000058,
    MAC03 = sfx_000059,
    MAC04 = sfx_00005a,
    MAC05 = sfx_00005b,
    MAC06 = sfx_00005c,
    MAC07 = sfx_00005d,
    MAC08 = sfx_00005e,
    MAC09 = sfx_00005f,
    MAC10 = sfx_000060,
    MAC10A1 = sfx_000061,
    MAC10B1 = sfx_000062,
    MAC11 = sfx_000063,
    MAC12 = sfx_000064,
    MAC13 = sfx_000065,
    MAC14 = sfx_000066,
    MAC15 = sfx_000067,
    MAC16 = sfx_000068,
    MAC17 = sfx_000069,
    MAC18 = sfx_00006a,
    MAC19 = sfx_00006b,
    MAC20 = sfx_00006c,
    MAC666 = sfx_00006d,
    MAE01 = sfx_00006e,
    MAE02 = sfx_00006f,
    MAE03 = sfx_000070,
    MAE04 = sfx_000071,
    MAE05 = sfx_000072,
    MAE06 = sfx_000073,
    MAG01 = sfx_000074,
    MAG02 = sfx_000075,
    MAG03 = sfx_000076,
    MAG04 = sfx_000077,
    MCTBL = sfx_000078,
    MACRWD = sfx_000079,
    MLTBL = sfx_00007a,
    MOTBL = sfx_00007b,
    ORC01 = sfx_00007c,
    ORC02 = sfx_00007d,
    ORC03 = sfx_00007e,
    ORC04 = sfx_00007f,
    ORC05 = sfx_000080,
    ORC06 = sfx_000081,
    ORC07 = sfx_000082,
    ORE01 = sfx_000083,
    ORE02 = sfx_000084,
    ORTBL = sfx_000085,
    PDG01 = sfx_000086,
    PDG02 = sfx_000087,
    PDG03 = sfx_000088,
    PPP01A = sfx_000089,
    PPP02A = sfx_00008A,
    PPP03A = sfx_00008B,
    PPP04 = sfx_00008C,
    PPP05 = sfx_00008D,
    PPP06A = sfx_00008E,
    PPP07A = sfx_00008F,
    PPP08 = sfx_000090,
    PRTBL = sfx_000091,
    QUI01 = sfx_000092,
    QUI02 = sfx_000093,
    QUI03 = sfx_000094,
    QUI04 = sfx_000095,
    QUI05 = sfx_000096,
    QUI06 = sfx_000097,
    QUTBL = sfx_000098,
    REBRM1 = sfx_000099,
    REBRM2 = sfx_00009A,
    REBRM3 = sfx_00009B,
    REBRM4 = sfx_00009C,
    REBRM5 = sfx_00009D,
    REBRM6 = sfx_00009E,
    REBRM7 = sfx_00009F,
    REBRM8 = sfx_0000A0,
    REBRM9 = sfx_0000A1,
    RET01 = sfx_0000a2,
    RET02 = sfx_0000a3,
    RET03 = sfx_0000a4,
    RET04 = sfx_0000a5,
    RET05 = sfx_0000a6,
    RET06 = sfx_0000a7,
    RET07 = sfx_0000a8,
    RET08 = sfx_0000a9,
    RET09 = sfx_0000aa,
    RET10 = sfx_0000ab,
    RET11 = sfx_0000ac,
    RET12 = sfx_0000ad,
    RETBL = sfx_0000ae,
    RGG01 = sfx_0000af,
    RGTBL = sfx_0000B0,
    BGG03 = sfx_0000B1,
    RIC01 = sfx_0000B2,
    RIC02 = sfx_0000B3,
    RIE01 = sfx_0000B4,
    RPP01 = sfx_0000B5,
    RRTBL = sfx_0000B6,
    SAM01A = sfx_0000B7,
    SAM02A = sfx_0000B8,
    SAM03A = sfx_0000B9,
    SAM04A = sfx_0000BA,
    SAM05A = sfx_0000BB,
    SATBL = sfx_0000BC,
    SS501B = sfx_0000BD,
    SS502B = sfx_0000BE,
    SS503B = sfx_0000BF,
    SS601A = sfx_0000C0,
    SS602A = sfx_0000C1,
    SS603A = sfx_0000C2,
    SUR4A1 = sfx_0000C3,
    TBTBL = sfx_0000C4,
    TCB01 = sfx_0000C5,
    TCB02 = sfx_0000C6,
    TCB03 = sfx_0000C7,
    TCC01 = sfx_0000C8,
    TCH01 = sfx_0000C9,
    TCH02 = sfx_0000CA,
    TCH03 = sfx_0000CB,
    TCT01 = sfx_0000CC,
    TETBL = sfx_0000CD,
    TTTBL = sfx_0000CE,
    WDM01 = sfx_0000CF,
    WDM02 = sfx_0000D0,
    WER01 = sfx_0000D1,
    WER02 = sfx_0000D2,
    WER03 = sfx_0000D3,
    WER05 = sfx_0000D4,
    WER06 = sfx_0000D5,
    WER07 = sfx_0000D6,
    WER08 = sfx_0000D7,
    WER09 = sfx_0000D8,
    WNTBL = sfx_0000D9,
    WOR01 = sfx_0000DA,
    WOR02 = sfx_0000DB,
    WOR03 = sfx_0000DC,
    WRTBL = sfx_0000DD,
    VOC1 = sfx_0000DE,
    VOC2 = sfx_0000DF,
    VOC3 = sfx_0000E0,
    VOC4 = sfx_0000E1,
    VOC5 = sfx_0000E2,
    VOC6 = sfx_0000E3,
    VOC7 = sfx_0000E4,
    VOC8 = sfx_0000E5,
    VOC9 = sfx_0000E6,
    VOC10 = sfx_0000E7,
    VOC11 = sfx_0000E8,
    VOC12 = sfx_0000E9,
    VOC13 = sfx_0000EA,
    VOC14 = sfx_0000EB,
    VOC15 = sfx_0000EC,
    VOC16 = sfx_0000ED,
    VOC17 = sfx_0000EE,
    VOC18 = sfx_0000EF,
    VOC19 = sfx_0000F0,
    VOC20 = sfx_0000F1,
    VOC21 = sfx_0000F2,
    VOC22 = sfx_0000F3,
    VOC23 = sfx_0000F4,
    VOC24 = sfx_0000F5,
    VOC25 = sfx_0000F6,
    VOC26 = sfx_0000F7,
    VOC27 = sfx_0000F8,
    VOC28 = sfx_0000F9,
    VOC29 = sfx_0000FA,
    VOC30 = sfx_0000FB,
    VOC31 = sfx_0000FC,
    VOC32 = sfx_0000FD,
    VOC33 = sfx_0000FE,
    VOC34 = sfx_0000FF,
    VOC35 = sfx_000100,
    VOC36 = sfx_000101,
    VOC37 = sfx_000102,
    VOC38 = sfx_000103,
    VOC39 = sfx_000104,
    VOC40 = sfx_000105,
    VOC41 = sfx_000106,
    VOC42 = sfx_000107,
    VOC43 = sfx_000108,
    VOC44 = sfx_000109,
    VOC45 = sfx_00010A,
    VOC46 = sfx_00010B,
    VOC47 = sfx_00010C,
    VOC48 = sfx_00010D,
    VOC49 = sfx_00010E,
    VOC50 = sfx_00010F,
    VOC51 = sfx_000110,
    VOC52 = sfx_000111,
    VOC53 = sfx_000112,
    VOC54 = sfx_000113,
    VOC55 = sfx_000114,
    VOC56 = sfx_000115,
    VOC57 = sfx_000116,
    VOC58 = sfx_000117,
    VOC59 = sfx_000118,
    VOC60 = sfx_000119,
    VOC61 = sfx_00011A,
    VOC62 = sfx_00011B,
    VOC63 = sfx_00011C,
    VOC64 = sfx_00011D,
    VOC65 = sfx_00011E,
    VOC66 = sfx_00011F,
    VOC67 = sfx_000120,
    VOC68 = sfx_000121,
    VOC69 = sfx_000122,
    VOC70 = sfx_000123,
    VOC71 = sfx_000124,
    VOC72 = sfx_000125,
    VOC73 = sfx_000126,
    VOC74 = sfx_000127,
    VOC75 = sfx_000128,
    VOC76 = sfx_000129,
    VOC77 = sfx_00012A,
    VOC78 = sfx_00012B,
    VOC79 = sfx_00012C,
    VOC80 = sfx_00012D,
    VOC81 = sfx_00012E,
    VOC82 = sfx_00012F,
    VOC83 = sfx_000130,
    VOC84 = sfx_000131,
    VOC85 = sfx_000132,
    VOC86 = sfx_000133,
    VOC87 = sfx_000134,
    VOC88 = sfx_000135,
    VOC89 = sfx_000136,
    VOC90 = sfx_000137,
    VOC91 = sfx_000138,
    VOC92 = sfx_000139,
    VOC93 = sfx_00013A,
    VOC94 = sfx_00013B,
    VOC95 = sfx_00013C,
    VOC96 = sfx_00013D,
    VOC97 = sfx_00013E,
    VOC98 = sfx_00013F,
    VOC99 = sfx_000140,
    VOC100 = sfx_000141,
    VOC101 = sfx_000142,
    VOC102 = sfx_000143,
    VOC103 = sfx_000144,
    VOC104 = sfx_000145,
    VOC105 = sfx_000146,
    VOC106 = sfx_000147,
    VOC120 = sfx_000148,
    VOC121 = sfx_000149,
    VOC122 = sfx_00014A,
    VOC128 = sfx_00014B,
    VOC129 = sfx_00014C,
    VOC130 = sfx_00014D,
    VOC200 = sfx_00014E,
    VOC201 = sfx_00014F,
    VOC202 = sfx_000150,
    VOC203 = sfx_000151,
    VOC204 = sfx_000152,
    VOC205 = sfx_000153,
    VOC206 = sfx_000154,
    VOC207 = sfx_000155,
    VOC208 = sfx_000156,
    VOC209 = sfx_000157,
    VOC210 = sfx_000158,
    VOC211 = sfx_000159,
    VOC212 = sfx_00015A,
    VOC213 = sfx_00015B,
    VOC214 = sfx_00015C,
    VOC215 = sfx_00015D,
    VOC216 = sfx_00015E,
    VOC217 = sfx_00015F,
    VOC218 = sfx_000160,
    VOC219 = sfx_000161,
    VOC220 = sfx_000162,
    VOC221 = sfx_000163,
    VOC222 = sfx_000164,
    VOC223 = sfx_000165,
    VOC224 = sfx_000166,
    VOC225 = sfx_000167,
    VOC226 = sfx_000168,
    VOC227 = sfx_000169,
    VOC228 = sfx_00016A,
    VOC229 = sfx_00016B,
    VOC230 = sfx_00016C,
    VOC231 = sfx_00016D,
    VOC232 = sfx_00016E,
    VOC233 = sfx_00016F,
    VOC234 = sfx_000170,
    VOC235 = sfx_000171,
    VOC236 = sfx_000172,
    VOC237 = sfx_000173,
}