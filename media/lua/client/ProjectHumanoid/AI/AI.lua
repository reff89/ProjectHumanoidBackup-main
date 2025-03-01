AI = {}
AI.__index = AI

AI.Type = {}
AI.Type.AI = "AI"
AI.Type.AutonomousAI = "AutonomousAI"
AI.Type.PlayerGroupAI = "PlayerGroupAI"

function AI:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.mainPlayer = getPlayer()
    o.character = character
    o.TaskManager = TaskManager:new(character)

    o.TaskArgs = {}
    o.command = nil
    o.idleCommand = nil

    -- Attributes
    o.isAtBase = false

    o.staySquare = nil

    o.agressiveAttack = true

    o.rareUpdateTimer = 0
    o.EatTaskTimer = 0
    o.DrinkTaskTimer = 0
    
    o.isUsingGunParam = true

	o.findItems = {}
	o.findItems.Food = false
	o.findItems.Weapon = false
	o.findItems.Clothing = false
	o.findItems.Meds = false
	o.findItems.Bags = false
	o.findItems.Melee = false
	o.findItems.Literature = false

	o.fleeFindOutsideSqTimer = 0
	o.fleeFindOutsideSq = nil

    o.chillTime = 0
    o.visitedClusters = {}
    o.currentCluster = nil
    o.isCheckCluster = false

    o.updateItemLocationTimer = 0

    o.isAtBase = false

    o.isRobbed = false
    o.robbedBy = nil
    o.robDropLoot = false
    o.robFlee = false

    return o
end

function AI:derive(type)
    local o = {}
    setmetatable(o, self)
    self.__index = self
	o.Type = type;
    return o
end


-- Check command functions --

function AI:isCommandFollow()
    return self.command == "FOLLOW"
end

function AI:isCommandStayHere()
    return self.command == "STAY"
end

function AI:isCommandPatrol()
    return self.command == "PATROL"
end

function AI:isCommandFindItems()
    return self.command == "FIND_ITEMS"
end

function AI:isCommandWash()
    return self.command == "WASH"
end

function AI:isCommandAttach()
    return self.command == "ATTACH"
end

function AI:isFlee()
	return self.TaskManager:getCurrentTaskName() == "Flee"
end

function AI:UpdateInputParams()
    local p = {}
    
    p.isRobbed = 0
    if self.isRobbed then
        p.isRobbed = 1
    end

    p.raiderGoodWeapon = 0
    if self.robbedBy ~= nil then
        p.raiderGoodWeapon = NPCUtils:isGoodWeapon(self.robbedBy)
    end
    
    p.isGoodStuff = 0   -- TODO

    p.needToHeal = NPCUtils:needToHeal(self.character)
    p.isGoodWeapon = NPCUtils:isGoodWeapon(self.character)

    p.isAgressiveMode = 0
    if self.agressiveAttack then
        p.isAgressiveMode = 1    
    end

    p.isNearEnemy = 0
    if self.character:getModData().NPC.nearestEnemy ~= nil or self.character:getModData().NPC.isEnemyAtBack then
        p.isNearEnemy = 1                   -- (1-yes, 0-no) // is enemy in danger vision dist (<8)
    end

    if self.character:getVehicle() ~= nil then
        p.isNearEnemy = 0
    end

    NPCInsp("NPC", "isNearEnemy", p.isNearEnemy)
    NPCInsp("NPC", "isGoodWeapon", p.isGoodWeapon)
    
    p.isRunFromDanger = 0
    if self.TaskManager:getCurrentTaskName() == "Flee" then
        p.isRunFromDanger = 1               -- (1-yes, 0-no) // npc is flee from last danger
    end

    p.needReload = 0
    local currentWeapon = self.character:getPrimaryHandItem()
    if currentWeapon and instanceof(currentWeapon, "HandWeapon") and currentWeapon:isAimedFirearm() and currentWeapon:getCurrentAmmoCount() < currentWeapon:getMaxAmmo()/3 and NPCUtils:haveAmmoForReload(currentWeapon, self.character:getInventory()) then
        p.needReload = 1
    end

    p.isTooDangerous = 0
    if self.character:getModData().NPC.nearestEnemy ~= nil or self.character:getModData().NPC.isEnemyAtBack then
        if self.character:getModData().NPC.isEnemyAtBack and self.character:getModData().NPC.isNearTooManyZombies then
            p.isTooDangerous = 1
        elseif self.character:getModData().NPC.isNearTooManyZombies or not self.agressiveAttack then
            if not self.character:isOutside() or not self.agressiveAttack then
                p.isTooDangerous = 1
            elseif self.character:getPrimaryHandItem() == nil or self.character:getPrimaryHandItem() and not self.character:getPrimaryHandItem():isAimedFirearm() then
                p.isTooDangerous = 1
            end           
        end
    end    

    p.isInSafeZone = 1
    if self.character:getModData().NPC.nearestEnemy ~= nil and NPCUtils.getDistanceBetween(self.character, self.character:getModData().NPC.nearestEnemy) < 4 or self.TaskManager:getCurrentTaskName() == "StepBack" then
        p.isInSafeZone = 0
    end

    p.isHaveAmmoToReload = 0
    if self.character:getModData().NPC:haveAmmo() then
        p.isHaveAmmoToReload = 1
    end

    p.needEatDrink = 0
    if self.EatTaskTimer <= 0 and self.character:getMoodles():getMoodleLevel(MoodleType.Hungry) > 1 then
        p.needEatDrink = 1
    end
    if self.DrinkTaskTimer <= 0 and self.character:getMoodles():getMoodleLevel(MoodleType.Thirst) > 1 then
        p.needEatDrink = 1
    end

    self.IP = p
