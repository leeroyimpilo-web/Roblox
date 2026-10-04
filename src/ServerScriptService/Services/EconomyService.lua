local EconomyService = {}

local DataService
local NetworkService

function EconomyService:Init(services)
	DataService = services.DataService
	NetworkService = services.NetworkService
end

function EconomyService:GetEnergy(player)
	local profile = DataService:GetProfile(player)
	return profile and profile.Energy or 0
end

function EconomyService:AddEnergy(player, amount)
	if type(amount) ~= "number" or amount <= 0 then
		return false
	end

	amount = math.floor(math.min(amount, 1_000_000_000))
	local profile = DataService:GetProfile(player)
	if not profile then
		return false
	end

	profile.Energy += amount
	profile.Stats.LifetimeEnergy += amount
	NetworkService:PushState(player)
	return true, profile.Energy
end

function EconomyService:SpendEnergy(player, amount)
	if type(amount) ~= "number" or amount <= 0 then
		return false
	end

	amount = math.floor(amount)
	local profile = DataService:GetProfile(player)
	if not profile or profile.Energy < amount then
		return false
	end

	profile.Energy -= amount
	NetworkService:PushState(player)
	return true, profile.Energy
end

return EconomyService
