local SCREENWIDTH = 320
local SCREENHEIGHT = 200

local HU_GAPY = 8
local HU_HUDHEIGHT = (6*HU_GAPY)

local HU_HUDX = 2
local HU_HUDY = (SCREENHEIGHT-HU_HUDHEIGHT-1)

local HU_MONSECY = HU_HUDY+0*HU_GAPY
local HU_KEYSY   = HU_HUDY+1*HU_GAPY
local HU_WEAPY   = HU_HUDY+2*HU_GAPY
local HU_AMMOY   = HU_HUDY+3*HU_GAPY
local HU_HEALTHY = HU_HUDY+4*HU_GAPY
local HU_ARMORY  = HU_HUDY+5*HU_GAPY
local HU_MONSECX = HU_HUDX
local HU_KEYSX   = HU_HUDX
local HU_WEAPX   = HU_HUDX
local HU_AMMOX   = HU_HUDX
local HU_HEALTHX = HU_HUDX
local HU_ARMORX  = HU_HUDX

local boomhudfontwidth = 5

local HU_KEYSGX = HU_HUDX+4*boomhudfontwidth

local HU_HUDX_LL = 2
local HU_HUDY_LL = SCREENHEIGHT-2*HU_GAPY-1
local HU_HUDX_LR = 200
local HU_HUDY_LR = SCREENHEIGHT-2*HU_GAPY-1
local HU_HUDX_UR = 224
local HU_HUDY_UR = 2

local HU_MONSECX_D = HU_HUDX_LL

local HU_WEAPX_D   = HU_HUDX_LR
local HU_AMMOX_D   = HU_HUDX_LR

local HU_HEALTHX_D = HU_HUDX_UR
local HU_ARMORX_D  = HU_HUDX_UR

local HU_MONSECY_D = (HU_HUDY_LL+0*HU_GAPY)
local HU_KEYSX_D   = HU_HUDX_LL
local HU_KEYSGX_D  = HU_HUDX_LL+4*boomhudfontwidth
local HU_KEYSY_D   = (HU_HUDY_LL+1*HU_GAPY)
local HU_WEAPY_D   = (HU_HUDY_LR+0*HU_GAPY)
local HU_AMMOY_D   = (HU_HUDY_LR+1*HU_GAPY)
local HU_HEALTHY_D = (HU_HUDY_UR+0*HU_GAPY)
local HU_ARMORY_D  = (HU_HUDY_UR+1*HU_GAPY)



local w_ammo =   {x = 0, y = 0}
local w_weapon = {x = 0, y = 0}
local w_keys =   {x = 0, y = 0}
local w_gkeys =  {x = 0, y = 0}
local w_monsec = {x = 0, y = 0}
local w_health = {x = 0, y = 0}
local w_armor =  {x = 0, y = 0}



local hud_ammostr = "AMM "
local hud_healthstr = "HEL "
local hud_armorstr = "ARM "
local hud_weapstr = "WEA "
local hud_keysstr = "KEY "
local hud_gkeysstr = " "
local hud_monsecstr = "STS "

