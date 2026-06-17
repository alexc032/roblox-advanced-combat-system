local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InputController = Knit.CreateController {
    Name = "InputController",
}

function InputController:KnitInit()
    self.Trove = Trove.new()
    
    self.AttackRequested = Signal.new()
    self.DashRequested = Signal.new()
    self.BlockPressed = Signal.new()
    self.BlockReleased = Signal.new()
end

function InputController:KnitStart()
    self.Trove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.AttackRequested:Fire()
        elseif input.KeyCode == Enum.KeyCode.Q then
            self.DashRequested:Fire()
        elseif input.KeyCode == Enum.KeyCode.F then
            self.BlockPressed:Fire()
        end
    end)
    
    self.Trove:Connect(UserInputService.InputEnded, function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F then
            self.BlockReleased:Fire()
        end
    end)
end

return InputController