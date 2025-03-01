-- TEMP PLACEHOLDER FOR COMMUNITY API

CommunityAPI = {}
CommunityAPI.Client = {}
CommunityAPI.Client.ModSetting = {}


function CommunityAPI.Client.ModSetting.GetModSettingValue(modID, settingName)
    if settingName == "DebugContextMenu" then return true end
    if settingName == "NPC_NEED_FOOD" then return true end
    if settingName == "NPC_CAN_INFECT" then return true end
    if settingName == "NPC_NEED_AMMO" then return true end
    if settingName == "RADIAL_MENU_KEY" then return Keyboard.KEY_TAB end
    if settingName == "HIDE_NAMES" then return false end
    if settingName == "NPC_NUM" then return 3 end
end