NPCPrintSystem = {}
NPCPrintSystem.fileWriter = nil
local isPrintOn = true  -- Turn On/Off print

--- Debug NPC print
---@param category string
function NPCPrint(printToConsole, category, a, b, c, d, e, f, g, h, j, k)
    if isPrintOn and printToConsole then
        if b == nil then
            print("NPCPrint: [" .. category .. "] ", a)
        elseif c == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b)
        elseif d == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c)
        elseif e == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d)
        elseif f == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d, ", ", e)
        elseif g == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f)
        elseif h == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g)
        elseif j == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g, ", ", h)
        elseif k == nil then
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g, ", ", h, ", ", j)
        else
            print("NPCPrint: [" .. category .. "] ", a, ", ", b, ", ", c, ", ", d, ", ", e, ", ", f, ", ", g, ", ", h, ", ", j, ", ", k)
        end
    end

    ----
    if NPCPrintSystem.fileWriter ~= nil then
        if b == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. "\n")
        elseif c == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. "\n")
        elseif d == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. "\n")
        elseif e == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. "\n")
        elseif f == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. ", " .. e .. "\n")
        elseif g == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. ", " .. e .. ", " .. f .. "\n")
        elseif h == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. ", " .. e .. ", " .. f .. ", " .. g .. "\n")
        elseif j == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. ", " .. e .. ", " .. f .. ", " .. g .. ", " .. h .. "\n")
        elseif k == nil then
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. ", " .. e .. ", " .. f .. ", " .. g .. ", " .. h .. ", " .. j .. "\n")
        else
            NPCPrintSystem.fileWriter:write("[" .. category .. "] " .. a .. ", " .. b .. ", " .. c .. ", " .. d .. ", " .. e .. ", " .. f .. ", " .. g .. ", " .. h .. ", " .. j .. ", " .. k .. "\n")
        end
    end
end

function NPCPrintSystem.OnGameStart()
    if NPCPrintSystem.fileWriter == nil then
        NPCPrintSystem.fileWriter = getFileWriter("ProjectHumanoidLog.txt", true, false)
    end
end

Events.OnGameStart.Add(NPCPrintSystem.OnGameStart)