local RobloxAnalytics = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

local Analytics = {}

local function enabled()
	return not RunService:IsStudio()
end

function Analytics:Init()
end

function Analytics:Custom(player, eventName, value)
	if not enabled() or not player then
		return
	end

	pcall(function()
		RobloxAnalytics:LogCustomEvent(player, eventName, tonumber(value) or 1, {})
	end)
end

function Analytics:Economy(player, flow, currency, amount, endingBalance, reason)
	if not enabled() or not player then
		return
	end

	local flowType = flow == "Sink" and Enum.AnalyticsEconomyFlowType.Sink or Enum.AnalyticsEconomyFlowType.Source
	pcall(function()
		RobloxAnalytics:LogEconomyEvent(
			player,
			flowType,
			tostring(currency),
			math.abs(tonumber(amount) or 0),
			tonumber(endingBalance) or 0,
			tostring(reason or "Unknown"),
			tostring(reason or "Unknown"),
			{}
		)
	end)
end

function Analytics:Onboarding(player, step, name)
	if not enabled() or not player then
		return
	end
	pcall(function()
		RobloxAnalytics:LogOnboardingFunnelStepEvent(player, step, name, {})
	end)
end

return Analytics
