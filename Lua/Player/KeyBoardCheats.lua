local function cheat(seq, cmd)
    -- split string into a table of chars
    local sequence = {}
    for i = 1, #seq do
        sequence[i] = seq:sub(i,i):lower()
    end

    return {
        sequence = sequence,
        progress = 0,
        command = cmd
    }
end

local cheats = {
    cheat("idkfa",  "idkfa"),
    cheat("idfa",   "idfa"),
    cheat("idclip", "idclip"),
}

addHook("KeyDown", function(keyevent)
    if not (consoleplayer and consoleplayer.valid) then return end
    if gamestate ~= GS_LEVEL or keyevent.repeated or keyevent.name == "TILDE" then
        return
    end

    local keyname = keyevent.name:lower()

    for _, cheat in ipairs(cheats) do
        -- Check next character in the sequence
        if keyname == cheat.sequence[cheat.progress + 1] then
            cheat.progress = cheat.progress + 1
        else
            cheat.progress = 0
        end

        -- Full sequence matched
        if cheat.progress >= #cheat.sequence then
            COM_BufInsertText(consoleplayer, cheat.command)
            cheat.progress = 0 -- reset after triggering
        end
    end
end)