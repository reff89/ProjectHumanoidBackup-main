CollectCorpsesTask = {}
CollectCorpsesTask.__index = CollectCorpsesTask

function CollectCorpsesTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "CollectCorpses"
	o.complete = false

    o.isClear = false

	return o
end


function CollectCorpsesTask:isComplete()
	return self.complete
end

function CollectCorpsesTask:stop()
end

function CollectCorpsesTask:isValid()
    return self.character and NPCGroupManager.collectCorpsesSector.x1 ~= nil
end

function CollectCorpsesTask:update()
    if not self:isValid() then 
        self.character:getModData().NPC.AI.command = nil
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        local inv = self.character:getInventory()
        local body = inv:getFirstTypeRecurse("Base.CorpseMale")
        if body == nil then
            body = inv:getFirstTypeRecurse("Base.CorpseFemale")
        end

        if body then
            if NPCUtils.getDistanceBetweenXYZ(self.character:getX(), self.character:getY(), NPCGroupManager.collectCorpsesSector.xx, NPCGroupManager.collectCorpsesSector.yy) < 1 and NPCGroupManager.collectCorpsesSector.zz == self.character:getZ() then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, body, body:getContainer(), ISInventoryPage.floorContainer[1]))    
            else
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, getCell():getGridSquare(NPCGroupManager.collectCorpsesSector.xx, NPCGroupManager.collectCorpsesSector.yy, NPCGroupManager.collectCorpsesSector.zz), false))
            end
        else
            local square = nil
            body, square = self:getNearestBody()
            if body == nil then
                self.isClear = true
            else
                if NPCUtils.getDistanceBetween(self.character, square) < 1 and square:getZ() == self.character:getZ() then
                    if self.character:getPrimaryHandItem() then
                        ISTimedActionQueue.add(ISUnequipAction:new(self.character, self.character:getPrimaryHandItem(), 50));
                    end
                    if self.character:getSecondaryHandItem() and self.character:getSecondaryHandItem() ~= self.character:getPrimaryHandItem() then
                        ISTimedActionQueue.add(ISUnequipAction:new(self.character, self.character:getSecondaryHandItem(), 50));
                    end
                    ISTimedActionQueue.add(ISGrabCorpseAction:new(self.character, body, 50));
                else
                    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, square, false))
                end
            end
        end
    end

    if self.character:getModData().NPC.AI.command ~= "COLLECT_CORPSES" or self.isClear then
        self.character:getModData().NPC.AI.command = nil
        self.complete = true
    end

    return true
end

function CollectCorpsesTask:getNearestBody()
    local cell = getCell()
    for x = NPCGroupManager.collectCorpsesSector.x1, NPCGroupManager.collectCorpsesSector.x2 do
        for y = NPCGroupManager.collectCorpsesSector.y1, NPCGroupManager.collectCorpsesSector.y2 do
            if x == NPCGroupManager.collectCorpsesSector.xx and y == NPCGroupManager.collectCorpsesSector.yy then
            else
                local sq = cell:getGridSquare(x, y, NPCGroupManager.collectCorpsesSector.z)
                if sq then
                    local items = sq:getDeadBodys()
                    for j=0, items:size()-1 do
                        local item = items:get(j)
                        if item then
                            return item, sq
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end