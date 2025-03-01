ReloadWeaponTask = {}
ReloadWeaponTask.__index = ReloadWeaponTask

function ReloadWeaponTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "ReloadWeapon"
	o.complete = false

    o.delayTimer = 0

	return o
end


function ReloadWeaponTask:isComplete()
	return self.complete
end

function ReloadWeaponTask:isValid()
    return self.character and self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():isAimedFirearm()
end

function ReloadWeaponTask:stop()
    self.character:NPCSetAttack(false)
    self.character:NPCSetMelee(false)
    self.character:NPCSetAiming(false)
    self.character:setForceShove(false);
    self.character:setVariable("bShoveAiming", false);
end

function ReloadWeaponTask:update()
    if not self:isValid() then return false end
    local currentWeapon = self.character:getPrimaryHandItem()
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        self.character:getModData()["NPC"]:readyGun(currentWeapon, self.character:getModData().NPC.AI.TaskArgs.isFullReload)
    end

    if self.character:getModData().NPC.AI.TaskArgs.isFullReload then
        if currentWeapon:getCurrentAmmoCount() == currentWeapon:getMaxAmmo() or not NPCUtils:haveAmmoForReload(currentWeapon, self.character:getInventory()) then
            if self.character:getModData().NPC.AI.command == "RELOAD" then
                self.character:getModData().NPC.AI.command = nil
            end
            self.character:getModData().NPC.AI.TaskArgs.isFullReload = false
            self.complete = true
        end
    else
        if currentWeapon:getCurrentAmmoCount() > currentWeapon:getMaxAmmo()/3 or not NPCUtils:haveAmmoForReload(currentWeapon, self.character:getInventory()) then
            if self.character:getModData().NPC.AI.command == "RELOAD" then
                self.character:getModData().NPC.AI.command = nil
            end
            self.character:getModData().NPC.AI.TaskArgs.isFullReload = false
            self.complete = true
        end
    end

    return true
end