local function HU_MoveHud(player)
	local hudPref = DOOM_GetConfigStoreValue(player, "hudstyle") or 0
	if (hudPref & 2) then
		w_ammo.x =    HU_AMMOX
		w_ammo.y =    HU_AMMOY
		w_ammo.f =    V_SNAPTOBOTTOM|V_SNAPTOLEFT
		w_weapon.x =  HU_WEAPX
		w_weapon.y =  HU_WEAPY
		w_weapon.f =  V_SNAPTOBOTTOM|V_SNAPTOLEFT
		w_keys.x =    HU_KEYSX
		w_keys.y =    HU_KEYSY
		w_keys.f =    V_SNAPTOBOTTOM|V_SNAPTOLEFT
		w_gkeys.x =   HU_KEYSGX
		w_gkeys.y =   HU_KEYSY
		w_gkeys.f =   V_SNAPTOBOTTOM|V_SNAPTOLEFT
		w_monsec.x =  HU_MONSECX
		w_monsec.y =  HU_MONSECY
		w_monsec.f =  V_SNAPTOBOTTOM|V_SNAPTOLEFT
		w_health.x =  HU_HEALTHX
		w_health.y =  HU_HEALTHY
		w_health.f =  V_SNAPTOBOTTOM|V_SNAPTOLEFT
		w_armor.x =   HU_ARMORX
		w_armor.y =   HU_ARMORY
		w_armor.f =   V_SNAPTOBOTTOM|V_SNAPTOLEFT
	else
		w_ammo.x =    HU_AMMOX_D
		w_ammo.y =    HU_AMMOY_D
		w_weapon.x =  HU_WEAPX_D
		w_weapon.y =  HU_WEAPY_D
		w_keys.x =    HU_KEYSX_D
		w_keys.y =    HU_KEYSY_D
		w_gkeys.x =   HU_KEYSGX_D
		w_gkeys.y =   HU_KEYSY_D
		w_monsec.x =  HU_MONSECX_D
		w_monsec.y =  HU_MONSECY_D
		w_health.x =  HU_HEALTHX_D
		w_health.y =  HU_HEALTHY_D
		w_armor.x =   HU_ARMORX_D
		w_armor.y =   HU_ARMORY_D
	end

	hud_ammostr = "AMM "
	hud_healthstr = "HEL "
	hud_armorstr = "ARM "
	hud_weapstr = "WEA "
	if (gametyperules & GTR_RINGSLINGER) then
		hud_keysstr = "FRG "
	else
		hud_keysstr = "KEY "
	end
	hud_gkeysstr = " "
	hud_monsecstr = "STS "
end

local CR_BRICK = 0
local CR_TAN = 1
local CR_GRAY = 2
local CR_GREEN = 3
local CR_BROWN = 4
local CR_GOLD = 5
local CR_RED = 6
local CR_BLUE = 7
local CR_ORANGE = 8
local CR_YELLOW = 9

local translations = {
	[CR_BRICK] = "BOOMCRBRICK",
	"BOOMCRTAN",
	"BOOMCRGRAY",
	"BOOMCRGREEN",
	"BOOMCRBROWN",
	"BOOMCRGOLD",
	"BOOMCRRED",
	"BOOMCRBLUE",
	"BOOMCRORANGE",
	"BOOMCRYELLOW"
}

---@param v videolib
local function drawBOOMString(v, x, y, str, cr, f)
	cr = cr == nil and CR_GRAY or cr
    str = str or "You forgot the string, chump!"  -- default string
	local skipnextflag = false

    for i = 1, #str do
		if skipnextflag then
			skipnextflag = false
			continue
		end
        local c = str:sub(i,i)
        local byte = c:byte()

        if c == "\n" then
            x = 0
            y = y + 8

        elseif c == "\t" then
            x = x - (x % 80) + 80

        elseif c == "\x1b" then
            i = i + 1
            if i <= #str then
                local nextc = str:sub(i,i)
                if nextc:match("%d") then
					-- TODO: is this correct??
					cr = tonumber(nextc)
					skipnextflag = true
                end
            end

        elseif byte > 32 and byte <= 127 then
            local patch
            local name = "DIG" .. c
            if not v.patchExists(name) then
                name = "DIG" .. byte
            end
            if not v.patchExists(name) then
                name = "STBR" .. byte
            end
			if v.patchExists(name) then
				patch = v.cachePatch(name)

				if x + patch.width > SCREENWIDTH then
					break
				end

				local crtocmap
				if cr != nil then
					crtocmap = v.getColormap(nil, nil, translations[cr])
				end
				v.draw(x, y, patch, f, crtocmap)
				x = x + patch.width
			else
				x = x + 4
				if x >= SCREENWIDTH then
					break
				end
			end

        else
            x = x + 4
            if x >= SCREENWIDTH then
                break
            end
        end
    end
end

