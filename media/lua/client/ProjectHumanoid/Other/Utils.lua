---@class NPCUtils
NPCUtils = {}

function NPCUtils.UUID()
    local seed={'e','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb={}
    for i=1,32 do
        table.insert(tb,seed[ZombRand(16)+1])
    end
    local sid=table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(sid,1,8),
        string.sub(sid,9,12),
        string.sub(sid,13,16),
        string.sub(sid,17,20),
        string.sub(sid,21,32)
    )
end

function NPCUtils.getSafestSquare(character, rangeCoeff)
    local currentSquare = character:getSquare()
    local x = currentSquare:getX()
    local y = currentSquare:getY()
    local z = currentSquare:getZ()

    local sectors = {}
    sectors["A"] = 0
    sectors["B"] = 0
    sectors["C"] = 0
    sectors["D"] = 0
    sectors["E"] = 0
    sectors["F"] = 0
    sectors["G"] = 0
    sectors["H"] = 0

    local objects = character:getCell():getObjectList()
    local npc = character:getModData().NPC
    if(objects ~= nil) then
		for i=0, objects:size()-1 do
			local obj = objects:get(i);
			if obj ~= nil and obj ~= character and (instanceof(obj,"IsoZombie") or instanceof(obj,"IsoPlayer")) then
                local dist = NPCUtils.getDistanceBetween(character, obj)

				if not obj:isDead() and npc:isEnemy(obj) and z == obj:getSquare():getZ() and dist < 20 then
                    local sector = NPCUtils.getSector(x, y, obj:getSquare():getX(), obj:getSquare():getY())
                    sectors[sector] = sectors[sector] + 1
                end
            end
        end
    end

    local minCount = 999999
    local resultSectors = {"A"}
    for key, count in pairs(sectors) do
        if count < minCount then
            minCount = count
            resultSectors = {}
            table.insert(resultSectors, key)
        elseif count == minCount then
            table.insert(resultSectors, key)
        end
    end

    local shiftsForSectors = {}
    shiftsForSectors["A"] = {dx = 2, dy = 4}
    shiftsForSectors["B"] = {dx = 4, dy = 2}
    shiftsForSectors["C"] = {dx = 4, dy = -2}
    shiftsForSectors["D"] = {dx = 2, dy = -4}
    shiftsForSectors["E"] = {dx = -2, dy = -4}
    shiftsForSectors["F"] = {dx = -4, dy = -2}
    shiftsForSectors["G"] = {dx = -4, dy = 2}
    shiftsForSectors["H"] = {dx = -2, dy = 4}

	local c = -1
	local resSector = "A"
	for _, sec in ipairs(resultSectors) do
		if sectors[NPCUtils.getOppositeSector(sec)] > c then
			c = sectors[NPCUtils.getOppositeSector(sec)]
			resSector = sec
		end	
	end

    local sq = getSquare(x + shiftsForSectors[resSector].dx*rangeCoeff, y + shiftsForSectors[resSector].dy*rangeCoeff, z)
    if sq == nil or not sq:isFree(false) then
        sq = getSquare(x + shiftsForSectors[resSector].dx*rangeCoeff/2, y + shiftsForSectors[resSector].dy*rangeCoeff/2, z)
    end
    if sq == nil or not sq:isFree(false) then
        return nil
    end

    return sq
end

function NPCUtils.getOppositeSector(sector)
	local tab = {}
	tab["A"] = "E"
	tab["B"] = "F"
	tab["C"] = "G"
	tab["D"] = "H"
	tab["E"] = "A"
	tab["F"] = "B"
	tab["G"] = "C"
	tab["H"] = "D"
	return tab[sector]
end

function NPCUtils.getSector(x, y, x2, y2)
    local xx = x2 - x
    local yy = y2 - y

    if xx >= 0 and yy >= 0 then
        if yy > xx then
            return "A"
        else
            return "B"
        end
    elseif xx >= 0 and yy <= 0 then
        if xx > -yy then
            return "C"
        else
            return "D"
        end
    elseif xx <= 0 and yy >= 0 then
        if yy > -xx then
            return "H"
        else
            return "G"
        end
    else
        if -yy > -xx then
            return "E"
        else
            return "F"
        end
    end
