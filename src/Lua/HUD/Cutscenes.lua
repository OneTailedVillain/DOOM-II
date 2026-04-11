local laststage
local finalecount = 0

local SCREENWIDTH = 320
local SCREENHEIGHT = 200

---@param v videolib
local function F_BunnyScroll(v, player)
	local scrolled
	local x
	local p1
	local p2
	local name
	local stage

	p1 = v.cachePatch("PFUB2")
	p2 = v.cachePatch("PFUB1")

	scrolled = 320 - (finalecount-230)/2
	if scrolled > 320 then
		scrolled = 320
	end
	if scrolled < 0 then
		scrolled = 0
	end

	local scroll = scrolled

	v.drawFill(nil, nil, nil, nil, 31)

	v.draw(-scroll, 0, p1)
	v.draw(-scroll + 320, 0, p2)

	if finalecount < 1130 then return end
	if finalecount < 1180 then
		v.draw((SCREENWIDTH-13*8)/2, (SCREENHEIGHT-8*8)/2, v.cachePatch("END0"))
		laststage = 0
		return
	end

	stage = (finalecount-1180) / 5
	if stage > 6 then
		stage = 6
	end
	if stage > laststage then
		S_StartSound(nil, sfx_pistol, player)
		laststage = stage
	end

	v.draw((SCREENWIDTH-13*8)/2, (SCREENHEIGHT-8*8)/2, v.cachePatch("END"..stage))
end

doom.cutscenes = {
	sweetlittledeadbunny = {
		music = "BUNNY",
		draw = F_BunnyScroll
	},
}

doom._curcutscene = doom._curcutscene or nil

setmetatable(doom, {
    __index = function(t, k)
        if k == "curcutscene" then
            return rawget(t, "_curcutscene")
        else
            return rawget(t, k)
        end
    end,
    __newindex = function(t, k, v)
        if k == "curcutscene" then
            local old = rawget(t, "_curcutscene")
            if old ~= v then
                rawset(t, "_curcutscene", v)
                finalecount = 0

                local cs = doom.cutscenes[v]
                if cs and cs.music then
                    S_ChangeMusic(cs.music)
                end
            end
        else
            rawset(t, k, v)
        end
    end
})

hud.add(function(v, player)
	local cs = doom.curcutscene and doom.cutscenes[doom.curcutscene]
	if cs and cs.draw then
		cs.draw(v, player)
	end
end)

addHook("ThinkFrame", function()
	if doom.curcutscene then
		finalecount = $ + 1
	end
end)

COM_AddCommand("doom_dobunny", function(player, finale)
	doom.curcutscene = "sweetlittledeadbunny"
end)