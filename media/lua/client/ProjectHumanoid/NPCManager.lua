
require("CommunityAPI")
local SettingAPI = CommunityAPI.Client.ModSetting

local BUILD_VERSION = "v.0.2.5"
local DEBUG_TURN_OFF_SPAWN_NPC = false

NPCManager = {}
NPCManager.characters = {}
NPCManager.characterMap = nil

NPCManager.vehicleSeatChoose = {}  -- Need for enter vehicle by NPC (Follow task)
NPCManager.vehicleSeatChooseSquares = {}  -- Need for enter vehicle by NPC (Follow task)
NPCManager.openInventoryNPC = nil  -- NPC character that showed inventory
NPCManager.moodlesTimer = 0  -- Timer for show moodles
NPCManager.NPCInRadius = 0  -- Counter for num NPC in radius
NPCManager.spawnON = false  -- Variable to turn off NPC for spawn NPC only when game starts
NPCManager.isSaveLoadUpdateOn = false
NPCManager.characterBuffer = {}  -- Buffer for save NPC when sleep and restore them after
NPCManager.chooseSector = false  -- Set choosing sector state
NPCManager.sector = nil  -- Sector that choosed
NPCManager.pvpTurnOffTimer = 0  -- Timer for turn off PVP after some time after NPC start fight
NPCManager.pvpTurnedOn = false  -- Param to set PVP from Player
---
NPCManager.patrolNPC = nil
NPCManager.patrolChoose = false
NPCManager.isFarmingChoose = false
NPCManager.cutWoodChoose = false
NPCManager.forageChoose = false
NPCManager.collectCorpsesChoose = false
NPCManager.collectCorpsesStorageChoose = false

local lastFPSCheck = -1
function NPCManager:OnTickUpdate()
    if getPlayer():isDead() then return end

    for i, char in ipairs(NPCManager.characters) do
        char:update()

        if char.character:isDead() then
            local name = char.character:getDescriptor():getForename() .. " " .. char.character:getDescriptor():getSurname()
            if char.nickname then
                name = name .. "\"" .. char.nickname
            end
            NPCPrint(true,"NPCManager", "NPC dead", name, char.ID)
            --
            NPCManager.characterMap[char.ID] = nil
            table.remove(NPCManager.characters, i)  
            
            if NPCGroupManager:getGroupID(char.ID) ~= nil then
                NPCGroupManager:removeFromGroup(char.ID)
                return
            end
        end        
    end
    
    local fps = getAverageFPS()
    if fps ~= lastFPSCheck then
        NPCPrint(false, "NPCManager", "FPS:", fps)  
        lastFPSCheck = fps
    end
    NPCInsp("NPC", "NPC count", NPCManager.NPCInRadius)

    if NPCManager.pvpTurnOffTimer <= 0 then
        if IsoPlayer.getCoopPVP() and not NPCManager.pvpTurnedOn then
            IsoPlayer.setCoopPVP(false)
        end
    else
        NPCManager.pvpTurnOffTimer = NPCManager.pvpTurnOffTimer - 1
    end    
end
Events.OnTick.Add(NPCManager.OnTickUpdate)

--- Show player teammates NPC inventory for Player
local refreshBackpackTimer = 0
function NPCManager:InventoryUpdate()
    if getPlayer():isDead() then return end

    if refreshBackpackTimer <= 0 then
        refreshBackpackTimer = 60
        for i, char in ipairs(NPCManager.characters) do
            if not char.character:isDead() and char.AI:getType() == AI.Type.PlayerGroupAI then
                if NPCUtils.getDistanceBetween(char.character, getPlayer()) < 2 then
                    NPCManager.openInventoryNPC = char
                    ISPlayerData[1].lootInventory:refreshBackpacks()
                end
            end
        end
    else
        refreshBackpackTimer = refreshBackpackTimer - 1
    end
end
Events.OnTick.Add(NPCManager.InventoryUpdate)

