doom.cssindex = doom.cssindex or {}

local function normalizeCSS(skinname, css)
	return {
		skin = skinname,
		name = css.name or skinname,
		nonselectedframe = css.nonselectedframe or A,
		nonselectedsprite2 = css.nonselectedsprite2 or css.nonselectedsprite or SPR2_STND,
		sprite2 = css.sprite2 or css.sprite or SPR2_WALK,
		sequence = css.sequence or {A, 8, 1},
		order = css.order or 9999,
		description = css.description or "Set a description here!",
		hidden = css.hidden or false,
	}
end

local function rebuildCSSIndex()
	doom.cssindex = {}

	for skinname, def in pairs(doom.charSupport) do
		if not skins[skinname] then continue end
		if def.css and not def.css.hidden then
			doom.cssindex[#doom.cssindex+1] = normalizeCSS(skinname, def.css)
		end
	end

	table.sort(doom.cssindex, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return a.name:lower() < b.name:lower()
	end)
end

local function BuildCSSMenu()
	local entries = {}

	if not #doom.cssindex then
		rebuildCSSIndex()
	end

	for _, css in ipairs(doom.cssindex) do
		entries[#entries+1] = {
			drawtype = "css",

			skin = css.skin or css.name,
			name = css.name,
			nonselectedframe = css.nonselectedframe,
			nonselectedsprite2 = css.nonselectedsprite,
			sprite2 = css.sprite2,
			sequence = css.sequence,
			description = css.description,

			-- Ensure skin is applied immediately
			command = "skin " .. css.skin,

			-- Route depending on IWAD structure
			goto = "__newgame_router",
		}
	end

	return entries
end

doom.normalizeCSS = normalizeCSS
doom.rebuildCSSIndex = rebuildCSSIndex
doom.buildCSSMenu = BuildCSSMenu