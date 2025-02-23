--[[
    HumanoidHandler Module
    Part of LSCommons Library
    Version: 1.2
    
    Core humanoid tracking and management system with advanced detection
]]

local HumanoidHandler = {}

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Camera = workspace.CurrentCamera
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

-- Advanced Player Detection
local function DetectPlayers()
    local potentialPlayers = {}
    local ignoreList = {Services.Players.LocalPlayer}
    local localChar = Services.Players.LocalPlayer.Character or Instance.new("Model")

    -- Method 1: Standard Player Service Check
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= Services.Players.LocalPlayer and player.Character then
            if HumanoidHandler.isValidHumanoid(player.Character) then
                table.insert(potentialPlayers, player.Character)
            end
        end
    end

    -- Method 2: Raycast-Based Detection
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localChar}
    
    for angle = 0, 360, 15 do
        local direction = (Services.Camera.CFrame * CFrame.Angles(0, math.rad(angle), 0)).LookVector
        local rayResult = workspace:Raycast(Services.Camera.CFrame.Position, direction * 500, raycastParams)
        
        if rayResult and rayResult.Instance then
            local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
            if model and HumanoidHandler.isValidHumanoid(model) then
                local player = Services.Players:GetPlayerFromCharacter(model)
                if player and not table.find(potentialPlayers, model) and not table.find(ignoreList, player) then
                    table.insert(potentialPlayers, model)
                end
            end
        end
    end

    -- Method 3: Proximity-Based Detection via FindPartsInRegion3
    local region = Region3.new(
        Services.Camera.CFrame.Position - Vector3.new(50, 50, 50),
        Services.Camera.CFrame.Position + Vector3.new(50, 50, 50)
    )
    local parts = workspace:FindPartsInRegion3WithIgnoreList(region, {localChar}, 100)
    
    for _, part in pairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and HumanoidHandler.isValidHumanoid(model) then
            local player = Services.Players:GetPlayerFromCharacter(model)
            if player and not table.find(potentialPlayers, model) and not table.find(ignoreList, player) then
                table.insert(potentialPlayers, model)
            end
        end
    end

    -- Method 4: Camera Obscuring Check
    local obscuringParts = Services.Camera:GetPartsObscuringTarget({Services.Camera.CFrame.Position}, {localChar})
    for _, part in pairs(obscuringParts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and HumanoidHandler.isValidHumanoid(model) then
            local player = Services.Players:GetPlayerFromCharacter(model)
            if player and not table.find(potentialPlayers, model) and not table.find(ignoreList, player) then
                table.insert(potentialPlayers, model)
            end
        end
    end

    return potentialPlayers
end

-- Player Management
function HumanoidHandler.setupPlayerTracking()
    table.clear(Cache.Players)
    
    -- Initial population with advanced detection
    for _, character in pairs(DetectPlayers()) do
        local player = Services.Players:GetPlayerFromCharacter(character)
        if player then
            Cache.Players[player.Name] = character
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
    local detectedPlayers = DetectPlayers()
    
    -- Scan workspace for humanoids
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Humanoid") then
            local model = instance.Parent
            if HumanoidHandler.isValidHumanoid(model) then
                -- Exclude detected players
                if not table.find(detectedPlayers, model) then
                    local info = HumanoidHandler.getHumanoidInfo(model)
                    if info then
                        newCache[info.DisplayName] = model
                    end
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
    for _, character in pairs(Cache.Players) do
        if HumanoidHandler.isValidHumanoid(character) then
            table.insert(valid, character)
        end
    end
    -- Supplement with real-time detection
    for _, character in pairs(DetectPlayers()) do
        if HumanoidHandler.isValidHumanoid(character) and not table.find(valid, character) then
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
    
    -- Add valid players with advanced detection
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
