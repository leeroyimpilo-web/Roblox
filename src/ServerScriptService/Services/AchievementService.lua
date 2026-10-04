local AchievementService = {}

local DataService
local NetworkService
local GameConfig

local function has(profile, id)
	return profile.Achievements and profile.Achievements[id] == true
end

local function qualifies(profile, id)
	if id == "energy_1k" then
		return profile.Stats.LifetimeEnergy >= 1_000
	elseif id == "nodes_100" then
		return profile.Stats.EnergyNodesCollected >= 100
	elseif id == "pets_5" then
		return profile.Stats.EggsHatched >= 5
	elseif id == "jungle" then
		return profile.UnlockedWorlds.Jungle == true
	elseif id == "rebirth_1" then
		return profile.Rebirths >= 1
	elseif id == "boss_1" then
		return profile.Stats.BossKills >= 1
	end
	return false
end

function AchievementService:Init(services)
	DataService = services.DataService
	NetworkService = services.NetworkService
	GameConfig = services.GameConfig
end

function AchievementService:Evaluate(player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return
	end

	profile.Achievements = profile.Achievements or {}
	local awarded = false

	for _, definition in ipairs(GameConfig.Achievements) do
		if not has(profile, definition.Id) and qualifies(profile, definition.Id) then
			profile.Achievements[definition.Id] = true
			profile.PowerCrystals += definition.RewardCrystals or 0
			awarded = true
			NetworkService:Toast(
				player,
				string.format("Achievement: %s • +%s Crystal%s", definition.Name, definition.RewardCrystals or 0, (definition.RewardCrystals or 0) == 1 and "" or "s"),
				"Rare"
			)
		end
	end

	if awarded then
		NetworkService:PushState(player)
	end
end

function AchievementService:GetClientState(profile)
	local result = {}
	for _, definition in ipairs(GameConfig.Achievements) do
		table.insert(result, {
			Id = definition.Id,
			Name = definition.Name,
			Description = definition.Description,
			Completed = has(profile, definition.Id),
			RewardCrystals = definition.RewardCrystals,
		})
	end
	return result
end

return AchievementService
