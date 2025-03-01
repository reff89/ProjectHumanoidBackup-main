RobbingTask = {}
RobbingTask.__index = RobbingTask

function RobbingTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Robbing"
	o.complete = false

    o.robbedCharacter = o.character:getModData().NPC.AI.TaskArgs.robbedPerson

    o.character:getModData().NPC:Say("Stop right there!", NPCColor.White)

    local robbedNPC = o.robbedCharacter:getModData().NPC
    if robbedNPC ~= nil then
        local groupID = NPCGroupManager:getGroupID(robbedNPC.ID)
        if groupID ~= nil then
            for _, id in ipairs(NPCGroupManager.Data.groups[groupID].npcIDs) do
                local teammate = NPCManager:getCharacter(id)    
                if teammate ~= nil then
                    teammate.reputationSystem:updateNPCRep(-1000)
                    teammate.AI.nearestEnemy = o.character
                end
            end
        else
            robbedNPC.reputationSystem:updateNPCRep(-1000)
            robbedNPC.AI.nearestEnemy = o.character
        end

        robbedNPC.AI.isRobbed = true
        robbedNPC.AI.robbedBy = o.character
        o.timer = 0
        RobbingTask.isPlayerSurrend = false
    else
        o.playerX = o.robbedCharacter:getX()
        o.playerY = o.robbedCharacter:getY()

        o.timer = 600
        o.character:getModData().NPC.reputationSystem.playerRep = 0
    end

    o.saidDropLoot = false

	return o
end


function RobbingTask:isComplete()
	return self.complete
end

function RobbingTask:stop()
end

function RobbingTask:isValid()
    return self.character and not self.character:isDead() and not self.robbedCharacter:isDead()
end

function RobbingTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        self.character:facePosition(self.robbedCharacter:getX(), self.robbedCharacter:getY())

        if self.robbedCharacter == getPlayer() and self.startLoot == nil then
            if self.startLoot == nil and (self.timer <= 0 and self.saidDropLoot == false or getPlayer():getActionStateName() == "aim" or NPCUtils.getDistanceBetweenXYZ(self.playerX, self.playerY, getPlayer():getX(), getPlayer():getY()) > 1) then
                self.character:getModData().NPC:Say("Not going to give me your stuff? Then die!", NPCColor.Red)
                self.character:getModData().NPC.reputationSystem.playerRep = -1000
                self.character:getModData().NPC.AI.command = nil
                self.character:getModData().NPC.AI.TaskArgs.robbedPerson = nil
                self.complete = true
                return
            end
            if self.saidDropLoot == false and RobbingTask.isPlayerSurrend then
                self.character:getModData().NPC:Say("Drop Items on floor!", NPCColor.White)
                self.saidDropLoot = true
                
                self.playerX = self.robbedCharacter:getX()
                self.playerY = self.robbedCharacter:getY()
            end
            if self.saidDropLoot and getPlayer():getInventory():getItems():size() == 0 then
                self.character:getModData().NPC:Say("Now get out of here!", NPCColor.White)
    
                self.startLoot = true
                self.square = self.robbedCharacter:getSquare()
            end
            if self.startLoot then
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.square, false))
                local items = self:getItemsOnFloorNearSquare(self.square)
                for _, item in ipairs(items) do
                    if item ~= nil and item:getWorldItem() then
                        ISTimedActionQueue.add(ISGrabItemAction:new(self.character, item:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, item:getWorldItem())))
                    end
                end

                NPCGroupManager:ignorePlayer(self.character:getModData().NPC.ID)
                self.character:getModData().NPC.nearestEnemy = nil
            end
            if self.timer > 0 then
                self.timer = self.timer - 1
            end
        elseif self.startLoot == nil then
            if self.saidDropLoot == false then
                self.character:getModData().NPC:Say("Drop Items on floor!", NPCColor.White)
                self.saidDropLoot = true
    
                ISTimedActionQueue.clear(self.robbedCharacter)
                self.robbedCharacter:getModData().NPC.AI.robDropLoot = true
                
                self.npcX = self.robbedCharacter:getX()
                self.npcY = self.robbedCharacter:getY()

                self.timer = 240
                self.character:getModData().NPC.reputationSystem.reputationList[self.robbedCharacter:getModData().NPC.ID] = 0
            end

            if self.saidDropLoot and NPCUtils.getDistanceBetweenXYZ(self.npcX, self.npcY, self.robbedCharacter:getX(), self.robbedCharacter:getY()) > 1 then
                self.character:getModData().NPC:Say("Not going to give me your stuff? Then die!", NPCColor.Red)
                self.character:getModData().NPC.reputationSystem.reputationList[self.robbedCharacter:getModData().NPC.ID] = -1000
                self.character:getModData().NPC.AI.nearestEnemy = self.robbedCharacter
                self.character:getModData().NPC.AI.command = nil
                self.character:getModData().NPC.AI.TaskArgs.robbedPerson = nil

                self.complete = true
                return
            end

            if self.saidDropLoot and self.timer <= 0 then
                if self.robbedCharacter:getInventory():getItems():size() == 0 then
                    self.character:getModData().NPC:Say("Now flee!", NPCColor.White)
        
                    ISTimedActionQueue.clear(self.robbedCharacter:getModData().NPC.character)
                    self.robbedCharacter:getModData().NPC.AI.robFlee = true
        
                    self.startLoot = true
                    self.square = self.robbedCharacter:getSquare()
                else
                    self.character:getModData().NPC:Say("Not going to give me your stuff? Then die!", NPCColor.Red)
                    self.character:getModData().NPC.reputationSystem.reputationList[self.robbedCharacter:getModData().NPC.ID] = -1000
                    self.character:getModData().NPC.AI.nearestEnemy = self.robbedCharacter
                    self.character:getModData().NPC.AI.command = nil
                    self.character:getModData().NPC.AI.TaskArgs.robbedPerson = nil
                    self.complete = true
                    return
                end
            end
            if self.startLoot then
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.square, false))
                local items = self:getItemsOnFloorNearSquare(self.square)
                for _, item in ipairs(items) do
                    if item ~= nil and item:getWorldItem() then
                        ISTimedActionQueue.add(ISGrabItemAction:new(self.character, item:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, item:getWorldItem())))
                    end
                end
                NPCGroupManager:ignoreNPC(self.character:getModData().NPC.ID, self.robbedCharacter:getModData().NPC.ID)
                self.character:getModData().NPC.nearestEnemy = nil
            end
            if self.timer > 0 then
                self.timer = self.timer - 1
            end
        end        
    end

    if #ISTimedActionQueue.getTimedActionQueue(self.character).queue == 0 and self.startLoot then
        self.character:getModData().NPC.AI.command = nil
        self.character:getModData().NPC.AI.TaskArgs.robbedPerson = nil
        self.complete = true
    end

    return true
end


function RobbingTask:getItemsOnFloorNearSquare(square)
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    
    local resultItems = {}
    for i=-1, 1 do
        for j=-1, 1 do
            local sq = getCell():getGridSquare(x+i, y+j, z)        
            local items = NPCUtils:getItemsOnFloor(function(item)
                return true
            end, sq)

            for _, item in ipairs(items) do
                table.insert(resultItems, item)
            end
        end
    end

    return resultItems
end

-- Hook
local defaultISEmoteRadialMenu_emote = ISEmoteRadialMenu.emote
function ISEmoteRadialMenu:emote(emote)
    defaultISEmoteRadialMenu_emote(self, emote)
	if emote == "surrender" then
        RobbingTask.isPlayerSurrend = true
    end
end