end

function NPCUtils.getNearestWaterSourceInClusters(x, y, evalFunc)
    local result = nil
    local dist = 9999
    for _, cluster in ipairs(ScanSquaresSystem.clusters) do
        local xx, yy = cluster:getCenter()
        for xyz, sqData in pairs(cluster.points) do
            if sqData.data.water then
                local d = IsoUtils.DistanceTo(xx, yy, x, y)
                if d < dist then
                    local items = square:getObjects()
                    for j=0, items:size()-1 do
                        local item = items:get(j)
                        if item:hasWater() and evalFunc(item) then
                            dist = d
                            result = item
                        end
                    end        
                end
            end 
        end        
    end
    return result
end

function NPCUtils.getNearestWaterItemSquareInClusters(x, y)
    local evalFunc = function(item)
        if item:isWaterSource() and item:getType() ~= "Bleach" then
            return true
        end
        return false
    end
    
    local resultItem = nil
    local resultSquare = nil
    local dist = 9999
    for _, cluster in ipairs(ScanSquaresSystem.clusters) do
        for xyz, sqData in pairs(cluster.points) do
            local d = IsoUtils.DistanceTo(x, y, sqData.x, sqData.y)
            local square = getCell():getGridSquare(sqData.x, sqData.y, sqData.z)
            if sqData.data.containers and square ~= nil then
                local items = square:getObjects()
                for j=0, items:size()-1 do
                    local item = items:get(j)
                    for containerIndex = 1, item:getContainerCount() do
                        local container = item:getContainerByIndex(containerIndex-1)
                        local item2 = container:getFirstEvalRecurse(evalFunc)
                        if item2 and d < dist then
                            resultItem = item2
                            resultSquare = container:getSourceGrid()
                            dist = d
                        end               
                    end
                end	
            end   
            if sqData.data.worldObjects and square ~= nil then
                local items = square:getWorldObjects()
                for j=0, items:size()-1 do
                    local item = items:get(j):getItem()
                    if item then
                        if evalFunc(item) and d < dist then
                            resultItem = item
                            resultSquare = items:get(j):getSourceGrid()
                            dist = d    
                        else
                            if item:getCategory() == "Container" then
                                local item2 = item:getInventory():getFirstEvalRecurse(evalFunc)
                                if item2 and d < dist then
                                    resultItem = item2
                                    resultSquare = sq
                                    dist = d
                                end
                            end
                        end
                        
                    end
                end	
            end
            if sqData.data.deadBody and square ~= nil then
                local items = square:getDeadBodys()
                for j=0, items:size()-1 do
                    local body = items:get(j)
                    local container = body:getContainer()
                    local item = container:getFirstEvalRecurse(evalFunc)
                    if item and d < dist then
                        resultItem = item
                        resultSquare = sq
                        dist = d
                    end
                end	
            end
        end        
    end
    return resultItem, resultSquare
end


function NPCUtils.getItemsInSquare(evalFunc, sq)
	local resultItems = {}

	local objs = sq:getObjects()
	for j=0, objs:size()-1 do
		local obj = objs:get(j)
		for containerIndex = 1, obj:getContainerCount() do
			local container = obj:getContainerByIndex(containerIndex-1)
			local items = container:getAllEvalRecurse(evalFunc)
			for i=1, items:size() do
				local item = items:get(i-1)
				table.insert(resultItems, item)
			end
		end
	end	

	local wObjs = sq:getWorldObjects()
	for j=0, wObjs:size()-1 do
		local item = wObjs:get(j):getItem()
		if item then
			if evalFunc(item) then
				table.insert(resultItems, item)
			else
				if item:getCategory() == "Container" then
					local cItems = item:getInventory():getAllEvalRecurse(evalFunc)
					for i = 1, cItems:size() do
						local cItem = cItems:get(i-1)
						table.insert(resultItems, cItem)
					end
				end
			end
		end
	end	

	local bodys = sq:getDeadBodys()
	for j=0, bodys:size()-1 do
		if bodys:get(j):getContainer():getItems():size() > 0 then
			local items = bodys:get(j):getContainer():getAllEvalRecurse(evalFunc)
			for i=1, items:size() do
				table.insert(resultItems, items:get(i-1))
			end
		end
	end	

	return resultItems
