local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local AnimationConfig = require(ReplicatedStorage.Shared.AnimationConfig)

local AnimationService = Knit.CreateService {
    Name = "AnimationService",
    Client = {
        ForcePlaySignal = Knit.CreateSignal(),
        ForceStopSignal = Knit.CreateSignal(),
    },
}

function AnimationService:KnitInit()
end

function AnimationService:KnitStart()
end

function AnimationService:ForceAnimation(player, category, animName)
    if not AnimationConfig[category] or not AnimationConfig[category][animName] then return end
    self.Client.ForcePlaySignal:Fire(player, category, animName)
end

function AnimationService:ForceStop(player, category, animName)
    if not AnimationConfig[category] or not AnimationConfig[category][animName] then return end
    self.Client.ForceStopSignal:Fire(player, category, animName)
end

return AnimationService
