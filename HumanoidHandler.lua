--[[
    HumanoidHandler Module
    Part of LSCommons Library
    Version: 1.0
    
    Efficient player and NPC detection/storage system
    with automatic cache management and validation
]]

local HumanoidHandler = {}

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService")
}

-- Cache System
local Cache = {
    Players = {},
    NPCs = {},
    LastUpdate = 0,
    UpdateInterval = 0.5, -- Half second refresh rate
    Connections = {}
}

-- Validation Functions
function HumanoidHandler.isValidHumanoid(model)
    if not model then return false end
    
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid or not humanoid:IsA("Humanoid") then return false end
    
    return humanoid.Health > 0 
        and model:FindFirstChild("Head") 
        and model:FindFirstChild("HumanoidRootPart")
end

function HumanoidHandler.getHumanoidName(model)
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    return humanoid.DisplayName ~= "" and humanoid.DisplayName or humanoid.Name
end

-- Player Management
function HumanoidHandler.setupPlayerTracking()
    -- Clear existing player cache
    table.clear(Cache.Players)
    
    -- Add existing players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        Cache.Players[player.Name] = player
    end
    
    -- Track new players
    Cache.Connections.PlayerAdded = Services.Players.PlayerAdded:Connect(function(player)
        Cache.Players[player.Name] = player
    end)
    
    -- Remove leaving players
    Cache.Connections.PlayerRemoving = Services.Players.PlayerRemoving:Connect(function(player)
        Cache.Players[player.Name] = nil
    end)
end

-- NPC Management
function HumanoidHandler.updateNPCCache()
    local currentTime = tick()
    if currentTime - Cache.LastUpdate < Cache.UpdateInterval then
        return Cache.NPCs
    end
    
    local newCache = {}
    
    -- Scan workspace for humanoids
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Humanoid") then
            local model = instance.Parent
            
            -- Validate and ensure it's not a player
            if HumanoidHandler.isValidHumanoid(model) and not Services.Players:GetPlayerFromCharacter(model) then
                local npcName = HumanoidHandler.getHumanoidName(model)
                if npcName then
                    newCache[npcName] = model
                end
            end
        end
    end
    
    Cache.NPCs = newCache
    Cache.LastUpdate = currentTime
    return Cache.NPCs
end

-- Public Interface
function HumanoidHandler.getPlayers()
    local players = {}
    for _, player in pairs(Cache.Players) do
        if player.Character and HumanoidHandler.isValidHumanoid(player.Character) then
            table.insert(players, player)
        end
    end
    return players
end

function HumanoidHandler.getNPCs()
    return HumanoidHandler.updateNPCCache()
end

function HumanoidHandler.getAllHumanoids()
    local humanoids = {}
    
    -- Add valid players
    for _, player in pairs(HumanoidHandler.getPlayers()) do
        table.insert(humanoids, player.Character)
    end
    
    -- Add NPCs
    for _, npc in pairs(HumanoidHandler.getNPCs()) do
        table.insert(humanoids, npc)
    end
    
    return humanoids
end

-- Utility Functions
function HumanoidHandler.getClosestHumanoid(position, maxDistance)
    maxDistance = maxDistance or math.huge
    local closest = nil
    local shortestDistance = maxDistance
    
    for _, model in ipairs(HumanoidHandler.getAllHumanoids()) do
        local distance = (position - model:GetPivot().Position).Magnitude
        if distance < shortestDistance then
            closest = model
            shortestDistance = distance
        end
    end
    
    return closest, shortestDistance
end

function HumanoidHandler.getHumanoidsInRadius(position, radius)
    local inRadius = {}
    
    for _, model in ipairs(HumanoidHandler.getAllHumanoids()) do
        local distance = (position - model:GetPivot().Position).Magnitude
        if distance <= radius then
            table.insert(inRadius, {
                Model = model,
                Distance = distance
            })
        end
    end
    
    -- Sort by distance
    table.sort(inRadius, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return inRadius
end

-- Debug Functions
function HumanoidHandler.debugPrint()
    print("=== HumanoidHandler Debug ===")
    
    -- Player info
    local players = HumanoidHandler.getPlayers()
    print(string.format("Active Players: %d", #players))
    for _, player in ipairs(players) do
        print(string.format("Player: %s (Character: %s)", 
            player.Name,
            player.Character and "Valid" or "Invalid"
        ))
    end
    
    -- NPC info
    local npcs = HumanoidHandler.getNPCs()
    local npcCount = 0
    print("\nActive NPCs:")
    for name, model in pairs(npcs) do
        npcCount = npcCount + 1
        local humanoid = model:FindFirstChild("Humanoid")
        print(string.format("NPC: %s (Health: %d/%d)", 
            name,
            humanoid.Health,
            humanoid.MaxHealth
        ))
    end
    print(string.format("Total NPCs: %d", npcCount))
    print("=========================")
end

-- Initialize the handler
function HumanoidHandler.init()
    HumanoidHandler.setupPlayerTracking()
    
    -- Start automatic NPC cache updates
    Cache.Connections.NPCUpdate = Services.RunService.Heartbeat:Connect(function()
        HumanoidHandler.updateNPCCache()
    end)
end

-- Cleanup function
function HumanoidHandler.cleanup()
    for _, connection in pairs(Cache.Connections) do
        connection:Disconnect()
    end
    table.clear(Cache.Connections)
    table.clear(Cache.Players)
    table.clear(Cache.NPCs)
end

return HumanoidHandler