NPCManager.hitPlayer = function(wielder, victim, weapon, damage)
    print("HERE")
    if instanceof(wielder, "IsoPlayer") and wielder:isNPC() and (victim == getPlayer() or (instanceof(victim, "IsoPlayer") and victim:isNPC() and victim:getModData().NPC.AI:getType() == AI.Type.PlayerGroupAI)) then
        for i, char in ipairs(NPCManager.characters) do
            if char.AI:getType() == AI.Type.PlayerGroupAI then
                char.reputationSystem.reputationList[wielder:getModData().NPC.ID] = -1000
                print("DICK")
            end
        end
    end

    if instanceof(victim, "IsoPlayer") and victim:isNPC() then
        local victimNPC = victim:getModData().NPC
        if wielder == getPlayer() and victimNPC.AI:getType() == AI.Type.PlayerGroupAI then
            return
        else
            victimNPC:getHit(wielder, weapon, damage)

            if wielder == getPlayer() then
                -- Phrase from NPC
                if victimNPC.reputationSystem:getPlayerRep() < 0 then
                    NPCDialogueSystem.SayDialoguePhrase(victimNPC, "angryWarning", 25, NPCColor.White)
                else
                    NPCDialogueSystem.SayDialoguePhrase(victimNPC, "friendWarning", 25, NPCColor.White)
                end             

                -- update rep for all group
                if NPCGroupManager:getGroupID(victimNPC.ID) ~= nil then
                    for _, npcID in ipairs(NPCGroupManager.Data.groups[NPCGroupManager:getGroupID(victimNPC.ID)].npcIDs) do
                        local char = NPCManager:getCharacter(npcID)
                        if char ~= nil then
                            char.reputationSystem:updatePlayerRep(-200)
                            char:SayNote("Reputation [img=media/ui/ArrowDown.png]", NPCColor.Red)
                        end
                    end
                else
                    victimNPC.reputationSystem:updatePlayerRep(-200)
                    victimNPC:SayNote("Reputation [img=media/ui/ArrowDown.png]", NPCColor.Red)
                end
            else
                local wielderNPC = wielder:getModData().NPC

                -- Phrase from NPC
                if victimNPC.reputationSystem:getNPCRep(wielderNPC) < 0 then
                    NPCDialogueSystem.SayDialoguePhrase(victimNPC, "angryWarning", 25, NPCColor.White)
                else
                    NPCDialogueSystem.SayDialoguePhrase(victimNPC, "friendWarning", 25, NPCColor.White)
                end

                -- update rep for all group
                if NPCGroupManager:getGroupID(victimNPC.ID) ~= nil then
                    for _, npcID in ipairs(NPCGroupManager.Data.groups[NPCGroupManager:getGroupID(victimNPC.ID)].npcIDs) do
                        local char = NPCManager:getCharacter(npcID)
                        if char ~= nil then
                            char.reputationSystem:updateNPCRep(-200, wielderNPC.ID)
                        end
                    end
                else
                    victimNPC.reputationSystem:updateNPCRep(-200, wielderNPC.ID)
                end
            end
        end
	end
end
Events.OnWeaponHitCharacter.Add(NPCManager.hitPlayer)

--- Save last hitted zombie for update rep when zombie is killed
local lastHittedZombie = nil
NPCManager.hitZombie = function(wielder, victim, weapon, damage)
    if instanceof(victim, "IsoZombie") and wielder == getPlayer() then
        lastHittedZombie = victim
    end
end
Events.OnWeaponHitCharacter.Add(NPCManager.hitZombie)

NPCManager.killZombie = function(zombie)
    if zombie == lastHittedZombie then
        for i, char in ipairs(NPCManager.characters) do
            if NPCUtils.getDistanceBetween(char.character, getPlayer()) < 10 then
                char.reputationSystem:updatePlayerRep(10)
                char:SayNote("Reputation [img=media/ui/ArrowUp.png]", NPCColor.Green)
            end
        end    
    end
end
Events.OnZombieDead.Add(NPCManager.killZombie)

NPCManager.onEnterVehicle = function(player)
    if player == getPlayer() then
        NPCManager.vehicleSeatChoose = {}
        NPCManager.vehicleSeatChooseSquares = {}
    end
end
Events.OnEnterVehicle.Add(NPCManager.onEnterVehicle)

--- Fix for weapon sound
NPCManager.onSwing = function(player, weapon)
    if player:getModData().NPC ~= nil then
        local range = weapon:getSoundRadius() 
        local volume = weapon:getSoundVolume()
        addSound(player, player:getX(), player:getY(), player:getZ(), range, volume)
        getSoundManager():PlayWorldSound(weapon:getSwingSound(), player:getCurrentSquare(), 0.5, range, 1.0, false)    
    end
end
Events.OnWeaponSwing.Add(NPCManager.onSwing)

