------------------------------------------------------------
-- LSCommons.lua
-- Version: 1.1
-- Utility functions for Roblox game development
------------------------------------------------------------

local Commons = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

------------------------------------------------------------
-- Player Utilities
------------------------------------------------------------
Commons.Players = {
    -- Return the player associated with a given character or instance, or nil if not found.
    getPlayerFromInstance = function(instance)
        if not instance then
            return nil
        end
        return Players:GetPlayerFromCharacter(instance)
    end,
    
    -- Check if an instance is an NPC.
    -- An instance is considered an NPC if it has a Humanoid and is not associated with a player.
    isNPC = function(instance)
        if not instance then 
            return false 
        end
        return instance:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(instance)
    end,
    
    -- Check whether a character is alive by ensuring it has the required parts
    -- and that its Humanoid’s Health is greater than 0.
    isAlive = function(character)
        return character 
            and character:FindFirstChild("Humanoid") 
            and character:FindFirstChild("Head") 
            and character:FindFirstChild("HumanoidRootPart")
            and character.Humanoid.Health > 0
    end,
    
    -- Check team relationship between two players.
    -- Returns true only if both players have a valid Team property and are on the same team.
    isSameTeam = function(player1, player2)
        if player1 and player2 and player1.Team and player2.Team then
            return player1.Team == player2.Team
        end
        return false
    end,
    
    -- Retrieve character health information:
    -- Returns the current health and maximum health as whole numbers.
    getHealthInfo = function(character)
        if not character or not character:FindFirstChild("Humanoid") then
            return 0, 0
        end
        return math.floor(character.Humanoid.Health), math.floor(character.Humanoid.MaxHealth)
    end,
    
    -- Returns the character for a given entity.
    -- If the entity is a Player, returns its Character.
    -- Otherwise, assumes the entity is a model representing an NPC and returns the entity.
    getCharacterFromEntity = function(entity)
        if typeof(entity) == "Instance" and entity:IsA("Player") then
            return entity.Character
        else
            return entity
        end
    end,
    
    -- Returns the Humanoid instance from the entity (player or NPC).
    getHumanoidFromEntity = function(entity)
        local character = Commons.Players.getCharacterFromEntity(entity)
        if character then
            return character:FindFirstChild("Humanoid")
        end
        return nil
    end
}

------------------------------------------------------------
-- Math Utilities
------------------------------------------------------------
Commons.Math = {
    -- Get the distance between two Vector3 positions.
    getDistance = function(pos1, pos2)
        return (pos1 - pos2).Magnitude
    end,
    
    -- Return the distance from the LocalPlayer's character to a given position.
    getDistanceFromPlayer = function(position)
        local player = Players.LocalPlayer
        if not player or not player.Character then
            return math.huge
        end
        return (position - player.Character:GetPivot().Position).Magnitude
    end,
    
    -- Linear interpolation between two numbers.
    lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    
    -- Clamp a value between a minimum and maximum value.
    clamp = function(value, min, max)
        return math.min(math.max(value, min), max)
    end
}

------------------------------------------------------------
-- Visual Utilities
------------------------------------------------------------
Commons.Visual = {
    -- Generate a rainbow color based on time. Optionally specify a speed.
    getRainbowColor = function(speed)
        speed = speed or 5
        return Color3.fromHSV((tick() % speed) / speed, 1, 1)
    end,
    
    -- Return the team color for a player if available, or return a default color.
    getTeamColor = function(player, default)
        if player and player.Team then
            return player.TeamColor.Color
        end
        return default or Color3.new(1, 0, 0)
    end,
    
    -- Format a distance number (assumed in studs) into a text string.
    formatDistance = function(distance)
        return string.format("%dm", math.floor(distance))
    end
}

------------------------------------------------------------
-- Instance Utilities
------------------------------------------------------------
Commons.Instance = {
    -- Destroys an instance safely if it exists.
    destroy = function(instance)
        if instance and typeof(instance) == "Instance" then
            instance:Destroy()
        end
    end,
    
    -- Remove a drawing object safely if applicable (for Drawing API objects).
    removeDrawing = function(drawing)
        if drawing and typeof(drawing) == "table" and drawing.Remove then
            drawing:Remove()
        end
    end,
    
    -- Disconnects all connections in a connections table and clears it.
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
