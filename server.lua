math.randomseed(os.time())
local safeCooldowns = {}

local stores = Config.stores

Citizen.CreateThread(function()
    while true do 
        Wait(1000)
        if #safeCooldowns >= 1 then 
            for i = 1, #safeCooldowns do 
                safeCooldowns[i].seconds = safeCooldowns[i].seconds - 1 
                if(safeCooldowns[i].seconds <= 0 ) then 
                    safeCooldowns[i].seconds = 60
                    safeCooldowns[i].mins = safeCooldowns[i].mins - 1
                    if (safeCooldowns[i].mins <= 0) then 
                        table.remove(safeCooldowns,i)
                    end
                end
            end
        end
    end
end)

local isSafeOnCooldown = function(safeId)
    for i = 1, #safeCooldowns do 
        if safeCooldowns[i].safeId == safeId then 
            return true, safeCooldowns[i].robber
        end
    end
    return false
end

local removeSafeCooldown = function(safeId)
    for i = 1, #safeCooldowns do 
        if safeCooldowns[i].safeId == safeId then 
            table.remove(safeCooldowns,i)
        end
    end
end

local getThreeRandomNumbers = function()
    local first = math.random(1,5)
    local second = math.random(3,8)
    local third = math.random(5,15)
    return first,second,third
end

local getNumberOfRobbedStores = function()
    return #safeCooldowns
end

local getSafeRemainingMinutes = function(safeId)
    for i = 1, #safeCooldowns do 
        if safeCooldowns[i].safeId == safeId then 
            return safeCooldowns[i].mins
        end
    end
end


local getSafeCoords = function(safeId)
    for i = 1,#stores do 
        if i == safeId then 
            return stores[i]
        end
    end
end

local setSafeOnCooldown = function(safeId, user_id)
    table.insert(safeCooldowns,{ robber = user_id, safeId = safeId, mins = Config.robberyCooldown, seconds = 60, coords = getSafeCoords(safeId)})
end



RegisterNetEvent('trySR', function(safeId)
    local user_id = vRP.getUserId({source})
  
    if (isSafeOnCooldown(safeId)) then return vRPclient.notify(source,{'~r~Cooldown: ' .. getSafeRemainingMinutes(safeId) .. ' minute'}) end;
    if(getNumberOfRobbedStores() >= Config.maxRobberiesActive) then vRPclient.notify(source,{'~r~Prea multe jafuri in desfasurare!'}) return end
    setSafeOnCooldown(safeId)
    local f,s,t = getThreeRandomNumbers()
    Citizen.SetTimeout(1000 * 10, function()
        local safeCoords = getSafeCoords(safeId)
        TriggerClientEvent('blipSR',-1,safeId,safeCoords,false)

        local users = vRP.getUsers()
        for user_id,source in pairs(users) do
             
            for k,v in pairs(Config.lawFactions) do 
                if v:lower() == (vRP.getUserFaction{user_id}):lower() then 
                    TriggerClientEvent('chatMessage',source,'^1ALERTA^0: Un magazin este jefuit chiar acum!')
                end
            end
            
          
        end
    end)   

    TriggerClientEvent('startSR', source,safeId,{f,s,t},5)
    vRPclient.notify(source,{'~g~Ai inceput un jaf!'})
end)

RegisterNetEvent('cancelSR', function(safeId)
    removeSafeCooldown(safeId)
end)

RegisterNetEvent('checkSR', function(safeId,result)
    local player = source
    local safeCoords = getSafeCoords(safeId)
    vRPclient.teleport(player,{safeCoords[1],safeCoords[2],safeCoords[3]})

    local user_id = vRP.getUserId{player}

    local _, robber = isSafeOnCooldown(safeId)


    if result and robber == user_id then 
        local user_id = vRP.getUserId{player}

        if Config.robberySuccesReward.name == 'dirty_money' then 
            vRP.giveInventoryItem{user_id, 'dirty_money',math.random( Config.robberySuccesReward.amount[1],  Config.robberySuccesReward.amount[2]),true}
        end

        if Config.robberySuccesReward.name == 'wallet' then 
            vRP.giveMoney{user_id, math.random( Config.robberySuccesReward.amount[1],  Config.robberySuccesReward.amount[2])}
        end

         if Config.robberySuccesReward.name ~= 'wallet' and  Config.robberySuccesReward.name ~= 'dirty_money' then 
            vRP.giveInventoryItem{user_id, Config.robberySuccesReward.name ,math.random( Config.robberySuccesReward.amount[1],  Config.robberySuccesReward.amount[2]),true}
         end
    else
        vRPclient.notify(player,{'~r~Ai esuat jaful!'})
    end
end)

AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
    local source = source
    if first_spawn then 
        TriggerClientEvent('initblipsSR', source, #stores)
    end
end)