NPCManager.choosingStaySquare = false
NPCManager.choosingStayNPC = nil
NPCManager.highlightSquare = function()
    if NPCManager.choosingStaySquare or NPCManager.patrolChoose or NPCManager.collectCorpsesStorageChoose then
        local z = getPlayer():getZ()
        local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
        local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
        if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
    end
    if NPCManager.chooseSector then
        if NPCManager.sector == nil then
            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
            local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
            if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
        else
            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)

            local t = nil
            local a = math.floor(x)
            local b = math.floor(NPCManager.sector.x1)
            if a > b then
                t = a
                a = b
                b = t                
            end
            
            local c = math.floor(y)
            local d = math.floor(NPCManager.sector.y1)
            if c > d then
                t = c
                c = d
                d = t                
            end

            for xx = a, b do
                for yy = c, d do
                    local sq = getCell():getGridSquare(xx, yy, z)
                    if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end        
                end
            end
        end
    end
end
Events.OnRenderTick.Add(NPCManager.highlightSquare)

NPCManager.onMouseDown = function()
    if NPCManager.choosingStaySquare then
        if NPCManager.choosingStayNPC then
            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
            local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
            if sq then
                NPCManager.choosingStayNPC.AI.staySquare = sq
                NPCManager.choosingStayNPC.AI.command = "STAY"
                NPCManager.choosingStayNPC = nil
            end
        end
        NPCManager.choosingStaySquare = false
    end

    if NPCManager.patrolChoose then
        local z = getPlayer():getZ()
        local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
        local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
        if sq and NPCManager.patrolNPC ~= nil then
            table.insert(NPCGroupManager.patrolPoints[NPCManager.patrolNPC.ID], {x = sq:getX(), y = sq:getY(), z = sq:getZ()})
        end
    end

    if NPCManager.collectCorpsesStorageChoose then
        local z = getPlayer():getZ()
        local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
        local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
        if sq then
            NPCGroupManager.collectCorpsesSector.xx = sq:getX()
            NPCGroupManager.collectCorpsesSector.yy = sq:getY()
            NPCGroupManager.collectCorpsesSector.zz = sq:getZ()
        end
        NPCManager.collectCorpsesStorageChoose = false
    end

    if NPCManager.chooseSector then
        if NPCManager.sector == nil then
            NPCManager.sector = {}
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
            NPCManager.sector.x1 = x
            NPCManager.sector.y1 = y 
            NPCManager.sector.z = getPlayer():getZ()
        else
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), getPlayer():getZ())
            NPCManager.sector.x2 = x
            NPCManager.sector.y2 = y  

            if NPCManager.sector.x1 > NPCManager.sector.x2 then
                local t = NPCManager.sector.x1
                NPCManager.sector.x1 = NPCManager.sector.x2
                NPCManager.sector.x2 = t
            end
            if NPCManager.sector.y1 > NPCManager.sector.y2 then
                local t = NPCManager.sector.y1
                NPCManager.sector.y1 = NPCManager.sector.y2
                NPCManager.sector.y2 = t
            end
            
            NPCManager.chooseSector = false

            if NPCManager.isBaseChoose then
                NPCGroupManager.playerBase.x1 = NPCManager.sector.x1
                NPCGroupManager.playerBase.y1 = NPCManager.sector.y1
                NPCGroupManager.playerBase.x2 = NPCManager.sector.x2
                NPCGroupManager.playerBase.y2 = NPCManager.sector.y2
                NPCManager.isBaseChoose = false
            elseif NPCManager.isFarmingChoose then
                NPCGroupManager.farmingSector.x1 = NPCManager.sector.x1
                NPCGroupManager.farmingSector.y1 = NPCManager.sector.y1
                NPCGroupManager.farmingSector.x2 = NPCManager.sector.x2
                NPCGroupManager.farmingSector.y2 = NPCManager.sector.y2
                NPCManager.isFarmingChoose = false
            elseif NPCManager.cutWoodChoose then
                NPCGroupManager.cutWoodSector.x1 = NPCManager.sector.x1
                NPCGroupManager.cutWoodSector.y1 = NPCManager.sector.y1
                NPCGroupManager.cutWoodSector.x2 = NPCManager.sector.x2
                NPCGroupManager.cutWoodSector.y2 = NPCManager.sector.y2
                NPCManager.cutWoodChoose = false
            elseif NPCManager.forageChoose then
                NPCGroupManager.forageSector.x1 = NPCManager.sector.x1
                NPCGroupManager.forageSector.y1 = NPCManager.sector.y1
                NPCGroupManager.forageSector.x2 = NPCManager.sector.x2
                NPCGroupManager.forageSector.y2 = NPCManager.sector.y2
                NPCManager.forageChoose = false
            elseif NPCManager.collectCorpsesChoose then
                NPCGroupManager.collectCorpsesSector.x1 = NPCManager.sector.x1
                NPCGroupManager.collectCorpsesSector.y1 = NPCManager.sector.y1
                NPCGroupManager.collectCorpsesSector.x2 = NPCManager.sector.x2
                NPCGroupManager.collectCorpsesSector.y2 = NPCManager.sector.y2
                NPCGroupManager.collectCorpsesSector.z = NPCManager.sector.z
                NPCManager.collectCorpsesChoose = false
                NPCManager.collectCorpsesStorageChoose = true
            end

            if NPCManager.isDropLootChoose then
                NPCGroupManager.dropLoot[NPCManager.isDropLootType] = {x1 = NPCManager.sector.x1, y1 = NPCManager.sector.y1, x2 = NPCManager.sector.x2, y2 = NPCManager.sector.y2, z = getPlayer():getZ()}
            end
        end
    end