end

function NPCUtils.getFreeFood(inv)
	local container = inv
	local foodTable = {}
    local items = container:getItems()
	
    for i=1, items:size() do
        local item = items:get(i-1)
        if item:getContainer() ~= nil and item:isEquipped() then
            local items2 = item:getContainer():getItems()
            for j=1, items2:size() do
                local item2 = items2:get(j-1)
                if(item2 ~= nil) and (item2:getCategory() == "Food") and not (item2:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item2:getType())) then
                    foodTable[item2] = 0
                end
            end
        else
            if(item ~= nil) and (item:getCategory() == "Food") and not (item:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType())) then
                foodTable[item] = 0
            end
        end
    end

    for item, score in pairs(foodTable) do
        local FoodType = item:getFoodType()
        if (FoodType == "NoExplicit") or (FoodType == nil) or (tostring(FoodType) == "nil") then
            score = score + 0
        elseif (FoodType == "Fruits") or (FoodType == "Vegetables") then 
            score = score + 2
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end
        elseif ((FoodType == "Egg") or (FoodType == "Meat")) or item:isIsCookable() then
            if(item:isCooked()) then score = score + 2 end
            if(item:isBurnt()) then score = score - 1 end
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end					
        end
        foodTable[item] = score
    end

    local tmpScore = -1
    local tmpItem = nil
	local tmpItem2 = nil
    for item, score in pairs(foodTable) do
        if score >= tmpScore then
            if tmpItem ~= nil then
				tmpItem2 = tmpItem
			end
			tmpItem = item
            tmpScore = score
        end
    end

	return tmpItem2
end

function NPCUtils.getDistanceBetween(z1,z2)
	if(z1 == nil) or (z2 == nil) then return -1 end
	
	local z1x = z1:getX();
	local z1y = z1:getY();
	local z2x = z2:getX();
	local z2y = z2:getY();

	return IsoUtils.DistanceTo(z1x, z1y, z2x, z2y)
end

function NPCUtils.getDistanceBetweenXYZ(x1,y1,x2,y2)
	return IsoUtils.DistanceTo(x1, y1, x2, y2)
end

function NPCUtils.getSaveDir()
    return Core.getMyDocumentFolder()..getFileSeparator().."Saves"..getFileSeparator().. getWorld():getGameMode() .. getFileSeparator() .. getWorld():getWorld().. getFileSeparator();
end

