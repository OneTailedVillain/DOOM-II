pcall(function()
	dofile("Unregister.lua")
end)
dofile("Globals.lua")
dofile("Freeslots.lua")
dofile("Specials.lua")
dofile("Colors.lua")
dofile("CustChar.lua")
dofile("WADString.lua")
dofile("WADLoad.lua")
dofile("Functions.lua")
dofile("Actions.lua")
dofile("+Use.lua")
dofile("Commands.lua")
dofile("Hooks.lua")
dofile("Definitions/Inventory/Ammo.lua")
dofile("Definitions/Inventory/Weps.lua")
dofile("Definitions/Objects/Deco.lua")
dofile("Definitions/Objects/Artifacts/Invuln.lua")
dofile("Definitions/Objects/Artifacts/Berserk.lua")
dofile("Definitions/Objects/Artifacts/Megasphere.lua")
dofile("Definitions/Objects/Artifacts/Blursphere.lua")
dofile("Definitions/Objects/Artifacts/Radiation Suit.lua")
dofile("Definitions/Objects/Artifacts/Soulsphere.lua")
dofile("Definitions/Objects/Artifacts/Backpack.lua")
dofile("Definitions/Objects/Artifacts/ComputerAreaMap.lua")
dofile("Definitions/Objects/Artifacts/Lite-Amp.lua")
dofile("Definitions/Objects/Items/Ammo.lua")
dofile("Definitions/Objects/Items/Armor.lua")
dofile("Definitions/Objects/Items/Health.lua")
dofile("Definitions/Objects/Items/Weapons.lua")
dofile("Definitions/Objects/Keycards/Yellow Key.lua")
dofile("Definitions/Objects/Keycards/Blue Key.lua")
dofile("Definitions/Objects/Keycards/Red Key.lua")
dofile("Definitions/Objects/Keycards/Yellow Skull Key.lua")
dofile("Definitions/Objects/Keycards/Blue Skull Key.lua")
dofile("Definitions/Objects/Keycards/Red Skull Key.lua")
dofile("Definitions/Objects/Monsters/Commander Keen.lua")
dofile("Definitions/Objects/Monsters/Cacodemon.lua")
dofile("Definitions/Objects/Monsters/Cyberdemon.lua")
dofile("Definitions/Objects/Monsters/Spider Mastermind.lua")
dofile("Definitions/Objects/Monsters/Imp.lua")
dofile("Definitions/Objects/Monsters/Zombieman.lua")
dofile("Definitions/Objects/Monsters/Shotgunner.lua")
dofile("Definitions/Objects/Monsters/Chaingunner.lua")
dofile("Definitions/Objects/Monsters/Demon.lua")
dofile("Definitions/Objects/Monsters/SS Guard.lua")
dofile("Definitions/Objects/Monsters/Hell Knight.lua")
dofile("Definitions/Objects/Monsters/RomeroHead.lua")
dofile("Definitions/Objects/Monsters/Exploding Barrel.lua")
dofile("Definitions/Objects/Monsters/Mancubus.lua")
dofile("Definitions/Objects/Monsters/Arachnotron.lua")
dofile("Definitions/Objects/Monsters/Revenant.lua")
dofile("Definitions/Objects/Monsters/Lost Soul.lua")
dofile("Definitions/Objects/Monsters/PLACEHOLD/Archvile.lua")
dofile("Definitions/Objects/Projectiles/Rocket.lua")
dofile("Definitions/Objects/Projectiles/Imp Fireball.lua")
dofile("Definitions/Objects/Projectiles/Mancubus Fireball.lua")
dofile("Definitions/Objects/Projectiles/Plasma.lua")
dofile("Definitions/Objects/Projectiles/Arachnotron Plasma.lua")
dofile("Definitions/Objects/Projectiles/Revenant Projectile.lua")
dofile("Definitions/Objects/Projectiles/BOH Fireball.lua")
dofile("Definitions/Objects/Effects/Telefog.lua")
dofile("Definitions/Objects/Effects/Revenant Tracer.lua")
dofile("Definitions/States/Player.lua")
dofile("Definitions/Objects/MiscDeco.lua")
dofile("HUD/HUDLib.lua")
dofile("HUD/HUD.lua")
dofile("HUD/Inter.lua")
dofile("HUD/Text Screens.lua")
dofile("HUD/Title.lua")
dofile("HUD/Cast Drawer.lua")
dofile("HUD/ENDOOM.lua")
dofile("Player/JohnDoom.lua")
dofile("Player/Player.lua")
dofile("Player/IntermissionThinker.lua")
dofile("Player/KeyBoardCheats.lua")
dofile("Player/PreThink.lua")
dofile("Player/PostThink.lua")
dofile("DEH Pointers.lua")
dofile("Obituaries.lua")

-- VSCode shit since with the advent of doomgfx it's now somewhat more viable as an option

---@class mapheader_t
---@field nextsecretlevel integer The level number of the map to go to on secret exit
---@field monsterscantelefrag boolean If this map should let monsters telefrag the player and their own kind

---@class torespawn_t
---@field time integer The time the victim was added to the respawn table
---@field type mobjtype_t The mobjtype of the victim
---@field x fixed_t The x position of the victim
---@field y fixed_t The y position of the victim
---@field z fixed_t The z position of the victim

