local GameConfig = {}

GameConfig.GameName = "Power Islands: Steal the Core"
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
	ExtraSlotsWithPass = 2,
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
	CrystalEnergyBonus = 0.05,
}

GameConfig.Quests = {
	{ Id = "collect_10", Title = "Energy Hunter", Description = "Collect 10 Energy nodes", Target = 10, RewardEnergy = 150 },
	{ Id = "power_3", Title = "Power Up", Description = "Buy 3 Power upgrades", Target = 3, RewardEnergy = 300 },
	{ Id = "hatch_1", Title = "New Friend", Description = "Hatch your first companion", Target = 1, RewardEnergy = 400 },
	{ Id = "raid_1", Title = "First Heist", Description = "Steal and bank a Power Core fragment", Target = 1, RewardEnergy = 1_000 },
}

GameConfig.DailyRewards = {
	{ Energy = 250, Crystals = 0 },
	{ Energy = 500, Crystals = 0 },
	{ Energy = 1_000, Crystals = 0 },
	{ Energy = 2_000, Crystals = 0 },
	{ Energy = 4_000, Crystals = 0 },
	{ Energy = 7_500, Crystals = 1 },
	{ Energy = 15_000, Crystals = 2 },
}

GameConfig.Achievements = {
	{ Id = "energy_1k", Name = "Charged Up", Description = "Earn 1,000 lifetime Energy", RewardCrystals = 1 },
	{ Id = "nodes_100", Name = "Collector", Description = "Collect 100 Energy nodes", RewardCrystals = 1 },
	{ Id = "pets_5", Name = "Pack Leader", Description = "Hatch 5 companions", RewardCrystals = 2 },
	{ Id = "jungle", Name = "Explorer", Description = "Unlock Jungle Island", RewardCrystals = 2 },
	{ Id = "rebirth_1", Name = "Born Again", Description = "Complete your first rebirth", RewardCrystals = 3 },
	{ Id = "boss_1", Name = "Boss Breaker", Description = "Defeat the Jungle Titan", RewardCrystals = 3 },
	{ Id = "raid_1", Name = "Core Thief", Description = "Complete your first successful Core raid", RewardCrystals = 2 },
	{ Id = "core_5", Name = "Reactor Online", Description = "Evolve your Power Core to Level 5", RewardCrystals = 3 },
}

GameConfig.Codes = {
	LAUNCH = { Energy = 1_000, Crystals = 0 },
	JUNGLE = { Energy = 2_500, Crystals = 0 },
	POWERUP = { Energy = 750, Crystals = 1 },
}

GameConfig.Social = {
	FriendBonusPerFriend = 0.05,
	MaxFriendBonus = 0.25,
}

GameConfig.LiveEvents = {
	IntervalSeconds = 600,
	DurationSeconds = 150,
	Pool = {
		{ Id = "PowerSurge", Name = "POWER SURGE", EnergyMultiplier = 2, CoreMultiplier = 1 },
		{ Id = "LuckyRush", Name = "LUCKY RUSH", EnergyMultiplier = 1.5, CoreMultiplier = 1.5 },
		{ Id = "MegaCharge", Name = "MEGA CHARGE", EnergyMultiplier = 3, CoreMultiplier = 1 },
		{ Id = "CoreMeltdown", Name = "CORE MELTDOWN", EnergyMultiplier = 1, CoreMultiplier = 4 },
	},
}

GameConfig.Boss = {
	Name = "Jungle Titan",
	MaxHealth = 500,
	RespawnSeconds = 60,
	AttackCooldown = 0.8,
	BaseRewardEnergy = 5_000,
}

GameConfig.Raid = {
	ArenaCenter = Vector3.new(1000, 55, 0),
	MaxBases = 20,
	RingRadius = 260,
	IslandSize = 72,
	HubSize = 100,
	Core = {
		BaseRatePerSecond = 2,
		RatePerLevel = 1.25,
		BaseCapacity = 500,
		CapacityGrowth = 1.45,
		BaseUpgradeCost = 500,
		UpgradeCostGrowth = 1.65,
		MaxLevel = 50,
	},
	Steal = {
		Percent = 0.20,
		MinimumCharge = 25,
		MaxAmount = 2_500,
		BankMultiplier = 1.25,
		HoldDuration = 1.25,
		TargetCooldownSeconds = 45,
		ShieldOnJoinSeconds = 30,
		ShieldAfterTheftSeconds = 20,
	},
	Wanted = {
		StartsAtStreak = 2,
		BountyPerStreak = 500,
		MaxBounty = 10_000,
	},
	Revenge = {
		WindowSeconds = 900,
		PayoutMultiplier = 1.50,
	},
	Trap = {
		MaxLevel = 5,
		BaseUpgradeCost = 1_000,
		UpgradeCostGrowth = 2,
		CooldownSeconds = 20,
		BaseSlowSeconds = 2.5,
		SlowPerLevel = 0.5,
		SlowWalkSpeed = 8,
	},
	MegaCore = {
		IntervalSeconds = 720,
		WarningSeconds = 20,
		DurationSeconds = 120,
		MaxDrains = 40,
		DrainCooldownSeconds = 4,
		BaseRewardEnergy = 1_000,
		WeeklyPointsPerDrain = 2,
	},
	Leaderboard = {
		RefreshSeconds = 30,
		TopCount = 10,
	},
	CoreSkins = {
		{ Id = "Default", Name = "Neon Blue", Color = Color3.fromRGB(62, 224, 255), Requirement = "Starter" },
		{ Id = "Solar", Name = "Solar Gold", Color = Color3.fromRGB(255, 176, 48), Requirement = "Core Level 5" },
		{ Id = "Toxic", Name = "Toxic Green", Color = Color3.fromRGB(95, 255, 94), Requirement = "5 successful raids" },
		{ Id = "Void", Name = "Void Purple", Color = Color3.fromRGB(125, 74, 255), Requirement = "Core Level 20" },
		{ Id = "Galaxy", Name = "Galaxy Pink", Color = Color3.fromRGB(255, 75, 190), Requirement = "Core Level 50" },
	},
}

