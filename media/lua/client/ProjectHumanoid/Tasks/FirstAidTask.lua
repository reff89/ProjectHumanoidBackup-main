FirstAidTask = {}
FirstAidTask.__index = FirstAidTask

function FirstAidTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "FirstAid"
	o.complete = false

	return o
end


function FirstAidTask:isComplete()
	return self.complete
end

function FirstAidTask:stop()

end

function FirstAidTask:isValid()
    return self.character
end

function FirstAidTask:update()
    if not self:isValid() then return false end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue
    local bodyparts = self.character:getBodyDamage():getBodyParts()

    local square = self.character:getSquare()
    if square ~= nil then
        local items = square:getObjects()
        for j=0, items:size()-1 do
            local item = items:get(j)
            if instanceof(item, "IsoBrokenGlass") then
                square:transmitRemoveItemFromSquare(item)
                square:RecalcProperties();
                square:RecalcAllWithNeighbours(true);
            end
        end	
    end

    if actionCount == 0 then
        if self.character:isOnFire() then
            self.character:StopBurning()
        end
        ISCampingMenu.campfire = CCampfireSystem.instance:getLuaObjectOnSquare(self.character:getSquare())
        if ISCampingMenu.campfire ~= nil or self.character:getSquare():haveFire() then
            ISTimedActionQueue.add(NPCWalkToAction:new(self.character, NPCUtils.AdjacentFreeTileFinder_Find(self.character:getSquare()), false))
            return true
        end
        
        for i=0, bodyparts:size()-1 do
            local bp = bodyparts:get(i)
            if(bp:HasInjury()) and (bp:bandaged() == false) then
                local item = self.character:getInventory():getItemFromType("RippedSheets")		
                if(item == nil) then item = self.character:getInventory():AddItem("Base.RippedSheets") end
                local TA = ISApplyBandage:new(self.character, self.character, item, bp, true)
                ISTimedActionQueue.add(TA)
                break
            end
        end
    end

    local hasInjury = false
    for i=0, bodyparts:size()-1 do
        local bp = bodyparts:get(i)
        if(bp:HasInjury()) and (bp:bandaged() == false) then
            hasInjury = true
            break
        end
    end
    
    self.complete = not hasInjury

    return true
end