local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")
local Knit              = require(ReplicatedStorage.Packages.Knit)
local MovementConfig    = require(ReplicatedStorage.Shared.MovementConfig)
local AnimationConfig   = require(ReplicatedStorage.Shared.AnimationConfig)
local CharacterState    = require(script.Parent.Parent.Modules.CharacterState)



local MovementService = Knit.CreateService {
    Name   = "MovementService",
    Client = {
        DashHitSignal = Knit.CreateSignal(),
    },
}

function MovementService:KnitInit() end

function MovementService:KnitStart()
    self.BlockService = Knit.GetService("BlockService")
end



local function isAttackingFromBehind(attackerRoot, victimRoot)
    local toAttacker = (attackerRoot.Position - victimRoot.Position).Unit
    return victimRoot.CFrame.LookVector:Dot(toAttacker) < 0
end

local function applyStun(humanoid, character, targetPlayer, duration)
    if targetPlayer then
        CharacterState.SetStunned(targetPlayer, duration)
    end
    
    local stamp = os.clock()
    character:SetAttribute("StunStamp", stamp)
    character:SetAttribute("IsStunned", true)

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local anim  = Instance.new("Animation")
    anim.AnimationId = AnimationConfig.Estados.Stunned.Id
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track:Play(0.1, 1, 1)

    if humanoid.WalkSpeed > 0 then
        character:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
    end
    humanoid.WalkSpeed = 0

    task.delay(duration, function()
        if humanoid and character:GetAttribute("StunStamp") == stamp then
            humanoid.WalkSpeed = character:GetAttribute("BaseWalkSpeed") or 16
            character:SetAttribute("IsStunned", false)
        end
        if track then track:Stop() end
        if anim  then anim:Destroy() end
    end)
end




function MovementService.Client:RequestDash(player, dashName)
    local dashConfig = MovementConfig.Dashs[dashName]
	if not dashConfig then return false end
	
	
	
	local character = player.Character
	local humanoid  = character and character:FindFirstChild("Humanoid")
	if not humanoid then return false end
	
	if humanoid.FloorMaterial == Enum.Material.Air then 
		return false 
	end
	
	
	if not CharacterState.ConsumeStamina(player, dashConfig.staminaCost) then return false end
    if not CharacterState.CanDash(player, dashConfig.cooldown) then return false end
    return true
end


function MovementService.Client:ProcessDashHit(player, enemyCharacter, dashName)
    local dashConfig    = MovementConfig.Dashs[dashName]
    local character     = player.Character
    if not dashConfig or not character then return end

    local rootPart      = character:FindFirstChild("HumanoidRootPart")
    local enemyRoot     = enemyCharacter:FindFirstChild("HumanoidRootPart")
    local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
    if not rootPart or not enemyRoot or not enemyHumanoid then return end
    if enemyHumanoid.Health <= 0 then return end

    local maxDist = (dashConfig.speed * dashConfig.duration) + 8
    if (rootPart.Position - enemyRoot.Position).Magnitude > maxDist then return end

    local victimPlayer = Players:GetPlayerFromCharacter(enemyCharacter)
    local isBlocking   = (victimPlayer and CharacterState.IsBlocking(victimPlayer))
                      or enemyCharacter:GetAttribute("IsBlocking") == true

    if isBlocking then
        if isAttackingFromBehind(rootPart, enemyRoot) then
            if victimPlayer then
                self.BlockService:BreakBlock(victimPlayer)
            end
        else
            return
        end
    end

    enemyHumanoid:TakeDamage(dashConfig.damage)
	applyStun(enemyHumanoid, enemyCharacter, victimPlayer, dashConfig.stunDuration)

    self.DashHitSignal:Fire(player)
end

return MovementService