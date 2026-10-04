local ReplicatedStorage = game:GetService("ReplicatedStorage")

local servicesFolder = script.Parent:WaitForChild("Services")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Services = {
	GameConfig = GameConfig,
	DataService = require(servicesFolder.DataService),
	SecurityService = require(servicesFolder.SecurityService),
	AnalyticsService = require(servicesFolder.AnalyticsService),
	NetworkService = require(servicesFolder.NetworkService),
	EconomyService = require(servicesFolder.EconomyService),
	AchievementService = require(servicesFolder.AchievementService),
	QuestService = require(servicesFolder.QuestService),
	SocialService = require(servicesFolder.SocialService),
	PartyService = require(servicesFolder.PartyService),
	TradeService = require(servicesFolder.TradeService),
	RaidService = require(servicesFolder.RaidService),
	BaseService = require(servicesFolder.BaseService),
	LiveEventService = require(servicesFolder.LiveEventService),
	MonetizationService = require(servicesFolder.MonetizationService),
	CompanionService = require(servicesFolder.CompanionService),
	UpgradeService = require(servicesFolder.UpgradeService),
	DailyRewardService = require(servicesFolder.DailyRewardService),
	CodeService = require(servicesFolder.CodeService),
	RebirthService = require(servicesFolder.RebirthService),
	WorldService = require(servicesFolder.WorldService),
	BossService = require(servicesFolder.BossService),
	AdminService = require(servicesFolder.AdminService),
}

local initOrder = {
	"DataService",
	"SecurityService",
	"AnalyticsService",
	"NetworkService",
	"EconomyService",
	"AchievementService",
	"QuestService",
	"SocialService",
	"PartyService",
	"TradeService",
	"RaidService",
	"BaseService",
	"LiveEventService",
	"MonetizationService",
	"CompanionService",
	"UpgradeService",
	"DailyRewardService",
	"CodeService",
	"RebirthService",
	"WorldService",
	"BossService",
	"AdminService",
}

for _, serviceName in ipairs(initOrder) do
	local service = Services[serviceName]
	if service.Init then
		service:Init(Services)
	end
end

local startOrder = {
	"NetworkService",
	"DataService",
	"SocialService",
	"PartyService",
	"TradeService",
	"MonetizationService",
	"WorldService",
	"RaidService",
	"BaseService",
	"BossService",
	"LiveEventService",
	"AdminService",
}

for _, serviceName in ipairs(startOrder) do
	local service = Services[serviceName]
	if service.Start then
		service:Start()
	end
end

print("[Power Islands] Full systems build started")