function NPCUtils.AdjacentFreeTileFinder_Find(gridSquare)
    local choices = {}
    local choicescount = 1;
    -- first try straight lines (N/S/E/W)
    local a = gridSquare:getAdjacentSquare(IsoDirections.W)
    local b = gridSquare:getAdjacentSquare(IsoDirections.E)
    local c = gridSquare:getAdjacentSquare(IsoDirections.N)
    local d = gridSquare:getAdjacentSquare(IsoDirections.S)

    -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then table.insert(choices, a); choicescount = choicescount + 1; end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then table.insert(choices, b); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then table.insert(choices, d); choicescount = choicescount + 1; end

    a = gridSquare:getAdjacentSquare(IsoDirections.NW)
	b = gridSquare:getAdjacentSquare(IsoDirections.NE)
	c = gridSquare:getAdjacentSquare(IsoDirections.SW)
	d = gridSquare:getAdjacentSquare(IsoDirections.SE)

	if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then  table.insert(choices, a); choicescount = choicescount + 1; end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then  table.insert(choices, b); choicescount = choicescount + 1;end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); choicescount = choicescount + 1;end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then  table.insert(choices, d); choicescount = choicescount + 1; end

    -- if we have multiple choices, pick the one closest to the player
    if choicescount > 1 then
        return choices[ZombRand(#choices-1)+1]
    else
        return choices[1]
    end
end

function NPCUtils.AdjacentFreeTileFinderSameOutside_Find(gridSquare)
    local isOutside = gridSquare:isOutside()

    local choices = {}
    local choicescount = 1;
    -- first try straight lines (N/S/E/W)
    local a = gridSquare:getAdjacentSquare(IsoDirections.W)
    local b = gridSquare:getAdjacentSquare(IsoDirections.E)
    local c = gridSquare:getAdjacentSquare(IsoDirections.N)
    local d = gridSquare:getAdjacentSquare(IsoDirections.S)

    -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) and isOutside == a:isOutside() then table.insert(choices, a); choicescount = choicescount + 1; end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) and isOutside == b:isOutside() then table.insert(choices, b); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) and isOutside == c:isOutside() then  table.insert(choices, c); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) and isOutside == d:isOutside() then table.insert(choices, d); choicescount = choicescount + 1; end

    a = gridSquare:getAdjacentSquare(IsoDirections.NW)
	b = gridSquare:getAdjacentSquare(IsoDirections.NE)
	c = gridSquare:getAdjacentSquare(IsoDirections.SW)
	d = gridSquare:getAdjacentSquare(IsoDirections.SE)

	if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) and isOutside == a:isOutside() then  table.insert(choices, a); choicescount = choicescount + 1; end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) and isOutside == b:isOutside()then  table.insert(choices, b); choicescount = choicescount + 1;end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) and isOutside == c:isOutside() then  table.insert(choices, c); choicescount = choicescount + 1;end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) and isOutside == d:isOutside() then  table.insert(choices, d); choicescount = choicescount + 1; end

    -- if we have multiple choices, pick the one closest to the player
    if choicescount > 1 then
        return choices[ZombRand(#choices-1)+1]
    else
        return choices[1]
    end
end

function NPCUtils.getNearestFreeSquare(obj, gridSquare, isInRoom)
    local choices = {}
    -- first try straight lines (N/S/E/W)
    local a = gridSquare:getAdjacentSquare(IsoDirections.W)
    local b = gridSquare:getAdjacentSquare(IsoDirections.E)
    local c = gridSquare:getAdjacentSquare(IsoDirections.N)
    local d = gridSquare:getAdjacentSquare(IsoDirections.S)

    -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then table.insert(choices, a); end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then table.insert(choices, b); end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then table.insert(choices, d); end

    a = gridSquare:getAdjacentSquare(IsoDirections.NW)
	b = gridSquare:getAdjacentSquare(IsoDirections.NE)
	c = gridSquare:getAdjacentSquare(IsoDirections.SW)
	d = gridSquare:getAdjacentSquare(IsoDirections.SE)

	if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then  table.insert(choices, a); end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then  table.insert(choices, b);end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); end
	if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then  table.insert(choices, d); end

    local dist = 99999
    local sq = nil
    for i, square in ipairs(choices) do
        local d = NPCUtils.getDistanceBetween(obj, square)
        if d < dist and (not isInRoom or NPCUtils.isInRoom(square)) then
            sq = square
            dist = d
        end
    end
    return sq
end

function NPCUtils.hasAnotherNPCOnSquare(square, char1)
    for i, char in ipairs(NPCManager.characters) do
        if square == char.character:getSquare() and char ~= char1 then
            return true
        end
    end
    return false
end

function NPCUtils.isInRoom(square)
    return square and (square:getRoom() ~= nil or square:isInARoom())
end

NPCUtils.FoodsToExlude = {"Bleach", "Cigarettes", "Antibiotics", "Teabag2" ,"Salt", "Pepper", "Cockroach", "Cricket", "DeadMouse", "DeadRat", "Worm", "GrassHopper"}
NPCUtils.FindAndReturnBestFood = function(container) 
	if not container then return nil end
	local foodTable = {}
    local items = container:getItems()
	
    for i=1, items:size() do
        local item = items:get(i-1)
        if item:getContainer() ~= nil and item:isEquipped() then
            local items2 = item:getContainer():getItems()
            for j=1, items2:size() do
                local item2 = items2:get(j-1)
                if(item2 ~= nil) and (item2:getCategory() == "Food") and not (item2:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item2:getType())) then
                    foodTable[item2] = 0
                end
            end
        else
            if(item ~= nil) and (item:getCategory() == "Food") and not (item:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType())) then
                foodTable[item] = 0
            end
        end
    end

    for item, score in pairs(foodTable) do
        local FoodType = item:getFoodType()
        if (FoodType == "NoExplicit") or (FoodType == nil) or (tostring(FoodType) == "nil") then
            score = score + 0
        elseif (FoodType == "Fruits") or (FoodType == "Vegetables") then 
            score = score + 2
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end
        elseif ((FoodType == "Egg") or (FoodType == "Meat")) or item:isIsCookable() then
            if(item:isCooked()) then score = score + 2 end
            if(item:isBurnt()) then score = score - 1 end
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end					
        end
        foodTable[item] = score
    end

    local tmpScore = -1
    local tmpItem = nil
    for item, score in pairs(foodTable) do
        if score > tmpScore then
            tmpItem = item
            tmpScore = score
        end
    end

	return tmpItem