end
Events.OnMouseDown.Add(NPCManager.onMouseDown)

NPCManager.onMouseRightDown = function()
    if NPCManager.patrolChoose then
        NPCManager.patrolChoose = false
        NPCManager.patrolNPC.AI.command = "PATROL"
        NPCManager.patrolNPC = nil
    end
end
Events.OnRightMouseDown.Add(NPCManager.onMouseRightDown)

function NPCManager.LoadGrid(square)
    if DEBUG_TURN_OFF_SPAWN_NPC then return end
    if NPCManager.spawnON and square:getZ() == 0 and square:getZoneType() == "TownZone" and not square:isSolid() and square:isFree(false) and ZombRand(5000) == 0 and NPCManager.NPCInRadius < SettingAPI.GetModSettingValue("ProjectHumanoid", "NPC_NUM") then
        NPC:new(square, NPCPresetSystem:getRandomPreset(ZombRand(0, 10) == 0), AI.Type.AutonomousAI)
        NPCManager.NPCInRadius = NPCManager.NPCInRadius + 1
    end
end
Events.LoadGridsquare.Add(NPCManager.LoadGrid)

function NPCManager.SaveLoadFunc()
    if NPCManager.isSaveLoadUpdateOn == false then return end

    for charID, value in pairs(NPCManager.characterMap) do
        if NPCManager.characterBuffer[charID] ~= nil then
            value.npc = NPCManager.characterBuffer[charID]
            value.isLoaded = true
            NPCManager.characterBuffer[charID] = nil
        end

        if value.isSaved == false and value.isLoaded then
            if NPCUtils.getDistanceBetween(getPlayer(), value.npc.character) > 60 then
                value.x = value.npc.character:getX()
                value.y = value.npc.character:getY()
                value.z = value.npc.character:getZ()

                value.npc:save()
                value.isSaved = true

                NPCPrint(true,"NPCManager", "NPC is saved (SaveLoadFunc)", charID, value.npc.character:getDescriptor():getSurname())
            end
        end

        if value.isLoaded == false then
            if NPCUtils.getDistanceBetweenXYZ(value.x, value.y, getPlayer():getX(), getPlayer():getY()) < 60 and getCell():getGridSquare(value.x, value.y, 0) ~= nil then
                for i, char in ipairs(NPCManager.characters) do
                    if value.npc and char.ID == value.npc.ID then
                        table.remove(NPCManager.characters, i)            
                    end
                end
                value.npc = NPC:load(charID, value.x, value.y, value.z)
                value.isLoaded = true
                value.isSaved = false
                NPCPrint(true,"NPCManager", "NPC is loaded (SaveLoadFunc)", charID, value.npc.character:getDescriptor():getSurname())
            end
        end

        if value.isLoaded == true and getCell():getGridSquare(value.npc.character:getX(), value.npc.character:getY(), 0) == nil then
            value.isLoaded = false
            for i, char in ipairs(NPCManager.characters) do
                if char.ID == value.npc.ID then
                    table.remove(NPCManager.characters, i)            
                end
            end
            value.npc = nil
            NPCPrint(true,"NPCManager", "NPC is unloaded (SaveLoadFunc)", charID)
        end
    end
end
Events.OnTick.Add(NPCManager.SaveLoadFunc)


function NPCManager.OnSave()
    for charID, value in pairs(NPCManager.characterMap) do
        if value.npc ~= nil then
            value.x = value.npc.character:getX()
            value.y = value.npc.character:getY()
            value.z = value.npc.character:getZ()

            value.npc:save()
            value.isSaved = true
            value.isLoaded = false
            
            NPCPrint(true,"NPCManager", "NPC is saved (OnSave)", charID, value.npc.character:getDescriptor():getSurname())

            NPCManager.characterBuffer[charID] = value.npc

            value.npc = nil
        end
    end

    NPCManager.isSaveLoadUpdateOn = false
end
Events.OnSave.Add(NPCManager.OnSave)

