local ReplicatedStorage = game:GetService("ReplicatedStorage")

local servicesFolder = script.Parent:WaitForChild("Services")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Services = {
	GameConfig = GameConfig,
	DataService = require(servicesFolder.DataService),
	NetworkService = require(servicesFolder.NetworkService),
	EconomyService = require(servicesFolder.EconomyService),
	QuestService = require(servicesFolder.QuestService),
	CompanionService = require(servicesFolder.CompanionService),
	UpgradeService = require(servicesFolder.UpgradeService),
	RebirthService = require(servicesFolder.RebirthService),
	WorldService = require(servicesFolder.WorldService),
}

local initOrder = {
	"DataService",
	"NetworkService",
	"EconomyService",
	"QuestService",
	"CompanionService",
	"UpgradeService",
	"RebirthService",
	"WorldService",
}

for _, serviceName in ipairs(initOrder) do
	local service = Services[serviceName]
	if service.Init then
		service:Init(Services)
	end
end

for _, serviceName in ipairs({ "NetworkService", "DataService", "WorldService" }) do
	local service = Services[serviceName]
	if service.Start then
		service:Start()
	end
end

print("[Power Islands] Phase 2 server started")
