local DailyRewardService = {}

local DataService
local EconomyService
local NetworkService
local AnalyticsService
local GameConfig

local DAY = 86400

local function dayIndex(timestamp)
	return math.floor((timestamp or os.time()) / DAY)
end

function DailyRewardService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	NetworkService = services.NetworkService
	AnalyticsService = services.AnalyticsService
	GameConfig = services.GameConfig
end

function DailyRewardService:GetClientState(profile)
	local today = dayIndex(os.time())
	local last = profile.LastDailyClaim > 0 and dayIndex(profile.LastDailyClaim) or -1
	local canClaim = today > last
	local projectedStreak = profile.DailyStreak
	if canClaim then
		projectedStreak = last == today - 1 and (profile.DailyStreak + 1) or 1
	end
	local rewardIndex = ((math.max(1, projectedStreak) - 1) % #GameConfig.DailyRewards) + 1
	local reward = GameConfig.DailyRewards[rewardIndex]

	return {
		CanClaim = canClaim,
		Streak = profile.DailyStreak,
		NextDay = rewardIndex,
		Energy = reward.Energy,
		Crystals = reward.Crystals,
	}
end

function DailyRewardService:Claim(player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	local today = dayIndex(os.time())
	local last = profile.LastDailyClaim > 0 and dayIndex(profile.LastDailyClaim) or -1
	if today <= last then
		NetworkService:Toast(player, "Today's reward is already claimed.", "Warning")
		return false
	end

	if last == today - 1 then
		profile.DailyStreak += 1
	else
		profile.DailyStreak = 1
	end

	local rewardIndex = ((profile.DailyStreak - 1) % #GameConfig.DailyRewards) + 1
	local reward = GameConfig.DailyRewards[rewardIndex]
	profile.LastDailyClaim = os.time()
	profile.Stats.DailyClaims += 1

	if reward.Energy > 0 then
		EconomyService:AddEnergy(player, reward.Energy, "DailyReward")
	end
	if reward.Crystals > 0 then
		profile.PowerCrystals += reward.Crystals
	end

	AnalyticsService:Custom(player, "DailyRewardClaimed", 1, tostring(rewardIndex))
	NetworkService:PushState(player)
	NetworkService:Toast(
		player,
		string.format("Daily Day %s: +%s Energy%s", rewardIndex, reward.Energy, reward.Crystals > 0 and (" + " .. reward.Crystals .. " Crystal") or ""),
		"Success"
	)
	return true
end

return DailyRewardService