end


function AI:getType()
    return nil
end


function AI:update()
    if self.character == nil or self.character:getSquare() == nil then return end

    self.rareUpdateTimer = self.rareUpdateTimer + 1
    if self.rareUpdateTimer == 30 then
        self.rareUpdateTimer = 0
        self:rareUpdate()
    end

    self:UpdateInputParams()
    self:chooseTask()
    self.TaskManager:update()

    local isAtBase = NPCGroupManager:isAtBase(self.character:getX(), self.character:getY())
    if isAtBase then
        if self.isAtBase == false then
            NPCDialogueSystem.SayDialoguePhrase( self.character:getModData().NPC, "returnToBase", 10, NPCColor.White)
        end
        self.isAtBase = true
    else
        self.isAtBase = false
    end    
end

function AI:rareUpdate()
    self.character:getModData().NPC:doVision()
end


function AI:calcSurrenderCat()
    local surr = {}
    surr.name = "Surrender"
    surr.score = self.IP.isRobbed * self.IP.raiderGoodWeapon * self:norm(1 - self.IP.isGoodStuff, self.IP.needToHeal, 1 - self.IP.isGoodWeapon)

    local attack = {}
    attack.name = "Attack"
    attack.score = self.IP.isRobbed * self.IP.isGoodWeapon * (1 - self.IP.needToHeal)

    local flee = {}
    flee.name = "Flee"
    flee.score = self.IP.isRobbed * self:norm(self.IP.isGoodStuff, self.IP.needToHeal, 1 - self.IP.isGoodWeapon)

    if self.isRobbed and self:getMaxTaskName(surr, attack, flee) == nil then
        self.isRobbed = false
        self.robbedBy = nil
        self.character:getModData().NPC:Say("ha-ha-ha, I don't fear you", NPCColor.White)
    end

    return self:getMaxTaskName(surr, attack, flee)
end

function AI:calcDangerCat()
    local attack = {}
    attack.name = "Attack"
    attack.score = self.IP.isAgressiveMode* self.IP.isNearEnemy * (1 - self.IP.isRunFromDanger) * self.IP.isGoodWeapon * (1 - self.IP.needReload) * (1 - self.IP.isTooDangerous)

    local flee = {}
    flee.name = "Flee"
    flee.score = self.IP.isNearEnemy *self:norm(self.IP.isRunFromDanger, self.IP.isTooDangerous, self.IP.needToHeal)

    local reload = {}
    reload.name = "ReloadWeapon"
    reload.score = self.IP.isNearEnemy*(1-self.IP.isRunFromDanger)*self.IP.needReload*self.IP.isGoodWeapon*self.IP.isInSafeZone*self.IP.isHaveAmmoToReload

    local equip = {}
    equip.name = "EquipWeapon"
    equip.score = self.IP.isNearEnemy*(1-self.IP.isRunFromDanger)*(1-self.IP.isGoodWeapon)*self.IP.isInSafeZone

    local stepBack = {}
    stepBack.name = "StepBack"
    stepBack.score = self.IP.isNearEnemy*(1-self.IP.isInSafeZone)* self:norm(self.IP.needReload, 1 - self.IP.isGoodWeapon) * (1-flee.score)

    return self:getMaxTaskName(attack, flee, stepBack, reload, equip)
end

function AI:calcImportantCat()
    local firstAid = {}
    firstAid.name = "FirstAid"
    firstAid.score = self.IP.needToHeal

    local reload = {}
    reload.name = "ReloadWeapon"
    reload.score = self.IP.needReload*self.IP.isGoodWeapon*self.IP.isHaveAmmoToReload

    local eatDrink = {}
    eatDrink.name = "EatDrink"
    eatDrink.score = self.IP.needEatDrink

    return self:getMaxTaskName(firstAid, reload, eatDrink)
