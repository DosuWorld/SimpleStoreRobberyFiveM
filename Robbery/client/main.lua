stores = Config.stores

local isInsideStore = {}
local spawnedNPCs = {}
local hasTriggeredEvent = false

-- Server side event's
RegisterNetEvent("robbery:spawnNPCs")
RegisterNetEvent("robbery:Success")


Citizen.CreateThread(function()
    Wait(5000) -- Delay for 5 seconds (adjust as needed)
    TriggerEvent("robbery:spawnNPCs")
end)

AddEventHandler("robbery:spawnNPCs", function()
    print("Trying to spawn NPCs")

    for _, store in pairs(Config.stores) do
        local npcHash = GetHashKey("mp_m_shopkeep_01")
        local npcCoords = store.npcCoords

        RequestModel(npcHash)

        while not HasModelLoaded(npcHash) do
            print("Waiting for model to load...")
            Wait(500)
        end

        local npc = CreatePed(4, npcHash, npcCoords.x, npcCoords.y, npcCoords.z, 0.0, true, false)
        SetEntityHeading(npc, 0.0)
        SetBlockingOfNonTemporaryEvents(npc, true)  -- NPC won't flee

        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        table.insert(spawnedNPCs, {ped = npc, store = store})

        -- Create blip for the store
        local blip = AddBlipForCoord(store.blipCoords.x, store.blipCoords.y, store.blipCoords.z)

        -- Customize blip appearance
        SetBlipSprite(blip, 52)  -- You can customize the sprite as needed
        SetBlipColour(blip, 1)  -- You can customize the color as needed
        SetBlipScale(blip, 0.8)

        -- Set blip name
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(store.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Function to respawn an NPC for a given store
function RespawnNPC(storeName)
    -- Find the store in the spawnedNPCs table
    for _, storeData in pairs(spawnedNPCs) do
        if storeData.store.name == storeName then
            local store = storeData.store

            -- Request NPC model
            local npcHash = GetHashKey("mp_m_shopkeep_01")
            RequestModel(npcHash)

            -- Wait for the model to load
            while not HasModelLoaded(npcHash) do
                print("Waiting for model to load...")
                Wait(500)
            end

            -- Get NPC coordinates from the store configuration
            local npcCoords = store.npcCoords

            -- Create the NPC
            local npc = CreatePed(4, npcHash, npcCoords.x, npcCoords.y, npcCoords.z, 0.0, true, false)
            SetEntityHeading(npc, 0.0)
            SetBlockingOfNonTemporaryEvents(npc, true)  -- NPC won't flee

            -- Set NPC's scenario to "WORLD_HUMAN_STAND_IMPATIENT"
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

            -- Update the spawnedNPCs table with the new NPC information
            storeData.ped = npc
            break
        end
    end
end

function IsPlayerNearStore(playerCoords, store)
    return #(playerCoords - store.npcCoords) < store.detectionRadius
end

function IsPlayerAimingAtNPC(player, npc)
    local playerCoords = GetEntityCoords(player)
    local playerForward = GetEntityForwardVector(player)
    local npcCoords = GetEntityCoords(npc)

    local dir = npcCoords - playerCoords
    local angle =
        math.acos(
        (playerForward.x * dir.x + playerForward.y * dir.y + playerForward.z * dir.z) /
            (Vdist(0, 0, 0, dir.x, dir.y, dir.z))
    )

    -- You can adjust the angle threshold as needed
    return math.deg(angle) < 30.0
end

function startUI(time, text) 
    SendNUIMessage({
        type = "ui",
        display = true,
        time = time,
        text = text
    })
end

function Surrender(npc, storeName)
    print(npc)

    FreezeEntityPosition(npc, true)

    RequestAnimDict("random@mugging3")
    while not HasAnimDictLoaded("random@mugging3") do
        Wait(500)
    end

    TaskPlayAnim(npc, "random@mugging3", "handsup_standing_base", 8.0, -8.0, -1, 49, 0, false, false, false)
    Citizen.Wait(400)

    local timer = 10000
    startUI(timer, "Surrendering") -- Adjust the UI parameters

    while timer > 0 do
        Citizen.Wait(1000)
        timer = timer - 1000
    end

    TriggerServerEvent("robbery:Success", storeName)


end

Citizen.CreateThread(function()
    while true do
        local playerPed = GetPlayerPed(-1)
        local playerCoords = GetEntityCoords(playerPed)

        for _, storeData in pairs(spawnedNPCs) do
            local store = storeData.store
            local npc = storeData.ped
            local storeName = store.name

            if IsPlayerNearStore(playerCoords, store) then
                if not isInsideStore[storeName] then
                    isInsideStore[storeName] = true
                    print("Entered " .. storeName .. " store.")
                end

                    -- Check if player is aiming at the NPC and holding the right mouse button
                if IsControlPressed(0, 25) and IsPlayerAimingAtNPC(playerPed, npc) then
                    --print("Player is aiming at the NPC in " .. storeName .. " store.")

                    if not hasTriggeredEvent then
                        hasTriggeredEvent = true
                        Wait(40)
                        TriggerServerEvent("robbery:playerAimingAtNPC", storeName)
                   end
                else
                    --print("Player is not aiming at the NPC in " .. storeName .. " store.")
                end
            else
                if isInsideStore[storeName] then
                    isInsideStore[storeName] = false
                    print("Left " .. storeName .. " store.")
                end
            end
        end

        Citizen.Wait(500)
    end
end)

-- Robbery server called client event's
RegisterNetEvent("robberyStarted")      -- send a server request to update status to 0
RegisterNetEvent("robberyNotStarted")   -- If the status response is 0 trigered by server script
RegisterNetEvent("robberyEnded")        -- to reset ( hasTriggeredEvent = ture to false )

-- Based on SQL store -> status
AddEventHandler("robberyStarted", function(storeName)
    print("Robbery started at") 
    print(storeName)
    Wait(40)
    for _, storeData in pairs(spawnedNPCs) do
        if storeData.store.name == storeName then
            Surrender(storeData.ped, storeName)
        end
    end
end)
-- Based on SQL store -> status
AddEventHandler("robberyNotStarted", function()  
    print("Robbery not started")
    hasTriggeredEvent = false
end)

AddEventHandler("robberyEnded", function(storeName)

    print("Robbery ended at")
    print(storeName)
    local playerPed = GetPlayerPed(-1)

    for _, storeData in pairs(spawnedNPCs) do
        local store = storeData.store
        local npc = storeData.ped

        if store.name == storeName then
            if not IsEntityDead(npc) then
                -- NPC is alive, clear the tasks
                ClearPedTasks(npc)
                print("Cleared tasks for NPC in " .. storeName)
                Wait(400)
                FreezeEntityPosition(npc, false)
                TaskCombatPed(npc, playerPed, 0, 16)
                Wait(10000) -- respawn time
                SetEntityHealth(npc, 0)  -- kill the npc not a good solution its a quick one ;) 
                Wait(10000) -- one more wait time because why not 
                RespawnNPC(storeName)
            else

                print("NPC in " .. storeName .. " is already dead.") -- 
                RespawnNPC(storeName)
            end

            break  -- No need to continue searching once found
        end
    end

    hasTriggeredEvent = false
end)