local RebirthService = {}

local DataService
local NetworkService
local GameConfig

function RebirthService:Init(services)
	DataService = services.DataService
	NetworkService = services.NetworkService
	GameConfig = services.GameConfig
end

function RebirthService:GetClientState(profile)
	local requiredEnergy = GameConfig.GetRebirthEnergyRequirement(profile.Rebirths)
	return {
		RequiredEnergy = requiredEnergy,
		RequiredPower = GameConfig.Rebirth.PowerRequired,
		RewardCrystals = GameConfig.GetRebirthCrystalReward(profile.Rebirths),
		CanRebirth = profile.Energy >= requiredEnergy and profile.Power >= GameConfig.Rebirth.PowerRequired,
	}
end

function RebirthService:Rebirth(player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	local state = self:GetClientState(profile)
	if not state.CanRebirth then
		NetworkService:Toast(
			player,
			string.format("Rebirth needs %s Energy and Power %s.", state.RequiredEnergy, state.RequiredPower),
			"Warning"
		)
		return false
	end

	profile.Rebirths += 1
	profile.PowerCrystals += state.RewardCrystals
	profile.Energy = 0
	profile.Power = 1
	profile.UnlockedWorlds = { Starter = true }
	profile.Stats.RebirthsCompleted += 1

	NetworkService:PushState(player)
	NetworkService:Toast(
		player,
		string.format("REBIRTH! +%s Power Crystal%s", state.RewardCrystals, state.RewardCrystals == 1 and "" or "s"),
		"Rare"
	)

	return true
end

return RebirthService
