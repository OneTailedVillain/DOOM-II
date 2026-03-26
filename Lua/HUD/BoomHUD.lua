/*
//
// Locally used constants, shortcuts.
//
// Ty 03/28/98 -
// These four shortcuts modifed to reflect char ** of mapnamesx[]
#define HU_TITLE  (*mapnames[(gameepisode-1)*9+gamemap-1])
#define HU_TITLE2 (*mapnames2[gamemap-1])
#define HU_TITLEP (*mapnamesp[gamemap-1])
#define HU_TITLET (*mapnamest[gamemap-1])
#define HU_TITLEHEIGHT  1
#define HU_TITLEX 0
//jff 2/16/98 change 167 to ST_Y-1
#define HU_TITLEY (ST_Y - 1 - SHORT(hu_font[0]->height))

//jff 2/16/98 add coord text widget coordinates
#define HU_COORDX (SCREENWIDTH - 13*SHORT(hu_font2['A'-HU_FONTSTART]->width))
//jff 3/3/98 split coord widget into three lines in upper right of screen
#define HU_COORDX_Y (1 + 0*SHORT(hu_font['A'-HU_FONTSTART]->height))
#define HU_COORDY_Y (2 + 1*SHORT(hu_font['A'-HU_FONTSTART]->height))
#define HU_COORDZ_Y (3 + 2*SHORT(hu_font['A'-HU_FONTSTART]->height))

//jff 2/16/98 add ammo, health, armor widgets, 2/22/98 less gap
#define HU_GAPY 8
#define HU_HUDHEIGHT (6*HU_GAPY)
#define HU_HUDX 2
#define HU_HUDY (SCREENHEIGHT-HU_HUDHEIGHT-1)
#define HU_MONSECX (HU_HUDX)
#define HU_MONSECY (HU_HUDY+0*HU_GAPY)
#define HU_KEYSX   (HU_HUDX)
//jff 3/7/98 add offset for graphic key widget
#define HU_KEYSGX  (HU_HUDX+4*SHORT(hu_font2['A'-HU_FONTSTART]->width))
#define HU_KEYSY   (HU_HUDY+1*HU_GAPY)
#define HU_WEAPX   (HU_HUDX)
#define HU_WEAPY   (HU_HUDY+2*HU_GAPY)
#define HU_AMMOX   (HU_HUDX)
#define HU_AMMOY   (HU_HUDY+3*HU_GAPY)
#define HU_HEALTHX (HU_HUDX)
#define HU_HEALTHY (HU_HUDY+4*HU_GAPY)
#define HU_ARMORX  (HU_HUDX)
#define HU_ARMORY  (HU_HUDY+5*HU_GAPY)

//jff 3/4/98 distributed HUD positions
#define HU_HUDX_LL 2
#define HU_HUDY_LL (SCREENHEIGHT-2*HU_GAPY-1)
#define HU_HUDX_LR 200
#define HU_HUDY_LR (SCREENHEIGHT-2*HU_GAPY-1)
#define HU_HUDX_UR 224
#define HU_HUDY_UR 2
#define HU_MONSECX_D (HU_HUDX_LL)
#define HU_MONSECY_D (HU_HUDY_LL+0*HU_GAPY)
#define HU_KEYSX_D   (HU_HUDX_LL)
#define HU_KEYSGX_D  (HU_HUDX_LL+4*SHORT(hu_font2['A'-HU_FONTSTART]->width))
#define HU_KEYSY_D   (HU_HUDY_LL+1*HU_GAPY)
#define HU_WEAPX_D   (HU_HUDX_LR)
#define HU_WEAPY_D   (HU_HUDY_LR+0*HU_GAPY)
#define HU_AMMOX_D   (HU_HUDX_LR)
#define HU_AMMOY_D   (HU_HUDY_LR+1*HU_GAPY)
#define HU_HEALTHX_D (HU_HUDX_UR)
#define HU_HEALTHY_D (HU_HUDY_UR+0*HU_GAPY)
#define HU_ARMORX_D  (HU_HUDX_UR)
#define HU_ARMORY_D  (HU_HUDY_UR+1*HU_GAPY)

//
// HU_Drawer()
//
// Draw all the pieces of the heads-up display
//
// Passed nothing, returns nothing
//
void HU_Drawer(void)
{
  char *s;
  player_t *plr;
  char ammostr[80];  //jff 3/8/98 allow plenty room for dehacked mods
  char healthstr[80];//jff
  char armorstr[80]; //jff
  int i,doit;

  plr = &players[displayplayer];         // killough 3/7/98
  // draw the automap widgets if automap is displayed
  if (automapactive)
  {
    // map title
    HUlib_drawTextLine(&w_title, false);

    //jff 2/16/98 output new coord display
    // x-coord
    sprintf(hud_coordstrx,"X: %-5d", (plr->mo->x)>>FRACBITS);
    HUlib_clearTextLine(&w_coordx);
    s = hud_coordstrx;
    while (*s)
      HUlib_addCharToTextLine(&w_coordx, *(s++));
    HUlib_drawTextLine(&w_coordx, false);

    //jff 3/3/98 split coord display into x,y,z lines
    // y-coord
    sprintf(hud_coordstry,"Y: %-5d", (plr->mo->y)>>FRACBITS);
    HUlib_clearTextLine(&w_coordy);
    s = hud_coordstry;
    while (*s)
      HUlib_addCharToTextLine(&w_coordy, *(s++));
    HUlib_drawTextLine(&w_coordy, false);

    //jff 3/3/98 split coord display into x,y,z lines
    //jff 2/22/98 added z
    // z-coord
    sprintf(hud_coordstrz,"Z: %-5d", (plr->mo->z)>>FRACBITS);
    HUlib_clearTextLine(&w_coordz);
    s = hud_coordstrz;
    while (*s)
      HUlib_addCharToTextLine(&w_coordz, *(s++));
    HUlib_drawTextLine(&w_coordz, false);
  }

  // draw the weapon/health/ammo/armor/kills/keys displays if optioned
  //jff 2/17/98 allow new hud stuff to be turned off
  // killough 2/21/98: really allow new hud stuff to be turned off COMPLETELY
  if
  (
    hud_active>0 &&                  // hud optioned on
    hud_displayed &&                 // hud on from fullscreen key
    viewheight==SCREENHEIGHT &&      // fullscreen mode is active
    !automapactive                   // automap is not active
  )
  {
    doit = !(gametic&1); //jff 3/4/98 speed update up for slow systems
    if (doit)            //jff 8/7/98 update every time, avoid lag in update
    {
      HU_MoveHud();                  // insure HUD display coords are correct

      // do the hud ammo display
      // clear the widgets internal line
      HUlib_clearTextLine(&w_ammo);
      strcpy(hud_ammostr,"AMM ");
      if (weaponinfo[plr->readyweapon].ammo == am_noammo)
      { // special case for weapon with no ammo selected - blank bargraph + N/A
        strcat(hud_ammostr,"\x7f\x7f\x7f\x7f\x7f\x7f\x7f N/A");
        w_ammo.cr = colrngs[CR_GRAY];
      }
      else
      {
        int ammo = plr->ammo[weaponinfo[plr->readyweapon].ammo];
        int fullammo = plr->maxammo[weaponinfo[plr->readyweapon].ammo];
        int ammopct = (100*ammo)/fullammo;
        int ammobars = ammopct/4;

        // build the numeric amount init string
        sprintf(ammostr,"%d/%d",ammo,fullammo);
        // build the bargraph string
        // full bargraph chars
        for (i=4;i<4+ammobars/4;)
          hud_ammostr[i++] = 123;
        // plus one last character with 0,1,2,3 bars
        switch(ammobars%4)
        {
          case 0:
            break;
          case 1:
            hud_ammostr[i++] = 126;
            break;
          case 2:
            hud_ammostr[i++] = 125;
            break;
          case 3:
            hud_ammostr[i++] = 124;
            break;
        }
        // pad string with blank bar characters
        while(i<4+7)
          hud_ammostr[i++] = 127;
        hud_ammostr[i] = '\0';
        strcat(hud_ammostr,ammostr);

        // set the display color from the percentage of total ammo held
        if (ammopct<ammo_red)
          w_ammo.cr = colrngs[CR_RED];
        else if (ammopct<ammo_yellow)
          w_ammo.cr = colrngs[CR_GOLD];
        else
          w_ammo.cr = colrngs[CR_GREEN];
      }
      // transfer the init string to the widget
      s = hud_ammostr;
      while (*s)
        HUlib_addCharToTextLine(&w_ammo, *(s++));
    }
    // display the ammo widget every frame
    HUlib_drawTextLine(&w_ammo, false);

    // do the hud health display
    if (doit)
    {
      int health = plr->health;
      int healthbars = health>100? 25 : health/4;

      // clear the widgets internal line
      HUlib_clearTextLine(&w_health);

      // build the numeric amount init string
      sprintf(healthstr,"%3d",health);
      // build the bargraph string
      // full bargraph chars
      for (i=4;i<4+healthbars/4;)
        hud_healthstr[i++] = 123;
      // plus one last character with 0,1,2,3 bars
      switch(healthbars%4)
      {
        case 0:
          break;
        case 1:
          hud_healthstr[i++] = 126;
          break;
        case 2:
          hud_healthstr[i++] = 125;
          break;
        case 3:
          hud_healthstr[i++] = 124;
          break;
      }
      // pad string with blank bar characters
      while(i<4+7)
        hud_healthstr[i++] = 127;
      hud_healthstr[i] = '\0';
      strcat(hud_healthstr,healthstr);

      // set the display color from the amount of health posessed
      if (health<health_red)
        w_health.cr = colrngs[CR_RED];
      else if (health<health_yellow)
        w_health.cr = colrngs[CR_GOLD];
      else if (health<=health_green)
        w_health.cr = colrngs[CR_GREEN];
      else
        w_health.cr = colrngs[CR_BLUE];

      // transfer the init string to the widget
      s = hud_healthstr;
      while (*s)
        HUlib_addCharToTextLine(&w_health, *(s++));
    }
    // display the health widget every frame
    HUlib_drawTextLine(&w_health, false);

    // do the hud armor display
    if (doit)
    {
      int armor = plr->armorpoints;
      int armorbars = armor>100? 25 : armor/4;

      // clear the widgets internal line
      HUlib_clearTextLine(&w_armor);
      // build the numeric amount init string
      sprintf(armorstr,"%3d",armor);
      // build the bargraph string
      // full bargraph chars
      for (i=4;i<4+armorbars/4;)
        hud_armorstr[i++] = 123;
      // plus one last character with 0,1,2,3 bars
      switch(armorbars%4)
      {
        case 0:
          break;
        case 1:
          hud_armorstr[i++] = 126;
          break;
        case 2:
          hud_armorstr[i++] = 125;
          break;
        case 3:
          hud_armorstr[i++] = 124;
          break;
      }
      // pad string with blank bar characters
      while(i<4+7)
        hud_armorstr[i++] = 127;
      hud_armorstr[i] = '\0';
      strcat(hud_armorstr,armorstr);

      // set the display color from the amount of armor posessed
      if (armor<armor_red)
        w_armor.cr = colrngs[CR_RED];
      else if (armor<armor_yellow)
        w_armor.cr = colrngs[CR_GOLD];
      else if (armor<=armor_green)
        w_armor.cr = colrngs[CR_GREEN];
      else
        w_armor.cr = colrngs[CR_BLUE];

      // transfer the init string to the widget
      s = hud_armorstr;
      while (*s)
        HUlib_addCharToTextLine(&w_armor, *(s++));
    }
    // display the armor widget every frame
    HUlib_drawTextLine(&w_armor, false);

    // do the hud weapon display
    if (doit)
    {
      int w;
      int ammo,fullammo,ammopct;

      // clear the widgets internal line
      HUlib_clearTextLine(&w_weapon);
      i=4; hud_weapstr[i] = '\0';      //jff 3/7/98 make sure ammo goes away

      // do each weapon that exists in current gamemode
      for (w=0;w<=wp_supershotgun;w++) //jff 3/4/98 show fists too, why not?
      {
        int ok=1;
        //jff avoid executing for weapons that do not exist
        switch (gamemode)
        {
          case shareware:
            if (w>=wp_plasma && w!=wp_chainsaw)
              ok=0;
            break;
          case retail:
          case registered:
            if (w>=wp_supershotgun)
              ok=0;
            break;
          default:
          case commercial:
            break;
        }
        if (!ok) continue;

        ammo = plr->ammo[weaponinfo[w].ammo];
        fullammo = plr->maxammo[weaponinfo[w].ammo];
        ammopct=0;

        // skip weapons not currently posessed
        if (!plr->weaponowned[w])
          continue;

        ammopct = fullammo? (100*ammo)/fullammo : 100;

        // display each weapon number in a color related to the ammo for it
        hud_weapstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
        if (weaponinfo[w].ammo==am_noammo) //jff 3/14/98 show berserk on HUD
          hud_weapstr[i++] = plr->powers[pw_strength]? '0'+CR_GREEN : '0'+CR_GRAY;
        else if (ammopct<ammo_red)
          hud_weapstr[i++] = '0'+CR_RED;
        else if (ammopct<ammo_yellow)
          hud_weapstr[i++] = '0'+CR_GOLD;
        else
          hud_weapstr[i++] = '0'+CR_GREEN;
        hud_weapstr[i++] = '0'+w+1;
        hud_weapstr[i++] = ' ';
        hud_weapstr[i] = '\0';
      }

      // transfer the init string to the widget
      s = hud_weapstr;
      while (*s)
        HUlib_addCharToTextLine(&w_weapon, *(s++));
    }
    // display the weapon widget every frame
    HUlib_drawTextLine(&w_weapon, false);

    if (doit && hud_active>1)
    {
      int k;

      hud_keysstr[4] = '\0';    //jff 3/7/98 make sure deleted keys go away
      //jff add case for graphic key display
      if (!deathmatch && hud_graph_keys)
      {
        i=0;
        hud_gkeysstr[i] = '\0'; //jff 3/7/98 init graphic keys widget string
        // build text string whose characters call out graphic keys from fontk
        for (k=0;k<6;k++)
        {
          // skip keys not possessed
          if (!plr->cards[k])
            continue;

          hud_gkeysstr[i++] = '!'+k;   // key number plus '!' is char for key
          hud_gkeysstr[i++] = ' ';     // spacing
          hud_gkeysstr[i++] = ' ';
        }
        hud_gkeysstr[i]='\0';
      }
      else // not possible in current code, unless deathmatching,
      {
        i=4;
        hud_keysstr[i] = '\0';  //jff 3/7/98 make sure deleted keys go away

        // if deathmatch, build string showing top four frag counts
        if (deathmatch) //jff 3/17/98 show frags, not keys, in deathmatch
        {
          int top1=-999,top2=-999,top3=-999,top4=-999;
          int idx1=-1,idx2=-1,idx3=-1,idx4=-1;
          int fragcount,m;
          char numbuf[32];

          // scan thru players
          for (k=0;k<MAXPLAYERS;k++)
          {
            // skip players not in game
            if (!playeringame[k])
              continue;

            fragcount = 0;
            // compute number of times they've fragged each player
            // minus number of times they've been fragged by them
            for (m=0;m<MAXPLAYERS;m++)
            {
              if (!playeringame[m]) continue;
              fragcount += (m!=k)?  players[k].frags[m] : -players[k].frags[m];
            }

            // very primitive sort of frags to find top four
            if (fragcount>top1)
            {
              top4=top3; top3=top2; top2 = top1; top1=fragcount;
              idx4=idx3; idx3=idx2; idx2 = idx1; idx1=k;
            }
            else if (fragcount>top2)
            {
              top4=top3; top3=top2; top2=fragcount;
              idx4=idx3; idx3=idx2; idx2=k;
            }
            else if (fragcount>top3)
            {
              top4=top3; top3=fragcount;
              idx4=idx3; idx3=k;
            }
            else if (fragcount>top4)
            {
              top4=fragcount;
              idx4=k;
            }
          }
          // if the biggest number exists, put it in the init string
          if (idx1>-1)
          {
            sprintf(numbuf,"%5d",top1);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx1&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          // if the second biggest number exists, put it in the init string
          if (idx2>-1)
          {
            sprintf(numbuf,"%5d",top2);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx2&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          // if the third biggest number exists, put it in the init string
          if (idx3>-1)
          {
            sprintf(numbuf,"%5d",top3);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx3&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          // if the fourth biggest number exists, put it in the init string
          if (idx4>-1)
          {
            sprintf(numbuf,"%5d",top4);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx4&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          hud_keysstr[i] = '\0';
        } //jff 3/17/98 end of deathmatch clause
        else // build alphabetical key display (not used currently)
        {
          // scan the keys
          for (k=0;k<6;k++)
          {
            // skip any not possessed by the displayed player's stats
            if (!plr->cards[k])
              continue;

            // use color escapes to make text in key's color
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            switch(k)
            {
              case 0:
                hud_keysstr[i++] = '0'+CR_BLUE;
                hud_keysstr[i++] = 'B';
                hud_keysstr[i++] = 'C';
                hud_keysstr[i++] = ' ';
                break;
              case 1:
                hud_keysstr[i++] = '0'+CR_GOLD;
                hud_keysstr[i++] = 'Y';
                hud_keysstr[i++] = 'C';
                hud_keysstr[i++] = ' ';
                break;
              case 2:
                hud_keysstr[i++] = '0'+CR_RED;
                hud_keysstr[i++] = 'R';
                hud_keysstr[i++] = 'C';
                hud_keysstr[i++] = ' ';
                break;
              case 3:
                hud_keysstr[i++] = '0'+CR_BLUE;
                hud_keysstr[i++] = 'B';
                hud_keysstr[i++] = 'S';
                hud_keysstr[i++] = ' ';
                break;
            case 4:
                hud_keysstr[i++] = '0'+CR_GOLD;
                hud_keysstr[i++] = 'Y';
                hud_keysstr[i++] = 'S';
                hud_keysstr[i++] = ' ';
                break;
              case 5:
                hud_keysstr[i++] = '0'+CR_RED;
                hud_keysstr[i++] = 'R';
                hud_keysstr[i++] = 'S';
                hud_keysstr[i++] = ' ';
                break;
            }
            hud_keysstr[i]='\0';
          }
        }
      }
    }
    // display the keys/frags line each frame
    if (hud_active>1)
    {
      HUlib_clearTextLine(&w_keys);      // clear the widget strings
      HUlib_clearTextLine(&w_gkeys);

      // transfer the built string (frags or key title) to the widget
      s = hud_keysstr; //jff 3/7/98 display key titles/key text or frags
      while (*s)
        HUlib_addCharToTextLine(&w_keys, *(s++));
      HUlib_drawTextLine(&w_keys, false);

      //jff 3/17/98 show graphic keys in non-DM only
      if (!deathmatch) //jff 3/7/98 display graphic keys
      {
        // transfer the graphic key text to the widget
        s = hud_gkeysstr;
        while (*s)
          HUlib_addCharToTextLine(&w_gkeys, *(s++));
        // display the widget
        HUlib_drawTextLine(&w_gkeys, false);
      }
    }

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
}
*/

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

