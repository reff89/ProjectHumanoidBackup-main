---@class Cluster
Cluster = {}
Cluster.__index = Cluster
Cluster.radius = 6

function Cluster:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.points = {}

    o.sumX = 0
    o.sumY = 0
    o.count = 0
    o.ID = NPCUtils.UUID()

	return o
end

function Cluster:getCenter()
    if self.count == 0 then return 0, 0 end
    return self.sumX / self.count, self.sumY / self.count
end

function Cluster:getX()
    return self.sumX / self.count
end

function Cluster:getY()
    return self.sumY / self.count
end

function Cluster:inRadius(x, y)
    local xx, yy = self:getCenter()
    if IsoUtils.DistanceTo(xx, yy, x, y) < Cluster.radius then
        return true
    end
    return false
end

function Cluster:addPoint(x, y, z, data)
    if self.points["X=" .. x .. "Y=" .. y .. "Z=" .. z] ~= nil then return end
    self.points["X=" .. x .. "Y=" .. y .. "Z=" .. z] = { ["x"] = x, ["y"] = y, ["z"] = z, ["data"] = data }

    self.sumX = self.sumX + x
    self.sumY = self.sumY + y
    self.count = self.count + 1
end

ScanSquaresSystem = {}
ScanSquaresSystem.clusters = {}
ScanSquaresSystem.windows = {}
ScanSquaresSystem.doors = {}

function ScanSquaresSystem.loadGridSquare(square)
    local sqx = square:getX()
    local sqy = square:getY()
    local sqz = square:getZ()
    
    --- Save door and window positions
    
    local window = square:getWindow()
    if window ~= nil then
        ScanSquaresSystem.windows["X=" .. sqx .. "Y=" .. sqy .. "Z=" .. sqz] = { x = sqx, y = sqy, z = sqz, obj = window }
    end

    local door = NPCUtils:getDoor(square)
    if door then
        ScanSquaresSystem.doors["X=" .. sqx .. "Y=" .. sqy .. "Z=" .. sqz] = { x = sqx, y = sqy, z = sqz, obj = door }
    end

    -----
    
    local data = ScanSquaresSystem.getInterestPointData(square)
    if data == nil then return end

    local settedInCluster = false
    for _, cluster in ipairs(ScanSquaresSystem.clusters) do
        if cluster:inRadius(sqx, sqy) then
            cluster:addPoint(sqx, sqy, sqz, data)
            settedInCluster = true
            break
        end      
    end

    if not settedInCluster then
        local cluster = Cluster:new()
        cluster:addPoint(sqx, sqy, sqz, data)
        table.insert(ScanSquaresSystem.clusters, cluster)
    end
end
Events.LoadGridsquare.Add(ScanSquaresSystem.loadGridSquare)

function ScanSquaresSystem.getInterestPointData(square)
    local data = {}
    local isUsefulSquare = false
    
    local items = square:getObjects()
    for j=0, items:size()-1 do
        local item = items:get(j)
        if item:hasWater() then
            data.water = true
            isUsefulSquare = true
        end
        if item:getContainerCount() > 0 then
            data.containers = true
            isUsefulSquare = true
        end
    end	

    items = square:getWorldObjects()
    for j=0, items:size()-1 do
        if(items:get(j):getItem()) then
            data.worldObjects = true
            isUsefulSquare = true
        end
    end	

    items = square:getDeadBodys()
    for j=0, items:size()-1 do
        if(items:get(j):getContainer():getItems():size() > 0) then
            data.deadBody = true
            isUsefulSquare = true
        end
    end	

    if not isUsefulSquare then return nil end

    return data
end

function ScanSquaresSystem.getNearestCluster(x, y, visitedClusters, evalFunc)
    local dist = 9999
    local nearestCluster = nil
    for _, cluster in ipairs(ScanSquaresSystem.clusters) do
        if visitedClusters[cluster.ID] == nil then
            local xx, yy = cluster:getCenter()
            local d = IsoUtils.DistanceTo(x, y, xx, yy)
            if d < dist and evalFunc(cluster) then
                dist = d
                nearestCluster = cluster
            end
        end
    end
    return nearestCluster
end

function ScanSquaresSystem.getNearestDoor(x, y, z, evalFunc)
    local dist = 9999
    local resultDoor = nil

    for xyz, doorData in pairs(ScanSquaresSystem.doors) do
        local d = IsoUtils.DistanceTo(x, y, doorData.x, doorData.y)
        if d < dist and doorData.z == z and doorData.obj:getSquare() ~= nil and evalFunc(doorData.obj) then
            dist = d
            resultDoor = doorData.obj
        end
    end
    return resultDoor
end

function ScanSquaresSystem.getNearestWindow(x, y, z, evalFunc)
    local dist = 9999
    local resultWindow = nil

    for xyz, windowData in pairs(ScanSquaresSystem.windows) do
        local d = IsoUtils.DistanceTo(x, y, windowData.x, windowData.y)
        if d < dist and windowData.z == z and windowData.obj:getSquare() ~= nil and evalFunc(windowData.obj) then
            dist = d
            resultWindow = windowData.obj
        end
    end
    return resultWindow
end

local clearTooFarWindowDoorTimer = 0
function ScanSquaresSystem.clearTooFarWindowDoor()
    if clearTooFarWindowDoorTimer <= 0 then
        clearTooFarWindowDoorTimer = 120

        local plX = getPlayer():getX()
        local plY = getPlayer():getY()
        for xyz, windowData in pairs(ScanSquaresSystem.windows) do
            local dToPlayer = IsoUtils.DistanceManhatten(plX, plY, windowData.x, windowData.y)
            if dToPlayer > 60 then
                ScanSquaresSystem.windows[xyz] = nil            
            end
        end

        for xyz, doorData in pairs(ScanSquaresSystem.doors) do
            local dToPlayer = IsoUtils.DistanceManhatten(plX, plY, doorData.x, doorData.y)
            if dToPlayer > 60 then
                ScanSquaresSystem.doors[xyz] = nil            
            end
        end
    else
        clearTooFarWindowDoorTimer = clearTooFarWindowDoorTimer - 1
    end
end