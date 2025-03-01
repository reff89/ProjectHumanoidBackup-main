
MeetSystem = {}
MeetSystem.Data = nil
MeetSystem.chanceToSay = 30
MeetSystem.longBreakTime = 60000


function MeetSystem:firstMeet(npc1, npc2)
    if npc1.reputationSystem.defaultReputation < 0 then
        NPCDialogueSystem.SayDialoguePhrase(npc1, "angryFirstMeet", MeetSystem.chanceToSay, NPCColor.White)
    else
        NPCDialogueSystem.SayDialoguePhrase(npc1, "friendFirstMeet", MeetSystem.chanceToSay, NPCColor.White)
    end
end

function MeetSystem:meetAfterLongBreak(npc1, npc2)
    if NPCGroupManager:getGroupID(npc1.ID) == NPCGroupManager:getGroupID(npc2.ID) then
        NPCDialogueSystem.SayDialoguePhrase(npc1, "meetAfterLongBreak", MeetSystem.chanceToSay, NPCColor.White)
    end
end

function MeetSystem:byebyeTalk(npc1, npc2)
    if npc1.reputationSystem.defaultReputation < 0 then
        NPCDialogueSystem.SayDialoguePhrase(npc1, "angryByeBye", MeetSystem.chanceToSay, NPCColor.White)
    else
        NPCDialogueSystem.SayDialoguePhrase(npc1, "friendByeBye", MeetSystem.chanceToSay, NPCColor.White)
    end
end

function MeetSystem:firstMeetPlayer(npc1, pl)
    if npc1.reputationSystem.playerRep < 0 then
        NPCDialogueSystem.SayDialoguePhrase(npc1, "angryFirstMeet", MeetSystem.chanceToSay, NPCColor.White)
    else
        NPCDialogueSystem.SayDialoguePhrase(npc1, "friendFirstMeet", MeetSystem.chanceToSay, NPCColor.White)
    end
end

function MeetSystem:meetAfterLongBreakPlayer(npc1, pl)
    if npc1.AI:getType() == AI.Type.PlayerGroupAI then
        NPCDialogueSystem.SayDialoguePhrase(npc1, "meetAfterLongBreak", MeetSystem.chanceToSay, NPCColor.White)
    end
end

function MeetSystem:byebyeTalkPlayer(npc1, pl)
    if ZombRand(0, MeetSystem.chanceToSay) == 0 then
        if npc1.reputationSystem.playerRep < 0 then
            NPCDialogueSystem.SayDialoguePhrase(npc1, "angryByeBye", MeetSystem.chanceToSay, NPCColor.White)
        else
            NPCDialogueSystem.SayDialoguePhrase(npc1, "friendByeBye", MeetSystem.chanceToSay, NPCColor.White)
        end
    end
end


local meetManagingTimer = 0
function MeetSystem:meetManaging()
    if meetManagingTimer <= 0 then
        meetManagingTimer = 60

        for i, char1 in ipairs(NPCManager.characters) do
            if ZombRand(0, 100) == 0 then
                if char1.reputationSystem.defaultReputation < 0 then
                    NPCDialogueSystem.SayDialoguePhrase(char1, "angryRandomTalk", 100, NPCColor.White)
                else
                    NPCDialogueSystem.SayDialoguePhrase(char1, "friendRandomTalk", 100, NPCColor.White)
                end
            end

            for j, char2 in ipairs(NPCManager.characters) do
                if char1 ~= char2 then
                    if MeetSystem.Data[char1.ID] == nil then
                        MeetSystem.Data[char1.ID] = {}
                    end
                    if MeetSystem.Data[char1.ID][char2.ID] == nil then
                        MeetSystem.Data[char1.ID][char2.ID] = {}
                    end
                    ---
                    if NPCUtils.getDistanceBetween(char1, char2) > 5 then
                        if MeetSystem.Data[char1.ID][char2.ID].divided == false then
                            MeetSystem:byebyeTalk(char1, char2)
                        end
                        MeetSystem.Data[char1.ID][char2.ID].divided = true
                    else
                        if MeetSystem.Data[char1.ID][char2.ID].divided then
                            MeetSystem.Data[char1.ID][char2.ID].divided = false

                            if MeetSystem.Data[char1.ID][char2.ID].time == nil then
                                MeetSystem:firstMeet(char1, char2)
                            else
                                if getTimeInMillis() - MeetSystem.Data[char1.ID][char2.ID].time  > MeetSystem.longBreakTime then
                                    MeetSystem:meetAfterLongBreak(char1, char2)
                                    MeetSystem.Data[char1.ID][char2.ID].time = getTimeInMillis()
                                end
                            end
                        end
                        MeetSystem.Data[char1.ID][char2.ID].time = getTimeInMillis()
                    end
                end
            end
        end

        for i, char in ipairs(NPCManager.characters) do
            if MeetSystem.Data[char.ID] == nil then
                MeetSystem.Data[char.ID] = {}
            end
            if MeetSystem.Data[char.ID]["PLAYER"] == nil then
                MeetSystem.Data[char.ID]["PLAYER"] = {}
            end
            --
            if NPCUtils.getDistanceBetween(getPlayer(), char) > 5 then
                if MeetSystem.Data[char.ID]["PLAYER"].divided == false then
                    MeetSystem:byebyeTalkPlayer(char, getPlayer())
                end

                MeetSystem.Data[char.ID]["PLAYER"].divided = true
            else
                if MeetSystem.Data[char.ID]["PLAYER"].divided then
                    MeetSystem.Data[char.ID]["PLAYER"].divided = false

                    if MeetSystem.Data[char.ID]["PLAYER"].time == nil then
                        MeetSystem:firstMeetPlayer(char, getPlayer())
                    else
                        if getTimeInMillis() - MeetSystem.Data[char.ID]["PLAYER"].time > MeetSystem.longBreakTime then
                            MeetSystem:meetAfterLongBreakPlayer(char, getPlayer())
                            MeetSystem.Data[char.ID]["PLAYER"].time = getTimeInMillis()
                        end
                    end
                end
                MeetSystem.Data[char.ID]["PLAYER"].time = getTimeInMillis()
            end
        end
        
    else
        meetManagingTimer = meetManagingTimer - 1
    end
end
Events.OnTick.Add(MeetSystem.meetManaging)