local function HU_MoveHud()
	if (doom.cvars.user_hudpref.value & 2) then
		w_ammo.x =    HU_AMMOX
		w_ammo.y =    HU_AMMOY
		w_weapon.x =  HU_WEAPX
		w_weapon.y =  HU_WEAPY
		w_keys.x =    HU_KEYSX
		w_keys.y =    HU_KEYSY
		w_gkeys.x =   HU_KEYSGX
		w_gkeys.y =   HU_KEYSY
		w_monsec.x =  HU_MONSECX
		w_monsec.y =  HU_MONSECY
		w_health.x =  HU_HEALTHX
		w_health.y =  HU_HEALTHY
		w_armor.x =   HU_ARMORX
		w_armor.y =   HU_ARMORY
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

local CR_GRAY = 2
local CR_GREEN = 3
local CR_GOLD = 5
local CR_RED = 6
local CR_BLUE = 7

local translations = {
	nil,
	"BOOMCRGRAY",
	"BOOMCRGREEN",
	nil,
	"BOOMCRGOLD",
	"BOOMCRRED",
	"BOOMCRBLUE"
}

---@param v videolib
local function drawBOOMString(v, x, y, str, cr)
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
				v.draw(x, y, patch, 0, crtocmap)
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

local function DoBOOMHud(v, player)
	local ammostr, healthstr, armorstr = "", "", ""

	HU_MoveHud()

	local funcs = P_GetMethodsForSkin(player)

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

		local ammo_red = doom.cvars.user_colorthresholds.ammo.red.value
		local ammo_yellow = doom.cvars.user_colorthresholds.ammo.yellow.value

		hud_ammostr = $ .. ammostr

		if ammopct < ammo_red then
			w_ammo.cr = CR_RED
		elseif ammopct < ammo_yellow then
			w_ammo.cr = CR_GOLD
		else
			w_ammo.cr = CR_GREEN
		end
	end
	drawBOOMString(v, w_ammo.x, w_ammo.y, hud_ammostr, w_ammo.cr)

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

		healthstr = string.format(health, "%3d")

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

		local health_red = doom.cvars.user_colorthresholds.health.red.value
		local health_yellow = doom.cvars.user_colorthresholds.health.yellow.value
		local health_green = doom.cvars.user_colorthresholds.health.green.value

		if healthpct < health_red then
			w_health.cr = CR_RED
		elseif healthpct < health_yellow then
			w_health.cr = CR_GOLD
		elseif healthpct < health_green then
			w_health.cr = CR_GREEN
		else
			w_health.cr = CR_BLUE
		end
	end
	drawBOOMString(v, w_health.x, w_health.y, hud_healthstr, w_health.cr)

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

		armorstr = string.format(armor, "%3d")

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

		local health_red = doom.cvars.user_colorthresholds.health.red.value
		local health_yellow = doom.cvars.user_colorthresholds.health.yellow.value
		local health_green = doom.cvars.user_colorthresholds.health.green.value

		if healthpct < health_red then
			w_armor.cr = CR_RED
		elseif healthpct < health_yellow then
			w_armor.cr = CR_GOLD
		elseif healthpct < health_green then
			w_armor.cr = CR_GREEN
		else
			w_armor.cr = CR_BLUE
		end
	end
	drawBOOMString(v, w_armor.x, w_armor.y, hud_armorstr, w_armor.cr)

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

		local ammo = funcs.getAmmoFor(player, trueweapon.ammotype) or 0
		local fullammo = funcs.getMaxFor(player, trueweapon.ammotype)
		local isInfinite = false
		if fullammo == false or fullammo == nil then
			isInfinite = true
		end
		local ammopct = not isInfinite and (100*ammo)/fullammo or 0

		local ammo_red = doom.cvars.user_colorthresholds.ammo.red.value
		local ammo_yellow = doom.cvars.user_colorthresholds.ammo.yellow.value

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

	drawBOOMString(v, w_weapon.x, w_weapon.y, hud_weapstr)

	local hudPref = doom.cvars.user_hudpref.value
	if hudPref % 2 then return end


	local deathmatch = {gametyperules & GTR_RINGSLINGER}
	local hud_graph_keys = true

	if not deathmatch and hud_graph_keys then
		for k = 0, 5 do
			local bit = 1 << k
			if not (player.doom.keys & bit) then continue end
			hud_gkeysstr = $ .. "!"..k.."  "
		end
	else
		if deathmatch then
			local top1, top2, top3, top4 = -999, -999, -999, -999
			local idx1, idx2, idx3, idx4 = -1, -1, -1, -1
			local fragcount, m
			local numbuf = ""
			for player in players.iterate() do
				if player.spectator then continue end

				fragcount = 0
				for otherplayer in players.iterate() do
					if otherplayer.spectator then continue end

					local fragdiffs
					local frags = player.doom.frags[#otherplayer] or 0
					if #player != #otherplayer then
						fragdiffs = frags
					else
						fragdiffs = -frags
					end
					fragcount = $ + fragdiffs
				end

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
		end
	end
/*
    if (doit && hud_active>1)
    {
      int k;

      hud_keysstr[4] = '\0';    //jff 3/7/98 make sure deleted keys go away
      //jff add case for graphic key display
      if (!deathmatch && hud_graph_keys)
      {
        i=0;
        hud_gkeysstr[i] = '\0'; //jff 3/7/98 init graphic keys widget string
        // build text string whose characters call out graphic keys from fontk
        for (k=0;k<6;k++)
        {
          // skip keys not possessed
          if (!plr->cards[k])
            continue;

          hud_gkeysstr[i++] = '!'+k;   // key number plus '!' is char for key
          hud_gkeysstr[i++] = ' ';     // spacing
          hud_gkeysstr[i++] = ' ';
        }
        hud_gkeysstr[i]='\0';
      }
      else // not possible in current code, unless deathmatching,
      {
        i=4;
        hud_keysstr[i] = '\0';  //jff 3/7/98 make sure deleted keys go away

        // if deathmatch, build string showing top four frag counts
        if (deathmatch) //jff 3/17/98 show frags, not keys, in deathmatch
        {
          int top1=-999,top2=-999,top3=-999,top4=-999;
          int idx1=-1,idx2=-1,idx3=-1,idx4=-1;
          int fragcount,m;
          char numbuf[32];

          // scan thru players
          for (k=0;k<MAXPLAYERS;k++)
          {
            // skip players not in game
            if (!playeringame[k])
              continue;

            fragcount = 0;
            // compute number of times they've fragged each player
            // minus number of times they've been fragged by them
            for (m=0;m<MAXPLAYERS;m++)
            {
              if (!playeringame[m]) continue;
              fragcount += (m!=k)?  players[k].frags[m] : -players[k].frags[m];
            }

            // very primitive sort of frags to find top four
            if (fragcount>top1)
            {
              top4=top3; top3=top2; top2 = top1; top1=fragcount;
              idx4=idx3; idx3=idx2; idx2 = idx1; idx1=k;
            }
            else if (fragcount>top2)
            {
              top4=top3; top3=top2; top2=fragcount;
              idx4=idx3; idx3=idx2; idx2=k;
            }
            else if (fragcount>top3)
            {
              top4=top3; top3=fragcount;
              idx4=idx3; idx3=k;
            }
            else if (fragcount>top4)
            {
              top4=fragcount;
              idx4=k;
            }
          }
          // if the biggest number exists, put it in the init string
          if (idx1>-1)
          {
            sprintf(numbuf,"%5d",top1);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx1&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          // if the second biggest number exists, put it in the init string
          if (idx2>-1)
          {
            sprintf(numbuf,"%5d",top2);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx2&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          // if the third biggest number exists, put it in the init string
          if (idx3>-1)
          {
            sprintf(numbuf,"%5d",top3);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx3&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          // if the fourth biggest number exists, put it in the init string
          if (idx4>-1)
          {
            sprintf(numbuf,"%5d",top4);
            // make frag count in player's color via escape code
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            hud_keysstr[i++] = '0'+plyrcoltran[idx4&3];
            s = numbuf;
            while (*s)
              hud_keysstr[i++] = *(s++);
          }
          hud_keysstr[i] = '\0';
        } //jff 3/17/98 end of deathmatch clause
        else // build alphabetical key display (not used currently)
        {
          // scan the keys
          for (k=0;k<6;k++)
          {
            // skip any not possessed by the displayed player's stats
            if (!plr->cards[k])
              continue;

            // use color escapes to make text in key's color
            hud_keysstr[i++] = '\x1b'; //jff 3/26/98 use ESC not '\' for paths
            switch(k)
            {
              case 0:
                hud_keysstr[i++] = '0'+CR_BLUE;
                hud_keysstr[i++] = 'B';
                hud_keysstr[i++] = 'C';
                hud_keysstr[i++] = ' ';
                break;
              case 1:
                hud_keysstr[i++] = '0'+CR_GOLD;
                hud_keysstr[i++] = 'Y';
                hud_keysstr[i++] = 'C';
                hud_keysstr[i++] = ' ';
                break;
              case 2:
                hud_keysstr[i++] = '0'+CR_RED;
                hud_keysstr[i++] = 'R';
                hud_keysstr[i++] = 'C';
                hud_keysstr[i++] = ' ';
                break;
              case 3:
                hud_keysstr[i++] = '0'+CR_BLUE;
                hud_keysstr[i++] = 'B';
                hud_keysstr[i++] = 'S';
                hud_keysstr[i++] = ' ';
                break;
            case 4:
                hud_keysstr[i++] = '0'+CR_GOLD;
                hud_keysstr[i++] = 'Y';
                hud_keysstr[i++] = 'S';
                hud_keysstr[i++] = ' ';
                break;
              case 5:
                hud_keysstr[i++] = '0'+CR_RED;
                hud_keysstr[i++] = 'R';
                hud_keysstr[i++] = 'S';
                hud_keysstr[i++] = ' ';
                break;
            }
            hud_keysstr[i]='\0';
          }
        }
      }
    }
    // display the keys/frags line each frame
    if (hud_active>1)
    {
      HUlib_clearTextLine(&w_keys);      // clear the widget strings
      HUlib_clearTextLine(&w_gkeys);

      // transfer the built string (frags or key title) to the widget
      s = hud_keysstr; //jff 3/7/98 display key titles/key text or frags
      while (*s)
        HUlib_addCharToTextLine(&w_keys, *(s++));
      HUlib_drawTextLine(&w_keys, false);

      //jff 3/17/98 show graphic keys in non-DM only
      if (!deathmatch) //jff 3/7/98 display graphic keys
      {
        // transfer the graphic key text to the widget
        s = hud_gkeysstr;
        while (*s)
          HUlib_addCharToTextLine(&w_gkeys, *(s++));
        // display the widget
        HUlib_drawTextLine(&w_gkeys, false);
      }
    }

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