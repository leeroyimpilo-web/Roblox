local ReplicatedStorage = game:GetService("ReplicatedStorage")

local servicesFolder = script.Parent:WaitForChild("Services")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Services = {
	GameConfig = GameConfig,
	DataService = require(servicesFolder.DataService),
	NetworkService = require(servicesFolder.NetworkService),
	EconomyService = require(servicesFolder.EconomyService),
	UpgradeService = require(servicesFolder.UpgradeService),
	WorldService = require(servicesFolder.WorldService),
}

for _, serviceName in ipairs({ "DataService", "NetworkService", "EconomyService", "UpgradeService", "WorldService" }) do
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

print("[Power Islands] Phase 1 server started")