---@alias validsource
---| "clip"           -- Source: Clip (ammo pickup).
---| "clipbox"        -- Source: Clip Box (ammo box).
---| "shells"         -- Source: Shell (pickup).
---| "shellbox"       -- Source: Shell Box (ammo box).
---| "rocket"         -- Source: Rocket (pickup).
---| "rocketbox"      -- Source: Rocket Box (ammo box).
---| "cell"           -- Source: Cell Pack (pickup).
---| "cellpack"       -- Source: Cell Pack (large pack).
---| "pistol"         -- Source: Pistol weapon (extensible; not explicitly called by pick-ups).
---| "chaingun"       -- Source: Chaingun weapon (extensible; not explicitly called by pick-ups).
---| "shotgun"        -- Source: Shotgun weapon (extensible; not explicitly called by pick-ups).
---| "supershotgun"   -- Source: Super Shotgun weapon (extensible; not explicitly called by pick-ups).
---| "rocketlauncher" -- Source: Rocket Launcher weapon (extensible; not explicitly called by pick-ups).
---| "plasmarifle"    -- Source: Plasma Rifle weapon (extensible; not explicitly called by pick-ups).
---| "bfg9000"        -- Source: BFG 9000 weapon (extensible; not explicitly called by pick-ups).

-- Engine default behavior for ammo gifts:
--   When the engine gives ammo automatically, it uses doom.ammoTypeGifts[ammoType].
--   *Single pickups* use doom.ammos[...].pickupamount and *box/pack* variants normally multiply by 5.
--   Weapon-based defaults often multiply that value (e.g. chaingun: *2).  
--   These defaults do NOT account for dropped weapons, Deathmatch, or skill modifiers;
--   giveAmmoFor should be used to implement any such special logic or to override defaults.

-- Modifiers, by default, follow the below order:
/*
	The current difficulty level being "I'm too young to die." or "Nightmare!" multiplies the ammo amount by 2.
	The current gamemode being Deathmatch turns small pick-ups into their large ammo counterparts.
	doomflags & DF_DROPPED divides the ammo amount by 2.
*/

---@alias validcheat
---| "idkfa"  Give all keys, weapons, ammo, and armor
---| "idfa"   Give all weapons, ammo, and armor
---| "idclip" Toggle noclip
---| "idclev" Change level/map
---| "idmus"  Play level music
---| "iddqd"  Toggle godmode
---| "idbehold" Give power-up (followed by a single letter indicating which one)
---| "idspispopd" Toggle no clipping (alternate)
---| "idchoppers" Give chainsaw and full ammo
---| "idmypos" Show current position and angle
---| "iddt"    Change map detail

---@alias poweruptype
---| "berserk"         Berserk pack.    Usually does NOT have a duration.
---| "invisibility"    Invisibility.    Lasts 60 seconds.
---| "invulnerability" Invulnerability. Lasts 30 seconds.
---| "ironfeet"        Radiation suit.  Lasts 60 seconds.

---@alias vanillaweps
---| "brassknuckles"
---| "chainsaw"
---| "pistol"
---| "chaingun"
---| "shotgun"
---| "supershotgun"
---| "rocketlauncher"
---| "plasmarifle"
---| "bfg9000"

---@class expectedValues Values expected for the saveState method.
---@field health integer
---@field armor integer
---@field currentWeapon string
---@field weapons table<string, boolean>
---@field oldweapons table<string, boolean>
---@field curwep string
---@field curwepslot integer
---@field curwepcat integer
---@field ammo table<string, integer>
---@field position vector3_t
---@field momentum vector3_t
---@field map integer

---@class doommethods_t List of Doom-specific methods for handling between different weapon/health/ammo systems.
---@field getHealth fun(player: player_t): integer|nil Returns the player's current health as an integer or nil if unavailable
---@field setHealth fun(player: player_t, health: integer): boolean Sets the player's health. Returns true if successful.
---@field getMaxHealth fun(player: player_t): integer|nil Returns the player's maximum health as an integer or nil if unavailable
---@field getArmor fun(player: player_t): integer|nil Returns the player's armor as an integer or nil if unavailable
---@field setArmor fun(player: player_t, armor: integer, efficiency: number|fixed_t|nil): boolean Sets the player's armor. Efficiency is in fixed_t (0-FRACUNIT). Returns true if successful.
---@field getMaxArmor fun(player: player_t): integer|nil Returns the player's maximum armor as an integer or nil if unavailable
---@field getCurAmmo fun(player: player_t): integer|false|nil Returns the player's current ammo for their current weapon, false if the weapon doesn't use ammo, or nil if unavailable
---@field getCurAmmoType fun(player: player_t): string|nil Returns the ammo type string for the player's current weapon, or nil if unavailable
---@field getAmmoFor fun(player: player_t, aType: string): integer|false Returns the player's current ammo for the given ammo type, or false if unavailable
---@field setAmmoFor fun(player: player_t, aType: string, amount: integer): boolean Sets the player's ammo for the given ammo type. Returns true if successful.
---@field getMaxFor fun(player: player_t, aType: string): integer|nil Returns the player's maximum ammo for the given ammo type, or nil if unavailable
---@field giveWeapon fun(player: player_t, weapon: string, doomflags: integer|nil): boolean Gives the specified weapon to the player. Returns true if the gift was successful (typically if the player didn't already have it or wasn't at max ammo)
---@field hasWeapon fun(player: player_t, weapon: string): boolean Returns true if the player has the specified weapon
---@field giveAmmoFor fun(player: player_t, source: validsource, dflags: integer|nil): boolean Gives ammo to the player based on `source`. Returns true if ammo was added.
---@field damage fun(player: mobj_t, damage: integer, attacker: player_t|mobj_t|nil, proj: mobj_t|nil, damageType: integer|nil, minhealth: integer|nil): boolean|nil Applies damage to the player using doom-style armor efficiency. Returns true if damage was applied. (Due to a bug, the player argument is not actually of type player_t)
---@field doBackpack fun(player: player_t): nil Gives the player a backpack and maximum ammo
---@field doPowerUp fun(player: player_t, powerType: poweruptype): boolean Gives a power-up to the player. Returns true if successful.
---@field shouldDealDamage fun(player: player_t, inflictor: mobj_t|nil, source: mobj_t|nil, damage: integer, damageType: integer|nil, minhealth: integer|nil): boolean|nil Optional. If present, called before applying damage to allow the skin/system to veto damage handling. Return truthy (true or any non-zero number) to allow damage to proceed; return falsy (false, nil or zero) to prevent damage. Parameters match those passed to the "damage" method. Due to intended behavior, the "player" argument is actually of player_t.
---@field hasPowerup fun(player: player_t, powerType: poweruptype): boolean Returns true if the player currently has the specified power-up active, or false otherwise.
---@field onIntermission fun(player: player_t): nil? Optional. Hook called when the intermission screen starts.
---@field onNowEntering fun(player: player_t): nil? Optional. Hook called when the Intermission Screen enters the "Now Entering" state.
---@field onSoulsphere fun(player: player_t): nil? Optional. Hook called when the player picks up a Soulsphere.
---@field onKill fun(player: player_t, victim: mobj_t): nil? Optional. Hook called when the player is credited with killing an enemy.
---@field shouldDoCheat fun(player: player_t, validcheat: string, arg: string|number|nil): boolean|nil Optional. Called before a cheat command runs (e.g. `"idkfa"`, `"idclev"`, `"idmus"`, etc.). If this function returns a truthy value the cheat will be cancelled/aborted; return falsy (nil/false) to allow the cheat to proceed. `arg` is present for cheats that accept an argument (like `idclev` / `idmus`).
---@field onCheat fun(player: player_t, validcheat: string, arg: string|number|nil): nil Optional. Hook called after a cheat command has executed. Useful for logging or additional side-effects. The return value is ignored.
---@field giveHealth fun(player: player_t, healAmount: integer, expectedMaxHealth: integer|nil): boolean|nil Gives health to the player. expectedMaxHealth is the caller-provided expected maximum used for clamping (often derived from getMaxHealth). Returns true if health was increased, false or nil if no change or unavailable.
---@field giveArmor fun(player: player_t, armorAmount: integer, efficiency: number|fixed_t|nil, expectedMaxArmor: integer|nil): boolean|nil Gives armor to the player using the given efficiency. expectedMaxArmor is the caller-provided expected maximum used for clamping (often derived from getMaxArmor). Returns true if armor was increased, false or nil if no change or unavailable.
---@field saveState fun(player: player_t, expectedValues: expectedValues): nil Attempt to save the player's current state. expectedValues mostly takes from existing "getSomething" methods and may not be correct for weapons and ammo.
---@field doForcedWeaponSwitch fun(player: player_t, weapon: string): nil Optional. Called when the game forcibly switches the player's weapon (e.g. Berserk Pack autoswitch). "weapon" is the internal weapon name the game is switching to.
---@field throwOutSaveState fun(player: player_t) Attempt to throw out the player's current saved state. This should clear out *all* state variables.
---@field getCurWeapon fun(player: player_t): vanillaweps Returns the weapon name the current player is holding.

