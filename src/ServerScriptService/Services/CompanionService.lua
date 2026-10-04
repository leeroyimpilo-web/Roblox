local HttpService = game:GetService("HttpService")

local CompanionService = {}

local DataService
local EconomyService
local NetworkService
local QuestService
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

function CompanionService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	NetworkService = services.NetworkService
	QuestService = services.QuestService
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
	local equipped = {}
	for _, uid in ipairs(profile.EquippedCompanions or {}) do
		local owned = findOwnedByUid(profile, uid)
		local definition = owned and definitionsById[owned.Id]
		if definition then
			table.insert(equipped, {
				Name = definition.Name,
				Rarity = definition.Rarity,
				Multiplier = definition.Multiplier,
			})
		end
	end

	return {
		OwnedCount = #(profile.Companions or {}),
		EquippedCount = #(profile.EquippedCompanions or {}),
		MaxEquipped = GameConfig.Companions.MaxEquipped,
		Multiplier = self:GetMultiplierFromProfile(profile),
		EggCost = GameConfig.Companions.StarterEgg.Cost,
		Equipped = equipped,
	}
end

function CompanionService:HatchStarterEgg(player)
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	local cost = GameConfig.Companions.StarterEgg.Cost
	if not EconomyService:SpendEnergy(player, cost) then
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

	if #profile.EquippedCompanions < GameConfig.Companions.MaxEquipped then
		table.insert(profile.EquippedCompanions, companion.Uid)
	end

	QuestService:Update(player, "hatch_1", 1)
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
