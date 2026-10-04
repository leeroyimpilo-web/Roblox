local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NetworkService = {}

local Services
local stateChanged
local toastEvent
local actionEvent
local eventBanner

local function getWorldState(profile)
	local unlockedCount = 0
	local nextWorld

	for _, world in ipairs(Services.GameConfig.Worlds) do
		if profile.UnlockedWorlds[world.Id] then
			unlockedCount += 1
		elseif not nextWorld then
			nextWorld = world
		end
	end

	return {
		UnlockedCount = unlockedCount,
		Total = #Services.GameConfig.Worlds,
		NextId = nextWorld and nextWorld.Id or nil,
		NextName = nextWorld and nextWorld.Name or "All worlds unlocked",
		NextCost = nextWorld and nextWorld.UnlockCost or 0,
	}
end

local function getServerPlayers(player)
	local result = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			table.insert(result, {
				UserId = other.UserId,
				Name = other.Name,
				DisplayName = other.DisplayName,
			})
		end
	end
	table.sort(result, function(a, b)
		return a.Name < b.Name
	end)
	return result
end

local function buildState(profile, player)
	if not profile then
		return nil
	end

	return {
		Energy = profile.Energy,
		PowerCrystals = profile.PowerCrystals,
		Power = profile.Power,
		Rebirths = profile.Rebirths,
		NextPowerCost = Services.GameConfig.GetPowerUpgradeCost(profile.Power),
		LifetimeEnergy = profile.Stats and profile.Stats.LifetimeEnergy or 0,
		JungleUnlocked = profile.UnlockedWorlds and profile.UnlockedWorlds.Jungle == true,
		Worlds = getWorldState(profile),
		Companions = Services.CompanionService:GetClientState(profile, player),
		Quests = Services.QuestService:GetClientState(profile),
		Rebirth = Services.RebirthService:GetClientState(profile),
		Daily = Services.DailyRewardService:GetClientState(profile),
		Achievements = Services.AchievementService:GetClientState(profile),
		Social = Services.SocialService:GetClientState(player),
		Party = Services.PartyService:GetClientState(player),
		Trade = Services.TradeService:GetClientState(player),
		ServerPlayers = getServerPlayers(player),
		Event = Services.LiveEventService:GetClientState(),
		Monetization = Services.MonetizationService:GetClientState(profile),
		Boss = Services.BossService:GetClientState(),
	}
end

function NetworkService:Init(services)
	Services = services
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

	actionEvent = remotes:FindFirstChild("Action") or Instance.new("RemoteEvent")
	actionEvent.Name = "Action"
	actionEvent.Parent = remotes

	eventBanner = remotes:FindFirstChild("EventBanner") or Instance.new("RemoteEvent")
	eventBanner.Name = "EventBanner"
	eventBanner.Parent = remotes

	getState.OnServerInvoke = function(player)
		return buildState(Services.DataService:GetProfile(player), player)
	end

	actionEvent.OnServerEvent:Connect(function(player, action, payload)
		if type(action) ~= "string" or not Services.SecurityService:Allow(player, "Action:" .. action, 0.25) then
			return
		end

		if action == "ClaimDaily" then
			Services.DailyRewardService:Claim(player)
		elseif action == "RedeemCode" then
			Services.CodeService:Redeem(player, payload)
		elseif action == "ToggleCompanion" then
			Services.CompanionService:ToggleEquip(player, payload)
		elseif action == "PromptPass" then
			Services.MonetizationService:PromptPass(player, payload)
		elseif action == "PromptProduct" then
			Services.MonetizationService:PromptProduct(player, payload)
		elseif action == "PromptSubscription" then
			Services.MonetizationService:PromptSubscription(player)
		elseif action == "AttackBoss" then
			Services.BossService:Attack(player)
		elseif action == "PartyInvite" then
			Services.PartyService:Invite(player, payload)
		elseif action == "PartyAccept" then
			Services.PartyService:Accept(player)
		elseif action == "PartyLeave" then
			Services.PartyService:Leave(player)
		elseif action == "GiftEnergy" and type(payload) == "table" then
			Services.PartyService:GiftEnergy(player, payload.UserId, payload.Amount)
		elseif action == "TradeRequest" then
			Services.TradeService:Request(player, payload)
		elseif action == "TradeAccept" then
			Services.TradeService:Accept(player)
		elseif action == "TradeOffer" then
			Services.TradeService:Offer(player, payload)
		elseif action == "TradeConfirm" then
			Services.TradeService:Confirm(player)
		elseif action == "TradeCancel" then
			Services.TradeService:Cancel(player)
		end
	end)
end

function NetworkService:PushState(player)
	if stateChanged and player and player.Parent == Players then
		stateChanged:FireClient(player, buildState(Services.DataService:GetProfile(player), player))
	end
end

function NetworkService:PushAll()
	for _, player in ipairs(Players:GetPlayers()) do
		self:PushState(player)
	end
end

function NetworkService:Toast(player, message, tone)
	if toastEvent and player and player.Parent == Players and type(message) == "string" then
		toastEvent:FireClient(player, message, tone or "Info")
	end
end

function NetworkService:ToastAll(message, tone)
	for _, player in ipairs(Players:GetPlayers()) do
		self:Toast(player, message, tone)
	end
end

function NetworkService:BannerAll(title, subtitle, duration)
	if eventBanner then
		eventBanner:FireAllClients(title, subtitle or "", duration or 4)
	end
end

return NetworkService