end

NPCUtils.FindAndReturnBestFoodFromTable = function(items)
    local foodTable = {}

    for _, item in ipairs(items) do
        if(item ~= nil) and (item:getCategory() == "Food") and not (item:getPoisonPower() > 1) and (not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType())) then
            foodTable[item] = 0
        end
    end

    for item, score in pairs(foodTable) do
        local FoodType = item:getFoodType()
        if (FoodType == "NoExplicit") or (FoodType == nil) or (tostring(FoodType) == "nil") then
            score = score + 0
        elseif (FoodType == "Fruits") or (FoodType == "Vegetables") then 
            score = score + 2
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end
        elseif ((FoodType == "Egg") or (FoodType == "Meat")) or item:isIsCookable() then
            if(item:isCooked()) then score = score + 2 end
            if(item:isBurnt()) then score = score - 1 end
            if(item:IsRotten()) then score = score - 1 end
            if(item:isFresh()) then score = score + 1 end					
        end
        foodTable[item] = score
    end

    local tmpScore = -1
    local resFood = nil
    for item, score in pairs(foodTable) do
        if score > tmpScore then
            resFood = item
            tmpScore = score
        end
    end

    return resFood
end

function NPCUtils.tableHasValue(table, val)
    for i, v in ipairs(table) do
        if val == v then
            return true
        end
    end
    return false
end

function NPCUtils:getDoor(sq)
    if sq:getDoor(false) then return sq:getDoor(false) end
    return sq:getDoor(true)
end

function NPCUtils:evalIsFood(item)
    if item == nil then return false end

    if item:getCategory() == "Food" and not (item:getPoisonPower() > 1) and not NPCUtils.tableHasValue(NPCUtils.FoodsToExlude, item:getType()) then
        return true
    end

    if item:isWaterSource() then return true end

    return false
end

function NPCUtils:evalIsWeapon(item)
    if item == nil then return false end

    if item:getCategory() == "Weapon" and instanceof(item, "HandWeapon") and item:isAimedFirearm() or item:getCategory() == "WeaponPart" then
        return true
    end

    if item:getMaxAmmo() > 0 then return true end
    if item:getDisplayCategory() == "Ammo" then return true end

    return false
end

function NPCUtils:evalIsClothing(item)
    return item ~= nil and item:getCategory() == "Clothing"
end

