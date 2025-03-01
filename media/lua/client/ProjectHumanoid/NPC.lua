
--- NPC class. Main class for create instance of NPC

require("CommunityAPI")
local SettingAPI = CommunityAPI.Client.ModSetting

---@class NPC
NPC = {}
NPC.__index = NPC

--- Create instance on NPC
---@param square IsoGridSquare
---@param preset table
---@param AIType AI.Type
function NPC:new(square, preset, AIType)
    local o = {}
	setmetatable(o, self)
	self.__index = self

    -- Create IsoPlayer character
    o.character = o:_createIsoPlayer(square, preset)
    o.character:getModData().NPC = o

    -- Set AI
    if AIType == AI.Type.PlayerGroupAI then
        o.AI = PlayerGroupAI:new(o.character)	-- TODO
	elseif AIType == AI.Type.AutonomousAI then
		o.AI = AutonomousAI:new(o.character)	-- TODO
	else
		NPCPrint(true, "NPC", "Incorrect AI type", AIType)
		return
    end

	o.ID = NPCUtils.UUID()
	o.username = NPCUsername:new(o.character)
	o.sayDialog = NPCSayDialog:new(o.character)
	o.hotbar = NPCHotBar:new(o.character)
	o.reputationSystem = ReputationSystem:new(o.character, preset.defaultReputation)

	-- Add npc to NPCManager
	table.insert(NPCManager.characters, o)
	NPCManager.characterMap[o.ID] = { isLoaded = true, isSaved = false, npc = o , x = o.character:getX(), y = o.character:getY(), z = o.character:getZ() }
	NPCPrint(true, "NPC", "Create new NPC", o.character:getDescriptor():getSurname(), o.ID)

	-- Attributes
	o.groupCharacteristic = preset.groupCharacteristic
	o.isRaiderVar = preset.isRaider
	o.username:updateName()

	o.saveTimer = 0
	o:save()

    return o
end

--- Create IsoPlayer instance
---@param square IsoGridSquare
---@param preset table
function NPC:_createIsoPlayer(square, preset)
    local survivorDesc = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, preset.isFemale)

	-- Skin color
	survivorDesc:getHumanVisual():setSkinTextureIndex(preset.skinColor)	-- int 0-4

	-- Hair
	survivorDesc:getHumanVisual():setHairModel(preset.hair)
	local ic = ImmutableColor.new(preset.hairColor.r, preset.hairColor.g, preset.hairColor.b, 1)
	survivorDesc:getHumanVisual():setHairColor(ic)

	-- Beard
	survivorDesc:getHumanVisual():setBeardModel(preset.beard)
	ic = ImmutableColor.new(preset.beardColor.r, preset.beardColor.g, preset.beardColor.b, 1)
	survivorDesc:getHumanVisual():setBeardColor(immutableColor)

	-- Set name
	survivorDesc:setForename(preset.forename)
	survivorDesc:setSurname(preset.surname)

	-- Set profession
	survivorDesc:setProfession(preset.profession)

	-- Outfit if random
	if preset.outfit == "RAND" then
		local outfits = getAllOutfits(preset.isFemale)
		local nameOutfit = outfits:get(ZombRand(outfits:size()))
		survivorDesc:dressInNamedOutfit(nameOutfit)
	end

	-- Create isoPlayer
	local z = 0
	if square:isSolidFloor() then z = square:getZ() end
	local character = IsoPlayer.new(getWorld():getCell(), survivorDesc, square:getX(), square:getY(), z)

	-- Perks
	for perk, num in pairs(preset.perks) do
		for i=1, num do
			character:LevelPerk(Perks.FromString(perk))
		end
	end

	-- Outfit if not random
	if preset.outfit ~= "RAND" then
		for _, element in ipairs(preset.outfit) do
			if type(element) == "table" then
				local invItem = instanceItem(element[1])
				if invItem then
					character:getInventory():AddItem(invItem)
					if element[2] == "Both hands" then
						character:setPrimaryHandItem(invItem)
						character:setSecondaryHandItem(invItem)
					elseif element[2] == "Primary" then
						character:setPrimaryHandItem(invItem)
					elseif element[2] == "Secondary" then
						character:setSecondaryHandItem(invItem)
					elseif element[2] == "Color" then
						invItem:getVisual():setTint(ImmutableColor.new(element[3].r, element[3].g, element[3].b, 1))
						if invItem:getBodyLocation() ~= "" then
							character:setWornItem(invItem:getBodyLocation(), invItem)
						end
					end
				end
			else
				local clothingItem = instanceItem(element)
				if clothingItem then
					character:getInventory():AddItem(clothingItem)
					if instanceof(clothingItem, "InventoryContainer") and clothingItem:canBeEquipped() ~= "" then
						character:setClothingItem_Back(clothingItem)
					elseif clothingItem:getCategory() == "Clothing" then
						if clothingItem:getBodyLocation() ~= "" then
							character:setWornItem(clothingItem:getBodyLocation(), clothingItem)
						end
					end
				else
					NPCPrint(true,"NPC", "Error in NPC preset", element)
				end 
			end
		end
	else
		local clothingItem = instanceItem("Base.Belt2")
		character:getInventory():AddItem(clothingItem)
		character:setWornItem(clothingItem:getBodyLocation(), clothingItem)
	end

	-- Items
	for _, element in ipairs(preset.items) do
		if type(element) == "table" then
			local invItems = character:getInventory():getItems()
			for i=1, invItems:size() do
				local tempItem = invItems:get(i-1)
				if instanceof(tempItem, "InventoryContainer") and tempItem:isEquipped() and (tempItem:getModule() .. "." .. tempItem:getType()) == element[1] then
					for j=2, #element do
						local containerItem = instanceItem(element[j])
						tempItem:getInventory():AddItem(containerItem)
					end
				end
			end
		else
			local invItem = instanceItem(element)
			character:getInventory():AddItem(invItem)
		end
	end

	-- Attach items
	for _, attachTable in ipairs(preset.attachments) do
		local invItems = character:getInventory():getItems()
		for i=1, invItems:size() do
			local tempItem = invItems:get(i-1)
			if (tempItem:getModule() .. "." .. tempItem:getType()) == attachTable[1] then
				character:setAttachedItem(attachTable[3], tempItem)
				tempItem:setAttachedSlot(attachTable[2])
				tempItem:setAttachedSlotType(attachTable[4])
				tempItem:setAttachedToModel(attachTable[3])
			end
		end	
	end

	character:setBlockMovement(false)
	character:setSceneCulled(false)
	character:setNPC(true)

	return character
