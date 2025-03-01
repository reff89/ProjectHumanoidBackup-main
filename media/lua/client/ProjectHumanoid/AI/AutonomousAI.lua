AutonomousAI = AI:derive("AutonomousAI")

function AutonomousAI:new(character)
    local o = AI.new(self, character)

    return o
end

function AutonomousAI:getType()
    return AI.Type.AutonomousAI
end

function AutonomousAI:update()
    AI.update(self)

    if self.chillTime > 0 then
        self.chillTime = self.chillTime - 1
    end

    self.character:setSneaking(false)
end

function AutonomousAI:UpdateInputParams()
    AI.UpdateInputParams(self)
    local p = self.IP

    p.findItems = 0
    p.isChillTime = 0
    p.goToPoint = 0
    p.isLeader = 0
    p.haveGroup = 0

    if NPCGroupManager:getGroupID(self.character:getModData().NPC.ID) == nil then
        if self.isCheckCluster then
            p.findItems = 1
        else
            if self.currentCluster == nil then
                self.currentCluster = ScanSquaresSystem.getNearestCluster(self.character:getX(), self.character:getY(), self.character:getModData().NPC.AI.visitedClusters, function(obj) return true end)
            end
            if self.currentCluster ~= nil then
                if NPCUtils.getDistanceBetweenXYZ(self.currentCluster:getX(),  self.currentCluster:getY(), self.character:getX(), self.character:getY()) < 6 then
                    p.findItems = 1
                    self:calcFindItemCategories()
                    self.isCheckCluster = true
                else
                    p.goToPoint = 1
                end
            else
                print("NO NEW INTEREST POINT")
            end
        end
    else
        p.haveGroup = 1
        if NPCGroupManager:isLeader(self.character:getModData().NPC.ID) then
            p.isLeader = 1

            if self.isCheckCluster then
                p.findItems = 1
            else
                if self.currentCluster == nil then
                    self.currentCluster = ScanSquaresSystem.getNearestCluster(self.character:getX(), self.character:getY(), self.character:getModData().NPC.AI.visitedClusters, function(obj) return true end)
                end
                if self.currentCluster ~= nil then
                    if NPCUtils.getDistanceBetweenXYZ(self.currentCluster:getX(),  self.currentCluster:getY(), self.character:getX(), self.character:getY()) < 6 then
                        p.findItems = 1
                        self:calcFindItemCategories()
                        self.isCheckCluster = true
                    else
                        p.goToPoint = 1
                    end
                else
                    print("NO NEW INTEREST POINT")
                end
            end

            if self.chillTime > 0 then
                p.isChillTime = 1
            else
                if ZombRand(20000) == 0 then
                    self.chillTime = 600
                    p.isChillTime = 1
                end
            end
        else
            local leaderID = NPCGroupManager:getLeaderID(NPCGroupManager:getGroupID(self.character:getModData().NPC.ID))
            local leader = NPCManager:getCharacter(leaderID)

            if leader ~= nil then
                if leader.AI.TaskManager:getCurrentTaskName() == "FindItems" and NPCUtils.getDistanceBetween(leader, self.character) < 20 then
                    self.currentCluster = leader.AI.currentCluster
                    p.findItems = 1
                    self:calcFindItemCategories()
                end 

                if leader.AI.chillTime > 0 then
                    p.isChillTime = 1
                end
            end
        end
    end

    p.isSmoke = 0
    p.isSit = 0
    p.talkIdle = 0
    p.idleWalk = 0

    if p.isChillTime == 1 then
        if ZombRand(0,20000) == 0 then
            p.isSmoke = 1
        elseif ZombRand(0, 2000) == 0 then
            p.talkIdle = 1
        elseif ZombRand(0, 5000) == 0 then
            p.isSit = 1
        elseif ZombRand(0, 500) == 0 then
            p.idleWalk = 1
        end
    end

    if self.idleCommand == "TALK_COMPANION" then
        p.talkIdle = 1
    end

    self.IP = p
end

function AutonomousAI:calcTaskCat()
    if self.command ~= nil then
        local take_items_from_player = {}
        take_items_from_player.name = "TakeItemsFromPlayer"
        take_items_from_player.score = 0
        if self.command == "TAKE_ITEMS_FROM_PLAYER" then
            take_items_from_player.score = 1
        end

        local robbing = {}
        robbing.name = "Robbing"
        robbing.score = 0
        if self.command == "ROBBING" then
            robbing.score = 1
        end

        return self:getMaxTaskName(take_items_from_player, robbing)
    else
        local find_items = {}
        find_items.name = "FindItems"
        find_items.score = self.IP.findItems * (1 - self.IP.isChillTime)

        local goToInterestPoint = {}
        goToInterestPoint.name = "GoToInterestPoint"
        goToInterestPoint.score = self.IP.goToPoint * (1 - self.IP.findItems) * (1 - self.IP.isChillTime)

        local followLeader = {}
        followLeader.name = "Follow"
        followLeader.score = self.IP.haveGroup * (1 - self.IP.isLeader) * (1 - self.IP.isChillTime) * (1 - self.IP.findItems)
        ----
        local talk = {}
        talk.name = "Talk"
        talk.score = self.IP.isChillTime * self.IP.talkIdle

        local walk = {}
        walk.name = "IdleWalk"
        walk.score = self.IP.isChillTime * self.IP.idleWalk

        local sit = {}
        sit.name = "Sit"
        sit.score = self.IP.isChillTime * self.IP.isSit

        local smoke = {}
        smoke.name = "Smoke"
        smoke.score = self.IP.isChillTime * self.IP.isSmoke

        return self:getMaxTaskName(find_items, goToInterestPoint, followLeader, talk, walk, sit, smoke)
    end
end

function AutonomousAI:calcFindItemCategories()
    self.findItems.Food = true
	self.findItems.Weapon = true
	self.findItems.Clothing = false
	self.findItems.Meds = true
	self.findItems.Bags = true
	self.findItems.Melee = true
	self.findItems.Literature = false
end