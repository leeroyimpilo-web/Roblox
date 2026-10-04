local QuestService = {}

local DataService
local EconomyService
local NetworkService
local AnalyticsService
local GameConfig
local questDefinitions = {}

local function getRecord(profile, questId)
	profile.Quests = profile.Quests or {}
	if not profile.Quests[questId] then
		profile.Quests[questId] = {
			Progress = 0,
			Completed = false,
			Claimed = false,
		}
	end
	return profile.Quests[questId]
end

function QuestService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	NetworkService = services.NetworkService
	AnalyticsService = services.AnalyticsService
	GameConfig = services.GameConfig

	for _, quest in ipairs(GameConfig.Quests) do
		questDefinitions[quest.Id] = quest
	end
end

function QuestService:Update(player, questId, amount)
	local definition = questDefinitions[questId]
	local profile = DataService:GetProfile(player)
	if not definition or not profile then
		return false
	end

	local record = getRecord(profile, questId)
	if record.Completed then
		return false
	end

	record.Progress = math.min(definition.Target, record.Progress + math.max(0, math.floor(amount or 1)))

	if record.Progress >= definition.Target then
		record.Completed = true
		record.Claimed = true
		if definition.RewardEnergy and definition.RewardEnergy > 0 then
			EconomyService:AddEnergy(player, definition.RewardEnergy, "QuestReward")
		end
		AnalyticsService:Custom(player, "QuestCompleted", 1, questId)
		NetworkService:Toast(player, "Quest complete: " .. definition.Title .. "!", "Success")
	else
		NetworkService:PushState(player)
	end

	return true
end

function QuestService:GetClientState(profile)
	local result = {}
	for _, definition in ipairs(GameConfig.Quests) do
		local record = getRecord(profile, definition.Id)
		table.insert(result, {
			Id = definition.Id,
			Title = definition.Title,
			Description = definition.Description,
			Progress = record.Progress,
			Target = definition.Target,
			Completed = record.Completed,
			RewardEnergy = definition.RewardEnergy,
		})
	end
	return result
end

return QuestService
