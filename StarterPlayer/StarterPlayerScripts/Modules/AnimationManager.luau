local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local AnimationManager = {}
AnimationManager.__index = AnimationManager

function AnimationManager.new(humanoid)
    local self = setmetatable({}, AnimationManager)
    self._trove = Trove.new()
    
    self.Animator = humanoid:FindFirstChildWhichIsA("Animator")
    if not self.Animator then
        self.Animator = Instance.new("Animator")
        self.Animator.Parent = humanoid
    end
    
    self._loadedTracks = {}
    return self
end

function AnimationManager:Play(configData)
    if not configData or not configData.Id then return end
    
    local track = self:GetTrack(configData.Id)
    if track then
        if configData.Priority then
            track.Priority = configData.Priority
        end
        if configData.Looped ~= nil then
            track.Looped = configData.Looped
        end
        track:Play(configData.Fade or 0.100000001, 1, configData.Speed or 1)
    end
    return track
end

function AnimationManager:Stop(animationId, fadeTime)
    local track = self._loadedTracks[animationId]
    if track then
        track:Stop(fadeTime or 0.100000001)
    end
end

function AnimationManager:GetTrack(animationId)
    if self._loadedTracks[animationId] then
        return self._loadedTracks[animationId]
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    
    local track = self.Animator:LoadAnimation(animation)
    self._loadedTracks[animationId] = track
    
    self._trove:Add(track)
    self._trove:Add(animation)
    
    return track
end

function AnimationManager:Destroy()
    self._trove:Destroy()
    self._loadedTracks = nil
end

return AnimationManager
