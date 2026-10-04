local HttpService = game:GetService("HttpService")

local CompanionService = {}

local DataService
local EconomyService
local NetworkService
local QuestService
local AchievementService
local AnalyticsService
local MonetizationService
local GameConfig
local definitionsById = {}
local random = Random.new()

local function findOwnedByUid(profile, uid)
	for _, companion in ipairs(profile.Companions or {}) do
		if companion.Uid == uid then
			return companion
		end
	end
	return nil
end

local function isEquipped(profile, uid)
	for _, equippedUid in ipairs(profile.EquippedCompanions or {}) do
		if equippedUid == uid then
			return true
		end
	end
	return false
end

function CompanionService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	NetworkService = services.NetworkService
	QuestService = services.QuestService
	AchievementService = services.AchievementService
	AnalyticsService = services.AnalyticsService
	MonetizationService = services.MonetizationService
	GameConfig = services.GameConfig

	for _, definition in ipairs(GameConfig.Companions.StarterEgg.Pool) do
		definitionsById[definition.Id] = definition
	end
end

function CompanionService:_rollStarterEgg()
	local pool = GameConfig.Companions.StarterEgg.Pool
	local totalWeight = 0
	for _, definition in ipairs(pool) do
		totalWeight += definition.Weight
	end

	local roll = random:NextNumber(0, totalWeight)
	local cursor = 0
	for _, definition in ipairs(pool) do
		cursor += definition.Weight
		if roll <= cursor then
			return definition
		end
	end

	return pool[1]
end

function CompanionService:GetMaxEquipped(profile)
	local max = GameConfig.Companions.MaxEquipped
	if profile and profile.Entitlements and profile.Entitlements.ExtraCompanionSlots then
		max += GameConfig.Companions.ExtraSlotsWithPass
	end
	return max
end

function CompanionService:GetMultiplierFromProfile(profile)
	if not profile then
		return 1
	end

	local multiplier = 1
	for _, uid in ipairs(profile.EquippedCompanions or {}) do
		local owned = findOwnedByUid(profile, uid)
		local definition = owned and definitionsById[owned.Id]
		if definition then
			multiplier += math.max(0, definition.Multiplier - 1)
		end
	end
	return multiplier
end

function CompanionService:GetClientState(profile)
	local ownedState = {}
	for _, owned in ipairs(profile.Companions or {}) do
		local definition = definitionsById[owned.Id]
		if definition then
			table.insert(ownedState, {
				Uid = owned.Uid,
				Id = owned.Id,
				Name = definition.Name,
				Rarity = definition.Rarity,
				Multiplier = definition.Multiplier,
				Level = owned.Level or 1,
				Equipped = isEquipped(profile, owned.Uid),
			})
		end
	end

	return {
		OwnedCount = #ownedState,
		EquippedCount = #(profile.EquippedCompanions or {}),
		MaxEquipped = self:GetMaxEquipped(profile),
		Multiplier = self:GetMultiplierFromProfile(profile),
		EggCost = GameConfig.Companions.StarterEgg.Cost,
		Owned = ownedState,
	}
end

function CompanionService:ToggleEquip(player, uid)
	if type(uid) ~= "string" or #uid > 64 then
		return false
	end

	local profile = DataService:GetProfile(player)
	local owned = profile and findOwnedByUid(profile, uid)
	if not owned then
		return false
	end

	if isEquipped(profile, uid) then
		for index, equippedUid in ipairs(profile.EquippedCompanions) do
			if equippedUid == uid then
				table.remove(profile.EquippedCompanions, index)
				break
			end
		end
	else
		if #profile.EquippedCompanions >= self:GetMaxEquipped(profile) then
			NetworkService:Toast(player, "Your companion slots are full.", "Warning")
			return false
		end
		table.insert(profile.EquippedCompanions, uid)
	end

	NetworkService:PushState(player)
	return true
end

function CompanionService:HatchStarterEgg(player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	local cost = GameConfig.Companions.StarterEgg.Cost
	if not EconomyService:SpendEnergy(player, cost, "StarterEgg") then
		NetworkService:Toast(player, string.format("You need %s Energy to hatch.", cost), "Warning")
		return false
	end

	local definition = self:_rollStarterEgg()
	local companion = {
		Uid = HttpService:GenerateGUID(false),
		Id = definition.Id,
		Level = 1,
	}
	table.insert(profile.Companions, companion)
	profile.Stats.EggsHatched += 1

	if #profile.EquippedCompanions < self:GetMaxEquipped(profile) then
		table.insert(profile.EquippedCompanions, companion.Uid)
	end

	QuestService:Update(player, "hatch_1", 1)
	AchievementService:Evaluate(player)
	AnalyticsService:Custom(player, "CompanionHatched", 1, definition.Rarity)
	NetworkService:PushState(player)

	local tone = (definition.Rarity == "Legendary" or definition.Rarity == "Mythic") and "Rare" or "Success"
	NetworkService:Toast(
		player,
		string.format("Hatched %s [%s] • x%.2f", definition.Name, definition.Rarity, definition.Multiplier),
		tone
	)

	return true, definition.Id
end

return CompanionService
