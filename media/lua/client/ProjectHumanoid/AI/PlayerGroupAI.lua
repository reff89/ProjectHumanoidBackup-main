PlayerGroupAI = AI:derive("PlayerGroupAI")

function PlayerGroupAI:new(character)
    local o = AI.new(self, character)

    return o
end

function PlayerGroupAI:getType()
    return AI.Type.PlayerGroupAI
end



function PlayerGroupAI:UpdateInputParams()
    AI.UpdateInputParams(self)
    local p = self.IP

    local number = ZombRand(0,200000)
    if number > 60 and number <= 70 then
        p.isSmoke = true
    elseif number >= 0 and number <= 10 then
        p.isSit = true
    elseif number > 10 and number <= 50 then
        p.idleWalk = true
    elseif number > 50 and number <= 60 then
        p.talkIdle = true
    end

    self.IP = p
end

function PlayerGroupAI:calcTaskCat()
    local follow = {}
    follow.name = "Follow"
    follow.score = 0
    if self:isCommandFollow() and NPCUtils.getDistanceBetween(self.character, self.mainPlayer) > 3 then
        follow.score = 1
    end

    local stay = {}
    stay.name = "StayHere"
    stay.score = 0
    if self:isCommandStayHere() and self.character:getSquare() ~= self.staySquare then
        stay.score = 1
    end

    local patrol = {}
    patrol.name = "Patrol"
    patrol.score = 0
    if self:isCommandPatrol() then
        patrol.score = 1
    end

    local collect_corpses = {}
    collect_corpses.name = "CollectCorpses"
    collect_corpses.score = 0
    if self.command == "COLLECT_CORPSES" then
        collect_corpses.score = 1
    end

    local find_items = {}
    find_items.name = "FindItems"
    find_items.score = 0
    if self:isCommandFindItems() then
        find_items.score = 1
    end

    local wash = {}
    wash.name = "Wash"
    wash.score = 0
    if self:isCommandWash() then
        wash.score = 1
    end

    local attach = {}
    attach.name = "AttachItem"
    attach.score = 0
    if self:isCommandAttach() then
        attach.score = 1
    end

    local dropLoot = {}
    dropLoot.name = "DropLoot"
    dropLoot.score = 0
    if self.command == "DROP_LOOT" then
        dropLoot.score = 1
    end

    local talk = {}
    talk.name = "Talk"
    talk.score = 0
    if self.command == "TALK" then
        talk.score = 1
    end

    local reload = {}
    reload.name = "ReloadWeapon"
    reload.score = 0
    if self.command == "RELOAD" then
        reload.score = 1
        local fireWeapon = NPCUtils:getBestRangedWeapon(self.character:getInventory())
        if fireWeapon == nil then
            self.character:getModData().NPC.AI.command = nil
            self.character:getModData().NPC.AI.TaskArgs.isFullReload = false
            reload.score = 0
        else
            if self.character:getPrimaryHandItem() ~= fireWeapon then
                reload.name = "EquipWeapon"
            end
        end
    end

    return self:getMaxTaskName(follow, stay, patrol, find_items, wash, attach, talk, dropLoot, collect_corpses, reload)
end