ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(250)
    end
end)

local easterEggs = {}
local isUIOpen = false
local currentEgg = nil
local eggBlips = {}
local eggProps = {}
local blipsVisible = false 

-- RegisterNetEvent('esx:playerLoaded')
-- AddEventHandler('esx:playerLoaded', function(xPlayer)
--     TriggerServerEvent('easter:requestSync')
-- end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        if LocalPlayer.playerLoaded then
            TriggerServerEvent('easter:requestSync')
            return
        end
    end
end)

RegisterNetEvent('easter:receiveEggs')
AddEventHandler('easter:receiveEggs', function(eggs)
    cleanupBlipsAndProps()
    easterEggs = eggs
    --createEggProps() 

    if blipsVisible then
        createEggBlips()
    end
end)

RegisterNetEvent('easter:syncEggs')
AddEventHandler('easter:syncEggs', function()
    TriggerServerEvent('easter:requestSync')
end)

RegisterNetEvent('easter:placeEgg')
AddEventHandler('easter:placeEgg', function(poemId)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('easter:saveEgg', coords, poemId)
end)

RegisterNetEvent('easter:eggCollected')
AddEventHandler('easter:eggCollected', function(eggId)
    for i, egg in ipairs(easterEggs) do
        if egg.id == eggId then
            easterEggs[i].collected = 1
            
            if blipsVisible and eggBlips[eggId] then
                SetBlipSprite(eggBlips[eggId], 143)
                SetBlipColour(eggBlips[eggId], 2)
            end
            
            -- if eggProps[eggId] and DoesEntityExist(eggProps[eggId]) then
            --     DeleteEntity(eggProps[eggId])
            --     eggProps[eggId] = nil
            -- end
            
            local eggCoords = vector3(egg.x, egg.y, egg.z)
            RequestNamedPtfxAsset("scr_easter_hunt")
            while not HasNamedPtfxAssetLoaded("scr_easter_hunt") do
                Citizen.Wait(10)
            end
            UseParticleFxAsset("scr_easter_hunt")
            StartParticleFxLoopedAtCoord("scr_egg_collected", eggCoords.x, eggCoords.y, eggCoords.z + 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            
            break
        end
    end

    ExecuteCommand('osterfortschritt')
end)

function createEggBlips()
    for _, egg in ipairs(easterEggs) do
        local eggCoords = vector3(egg.x, egg.y, egg.z)

        local blip = AddBlipForCoord(eggCoords)
        SetBlipSprite(blip, egg.collected == 1 and 143 or 432)
        SetBlipColour(blip, egg.collected == 1 and 2 or 1)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(egg.label or "Osterei")
        EndTextCommandSetBlipName(blip)
        eggBlips[egg.id] = blip
    end
end

function toggleBlips()
    if blipsVisible then
        for _, blip in pairs(eggBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        eggBlips = {}
        blipsVisible = false
    else
        createEggBlips()
        blipsVisible = true
    end
end

RegisterCommand('toggleeasterblips', function()
    ESX.TriggerServerCallback('easter:isPlayerAdmin', function(isAdmin)
        if isAdmin then
            toggleBlips()
            
            local statusMsg = blipsVisible and "Ostereier-Blips aktiviert" or "Ostereier-Blips deaktiviert"
            ESX.ShowNotification(statusMsg)
        else
            ESX.ShowNotification("Du hast keine Berechtigung für diesen Befehl!")
        end
    end)
end, false)

function cleanupBlipsAndProps()
    for _, blip in pairs(eggBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    eggBlips = {}
    
    for _, prop in pairs(eggProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    eggProps = {}
    
    --blipsVisible = false 
end

local isInteractingWithEgg = false

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if #easterEggs > 0 and not isInteractingWithEgg then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local closestEgg = nil
            local minDistance = 75.0
            
            for _, egg in ipairs(easterEggs) do
                if egg.collected == 0 then
                    local eggCoords = vector3(egg.x, egg.y, egg.z)
                    local dist = #(playerCoords - eggCoords)
                    
                    if dist < 75.0 then
                        sleep = 0
                        
                        local eggId = egg.id or 0
                        local colorIndex = eggId % 4
                        local r, g, b = 255, 255, 255
                        
                        if colorIndex == 0 then     
                            r, g, b = 255, 182, 193
                        elseif colorIndex == 1 then  
                            r, g, b = 173, 216, 230
                        elseif colorIndex == 2 then  
                            r, g, b = 255, 255, 180
                        else                        
                            r, g, b = 152, 251, 152
                        end
                        
                        DrawMarker(
                            1, 
                            eggCoords.x, eggCoords.y, eggCoords.z - 0.85, 
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.7, 0.7, 0.1, 
                            120, 60, 10, 180, 
                            false, false, 2,
                            nil, nil, false
                        )
                        
                        DrawMarker(
                            25, 
                            eggCoords.x, eggCoords.y, eggCoords.z - 0.80,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.72, 0.72, 0.05, 
                            139, 69, 19, 180, 
                            false, false, 2,
                            nil, nil, false
                        )
                        
                        for i = 1, 16 do
                            local angle = (i / 16) * math.pi * 2
                            local radius = 0.28 + (i % 4) * 0.05 
                            local xOffset = math.cos(angle) * radius
                            local yOffset = math.sin(angle) * radius
                            local zHeight = -0.65 + (i % 3) * 0.02 
                            
                            if i % 2 == 0 then
                                DrawMarker(
                                    9,
                                    eggCoords.x + xOffset, eggCoords.y + yOffset, eggCoords.z + zHeight,
                                    0.0, 0.0, 0.0,
                                    90.0 + (i * 10), 0.0, 0.0, 
                                    0.03, 0.03, 0.15, 
                                    50, 205, 50, 150, 
                                    false, false, 2,
                                    nil, nil, false
                                )
                            else
                                DrawMarker(
                                    9,
                                    eggCoords.x + xOffset, eggCoords.y + yOffset, eggCoords.z + zHeight,
                                    0.0, 0.0, 0.0,
                                    90.0 - (i * 10), 0.0, 0.0,
                                    0.02, 0.02, 0.12,
                                    210, 180, 140, 150, 
                                    false, false, 2,
                                    nil, nil, false
                                )
                            end
                        end
                        
                        local dx = playerCoords.x - eggCoords.x
                        local dy = playerCoords.y - eggCoords.y
                        local heading = (math.atan2(dy, dx) * 180 / math.pi) - 90.0 
                        
                        DrawMarker(
                            28, 
                            eggCoords.x, eggCoords.y, eggCoords.z - 0.30, 
                            0.0, 0.0, 0.0, 
                            0.0, heading, 0.0, 
                            0.4, 0.3, 0.4, 
                            r, g, b, 200,
                            true, false, 2,
                            nil, nil, false
                        )

                        for i = 1, 5 do
                            local dotAngle = (i / 5) * math.pi * 2 + (heading * math.pi / 180)
                            local xOffset = math.cos(dotAngle) * 0.15
                            local yOffset = math.sin(dotAngle) * 0.15
                            
                            DrawMarker(
                                20, 
                                eggCoords.x + xOffset, eggCoords.y + yOffset, eggCoords.z - 0.30,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                0.04, 0.04, 0.04, 
                                255 - r, 255 - g, 255 - b, 200, 
                                false, false, 2,
                                nil, nil, false
                            )
                        end
                        
                        if dist < 15.0 then
                            DrawLightWithRange(
                                eggCoords.x, eggCoords.y, eggCoords.z - 0.25,
                                r/255, g/255, b/255,
                                0.85, 0.4 
                            )
                        end
                    end
                    
                    if dist < minDistance then
                        minDistance = dist
                        closestEgg = egg
                    end
                end
            end
            
            if closestEgg and not isUIOpen then
                sleep = 0
                if minDistance < 1.5 then
                    displayHelpText("Drücke ~INPUT_CONTEXT~ um das Osterei zu untersuchen")
                    
                    if IsControlJustReleased(0, 38) then 
                        isInteractingWithEgg = true 
                        openEggUI(closestEgg)
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

function displayHelpText(text)
    TriggerEvent('showHelp', text)
end

function openEggUI(egg)
    isUIOpen = true
    isInteractingWithEgg = true 
    currentEgg = egg
    
    ESX.TriggerServerCallback('easter:getPoem', function(poem)
        if poem then
            SendNUIMessage({
                type = "openEgg",
                eggId = egg.id,
                poemStart = poem.poem_start
            })
            SetNuiFocus(true, true)
        end
    end, egg.poem_id)
end

RegisterNUICallback('submitPoem', function(data, cb)
    if currentEgg then
        TriggerServerEvent('easter:checkPoem', currentEgg.id, data.answer)
    end
    closeUI()
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    closeUI()
    cb('ok')
end)

function closeUI()
    isUIOpen = false
    isInteractingWithEgg = false 
    currentEgg = nil
    SendNUIMessage({
        type = "closeEgg"
    })
    SetNuiFocus(false, false)
end

RegisterCommand('osterfortschritt', function()
    ESX.TriggerServerCallback('easter:getProgress', function(collected, total)
        if collected and total then
            ESX.ShowNotification('Du hast ' .. collected .. ' von ' .. total .. ' Ostereiern gefunden!')
        end
    end)
end, false)

Citizen.CreateThread(function()
    RequestNamedPtfxAsset("scr_easter_hunt")
    while not HasNamedPtfxAssetLoaded("scr_easter_hunt") do
        Citizen.Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupBlipsAndProps()
    end
end)

RegisterNetEvent('easter:showLeaderboard')
AddEventHandler('easter:showLeaderboard', function(leaderboardData)
    SendNUIMessage({
        type = "showLeaderboard",
        leaderboard = leaderboardData
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeLeaderboard', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Admin stuff
local display = false

RegisterNetEvent('easter:openStatsUI')
AddEventHandler('easter:openStatsUI', function(playersData)
    display = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openStats",
        players = playersData
    })
end)

RegisterNUICallback('closeUI', function(data, cb)
    display = false
    SetNuiFocus(false, false)
    cb('ok')
end)