pcall(function()
	dofile("Unregister.lua")
end)
dofile("Globals.lua")
dofile("Freeslots.lua")
dofile("Specials.lua")
dofile("Colors.lua")
dofile("CustChar.lua")
dofile("WADLoad.lua")
dofile("Functions.lua")
dofile("Actions.lua")
dofile("+Use.lua")
dofile("Commands.lua")
dofile("Hooks.lua")
dofile("HUD/Title.lua")
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
dofile("Definitions/Objects/Items/Ammo.lua")
dofile("Definitions/Objects/Items/Armor.lua")
dofile("Definitions/Objects/Items/Health.lua")
dofile("Definitions/Objects/Items/Weapons.lua")
dofile("Definitions/Objects/Keycards/Yellow Key.lua")
dofile("Definitions/Objects/Keycards/Blue Key.lua")
dofile("Definitions/Objects/Keycards/Red Key.lua")
dofile("Definitions/Objects/Monsters/Commander Keen.lua")
dofile("Definitions/Objects/Monsters/Cacodemon.lua")
dofile("Definitions/Objects/Monsters/Imp.lua")
dofile("Definitions/Objects/Monsters/Zombieman.lua")
dofile("Definitions/Objects/Monsters/Shotgunner.lua")
dofile("Definitions/Objects/Monsters/Chaingunner.lua")
dofile("Definitions/Objects/Monsters/Demon.lua")
dofile("Definitions/Objects/Monsters/SS Guard.lua")
dofile("Definitions/Objects/Monsters/Hell Knight.lua")
dofile("Definitions/Objects/Monsters/RomeroHead.lua")
dofile("Definitions/Objects/Monsters/Exploding Barrel.lua")
dofile("Definitions/Objects/Monsters/PLACEHOLD/Archvile.lua")
dofile("Definitions/Objects/Monsters/PLACEHOLD/Lost Soul.lua")
dofile("Definitions/Objects/Projectiles/Rocket.lua")
dofile("HUD/HUDLib.lua")
dofile("HUD/HUD.lua")
dofile("HUD/Inter.lua")
dofile("HUD/Text Screens.lua")
dofile("HUD/ENDOOM.lua")
dofile("Player/JohnDoom.lua")
dofile("Player/Player.lua")
dofile("Player/IntermissionThinker.lua")
dofile("Player/KeyBoardCheats.lua")
dofile("DEH Pointers.lua")

-- VSCode shit since with the advent of doomgfx it's now somewhat more viable as an option

---@class torespawn_t
---@field time integer The time the victim was added to the respawn table
---@field type mobjtype_t The mobjtype of the victim
---@field x fixed_t The x position of the victim
---@field y fixed_t The y position of the victim
---@field z fixed_t The z position of the victim

---@class endoom_t
---@field colors table A 2D table of color values used in ENDOOM screens. Is run-length encoded.
---@field text table A 2D table of strings used in ENDOOM screens.

---@class doomglobal_t
---@field isdoom1 boolean Denotes if the IWAD loaded was based on the Doom 1 engine
---@field torespawn table<torespawn_t> The list of victims to respawn
---@field strings table<doomstrings_t> The set of strings used for various pickups and events
---@field endoom endoom_t The ENDOOM screen data
---@field rndtable table A table of random numbers used for various calculations
---@field prndindex integer The current index in the random number table
---@field addWeapon function A function to register a weapon definition
---@field addAmmo function A function to register an ammo definition
---@field weapons table<weapondef_t> The registered weapon definitions
---@field ammos table<ammodef_t> The registered ammo definitions
---@field thinkers table<any, table> The thinkers in the current map
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
---@field kills integer (Deprecated?) The number of kills the player has made in the current map
---@field items integer (Deprecated?) The number of items the player has collected in the current map
---@field secrets integer (Deprecated?) The number of secrets the player has found in the current map
---@field defaultgravity fixed_t The default gravity value for the map
---@field lineActions table<integer, table> A table of line special actions, indexed by their line special number
---@field linebackups table<line_t, table> A table of line special backups, indexed by their line_t
---@field charSupport table<string, doomcharsupport_t> A table of character support definitions, indexed by skin name

