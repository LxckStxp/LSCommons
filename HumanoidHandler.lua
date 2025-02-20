--[[
    HumanoidHandler Module
    Part of LSCommons Library
    Version: 1.1
    
    Core humanoid tracking and management system
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
    UpdateInterval = 0.5,
    Connections = {}
}

-- Core Validation
function HumanoidHandler.isValidHumanoid(model)
    if not model then return false end
    
    local humanoid = model:FindFirstChild("Humanoid")
    return humanoid 
        and humanoid:IsA("Humanoid")
        and humanoid.Health > 0 
        and model:FindFirstChild("Head") 
        and model:FindFirstChild("HumanoidRootPart")
end

-- Humanoid Information
function HumanoidHandler.getHumanoidInfo(model)
    if not model then return nil end
    
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    
    return {
        Instance = humanoid,
        Health = humanoid.Health,
        MaxHealth = humanoid.MaxHealth,
        DisplayName = humanoid.DisplayName ~= "" and humanoid.DisplayName or humanoid.Name,
        WalkSpeed = humanoid.WalkSpeed,
        JumpPower = humanoid.JumpPower
    }
end

-- Player Management
function HumanoidHandler.setupPlayerTracking()
    table.clear(Cache.Players)
    
    -- Add existing players
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player.Character and HumanoidHandler.isValidHumanoid(player.Character) then
            Cache.Players[player.Name] = player.Character
        end
    end
    
    -- Track character changes
    Cache.Connections.CharacterAdded = Services.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            if HumanoidHandler.isValidHumanoid(character) then
                Cache.Players[player.Name] = character
            end
        end)
    end)
    
    Cache.Connections.CharacterRemoving = Services.Players.PlayerRemoving:Connect(function(player)
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
            if HumanoidHandler.isValidHumanoid(model) 
            and not Services.Players:GetPlayerFromCharacter(model) then
                local info = HumanoidHandler.getHumanoidInfo(model)
                if info then
                    newCache[info.DisplayName] = model
                end
            end
        end
    end
    
    Cache.NPCs = newCache
    Cache.LastUpdate = currentTime
    return Cache.NPCs
end

-- Public Interface
function HumanoidHandler.getValidPlayers()
    local valid = {}
    for name, character in pairs(Cache.Players) do
        if HumanoidHandler.isValidHumanoid(character) then
            table.insert(valid, character)
        end
    end
    return valid
end

function HumanoidHandler.getValidNPCs()
    return HumanoidHandler.updateNPCCache()
end

function HumanoidHandler.getAllValidHumanoids()
    local humanoids = {}
    
    -- Add valid players
    for _, character in pairs(HumanoidHandler.getValidPlayers()) do
        table.insert(humanoids, character)
    end
    
    -- Add NPCs
    for _, npc in pairs(HumanoidHandler.getValidNPCs()) do
        table.insert(humanoids, npc)
    end
    
    return humanoids
end

-- Distance Utilities
function HumanoidHandler.getHumanoidDistance(model1, model2)
    if not (model1 and model2) then return math.huge end
    
    local pos1 = model1:GetPivot().Position
    local pos2 = model2:GetPivot().Position
    return (pos1 - pos2).Magnitude
end

-- Debug Functions
function HumanoidHandler.debugPrint()
    print("=== HumanoidHandler Debug ===")
    
    -- Player info
    local players = HumanoidHandler.getValidPlayers()
    print(string.format("Active Players: %d", #players))
    for _, character in ipairs(players) do
        local info = HumanoidHandler.getHumanoidInfo(character)
        print(string.format("Player: %s (Health: %d/%d)", 
            info.DisplayName,
            info.Health,
            info.MaxHealth
        ))
    end
    
    -- NPC info
    local npcs = HumanoidHandler.getValidNPCs()
    local npcCount = 0
    print("\nActive NPCs:")
    for _, npc in pairs(npcs) do
        npcCount = npcCount + 1
        local info = HumanoidHandler.getHumanoidInfo(npc)
        print(string.format("NPC: %s (Health: %d/%d)", 
            info.DisplayName,
            info.Health,
            info.MaxHealth
        ))
    end
    print(string.format("Total NPCs: %d", npcCount))
    print("=========================")
end

-- Initialize
function HumanoidHandler.init()
    HumanoidHandler.setupPlayerTracking()
    
    -- Start automatic NPC cache updates
    Cache.Connections.NPCUpdate = Services.RunService.Heartbeat:Connect(function()
        HumanoidHandler.updateNPCCache()
    end)
end

-- Cleanup
function HumanoidHandler.cleanup()
    for _, connection in pairs(Cache.Connections) do
        connection:Disconnect()
    end
    table.clear(Cache.Connections)
    table.clear(Cache.Players)
    table.clear(Cache.NPCs)
end

return HumanoidHandler
