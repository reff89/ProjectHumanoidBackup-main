GoToInterestPointTask = {}
GoToInterestPointTask.__index = GoToInterestPointTask

function GoToInterestPointTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "GoToInterestPoint"
	o.complete = false

    o.goalX = o.character:getModData().NPC.AI.currentCluster:getX()
    o.goalY = o.character:getModData().NPC.AI.currentCluster:getY()

    if NPCGroupManager:isAtBase(o.goalX, o.goalY) then
        o.character:getModData().NPC.AI.visitedClusters[newCluster.ID] = true
        o.character:getModData().NPC.AI.currentCluster = ScanSquaresSystem.getNearestCluster(o.character:getX(), o.character:getY(), o.character:getModData().NPC.AI.visitedClusters, function(obj) return true end)
        o.goalX = o.character:getModData().NPC.AI.currentCluster:getX()
        o.goalY = o.character:getModData().NPC.AI.currentCluster:getY()
    end

    o.clusterID = o.character:getModData().NPC.AI.currentCluster.ID

	return o
end


function GoToInterestPointTask:isComplete()
	return self.complete
end

function GoToInterestPointTask:isValid()
    return self.character
end

function GoToInterestPointTask:stop()

end

function GoToInterestPointTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if self.mainPlayer:getVehicle() == nil and self.character:getVehicle() == nil then
        if actionCount == 0 then
            self.goalSquare = getCell():getGridSquare(self.goalX, self.goalY, 0)            

            if self.goalSquare == nil then
                local dToPlayer = NPCUtils.getDistanceBetweenXYZ(self.goalX, self.goalY, self.mainPlayer:getX(), self.mainPlayer:getY())
                local coeff = 70.0 / dToPlayer 

                local deltaX = self.goalX - self.character:getX()
                local deltaY = self.goalY - self.character:getY()

                self.goalX = deltaX * coeff + self.character:getX()
                self.goalY = deltaY * coeff + self.character:getY()
                self.goalSquare = getCell():getGridSquare(self.goalX, self.goalY, 0)            
            end

            if self.goalSquare == nil then
                return false
            end

            if not self.goalSquare:isFree(false) then
                self.goalSquare = NPCUtils.AdjacentFreeTileFinder_Find(self.goalSquare)
            end

		    ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.goalSquare, false))
        end

        if self.character:getSquare() == self.goalSquare then
            self.complete = true
            return true
        end
    end
    return true
end

function GoToInterestPointTask:isRun()
    return NPCUtils.getDistanceBetween(self.character:getSquare(), self.mainPlayer:getSquare()) > 5 or self.mainPlayer:getVehicle() ~= nil
end