end

function NPC:isRaider()
	return self.isRaiderVar
end

function NPC:save()
	NPCPrint(true, "NPC", "Saving NPC", self.character:getDescriptor():getSurname(), self.ID)

	-- Save params to ModData
	self.character:getModData().actionContext_isSit = self.character:getActionStateName() == "sitonground"
	self.character:getModData().NPCAIType = self.AI:getType()
	self.character:getModData().defaultRep = self.character:getModData().NPC.reputationSystem.defaultReputation
	self.character:getModData().playerRep = self.character:getModData().NPC.reputationSystem.playerRep
	self.character:getModData().repList = self.character:getModData().NPC.reputationSystem.reputationList

	local temp = self.character:getModData().NPC.AI.TaskManager.tasks[0]
	self.character:getModData().NPC.AI.TaskManager.tasks[0] = nil

	local filename = NPCUtils.getSaveDir() .. "NPC"..tostring(self.ID)
	self.character:save(filename)

	self.character:getModData().NPC.AI.TaskManager.tasks[0] = temp

	self.saveTimer = 1800
end

function NPC:load(ID, x, y, z)
	NPCPrint(true, "NPC", "Load NPC", ID)
	
	local survivorDesc = SurvivorFactory.CreateSurvivor()
	local character = IsoPlayer.new(getWorld():getCell(), survivorDesc, x, y, z)
	character:getInventory():emptyIt()
	local filename = NPCUtils.getSaveDir() .. "NPC"..tostring(ID)
	character:load(filename)

	character:setX(x)
	character:setY(y)
	character:setZ(z)
	character:setNPC(true)
	character:setBlockMovement(false)
	character:setSceneCulled(false)

	local o = character:getModData().NPC
	setmetatable(o, self)
	self.__index = self

    o.character = character
	o.username = NPCUsername:new(o.character)
	o.sayDialog = NPCSayDialog:new(o.character)
	o.hotbar = NPCHotBar:new(o.character)

	o.reputationSystem = ReputationSystem:new(o.character, o.character:getModData().defaultRep)
	o.reputationSystem.playerRep = o.character:getModData().playerRep
	o.reputationSystem.reputationList = o.character:getModData().repList

	table.insert(NPCManager.characters, o)

	if o.character:getModData().NPCAIType == AI.Type.PlayerGroupAI then
		o.AI = PlayerGroupAI:new(o.character)
	else
		o.AI = AutonomousAI:new(o.character)
	end

	if o.character:getModData().actionContext_isSit then
		o.character:reportEvent("EventSitOnGround")
	end
	
	return o
