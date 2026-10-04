local GameConfig = {}

GameConfig.GameName = "Power Islands"
GameConfig.DataVersion = 1
GameConfig.AutoSaveSeconds = 60

GameConfig.Currencies = {
	Primary = "Energy",
	PremiumProgression = "PowerCrystals",
}

GameConfig.Worlds = {
	{ Id = "Starter", Name = "Starter Island", UnlockCost = 0, RewardMultiplier = 1 },
	{ Id = "Jungle", Name = "Jungle Island", UnlockCost = 5_000, RewardMultiplier = 5 },
	{ Id = "Ice", Name = "Ice World", UnlockCost = 50_000, RewardMultiplier = 15 },
	{ Id = "Volcano", Name = "Volcano", UnlockCost = 500_000, RewardMultiplier = 45 },
	{ Id = "Cyber", Name = "Cyber City", UnlockCost = 5_000_000, RewardMultiplier = 140 },
	{ Id = "Space", Name = "Space", UnlockCost = 50_000_000, RewardMultiplier = 450 },
}

GameConfig.PowerUpgrade = {
	BaseCost = 25,
	Growth = 1.55,
	MaxPower = 500,
}

GameConfig.EnergyNodes = {
	Count = 12,
	BaseReward = 5,
	RespawnSeconds = 2,
	InteractionDistance = 14,
}

GameConfig.Companions = {
	MaxEquipped = 3,
	StarterEgg = {
		Cost = 250,
		Pool = {
			{ Id = "SparkPup", Name = "Spark Pup", Rarity = "Common", Weight = 55, Multiplier = 1.10 },
			{ Id = "LeafCub", Name = "Leaf Cub", Rarity = "Rare", Weight = 28, Multiplier = 1.25 },
			{ Id = "VoltFox", Name = "Volt Fox", Rarity = "Epic", Weight = 12, Multiplier = 1.55 },
			{ Id = "BabyDragon", Name = "Baby Dragon", Rarity = "Legendary", Weight = 4, Multiplier = 2.10 },
			{ Id = "CosmicSlime", Name = "Cosmic Slime", Rarity = "Mythic", Weight = 1, Multiplier = 3.00 },
		},
	},
}

GameConfig.Rebirth = {
	BaseEnergyRequirement = 2_500,
	EnergyGrowth = 1.7,
	PowerRequired = 10,
	BaseCrystalReward = 1,
}

GameConfig.Quests = {
	{
		Id = "collect_10",
		Title = "Energy Hunter",
		Description = "Collect 10 Energy nodes",
		Target = 10,
		RewardEnergy = 150,
	},
	{
		Id = "power_3",
		Title = "Power Up",
		Description = "Buy 3 Power upgrades",
		Target = 3,
		RewardEnergy = 300,
	},
	{
		Id = "hatch_1",
		Title = "New Friend",
		Description = "Hatch your first companion",
		Target = 1,
		RewardEnergy = 400,
	},
}

GameConfig.DefaultProfile = {
	Energy = 0,
	PowerCrystals = 0,
	Power = 1,
	Rebirths = 0,
	UnlockedWorlds = { Starter = true },
	Companions = {},
	EquippedCompanions = {},
	Quests = {},
	DailyStreak = 0,
	LastDailyClaim = 0,
	PlaytimeSeconds = 0,
	Stats = {
		LifetimeEnergy = 0,
		EnergyNodesCollected = 0,
		PowerUpgradesBought = 0,
		EggsHatched = 0,
		WorldsUnlocked = 0,
		RebirthsCompleted = 0,
	},
}

function GameConfig.GetPowerUpgradeCost(power)
	power = math.max(1, math.floor(tonumber(power) or 1))
	return math.floor(GameConfig.PowerUpgrade.BaseCost * (GameConfig.PowerUpgrade.Growth ^ (power - 1)))
end

function GameConfig.GetRebirthEnergyRequirement(rebirths)
	rebirths = math.max(0, math.floor(tonumber(rebirths) or 0))
	return math.floor(GameConfig.Rebirth.BaseEnergyRequirement * (GameConfig.Rebirth.EnergyGrowth ^ rebirths))
end

function GameConfig.GetRebirthCrystalReward(rebirths)
	rebirths = math.max(0, math.floor(tonumber(rebirths) or 0))
	return GameConfig.Rebirth.BaseCrystalReward + math.floor(rebirths / 5)
end

function GameConfig.GetWorld(worldId)
	for _, world in ipairs(GameConfig.Worlds) do
		if world.Id == worldId then
			return world
		end
	end
	return nil
end

return GameConfig