---@param v videolib
---@param player player_t
local function DoBOOMHud(v, player)
	local ammostr, healthstr, armorstr = "", "", ""

	HU_MoveHud(player)
	local hudPref = player.doom.prefs

	local funcs = P_GetMethodsForSkin(player)

	local ammo_red = hudPref.t_ammo_red
	local ammo_yellow = hudPref.t_ammo_yellow


	hud_ammostr = "AMM "
	local curwep = DOOM_GetWeaponDef(player)
	if doom.ammos[curwep.ammotype].max < 0 then
		hud_ammostr = $ .. "\x7f\x7f\x7f\x7f\x7f\x7f\x7f N/A"
		w_ammo.cr = CR_GRAY
	else
		local ammo = funcs.getCurAmmo(player)
		local fullammo = funcs.getMaxFor(player, curwep.ammotype)
		local ammopct = (100*ammo)/fullammo
		local ammobars = ammopct/4
		local full = ammobars/4

		ammostr = ammo .. "/" .. fullammo

		for i = 1, full do
			hud_ammostr = $ .. string.char(123)
		end

		local rem = ammobars % 4
		if rem ~= 0 then
			hud_ammostr = $ .. string.char(127 - rem)
		end

		local total = full + (rem > 0 and 1 or 0)
		hud_ammostr = $ .. string.rep(string.char(127), 7 - total)

		hud_ammostr = $ .. ammostr

		if ammopct < ammo_red then
			w_ammo.cr = CR_RED
		elseif ammopct < ammo_yellow then
			w_ammo.cr = CR_GOLD
		else
			w_ammo.cr = CR_GREEN
		end
	end
	drawBOOMString(v, w_ammo.x, w_ammo.y, hud_ammostr, w_ammo.cr, w_ammo.f)

	local health = funcs.getHealth(player)
	local maxhealth = funcs.getMaxHealth(player)
	if health == nil then
		hud_healthstr = $ .. "\x7f\x7f\x7f\x7f\x7f\x7f\x7f N/A"
	else
		local healthpct
		if health >= maxhealth then
			healthpct = 100
		else
			healthpct = (100*health)/maxhealth
		end
		local healthbars = healthpct/4
		local full = healthbars/4

		healthstr = string.format("%3d", health)

		for i = 1, full do
			hud_healthstr = $ .. string.char(123)
		end

		local rem = healthbars % 4
		if rem ~= 0 then
			hud_healthstr = $ .. string.char(127 - rem)
		end

		local total = full + (rem > 0 and 1 or 0)
		hud_healthstr = $ .. string.rep(string.char(127), 7 - total)

		hud_healthstr = $ .. healthstr

		local health_red = hudPref.t_health_red
		local health_yellow = hudPref.t_health_yellow
		local health_green = tonumber(hudPref.t_health_green) or 0

		if healthpct < health_red then
			w_health.cr = CR_RED
		elseif healthpct < health_yellow then
			w_health.cr = CR_GOLD
		elseif healthpct <= health_green then
			w_health.cr = CR_GREEN
		else
			w_health.cr = CR_BLUE
		end
	end
	drawBOOMString(v, w_health.x, w_health.y, hud_healthstr, w_health.cr, w_health.f)

	local armor = funcs.getArmor(player)
	local maxarmor = funcs.getMaxArmor(player)
	if armor == nil then
		hud_armorstr = $ .. "\x7f\x7f\x7f\x7f\x7f\x7f\x7f N/A"
	else
		local healthpct
		if armor >= maxarmor then
			healthpct = 100
		else
			healthpct = (100*armor)/maxarmor
		end
		local healthbars = healthpct/4
		local full = healthbars/4

		armorstr = string.format("%3d", armor)

		for i = 1, full do
			hud_armorstr = $ .. string.char(123)
		end

		local rem = healthbars % 4
		if rem ~= 0 then
			hud_armorstr = $ .. string.char(127 - rem)
		end

		local total = full + (rem > 0 and 1 or 0)
		hud_armorstr = $ .. string.rep(string.char(127), 7 - total)

		hud_armorstr = $ .. armorstr

		local health_red = tonumber(hudPref.t_health_red) or 25
		local health_yellow = tonumber(hudPref.t_health_yellow) or 50
		local health_green = tonumber(hudPref.t_health_green) or 100

		if healthpct < health_red then
			w_armor.cr = CR_RED
		elseif healthpct < health_yellow then
			w_armor.cr = CR_GOLD
		elseif healthpct <= health_green then
			w_armor.cr = CR_GREEN
		else
			w_armor.cr = CR_BLUE
		end
	end
	drawBOOMString(v, w_armor.x, w_armor.y, hud_armorstr, w_armor.cr, w_armor.f)

	local wp_fist = 0
	local wp_pistol = 1
	local wp_shotgun = 2
	local wp_chaingun = 3
	local wp_missile = 4
	local wp_plasma = 5
	local wp_bfg = 6
	local wp_chainsaw = 7
	local wp_supershotgun = 8

	local consttorealname = {
		[wp_fist] = "brassknuckles",
		[wp_pistol] = "pistol",
		[wp_shotgun] = "shotgun",
		[wp_chaingun] = "chaingun",
		[wp_missile] = "rocketlauncher",
		[wp_plasma] = "plasmarifle",
		[wp_bfg] = "bfg9000",
		[wp_chainsaw] = "chainsaw",
		[wp_supershotgun] = "supershotgun"
	}

	for i = 0, 8 do
		local gamemode = doom.gamemode
		if gamemode == "shareware" then
			if i >= wp_plasma and i != wp_chainsaw then
				continue
			end
		elseif gamemode == "retail" or gamemode == "registered" then
			if i >= wp_supershotgun then
				continue
			end
		end

		local trueweapon = consttorealname[i] or "brassknuckles"
		if not funcs.hasWeapon(player, trueweapon) then continue end
		trueweapon = doom.weapons[$]

		local ammo = funcs.getAmmoFor(player, trueweapon.ammotype)
		local fullammo = funcs.getMaxFor(player, trueweapon.ammotype)
		local isInfinite = false
		if ammo == false or ammo == nil or fullammo == false or fullammo == nil then
			isInfinite = true
		end
		local ammopct = not isInfinite and (100*ammo)/fullammo or 0

		hud_weapstr = $ .. "\x1b"
		if isInfinite or doom.ammos[trueweapon.ammotype].max < 0 then
			if trueweapon == "brassknuckles" or trueweapon == "chainsaw" then
				local berserk = funcs.hasPowerUp(player, "berserk")
				local suffix = berserk and (CR_GREEN) or (CR_GRAY)
				hud_weapstr = $ .. suffix
			else
				hud_weapstr = $ .. CR_GRAY
			end
		elseif ammopct < ammo_red then
			hud_weapstr = $ .. CR_RED
		elseif ammopct < ammo_yellow then
			hud_weapstr = $ .. CR_GOLD
		else
			hud_weapstr = $ .. CR_GREEN
		end

		hud_weapstr = $ .. i + 1
		hud_weapstr = $ .. " "
	end

	drawBOOMString(v, w_weapon.x, w_weapon.y, hud_weapstr, nil, w_weapon.f)

	local hudPrefVal = DOOM_GetConfigStoreValue(player, "hudstyle")
	if hudPrefVal % 2 then return end


	local deathmatch = (gametyperules & GTR_RINGSLINGER)
	local hud_graph_keys = true

	if not deathmatch and hud_graph_keys then
		for k = 0, 5 do
			local bit = 1 << k
			if not (player.doom.keys & bit) then continue end
			local stringbyte = string.char(string.byte("!") + k)
			hud_gkeysstr = $ .. stringbyte .. "  "
		end
	else
		if deathmatch then
			local top1, top2, top3, top4 = -999, -999, -999, -999
			local idx1, idx2, idx3, idx4 = -1, -1, -1, -1
			local fragcount, m
			local numbuf = ""
			for player in players.iterate() do
				if player.spectator then continue end

				fragcount = doom.getFrags(player)

				if fragcount > top1 then
					top4 = top3
					top3 = top2
					top2 = top1
					top1 = fragcount
					idx4 = idx3
					idx3 = idx2
					idx2 = idx1
					idx1 = k
				elseif fragcount > top2 then
					top4 = top3
					top3 = top2
					top2 = fragcount
					idx4 = idx3
					idx3 = idx2
					idx2 = fragcount
				elseif fragcount > top3 then
					top4 = top3
					top3 = fragcount
					idx4 = idx3
					idx3 = k
				elseif fragcount > top4 then
					top4 = fragcount
					idx4 = k
				end
			end

			if idx1 > -1 then
				local numbuf = string.format("%5d", top1)
				hud_keysstr = $ .. "\x1b"
				hud_keysstr = $ .. "0" + (idx1 & 3)
				hud_keysstr = $ .. numbuf
			end

			if idx2 > -1 then
				local numbuf = string.format("%5d", top2)
				hud_keysstr = $ .. "\x1b"
				hud_keysstr = $ .. "0" + (idx2 & 3)
				hud_keysstr = $ .. numbuf
			end

			if idx3 > -1 then
				local numbuf = string.format("%5d", top3)
				hud_keysstr = $ .. "\x1b"
				hud_keysstr = $ .. "0" + (idx3 & 3)
				hud_keysstr = $ .. numbuf
			end

			if idx4 > -1 then
				local numbuf = string.format("%5d", top4)
				hud_keysstr = $ .. "\x1b"
				hud_keysstr = $ .. "0" + (idx4 & 3)
				hud_keysstr = $ .. numbuf
			end
		else
			local i = 4
			for k = 0, 5 do
				if not (player.doom.keys & (1 << k)) then continue end
				hud_keysstr = $ .. "\x1b"
				if k == 0 then
					hud_keysstr = $ .. CR_BLUE .. "BC "
				elseif k == 1 then
					hud_keysstr = $ .. CR_GOLD .. "YC "
				elseif k == 2 then
					hud_keysstr = $ .. CR_RED .. "RC "
				elseif k == 3 then
					hud_keysstr = $ .. CR_BLUE .. "BS "
				elseif k == 4 then
					hud_keysstr = $ .. CR_GOLD .. "YS "
				elseif k == 5 then
					hud_keysstr = $ .. CR_RED .. "RS "
				end
			end
		end
	end
	drawBOOMString(v, w_keys.x, w_keys.y, hud_keysstr, nil, w_keys.f)
	if not deathmatch then
		drawBOOMString(v, w_gkeys.x, w_gkeys.y, hud_gkeysstr, nil, w_gkeys.f)
	end

	local hud_nosecrets = player.doom.prefs.nosecrets
	if not hud_nosecrets then
		hud_monsecstr = $ .. "\x1b\x36K \x1b\x33" .. (player.doom.kills or "NIL") .. "/" .. (doom.killcount or "NIL")
		hud_monsecstr = $ .. " \x1b\x37I \x1b\x33" .. (player.doom.items or "NIL") .. "/" .. (doom.itemcount or "NIL")
		hud_monsecstr = $ .. " \x1b\x35S \x1b\x33" .. (player.doom.secrets or "NIL") .. "/" .. (doom.secretcount or "NIL")
		drawBOOMString(v, w_monsec.x, w_monsec.y, hud_monsecstr, nil, w_monsec.f)
	end
