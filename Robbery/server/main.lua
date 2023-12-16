stores = Config.stores

RegisterServerEvent('robbery:spawnNPCs')
RegisterServerEvent('robbery:playerAimingAtNPC')
RegisterServerEvent('robbery:Success')

function RespawnNPC(storeName)
    local store = nil
    for _, storeData in pairs(Config.stores) do
        if storeData.name == storeName then
            store = storeData
            break
        end
    end

    if store then
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

        return npc
    end

    return nil
end

-- Function to get store status from the database
function GetStoreStatus(storeName)
    local result = MySQL.Sync.fetchScalar("SELECT status FROM shoplocations WHERE name = @storeName", {
        ['@storeName'] = storeName
    })

    return result
end
-- Function to update the store status to 0 after robbery todo: change it back after 3 minutes
function UpdateShopStatus(storeName, status)
    local query = "UPDATE shoplocations SET status = 1 WHERE name = ?"
    
    MySQL.Async.execute(query, {status, storeName}, function(affectedRows)
        print("Updated shop status for " .. storeName)

        -- Schedule a function to change the status back after 3 minutes (3000 milliseconds per second)
        Citizen.Wait(1 * 60 * 1000)  -- 3 minutes in milliseconds

        local newStatus = 0  -- Set the status back to 0 after the delay
        MySQL.Async.execute(query, {newStatus, storeName}, function(affectedRows)
            print("Changed shop status back for " .. storeName)
        end)
    end)
end


AddEventHandler('robbery:playerAimingAtNPC', function(storeName)
    local storeStatus = GetStoreStatus(storeName)  

    if storeStatus == '0' then
        TriggerClientEvent('robberyStarted', -1, storeName)
    elseif storeStatus == '1' then
        TriggerClientEvent('robberyNotStarted', -1, storeName)
    end
end)


AddEventHandler('robbery:Success', function(storeName) 
    local newStatus = 1
    UpdateShopStatus(storeName, newStatus)
    -- give xPlayer money or item
    Wait(300)
    TriggerClientEvent('robberyEnded', -1, storeName)
end)