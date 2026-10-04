local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}

local DataService
local GameConfig
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
	}
end

function NetworkService:Init(services)
	DataService = services.DataService
	GameConfig = services.GameConfig
end

function NetworkService:Start()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage

	local getState = Instance.new("RemoteFunction")
	getState.Name = "GetPlayerState"
	getState.Parent = remotes

	stateChanged = Instance.new("RemoteEvent")
	stateChanged.Name = "StateChanged"
	stateChanged.Parent = remotes

	toastEvent = Instance.new("RemoteEvent")
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