end

function NPC:update()
	self.character:setGhostMode(false)
	self.character:setGodMod(false)
	self.character:setAvoidDamage(false)
	self.character:setInvincible(false)

	self.AI:update()

	self.username:update()
	self.sayDialog:update()
	self.hotbar:update()

	self:updateSpecialParams()

	if self.saveTimer > 0 then
		self.saveTimer = self.saveTimer - 1
	else
		self:save()
	end
end


function NPC:updateSpecialParams()
	self.character:getStats():setFatigue(0) -- Set sleep always full

	if not SettingAPI.GetModSettingValue("ProjectHumanoid", "NPC_NEED_FOOD") then
		self.character:getStats():setThirst(0.0)
		self.character:getStats():setHunger(0.0)
	end

	self.character:getStats():setPanic(0)
	self.character:getBodyDamage():setHasACold(false)

	if not SettingAPI.GetModSettingValue("ProjectHumanoid", "NPC_CAN_INFECT") then
		self.character:getBodyDamage():setInfectionLevel(0)
	end

	if not SettingAPI.GetModSettingValue("ProjectHumanoid", "NPC_NEED_AMMO") then
		local container = self.character:getInventory()
		for j=1, container:getItems():size() do
			local weapon = container:getItems():get(j-1)
			if instanceof(weapon, "HandWeapon") and weapon:isAimedFirearm() then
				if(weapon:getMagazineType()) then
					if weapon:isContainsClip() then
						local ammoCount = self.character:getInventory():getItemCountRecurse(weapon:getAmmoType()) + weapon:getCurrentAmmoCount()
						if ammoCount < 10 then
							for i=ammoCount, 10 do
								self.character:getInventory():AddItem(weapon:getAmmoType())	
							end
						end
					else
						local ammoCount = self.character:getInventory():getItemCountRecurse(weapon:getAmmoType())
						local magazine = self.character:getInventory():getFirstTypeRecurse(weapon:getMagazineType())
						if magazine == nil then
							self.character:getInventory():AddItem(weapon:getMagazineType())	
						else
							ammoCount = ammoCount + magazine:getCurrentAmmoCount()
						end
						if ammoCount < 10 then
							for i=ammoCount, 10 do
								self.character:getInventory():AddItem(weapon:getAmmoType())	
							end
						end
					end
				else
					local ammoCount = self.character:getInventory():getItemCountRecurse(weapon:getAmmoType()) + weapon:getCurrentAmmoCount()
					if ammoCount < 10 then
						for i=ammoCount, 10 do
							self.character:getInventory():AddItem(weapon:getAmmoType())	
						end
					end
				end
			end
		end
	end
end

function NPC:setAI(AIType)
	if AIType == AI.Type.PlayerGroupAI then
        self.AI = PlayerGroupAI:new(self.character)
	elseif AIType == AI.Type.AutonomousAI then
		self.AI = AutonomousAI:new(self.character)	
	else
		NPCPrint(true, "NPC", "Incorrect AI type", AIType)
		return
    end
end

function NPC:Say(text, color)
	self.sayDialog:Say(text, color)
end

function NPC:SayNote(text, color)
	self.sayDialog:SayNote(text, color)
end

