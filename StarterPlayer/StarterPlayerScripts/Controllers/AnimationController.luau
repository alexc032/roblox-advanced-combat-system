local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit              = require(ReplicatedStorage.Packages.Knit)
local Observers         = require(ReplicatedStorage.Packages.Observers)
local Trove             = require(ReplicatedStorage.Packages.Trove)
local AnimationConfig   = require(ReplicatedStorage.Shared.AnimationConfig)
local AnimationManager  = require(script.Parent.Parent.Modules.AnimationManager)




local AnimationController = Knit.CreateController {
    Name = "AnimationController"
}

function AnimationController:KnitInit()
    self.PlayerManager = nil
end

function AnimationController:KnitStart()
    self.AnimationService = Knit.GetService("AnimationService")

    self.AnimationService.ForcePlaySignal:Connect(function(category, animName)
        self:Play(category, animName)
    end)

    self.AnimationService.ForceStopSignal:Connect(function(category, animName)
        self:Stop(category, animName)
    end)

    Observers.observeCharacter(function(player, character)
        if player ~= game.Players.LocalPlayer then return end

        local trove    = Trove.new()
        local humanoid = character:WaitForChild("Humanoid")

        self.PlayerManager = AnimationManager.new(humanoid)

        trove:Add(function()
            self.PlayerManager:Destroy()
            self.PlayerManager = nil
        end)

        return function()
            trove:Destroy()
        end
    end)
end

function AnimationController:Play(category, animName)
    if not self.PlayerManager then return end
    local config = AnimationConfig[category] and AnimationConfig[category][animName]
    if not config then return end
    return self.PlayerManager:Play(config)
end

function AnimationController:Stop(category, animName)
    if not self.PlayerManager then return end
    local config = AnimationConfig[category] and AnimationConfig[category][animName]
    if not config then return end
    self.PlayerManager:Stop(config.Id)
end

return AnimationController