local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers    = require(ReplicatedStorage.Packages.Observers)
local Trove        = require(ReplicatedStorage.Packages.Trove)
local MovementConfig = require(game.ReplicatedStorage.Shared.MovementConfig)




local CharacterState = {}
local characterData  = {} 

local ATTACK_LOCK_DURATION = 0.3 
local DASH_LOCK_DURATION   = 0.5 
local MAX_COMBO             = 5
local COMBO_RESET_WINDOW    = 1   

local function newData()
    return {
        LastAttack   = 0,
        LastDash     = 0,
        LastStunTime = 0,
        Combo        = 0,
        IsStunned    = false,
		IsBlocking   = false,
		BlockStartTime = 0,
		Stamina = 100,
		MaxStamina = 100,
    }
end

local function syncAttributes(player, data)
    local char = player.Character
    if not char then return end
    char:SetAttribute("IsBlocking", data.IsBlocking)
	char:SetAttribute("IsStunned",  data.IsStunned)
	char:SetAttribute("Stamina", data.Stamina)
end

function CharacterState.Init()
    Observers.observeCharacter(function(player, _character)
        characterData[player] = newData()
        return function()
            characterData[player] = nil
        end
	end)
	
	task.spawn(function()
		while task.wait(1) do
			for player, data in pairs(characterData) do
				if data.Stamina < data.MaxStamina then
					data.Stamina = math.min(data.Stamina + 5, data.MaxStamina) 
					syncAttributes(player, data)
				end
			end
		end
	end)
end

function CharacterState.Get(player)
    return characterData[player]
end

function CharacterState.CanAttack(player, cooldown)
    local data = characterData[player]
    if not data              then return false end
    if data.IsStunned        then return false end
    if data.IsBlocking       then return false end
	
	
    local now = os.clock()
    if now < data.LastAttack + cooldown then return false end

	local dashConfig = MovementConfig.Dashs["Frontal"]
	local timeSinceDash = now - data.LastDash
	if timeSinceDash < (dashConfig.duration + dashConfig.postDashAttackDelay) then 
		return false 
	end

    data.Combo       = (now - data.LastAttack > COMBO_RESET_WINDOW) and 1 or math.min(data.Combo + 1, MAX_COMBO)
    data.LastAttack  = now
    return true
end

function CharacterState.CanDash(player, cooldown)
    local data = characterData[player]
    if not data        then return false end
    if data.IsStunned  then return false end
    if data.IsBlocking then return false end

    local now = os.clock()
    if now < data.LastDash + cooldown then return false end

    data.LastDash = now
    return true
end

function CharacterState.SetStunned(player, duration)
    local data = characterData[player]
    if not data then return end

    data.IsStunned   = true
    data.IsBlocking  = false
    local stamp      = os.clock()
    data.LastStunTime = stamp

    syncAttributes(player, data)

    task.delay(duration, function()
        local d = characterData[player]
        if d and d.LastStunTime == stamp then
            d.IsStunned = false
            syncAttributes(player, d)
        end
    end)
end

function CharacterState.SetBlocking(player, state)
    local data = characterData[player]
    if not data then return false end

    if state then
        if data.IsStunned                               then return false end
        if os.clock() - data.LastAttack < ATTACK_LOCK_DURATION then return false end
        if os.clock() - data.LastDash   < DASH_LOCK_DURATION   then return false end
    end

	data.IsBlocking = state
	data.BlockStartTime = os.clock()
    syncAttributes(player, data)
    return true
end

function CharacterState.IsBlocking(player)
    local data = characterData[player]
    return data and data.IsBlocking or false
end

function CharacterState.IsStunned(player)
    local data = characterData[player]
    return data and data.IsStunned or false
end

function CharacterState.GetBlockDuration(player)
	local data = characterData[player]
	if not data then return 999 end
	return os.clock() - data.BlockStartTime
end


function CharacterState.ConsumeStamina(player, amount)
	local data = characterData[player]
	if not data or data.Stamina < amount then return false end
	
	data.Stamina -= amount
	syncAttributes(player, data)
	return true
end

return CharacterState