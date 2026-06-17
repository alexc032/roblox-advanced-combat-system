local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatConfig      = require(ReplicatedStorage.Shared.CombatConfig)
local Knit              = require(ReplicatedStorage.Packages.Knit)
local Trove             = require(ReplicatedStorage.Packages.Trove)





local BlockController = Knit.CreateController {
    Name = "BlockController"
}

local BLOCK_WALK_SPEED   = 8
local NORMAL_WALK_SPEED  = 16

function BlockController:KnitInit()
    self._isBlocking = false
    self.Trove       = Trove.new()
end

function BlockController:KnitStart()
    self.BlockService       = Knit.GetService("BlockService")
    self.AnimationController = Knit.GetController("AnimationController")
    self.CombatController   = Knit.GetController("CombatController")
    self.MovementController = Knit.GetController("MovementController")
    self.InputController    = Knit.GetController("InputController")

    self.Trove:Connect(self.InputController.BlockPressed,  function() self:_block() end)
    self.Trove:Connect(self.InputController.BlockReleased, function() self:_unblock() end)

    self.BlockService.BlockBrokenSignal:Connect(function()
        if self._isBlocking then self:_unblock() end
    end)
end



function BlockController:IsBlocking()
    return self._isBlocking
end



function BlockController:_block()
    local player = game.Players.LocalPlayer
    if not player.Character then return end
    if player.Character:GetAttribute("IsStunned")     then return end
    if os.clock() - self.CombatController.LastAttackTime < 0.3 then return end
    if self.MovementController:IsDashing("Frontal")   then return end

    self._isBlocking = true
    self.AnimationController:Play("Estados", "Block")
    self.BlockService:StartBlock()

    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.WalkSpeed = BLOCK_WALK_SPEED end
end

function BlockController:_unblock()
    self._isBlocking = false
    self.AnimationController:Stop("Estados", "Block")
    self.BlockService:StopBlock()

    local player   = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.WalkSpeed = NORMAL_WALK_SPEED end
end

return BlockController