local responsetable = {
	"MORE INFO. FOR 5",
	"BYE!"
}

local function drawDialogue(v, player, convo)
	if convo.backpic and v.patchExists(convo.backpic) then
		v.draw(0, 0, v.cachePatch(convo.backpic))
	end

	doom.drawInFont(v,
		16*FRACUNIT, 16*FRACUNIT,
		FRACUNIT,
		"STCFN",
		convo.speakerName,
		V_PERPLAYER,
		"left"
	)

	doom.drawInFont(v,
		24*FRACUNIT, 28*FRACUNIT,
		FRACUNIT,
		"STCFN",
		convo.dialogueText,
		V_PERPLAYER,
		"left",
		nil,
		nil,
		nil,
		272*FRACUNIT
	)

	-- number of selectable entries INCLUDING "Bye!"
	local choiceCount = #convo.choices + 1

	v.draw(22, 140 + ((convo.selection - choiceCount) * 8), v.cachePatch("M_CURS1"))

	for i = 1, choiceCount do
		local y = 148*FRACUNIT + ((i - choiceCount) * 8*FRACUNIT)

		-- draw index number
		doom.drawInFont(
			v,
			50*FRACUNIT,
			y,
			FRACUNIT,
			"STCFN",
			i .. ".",
			V_PERPLAYER,
			"right",
			nil,
			nil,
			nil,
			272*FRACUNIT
		)

		-- determine text
		local text
		if i <= #convo.choices then
			text = convo.choices[i].displayText
		else
			text = "BYE!"
		end

		-- draw option text
		doom.drawInFont(
			v,
			64*FRACUNIT,
			y,
			FRACUNIT,
			"STCFN",
			text,
			V_PERPLAYER,
			"left",
			nil,
			nil,
			nil,
			272*FRACUNIT
		)
	end
end

table.insert(doom.hud_postdraw, function(v, player)
	local convo = player.doom.conversation
	if convo and convo.active then
		drawDialogue(v, player, convo)
	end
end)