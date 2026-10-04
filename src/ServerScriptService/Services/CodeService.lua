local CodeService = {}

local DataService
local EconomyService
local NetworkService
local AnalyticsService
local SecurityService
local GameConfig

function CodeService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	NetworkService = services.NetworkService
	AnalyticsService = services.AnalyticsService
	SecurityService = services.SecurityService
	GameConfig = services.GameConfig
end

function CodeService:Redeem(player, rawCode)
	local safe = SecurityService:ShortString(rawCode, 24)
	if not safe then
		return false
	end

	local code = string.upper(string.gsub(safe, "%s+", ""))
	local reward = GameConfig.Codes[code]
	local profile = DataService:GetProfile(player)
	if not reward or not profile then
		NetworkService:Toast(player, "That code is invalid.", "Warning")
		return false
	end

	profile.CodesRedeemed = profile.CodesRedeemed or {}
	if profile.CodesRedeemed[code] then
		NetworkService:Toast(player, "You already redeemed that code.", "Warning")
		return false
	end

	profile.CodesRedeemed[code] = true
	profile.Stats.CodesRedeemed += 1

	if (reward.Energy or 0) > 0 then
		EconomyService:AddEnergy(player, reward.Energy, "PromoCode")
	end
	if (reward.Crystals or 0) > 0 then
		profile.PowerCrystals += reward.Crystals
	end

	AnalyticsService:Custom(player, "PromoCodeRedeemed", 1, code)
	NetworkService:PushState(player)
	NetworkService:Toast(player, "Code redeemed: " .. code, "Success")
	return true
end

return CodeService
