local SCRIPT_CONTINUE = 0
local SCRIPT_STOP = 1
local SCRIPT_TERMINATE 	= 2
local OPEN_SCRIPTS_BASE = 1000
local PRINT_BUFFER_SIZE = 256
local GAME_SINGLE_PLAYER = 0
local GAME_NET_COOPERATIVE = 1
local GAME_NET_DEATHMATCH = 2
local TEXTURE_TOP = 0
local TEXTURE_MIDDLE = 1
local TEXTURE_BOTTOM = 2

-- array of the amount of immediate arguments the above opcodes take
doom.opCodeArguments = {
    -- Opcodes 0-2: 0 args
    [0] = 0, [1] = 0, [2] = 0,
    -- Opcode 3: 1 arg
    [3] = 1,
    -- Opcodes 4-8: 1 arg each
    [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1,
    -- Opcodes 9-13: 2-6 args respectively
    [9] = 2, [10] = 3, [11] = 4, [12] = 5, [13] = 6,
    -- Opcode 54: 0 args
    [54] = 0,
    -- Opcodes 55-56: 1 arg each
    [55] = 1, [56] = 1,
    -- Opcode 57: 0 args
    [57] = 0,
    -- Opcode 58: 2 args
    [58] = 2,
    -- Opcode 59: 0 args
    [59] = 0,
    -- Opcode 60: 2 args
    [60] = 2,
    -- Opcode 61: 0 args
    [61] = 0,
    -- Opcode 62: 1 arg
    [62] = 1,
    -- Opcode 63: 0 args
    [63] = 0,
    -- Opcode 64: 1 arg
    [64] = 1,
    -- Opcode 65: 0 args
    [65] = 0,
    -- Opcode 66: 2 args
    [66] = 2,
    -- Opcode 67: 0 args
    [67] = 0,
    -- Opcode 68: 2 args
    [68] = 2,
    -- Opcode 69: 0 args (was missing)
    [69] = 0,
    -- Opcode 78: 0 args (unary minus, no immediate args)
    [78] = 0,
    -- Opcode 79: 1 arg (was missing)
    [79] = 1,
    -- Opcode 80: 0 args
    [80] = 0,
    -- Opcodes 81-82: 1 arg each
    [81] = 1, [82] = 1,
    -- Opcode 83: 0 args
    [83] = 0,
    -- Opcode 84: 1 arg
    [84] = 1,
    -- Opcodes 85-86: 0 args
    [85] = 0, [86] = 0,
    -- Opcodes 87-89: 1 arg each
    [87] = 1, [88] = 1, [89] = 1,
    -- Opcodes 90-93: 0 args
    [90] = 0, [91] = 0, [92] = 0, [93] = 0,
    -- Opcodes 94-95: 2 args each
    [94] = 2, [95] = 2,
    -- Opcode 96: 1 arg
    [96] = 1,
    -- Opcode 97: 4 args
    [97] = 4,
    -- Opcode 98: 2 args
    [98] = 2,
    -- Opcode 99: 7 args
    [99] = 7,
    -- Opcode 100: 3 args
    [100] = 3,
    -- Opcode 101: 0 args
    [101] = 0,
}

-- Bulk ranges using loops for maximum compression
-- Opcodes 14-24: 0 args (arithmetic and comparison)
for i = 14, 24 do doom.opCodeArguments[i] = 0 end

-- Opcodes 25-53: 1 arg each (variable operations)
for i = 25, 53 do doom.opCodeArguments[i] = 1 end

-- Opcodes 70-77: 0 args (logical and bitwise)
for i = 70, 77 do doom.opCodeArguments[i] = 0 end

/*
Opcode	DWORDs	Name	Args	Stack diff	Logic
0	1	NOP	-	0	No effect
1	1	Terminate	-	0	Stops the script, terminating its thinker
2	1	Suspend	-	0	Suspends execution of the script until it is manually resumed
3	2	PushNumber	Imm	+1	Pushes immediate argument onto the stack
4	2	LSpec1	Imm, Stack	-1	Executes immediate argument as line special number, with 1 argument popped from stack
5	2	LSpec2	Imm, Stack x2	-2	Executes immediate argument as line special number, with 2 arguments popped from stack[notes 1]
6	2	LSpec3	Imm, Stack x3	-3	Executes immediate argument as line special number, with 3 arguments popped from stack
7	2	LSpec4	Imm, Stack x4	-4	Executes immediate argument as line special number, with 4 arguments popped from stack
8	2	LSpec5	Imm, Stack x5	-5	Executes immediate argument as line special number, with 5 arguments popped from stack
9	3	LSpec1Direct	Imm x2	0	Executes immediate argument 0 as line special number, with immediate argument 1 as args[notes 2]
10	4	LSpec2Direct	Imm x3	0	Executes immediate argument 0 as line special number, with immediate arguments 1 - 2 as args
11	5	LSpec3Direct	Imm x4	0	Executes immediate argument 0 as line special number, with immediate arguments 1 - 3 as args
12	6	LSpec4Direct	Imm x5	0	Executes immediate argument 0 as line special number, with immediate arguments 1 - 4 as args
13	7	LSpec5Direct	Imm x6	0	Executes immediate argument 0 as line special number, with immediate arguments 1 - 5 as args
14	1	Add	Stack x2	-1	Push(Pop() + Pop())
15	1	Subtract	Stack x2	-1	t = Pop(); Push(Pop() - t)
16	1	Multiply	Stack x2	-1	Push(Pop() * Pop())
17	1	Divide	Stack x2	-1	t = Pop(); Push(Pop() / t)
18	1	Modulus	Stack x2	-1	t = Pop(); Push(Pop() % t)
19	1	EQ	Stack x2	-1	Compare equality; Push(Pop() == Pop())
Opcode	DWORDs	Name	Args	Stack diff	Logic
20	1	NE	Stack x2	-1	Compare non-equality; Push(Pop() != Pop())
21	1	LT	Stack x2	-1	Compare less-than; t = Pop(); Push(Pop() < t)
22	1	GT	Stack x2	-1	Compare greater-than; t = Pop(); Push(Pop() > t)
23	1	LE	Stack x2	-1	Compare less-than-or-equal; t = Pop(); Push(Pop() <= t)
24	1	GE	Stack x2	-1	Compare greater-than-or-equal; t = Pop(); Push(Pop() >= t)
25	2	AssignScriptVar	Imm, Stack	-1	scriptvars[imm] = Pop()
26	2	AssignMapVar	Imm, Stack	-1	mapvars[imm] = Pop()
27	2	AssignWorldVar	Imm, Stack	-1	worldvars[imm] = Pop()
28	2	PushScriptVar	Imm	+1	Push(scriptvars[imm])
29	2	PushMapVar	Imm	+1	Push(mapvars[imm])
30	2	PushWorldVar	Imm	+1	Push(worldvars[imm])
31	2	AddScriptVar	Imm, Stack	-1	scriptvars[imm] += Pop()
32	2	AddMapVar	Imm, Stack	-1	mapvars[imm] += Pop()
33	2	AddWorldVar	Imm, Stack	-1	worldvars[imm] += Pop()
34	2	SubScriptVar	Imm, Stack	-1	scriptvars[imm] -= Pop()
35	2	SubMapVar	Imm, Stack	-1	mapvars[imm] -= Pop()
36	2	SubWorldVar	Imm, Stack	-1	worldvars[imm] -= Pop()
37	2	MulScriptVar	Imm, Stack	-1	scriptvars[imm] *= Pop()
38	2	MulMapVar	Imm, Stack	-1	mapvars[imm] *= Pop()
39	2	MulWorldVar	Imm, Stack	-1	worldvars[imm] *= Pop()
Opcode	DWORDs	Name	Args	Stack diff	Logic
40	2	DivScriptVar	Imm, Stack	-1	scriptvars[imm] /= Pop()
41	2	DivMapVar	Imm, Stack	-1	mapvars[imm] /= Pop()
42	2	DivWorldVar	Imm, Stack	-1	worldvars[imm] /= Pop()
43	2	ModScriptVar	Imm, Stack	-1	scriptvars[imm] %= Pop()
44	2	ModMapVar	Imm, Stack	-1	mapvars[imm] %= Pop()
45	2	ModWorldVar	Imm, Stack	-1	worldvars[imm] %= Pop()
46	2	IncScriptVar	Imm	0	scriptvars[imm] += 1
47	2	IncMapVar	Imm	0	mapvars[imm] += 1
48	2	IncWorldVar	Imm	0	worldvars[imm] += 1
49	2	DecScriptVar	Imm	0	scriptvars[imm] -= 1
50	2	DecMapVar	Imm	0	mapvars[imm] -= 1
51	2	DecWorldVar	Imm	0	worldvars[imm] -= 1
52	2	Goto	Imm	0	Unconditional jump to immediate absolute offset
53	2	IfGoto	Imm, Stack	-1	Jump to immediate absolute offset if value popped from stack is not zero
54	1	Drop	-	-1	Pops the stack, discarding the value
55	1	Delay	Stack	-1	Sets script delay counter to popped value
56	2	DelayDirect	Imm	0	Sets script delay counter to immediate operand
57	1	Random	Stack x2	-1	high = Pop(); low = Pop(); Push(low + (P_Random() % (high - low + 1)))
58	3	RandomDirect	Imm x2	+1	low = imm0; high = imm1; Push(low + (P_Random() % (high - low + 1)))
59	1	ThingCount	Stack x2	-1	tid = Pop(); type = Pop(); Push(ThingCount(type, tid))
Opcode	DWORDs	Name	Args	Stack diff	Logic
60	3	ThingCountDirect	Imm x2	+1	type = imm0; tid = imm1; Push(ThingCount(type, tid))
61	1	TagWait	Stack	-1	Pop stack and set value to script waitValue; set script state to "waiting for tag"
62	2	TagWaitDirect	Imm	0	Assign imm0 to script waitValue; set script state to "waiting for tag"
63	1	PolyWait	Stack	-1	Pop stack and assign value to script waitValue; set script state to "waiting for polyobject"
64	2	PolyWaitDirect	Imm	0	Assign imm0 to script waitValue; set script state to "waiting for polyobject"
65	1	ChangeFloor	Stack x2	-2	flat = strings[Pop()]; tag = Pop(); ChangeFloor(tag, flat)
66	3	ChangeFloorDirect	Imm x2	0	tag = imm0; flat = strings[imm1]; ChangeFloor(tag, flat)
67	1	ChangeCeiling	Stack x2	-2	flat = strings[Pop()]; tag = Pop(); ChangeCeiling(tag, flat)
68	3	ChangeCeilingDirect	Imm x2	0	tag = imm0; flat = strings[imm1]; ChangeCeiling(tag, flat)
69	1	Restart	-	0	Unconditional jump to beginning of script's bytecode
70	1	AndLogical	Stack x2	?	Push(Pop() && Pop())[notes 3]
71	1	OrLogical	Stack x2	?	Push(Pop() || Pop())[notes 3]
72	1	AndBitwise	Stack x2	-1	Push(Pop() & Pop())
73	1	OrBitwise	Stack x2	-1	Push(Pop() | Pop())
74	1	EorBitwise	Stack x2	-1	Push(Pop() ^ Pop())
75	1	NegateLogical	Stack x2	0	Push(!Pop())
76	1	LShift	Stack x2	-1	t = Pop(); Push(Pop() << t)
77	1	RShift	Stack x2	-1	t = Pop(); Push(Pop() >> t)
78	1	UnaryMinus	Stack	0	Push(-Pop())
79	2	IfNotGoto	Imm, Stack	-1	Jump to immediate absolute offset if popped value is equal to zero
Opcode	DWORDs	Name	Args	Stack diff	Logic
80	1	LineSide	-	+1	Pushes side (0 or 1) on which the linedef was activated to start this script (always 0 if not started by a linedef)
81	1	ScriptWait	Stack	-1	Pop value and assign to script waitValue; set script state to "waiting on script"
82	2	ScriptWaitDirect	Imm	0	Assign immediate operand to script waitValue; set script state to "waiting on script"
83	1	ClearLineSpecial	-	0	If this script was started from a linedef, that linedef's special will be set to 0.
84	3	CaseGoto	Imm x2, Stack	0 or -1	Conditional jump for switch case statements; CaseGoto()
85	1	BeginPrint	-	0	Clears print buffer
86	1	EndPrint	-	0	If script activator is valid player, send accumulated print buffer to that player; otherwise, send to local client player (consoleplayer)
87	1	PrintString	Stack	-1	Concatenate strings[Pop()] with print buffer
88	1	PrintNumber	Stack	-1	Pop value, convert integer to string as by snprintf with "%d" format specifier, and concatenate with print buffer
89	1	PrintCharacter	Stack	-1	Pop value, convert to ASCII character, and concatenate with print buffer
90	1	PlayerCount	-	+1	Push number of valid players currently in game
91	1	GameType	-	+1	Push game type value: 0 == single player, 1 == cooperative, 2 == deathmatch
92	1	GameSkill	-	+1	Push current game skill value as value from 0 (baby) to 4 (extra hard, ie. Nightmare)
93	1	Timer	-	+1	Push the amount of tics that have passed in the current level (leveltime)
94	1	SectorSound	Stack x2	-2	volume = Pop(); name = strings[Pop()]; SectorSound(name, volume)
95	1	AmbientSound	Stack x2	-2	volume = Pop(); name = strings[Pop()]; S_StartSoundAtVolume(NULL, S_GetSoundID(name), volume)
96	1	SoundSequence	Stack	-1	name = strings[Pop()]; SoundSequence(name)
97	1	SetLineTexture	Stack x4	-4	texture = strings[Pop()]; position = Pop(); side = Pop(); lineTag = Pop(); SetLineTexture(lineTag, side, position, texture)
98	1	SetLineBlocking	Stack x2	-2	Pop blocking flag (0 or 1), pop line id. Set all linedefs matching the id to blocking or non-blocking depending on flag value (1 or 0).
99	1	SetLineSpecial	Stack x7	-7	Pop arguments 4 through 0 in that order; pop special; pop line id. Set all linedefs matching the line id to have the indicated special and arguments.
100	1	ThingSound	Stack x3	-3	volume = Pop(); sound = strings[Pop()]; tid = Pop(); ThingSound(tid, sound, volume)
101	1	EndPrintBold	-	0	Send the accumulated print buffer to every valid player in the game as a yellow-colored important message

Notes
 Arguments for stack-based LSpec opcodes are placed in the args array starting from the highest index, meaning they should be pushed in ascending order (ie., 0, 1, 2, 3, 4).
 Arguments for immediate LSpecDirect opcodes are placed in the args array in the same order as they occur in the opcode.
 As written in the vanilla executable, these operations are both subject to short-circuiting logic. As a result, they may potentially leave the stack in an unpredictable state (either 0 or -1) depending on whether the first value popped is 0 or 1.
*/

doom.hexen_globalacsvars = {
	world = {},
	map = {},
}

doom.ACSInstances = {}

---@class hexenacsvm_t
---@field stack number[] The stack of the VM, used for passing arguments and storing temporary values
---@field locals table<number, number> Local variables for the currently executing script
---@field args number[] Script arguments (Unused?)
---@field globals table<number, number> Global variables shared across all scripts
---@field mapvars table<number, number> Map-specific variables
---@field ip number Instruction pointer, tracking the current position in the script's bytecode
---@field script table The script currently being executed
---@field line table The linedef that triggered the script (if applicable)
---@field side number The side of the linedef that triggered the script (if applicable)
---@field activator table The activator of the script, usually the player or thing that caused the script to run
---@field trigger table The trigger that caused the script to run (if applicable)
---@field waitstate string The current wait state of the script, if it is waiting for something
---@field delay number The remaining delay time if the script is in a delayed state
---@field opcodemap table<number, function> A mapping of opcode numbers to their corresponding handler functions in the VM
---@field new fun(line: table, side: number, activator: table): hexenacsvm_t Creates a new instance of the ACS VM for a given linedef, side, and activator
---@field execute fun(self: hexenacsvm_t, script: table): string Executes a given script's bytecode on this VM instance, returning the final state of execution ("terminated", "suspended", or "completed")
---@field pop fun(self: hexenacsvm_t): number Pops a value from the VM's stack and returns it
---@field push fun(self: hexenacsvm_t, value: number): nil Pushes a value onto the VM's stack
---@field NOP fun(self: hexenacsvm_t): number Does nothing and continues execution
---@field Terminate fun(self: hexenacsvm_t): number Terminates the script
---@field Suspend fun(self: hexenacsvm_t): number Suspends the script until it is manually resumed
---@field PushNumber fun(self: hexenacsvm_t, args: number[]): number Pushes an immediate number onto the stack
---@field LSpec1 fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 1 argument popped from the stack
---@field LSpec2 fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 2 arguments popped from the stack
---@field LSpec3 fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 3 arguments popped from the stack
---@field LSpec4 fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 4 arguments popped from the stack
---@field LSpec5 fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 5 arguments popped from the stack
---@field Lspec1Direct fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 1 immediate argument
---@field Lspec2Direct fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 2 immediate arguments
---@field Lspec3Direct fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 3 immediate arguments
---@field Lspec4Direct fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 4 immediate arguments
---@field Lspec5Direct fun(self: hexenacsvm_t, args: number[]): number Executes a line special with 5 immediate arguments
---@field Add fun(self: hexenacsvm_t, args: number[]): number Pops two values, adds them, and pushes the result
---@field Subtract fun(self: hexenacsvm_t, args: number[]): number Pops two values, subtracts the second popped from the first, and pushes the result
---@field Multiply fun(self: hexenacsvm_t, args: number[]): number Pops two values, multiplies them, and pushes the result
---@field Divide fun(self: hexenacsvm_t, args: number[]): number Pops two values, divides the first popped by the second, and pushes the result
---@field Modulus fun(self: hexenacsvm_t, args: number[]): number Pops two values, calculates the modulus, and pushes the result
---@field EQ fun(self: hexenacsvm_t, args: number[]): number Pops two values, compares for equality, and pushes 1 if equal or 0 if not
---@field NE fun(self: hexenacsvm_t, args: number[]): number Pops two values, compares for non-equality, and pushes 1 if not equal or 0 if equal
---@field LT fun(self: hexenacsvm_t, args: number[]): number Pops two values, compares if the first popped is less than the second, and pushes 1 if true or 0 if false
---@field GT fun(self: hexenacsvm_t, args: number[]): number Pops two values, compares if the first popped is greater than the second, and pushes 1 if true or 0 if false
---@field LE fun(self: hexenacsvm_t, args: number[]): number Pops two values, compares if the first popped is less than or equal to the second, and pushes 1 if true or 0 if false
---@field GE fun(self: hexenacsvm_t, args: number[]): number Pops two values, compares if the first popped is greater than or equal to the second, and pushes 1 if true or 0 if false
---@field AssignScriptVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and assigns it to a script variable
---@field AssignMapVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and assigns it to a map variable
---@field AssignWorldVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and assigns it to a world variable
---@field PushScriptVar fun(self: hexenacsvm_t, args: number[]): number Pushes a script variable onto the stack
---@field PushMapVar fun(self: hexenacsvm_t, args: number[]): number Pushes a map variable onto the stack
---@field PushWorldVar fun(self: hexenacsvm_t, args: number[]): number Pushes a world variable onto the stack
---@field AddScriptVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and adds it to a script variable
---@field AddMapVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and adds it to a map variable
---@field AddWorldVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and adds it to a world variable
---@field SubScriptVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and subtracts it from a script variable
---@field SubMapVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and subtracts it from a map variable
---@field SubWorldVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and subtracts it from a world variable
---@field MulScriptVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and multiplies it with a script variable
---@field MulMapVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and multiplies it with a map variable
---@field MulWorldVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and multiplies it with a world variable
---@field DivScriptVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and divides it by a script variable
---@field DivMapVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and divides it by a map variable
---@field DivWorldVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and divides it by a world variable
---@field ModScriptVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and calculates the modulus with a script variable
---@field ModMapVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and calculates the modulus with a map variable
---@field ModWorldVar fun(self: hexenacsvm_t, args: number[]): number Pops a value and calculates the modulus with a world variable
---@field IncScriptVar fun(self: hexenacsvm_t, args: number[]): number Increments a script variable
---@field IncMapVar fun(self: hexenacsvm_t, args: number[]): number Increments a map variable
---@field IncWorldVar fun(self: hexenacsvm_t, args: number[]): number Increments a world variable
---@field DecScriptVar fun(self: hexenacsvm_t, args: number[]): number Decrements a script variable
---@field DecMapVar fun(self: hexenacsvm_t, args: number[]): number Decrements a map variable
---@field DecWorldVar fun(self: hexenacsvm_t, args: number[]): number Decrements a world variable
---@field Goto fun(self: hexenacsvm_t, args: number[]): number Jumps to an absolute offset in the script's bytecode
---@field IfGoto fun(self: hexenacsvm_t, args: number[]): number Pops a value and jumps to an absolute offset if the value is not zero
---@field Drop fun(self: hexenacsvm_t, args: number[]): number Pops a value and discards it
---@field Delay fun(self: hexenacsvm_t, args: number[]): number Pops a value and sets the script's delay counter to that value
---@field DelayDirect fun(self: hexenacsvm_t, args: number[]): number Sets the script's delay counter to an immediate value
---@field Random fun(self: hexenacsvm_t, args: number[]): number Pops two values as a range and pushes a random number within that range
---@field RandomDirect fun(self: hexenacsvm_t, args: number[]): number Pushes a random number within an immediate range
---@field ThingCount fun(self: hexenacsvm_t, args: number[]): number Pops two values as type and tid, counts matching things, and pushes the count
---@field ThingCountDirect fun(self: hexenacsvm_t, args: number[]): number Pushes the count of things matching an immediate type and tid
---@field TagWait fun(self: hexenacsvm_t, args: number[]): number Pops a value and sets the script to wait for a tag with that value
---@field TagWaitDirect fun(self: hexenacsvm_t, args: number[]): number Sets the script to wait for a tag with an immediate value
---@field PolyWait fun(self: hexenacsvm_t, args: number[]): number Pops a value and sets the script to wait for a polyobject with that value
---@field PolyWaitDirect fun(self: hexenacsvm_t, args: number[]): number Sets the script to wait for a polyobject with an immediate value
---@field ChangeFloor fun(self: hexenacsvm_t, args: number[]): number Pops two values as tag and flat, and changes the floor of matching sectors to that flat
---@field ChangeFloorDirect fun(self: hexenacsvm_t, args: number[]): number Changes the floor of sectors matching an immediate tag to an immediate flat
---@field ChangeCeiling fun(self: hexenacsvm_t, args: number[]): number Pops two values as tag and flat, and changes the ceiling of matching sectors to that flat
---@field ChangeCeilingDirect fun(self: hexenacsvm_t, args: number[]): number Changes the ceiling of sectors matching an immediate tag to an immediate flat
---@field Restart fun(self: hexenacsvm_t, args: number[]): number Jumps to the beginning of the script's bytecode
---@field AndLogical fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a logical AND, and pushes the result
---@field OrLogical fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a logical OR, and pushes the result
---@field AndBitwise fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a bitwise AND, and pushes the result
---@field OrBitwise fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a bitwise OR, and pushes the result
---@field EorBitwise fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a bitwise XOR, and pushes the result
---@field NegateLogical fun(self: hexenacsvm_t, args: number[]): number Pops a value, performs a logical NOT, and pushes the result
---@field LShift fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a left shift, and pushes the result
---@field RShift fun(self: hexenacsvm_t, args: number[]): number Pops two values, performs a right shift, and pushes the result
---@field UnaryMinus fun(self: hexenacsvm_t, args: number[]): number Pops a value, negates it, and pushes the result
---@field LineSide fun(self: hexenacsvm_t, args: number[]): number Pushes the side of the linedef that triggered the script
---@field ScriptWait fun(self: hexenacsvm_t, args: number[]): number Pops a value and sets the script to wait for that many tics
---@field ScriptWaitDirect fun(self: hexenacsvm_t, args: number[]): number Sets the script to wait for an immediate number of tics

---@type hexenacsvm_t
local doomACS = {
    stack = {},
    locals = {},      -- local variables
    args = {},        -- script arguments
    globals = doom.hexen_globalacsvars.world,    -- shared global variable tables
    mapvars = doom.hexen_globalacsvars.map,

    ip = 1,
    script = nil,

    line = nil,
    side = 0,
    activator = nil,
    trigger = nil,

    waitstate = nil,
    delay = 0,
}

doomACS.__index = doomACS

function doomACS.new(line, side, activator)
	local instance = setmetatable({}, doomACS)
	instance.line = line
	instance.side = side
	instance.activator = activator
	instance.ip = 1
	table.insert(doom.ACSInstances, instance)
	return instance
end

function doomACS:execute(script)
	local bytecode = script.bytecode
	while self.ip <= #bytecode do
		local opcode = bytecode[self.ip]
		self.ip = self.ip + 1
		local argCount = doom.opCodeArguments[opcode]
		local args = {}
		for i = 1, argCount do
			args[i] = bytecode[self.ip]
			self.ip = self.ip + 1
		end
		local result = self.opcodemap[opcode](self, args)
		if result == SCRIPT_TERMINATE then
			return "terminated"
		elseif result == SCRIPT_STOP then
			return "suspended"
		end
	end
	return "completed"
end

function doomACS:pop()
	return table.remove(self.stack)
end

function doomACS:push(value)
	table.insert(self.stack, value)
end

function doomACS:NOP()
	return SCRIPT_CONTINUE
end

function doomACS:Terminate()
	return SCRIPT_TERMINATE
end

function doomACS:Suspend()
	return SCRIPT_STOP
end

function doomACS:PushNumber(args)
	self:push(args[1])
	return SCRIPT_CONTINUE
end

local function getLineSpecialDef(lineSpecial)
	return doom.lineActions[lineSpecial]
end

function doomACS:LSpec1(args)
	doom.hexen_addThinker(args[1], doomACS:pop(), self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:LSpec2(args)
	doom.hexen_addThinker(args[1], {args[2], doomACS:pop()}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:LSpec3(args)
	doom.hexen_addThinker(args[1], {args[2], args[3], doomACS:pop()}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:LSpec4(args)
	doom.hexen_addThinker(args[1], {args[2], args[3], args[4], doomACS:pop()}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:LSpec5(args)
	doom.hexen_addThinker(args[1], {args[2], args[3], args[4], args[5], doomACS:pop()}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:Lspec1Direct(args)
	doom.hexen_addThinker(args[1], args[2], self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:Lspec2Direct(args)
	doom.hexen_addThinker(args[1], {args[2], args[3]}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:Lspec3Direct(args)
	doom.hexen_addThinker(args[1], {args[2], args[3], args[4]}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:Lspec4Direct(args)
	doom.hexen_addThinker(args[1], {args[2], args[3], args[4], args[5]}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:Lspec5Direct(args)
	doom.hexen_addThinker(args[1], {args[2], args[3], args[4], args[5], args[6]}, self.line, self.side, self.activator)
	return SCRIPT_CONTINUE
end

function doomACS:Add(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a + b)
	return SCRIPT_CONTINUE
end

function doomACS:Subtract(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a - b)
	return SCRIPT_CONTINUE
end

function doomACS:Multiply(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a * b)
	return SCRIPT_CONTINUE
end

function doomACS:Divide(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a / b) -- We are so fucked if SRB2 does away with C-like truncation when dividing
	return SCRIPT_CONTINUE
end

function doomACS:Modulus(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a % b)
	return SCRIPT_CONTINUE
end

-- old C returns integer for normally boolean expressions, oddly
function doomACS:EQ(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a == b and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:NE(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a ~= b and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:LT(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a < b and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:GT(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a > b and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:LE(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a <= b and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:GE(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a >= b and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:AssignScriptVar(args)
	local value = self:pop()
	local varIndex = args[1]
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:AssignMapVar(args)
	local value = self:pop()
	local varIndex = args[1]
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:AssignWorldVar(args)
	local value = self:pop()
	local varIndex = args[1]
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:PushScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	self:push(value)
	return SCRIPT_CONTINUE
end

function doomACS:PushMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	self:push(value)
	return SCRIPT_CONTINUE
end

function doomACS:PushWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	self:push(value)
	return SCRIPT_CONTINUE
end

function doomACS:AddScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value + self:pop()
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:AddMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value + self:pop()
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:AddWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value + self:pop()
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:SubScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value - self:pop()
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:SubMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value - self:pop()
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:SubWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value - self:pop()
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:MulScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value * self:pop()
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:MulMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value * self:pop()
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:MulWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value * self:pop()
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:DivScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value / self:pop()
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:DivMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value / self:pop()
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:DivWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value / self:pop()
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:ModScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value % self:pop()
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:ModMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value % self:pop()
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:ModWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value % self:pop()
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:IncScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value + 1
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:IncMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value + 1
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:IncWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value + 1
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:DecScriptVar(args)
	local varIndex = args[1]
	local value = self.locals[varIndex] or 0
	value = value - 1
	self.locals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:DecMapVar(args)
	local varIndex = args[1]
	local value = self.mapvars[varIndex] or 0
	value = value - 1
	self.mapvars[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:DecWorldVar(args)
	local varIndex = args[1]
	local value = self.globals[varIndex] or 0
	value = value - 1
	self.globals[varIndex] = value
	return SCRIPT_CONTINUE
end

function doomACS:Goto(args)
	self.ip = args[1] + 1
	return SCRIPT_CONTINUE
end

function doomACS:IfGoto(args)
	if self:pop() != 0 then
		self.ip = args[1] + 1
	end
	return SCRIPT_CONTINUE
end

function doomACS:Drop(args)
	self:pop()
	return SCRIPT_CONTINUE
end

function doomACS:Delay(args)
	self.delay = self:pop()
	return SCRIPT_STOP
end

function doomACS:DelayDirect(args)
	self.delay = args[1]
	return SCRIPT_STOP
end

function doomACS:Random(args)
	local high = self:pop()
	local low = self:pop()
	local range = high - low + 1
	local randomValue = low + DOOM_Random() % range
	self:push(randomValue)
	return SCRIPT_CONTINUE
end

function doomACS:RandomDirect(args)
	local low = args[1]
	local high = args[2]
	local range = high - low + 1
	local randomValue = low + DOOM_Random() % range
	self:push(randomValue)
	return SCRIPT_CONTINUE
end

function doom.countThings(type, tid)
	if doom.currentGame != "Hexen" then
		-- Non-Hexen games don't have TIDs
		tid = 0
	end

	local count = 0

	if tid then
		for mobj in mobjs.iterate() do
			if (type == 0 or mobj.type == type) and (tid == 0 or mobj.doom.hexen_tid == tid) then
				if (mobj.doom.flags & DF_COUNTKILL) == 0 or mobj.health > 0 then
					count = count + 1
				end
			end
		end
	else
		for mobj in mobjs.iterate() do
			if (type == 0 or mobj.type == type) then
				if (mobj.doom.flags & DF_COUNTKILL) == 0 or mobj.health > 0 then
					count = count + 1
				end
			end
		end
	end

	return count
end

function doomACS:ThingCount(args)
	local tid = self:pop()
	local type = self:pop()
	local count = doom.countThings(type, tid)
	self:push(count)
	return SCRIPT_CONTINUE
end

function doomACS:ThingCountDirect(args)
	local type = args[1]
	local tid = args[2]
	local count = doom.countThings(type, tid)
	self:push(count)
	return SCRIPT_CONTINUE
end

function doomACS:TagWait(args)
	self.waitstate = "tag"
	self.tagWaitValue = self:pop()
	return SCRIPT_STOP
end

function doomACS:TagWaitDirect(args)
	self.waitstate = "tag"
	self.tagWaitValue = args[1]
	return SCRIPT_STOP
end

function doomACS:PolyWait(args)
	self.waitstate = "poly"
	self.polyWaitValue = self:pop()
	return SCRIPT_STOP
end

function doomACS:PolyWaitDirect(args)
	self.waitstate = "poly"
	self.polyWaitValue = args[1]
	return SCRIPT_STOP
end

function doomACS:ChangeFloor(args)
	local flat = self:pop()
	local tag = self:pop()
	doom.hexen_changeFloor(tag, flat)
	return SCRIPT_CONTINUE
end

function doomACS:ChangeFloorDirect(args)
	local tag = args[1]
	local flat = args[2]
	doom.hexen_changeFloor(tag, flat)
	return SCRIPT_CONTINUE
end

function doomACS:ChangeCeiling(args)
	local flat = self:pop()
	local tag = self:pop()
	doom.hexen_changeCeiling(tag, flat)
	return SCRIPT_CONTINUE
end

function doomACS:ChangeCeilingDirect(args)
	local tag = args[1]
	local flat = args[2]
	doom.hexen_changeCeiling(tag, flat)
	return SCRIPT_CONTINUE
end

function doomACS:Restart(args)
	self.ip = 1
	return SCRIPT_CONTINUE
end

function doomACS:AndLogical(args)
	local b = self:pop()
	local a = self:pop()
	self:push((a ~= 0 and b ~= 0) and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:OrLogical(args)
	local b = self:pop()
	local a = self:pop()
	self:push((a ~= 0 or b ~= 0) and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:AndBitwise(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a & b)
	return SCRIPT_CONTINUE
end

function doomACS:OrBitwise(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a | b)
	return SCRIPT_CONTINUE
end

function doomACS:EorBitwise(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a ~ b)
	return SCRIPT_CONTINUE
end

function doomACS:NegateLogical(args)
	local a = self:pop()
	self:push((a == 0) and 1 or 0)
	return SCRIPT_CONTINUE
end

function doomACS:LShift(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a << b)
	return SCRIPT_CONTINUE
end

function doomACS:RShift(args)
	local b = self:pop()
	local a = self:pop()
	self:push(a >> b)
	return SCRIPT_CONTINUE
end

function doomACS:UnaryMinus(args)
	local a = self:pop()
	self:push(-a)
	return SCRIPT_CONTINUE
end

function doomACS:IfNotGoto(args)
	if self:pop() == 0 then
		self.ip = args[1] + 1
	end
	return SCRIPT_CONTINUE
end

function doomACS:LineSide(args)
	self:push(self.side)
	return SCRIPT_CONTINUE
end

function doomACS:ScriptWait(args)
	self.waitstate = "script"
	self.delay = self:pop()
	return SCRIPT_STOP
end

function doomACS:ScriptWaitDirect(args)
	self.waitstate = "script"
	self.delay = args[1]
	return SCRIPT_STOP
end

doomACS.opcodemap = {
    [0] = doomACS.NOP,
    [1] = doomACS.Terminate,
    [2] = doomACS.Suspend,
    [3] = doomACS.PushNumber,
	[4] = doomACS.LSpec1,
	[5] = doomACS.LSpec2,
	[6] = doomACS.LSpec3,
	[7] = doomACS.LSpec4,
	[8] = doomACS.LSpec5,
	[9] = doomACS.Lspec1Direct,
	[10] = doomACS.Lspec2Direct,
	[11] = doomACS.Lspec3Direct,
	[12] = doomACS.Lspec4Direct,
	[13] = doomACS.Lspec5Direct,
	[14] = doomACS.Add,
	[15] = doomACS.Subtract,
	[16] = doomACS.Multiply,
	[17] = doomACS.Divide,
	[18] = doomACS.Modulus,
	[19] = doomACS.EQ,
	[20] = doomACS.NE,
	[21] = doomACS.LT,
	[22] = doomACS.GT,
	[23] = doomACS.LE,
	[24] = doomACS.GE,
	[25] = doomACS.AssignScriptVar,
	[26] = doomACS.AssignMapVar,
	[27] = doomACS.AssignWorldVar,
	[28] = doomACS.PushScriptVar,
	[29] = doomACS.PushMapVar,
	[30] = doomACS.PushWorldVar,
	[31] = doomACS.AddScriptVar,
	[32] = doomACS.AddMapVar,
	[33] = doomACS.AddWorldVar,
	[34] = doomACS.SubScriptVar,
	[35] = doomACS.SubMapVar,
	[36] = doomACS.SubWorldVar,
	[37] = doomACS.MulScriptVar,
	[38] = doomACS.MulMapVar,
	[39] = doomACS.MulWorldVar,
	[40] = doomACS.DivScriptVar,
	[41] = doomACS.DivMapVar,
	[42] = doomACS.DivWorldVar,
	[43] = doomACS.ModScriptVar,
	[44] = doomACS.ModMapVar,
	[45] = doomACS.ModWorldVar,
	[46] = doomACS.IncScriptVar,
	[47] = doomACS.IncMapVar,
	[48] = doomACS.IncWorldVar,
	[49] = doomACS.DecScriptVar,
	[50] = doomACS.DecMapVar,
	[51] = doomACS.DecWorldVar,
	[52] = doomACS.Goto,
	[53] = doomACS.IfGoto,
	[54] = doomACS.Drop,
	[55] = doomACS.Delay,
	[56] = doomACS.DelayDirect,
	[57] = doomACS.Random,
	[58] = doomACS.RandomDirect,
	[59] = doomACS.ThingCount,
	[60] = doomACS.ThingCountDirect,
	[61] = doomACS.TagWait,
	[62] = doomACS.TagWaitDirect,
	[63] = doomACS.PolyWait,
	[64] = doomACS.PolyWaitDirect,
	[65] = doomACS.ChangeFloor,
	[66] = doomACS.ChangeFloorDirect,
	[67] = doomACS.ChangeCeiling,
	[68] = doomACS.ChangeCeilingDirect,
	[69] = doomACS.Restart,
	[70] = doomACS.AndLogical,
	[71] = doomACS.OrLogical,
	[72] = doomACS.AndBitwise,
	[73] = doomACS.OrBitwise,
	[74] = doomACS.EorBitwise,
	[75] = doomACS.NegateLogical,
	[76] = doomACS.LShift,
	[77] = doomACS.RShift,
	[78] = doomACS.UnaryMinus,
	[79] = doomACS.IfNotGoto,
	[80] = doomACS.LineSide,
	[81] = doomACS.ScriptWait,
	[82] = doomACS.ScriptWaitDirect,
	[83] = doomACS.ClearLineSpecial,
	[84] = doomACS.CaseGoto,
	[85] = doomACS.BeginPrint,
	[86] = doomACS.EndPrint,
	[87] = doomACS.PrintString,
	[88] = doomACS.PrintNumber,
	[89] = doomACS.PrintCharacter,
	[90] = doomACS.PlayerCount,
	[91] = doomACS.GameType,
	[92] = doomACS.GameSkill,
	[93] = doomACS.Timer,
	[94] = doomACS.SectorSound,
	[95] = doomACS.AmbientSound,
	[96] = doomACS.SoundSequence,
	[97] = doomACS.SetLineTexture,
	[98] = doomACS.SetLineBlocking,
	[99] = doomACS.SetLineSpecial,
	[100] = doomACS.ThingSound,
	[101] = doomACS.EndPrintBold,
}

/*
Lump structure
The BEHAVIOR lump contains compiled ACS scripts for the map. There exist three different formats for BEHAVIOR lumps, the original Hexen one is identified by a four-byte header of ACS\0 (0x41435300); ZDoom also uses two different "enhanced" formats identified by ACSE (0x41435345) and ACSe (0x41435365).

Behavior lumps are compiled with ACC. The version of ACC maintained by Marisa Heit (Randi) needs the -h command line parameter to produce ACS\0 bytecode, since many of the ACS functions it supports are only available in the ZDoom formats.

The Eternity Engine's ACS VM can now interpret all three bytecode formats.

ACS0 bytecode format
Lump header
Offset	Size	C99 data type	Field name	Purpose
0	4	int32_t	marker	Must be 0x41435300 ("ACS\0")
4	4	int32_t	infoOffset	Offset to script directory from start of lump[notes 1]
Script directory
Offset	Size	C99 data type	Field name	Purpose
0	4	int32_t	ACScriptCount	Number of scripts in directory; 0 if empty[notes 2]
4	12 * ACScriptCount		info[]	Array of script information structures
4 + 12 * ACScriptCount	4	int32_t	ACStringCount	Number of strings in string table
8 + 12 * ACScriptCount	4 * ACStringCount		strings[]	Array of string table entries
Script information structure
Offset	Size	C99 data type	Field name	Purpose
0	4	int32_t	number	Script number
4	4	int32_t	offset	Offset to bytecode instruction stream from start of lump
8	4	int32_t	argCount	Number of arguments to script (only 0 to 3 are valid)[notes 3]
String table entry
Offset	Size	C99 data type	Field Name	Purpose
0	4	int32_t	offset	Offset to null-terminated string data from start of lump
Notes
 Offset validation for all offset fields is minimal in the vanilla Hexen executable; invalid values may cause undefined behavior.
 Lump cannot be empty in vanilla Hexen; a map with no scripts must have a valid header containing 0 in this field instead. Program behavior is undefined otherwise.
 Negative values or values greater than 3 may cause undefined behavior in the vanilla Hexen executable.
*/

-- Load a specific map's script entry from doom.hexen_scripts
-- hexen_scripts contains the raw bytes of the map's BEHAVIOR lump,
-- Due to the fact that making the parser be pre-packed would be impractical (and mildly inefficient)
function doom.loadScript(map)
	if not doom.hexen_scripts[map] then
		error("No BEHAVIOR lump found for map " .. map)
	end

	return doom.hexen_scripts[map]
end

function doom.executeScript(script, line, side, activator)
	local instance = doomACS.new(line, side, activator)
	return instance:execute(script)
end

-- Unpack the script directory from a BEHAVIOR lump
function doom.unpackBehaviorLump(lumpData)
	local scripts = {}
	local marker = string.unpack("I4", lumpData, 1)
	if marker ~= 0x41435300 then
		error("Invalid BEHAVIOR lump: incorrect marker or unsupported ACS version!")
	end
	local infoOffset = string.unpack("I4", lumpData, 5)
	local scriptCount = string.unpack("I4", lumpData, infoOffset + 1)
	for i = 1, scriptCount do
		local number = string.unpack("I4", lumpData, infoOffset + 4 + (i - 1) * 12)
		local offset = string.unpack("I4", lumpData, infoOffset + 8 + (i - 1) * 12)
		local argCount = string.unpack("I4", lumpData, infoOffset + 12 + (i - 1) * 12)
		scripts[number] = {bytecode = string.sub(lumpData, offset + 1), argCount = argCount, offset = offset}
	end

	local strings = {}

	-- Offsets
	local stringCount = string.unpack("I4", lumpData, infoOffset + 4 + scriptCount * 12)
	local stringTableOffset = infoOffset + 4 + scriptCount * 12 + 4
	if stringTableOffset + stringCount * 4 - 1 > #lumpData then
		error("Invalid BEHAVIOR lump: string table offset and count exceed lump size!")
	else
		-- Grab the string array while we're here

		for i = 1, stringCount do
			strings[i] = doom.getStringTableEntry(lumpData, stringTableOffset, i)
		end
	end

	-- Bytecode
	local scriptCount = 0
	for number, script in pairs(scripts) do
		scriptCount = scriptCount + 1
		if #script.bytecode == 0 then
			error("Invalid BEHAVIOR lump: script " .. number .. " has no bytecode!")
		end
	end

	return {
		marker = marker,
		infoOffset = infoOffset,
		scripts = scripts,
		stringCount = stringCount,
		stringTableOffset = stringTableOffset,
		strings = strings,
		scriptCount = scriptCount,
	}
end