---@class validsoundentries Non-class
---@field noway integer Sound played when you try to interact with a non-interactible line
---@field oof integer Sound played when you land from a big fall
---@field pldeth integer Sound played when A_PlayerScream gets called while the player had > -50% health.
---@field pdiehi integer Sound played when A_PlayerScream gets called while the player had < -50% health.
---@field slop integer Sound played when A_PlayerXDeath gets called.
---@field itemup integer Sound played when you collect an item.
---@field wpnup integer Sound played when you collect a weapon.
---@field getpow integer Sound played when you collect a power-up.

---@class doomcharsupport_t Character support definition
---@field noWeapons boolean If true, disable Doom weapon system. Nil = default behavior (uses Doom system)
---@field noHUD boolean If true, disable Doom HUD. Nil = default behavior (uses Doom HUD)
---@field customDamage boolean @deprecated Unnecessary to set since v0.99-3. Used to be a hack to circumnavigate a stack overflow when a damage method used P_DamageMobj.
---@field soundTable validsoundentries Table of sound effects that can be replaced. Empty entries will use their default sound effects.
---@field intermusic string The music lump played when you go the intermission while playing as this character. Overrides both DOOM II and DOOM 1 intermission songs.
---@field methods doommethods_t The methods table for this character

---@class dehackedpointers Semi-class, holds arrays of Dehacked-related pointers
---@field sprites integer[] Array of sprite IDs
---@field things mobjtype_t[] Array of mobj types
---@field flags table<integer, {num: integer, type: string}> Mapping of flag bitmask to flag number and type
---@field sounds integer[] Array of sound effect enums
---@field frames integer[] Array of state IDs
---@field frametowepstate table<integer, {[1]: string, [2]: string, [3]: integer}> Mapping of frame number to weapon state (weapon name, state name, state index)

---@class endoom_t The current ENDOOM screen data, populated by the conversion script.
---@field colors table A 2D table of color values for the current ENDOOM screen. Entries use RLE of format {attribute, count}.
---@field text table A 2D table of strings used in the current ENDOOM screen.

---@class doomimmunityconfig
---@field excludedSourceTypes table<number, boolean> source types that bypass infighting checks
---@field pairImmunities table<number, table<number, boolean>> specific A->B immunity pairs
---@field ignoreSameType boolean whether to ignore same-type attacks by default
---@field noRetaliateAgainst table<number, boolean> monster types that should not be retaliated against
---@field noExplosionDamage table<number, boolean> monster types that are immune to explosion damage

