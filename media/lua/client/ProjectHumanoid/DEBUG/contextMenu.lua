require("CommunityAPI")

local function spawnCompanion(playerObj, square, preset, IsPlayerTeam, respectToPlayer, groupCharacteristic)
    local npc = nil
    if IsPlayerTeam then
        npc = NPC:new(square, preset, AI.Type.PlayerGroupAI)
    else
        npc = NPC:new(square, preset, AI.Type.AutonomousAI)
    end

    if respectToPlayer == "Friendly" then
        npc.reputationSystem.playerRep = 600
    elseif respectToPlayer == "Hostile" then
        npc.reputationSystem.playerRep = -600
    else
        npc.reputationSystem.playerRep = 0
    end

    if groupCharacteristic == "Lonely" then
        npc.groupCharacteristic = "Lonely"
    elseif groupCharacteristic == "Group Guy" then
        npc.groupCharacteristic = "Group Guy"
    else
        npc.groupCharacteristic = "Normal"
    end
end

local function killAllNPC()
    for i, char in ipairs(NPCManager.characters) do
        char.character:Kill(char.character)
    end
end

---@param playerNum number
---@param context ISContextMenu
---@param worldobjects table
local function debugContextMenu(playerNum, context, worldobjects)
	local sq = nil
    local playerObj = getSpecificPlayer(playerNum)

    for _,v in ipairs(worldobjects) do
        local square = v:getSquare()
        if square then
            sq = square
            break
        end
    end
    
    if sq and CommunityAPI.Client.ModSetting.GetModSettingValue("ProjectHumanoid", "DebugContextMenu") then
        local spawnMenuOption = context:addOption("DEBUG NPC", nil, nil)
        local subMenuSpawn = context:getNew(context)
        context:addSubMenu(spawnMenuOption, subMenuSpawn)

        subMenuSpawn:addOption("Spawn Random - Player team", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), true)
        ---
        local autoMenuOption = subMenuSpawn:addOption("Spawn Random - Auto team")
        local autoSubMenu = subMenuSpawn:getNew(subMenuSpawn)
        subMenuSpawn:addSubMenu(autoMenuOption, autoSubMenu)

        --
        local friendMenuOption = autoSubMenu:addOption("Friendly")
        local friendSubMenu = autoSubMenu:getNew(autoSubMenu)
        autoSubMenu:addSubMenu(friendMenuOption, friendSubMenu)

        friendSubMenu:addOption("Lonely", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Friendly", "Lonely")
        friendSubMenu:addOption("Group Guy", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Friendly", "Group Guy")
        friendSubMenu:addOption("Normal", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Friendly", "Normal")
        --
        local hostileMenuOption = autoSubMenu:addOption("Hostile")
        local hostileSubMenu = autoSubMenu:getNew(autoSubMenu)
        autoSubMenu:addSubMenu(hostileMenuOption, hostileSubMenu)

        hostileSubMenu:addOption("Lonely", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Hostile", "Lonely")
        hostileSubMenu:addOption("Group Guy", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Hostile", "Group Guy")
        hostileSubMenu:addOption("Normal", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Hostile", "Normal")
        --
        local neutralMenuOption = autoSubMenu:addOption("Neutral")
        local neutralSubMenu = autoSubMenu:getNew(autoSubMenu)
        autoSubMenu:addSubMenu(neutralMenuOption, neutralSubMenu)

        neutralSubMenu:addOption("Lonely", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Neutral", "Lonely")
        neutralSubMenu:addOption("Group Guy", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Neutral", "Group Guy")
        neutralSubMenu:addOption("Normal", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(false), false, "Neutral", "Normal")        

        ---
        subMenuSpawn:addOption("Spawn Random - Raider team", playerObj, spawnCompanion, sq, NPCPresetSystem:getRandomPreset(true), false)
        
        subMenuSpawn:addOption("Kill all npc", playerObj, killAllNPC, sq)
    end
end
Events.OnFillWorldObjectContextMenu.Add(debugContextMenu)