end

function AI:calcTaskCat()
    return nil
end

function AI:calcCommonTaskCat()
    if self.idleCommand ~= nil then
        if self.idleCommand == "SMOKE" then
            return "Smoke"
        end
    
        if self.idleCommand == "SIT" then
            return "Sit"
        end
    
        if self.idleCommand == "IDLE_WALK" and self.character:getActionStateName() ~= "sitonground" then
            return "IdleWalk"
        end
    
        if self.idleCommand == "TALK" then
            self.TaskArgs.talkChar = getPlayer()
            return "Talk"
        end
    else
        if self.IP.isSmoke then
            return "Smoke"
        end
    
        if self.IP.isSit then
            return "Sit"
        end
    
        if self.IP.idleWalk and self.character:getActionStateName() ~= "sitonground" then
            return "IdleWalk"
        end
    
        if self.IP.talkIdle  then
            self.TaskArgs.talkChar = getPlayer()
            return "Talk"
        end
    end
end

function AI:getMaxTaskName(a, b, c, d, e, f, g, i, j, k, l, m)
    local t = {a, b, c, d, e, f, g, i, j, k, l, m}
    local task
    local max = 0
    for _, v in ipairs(t) do
        if v.score > max then
            max = v.score
            task = v
        end        
    end
    if task == nil then return nil end
    return task.name
end

function AI:norm(a, b, c, d, e, f)
    local t = { a, b, c, d, e, f }
    local s = 0
    for i, v in ipairs(t) do
        s = s + v
    end
    return math.min(s, 1)
end



function AI:chooseTask()
    local taskPoints = {}
    taskPoints["AttachItem"] = AttachItemTask
    taskPoints["Attack"] = AttackTask
    taskPoints["CollectCorpses"] = CollectCorpsesTask
    taskPoints["DropLoot"] = DropLootTask
    taskPoints["EatDrink"] = EatDrinkTask
    taskPoints["EquipWeapon"] = EquipWeaponTask
    taskPoints["FindItems"] = FindItemsTask
    taskPoints["FirstAid"] = FirstAidTask
    taskPoints["Flee"] = FleeTask
    taskPoints["Follow"] = FollowTask
    taskPoints["GoToInterestPoint"] = GoToInterestPointTask
    taskPoints["IdleWalk"] = IdleWalkTask
    taskPoints["Patrol"] = PatrolTask
    taskPoints["ReloadWeapon"] = ReloadWeaponTask
    taskPoints["Robbing"] = RobbingTask
    taskPoints["Sit"] = SitTask
    taskPoints["Smoke"] = SmokeTask
    taskPoints["StayHere"] = StayHereTask
    taskPoints["StepBack"] = StepBackTask
    taskPoints["Surrender"] = SurrenderTask
    taskPoints["TakeItemsFromPlayer"] = TakeItemsFromPlayerTask
    taskPoints["Talk"] = TalkTask
    taskPoints["Wash"] = WashTask

    -- Each category task have more priority than next (surrender > danger > important > ...)
    local task = nil
    local score = 0
    local surrenderTask = self:calcSurrenderCat()
    if surrenderTask ~= nil then
        task = surrenderTask
        score = 600
    else
        local dangerTask = self:calcDangerCat()
        if dangerTask ~= nil then
            task = dangerTask
            score = 500
        else
            local importantTask = self:calcImportantCat()
            if importantTask ~= nil then
                task = importantTask
                score = 400
            else
                local playerTask = self:calcTaskCat()
                if playerTask ~= nil then
                    task = playerTask
                    score = 300
                else
                    local commonTask = self:calcCommonTaskCat()
                    if commonTask ~= nil then
                        task = commonTask
                        score = 200
                    end
                end
            end
        end
    end

    NPCInsp("NPC", self.character:getDescriptor():getSurname(), self.TaskManager:getCurrentTaskName())
    NPCPrint(false, "AI", "Current task", self.TaskManager:getCurrentTaskName(), self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
    if self.TaskManager:getCurrentTaskScore() <= score and task ~= nil and task ~= self.TaskManager:getCurrentTaskName() then
        ISTimedActionQueue.clear(self.character)
        if self.TaskManager.tasks[0] ~= nil then
            NPCPrint(true, "AI", "Old task stopped", self.TaskManager:getCurrentTaskName(), self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
        end
        NPCPrint(true, "AI", "New current task", task, self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
        self.TaskManager:addToTop(taskPoints[task]:new(self.character), score)
    end
end
