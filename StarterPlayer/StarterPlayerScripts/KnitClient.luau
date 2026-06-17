local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)


for _, controller in ipairs(script.Parent.Controllers:GetChildren()) do
    if controller:IsA("ModuleScript") then
        require(controller)
    end
end


Knit.Start():andThen(function()
end):catch(warn)