---@class doomglobal_t Global Doom-specific variables and functions
---@field isdoom1 boolean Denotes if the IWAD loaded was based on the Doom 1 engine
---@field torespawn table<torespawn_t> The list of victims to respawn
---@field strings table<doomstrings> The set of strings used for various pickups and events
---@field endoom endoom_t The ENDOOM screen data
---@field rndtable table A table of random numbers used for various calculations
---@field prndindex integer The current index in the random number table
---@field addWeapon function A function to register a weapon definition
---@field addAmmo function A function to register an ammo definition
---@field weapons table<weapondef_t> The registered weapon definitions
---@field ammos table<ammodef_t> The registered ammo definitions
---@field thinkers table<any, table> @deprecated Use doom.thinkerlist and doom.thinkermap instead
---@field thinkerlist table<number, {key: any, data: any, active: boolean}> The list of active thinkers
---@field thinkermap table<any, number> Mapping of thinker keys to their index in thinkerlist
---@field gameskill integer The current skill level of the game
---@field showendoom boolean Whether the ENDOOM screen is being shown
---@field KEY_RED integer The bitmask value for the red key
---@field KEY_BLUE integer The bitmask value for the blue key
---@field KEY_YELLOW integer The bitmask value for the yellow key
---@field KEY_SKULLRED integer The bitmask value for the red skull key
---@field KEY_SKULLBLUE integer The bitmask value for the blue skull key
---@field KEY_SKULLYELLOW integer The bitmask value for the yellow skull key
---@field respawnmonsters boolean Whether monsters should respawn
---@field killcount integer The total number of kills in the current map
---@field itemcount integer The total number of items in the current map
---@field secretcount integer The total number of secrets in the current map
---@field kills integer @deprecated Use player.killcount instead
---@field items integer (Deprecated?) The number of items the player has collected in the current map
---@field secrets integer (Deprecated?) The number of secrets the player has found in the current map
---@field defaultgravity fixed_t The default gravity value for the map
---@field lineActions table<integer, table> A table of line special actions, indexed by their line special number
---@field linebackups table<line_t, table> A table of line special backups, indexed by their line_t
---@field charSupport table<string, doomcharsupport_t> A table of character support definitions, indexed by skin name
---@field midGameTitlescreen boolean (MULTIPLAYER UNSAFE!) If true, enables access to the titlescreen in singleplayer mid-game.
---@field titlemenus table<string, table> The title menu definitions.
---@field intermission boolean True if in intermission.
---@field textscreen table|nil The active text screen, if any.
---@field mapString string The prefix string for the current map's lumps
---@field subthinkers table<any, table> The sub-thinkers in the current map. Only used for light effects
---@field texturesByNum table<integer, string> A mapping of texture numbers to texture names
---@field weaponnames table<integer, table<integer, string>> A mapping of weapon slots and orders to weapon names
---@field sectorspecials table<integer, table> A mapping of sector indices to their special
---@field sectorbackups table<sector_t, table> A mapping of sector userdatas to their backup data
---@field validcount integer A counter used to mark valid sectors for processing
---@field sectordata table<sector_t, table> A mapping of sector userdatas to their custom data
---@field gamemode string The current game mode ("shareware", "registered", "commercial", etc)
---@field switchTexNames table<integer, table<1, string>|table<2, string>|table<3, integer>> A list of switch texture name mappings for different game versions
---@field textscreenmaps table<integer, table> A mapping of text screen IDs to their data
---@field pistolstartstate table The initial player state (and back-up, in case of missing values)
---@field soulspheregrant integer The amount of health granted by a soulsphere pickup
---@field maxsoulsphere integer The maximum health a player can have when picking up a soulsphere
---@field megaspheregrant integer The amount of health granted by a megasphere pickup
---@field godmodehealth integer The health value set when god mode is activated
---@field idfaarmor integer The amount of armor granted by using the IDFA cheat
---@field greenarmorclass integer The armor class value for Security Armor
---@field bluearmorclass integer The armor class value for Combat Armor
---@field idfaarmorclass integer The armor class value for the IDFA cheat
---@field idkfaarmor integer The amount of armor granted by using the IDKFA cheat
---@field idkfaarmorclass integer The armor class value for the IDKFA cheat
---@field bfgshotcost integer The amount of cells consumed by firing the BFG9000
---@field infighting boolean Whether monster infighting is enabled
---@field linespecials table<any, integer> The line specials in the current map.
---@field switches table<integer, integer> The switch texture numbers.
---@field numswitches integer The number of switches in the current map.
---@field patchesLoaded boolean Whether the WAD patches have been loaded
---@field issrb2 boolean Whether the loaded WAD is SRB2
---@field lastmap integer The last map number in this WAD
---@field quitStrings table<integer, string> The quit messages for this WAD
---@field dropTable table<mobjtype_t, mobjtype_t> Mapping of monster types to which item they drop on death
---@field bossDeathSpecials table<mobjtype_t, {map: integer, tag: integer, special: integer, type?: integer}> Special level actions triggered on boss deaths
---@field dehackedpointers dehackedpointers Holds Dehacked-related pointers
---@field doom1Pars table<number, table<number>> Doom 1 par times, indexed via [episode][map]
---@field doom2Pars table<number, number> Doom 2 par times, indexed via map number
---@field Doom2MapToDoom1 table<number, {ep: number, map: number}> Mapping of Doom 2 map numbers to Doom 1 episode and map numbers
---@field secretExits table<number, number> Mapping of map numbers to their secret exit destinations
---@field animatorOffsets table<integer, integer> Mapping of weapon state IDs to animator offsets
---@field oolors table A list of custom skincolors used for DOOM team colors and more. Yes, the name was misspelled.
---@field predefinedWeapons table<number, weapondef_t> Predefined weapon definitions for enemies
---@field didSecretExit boolean If the player exited via a secret exit
---@field immunity doomimmunityconfig immunity configuration for infighting and damage handling
---@field mthingReplacements table<number, number> mapping of Doom mobj types to Lua mobj types
---@field setIgnoreSameType fun(enabled: boolean) set whether to ignore same-type attacks
---@field addExcludedSourceType fun(t: number) add a source type that bypasses infighting checks
---@field addNoExplosionDamageType fun(t: number) add a type that is immune to explosion damage
---@field removeExcludedSourceType fun(t: number) remove a source type from bypassing infighting checks
---@field addPairImmunity fun(attackerType: number, targetType: number) add a specific A->B immunity pair
---@field removePairImmunity fun(attackerType: number, targetType: number) remove a specific A->B immunity pair
---@field setNoRetaliateAgainst fun(monsterType: number, enabled: boolean) set whether a monster type should not be retaliated against
---@field damagetypes table<string, integer> A table of damage type constants. OR'ing with doom.damagetypes.instakill will make the damage ignore armor and directly set health to zero.
---@field spawnpoints table<string, table> The spawnpoints in the current map
---@field cvars table<string, consvar_t> A table of registered DOOM cvars
---@field doObituary fun(target: mobj_t, source: mobj_t|nil, inflictor: mobj_t|nil, dtype: integer): nil Function to handle obituaries
---@field obitStrings table<string, table> Table of obituary strings, where "doom.obitStringsp[gametype]" gets the strings for the current game type
---@field loadStrings fun(gametype: string): nil Function to load the doom.strings table for the given game type

