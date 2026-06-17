local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players        = game:GetService("Players")
local Knit           = require(ReplicatedStorage.Packages.Knit)
local CombatConfig   = require(ReplicatedStorage.Shared.CombatConfig)
local AnimationConfig = require(ReplicatedStorage.Shared.AnimationConfig)
local CharacterState = require(script.Parent.Parent.Modules.CharacterState)




local CombatService = Knit.CreateService {
    Name   = "CombatService",
    Client = {
        AttackSignal = Knit.CreateSignal(),
    },
}

local ANTI_CHEAT_DISTANCE_MARGIN = 7 

function CombatService:KnitInit()
    CharacterState.Init()
end

function CombatService:KnitStart()
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


local function resolveBlock(self, attacker, humanoid)
    local targetPlayer  = Players:GetPlayerFromCharacter(humanoid.Parent)
    local isBlocking    = (targetPlayer and CharacterState.IsBlocking(targetPlayer))
                       or humanoid.Parent:GetAttribute("IsBlocking") == true
	
	if not isBlocking then return true end
	
    local attackerRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
    local victimRoot   = humanoid.Parent:FindFirstChild("HumanoidRootPart")

    if not attackerRoot or not victimRoot then return false end

    
    if isAttackingFromBehind(attackerRoot, victimRoot) then
        if targetPlayer then
            self.BlockService:BreakBlock(targetPlayer)
        end
        return true
    end

    
	if targetPlayer then
		local blockDuration = CharacterState.GetBlockDuration(targetPlayer)
		if blockDuration <= CombatConfig.Block.ParryWindow then
			print("¡PARRY PERFECTO!")
			applyStun(attacker.Character.Humanoid, attacker.Character, attacker, 1.5)
		end
	end

    return false
end



function CombatService:ApplyDamage(attacker, humanoid, damage)
    if humanoid.Health <= 0 then return end
    if not resolveBlock(self, attacker, humanoid) then return end

    local targetPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)

    humanoid:TakeDamage(damage)
    applyStun(humanoid, humanoid.Parent, targetPlayer, CombatConfig.StunDuration)
end




function CombatService.Client:Attack(player, attackName, count)
    local attackData = CombatConfig.Attacks[attackName]
    if not attackData                                          then return false end
    if not player.Character                                    then return false end
    if not CharacterState.CanAttack(player, attackData.Cooldown) then return false end
    return true
end


function CombatService.Client:ProcessHit(player, enemyCharacter, attackName)
    local attackData   = CombatConfig.Attacks[attackName]
    local character    = player.Character
    if not attackData or not character then return false end

    local rootPart     = character:FindFirstChild("HumanoidRootPart")
    local enemyRoot    = enemyCharacter:FindFirstChild("HumanoidRootPart")
    local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
    if not rootPart or not enemyRoot or not enemyHumanoid then return false end

    local maxDist = math.max(attackData.HitboxSize.X, attackData.HitboxSize.Z) + ANTI_CHEAT_DISTANCE_MARGIN
    if (rootPart.Position - enemyRoot.Position).Magnitude > maxDist then return false end

    if CharacterState.IsStunned(player) or CharacterState.IsBlocking(player) then return false end

    self.Server:ApplyDamage(player, enemyHumanoid, attackData.Damage)
    return true
end

return CombatService