function NPC:getHit(wielder, weapon, damage)
	damage = damage/2

	local parts = self.character:getBodyDamage():getBodyParts()
    local partIndex = ZombRand(parts:size())

    ISTimedActionQueue.clear(self.character)
    ISTimedActionQueue.add(ISGetHitAction:new(self.character, wielder))

    local bodyDefence = true

    local bluntCat = false
    local firearmCat = false
    local otherCat = false

    if weapon:getType() == "BareHands" then
        return
    end

    if (weapon:getCategories():contains("Blunt") or weapon:getCategories():contains("SmallBlunt")) then
        bluntCat = true1
    elseif not (weapon:isAimedFirearm()) then
        otherCat = true
    else 
        firearmCat = true
    end

    local bodydamage = self.character:getBodyDamage()
    local bodypart = bodydamage:getBodyPart(BodyPartType.FromIndex(partIndex))
    if (ZombRand(0,100) < self.character:getBodyPartClothingDefense(partIndex, otherCat, firearmCat)) then
        bodyDefence = false
        self.character:addHoleFromZombieAttacks(BloodBodyPartType.FromIndex(partIndex), false)
    end
    if bodyDefence == false then
        return
    end

    self.character:addHole(BloodBodyPartType.FromIndex(partIndex))

    if (otherCat) then
        if (ZombRand(0,6) == 6) then
            bodypart:generateDeepWound()
        elseif (ZombRand(0,3) == 3) then
            bodypart:setCut(true)
        else
            bodypart:setScratched(true, true)
        end
    elseif (bluntCat) then
        if (ZombRand(0,4) == 4) then
            bodypart:setCut(true)
        else
            bodypart:setScratched(true, true)
        end
    elseif (firearmCat) then
        bodypart:setHaveBullet(true, 0)
    end

    bodydamage:AddDamage(partIndex, damage*100.0)
    local stats = self.character:getStats()
    if bluntCat then
        stats:setPain(stats:getPain() + bodydamage:getInitialThumpPain() * BodyPartType.getPainModifyer(partIndex))
    elseif otherCat then
        stats:setPain(stats:getPain() + bodydamage:getInitialScratchPain() * BodyPartType.getPainModifyer(partIndex))
    elseif firearmCat then
        stats:setPain(stats:getPain() + bodydamage:getInitialBitePain() * BodyPartType.getPainModifyer(partIndex))
    end

    bodydamage:Update()
end


function NPC:doVision()
	local objects = self.character:getCell():getObjectList()
	self.seeEnemyCount = 0

	if self.nearestEnemy ~= nil and (self.nearestEnemy:isDead() or NPCUtils.getDistanceBetween(self.character, self.nearestEnemy) > 15) then
		self.nearestEnemy = nil
	end

	local nearestDist = 100000
	if self.nearestEnemy ~= nil then
		nearestDist = NPCUtils.getDistanceBetween(self.character, self.nearestEnemy)
	end
	
	self.isNearTooManyZombies = false
	local nearZombiesCount = 0
	self.isZombieAtFront = false
	self.isEnemyAtBack = false

	if(objects ~= nil) then
		for i=0, objects:size()-1 do
			local obj = objects:get(i)
			if obj ~= nil and obj ~= self.character and (instanceof(obj,"IsoZombie") or instanceof(obj,"IsoPlayer")) then
				if not obj:isDead() and obj:getSquare() ~= nil and obj:getSquare():getZ() == self.character:getSquare():getZ() then
					local dist = NPCUtils.getDistanceBetween(self.character, obj)
					if obj:isOnFloor() then dist = dist + 1 end		-- less priority to lay down zombie	

					if self:isEnemy(obj) then
						local canSee = self:canSee(obj)

						if canSee and dist < 10 then
							self.seeEnemyCount = self.seeEnemyCount + 1
							
							if dist < nearestDist then
								nearestDist = dist
								self.nearestEnemy = obj
							end
						end

						-- Can hear zombie if near
						if dist <= 2 then
							if not canSee then
								nearestDist = dist
								self.nearestEnemy = obj
								self.isEnemyAtBack = true
							else
								if dist < nearestDist and dist < 1.5 then
									self.isZombieAtFront = true
								end
							end
						end

						if dist <= 3 then
							nearZombiesCount = nearZombiesCount + 1
						end
					end
				end
			end
		end
	end

	if nearZombiesCount > 4 then
		self.isNearTooManyZombies = true
	end
end

function NPC:canSee(character)
	if instanceof(character,"IsoZombie") then return self.character:CanSee(character) end

	local visionCone = 0.9

	if self.character:CanSee(character) then
		if(character:isSneaking()) then 
			visionCone = visionCone - 0.3 
		end

		return (self.character:getDotWithForwardDirection(character:getX(), character:getY()) + visionCone) >= 1
	end
	return false
end

function NPC:isEnemy(character)
	if instanceof(character,"IsoZombie") then
		return true
	end
	if instanceof(character, "IsoPlayer") then
		if character:getModData().NPC ~= nil then
			if self.reputationSystem:getNPCRep(character:getModData().NPC) < 0 then
				return true
			end
		else
			if self.reputationSystem:getPlayerRep() < 0 then
				return true
			end
		end
	end
	return false
end


function NPC:getMinWeaponRange()
	local out = 0.5
	if(self.character:getPrimaryHandItem() ~= nil) then
		if(instanceof(self.character:getPrimaryHandItem(),"HandWeapon")) then
			return self.character:getPrimaryHandItem():getMinRange()
		end
	end
	return out