---@class doomspread_t
---@field horiz fixed_t
---@field vert fixed_t

---@class doomstate_t
---@field frame integer The frame of the current state
---@field tics integer The number of tics this state lasts for
---@field action fun(actor: mobj_t, var1: any, var2: any, weapon: weapondef_t) The action to perform during this state
---@field var1 any The first variable for the action
---@field var2 any The second variable for the action

---@class doomweaponstates_t Table of valid weapon states
---@field idle table<doomstate_t> The idle state of the weapon
---@field attack table<doomstate_t> The attack state of the weapon
---@field lower table<doomstate_t> The lower state of the weapon
---@field raise table<doomstate_t> The raise state of the weapon
---@field flash table<doomstate_t> The gunflash that shows whenever A_DoomFire gets called

---@class weapondef_t Definition of a Doom weapon
---@field sprite spritenum_t The weapon sprite this weapon uses
---@field weaponslot integer The slot this weapon occupies in the player's inventory
---@field order integer The order of this weapon in the player's inventory (higher == lower)
---@field damage table The damage values for this weapon, in order of {min, max, steps}
---@field pellets integer The number of shootmobjs fired by this weapon
---@field shootmobj mobjtype_t The type of object this weapon fires (defaults to hitscanner)
---@field raycaster boolean Whether this weapon uses raycasting (defaults to false)
---@field shotcost integer The ammo cost per shot
---@field ammotype string The type of ammo this weapon uses
---@field spread doomspread_t The spread values for this weapon
---@field states doomweaponstates_t The states for this weapon
---@field noinitfirespread boolean Whether this weapon should only apply spread on refire

---@class ammodef_t Definition of a Doom ammo type
---@field max integer The maximum amount of this ammo the player can carry
---@field backpackmax integer The maximum amount of this ammo the player can carry when they have the backpack
---@field icon string (Unused) The icon representing this ammo type
---@field backpackicon string (Unused) The icon representing this ammo type when they have the backpack

---@class doompowers_t Powerup timers
---@field pw_strength integer Timer for the Berserk power-up. Counts up if non-zero.
---@field pw_ironfeet integer Timer for the Radiation Suit power-up. Counts down until it turns back to zero.
---@field pw_invisibility integer Timer for the Blursphere power-up. Counts down until it turns back to zero.

---@class laststate_t Snapshot of player state, taken on level exit
---@field ammo table<number, integer> The ammo counts since last archive.
---@field weapons table<number, integer> The weapons owned since last archive.
---@field oldweapons table<number, integer> The last weapons owned since last archive.
---@field curwep table<number, integer> The last weapon held since last archive.
---@field health integer The last health % since last archive.
---@field armor integer The last armor % since last archive.
---@field armorefficiency integer The last armor efficiency since last archive.
---@field pos vector3_t The last position the player was in since last archive.
---@field momentum vector3_t The last momentum the player had since last archive.
---@field map integer The last map the player was in since last archive.

---@class doomplayer_t Doom-specific player fields
---@field ammo table<string, integer> Ammo counts by ammo type/index
---@field weapons table<string, boolean> Owned weapons map (weapon name -> true)
---@field oldweapons table Previous weapons map/state
---@field curwep string Current weapon id/name
---@field curwepcat integer Current weapon category/slot
---@field curwepslot integer Current weapon order within slot
---@field weptics integer Weapon tics (animation timer)
---@field wepstate string Weapon state name (eg. "idle", "attack")
---@field wepframe integer Current frame within the weapon state
---@field wishwep string|nil Weapon requested to switch to
---@field switchingweps boolean True while switching weapons
---@field switchtimer integer Timer used while switching weapons
---@field lastwepbutton integer Last weapon button bitmask
---@field lastbuttons integer Last input buttons bitmask
---@field lastmomz integer Last vertical momentum (momz)
---@field powers doompowers_t Powerup timers
---@field bonuscount integer Bonus/powerup visual counter
---@field damagecount integer Damage flash counter (0-100)
---@field attacker any Last attacker (mobj or nil), gets reset when damagecount is zero
---@field deadtimer integer Death animation timer
---@field killcam any Kill camera object (mobj or nil)
---@field notrigger boolean Whether walkover triggers are disabled for this player
---@field keys integer Bitmask of keys/skull keys the player has
---@field laststate laststate_t Saved state snapshot (pos, momentum, ammo, etc.)
---@field killcount integer Kill count used in intermission calculations
---@field intstate integer Intermission state machine variable
---@field intpause integer Intermission pause timer
---@field bcnt integer Intermission blink/counter helper
---@field cnt_time integer Intermission displayed time counter
---@field cnt_par integer Intermission displayed par counter
---@field wintime integer Win time (for intermission calculations)
---@field frags integer Frag count (multiplayer)
---@field message string|nil HUD message text
---@field messageclock integer|nil Message display timer
---@field cheats integer Bitmask of active cheats

