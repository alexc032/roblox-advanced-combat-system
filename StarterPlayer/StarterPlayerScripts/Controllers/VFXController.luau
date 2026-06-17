local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")
local Knit              = require(ReplicatedStorage.Packages.Knit)




local VFXController = Knit.CreateController {
    Name = "VFXController",
}

local EFFECT_LIFETIME = 0.15 

function VFXController:KnitInit()
    self.ParticlesFolder = ReplicatedStorage:WaitForChild("Particles")
end

function VFXController:KnitStart() end


function VFXController:PlayHitEffect(position, targetPart, isHeavy)
    if not targetPart then return end

    local electricTemplate = self.ParticlesFolder:FindFirstChild("HitVfx")
    if electricTemplate and electricTemplate:IsA("BasePart") then
        local effect    = electricTemplate:Clone()
        effect.Position = position

        for _, obj in ipairs(effect:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj:Emit(10)
            end
        end

        effect.Parent = workspace
        Debris:AddItem(effect, EFFECT_LIFETIME)
    end
	
	if isHeavy then
		local soundTemplate = self.ParticlesFolder:FindFirstChild("HeavyHitSound")
		if soundTemplate and soundTemplate:IsA("Sound") then
			local sound   = soundTemplate:Clone()
			sound.Parent  = targetPart
			sound:Play()
			Debris:AddItem(sound, math.max(sound.TimeLength, 0.5) + 0.1)
		end
	else
		local soundTemplate = self.ParticlesFolder:FindFirstChild("HitSound")
		if soundTemplate and soundTemplate:IsA("Sound") then
			local sound   = soundTemplate:Clone()
			sound.Parent  = targetPart
			sound:Play()
			Debris:AddItem(sound, math.max(sound.TimeLength, 0.5) + 0.1)
		end
	end
end

return VFXController