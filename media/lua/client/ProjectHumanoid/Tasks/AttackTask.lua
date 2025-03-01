AttackTask = {}
AttackTask.__index = AttackTask

function AttackTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Attack"
	o.complete = false

    o.delayTimer = 0
    o.pressedAttackDelay = 0
    o.attackDone = true
    o.currentRunAction = nil

    if o.character:getModData().NPC.AI.isRobbed then
        character:getModData().NPC:Say("FUCK YOU. I AM NOT SURREND!", NPCColor.White)
        o.character:getModData().NPC.AI.isRobbed = false
        o.character:getModData().NPC.AI.robbedBy = nil
    else
        if ZombRand(0, 100) == 0 then
            NPCDialogueSystem.SayDialoguePhrase(o.character:getModData().NPC, "attackTalk", 1, NPCColor.White)  
        end
    end

    o.shoveDelay = 0

	return o
end


function AttackTask:isComplete()
	return self.complete
end

function AttackTask:isValid()
    if self.character == nil or self.character:getModData()["NPC"].nearestEnemy == nil or self.character:getModData()["NPC"].nearestEnemy:isDead() or self.character:getModData()["NPC"].nearestEnemy:getSquare() == nil then
        self.character:NPCSetAttack(false)
        self.character:NPCSetMelee(false)
        self.character:NPCSetAiming(false)
        self.character:setForceShove(false);
        self.character:setAimAtFloor(false)
        self.character:setVariable("bShoveAiming", false);
        return false
    end
    return true
end

function AttackTask:stop()
    self.character:NPCSetAttack(false)
    self.character:NPCSetMelee(false)
    self.character:NPCSetAiming(false)
    self.character:setForceShove(false);
    self.character:setAimAtFloor(false)
    self.character:setVariable("bShoveAiming", false);
end

function AttackTask:customPressedAttack()
    if self.pressedAttackDelay <= 0 then
        self.pressedAttackDelay = 50
        self.attackDone = false
    end
end

