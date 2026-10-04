local Players = game:GetService("Players")

local SecurityService = {}
local lastActions = {}

function SecurityService:Init()
	Players.PlayerRemoving:Connect(function(player)
		lastActions[player] = nil
	end)
end

function SecurityService:Allow(player, key, minInterval)
	if not player or type(key) ~= "string" then
		return false
	end

	minInterval = math.max(0, tonumber(minInterval) or 0.2)
	lastActions[player] = lastActions[player] or {}

	local now = os.clock()
	local previous = lastActions[player][key] or -math.huge
	if now - previous < minInterval then
		return false
	end

	lastActions[player][key] = now
	return true
end

function SecurityService:ShortString(value, maxLength)
	if type(value) ~= "string" then
		return nil
	end
	maxLength = maxLength or 32
	if #value == 0 or #value > maxLength then
		return nil
	end
	return value
end

return SecurityService
