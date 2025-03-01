
local tempTransferFunc = ISInventoryTransferAction.start
function ISInventoryTransferAction:start()
    if self.character:getModData().NPC then
        self.character:getModData().NPC:SayNote("*transfer " .. self.item:getName() .. "*", NPCColor.transferItem)
    end
    tempTransferFunc(self)
end

-- Fix
function ISInventoryTransferAction:perform()
	-- I would have done this in start(), however the first action added to the queue
	-- is started immediately, before any other actions can be added.
	self:checkQueueList()

	self.item:setJobDelta(0.0)
--	print("perform on item", self.item, self.item:getDisplayName())
	-- take the next item in our queue list
	local queuedItem = table.remove(self.queueList, 1);
	-- reopen the correct container
	if self.selectedContainer and self.character == getPlayer() then
		getPlayerLoot(self.character:getPlayerNum()):selectButtonForContainer(self.selectedContainer)
	end

	for i,item in ipairs(queuedItem.items) do
		self.item = item
		-- Check destination container capacity and item-count limit.
		if not self:isValid() then
			self.queueList = {}
			break
		end
		self:transferItem(item);
	end
	-- if we still have other item to transfer in our queue list, we "reset" the action
	if #self.queueList > 0 then
		queuedItem = self.queueList[1]
		self.item = queuedItem.items[1];
--		print("reset with new item: ", queuedItem.items[1], #queuedItem.items)
		local time = queuedItem.time;
		if self:isAlreadyTransferred(self.item) then
			time = 0
		end
		self.maxTime = time
		self.action:setTime(tonumber(time))
		self:resetJobDelta();
		self:startActionAnim()
	else
		self.action:stopTimedActionAnim();
		self.action:setLoopedAction(false);

		if self.onCompleteFunc then
			local args = self.onCompleteArgs
			self.onCompleteFunc(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
		end

		-- needed to remove from queue / start next.
		ISBaseTimedAction.perform(self);
	end

	if instanceof(self.item, "Radio") then
		self.character:updateEquippedRadioFreq();
	end

    for i, char in ipairs(NPCManager.characters) do
        if NPCUtils.getDistanceBetween(char.character, getPlayer()) < 30 then
            char.AI.EatTaskTimer = 0
            char.AI.DrinkTaskTimer = 0
        end
    end
end

-- FIX
function ISInventoryTransferAction:update()
	-- reopen the correct container
	if self.selectedContainer and self.character:getModData().NPC == nil then
		if self.selectedContainer:getParent() then
			self.character:faceThisObject(self.selectedContainer:getParent())
		end
		if self.character:shouldBeTurning() then
			getPlayerLoot(self.character:getPlayerNum()):setForceSelectedContainer(self.selectedContainer)
		end
		getPlayerLoot(self.character:getPlayerNum()):selectButtonForContainer(self.selectedContainer)
	end
	self.item:setJobDelta(self.action:getJobDelta());

    self.character:setMetabolicTarget(Metabolics.LightWork);
end

local tempGrabFunc = ISGrabItemAction.start
function ISGrabItemAction:start()
    if self.character:getModData().NPC then
        self.character:getModData().NPC:Say("*transfer " .. self.item:getItem():getName() .. "*", NPCColor.transferItem)
    end
    tempGrabFunc(self)
end