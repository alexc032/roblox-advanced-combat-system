local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local MuchachoHitbox = require(ReplicatedStorage.Packages.MuchachoHitbox)
local Timer = require(ReplicatedStorage.Packages.Timer)

local HitboxHandler = {}
HitboxHandler.__index = HitboxHandler


function HitboxHandler.new(part, size, offset)
    local self = setmetatable({}, HitboxHandler)
    self._trove = Trove.new()
    self.Part = part
    self.Offset = offset or CFrame.new()
    
    self.Hitbox = MuchachoHitbox.CreateHitbox()
    self.Hitbox.Size = size
	self.Hitbox.Visualizer = false
	self.Hitbox.VelocityPrediction = true
    
    
    self._trove:Connect(RunService.Heartbeat, function()
        if self.Part and self.Part.Parent then
            self.Hitbox.CFrame = self.Part.CFrame * self.Offset
        end
    end)
    
    self._trove:Add(function()
        self.Hitbox:Stop()
        
    end)
    
    return self
end


function HitboxHandler:Start(duration)
    self.Hitbox:Start()
    
    if duration then
        local timer = self._trove:Construct(Timer.new, duration)
        self._trove:Connect(timer.Tick, function()
            self:Destroy()
        end)
        timer:Start()
    end
end


function HitboxHandler:OnHit(callback)
    self._trove:Connect(self.Hitbox.Touched, callback)
end


function HitboxHandler:Destroy()
    self._trove:Destroy()
end

return HitboxHandler