end

function NPC:getMaxWeaponRange()
	local out = 0.8
	if(self.character:getPrimaryHandItem() ~= nil) then
		if(instanceof(self.character:getPrimaryHandItem(),"HandWeapon")) then
			return self.character:getPrimaryHandItem():getMaxRange()
		end
	end
	return out
end

function NPC:isUsingGun()
	return self.AI.isUsingGunParam
end

function NPC:readyGun(weapon, isFullReaload)
	if(not weapon) or (not weapon:isAimedFirearm()) then return false end

	if weapon:isJammed() then
		ISTimedActionQueue.add(ISRackFirearm:new(self.character, weapon))
		return true
	end	

	if weapon:haveChamber() and not weapon:isRoundChambered() then
		if(ISReloadWeaponAction.canRack(weapon)) then
			ISReloadWeaponAction.OnPressRackButton(self.character, weapon)
			return true
		end	
	end

	if weapon:getMagazineType() then
		if weapon:isContainsClip() then
			if isFullReaload then
				if weapon:getCurrentAmmoCount() == weapon:getMaxAmmo() and weapon:isRoundChambered() then
					return true
				end
			else
				if weapon:getCurrentAmmoCount() > weapon:getMaxAmmo()*4/5 and weapon:isRoundChambered() then
					return true
				end
			end

			if weapon:getCurrentAmmoCount() > 0 and not weapon:isRoundChambered() then
				ISTimedActionQueue.add(ISRackFirearm:new(self.character, weapon))
				return true
			end
			
			local magazine = NPCUtils:getBestMagazine(weapon, self.character:getInventory())
			if weapon:getCurrentAmmoCount() == 0 and magazine ~= nil then
				ISTimedActionQueue.add(ISEjectMagazine:new(self.character, weapon))
				ISTimedActionQueue.add(ISInsertMagazine:new(self.character, weapon, magazine))
				return true
			end

			ISTimedActionQueue.add(ISEjectMagazine:new(self.character, weapon))

			local ammoCount = ISInventoryPaneContextMenu.transferBullets(self.character, weapon:getAmmoType(), weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
			if ammoCount == 0 then
				return false
			end
			return true			
		else
			local magazine = NPCUtils:getBestMagazine(weapon, self.character:getInventory())
			if not magazine then
				magazine = self.character:getInventory():getFirstTypeRecurse(weapon:getMagazineType())
			end
			if magazine == nil then return false end

			ISInventoryPaneContextMenu.transferIfNeeded(self.character, magazine)

			if NPCUtils:haveAmmoForReload(weapon, self.character:getInventory()) then
				if magazine:getCurrentAmmoCount() < weapon:getMaxAmmo()*4/5 then
					ISReloadWeaponAction.ReloadBestMagazine(self.character, weapon)
				else
					ISTimedActionQueue.add(ISInsertMagazine:new(self.character, weapon, magazine))
				end
			else
				ISTimedActionQueue.add(ISInsertMagazine:new(self.character, weapon, magazine))
			end
		end
	else
		if weapon:getCurrentAmmoCount() == weapon:getMaxAmmo() then
			return true
		end

		local ammoCount = ISInventoryPaneContextMenu.transferBullets(self.character, weapon:getAmmoType(), weapon:getCurrentAmmoCount(), weapon:getMaxAmmo())
		if ammoCount == 0 then
			return false
		end
		ISTimedActionQueue.add(ISReloadWeaponAction:new(self.character, weapon))
		return true
	end

	return true
end

function NPC:haveAmmo()
	local currentWeapon = self.character:getPrimaryHandItem()
	if currentWeapon == nil or not instanceof(currentWeapon, "HandWeapon") or not currentWeapon:isAimedFirearm() then return end

	if NPCUtils:haveAmmo(currentWeapon, self.character:getInventory()) then
		return true
	end

	return false
end

function NPC:isOkDist(sq)
	if not self.AI:isCommandFollow() and not self.AI:isCommandStayHere() then
        return true
    end
    if self.AI:isCommandFollow() and NPCUtils.getDistanceBetween(sq, getPlayer()) < 3 then
        return true
    end
    if self.AI:isCommandStayHere() and NPCUtils.getDistanceBetween(sq, self.AI.staySquare) < 2 then
        return true
    end
    return false
end

function NPC:getX()
	return self.character:getX()
end

function NPC:getY()
	return self.character:getY()
end

function NPC:getZ()
	return self.character:getZ()
end