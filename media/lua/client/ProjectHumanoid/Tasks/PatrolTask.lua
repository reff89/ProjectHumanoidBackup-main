PatrolTask = {}
PatrolTask.__index = PatrolTask

function PatrolTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Patrol"
	o.complete = false

    o.goFromStartToEnd = true
    o.currentPoint = 1
    o.pointsCount = #NPCGroupManager.patrolPoints[o.character:getModData().NPC.ID]

	return o
end


function PatrolTask:isComplete()
	return self.complete
end

function PatrolTask:stop()
end

function PatrolTask:isValid()
    return self.character and self.pointsCount > 0
end

function PatrolTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        if self.goFromStartToEnd then
            local point = NPCGroupManager.patrolPoints[self.character:getModData().NPC.ID][self.currentPoint]
            local square = getCell():getGridSquare(point.x, point.y, point.z)
            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, square, false))
            self.currentPoint = self.currentPoint + 1
            if self.currentPoint > self.pointsCount then
                self.currentPoint = self.currentPoint - 1
                self.goFromStartToEnd = false
            end
        else
            local point = NPCGroupManager.patrolPoints[self.character:getModData().NPC.ID][self.currentPoint]
            local square = getCell():getGridSquare(point.x, point.y, point.z)
            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, square, false))
            self.currentPoint = self.currentPoint - 1
            if self.currentPoint <= 0 then
                self.currentPoint = self.currentPoint + 1
                self.goFromStartToEnd = true
            end
        end
    end

    if self.character:getModData().NPC.AI.command ~= "PATROL" then
        self.complete = true
    end

    return true
end