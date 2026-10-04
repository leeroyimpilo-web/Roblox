local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local MonetizationService = {}

local Services
local receiptStore
local productNameById = {}

local function configured(id)
	return type(id) == "number" and id > 0
end

local function subscriptionConfigured()
	return type(Services.GameConfig.Monetization.SubscriptionId) == "string"
		and Services.GameConfig.Monetization.SubscriptionId ~= ""
end

local function waitForProfile(player)
	for _ = 1, 40 do
		if Services.DataService:GetProfile(player) then
			return Services.DataService:GetProfile(player)
		end
		task.wait(0.25)
	end
	return nil
end

function MonetizationService:Init(services)
	Services = services
	receiptStore = DataStoreService:GetDataStore("PowerIslands_ReceiptHistory_v1")

	for name, id in pairs(Services.GameConfig.Monetization.Products) do
		if configured(id) then
			productNameById[id] = name
		end
	end
end

function MonetizationService:GetEnergyMultiplier(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return 1
	end

	local multiplier = 1
	if profile.Entitlements.DoubleEnergy then
		multiplier *= 2
	end
	if profile.Entitlements.VIP then
		multiplier *= 1.2
	end
	if profile.Entitlements.SubscriptionVIP then
		multiplier *= 1.1
	end
	return multiplier
end

function MonetizationService:GetClientState(profile)
	local passes = {}
	for name, id in pairs(Services.GameConfig.Monetization.Passes) do
		passes[name] = {
			Configured = configured(id),
			Owned = profile.Entitlements[name] == true,
		}
	end

	local products = {}
	for name, id in pairs(Services.GameConfig.Monetization.Products) do
		products[name] = { Configured = configured(id) }
	end

	return {
		Passes = passes,
		Products = products,
		SubscriptionConfigured = subscriptionConfigured(),
		SubscriptionOwned = profile.Entitlements.SubscriptionVIP == true,
	}
end

function MonetizationService:RefreshSubscription(player)
	local profile = waitForProfile(player)
	if not profile then
		return
	end

	if not subscriptionConfigured() then
		profile.Entitlements.SubscriptionVIP = false
		return
	end

	local ok, response = pcall(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(
			player,
			Services.GameConfig.Monetization.SubscriptionId
		)
	end)

	if ok and type(response) == "table" then
		profile.Entitlements.SubscriptionVIP = response.IsSubscribed == true
		Services.NetworkService:PushState(player)
	end
end

function MonetizationService:RefreshPasses(player)
	local profile = waitForProfile(player)
	if not profile then
		return
	end

	for name, id in pairs(Services.GameConfig.Monetization.Passes) do
		if configured(id) then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok then
				profile.Entitlements[name] = owns == true
			end
		end
	end

	self:RefreshSubscription(player)
	Services.NetworkService:PushState(player)
end

function MonetizationService:PromptPass(player, passName)
	if type(passName) ~= "string" then
		return false
	end
	local id = Services.GameConfig.Monetization.Passes[passName]
	if not configured(id) then
		Services.NetworkService:Toast(player, "This pass still needs its Creator Hub ID configured.", "Warning")
		return false
	end

	MarketplaceService:PromptGamePassPurchase(player, id)
	return true
end

function MonetizationService:PromptProduct(player, productName)
	if type(productName) ~= "string" then
		return false
	end
	local id = Services.GameConfig.Monetization.Products[productName]
	if not configured(id) then
		Services.NetworkService:Toast(player, "This product still needs its Creator Hub ID configured.", "Warning")
		return false
	end

	MarketplaceService:PromptProductPurchase(player, id)
	return true
end

function MonetizationService:PromptSubscription(player)
	if not subscriptionConfigured() then
		Services.NetworkService:Toast(player, "The VIP subscription ID still needs to be configured.", "Warning")
		return false
	end
	MarketplaceService:PromptSubscriptionPurchase(player, Services.GameConfig.Monetization.SubscriptionId)
	return true
end

function MonetizationService:_grantProduct(player, productName)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	if productName == "Energy5K" then
		return Services.EconomyService:AddEnergy(player, 5_000, "DeveloperProduct")
	elseif productName == "Energy50K" then
		return Services.EconomyService:AddEnergy(player, 50_000, "DeveloperProduct")
	elseif productName == "ServerBoost" then
		Services.LiveEventService:Activate("PowerSurge", 600)
		return true
	elseif productName == "InstantRebirth" then
		return Services.RebirthService:Rebirth(player, true)
	end

	return false
end

function MonetizationService:_processReceipt(receiptInfo)
	local purchaseId = tostring(receiptInfo.PurchaseId)
	local productName = productNameById[receiptInfo.ProductId]
	if not productName then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local alreadyGranted = false
	local checkOk = pcall(function()
		alreadyGranted = receiptStore:GetAsync(purchaseId) == true
	end)
	if checkOk and alreadyGranted then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player or not Services.DataService:GetProfile(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = self:_grantProduct(player, productName)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = Services.DataService:GetProfile(player)
	profile.Stats.Purchases += 1

	if not Services.DataService:Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local markOk = pcall(function()
		receiptStore:SetAsync(purchaseId, true)
	end)
	if not markOk then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Services.AnalyticsService:Custom(player, "DeveloperProductPurchased", 1)
	Services.NetworkService:PushState(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:Start()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:_processReceipt(receiptInfo)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end

		local profile = Services.DataService:GetProfile(player)
		if not profile then
			return
		end

		for name, id in pairs(Services.GameConfig.Monetization.Passes) do
			if id == gamePassId then
				profile.Entitlements[name] = true
				profile.Stats.Purchases += 1
				Services.AnalyticsService:Custom(player, "GamePassPurchased", 1)
				Services.NetworkService:PushState(player)
				Services.NetworkService:Toast(player, name .. " unlocked!", "Rare")
				break
			end
		end
	end)

	Players.UserSubscriptionStatusChanged:Connect(function(player, subscriptionId)
		if subscriptionId == Services.GameConfig.Monetization.SubscriptionId then
			task.spawn(function()
				self:RefreshSubscription(player)
			end)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:RefreshPasses(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:RefreshPasses(player)
		end)
	end
end

return MonetizationService
