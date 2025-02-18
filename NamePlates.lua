--[[
    NamePlates Module
    Author: LxckStxp
    Version: 1.0
    
    Provides customizable name plates for ESP and other UI elements
    
    Example Usage:
    local NamePlates = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/LSCommons/main/NamePlates.lua"))()
    local plate = NamePlates.new(character, {
        name = "Player123",
        health = 100,
        maxHealth = 100,
        distance = 50,
        color = Color3.fromRGB(255, 0, 0)
    })
]]

local NamePlates = {}

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local DEFAULTS = {
    FADE_TIME = 0.2,
    FONT = {
        NAME = Enum.Font.GothamBold,
        INFO = Enum.Font.Gotham
    },
    SIZE = {
        NAME = 14,
        INFO = 12
    },
    OFFSET = Vector3.new(0, 2.5, 0),
    PADDING = 4
}

-- Utility Functions
local function Lerp(a, b, t)
    return a + (b - a) * t
end

-- NamePlate Class
local NamePlate = {}
NamePlate.__index = NamePlate

function NamePlate.new(config)
    local self = setmetatable({}, NamePlate)
    
    -- Initialize configuration
    self.config = {
        showName = config.showName or true,
        showHealth = config.showHealth or true,
        showDistance = config.showDistance or true,
        fadeStart = config.fadeStart or 0.7, -- Start fading at 70% of max distance
        maxDistance = config.maxDistance or 1000
    }
    
    -- Create BillboardGui
    self.gui = Instance.new("BillboardGui")
    self.gui.Name = "NamePlate"
    self.gui.Size = UDim2.new(0, 200, 0, 60)
    self.gui.StudsOffset = DEFAULTS.OFFSET
    self.gui.AlwaysOnTop = true
    self.gui.MaxDistance = self.config.maxDistance
    
    -- Create container for better organization
    self.container = Instance.new("Frame")
    self.container.Name = "Container"
    self.container.Size = UDim2.new(1, 0, 1, 0)
    self.container.BackgroundTransparency = 1
    self.container.Parent = self.gui
    
    -- Create labels with enhanced visuals
    self.labels = {
        name = self:CreateLabel("NameLabel", {
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0, 0, 0, 0),
            TextSize = DEFAULTS.SIZE.NAME,
            Font = DEFAULTS.FONT.NAME
        }),
        
        info = self:CreateLabel("InfoLabel", {
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            TextSize = DEFAULTS.SIZE.INFO,
            Font = DEFAULTS.FONT.INFO
        })
    }
    
    return self
end

function NamePlate:CreateLabel(name, props)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = props.Size
    label.Position = props.Position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.TextSize = props.TextSize
    label.Font = props.Font
    label.Parent = self.container
    return label
end

function NamePlate:Update(data)
    -- Calculate fade based on distance
    local alpha = 1
    if data.distance then
        local fadeStart = self.config.maxDistance * self.config.fadeStart
        alpha = math.clamp(
            (self.config.maxDistance - data.distance) / (self.config.maxDistance - fadeStart),
            0, 1
        )
    end
    
    -- Update name text
    if self.config.showName and data.name then
        self.labels.name.Text = string.format("[%s]", data.name)
        self.labels.name.TextTransparency = 1 - alpha
        self.labels.name.TextStrokeTransparency = 1 - alpha
    else
        self.labels.name.Text = ""
    end
    
    -- Update info text
    local infoText = ""
    
    -- Add health info
    if self.config.showHealth and data.health then
        infoText = string.format("HP: %d/%d", data.health, data.maxHealth or 100)
    end
    
    -- Add distance info
    if self.config.showDistance and data.distance then
        infoText = infoText ~= "" 
            and string.format("%s | %dm", infoText, math.floor(data.distance))
            or string.format("%dm", math.floor(data.distance))
    end
    
    self.labels.info.Text = infoText
    self.labels.info.TextTransparency = 1 - alpha
    self.labels.info.TextStrokeTransparency = 1 - alpha
    
    -- Update colors if provided
    if data.color then
        self.labels.name.TextColor3 = data.color
        self.labels.info.TextColor3 = data.color
    end
end

function NamePlate:SetParent(parent)
    self.gui.Parent = parent
end

function NamePlate:Show()
    self.gui.Enabled = true
end

function NamePlate:Hide()
    self.gui.Enabled = false
end

function NamePlate:Destroy()
    self.gui:Destroy()
    self.labels = nil
    self.container = nil
    self.gui = nil
end

-- Main Module Functions
function NamePlates.new(config)
    return NamePlate.new(config)
end

return NamePlates
