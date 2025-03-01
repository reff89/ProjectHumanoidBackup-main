---@class ReputationSystem
ReputationSystem = {}
ReputationSystem.__index = ReputationSystem

function ReputationSystem:new(character, defaultReputation)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.character = character

    o.reputationList = {}
    if defaultReputation ~= nil then
        o.playerRep = defaultReputation
        o.defaultReputation = defaultReputation
    else
        o.playerRep = 0
        o.defaultReputation = 0
    end
    
    return o
end

function ReputationSystem:getNPCRep(npc)
    local currentNPC = self.character:getModData().NPC

    -- If in group - get Reputation of leader
    if NPCGroupManager:getGroupID(currentNPC.ID) ~= nil then
        if NPCGroupManager:isLeader(currentNPC.ID) then
            if NPCGroupManager:getGroupID(npc.ID) == NPCGroupManager:getGroupID(currentNPC.ID) then
                return 1000
            else
                if self.reputationList[npc.ID] == nil then
                    return self.defaultReputation
                else
                    return self.reputationList[npc.ID]
                end
            end
        else
            local leader = NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(currentNPC.ID)))
            if leader == nil then
                if self.reputationList[npc.ID] == nil then
                    return self.defaultReputation
                else
                    return self.reputationList[npc.ID]
                end
            else
                return leader.reputationSystem:getNPCRep(npc)
            end
        end
    else
        if npc.AI:getType() == AI.Type.PlayerGroupAI and currentNPC.AI:getType() == AI.Type.PlayerGroupAI then
            return 1000
        end

        if self.reputationList[npc.ID] == nil then
            return self.defaultReputation
        else
            return self.reputationList[npc.ID]
        end
    end
end

function ReputationSystem:getPlayerRep()
    local currentNPC = self.character:getModData().NPC
    
    -- If in group - get Reputation of leader
    if NPCGroupManager:getGroupID(currentNPC.ID) ~= nil then
        if NPCGroupManager:isLeader(currentNPC.ID) then
            return self.playerRep
        else
            local leader =  NPCManager:getCharacter(NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(currentNPC.ID)))
            if leader == nil then
                return self.playerRep
            else
                return leader.reputationSystem:getPlayerRep()
            end
        end
    else
        if currentNPC.AI:getType() == AI.Type.PlayerGroupAI then
            return 1000
        else
            return self.playerRep
        end
    end
end

function ReputationSystem:updatePlayerRep(value)
    self.playerRep = self.playerRep + value
end

function ReputationSystem:updateNPCRep(value, npcID)
    if self.reputationList[npcID] == nil then
        self.reputationList[npcID] = self.defaultReputation
    end
    self.reputationList[npcID] = self.defaultReputation + value
end



