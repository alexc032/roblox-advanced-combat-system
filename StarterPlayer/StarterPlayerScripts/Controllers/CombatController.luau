local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit          = require(ReplicatedStorage.Packages.Knit)
local Trove         = require(ReplicatedStorage.Packages.Trove)
local CombatConfig  = require(ReplicatedStorage.Shared.CombatConfig)
local HitboxHandler = require(ReplicatedStorage.Shared.HitboxHandler)
local MovementConfig = require(ReplicatedStorage.Shared.MovementConfig)




local CombatController = Knit.CreateController {
    Name = "CombatController",
}

local COMBO_RESET_WINDOW = 1 

function CombatController:KnitInit()
    self.Trove         = Trove.new()
    self.ComboCount    = 0
    self.LastAttackTime = 0
end

function CombatController:KnitStart()
    self.CombatService      = Knit.GetService("CombatService")
    self.AnimationController = Knit.GetController("AnimationController")
    self.BlockController    = Knit.GetController("BlockController")
    self.InputController    = Knit.GetController("InputController")
    self.MovementController = Knit.GetController("MovementController")
    self.VFXController      = Knit.GetController("VFXController")

    self.Trove:Connect(self.InputController.AttackRequested, function()
        self:_onAttackInput()
    end)
end



function CombatController:_isBlocked()
    local player = game.Players.LocalPlayer
    local char   = player.Character
    if char and char:GetAttribute("IsStunned") then return true end
    if self.BlockController:IsBlocking()        then return true end
	if self.MovementController:IsDashing("Frontal") then return true end
	
	local dashConfig = MovementConfig.Dashs["Frontal"]
	local timeSinceDash = os.clock() - self.MovementController.LastDashTime
	
	if timeSinceDash < (dashConfig.duration + dashConfig.postDashAttackDelay) then 
		return true
	end
	
    return false
end

function CombatController:_advanceCombo(attackData)
    local now = os.clock()
    if now - self.LastAttackTime < attackData.Cooldown then return nil end

    if now - self.LastAttackTime > COMBO_RESET_WINDOW then
        self.ComboCount = 1
    else
        self.ComboCount = (self.ComboCount % 5) + 1
    end
    self.LastAttackTime = now
    return self.ComboCount
end

function CombatController:_onAttackInput()
    if self:_isBlocked() then return end

    local attackData = CombatConfig.Attacks["Punch"]
    if not attackData then return end

    local count = self:_advanceCombo(attackData)
    if not count then return end

    self:_executeAttack("Punch", attackData, count)
end

function CombatController:_executeAttack(attackName, attackData, count)
    self.AnimationController:Play("Ataques", "Hit" .. count)

    self.CombatService:Attack(attackName, count):andThen(function(success)
        if not success then return end

        local player    = game.Players.LocalPlayer
        local character = player.Character
        local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local hitbox = HitboxHandler.new(rootPart, attackData.HitboxSize, attackData.HitboxOffset)

        hitbox:OnHit(function(hit, humanoid)
            if humanoid.Parent == character then return end
			self.CombatService:ProcessHit(humanoid.Parent, attackName)
			if count == 5 then
				self.VFXController:PlayHitEffect(hit.Position, hit, true)
			else
				self.VFXController:PlayHitEffect(hit.Position, hit)
			end
        end)

        hitbox:Start(attackData.ActiveTime)
    end):catch(warn)
end

return CombatController