function AttackTask:update()
    if not self:isValid() then return false end
    
    if self.shoveDelay > 0 then
        self.shoveDelay = self.shoveDelay - 1
    end

    if self.pressedAttackDelay < 30 and not self.attackDone then
        self.character:pressedAttack(true)
        if self.character:getPrimaryHandItem() ~= nil then
            SwipeStatePlayer.instance():ConnectSwing(self.character, self.character:getPrimaryHandItem());
        else
            self.character:setAimAtFloor(false)
            self.character:setForceShove(true);
            self.character:setVariable("bShoveAiming", true);
            self.character:NPCSetAttack(true);
            self.character:NPCSetMelee(true);  
            self:customPressedAttack()
            self.shoveDelay = 30
        end
        self.attackDone = true
    end

    if self.pressedAttackDelay > 0 then
        self.pressedAttackDelay = self.pressedAttackDelay - 1
    end

    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    self.character:getModData()["NPC"]:doVision()
    self.character:faceThisObject(self.character:getModData()["NPC"].nearestEnemy)

    local dist = NPCUtils.getDistanceBetween(self.character, self.character:getModData()["NPC"].nearestEnemy)

    if self.character:getModData().NPC.nearestEnemy ~= nil and instanceof(self.character:getModData().NPC.nearestEnemy, "IsoPlayer") then
        IsoPlayer.setCoopPVP(true)   
        NPCManager.pvpTurnOffTimer = 120 
    end

    if self.character:getModData()["NPC"]:isUsingGun() and self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():isAimedFirearm() then
        if self.character:getVehicle() ~= nil then
            return false
        end
        
        if dist < 3 then
            if not ISTimedActionQueue.hasAction(self.currentWalkAction) then
                self.character:NPCSetAiming(false)
                local sq = NPCUtils.getSafestSquare(self.character, 2) 
                ISTimedActionQueue.clear(self.character)
                self.currentWalkAction = NPCWalkToAction:new(self.character, sq, true)
                ISTimedActionQueue.add(self.currentWalkAction)
            end
        else
            if actionCount == 0 then
                if self.character:getModData()["NPC"].nearestEnemy ~= nil and self.delayTimer <= 0 then
                    self.character:NPCSetAiming(true)
                    if ISReloadWeaponAction.canShoot(self.character:getPrimaryHandItem()) then
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(false);
                        self:customPressedAttack()
                        self.delayTimer = 50  
                    else
                        if not self.character:getModData()["NPC"]:readyGun(self.character:getPrimaryHandItem()) then
                            self:stop()
                            return false
                        end
                    end
                else
                    self.character:NPCSetAttack(false)
                    self.character:NPCSetMelee(false)
                end
            end
            if self.delayTimer > 0 then
                self.delayTimer = self.delayTimer - 1
            end
        end

        if self.character:getModData()["NPC"].nearestEnemy == nil or self.character:getModData()["NPC"].nearestEnemy:isDead() then
            self.complete = true
            self.character:setAimAtFloor(false)
            self.character:NPCSetAttack(false)
            self.character:NPCSetMelee(false)
            self.character:NPCSetAiming(false)
            self.character:setForceShove(false);
            self.character:setVariable("bShoveAiming", false);
        end
    else
        if self.character:getVehicle() ~= nil then
            return false
        end

        local minrange = self.character:getModData()["NPC"]:getMinWeaponRange()
        local maxrange = self.character:getModData()["NPC"]:getMaxWeaponRange()

        if dist >= maxrange then
            self.character:NPCSetAttack(false)
            self.character:NPCSetMelee(false)
    
            if actionCount == 0 then
                ISTimedActionQueue.add(NPCWalkToAction:new(self.character, self.character:getModData()["NPC"].nearestEnemy:getSquare(), false))
            end
        else
            ISTimedActionQueue.clear(self.character)
            if self.character:getModData()["NPC"].nearestEnemy then
                if self.character:getModData()["NPC"].nearestEnemy:isOnFloor() then
                    if self.character:getPrimaryHandItem() ~= nil then
                        self.character:setAimAtFloor(true)
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(true);
                        self:customPressedAttack()
                        --print("A")
                    else
                        self.character:setAimAtFloor(true)
                        self.character:NPCSetAttack(true);
                        self.character:NPCSetMelee(true);
                        self:customPressedAttack()
                        --print("B")
                    end
                else
                    if dist < minrange then
                        if self.shoveDelay <= 0 then
                            self.character:setAimAtFloor(false)
                            self.character:setForceShove(true);
                            self.character:setVariable("bShoveAiming", true);
                            self.character:NPCSetAttack(true);
                            self.character:NPCSetMelee(true);  
                            self:customPressedAttack()
                            self.shoveDelay = 30
                        end
                        --print("C")
                    else
                        if self.character:getPrimaryHandItem() ~= nil then
                            self.character:setAimAtFloor(false)
                            self.character:NPCSetAttack(true);
                            self.character:NPCSetMelee(true);
                            self:customPressedAttack()
                            --print("D")
                        else
                            self.character:setAimAtFloor(false)
                            self.character:setForceShove(true);
                            self.character:setVariable("bShoveAiming", true);
                            self.character:NPCSetAttack(true);
                            self.character:NPCSetMelee(false);  
                            --print("E")
                        end
                    end
                end
            end
        end
    
        if self.character:getModData()["NPC"].nearestEnemy == nil or self.character:getModData()["NPC"].nearestEnemy:isDead() then
            self.complete = true
            self.character:NPCSetAttack(false)
            self.character:NPCSetMelee(false)
            self.character:setForceShove(false)
            self.character:NPCSetAiming(false)
            self.character:setAimAtFloor(false)
            self.character:setVariable("bShoveAiming", false);
        end
    end
    return true
end