local evalMedsList = {"Needle", "Thread", "SutureNeedle", "Splint", "SutureNeedleHolder", "PlantainCataplasm", "WildGarlicCataplasm", "ComfreyCataplasm", "Disinfectant", "Splint", "Splint", "Splint", }
function NPCUtils:evalIsMeds(item)
    if item == nil then return false end

    if ISInventoryPaneContextMenu.startWith(item:getType(), "Pills") then return true end   -- All Pills

    if item:isCanBandage() then return true end

    if NPCUtils.tableHasValue(evalMedsList, item:getType()) then return true end

    return false
end

function NPCUtils:evalIsBags(item)
    return item ~= nil and item:getCategory() == "Container"
end

function NPCUtils:evalIsMelee(item)
    if item == nil then return false end

    if item:getCategory() == "Weapon" and instanceof(item, "HandWeapon") and not item:isAimedFirearm() then return true end

    return false
end

function NPCUtils:evalIsLiterature(item)
    return item ~= nil and item:getCategory() == "Literature"
end

function NPCUtils:getBestMeleWeapon(container)
	local score = 0
	local bestItem = nil
	for j=1, container:getItems():size() do
		local item = container:getItems():get(j-1)
		if instanceof(item, "HandWeapon") and not item:isAimedFirearm() and not (item:getSwingAnim() == "Throw") and NPCUtils:getWeaponScore(item, container) > score and item:getCondition() > 1 then
			score = item:getScore(nil)
			bestItem = item
		end
	end

	return bestItem
end

function NPCUtils:getBestRangedWeapon(container)
	local score = 0
	local bestItem = nil
	for j=1, container:getItems():size() do
		local item = container:getItems():get(j-1)
		if instanceof(item, "HandWeapon") and item:isAimedFirearm() and NPCUtils:getWeaponScore(item, container) > score and NPCUtils:haveAmmo(item, container) and item:getCondition() > 1 then
			score = item:getScore(nil)
			bestItem = item
		end
	end
	return bestItem
end

function NPCUtils:getWeaponScore(weapon, container)
	local score = 0
	score = score + weapon:getCondition()
	if weapon:getCondition() <= 0 then
		score = -99999
	end
	
	if weapon:isAimedFirearm() then
		if(weapon:getMagazineType()) then
			if weapon:isContainsClip() then
				local ammoCount = container:getItemCountRecurse(weapon:getAmmoType())
				score = score + 10 + weapon:getCurrentAmmoCount() + ammoCount
			else
				local ammoCount = container:getItemCountRecurse(weapon:getAmmoType())
				local magazine = container:getFirstTypeRecurse(weapon:getMagazineType())
				if magazine == nil then
					score = -99999
				else
					score = score + 10 + magazine:getCurrentAmmoCount() + ammoCount
				end
			end
		else
			local ammoInGun = weapon:getCurrentAmmoCount()
			local ammoCount = container:getItemCountRecurse(weapon:getAmmoType())

			if ammoInGun == 0 and ammoCount == 0 then
				score = -99999
			else
				score = score + ammoInGun + ammoCount
			end
		end
	else
		score = score + weapon:getMaxDamage()*10
	end

	return score
end


function NPCUtils:getItemsOnFloor(evalFunc, sq)
	local resultItems = {}

	local wObjs = sq:getWorldObjects()
	for j=0, wObjs:size()-1 do
		local item = wObjs:get(j):getItem()
		if item then
			if evalFunc(item) then
				table.insert(resultItems, item)
			else
				if item:getCategory() == "Container" then
					local cItems = item:getInventory():getAllEvalRecurse(evalFunc)
					for i = 1, cItems:size() do
						local cItem = cItems:get(i-1)
						table.insert(resultItems, cItem)
					end
				end
			end
		end
	end	
	return resultItems
end

function table.contains(tbl, e)
    for _, v in pairs(tbl) do
        if v == e then
            return true
        end
    end

    return false
end

function table.copy(tbl)
    local t = {}

    for _, v in pairs(tbl) do
        table.insert(t, v)
    end

    return t
end

