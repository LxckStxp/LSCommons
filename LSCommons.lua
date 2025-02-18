--[[
    LSCommons.lua
    Version: 1.0
    Utility functions for Roblox game development
]]

local Commons = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player Utilities
Commons.Players = {
    -- Get player from character or model
    getPlayerFromInstance = function(instance)
        if not instance then return nil end
        return Players:GetPlayerFromCharacter(instance)
    end,
    
    -- Check if instance is an NPC
    isNPC = function(instance)
        if not instance then return false end
        return instance:FindFirstChild("Humanoid") 
            and not Players:GetPlayerFromCharacter(instance)
    end,
    
    -- Check if character is alive
    isAlive = function(character)
        return character 
            and character:FindFirstChild("Humanoid") 
            and character:FindFirstChild("Head") 
            and character:FindFirstChild("HumanoidRootPart")
            and character.Humanoid.Health > 0
    end,
    
    -- Check team relationship
    isSameTeam = function(player1, player2)
        return player1.Team and player2.Team and player1.Team == player2.Team
    end,
    
    -- Get character health info
    getHealthInfo = function(character)
        if not character or not character:FindFirstChild("Humanoid") then
            return 0, 0
        end
        return math.floor(character.Humanoid.Health), 
               math.floor(character.Humanoid.MaxHealth)
    end
}

-- Math Utilities
Commons.Math = {
    -- Get distance between two Vector3 positions
    getDistance = function(pos1, pos2)
        return (pos1 - pos2).Magnitude
    end,
    
    -- Get distance from player to position
    getDistanceFromPlayer = function(position)
        local player = Players.LocalPlayer
        if not player or not player.Character then return math.huge end
        return (position - player.Character:GetPivot().Position).Magnitude
    end,
    
    -- Lerp between two numbers
    lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    
    -- Clamp value between min and max
    clamp = function(value, min, max)
        return math.min(math.max(value, min), max)
    end
}

-- Visual Utilities
Commons.Visual = {
    -- Create rainbow color cycle
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
    
    -- Format distance string
    formatDistance = function(distance)
        return string.format("%dm", math.floor(distance))
    end
}

-- Instance Utilities
Commons.Instance = {
    -- Safely destroy instance
    destroy = function(instance)
        if instance and typeof(instance) == "Instance" then
            instance:Destroy()
        end
    end,
    
    -- Safely remove drawing object
    removeDrawing = function(drawing)
        if drawing and typeof(drawing) == "table" and drawing.Remove then
            drawing:Remove()
        end
    end,
    
    -- Clean up connections
    disconnectConnections = function(connections)
        for _, connection in pairs(connections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        table.clear(connections)
    end
}

return Commons
