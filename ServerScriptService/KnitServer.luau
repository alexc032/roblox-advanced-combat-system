local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)


for _, service in ipairs(script.Parent.Services:GetChildren()) do
    if service:IsA("ModuleScript") then
        require(service)
    end
end


Knit.Start():andThen(function()
end):catch(warn)
