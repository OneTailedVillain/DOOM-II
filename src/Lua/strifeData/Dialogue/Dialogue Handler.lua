-- Helpers --------------------------------------------------------

local function resolveRandomText(text)
    if type(text) ~= "string" then return text end
    local category = text:match("^RANDOM_(.+)$")
    if not category then return text end

    local pool = doom.rndMessages and doom.rndMessages[category]
    if type(pool) == "table" and #pool > 0 then
        return pool[P_RandomRange(1, #pool)]
    end

    return "..."
end

-- hasItems: check up to 3 item slots (legacy format). Returns true if requirements satisfied.
local function hasItems(methods, player, items, amounts)
    if not items or #items == 0 then return true end

    for i = 1, 3 do
        local item = (items and items[i]) or 0
        local need = (amounts and amounts[i]) or 1
        if item > 0 and need > 0 then
            local checkId = (doom.conversationids and doom.conversationids[item]) or item
            if not checkId then
                -- cannot map item id, treat as failing (original code guarded against nil)
                return false
            end
            local cnt = methods.checkInventory and methods.checkInventory(player, checkId) or 0
            if not cnt or cnt < need then
                return false
            end
        end
    end

    return true
end

-- Find n-th dialog for a speaker in a script (returns node, index)
local function findDialog(script, speakerId, nth)
    if not script or not script.dialogs then return nil, 0 end
    nth = nth or 1
    local found = 0
    for i, node in ipairs(script.dialogs) do
        if node.speaker == speakerId then
            found = found + 1
            if found >= nth then
                return node, i
            end
        end
    end
    return nil, 0
end

local function endConversation(convo, player)
    if not convo then return end
    convo.active = false
    convo.nodeIndex = nil
    convo.currentNode = nil
    convo.choices = nil
    convo.dialogueText = nil
    convo.selection = 1
    if convo.speakerMobj and convo.speakerMobjOldAngle then
        convo.speakerMobj.angle = convo.speakerMobjOldAngle
    end
end

local function continueConversation(convo, newNode, newIndex, scriptObj, player, methods)
    convo.currentNode = newNode
    convo.nodeIndex = newIndex
    convo.currentScript = scriptObj
    convo.voice = newNode.voice
    convo.backpic = newNode.backpic
    convo.originalDialogueKey = newNode.text
    convo.dialogueText = resolveRandomText(newNode.text)
    convo.speakerName = newNode.name or convo.speakerName
    convo.selection = 1

    if newNode.dropitem and newNode.dropitem > 0 then
        convo.speakerDropItem = newNode.dropitem
    else
        convo.speakerDropItem = nil
    end

    if convo.voice and doom.voices[convo.voice] then
        S_StopSound(convo.speakerMobj)
        S_StartSound(convo.speakerMobj, doom.voices[convo.voice])
    end

    -- rebuild choices
    local avail = {}
    for i, ch in ipairs(newNode.choices or {}) do
        if ch.text and ch.text ~= "" then
            table.insert(avail, {
                index = i,
                displayText = resolveRandomText(ch.text),
                data = ch
            })
        end
    end
    convo.choices = avail
end

-- Dialog lookup following Chocolate Doom logic: level-specific, then SCRIPT00, then fallback to first SCRIPT00
local function P_DialogFind(speakerId, jumptoconv)
    jumptoconv = jumptoconv or 1
    local scriptnum = string.format("%02d", gamemap)
    local scriptname = "SCRIPT" .. scriptnum
    local curMapScript = doom.scripts[scriptname]

    local node, index = findDialog(curMapScript, speakerId, jumptoconv)
    if node then return node, index, doom.levelDialogs end

    local script00 = doom.scripts["SCRIPT00"]
    node, index = findDialog(script00, speakerId, jumptoconv)
    if node then return node, index, script00 end

    if script00 and script00.dialogs and #script00.dialogs > 0 then
        return script00.dialogs[1], 1, script00
    end

    return nil, 0, nil
end

-- AcceptChoice --------------------------------------------------

local function AcceptChoice(player, choiceId)
    if not player or not player.doom or not player.doom.conversation then
        print("AcceptChoice: no active conversation for player")
        return false
    end

    local convo = player.doom.conversation
    if not convo.active then
        print("AcceptChoice: conversation not active")
        return false
    end

    local methods = P_GetMethodsForSkin(player)
    if not methods then
        print("AcceptChoice: no methods for player skin")
        return false
    end

    -- find selected choice entry
    local selected, selListIndex
    for i, c in ipairs(convo.choices or {}) do
        if i == choiceId or (c.index and c.index == choiceId) then
            selected = c.data or c
            selListIndex = i
            break
        end
    end

    -- "end conversation" special case (choice = last entry + 1)
    if not selected then
        if choiceId == (#convo.choices + 1) then
            endConversation(convo, player)
            return false
        end
        print("AcceptChoice: choice not found (id = " .. tostring(choiceId) .. ")")
        return false
    end

    local function showTopMessage(msg)
        if not msg or msg == "" then return end
        if msg == "_" then return end
        if msg == "." then
            DOOM_DoMessage(player, "")
            return
        end
        DOOM_DoMessage(player, msg)
    end

    -- requirements check
    if not hasItems(methods, player, selected.needitem, selected.needamount) then
        if selected.no and selected.no ~= "" and selected.no ~= "_" then
            showTopMessage(selected.no)
        end
		endConversation(convo, player)
        return false
    end

    -- remove required items (best-effort)
    local function removeInventory(itemid, amount)
        if not itemid or itemid <= 0 or amount <= 0 then return true end
        local mapped = (doom.conversationids and doom.conversationids[itemid]) or itemid
        if methods.takeInventory then
            return methods.takeInventory(player, mapped, amount)
        elseif methods.removeInventory then
            return methods.removeInventory(player, mapped, amount)
        elseif methods.giveInventory then
            -- fallback: try giving negative if allowed
            local ok, err = pcall(function() methods.giveInventory(player, mapped, -amount) end)
            return ok
        else
            print("Warning: cannot remove inventory item " .. tostring(mapped) .. " (no method found)")
            return false
        end
    end

    for i = 1, 3 do
        local need = (selected.needitem and selected.needitem[i]) or -1
        local amt = (selected.needamount and selected.needamount[i]) or 1
        if need and need > 0 and amt and amt > 0 then
            local removed = removeInventory(need, amt)
            if not removed then
                print("AcceptChoice: failed to remove item " .. tostring(need) .. " x" .. tostring(amt))
            end
        end
    end

    -- give item (best-effort)
    if selected.giveitem and selected.giveitem > 0 then
        local giveid = selected.giveitem
        local canHold = true
        if methods.canHoldInventory then
            canHold = methods.canHoldInventory(player, (doom.conversationids and doom.conversationids[giveid]) or giveid)
        end

        if not canHold then
            showTopMessage("You seem to have enough!")
        else
            if methods.giveInventory then
                local ok = methods.giveInventory(player, (doom.conversationids and doom.conversationids[giveid]) or giveid, 1)
                if not ok then print("AcceptChoice: methods.giveInventory returned false for item " .. tostring(giveid)) end
            elseif P_GiveInventory then
                local ok, err = pcall(function() P_GiveInventory(player, giveid, 1) end)
                if not ok then print("AcceptChoice: P_GiveInventory failed: " .. tostring(err)) end
            else
                print("AcceptChoice: cannot give item " .. tostring(giveid) .. " (no method found)")
            end
        end
    end

    -- log
    if selected.log and selected.log > 0 then
        if methods.recordLog then
            methods.recordLog(player, selected.log)
        else
            print("Log entry requested: LOG" .. tostring(selected.log) .. " (no recordLog method found)")
        end
    end

    -- success message
    if selected.yes and selected.yes ~= "" and selected.yes ~= "_" then
        showTopMessage(selected.yes)
    end

    -- handle link
    local nextLink = tonumber(selected.link) or 0
    if convo.speakerMobj and convo.speakerMobj.valid and nextLink ~= 0 then
        convo.speakerMobj.dialogstate = abs(nextLink)
    end

    if nextLink < 0 then
        -- continue conversation immediately (do not end)
        local speakerId = convo.speakerId or (convo.currentNode and convo.currentNode.speaker)
        if not speakerId then
            print("AcceptChoice: no speaker ID available")
            return false
        end

        local scriptnum = string.format("%02d", gamemap)
        local scriptname = "SCRIPT" .. scriptnum
        local curMapScript = doom.scripts[scriptname]
        local scriptObj = curMapScript or doom.scripts["SCRIPT00"]
        if not scriptObj then
            print("AcceptChoice: no script found")
            return false
        end

        local newNode, newIndex = findDialog(scriptObj, speakerId, abs(nextLink))
        if not newNode then
            print("AcceptChoice: target dialog not found for speaker " .. tostring(speakerId) .. " link=" .. tostring(abs(nextLink)))
            return false
        end

        continueConversation(convo, newNode, newIndex, scriptObj, player, methods)
        return false

    else
        -- positive link or zero: end conversation
        endConversation(convo, player)
        return false
    end
end

addHook("PlayerThink", function(player)
    if (player.mo.flags & MF_NOTHINK) then return end
    local convo = player.doom.conversation
    if not convo then return end
    if not convo.active then return end
    player.powers[pw_nocontrol] = INT32_MAX
    if not convo.speakerMobj then error("Conversation being held with nonexistent object!") return end
    local playerPointAngle = R_PointToAngle2(player.mo.x, player.mo.y, convo.speakerMobj.x, convo.speakerMobj.y)
    player.drawangle = playerPointAngle
    player.mo.angle = playerPointAngle
    convo.speakerMobj.angle = player.drawangle - ANGLE_180

    local dz = convo.speakerMobj.z - player.mo.z
    local dist = R_PointToDist2(player.mo.x, player.mo.y, convo.speakerMobj.x, convo.speakerMobj.y)
    player.aiming = R_PointToAngle2(0, 0, dist, dz)
end)

addHook("PreThinkFrame", function()
    for player in players.iterate do
        if (player.mo.flags & MF_NOTHINK) then continue end

        local convo = player.doom.conversation
        if not convo then
            convo = {}
            player.doom.conversation = convo
        end
        convo.inputcooldown = max(($ or 0) - 1, 0)

        if not convo.active then continue end

        convo.prevbuttons = convo.prevbuttons or 0
        convo.prevforward = convo.prevforward or 0
        convo.selection = convo.selection or 1

        local buttons = player.cmd.buttons
        local forward = player.cmd.forwardmove

        if (buttons & BT_JUMP)
        and not (convo.prevbuttons & BT_JUMP)
        and convo.inputcooldown == 0 then
            AcceptChoice(player, convo.selection)
            convo.inputcooldown = TICRATE/6
        end

        local DEADZONE = 30
        local wasNeutral = (convo.prevforward > -DEADZONE and convo.prevforward < DEADZONE)
        local isForward = forward >= DEADZONE
        local isBackward = forward <= -DEADZONE

        if convo.inputcooldown == 0 and wasNeutral then
            if isForward then
                convo.selection = max(convo.selection - 1, 1)
                convo.inputcooldown = TICRATE/8
            elseif isBackward then
                convo.selection = min(convo.selection + 1, #convo.choices + 1)
                convo.inputcooldown = TICRATE/8
            end
        end

        convo.prevbuttons = buttons
        convo.prevforward = forward

        player.cmd.forwardmove = 0
        player.cmd.sidemove = 0
        player.cmd.buttons = 0
    end
end)

local function TryInteract(tmthing, thing)
    if tmthing.hitenemy then return false end
    if tmthing.target == thing then return false end
    if not (thing.z + thing.height >= tmthing.z and thing.z <= tmthing.z + tmthing.height) then
        return false
    end

    local convid = thing.info.conversationid
    local speakerId = (type(convid) == "table" and convid[1]) or convid or 0
    if speakerId <= 0 then return false end

    local scriptnum = string.format("%02d", gamemap)
    local scriptname = "SCRIPT" .. scriptnum
    local script = doom.scripts[scriptname]

    local jumptoconv = thing.dialogstate or 1
    local dialogueNode, nodeIndex = findDialog(script, speakerId, jumptoconv)

    local usedScript00 = false
    if not dialogueNode then
        scriptname = "SCRIPT00"
        script = doom.scripts[scriptname]
        if not script then
            print("No script found for speaker ID " .. speakerId)
            return false
        end
        dialogueNode, nodeIndex = findDialog(script, speakerId, jumptoconv)
        usedScript00 = true
    end

    if not dialogueNode then
        print("No dialogue node for speaker ID " .. speakerId)
        return false
    end

    local player = tmthing.target.player
    local methods = P_GetMethodsForSkin(player)
    if not methods then return false end

    local convo = player.doom.conversation or {}
    if convo.inputcooldown then return false end

    -- Optional jump-link pre-check
    if dialogueNode.link and dialogueNode.link > 0 and dialogueNode.checkitem
        and hasItems(methods, player, dialogueNode.checkitem) then

        local jumpNode, jumpIndex, jumpScript = P_DialogFind(dialogueNode.speaker, dialogueNode.link)
        if not jumpNode then
            print("Jump link invalid: " .. tostring(dialogueNode.link))
            return false
        end
        dialogueNode = jumpNode
        nodeIndex = jumpIndex
        scriptname = (jumpScript and (jumpScript.name or "SCRIPT??")) or scriptname
        -- (nodeIndex already is the index in the script returned by P_DialogFind)
    end

    local speakerName = dialogueNode.name
    if not speakerName or speakerName == "" then
        speakerName = thing.tagname or "Person"
    end

    local displayText = resolveRandomText(dialogueNode.text)

    local availableChoices = {}
    for i, choice in ipairs(dialogueNode.choices or {}) do
        if choice.text and choice.text ~= "" then
            table.insert(availableChoices, {
                index = i,
                displayText = resolveRandomText(choice.text),
                data = choice
            })
        end
    end

    player.doom.conversation = convo

    convo.active = true
    convo.script = scriptname
    convo.nodeIndex = nodeIndex
    convo.speaker = speakerId
    convo.speakerName = speakerName
    convo.speakerMobj = thing
    convo.speakerMobjOldAngle = thing.angle
    convo.dialogueText = displayText
    convo.originalDialogueKey = dialogueNode.text
    convo.choices = availableChoices
    convo.voice = dialogueNode.voice
    convo.backpic = dialogueNode.backpic
    convo.currentNode = dialogueNode
    convo.currentScript = script
    convo.usedScript00 = usedScript00
    convo.inputcooldown = TICRATE/6
    convo.selection = 1

print("[" + convo.voice + "]")
print("len:", #convo.voice)
    if convo.voice and doom.voices[convo.voice] then
        S_StopSound(convo.speakerMobj)
        S_StartSound(convo.speakerMobj, doom.voices[convo.voice])
    end

    if dialogueNode.dropitem and dialogueNode.dropitem > 0 then
        convo.speakerDropItem = dialogueNode.dropitem
    end

    convo.choiceTimer = nil
    tmthing.hitenemy = true

    return false
end

doom.Strife_TryNPCInteract = TryInteract