function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function NPCUtils:getNPCScore(npc)
    local score = 0
    
    score = score + (npc.character:getHealth()*100 - 80)

    local bestWeapon = NPCUtils:getBestWeapon(npc)
    score = score + bestWeapon:getMaxDamage()*10

    return score
end

function NPCUtils:getBestWeapon(npc)
    local melee = NPCUtils:getBestMeleWeapon(npc.character:getInventory())
    local firearm = NPCUtils:getBestRangedWeapon(npc.character:getInventory())

    local resultWeapon = melee
    if melee ~= nil and firearm ~= nil then
        if firearm:getMaxDamage() > melee:getMaxDamage() then
            resultWeapon = firearm
        end    
    elseif melee ~= nil then
    else
        resultWeapon = firearm
    end
    
    return resultWeapon
end

function NPCUtils:isGoodWeapon(character)
    if character == getPlayer() then
        return 1
    end

    local characterNPC = character:getModData().NPC

    local isGoodWeapon = 1                                   
    local currentWeapon = character:getPrimaryHandItem()
    if not instanceof(currentWeapon, "HandWeapon") then currentWeapon = nil end
    local meleWeapon = NPCUtils:getBestMeleWeapon(character:getInventory())
    local fireWeapon = NPCUtils:getBestRangedWeapon(character:getInventory())

    if currentWeapon == nil then
        if characterNPC:isUsingGun() then
            if fireWeapon ~= nil or meleWeapon ~= nil then
                isGoodWeapon = 0
            end
        else
            if meleWeapon ~= nil then
                isGoodWeapon = 0
            end
        end
    else
        if characterNPC:isUsingGun() then
            if fireWeapon ~= nil then
                if currentWeapon ~= fireWeapon then
                    isGoodWeapon = 0
                end
            elseif meleWeapon ~= nil then
                if currentWeapon ~= meleWeapon then
                    isGoodWeapon = 0
                end
            else
                isGoodWeapon = 0
            end
        else
            if meleWeapon ~= nil then
                isGoodWeapon = 0
            end
        end
    end

    return isGoodWeapon
end

function NPCUtils:haveAmmo(weapon, container)
    if weapon:getCurrentAmmoCount() > 0 then
        return true
    end

    if weapon:getMagazineType() then
        if NPCUtils:haveMagazineWithAmmo(container,  weapon:getMagazineType(), weapon) then
            return true
        end
    end

    if container:getItemCountRecurse(weapon:getAmmoType()) > 0 then
        return true
    end

    return false
end

function NPCUtils:haveAmmoForReload(weapon, container)
    if container:getItemCountRecurse(weapon:getAmmoType()) > 0 then
        return true
    end

    return false
end

function NPCUtils:haveMagazineWithAmmo(inv, magType, weapon)
    if weapon:isContainsClip() and weapon:getCurrentAmmoCount() > 0 then
        return true
    end
    
    local items = inv:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        if item:getFullType() == magType then
            if item:getCurrentAmmoCount() > 0 then
                return true
            end
        end
    end
    return false
end

function NPCUtils:needToHeal(character)
    local needToHeal = 1 - character:getBodyDamage():getOverallBodyHealth()/100.0              -- (from 0 to 1: 0-notneed, 1-isveryneed) // how much need to heal
    local hasInjury = false
    for i=0, character:getBodyDamage():getBodyParts():size()-1 do
        local bp = character:getBodyDamage():getBodyParts():get(i)
        if(bp:HasInjury()) and (bp:bandaged() == false) then
            hasInjury = true
            break
        end
    end
    if hasInjury then
       return needToHeal
    end
    return 0
end

function NPCUtils:getBestMagazine(weapon, inv)
    local items = inv:getItems()
    local maxAmmo = -1
    local mag = nil
    for i=0, items:size()-1 do
        local item = items:get(i)
        if item:getFullType() == weapon:getMagazineType() then
            if item:getCurrentAmmoCount() > maxAmmo then
                maxAmmo = item:getCurrentAmmoCount()
                mag = item
            end
        end
    end
    return mag
end