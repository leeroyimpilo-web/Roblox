local TutorialService = {}

local Services

local STEPS = {
	[0] = {
		Action = "ClaimCore",
		Title = "CLAIM YOUR CORE",
		Text = "Walk to your glowing Power Core and use Claim Charge.",
	},
	[1] = {
		Action = "UpgradeCore",
		Title = "EVOLVE YOUR CORE",
		Text = "Use the orange EVOLVE CORE pad. Your tutorial bonus covers the first upgrade.",
	},
	[2] = {
		Action = "StealCore",
		Title = "STEAL A CORE",
		Text = "Cross a bridge to another island and hold STEAL FRAGMENT on their Core.",
	},
	[3] = {
		Action = "BankCore",
		Title = "ESCAPE AND BANK",
		Text = "Carry the stolen fragment back to your green BANK pad before the owner catches you.",
	},
}

function TutorialService:Init(services)
	Services = services
end

function TutorialService:GetClientState(profile)
	if not profile or profile.TutorialComplete then
		return {
			Complete = true,
			Step = 4,
			Title = "CORE RAIDER",
			Text = "Tutorial complete.",
		}
	end

	local step = math.clamp(math.floor(profile.TutorialStep or 0), 0, 3)
	local definition = STEPS[step]
	return {
		Complete = false,
		Step = step,
		Title = definition.Title,
		Text = definition.Text,
	}
end

function TutorialService:Mark(player, action)
	local profile = Services.DataService:GetProfile(player)
	if not profile or profile.TutorialComplete then
		return false
	end

	local step = math.clamp(math.floor(profile.TutorialStep or 0), 0, 3)
	local definition = STEPS[step]
	if not definition or definition.Action ~= action then
		return false
	end

	Services.AnalyticsService:Onboarding(player, step + 1, action)

	if step == 0 then
		Services.EconomyService:AddEnergy(player, 500, "TutorialCoreBonus")
		Services.NetworkService:Toast(player, "Tutorial bonus: +500 Energy. Now evolve your Core!", "Success")
	end

	if step >= 3 then
		profile.TutorialStep = 4
		profile.TutorialComplete = true
		Services.EconomyService:AddEnergy(player, 1_000, "TutorialComplete")
		profile.PowerCrystals += 1
		Services.AnalyticsService:Custom(player, "TutorialCompleted", 1)
		Services.NetworkService:BannerAll(
			"NEW CORE RAIDER!",
			player.DisplayName .. " completed their first heist!",
			4
		)
		Services.NetworkService:Toast(player, "Tutorial complete: +1,000 Energy +1 Power Crystal!", "Rare")
	else
		profile.TutorialStep = step + 1
	end

	Services.NetworkService:PushState(player)
	return true
end

return TutorialService