GameConfig.Monetization = {
	-- Replace 0 values after creating the items in Creator Hub.
	Passes = {
		VIP = 0,
		DoubleEnergy = 0,
		ExtraCompanionSlots = 0,
		Hoverboard = 0,
	},
	Products = {
		Energy5K = 0,
		Energy50K = 0,
		ServerBoost = 0,
		InstantRebirth = 0,
	},
	SubscriptionId = "",
}

GameConfig.AdminUserIds = {
	-- Add your Roblox numeric UserId here before using admin chat commands.
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
	Achievements = {},
	CodesRedeemed = {},
	Entitlements = {},
	ProcessedReceipts = {},
	DailyStreak = 0,
	LastDailyClaim = 0,
	LastSeen = 0,
	PlaytimeSeconds = 0,
	CoreLevel = 1,
	CoreCharge = 75,
	CoreRaidScore = 0,
	CoreSkin = "Default",
	UnlockedCoreSkins = { Default = true },
	TrapLevel = 0,
	WeeklyRaidScore = 0,
	WeeklyRaidKey = "",
	WantedStreak = 0,
	WantedBounty = 0,
	Settings = {
		Music = true,
		SFX = true,
	},
	Stats = {
		LifetimeEnergy = 0,
		EnergyNodesCollected = 0,
		PowerUpgradesBought = 0,
		EggsHatched = 0,
		WorldsUnlocked = 0,
		RebirthsCompleted = 0,
		BossKills = 0,
		DailyClaims = 0,
		CodesRedeemed = 0,
		Purchases = 0,
		CoreEnergyClaimed = 0,
		CoreFragmentsStolen = 0,
		CoreFragmentsLost = 0,
		RaidDefenses = 0,
		MegaCoreDrains = 0,
		TrapTriggers = 0,
		RevengeHeists = 0,
		BountiesClaimed = 0,
	},
}

function GameConfig.GetTrapUpgradeCost(level)
	level = math.max(0, math.floor(tonumber(level) or 0))
	return math.floor(GameConfig.Raid.Trap.BaseUpgradeCost * (GameConfig.Raid.Trap.UpgradeCostGrowth ^ level))
end

function GameConfig.GetTrapSlowSeconds(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	return GameConfig.Raid.Trap.BaseSlowSeconds + ((level - 1) * GameConfig.Raid.Trap.SlowPerLevel)
end

function GameConfig.GetCoreSkin(skinId)
	for _, skin in ipairs(GameConfig.Raid.CoreSkins) do
		if skin.Id == skinId then
			return skin
		end
	end
	return GameConfig.Raid.CoreSkins[1]
end

function GameConfig.GetCoreRate(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	return GameConfig.Raid.Core.BaseRatePerSecond + ((level - 1) * GameConfig.Raid.Core.RatePerLevel)
end

function GameConfig.GetCoreCapacity(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	return math.floor(GameConfig.Raid.Core.BaseCapacity * (GameConfig.Raid.Core.CapacityGrowth ^ (level - 1)))
end

function GameConfig.GetCoreUpgradeCost(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	return math.floor(GameConfig.Raid.Core.BaseUpgradeCost * (GameConfig.Raid.Core.UpgradeCostGrowth ^ (level - 1)))
end

function GameConfig.GetCoreName(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	if level >= 50 then
		return "Galaxy Core"
	elseif level >= 35 then
		return "Black Hole Core"
	elseif level >= 20 then
		return "Dragon Core"
	elseif level >= 10 then
		return "Plasma Core"
	elseif level >= 5 then
		return "Reactor Core"
	end
	return "Spark Core"
end

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
