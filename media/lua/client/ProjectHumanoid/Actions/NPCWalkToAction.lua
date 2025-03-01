require "TimedActions/ISBaseTimedAction"

NPCWalkToAction = ISBaseTimedAction:derive("NPCWalkToAction");

function NPCWalkToAction:isValid()
	if self.character:getVehicle() then return false end
    if self.location == nil then return false end
    return true;
end

function NPCWalkToAction:update()
    if not self:isValid() then return end

    if self.isRun then
        self.character:setRunning(true)
        self.character:setVariable("WalkSpeed", 10);    
    else
        self.character:setVariable("WalkSpeed", 1); 
    end

    if NPCUtils.hasAnotherNPCOnSquare(self.location, self.character:getModData()["NPC"]) then
        local sq = NPCUtils.AdjacentFreeTileFinder_Find(self.location)
        self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
        table.insert(self.pathQueue, self.location)
        self.location = sq
    end

    self.result = self.character:getPathFindBehavior2():update();

    if self.result == BehaviorResult.Failed then
        NPCPrint(false,"NPCWalkToAction", "Pathfind failed", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 

        if self.character:getZ() ~= 0 then
            self.character:getModData().NPC.lastWalkActionFailed = true
            self:forceStop();
            return
        end

        local nearestDoor = ScanSquaresSystem.getNearestDoor(self.character:getX(), self.character:getY(), self.character:getZ(), function(obj) return true end)
        local window = ScanSquaresSystem.getNearestWindow(self.character:getX(), self.character:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() end)
        if nearestDoor and (nearestDoor:isLocked() or nearestDoor:isLockedByKey() or nearestDoor:isBarricaded()) then
            if window then
                local sq = window:getSquare()
                if self.ifWindowFail == nil then
                    self.ifWindowFail = true
                else
                    sq = window:getOppositeSquare()
                end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ())

                if window:isPermaLocked() or window:isLocked() then
                    if window:isSmashed() then
                        if window:isGlassRemoved() then
                            local act1 = ISClimbThroughWindow:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                            ISTimedActionQueue.addAfter(act1, act2)
                        else
                            local act1 = ISRemoveBrokenGlass:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = ISClimbThroughWindow:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(act1, act2)
                            local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                            ISTimedActionQueue.addAfter(act2, act3)
                        end
                    else
                        local act0 = self
                        local melee = NPCUtils:getBestMeleWeapon(self.character:getInventory())
                        if self.character:getPrimaryHandItem() == nil and melee ~= nil then
                            if melee:getAttachedSlot() ~= -1 then
                                self.character:getModData()["NPC"].hotbar:removeItem(melee, true, true)
                            else
                                act0 = ISEquipWeaponAction:new(self.character, melee, 100, true, melee:isTwoHandWeapon())
                                ISTimedActionQueue.addAfter(self, act0)
                            end                            
                        end
                        local act1 = WaitAction:new(self.character, 40)
                        ISTimedActionQueue.addAfter(act0, act1)
                        local act2 = ISSmashWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = WaitAction:new(self.character, 40)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = ISRemoveBrokenGlass:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act3, act4)
                        local act5 = WaitAction:new(self.character, 40)
                        ISTimedActionQueue.addAfter(act4, act5)
                        local act6 = ISClimbThroughWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act5, act6)
                        local act7 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                        ISTimedActionQueue.addAfter(act6, act7)
                    end
                else
                    if window:IsOpen() then
                        local act2 = ISClimbThroughWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISOpenCloseWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = WaitAction:new(self.character, 160)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                end
            else
                self.character:getModData().NPC.lastWalkActionFailed = true
                self:forceStop();
                return;
            end
        else
            self.character:getModData().NPC.lastWalkActionFailed = true
            self:forceStop();
            return;
        end        
    end

    if self.result == BehaviorResult.Succeeded then
        if #self.pathQueue == 0 then
            NPCPrint(false,"NPCWalkToAction", "Pathfind succeeded", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
            self:forceComplete();
        else
            NPCPrint(false,"NPCWalkToAction", "Go to next by pathQueue", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
            self.character:getPathFindBehavior2():pathToLocation(self.pathQueue[1]:getX(), self.pathQueue[1]:getY(), self.pathQueue[1]:getZ());
            table.remove(self.pathQueue, 1)
        end
    end

    if math.abs(self.lastX - self.character:getX()) > 1 or math.abs(self.lastY - self.character:getY()) > 1 or math.abs(self.lastZ - self.character:getZ()) > 1 then
        self.lastX = self.character:getX();
        self.lastY = self.character:getY();
        self.lastZ = self.character:getZ();
        self.timer = 0
    end
    self.timer = self.timer + 1

    if self.timer == 30 and NPCUtils.hasAnotherNPCOnSquare(self.character:getSquare(), self.character:getModData()["NPC"]) then
        local sq = NPCUtils.AdjacentFreeTileFinder_Find(self.character:getSquare())
        self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
        table.insert(self.pathQueue, self.location)
    end

    if self.timer == 500 then
        NPCPrint(false,"NPCWalkToAction", "Stop by timer 500", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
        self.character:getModData().NPC.lastWalkActionFailed = true
        self:forceStop()
    end    

    -- Close doors
    if(self.character:getLastSquare() ~= nil ) then
        local cs = self.character:getCurrentSquare()
        local ls = self.character:getLastSquare()
        local tempdoor = ls:getDoorTo(cs);
        if(tempdoor ~= nil and tempdoor:IsOpen()) then
            tempdoor:ToggleDoor(self.character);
        end		
    end
end

function NPCWalkToAction:start()
    if not self:isValid() then return end
    NPCPrint(false,"NPCWalkToAction", "Calling pathfind method", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 

    if not self.location:isFree(false) then
        local sq = NPCUtils.AdjacentFreeTileFinderSameOutside_Find(self.location)
        if sq == nil then
            sq = NPCUtils.AdjacentFreeTileFinder_Find(self.location)
        end
        self.location = sq
    end

    if self.character:getSquare():isOutside() and not self.location:isOutside() and false then
        local doorUnlocked = ScanSquaresSystem.getNearestDoor(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and not obj:isLocked() and not obj:isLockedByKey() end)
        local doorLocked = ScanSquaresSystem.getNearestDoor(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and (obj:isLocked() or obj:isLockedByKey()) end)
        local windowUnlocked = ScanSquaresSystem.getNearestWindow(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and not obj:isLocked() and not obj:isPermaLocked() end) 
        local windowLocked = ScanSquaresSystem.getNearestWindow(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and (obj:isLocked() or obj:isPermaLocked()) end) 
        
        local door = doorUnlocked
        if door == nil then door = doorLocked end
        local window = windowUnlocked
        if window == nil then window = windowLocked end

        if door and not door:isLocked() and not door:isLockedByKey() then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, door:getSquare(), door:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                ISTimedActionQueue.addAfter(self, NPCWalkToAction:new(self.character, self.location, self.isRun, false))
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        elseif window then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, window:getSquare(), window:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                
                if window:isPermaLocked() or window:isLocked() then
                    if window:isSmashed() then
                        if window:isGlassRemoved() then
                            local act1 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act1, act2)
                        else
                            local act1 = ISRemoveBrokenGlass:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(act1, act2)
                            local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act2, act3)
                        end
                    else
                        local act1 = ISSmashWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = ISRemoveBrokenGlass:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                else
                    if window:IsOpen() then
                        local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(self, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISOpenCloseWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = WaitAction:new(self.character, 160)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                end
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        else
            self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
        end
    elseif not self.character:getSquare():isOutside() and self.location:isOutside() and false then

        local doorUnlocked = ScanSquaresSystem.getNearestDoor(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and not obj:isLocked() and not obj:isLockedByKey() end)
        local doorLocked = ScanSquaresSystem.getNearestDoor(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and (obj:isLocked() or obj:isLockedByKey()) end)
        local windowUnlocked = ScanSquaresSystem.getNearestWindow(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and not obj:isLocked() and not obj:isPermaLocked() end) 
        local windowLocked = ScanSquaresSystem.getNearestWindow(self.location:getX(), self.location:getY(), self.character:getZ(), function(obj) return not obj:isBarricaded() and (obj:isLocked() or obj:isPermaLocked()) end) 

        local door = doorUnlocked
        if door == nil then door = doorLocked end
        local window = windowUnlocked
        if window == nil then window = windowLocked end

        if door then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, door:getSquare(), door:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                ISTimedActionQueue.addAfter(self, NPCWalkToAction:new(self.character, self.location, self.isRun, false))
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        elseif window then
            if self.withOptimisation then
                local sq = self:getSameOutsideSquare(self.character, window:getSquare(), window:getOppositeSquare())
                if sq == nil then return false end
                self.character:getPathFindBehavior2():pathToLocation(sq:getX(), sq:getY(), sq:getZ());
                
                if window:isPermaLocked() then
                    if window:isSmashed() then
                        if window:isGlassRemoved() then
                            local act1 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act1, act2)
                        else
                            local act1 = ISRemoveBrokenGlass:new(self.character, window, 0)
                            ISTimedActionQueue.addAfter(self, act1)
                            local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                            ISTimedActionQueue.addAfter(act1, act2)
                            local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                            ISTimedActionQueue.addAfter(act2, act3)
                        end
                    else
                        local act1 = ISSmashWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = ISRemoveBrokenGlass:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                else
                    if window:IsOpen() then
                        local act2 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(self, act2)
                        local act3 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act2, act3)
                    else
                        local act1 = ISOpenCloseWindow:new(self.character, window, 0)
                        ISTimedActionQueue.addAfter(self, act1)
                        local act2 = WaitAction:new(self.character, 160)
                        ISTimedActionQueue.addAfter(act1, act2)
                        local act3 = ISClimbThroughWindow:new(self.character, window, 10)
                        ISTimedActionQueue.addAfter(act2, act3)
                        local act4 = NPCWalkToAction:new(self.character, self.location, self.isRun, false)
                        ISTimedActionQueue.addAfter(act3, act4)
                    end
                end
            else
                self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
            end
        else
            self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
        end
    else
        self.character:getPathFindBehavior2():pathToLocation(self.location:getX(), self.location:getY(), self.location:getZ());
    end
end

function NPCWalkToAction:stop()
    NPCPrint(false,"NPCWalkToAction", "Pathfind cancelled", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
    ISBaseTimedAction.stop(self);
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);
end

function NPCWalkToAction:perform()
    NPCPrint(false,"NPCWalkToAction", "Pathfind complete", self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
	self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);

    ISBaseTimedAction.perform(self);

    if self.onCompleteFunc then
        local args = self.onCompleteArgs
        self.onCompleteFunc(args[1], args[2], args[3], args[4])
    end
end

function NPCWalkToAction:setOnComplete(func, arg1, arg2, arg3, arg4)
    self.onCompleteFunc = func
    self.onCompleteArgs = { arg1, arg2, arg3, arg4 }
end


function NPCWalkToAction:new(character, location, isRun, withOptimisation)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;

    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.location = location;
    o.pathIndex = 0;

    o.isRun = isRun
    o.withOptimisation = withOptimisation
    if o.withOptimisation == nil then
        o.withOptimisation = true
    end

    o.lastX = character:getX();
    o.lastY = character:getY();
    o.lastZ = character:getZ();
    o.timer = 0

    o.pathQueue = {}

    return o
end

function NPCWalkToAction:getSameOutsideSquare(char, sq1, sq2)
    local charSq = char:getSquare()

    if charSq:isOutside() then
        if sq1:isOutside() then
            return sq1
        else
            return sq2
        end
    else
        if not sq1:isOutside() then
            return sq1
        else
            return sq2
        end
    end
end