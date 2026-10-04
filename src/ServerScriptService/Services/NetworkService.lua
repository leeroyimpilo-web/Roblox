local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}

local DataService
local GameConfig
local CompanionService
local QuestService
local RebirthService
local stateChanged
local toastEvent

local function buildState(profile)
	if not profile then
		return nil
	end

	return {
		Energy = profile.Energy,
		PowerCrystals = profile.PowerCrystals,
		Power = profile.Power,
		Rebirths = profile.Rebirths,
		NextPowerCost = GameConfig.GetPowerUpgradeCost(profile.Power),
		LifetimeEnergy = profile.Stats and profile.Stats.LifetimeEnergy or 0,
		JungleUnlocked = profile.UnlockedWorlds and profile.UnlockedWorlds.Jungle == true,
		Companions = CompanionService and CompanionService:GetClientState(profile) or nil,
		Quests = QuestService and QuestService:GetClientState(profile) or {},
		Rebirth = RebirthService and RebirthService:GetClientState(profile) or nil,
	}
end

function NetworkService:Init(services)
	DataService = services.DataService
	GameConfig = services.GameConfig
	CompanionService = services.CompanionService
	QuestService = services.QuestService
	RebirthService = services.RebirthService
end

function NetworkService:Start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage

	local getState = remotes:FindFirstChild("GetPlayerState") or Instance.new("RemoteFunction")
	getState.Name = "GetPlayerState"
	getState.Parent = remotes

	stateChanged = remotes:FindFirstChild("StateChanged") or Instance.new("RemoteEvent")
	stateChanged.Name = "StateChanged"
	stateChanged.Parent = remotes

	toastEvent = remotes:FindFirstChild("Toast") or Instance.new("RemoteEvent")
	toastEvent.Name = "Toast"
	toastEvent.Parent = remotes

	getState.OnServerInvoke = function(player)
		return buildState(DataService:GetProfile(player))
	end
end

function NetworkService:PushState(player)
	if stateChanged then
		stateChanged:FireClient(player, buildState(DataService:GetProfile(player)))
	end
end

function NetworkService:Toast(player, message, tone)
	if toastEvent and type(message) == "string" then
		toastEvent:FireClient(player, message, tone or "Info")
	end
end

return NetworkService
