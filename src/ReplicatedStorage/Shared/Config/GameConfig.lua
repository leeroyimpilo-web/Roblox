local GameConfig = {}

GameConfig.GameName = "Power Islands"
GameConfig.DataVersion = 1
GameConfig.AutoSaveSeconds = 60

GameConfig.Currencies = {
	Primary = "Energy",
	PremiumProgression = "PowerCrystals",
}

GameConfig.Worlds = {
	{ Id = "Starter", Name = "Starter Island", UnlockCost = 0 },
	{ Id = "Jungle", Name = "Jungle Island", UnlockCost = 5_000 },
	{ Id = "Ice", Name = "Ice World", UnlockCost = 50_000 },
	{ Id = "Volcano", Name = "Volcano", UnlockCost = 500_000 },
	{ Id = "Cyber", Name = "Cyber City", UnlockCost = 5_000_000 },
	{ Id = "Space", Name = "Space", UnlockCost = 50_000_000 },
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

GameConfig.DefaultProfile = {
	Energy = 0,
	PowerCrystals = 0,
	Power = 1,
	Rebirths = 0,
	UnlockedWorlds = { Starter = true },
	Companions = {},
	EquippedCompanions = {},
	DailyStreak = 0,
	LastDailyClaim = 0,
	PlaytimeSeconds = 0,
	Stats = {
		LifetimeEnergy = 0,
		EnergyNodesCollected = 0,
		PowerUpgradesBought = 0,
	},
}

function GameConfig.GetPowerUpgradeCost(power)
	power = math.max(1, math.floor(tonumber(power) or 1))
	return math.floor(GameConfig.PowerUpgrade.BaseCost * (GameConfig.PowerUpgrade.Growth ^ (power - 1)))
end

return GameConfig
