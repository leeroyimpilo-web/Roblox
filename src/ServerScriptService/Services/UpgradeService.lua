local UpgradeService = {}

local DataService
local EconomyService
local NetworkService
local QuestService
local GameConfig

function UpgradeService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	NetworkService = services.NetworkService
	QuestService = services.QuestService
	GameConfig = services.GameConfig
end

function UpgradeService:BuyPowerUpgrade(player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return false, "Profile is still loading."
	end

	if profile.Power >= GameConfig.PowerUpgrade.MaxPower then
		NetworkService:Toast(player, "Power is already maxed!", "Success")
		return false, "Max power"
	end

	local cost = GameConfig.GetPowerUpgradeCost(profile.Power)
	local paid = EconomyService:SpendEnergy(player, cost)
	if not paid then
		NetworkService:Toast(player, string.format("You need %s Energy.", cost), "Warning")
		return false, "Not enough Energy"
	end

	profile.Power += 1
	profile.Stats.PowerUpgradesBought += 1
	QuestService:Update(player, "power_3", 1)
	NetworkService:PushState(player)
	NetworkService:Toast(player, string.format("Power upgraded to %sx!", profile.Power), "Success")
	return true, profile.Power
end

return UpgradeService