/*
    // display the hud kills/items/secret display if optioned
    if (!hud_nosecrets)
    {
      if (hud_active>1 && doit)
      {
        // clear the internal widget text buffer
        HUlib_clearTextLine(&w_monsec);
        //jff 3/26/98 use ESC not '\' for paths
        // build the init string with fixed colors
        sprintf
        (
          hud_monsecstr,
          "STS \x1b\x36K \x1b\x33%d/%d \x1b\x37I \x1b\x33%d/%d \x1b\x35S \x1b\x33%d/%d",
          plr->killcount,totalkills,
          plr->itemcount,totalitems,
          plr->secretcount,totalsecret
        );
        // transfer the init string to the widget
        s = hud_monsecstr;
        while (*s)
          HUlib_addCharToTextLine(&w_monsec, *(s++));
      }
      // display the kills/items/secrets each frame, if optioned
      if (hud_active>1)
        HUlib_drawTextLine(&w_monsec, false);
    }
  }

  //jff 3/4/98 display last to give priority
  HU_Erase(); // jff 4/24/98 Erase current lines before drawing current
              // needed when screen not fullsize

  //jff 4/21/98 if setup has disabled message list while active, turn it off
  if (hud_msg_lines<=1)
    message_list = false;

  // if the message review not enabled, show the standard message widget
  if (!message_list)
    HUlib_drawSText(&w_message);

  // if the message review is enabled show the scrolling message review
  if (hud_msg_lines>1 && message_list)
    HUlib_drawMText(&w_rtext);

  // display the interactive buffer for chat entry
  HUlib_drawIText(&w_chat);
*/
end

return DoBOOMHud