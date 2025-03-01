TakeItemsFromPlayerTask = {}
TakeItemsFromPlayerTask.__index = TakeItemsFromPlayerTask

function TakeItemsFromPlayerTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "TakeItemsFromPlayer"
	o.complete = false

    o.items = character:getModData().NPC.AI.TaskArgs.inviteItems
    o.square = getPlayer():getSquare()

	return o
end


function TakeItemsFromPlayerTask:isComplete()
	return self.complete
end

function TakeItemsFromPlayerTask:stop()
end

function TakeItemsFromPlayerTask:isValid()
    return self.character
end

function TakeItemsFromPlayerTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        if NPCUtils.getDistanceBetween(self.square, self.character) > 1.5 then
            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, NPCUtils.AdjacentFreeTileFinder_Find(self.square), false))    
        end
        
        for _, item in ipairs(self.items) do
            if item ~= nil and item:getWorldItem() then
                ISTimedActionQueue.add(ISGrabItemAction:new(self.character, item:getWorldItem(), ISWorldObjectContextMenu.grabItemTime(self.character, item:getWorldItem())))
                self.character:getModData().NPC.reputationSystem:updatePlayerRep(100)
                self.character:getModData().NPC:SayNote("Reputation [img=media/ui/ArrowUp.png]", NPCColor.Green)
            end
        end
    end

    if #ISTimedActionQueue.getTimedActionQueue(self.character).queue == 0 then
        self.character:getModData().NPC.AI.command = nil
        self.complete = true
    end

    return true
end