---@class doomflags_t Bitmask of doommobj_t flags
---@field DF_DROPPED integer If the object was dropped by a monster or player
---@field DF_NOBLOOD integer If the object should not bleed when damaged
---@field DF_CORPSE integer If the object is a corpse
---@field DF_COUNTKILL integer If the object counts towards kill count
---@field DF_COUNTITEM integer If the object counts towards item count
---@field DF_ALWAYSPICKUP integer (Unused?) If the object should always be picked up
---@field DF_DROPOFF integer If the object should be able to drop off ledges
---@field DF_JUSTHIT integer If the object was just hit
---@field DF_SHADOW integer If the object is a shadow
---@field DF_DMRESPAWN integer If the object should not disappear in deathmatch 1.0
---@field DF_DM2RESPAWN integer If the object should be able to respawn in deathmatch 2.0
---@field DF_INFLOAT integer If the object is in a floating state
---@field DF_TELEPORT integer If the object was teleported this tic
---@field DF_SKULLFLY integer If the object is in skull fly mode (Lost Souls)

---@class doommobj_t Doom-specific mobj fields
---@field health integer The health of the mobj
---@field armor integer The armor of the mobj
---@field armorefficiency integer The armor efficiency of the mobj's armor
---@field flags doomflags_t Bitmask of doommobj_t flags (DF_*)
---@field damage integer The damage value of the mobj, for projectiles
---@field hitsound integer The sound to play when the mobj hits something

---@class mobj_t
---@field doom doommobj_t The Doom-specific fields for this object
---@field parent mobj_t The "parent" of this object
---@field child mobj_t The "child" of this object
---@field corpse mobj_t The corpse object of the player
---@field dist fixed_t Used for raycasting. The distance from the ray origin to this mobj.
---@field shooter mobj_t The mobj that fired/shot this projectile, if any

---@class player_t
---@field doom doomplayer_t The Doom-specific fields for this player
---@field killcam mobj_t|nil The player's killcam mobj, if any
---@field attacker mobj_t|nil The last attacker of the player, if any. Automatically reset when their damagecount is zero.

---@class mobjinfo_t
---@field doomflags doomflags_t Bitmask of doommobj_t flags (DF_*). Auto-copied to mobj_t.doom.flags on spawn.
---@field doomname string The Name passed to DefineDoomActor
---@field fastspeed fixed_t The speed used when doom_fastmonsters is enabled

