local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit          = require(ReplicatedStorage.Packages.Knit)
local CharacterState = require(script.Parent.Parent.Modules.CharacterState)


local BlockService = Knit.CreateService {
    Name   = "BlockService",
    Client = {
        BlockSignal       = Knit.CreateSignal(),
        BlockBrokenSignal = Knit.CreateSignal(),
    },
}

function BlockService:KnitInit() end
function BlockService:KnitStart() end


function BlockService.Client:StartBlock(player)
    if CharacterState.SetBlocking(player, true) then
        self.BlockSignal:Fire(player, true)
    end
end

function BlockService.Client:StopBlock(player)
    if CharacterState.SetBlocking(player, false) then
        self.BlockSignal:Fire(player, false)
    end
end

function BlockService:BreakBlock(player)
    if CharacterState.SetBlocking(player, false) then
        self.Client.BlockBrokenSignal:Fire(player)
    end
end

return BlockService