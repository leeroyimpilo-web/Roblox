local Players = game:GetService("Players")

local WantedService = {}
local Services

local revengeTargets = {}
local recentVictims = {}

function WantedService:Init(services)
	Services = services
end

function WantedService:_recalculateBounty(profile)
	local cfg = Services.GameConfig.Raid.Wanted
	if profile.WantedStreak >= cfg.StartsAtStreak then
		profile.WantedBounty = math.min(cfg.MaxBounty, profile.WantedStreak * cfg.BountyPerStreak)
	else
		profile.WantedBounty = 0
	end
end

function WantedService:OnSuccessfulRaid(thief, victim, amount)
	local thiefProfile = Services.DataService:GetProfile(thief)
	local victimProfile = Services.DataService:GetProfile(victim)
	if not thiefProfile or not victimProfile then
		return
	end

	thiefProfile.WantedStreak += 1
	self:_recalculateBounty(thiefProfile)

	revengeTargets[victim.UserId] = {
		TargetUserId = thief.UserId,
		ExpiresAt = os.time() + Services.GameConfig.Raid.Revenge.WindowSeconds,
	}

	recentVictims[thief.UserId] = victim.UserId

	if thiefProfile.WantedBounty > 0 then
		Services.NetworkService:BannerAll(
			"WANTED PLAYER",
			string.format("%s has a %s Energy bounty!", thief.DisplayName, thiefProfile.WantedBounty),
			4
		)
	end

	Services.AnalyticsService:Custom(thief, "WantedStreak", thiefProfile.WantedStreak)
	Services.NetworkService:PushState(thief)
	Services.NetworkService:PushState(victim)
end

function WantedService:OnRaidBanked(thief, victim, basePayout)
	local thiefProfile = Services.DataService:GetProfile(thief)
	local victimProfile = Services.DataService:GetProfile(victim)
	if not thiefProfile or not victimProfile then
		return basePayout
	end

	local revenge = revengeTargets[thief.UserId]
	local isRevenge = revenge
		and revenge.TargetUserId == victim.UserId
		and revenge.ExpiresAt >= os.time()

	if isRevenge then
		revengeTargets[thief.UserId] = nil
		thiefProfile.Stats.RevengeHeists += 1
		local bonus = math.floor(basePayout * (Services.GameConfig.Raid.Revenge.PayoutMultiplier - 1))
		if bonus > 0 then
			Services.EconomyService:AddEnergy(thief, bonus, "RevengeBonus")
		end
		Services.NetworkService:BannerAll(
			"REVENGE COMPLETE!",
			thief.DisplayName .. " got revenge on " .. victim.DisplayName .. "!",
			4
		)
	end

	if victimProfile.WantedBounty > 0 then
		local bounty = victimProfile.WantedBounty
		victimProfile.WantedStreak = 0
		victimProfile.WantedBounty = 0
		thiefProfile.Stats.BountiesClaimed += 1
		Services.EconomyService:AddEnergy(thief, bounty, "WantedBounty")
		Services.NetworkService:BannerAll(
			"BOUNTY CLAIMED!",
			string.format("%s collected %s Energy from %s!", thief.DisplayName, bounty, victim.DisplayName),
			5
		)
	end

	Services.NetworkService:PushState(thief)
	Services.NetworkService:PushState(victim)
	return basePayout
end

function WantedService:OnDefended(defender, thief)
	local thiefProfile = Services.DataService:GetProfile(thief)
	if thiefProfile then
		thiefProfile.WantedStreak = 0
		thiefProfile.WantedBounty = 0
		Services.NetworkService:PushState(thief)
	end
end

function WantedService:GetClientState(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return nil
	end

	local revenge = revengeTargets[player.UserId]
	if revenge and revenge.ExpiresAt < os.time() then
		revengeTargets[player.UserId] = nil
		revenge = nil
	end

	local target
	if revenge then
		target = Players:GetPlayerByUserId(revenge.TargetUserId)
	end

	return {
		Streak = profile.WantedStreak or 0,
		Bounty = profile.WantedBounty or 0,
		RevengeTarget = target and {
			UserId = target.UserId,
			Name = target.DisplayName,
			ExpiresAt = revenge.ExpiresAt,
		} or nil,
	}
end

function WantedService:Start()
	Players.PlayerRemoving:Connect(function(player)
		revengeTargets[player.UserId] = nil
		recentVictims[player.UserId] = nil
	end)
end

return WantedService