---@class doomstrings Non-class, holds the IDs of Doom strings
---@field GOTARMOR string Message for picking up the CombatArmor.
---@field GOTMEGA string Message for picking up the MegaArmor.
---@field GOTHTHBONUS string Message for picking up a health bonus.
---@field GOTARMBONUS string Message for picking up an armor bonus.
---@field GOTSTIM string Message for picking up a stimpack.
---@field GOTMEDINEED string Message for picking up a medikit when low on health.
---@field GOTMEDIKIT string Message for picking up a medikit.
---@field GOTSUPER string Message for picking up a supercharge.
---@field GOTBLUECARD string Message for picking up a blue keycard.
---@field GOTYELWCARD string Message for picking up a yellow keycard.
---@field GOTREDCARD string Message for picking up a red keycard.
---@field GOTBLUESKUL string Message for picking up a blue skull key.
---@field GOTYELWSKUL string Message for picking up a yellow skull key.
---@field GOTREDSKULL string Message for picking up a red skull key.
---@field GOTINVUL string Message for picking up invulnerability.
---@field GOTBERSERK string Message for picking up berserk.
---@field GOTINVIS string Message for picking up invisibility.
---@field GOTSUIT string Message for picking up a radiation suit.
---@field GOTMAP string Message for picking up a map.
---@field GOTVISOR string Message for picking up a light amplification visor.
---@field GOTMSPHERE string Message for picking up a megasphere.
---@field GOTCLIP string Message for picking up a clip.
---@field GOTCLIPBOX string Message for picking up a box of bullets.
---@field GOTROCKET string Message for picking up a rocket.
---@field GOTROCKBOX string Message for picking up a box of rockets.
---@field GOTCELL string Message for picking up an energy cell.
---@field GOTCELLBOX string Message for picking up an energy cell pack.
---@field GOTSHELLS string Message for picking up shotgun shells.
---@field GOTSHELLBOX string Message for picking up a box of shotgun shells.
---@field GOTBACKPACK string Message for picking up a backpack.
---@field GOTBFG9000 string Message for picking up the BFG9000.
---@field GOTCHAINGUN string Message for picking up the chaingun.
---@field GOTCHAINSAW string Message for picking up the chainsaw.
---@field GOTLAUNCHER string Message for picking up the rocket launcher.
---@field GOTPLASMA string Message for picking up the plasma gun.
---@field GOTSHOTGUN string Message for picking up the shotgun.
---@field GOTSHOTGUN2 string Message for picking up the super shotgun.
---@field PD_BLUEO string Message for needing a blue key to activate an object.
---@field PD_REDO string Message for needing a red key to activate an object.
---@field PD_YELLOWO string Message for needing a yellow key to activate an object.
---@field PD_BLUEK string Message for needing a blue key to open a door.
---@field PD_REDK string Message for needing a red key to open a door.
---@field PD_YELLOWK string Message for needing a yellow key to open a door.
---@field GGSAVED string Message for saving the game.
---@field HUSTR_MSGU string Message for unsent message.
---@field HUSTR_E1M1 string Level name for E1M1.
---@field HUSTR_E1M2 string Level name for E1M2.
---@field HUSTR_E1M3 string Level name for E1M3.
---@field HUSTR_E1M4 string Level name for E1M4.
---@field HUSTR_E1M5 string Level name for E1M5.
---@field HUSTR_E1M6 string Level name for E1M6.
---@field HUSTR_E1M7 string Level name for E1M7.
---@field HUSTR_E1M8 string Level name for E1M8.
---@field HUSTR_E1M9 string Level name for E1M9.
---@field HUSTR_E2M1 string Level name for E2M1.
---@field HUSTR_E2M2 string Level name for E2M2.
---@field HUSTR_E2M3 string Level name for E2M3.
---@field HUSTR_E2M4 string Level name for E2M4.
---@field HUSTR_E2M5 string Level name for E2M5.
---@field HUSTR_E2M6 string Level name for E2M6.
---@field HUSTR_E2M7 string Level name for E2M7.
---@field HUSTR_E2M8 string Level name for E2M8.
---@field HUSTR_E2M9 string Level name for E2M9.
---@field HUSTR_E3M1 string Level name for E3M1.
---@field HUSTR_E3M2 string Level name for E3M2.
---@field HUSTR_E3M3 string Level name for E3M3.
---@field HUSTR_E3M4 string Level name for E3M4.
---@field HUSTR_E3M5 string Level name for E3M5.
---@field HUSTR_E3M6 string Level name for E3M6.
---@field HUSTR_E3M7 string Level name for E3M7.
---@field HUSTR_E3M8 string Level name for E3M8.
---@field HUSTR_E3M9 string Level name for E3M9.
---@field HUSTR_E4M1 string Level name for E4M1.
---@field HUSTR_E4M2 string Level name for E4M2.
---@field HUSTR_E4M3 string Level name for E4M3.
---@field HUSTR_E4M4 string Level name for E4M4.
---@field HUSTR_E4M5 string Level name for E4M5.
---@field HUSTR_E4M6 string Level name for E4M6.
---@field HUSTR_E4M7 string Level name for E4M7.
---@field HUSTR_E4M8 string Level name for E4M8.
---@field HUSTR_E4M9 string Level name for E4M9.
---@field HUSTR_1 string Level name for MAP01.
---@field HUSTR_2 string Level name for MAP02.
---@field HUSTR_3 string Level name for MAP03.
---@field HUSTR_4 string Level name for MAP04.
---@field HUSTR_5 string Level name for MAP05.
---@field HUSTR_6 string Level name for MAP06.
---@field HUSTR_7 string Level name for MAP07.
---@field HUSTR_8 string Level name for MAP08.
---@field HUSTR_9 string Level name for MAP09.
---@field HUSTR_10 string Level name for MAP10.
---@field HUSTR_11 string Level name for MAP11.
---@field HUSTR_12 string Level name for MAP12.
---@field HUSTR_13 string Level name for MAP13.
---@field HUSTR_14 string Level name for MAP14.
---@field HUSTR_15 string Level name for MAP15.
---@field HUSTR_16 string Level name for MAP16.
---@field HUSTR_17 string Level name for MAP17.
---@field HUSTR_18 string Level name for MAP18.
---@field HUSTR_19 string Level name for MAP19.
---@field HUSTR_20 string Level name for MAP20.
---@field HUSTR_21 string Level name for MAP21.
---@field HUSTR_22 string Level name for MAP22.
---@field HUSTR_23 string Level name for MAP23.
---@field HUSTR_24 string Level name for MAP24.
---@field HUSTR_25 string Level name for MAP25.
---@field HUSTR_26 string Level name for MAP26.
---@field HUSTR_27 string Level name for MAP27.
---@field HUSTR_28 string Level name for MAP28.
---@field HUSTR_29 string Level name for MAP29.
---@field HUSTR_30 string Level name for MAP30.
---@field HUSTR_31 string Level name for MAP31.
---@field HUSTR_32 string Level name for MAP32.
---@field PHUSTR_1 string Level name for MAP01 (Plutonia Experiment).
---@field PHUSTR_2 string Level name for MAP02 (Plutonia Experiment).
---@field PHUSTR_3 string Level name for MAP03 (Plutonia Experiment).
---@field PHUSTR_4 string Level name for MAP04 (Plutonia Experiment).
---@field PHUSTR_5 string Level name for MAP05 (Plutonia Experiment).
---@field PHUSTR_6 string Level name for MAP06 (Plutonia Experiment).
---@field PHUSTR_7 string Level name for MAP07 (Plutonia Experiment).
---@field PHUSTR_8 string Level name for MAP08 (Plutonia Experiment).
---@field PHUSTR_9 string Level name for MAP09 (Plutonia Experiment).
---@field PHUSTR_10 string Level name for MAP10 (Plutonia Experiment).
---@field PHUSTR_11 string Level name for MAP11 (Plutonia Experiment).
---@field PHUSTR_12 string Level name for MAP12 (Plutonia Experiment).
---@field PHUSTR_13 string Level name for MAP13 (Plutonia Experiment).
---@field PHUSTR_14 string Level name for MAP14 (Plutonia Experiment).
---@field PHUSTR_15 string Level name for MAP15 (Plutonia Experiment).
---@field PHUSTR_16 string Level name for MAP16 (Plutonia Experiment).
---@field PHUSTR_17 string Level name for MAP17 (Plutonia Experiment).
---@field PHUSTR_18 string Level name for MAP18 (Plutonia Experiment).
---@field PHUSTR_19 string Level name for MAP19 (Plutonia Experiment).
---@field PHUSTR_20 string Level name for MAP20 (Plutonia Experiment).
---@field PHUSTR_21 string Level name for MAP21 (Plutonia Experiment).
---@field PHUSTR_22 string Level name for MAP22 (Plutonia Experiment).
---@field PHUSTR_23 string Level name for MAP23 (Plutonia Experiment).
---@field PHUSTR_24 string Level name for MAP24 (Plutonia Experiment).
---@field PHUSTR_25 string Level name for MAP25 (Plutonia Experiment).
---@field PHUSTR_26 string Level name for MAP26 (Plutonia Experiment).
---@field PHUSTR_27 string Level name for MAP27 (Plutonia Experiment).
---@field PHUSTR_28 string Level name for MAP28 (Plutonia Experiment).
---@field PHUSTR_29 string Level name for MAP29 (Plutonia Experiment).
---@field PHUSTR_30 string Level name for MAP30 (Plutonia Experiment).
---@field PHUSTR_31 string Level name for MAP31 (Plutonia Experiment).
---@field PHUSTR_32 string Level name for MAP32 (Plutonia Experiment).
---@field THUSTR_1 string Level name for MAP01 (TNT Evilution).
---@field THUSTR_2 string Level name for MAP02 (TNT Evilution).
---@field THUSTR_3 string Level name for MAP03 (TNT Evilution).
---@field THUSTR_4 string Level name for MAP04 (TNT Evilution).
---@field THUSTR_5 string Level name for MAP05 (TNT Evilution).
---@field THUSTR_6 string Level name for MAP06 (TNT Evilution).
---@field THUSTR_7 string Level name for MAP07 (TNT Evilution).
---@field THUSTR_8 string Level name for MAP08 (TNT Evilution).
---@field THUSTR_9 string Level name for MAP09 (TNT Evilution).
---@field THUSTR_10 string Level name for MAP10 (TNT Evilution).
---@field THUSTR_11 string Level name for MAP11 (TNT Evilution).
---@field THUSTR_12 string Level name for MAP12 (TNT Evilution).
---@field THUSTR_13 string Level name for MAP13 (TNT Evilution).
---@field THUSTR_14 string Level name for MAP14 (TNT Evilution).
---@field THUSTR_15 string Level name for MAP15 (TNT Evilution).
---@field THUSTR_16 string Level name for MAP16 (TNT Evilution).
---@field THUSTR_17 string Level name for MAP17 (TNT Evilution).
---@field THUSTR_18 string Level name for MAP18 (TNT Evilution).
---@field THUSTR_19 string Level name for MAP19 (TNT Evilution).
---@field THUSTR_20 string Level name for MAP20 (TNT Evilution).
---@field THUSTR_21 string Level name for MAP21 (TNT Evilution).
---@field THUSTR_22 string Level name for MAP22 (TNT Evilution).
---@field THUSTR_23 string Level name for MAP23 (TNT Evilution).
---@field THUSTR_24 string Level name for MAP24 (TNT Evilution).
---@field THUSTR_25 string Level name for MAP25 (TNT Evilution).
---@field THUSTR_26 string Level name for MAP26 (TNT Evilution).
---@field THUSTR_27 string Level name for MAP27 (TNT Evilution).
---@field THUSTR_28 string Level name for MAP28 (TNT Evilution).
---@field THUSTR_29 string Level name for MAP29 (TNT Evilution).
---@field THUSTR_30 string Level name for MAP30 (TNT Evilution).
---@field THUSTR_31 string Level name for MAP31 (TNT Evilution).
---@field THUSTR_32 string Level name for MAP32 (TNT Evilution).
---@field HUSTR_CHATMACRO1 string Message for chat macro 1.
---@field HUSTR_CHATMACRO2 string Message for chat macro 2.
---@field HUSTR_CHATMACRO3 string Message for chat macro 3.
---@field HUSTR_CHATMACRO4 string Message for chat macro 4.
---@field HUSTR_CHATMACRO5 string Message for chat macro 5.
---@field HUSTR_CHATMACRO6 string Message for chat macro 6.
---@field HUSTR_CHATMACRO7 string Message for chat macro 7.
---@field HUSTR_CHATMACRO8 string Message for chat macro 8.
---@field HUSTR_CHATMACRO9 string Message for chat macro 9.
---@field HUSTR_CHATMACRO0 string Message for chat macro 0.
---@field HUSTR_TALKTOSELF1 string Message for talking to yourself one time.
---@field HUSTR_TALKTOSELF2 string Message for talking to yourself two times.
---@field HUSTR_TALKTOSELF3 string Message for talking to yourself three times.
---@field HUSTR_TALKTOSELF4 string Message for talking to yourself four times.
---@field HUSTR_TALKTOSELF5 string Message for talking to yourself five times.
---@field HUSTR_MESSAGESENT string Message for sending a message.
---@field HUSTR_PLRGREEN string Message for player one (green)'s message.
---@field HUSTR_PLRINDIGO string Message for player two (indigo)'s message.
---@field HUSTR_PLRBROWN string Message for player three (brown)'s message.
---@field HUSTR_PLRRED string Message for player four (red)'s message.
---@field HUSTR_KEYGREEN string Key for talking to player one (green).
---@field HUSTR_KEYINDIGO string Key for talking to player two (indigo).
---@field HUSTR_KEYBROWN string Key for talking to player three (brown).
---@field HUSTR_KEYRED string Key for talking to player four (red).
---@field AMSTR_FOLLOWON string Message for turning on follow mode in the automap.
---@field AMSTR_FOLLOWOFF string Message for turning off follow mode in the automap.
---@field AMSTR_GRIDON string Message for turning on the grid in the automap.
---@field AMSTR_GRIDOFF string Message for turning off the grid in the automap.
---@field AMSTR_MARKEDSPOT string Message for marking a spot in the automap.
---@field AMSTR_CLEARMARKS string Message for clearing marks in the automap
---@field STSTR_MUS string Message for when music gets switched.
---@field STSTR_NOMUS string Message for when the target selection is nonexistent.
---@field STSTR_DQDON string Message for when IDDQD is activated.
---@field STSTR_DQDOFF string Message for when IDDQD is deactivated.
---@field STSTR_KFAADDED stringtype Message for when IDKFA is activated.
---@field STSTR_FAADDED stringtype Message for when IDFA is activated.
---@field STSTR_NCON string Message for when noclip is activated.
---@field STSTR_NCOFF string Message for when noclip is deactivated.
---@field STSTR_BEHOLD string Message for when IDBEHOLD is typed.
---@field STSTR_BEHOLDX string Message for when IDBEHOLDx is typed.
---@field STSTR_CHOPPERS string Message for when IDCHOPPERS is typed.
---@field STSTR_CLEV string Message for when IDCLEVxx is typed.