---@class doomspread_t
---@field horiz fixed_t
---@field vert fixed_t

---@class doomstate_t
---@field frame integer The frame of the current state
---@field tics integer The number of tics this state lasts for
---@field action function The action to perform during this state
---@field var1 any The first variable for the action
---@field var2 any The second variable for the action

---@class doomweaponstates_t
---@field idle table<doomstate_t> The idle state of the weapon
---@field attack table<doomstate_t> The attack state of the weapon
---@field lower table<doomstate_t> The lower state of the weapon
---@field raise table<doomstate_t> The raise state of the weapon
---@field flash table<doomstate_t> The gunflash that shows whenever A_DoomFire gets called

---@class weapondef_t
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

---@class ammodef_t
---@field max integer The maximum amount of this ammo the player can carry
---@field backpackmax integer The maximum amount of this ammo the player can carry when they have twoxammo active
---@field icon string (Unused) The icon representing this ammo type
---@field backpackicon string (Unused) The icon representing this ammo type when they have twoxammo active

---@class doompowers_t
---@field pw_strength integer Timer for the Berserk power-up. Counts up if non-zero.
---@field pw_ironfeet integer Timer for the Radiation Suit power-up. Counts down until it turns back to zero.
---@field pw_invisibility integer Timer for the Blursphere power-up. Counts down until it turns back to zero.

---@class laststate_t
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

---@class doomplayer_t
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
---@field twoxammo boolean|integer 2x ammo flag/counter
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

---@class doomflags_t
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

---@class doommobj_t
---@field health integer The health of the mobj
---@field armor integer The armor of the mobj
---@field armorefficiency integer The armor efficiency of the mobj's armor
---@field flags doomflags_t Bitmask of doommobj_t flags (DF_*)

---@class doommethods_t
---@field getHealth fun(player: player_t): integer Gets the health of the player
---@field setHealth fun(player: player_t, health: integer): boolean Sets the health of the player, returns true if successful
---@field getArmor fun(player: player_t): integer Gets the armor of the player
---@field setArmor fun(player: player_t, armor: integer): boolean Sets the armor of the player, returns true if successful
---@field getAmmo fun(player: player_t, ammoType: string): integer Gets the player's ammo for the given ammo type
---@field setAmmo fun(player: player_t, ammoType: string, amount: integer): boolean Sets the player's ammo for the given ammo type, returns true if successful
---@field giveAmmoFor fun(player: player_t, source: string, dflags: doomflags_t): boolean Gives ammo to the player from the given source, returns true if successful
---@field giveWeapon fun(player: player_t, weaponName: string): boolean Gives the specified weapon to the player, returns true if successful
---@field hasWeapon fun(player: player_t, weaponName: string): boolean Checks if the player has the specified weapon
---@field getMaxFor fun(player: player_t, ammoType: string): integer Gets the maximum ammo for the given ammo type
---@field setAmmoFor fun(player: player_t, ammoType: string, amount: integer): boolean Sets the player's ammo for the given ammo type, returns true if successful
---@field getAmmoFor fun(player: player_t, ammoType: string): integer Gets the player's ammo for the given ammo type
---@field getCurAmmoType fun(player: player_t): string Gets the current ammo type for the player's active weapon
---@field getCurAmmo fun(player: player_t): integer Gets the current ammo count for the player's active weapon
---@field damage fun(player: player_t, amount: integer, source: mobj_t, inflictor: mobj_t, damageType: integer, minhealth: integer) Inflicts damage to the player

---@class doomcharsupport_t
---@field noWeapons boolean Whether the character will use our weapon system (true or nil if yes)
---@field noHUD boolean Whether the character will use our HUD system (true or nil if yes)
---@field dontSetRings boolean Whether the character will have their player_t.rings set to their current ammo (true or nil if yes)
---@field customDamage boolean Whether the character will not use their own custom damage handling (true or nil if yes)
---@field methods doommethods_t The methods table for this character

---@class mobj_t
---@field doom doommobj_t

---@class player_t
---@field doom doomplayer_t

---@class mobjinfo_t
---@field doomflags doomflags_t Bitmask of doommobj_t flags (DF_*). Auto-copied to mobj_t.doom.flags on spawn.

---@class doomstrings
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