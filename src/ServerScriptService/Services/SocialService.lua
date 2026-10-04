local Players = game:GetService("Players")

local SocialService = {}
local friendCounts = {}
local NetworkService
local GameConfig

local function areFriends(a, b)
	local ok, result = pcall(function()
		return a:IsFriendsWith(b.UserId)
	end)
	return ok and result == true
end

function SocialService:Init(services)
	NetworkService = services.NetworkService
	GameConfig = services.GameConfig
end

function SocialService:RefreshAll()
	local players = Players:GetPlayers()

	for _, player in ipairs(players) do
		local count = 0
		for _, other in ipairs(players) do
			if other ~= player and areFriends(player, other) then
				count += 1
			end
		end
		friendCounts[player] = count
	end

	if NetworkService then
		NetworkService:PushAll()
	end
end

function SocialService:GetMultiplier(player)
	local count = friendCounts[player] or 0
	local bonus = math.min(count * GameConfig.Social.FriendBonusPerFriend, GameConfig.Social.MaxFriendBonus)
	return 1 + bonus
end

function SocialService:GetClientState(player)
	local count = friendCounts[player] or 0
	return {
		FriendsInServer = count,
		Multiplier = self:GetMultiplier(player),
		MaxBonus = GameConfig.Social.MaxFriendBonus,
	}
end

function SocialService:Start()
	Players.PlayerAdded:Connect(function()
		task.delay(2, function()
			self:RefreshAll()
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		friendCounts[player] = nil
		task.defer(function()
			self:RefreshAll()
		end)
	end)

	task.delay(2, function()
		self:RefreshAll()
	end)
end

return SocialService
