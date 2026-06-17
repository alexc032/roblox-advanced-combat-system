local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local Knit              = require(ReplicatedStorage.Packages.Knit)
local Trove             = require(ReplicatedStorage.Packages.Trove)
local MovementConfig    = require(ReplicatedStorage.Shared.MovementConfig)
local HitboxHandler     = require(ReplicatedStorage.Shared.HitboxHandler)




local MovementController = Knit.CreateController {
    Name = "MovementController"
}

function MovementController:KnitInit()
    self.LastDashTime     = 0
    self.CurrentDashTrove = nil
    self.Trove            = Trove.new()
end

function MovementController:KnitStart()
    self.MovementService = Knit.GetService("MovementService")
    self.BlockController = Knit.GetController("BlockController")
    self.InputController = Knit.GetController("InputController")
    self.VFXController   = Knit.GetController("VFXController")

    self.Trove:Connect(self.InputController.DashRequested, function()
        if not self.BlockController:IsBlocking() then
            self:_requestDash("Frontal")
        end
    end)

    self.MovementService.DashHitSignal:Connect(function()
        self:_stopDash()
    end)
end



function MovementController:IsDashing(dashName)
    local dashConfig = MovementConfig.Dashs[dashName]
    if not dashConfig then return false end
    return os.clock() - self.LastDashTime < dashConfig.duration
end



function MovementController:_stopDash()
    if not self.CurrentDashTrove then return end
    self.CurrentDashTrove:Destroy()
    self.CurrentDashTrove = nil
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    end
end

function MovementController:_requestDash(dashName)
    local dashConfig = MovementConfig.Dashs[dashName]
    if not dashConfig then return end

    local player    = game.Players.LocalPlayer
	local character = player.Character
	local humanoid  = character and character:FindFirstChild("Humanoid") 
    local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not humanoid then return end
	
	if humanoid.FloorMaterial == Enum.Material.Air then 
		return
	end

    local now = os.clock()
    if now - self.LastDashTime < dashConfig.cooldown then return end
    self.LastDashTime = now

    self:_stopDash()

    local dashTrove = Trove.new()
	self.CurrentDashTrove = dashTrove
	
	local currentStamina = character:GetAttribute("Stamina") or 100
	if currentStamina < dashConfig.staminaCost then return end


    local AnimationController = Knit.GetController("AnimationController")
    AnimationController:Play("Estados", "Dash1")
    dashTrove:Add(function()
        AnimationController:Stop("Estados", "Dash1")
        AnimationController:Play("Estados", "Dash2")
    end)

    local attachment    = dashTrove:Construct(Instance.new, "Attachment")
    attachment.Parent   = rootPart

    local linearVelocity              = dashTrove:Construct(Instance.new, "LinearVelocity")
    linearVelocity.Attachment0        = attachment
    linearVelocity.MaxForce           = 999999
    linearVelocity.RelativeTo         = Enum.ActuatorRelativeTo.World
    linearVelocity.Parent             = rootPart

    dashTrove:Connect(RunService.Heartbeat, function()
        local camLook = workspace.CurrentCamera.CFrame.LookVector
        local dir     = Vector3.new(camLook.X, 0, camLook.Z)
        if dir.Magnitude > 0.001 then
            dir = dir.Unit
            linearVelocity.VectorVelocity = dir * dashConfig.speed
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + dir)
        end
    end)

    local prevAutoRotate              = character.Humanoid.AutoRotate
    character.Humanoid.AutoRotate     = false
    dashTrove:Add(function()
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.AutoRotate = prevAutoRotate
        end
    end)

    task.delay(dashConfig.duration, function()
        if self.CurrentDashTrove ~= dashTrove then return end
        self:_stopDash()

        local hitbox = HitboxHandler.new(rootPart, Vector3.new(2, 2, 2), CFrame.new(0, 0, -3))
        hitbox:OnHit(function(hit, humanoid)
            if humanoid.Parent == character then return end
            self.MovementService:ProcessDashHit(humanoid.Parent, dashName)
            self.VFXController:PlayHitEffect(hit.Position, hit)
        end)
        hitbox:Start(0.2)
    end)

    self.MovementService:RequestDash(dashName)
end

return MovementController
