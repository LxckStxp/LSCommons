--[[
    LSCommons Library
    Version: 1.2
    Core utility functions for Roblox exploiting
]]

local Commons = {}

-- Services
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService")
}

-- Load Dependencies
local HumanoidHandler = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/HumanoidHandler.lua"))()

------------------------------------------------------------
-- Player Utilities
------------------------------------------------------------
Commons.Players = {
    -- Get player from instance
    getPlayerFromInstance = function(instance)
        if not instance then return nil end
        return Services.Players:GetPlayerFromCharacter(instance)
    end,
    
    -- Get character from entity (player or model)
    getCharacterFromEntity = function(entity)
        if not entity then return nil end
        
        if entity:IsA("Player") then
            return entity.Character
        else
            return entity
        end
    end,
    
    -- Get humanoid from entity
    getHumanoidFromEntity = function(entity)
        local character = Commons.Players.getCharacterFromEntity(entity)
        return character and character:FindFirstChild("Humanoid")
    end,
    
    -- Check if entity is alive
    isAlive = function(character)
        if not character then return false end
        
        local humanoid = character:FindFirstChild("Humanoid")
        return humanoid 
            and humanoid.Health > 0 
            and character:FindFirstChild("Head")
            and character:FindFirstChild("HumanoidRootPart")
    end,
    
    -- Get health information
    getHealthInfo = function(character)
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not humanoid then return 0, 0 end
        
        return math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)
    end,
    
    -- Check team relationship
    isSameTeam = function(player1, player2)
        if not (player1 and player2) then return false end
        if not (player1.Team and player2.Team) then return false end
        return player1.Team == player2.Team
    end,
    
    -- Get all valid players
    getValidPlayers = function()
        return HumanoidHandler.getPlayers()
    end,
    
    -- Get all valid NPCs
    getValidNPCs = function()
        return HumanoidHandler.getNPCs()
    end,
    
    -- Get all valid humanoids
    getAllValidHumanoids = function()
        return HumanoidHandler.getAllHumanoids()
    end,
    
    -- Get closest humanoid to a position
    getClosestHumanoid = function(position, maxDistance)
        return HumanoidHandler.getClosestHumanoid(position, maxDistance)
    end,
    
    -- Get humanoids within radius
    getHumanoidsInRadius = function(position, radius)
        return HumanoidHandler.getHumanoidsInRadius(position, radius)
    end
}

------------------------------------------------------------
-- Math Utilities
------------------------------------------------------------
Commons.Math = {
    -- Get distance between two positions
    getDistance = function(pos1, pos2)
        return (pos1 - pos2).Magnitude
    end,
    
    -- Get distance from local player
    getDistanceFromPlayer = function(position)
        local character = Services.Players.LocalPlayer.Character
        if not character then return math.huge end
        
        return (position - character:GetPivot().Position).Magnitude
    end,
    
    -- Linear interpolation
    lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    
    -- Clamp value
    clamp = function(value, min, max)
        return math.min(math.max(value, min), max)
    end,
    
    -- Get angle between two vectors
    getAngle = function(v1, v2)
        return math.acos(v1:Dot(v2) / (v1.Magnitude * v2.Magnitude))
    end,
    
    -- Get direction to target
    getDirection = function(from, to)
        return (to - from).Unit
    end
}

------------------------------------------------------------
-- Visual Utilities
------------------------------------------------------------
Commons.Visual = {
    -- Generate rainbow color
    getRainbowColor = function(speed)
        speed = speed or 5
        return Color3.fromHSV((tick() % speed) / speed, 1, 1)
    end,
    
    -- Get team color or default
    getTeamColor = function(player, default)
        if player and player.Team then
            return player.TeamColor.Color
        end
        return default or Color3.new(1, 0, 0)
    end,
    
    -- Format distance
    formatDistance = function(distance)
        return string.format("%dm", math.floor(distance))
    end,
    
    -- Create smooth tween
    createTween = function(object, info, properties)
        return Services.TweenService:Create(object, info, properties)
    end,
    
    -- Check if position is visible on screen
    isOnScreen = function(position)
        local _, onScreen = workspace.CurrentCamera:WorldToScreenPoint(position)
        return onScreen
    end
}

------------------------------------------------------------
-- Instance Utilities
------------------------------------------------------------
Commons.Instance = {
    -- Safely destroy instance
    destroy = function(instance)
        if instance and typeof(instance) == "Instance" then
            instance:Destroy()
        end
    end,
    
    -- Safely remove drawing
    removeDrawing = function(drawing)
        if drawing and typeof(drawing) == "table" and drawing.Remove then
            drawing:Remove()
        end
    end,
    
    -- Disconnect connections
    disconnectConnections = function(connections)
        for _, connection in pairs(connections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        table.clear(connections)
    end,
    
    -- Find instance in path
    findInPath = function(path)
        local current = game
        for _, name in ipairs(path:split(".")) do
            current = current:FindFirstChild(name)
            if not current then return nil end
        end
        return current
    end,
    
    -- Create instance with properties
    create = function(className, properties)
        local instance = Instance.new(className)
        for prop, value in pairs(properties) do
            instance[prop] = value
        end
        return instance
    end
}

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
do
    -- Initialize HumanoidHandler
    HumanoidHandler.init()
    
    -- Cleanup on script stop
    game:GetService("CoreGui").ChildRemoved:Connect(function(child)
        if child:IsA("ScreenGui") then
            HumanoidHandler.cleanup()
        end
    end)
end

return Commons