function NPCManager.OnGameStart()
    NPCPrint(true,"NPCManager", "OnGameStart", BUILD_VERSION)

    IsoPlayer.setCoopPVP(false)

    for charID, value in pairs(NPCManager.characterMap) do
        value.isLoaded = false
        if value.isLoaded == false and getCell():getGridSquare(value.x, value.y, value.z) ~= nil then
            value.npc = NPC:load(charID, value.x, value.y, value.z)
            value.isLoaded = true
            value.isSaved = false
                        
            if value.npc.character:getSquare() == nil then
                value.isLoaded = false
                for i, char in ipairs(NPCManager.characters) do
                    if char.ID == value.npc.ID then
                        table.remove(NPCManager.characters, i)            
                    end
                end
            else
                NPCPrint(true,"NPCManager", "NPC is loaded (OnGameStart)", charID, value.npc.character:getDescriptor():getSurname()) 
            end
        end
    end
    NPCManager.spawnON = true
    NPCManager.isSaveLoadUpdateOn = true
end
Events.OnGameStart.Add(NPCManager.OnGameStart)

function NPCManager.LoadGlobalModData()
    NPCManager.characterMap = ModData.getOrCreate("characterMap")

    NPCGroupManager.Data = ModData.getOrCreate("NPCGroups")
    if NPCGroupManager.Data.leaders == nil then
        NPCGroupManager.Data.leaders = {}   -- playerID = GroupID
        NPCGroupManager.Data.groups = {}    -- GroupID = {count, leader, {npcIDs}}
        NPCGroupManager.Data.characterGroup = {} -- playerID = GroupID
    end

    NPCGroupManager.playerBase = ModData.getOrCreate("NPCPlayerBase")
    NPCGroupManager.dropLoot = ModData.getOrCreate("NPCDropLoot")
    NPCGroupManager.farmingSector = ModData.getOrCreate("NPCfarmingSector")
    NPCGroupManager.cutWoodSector = ModData.getOrCreate("NPCcutWoodSector")
    NPCGroupManager.forageSector = ModData.getOrCreate("NPCforageSector")
    NPCGroupManager.collectCorpsesSector = ModData.getOrCreate("NPCcollectCorpsesSector")
    NPCGroupManager.patrolPoints = ModData.getOrCreate("NPCpatrolPoints")

    MeetSystem.Data = ModData.getOrCreate("MeetSystemData")
end
Events.OnInitGlobalModData.Add(NPCManager.LoadGlobalModData)

local countInRadiusNPCTimer = 0
function NPCManager.CountNPCInRadius()
    if countInRadiusNPCTimer <= 0 then
        countInRadiusNPCTimer = 60
        NPCManager.NPCInRadius = 0
        local x = getPlayer():getX()
        local y = getPlayer():getY()
        for _, value in pairs(NPCManager.characterMap) do
            if value.isLoaded and value.npc ~= nil then
                if NPCUtils.getDistanceBetweenXYZ(value.npc.character:getX(), value.npc.character:getY(), x, y) < 120 then
                    NPCManager.NPCInRadius = NPCManager.NPCInRadius + 1
                end 
            else
                if NPCUtils.getDistanceBetweenXYZ(value.x, value.y, x, y) < 120 then
                    NPCManager.NPCInRadius = NPCManager.NPCInRadius + 1
                end
            end
        end
    else
        countInRadiusNPCTimer = countInRadiusNPCTimer - 1
    end
end
Events.OnTick.Add(NPCManager.CountNPCInRadius)

function NPCManager:getCharacter(id)
    if NPCManager.characterMap[id] == nil then return nil end
    return NPCManager.characterMap[id].npc
end

local pointTimer = 0
function NPCManager:showNamesByMousePoint()
    if SettingAPI.GetModSettingValue("ProjectHumanoid", "HIDE_NAMES") then
        if pointTimer <= 0 then
            pointTimer = 30
            local charBySq = {}

            for i, npc in ipairs(NPCManager.characters) do
                local sq = npc.character:getSquare()
                if sq ~= nil then
                    charBySq[sq] = npc
                end
                npc.username:setShowName(false)
            end

            local z = getPlayer():getZ()
            local x, y = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), z)
            local sq = getCell():getGridSquare(math.floor(x), math.floor(y), z)
            if sq and sq:getFloor() then 
                if charBySq[sq] ~= nil then
                    charBySq[sq].username:setShowName(true)
                end
            end
        else
            pointTimer = pointTimer - 1
        end
    end
end
Events.OnTick.Add(NPCManager.showNamesByMousePoint)