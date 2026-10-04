local Players = game:GetService("Players")

local MegaCoreService = {}

local Services
local core
local label
local prompt
local active = false
local endsAt = 0
local remainingDrains = 0
local contributions = {}
local lastDrain = {}
local eventToken = 0

local function formatNumber(value)
	value = tonumber(value) or 0
	if value >= 1e6 then
		return string.format("%.1fM", value / 1e6)
	elseif value >= 1e3 then
		return string.format("%.1fK", value / 1e3)
	end
	return tostring(math.floor(value))
end

function MegaCoreService:Init(services)
	Services = services
end

function MegaCoreService:GetClientState()
	return {
		Active = active,
		EndsAt = endsAt,
		RemainingDrains = remainingDrains,
		MaxDrains = Services.GameConfig.Raid.MegaCore.MaxDrains,
	}
end

function MegaCoreService:_updateVisual()
	if not core or not label or not prompt then
		return
	end

	if active then
		core.Material = Enum.Material.Neon
		core.Color = Color3.fromRGB(255, 73, 203)
		core.Transparency = 0
		prompt.Enabled = true
		label.Text = string.format(
			"MEGA CORE\n%s DRAINS LEFT\nBANK ENERGY + WEEKLY POINTS",
			remainingDrains
		)
	else
		core.Material = Enum.Material.Slate
		core.Color = Color3.fromRGB(70, 70, 84)
		core.Transparency = 0.35
		prompt.Enabled = false
		label.Text = "MEGA CORE\nDORMANT"
	end
end

function MegaCoreService:_finish()
	if not active then
		return
	end

	active = false
	endsAt = 0
	eventToken += 1
	self:_updateVisual()

	local topPlayer
	local topCount = 0
	for userId, count in pairs(contributions) do
		if count > topCount then
			topCount = count
			topPlayer = Players:GetPlayerByUserId(userId)
		end
	end

	if topPlayer and topPlayer.Parent == Players then
		local bonus = 5_000 + (topCount * 500)
		Services.EconomyService:AddEnergy(topPlayer, bonus, "MegaCoreChampion")
		Services.NetworkService:BannerAll(
			"MEGA CORE CHAMPION",
			topPlayer.DisplayName .. " drained it " .. topCount .. " times and won +" .. formatNumber(bonus) .. " Energy!",
			6
		)
	else
		Services.NetworkService:ToastAll("The Mega Core event ended.", "Info")
	end

	contributions = {}
	lastDrain = {}
	Services.NetworkService:PushAll()
end

function MegaCoreService:Drain(player)
	if not active or remainingDrains <= 0 then
		return false
	end

	local now = os.clock()
	if now - (lastDrain[player.UserId] or -math.huge) < Services.GameConfig.Raid.MegaCore.DrainCooldownSeconds then
		Services.NetworkService:Toast(player, "Mega Core is recharging. Keep moving!", "Warning")
		return false
	end
	lastDrain[player.UserId] = now

	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	remainingDrains -= 1
	contributions[player.UserId] = (contributions[player.UserId] or 0) + 1
	profile.Stats.MegaCoreDrains += 1

	local reward = math.floor(
		Services.GameConfig.Raid.MegaCore.BaseRewardEnergy
			* (1 + math.min((profile.CoreLevel or 1) / 50, 1))
	)
	Services.EconomyService:AddEnergy(player, reward, "MegaCoreDrain")
	Services.LeaderboardService:AddWeeklyScore(player, Services.GameConfig.Raid.MegaCore.WeeklyPointsPerDrain)
	Services.AnalyticsService:Custom(player, "MegaCoreDrain", reward)
	Services.NetworkService:Toast(player, "+" .. formatNumber(reward) .. " Energy from the Mega Core!", "Rare")
	self:_updateVisual()
	Services.NetworkService:PushAll()

	if remainingDrains <= 0 then
		self:_finish()
	end
	return true
end

function MegaCoreService:Activate(duration)
	if active then
		return false
	end

	duration = math.max(30, math.floor(tonumber(duration) or Services.GameConfig.Raid.MegaCore.DurationSeconds))
	active = true
	endsAt = os.time() + duration
	remainingDrains = Services.GameConfig.Raid.MegaCore.MaxDrains
	contributions = {}
	lastDrain = {}
	eventToken += 1
	local token = eventToken

	self:_updateVisual()
	Services.NetworkService:BannerAll(
		"MEGA CORE ACTIVE!",
		"Race to the center hub • drain it for Energy and weekly championship points!",
		6
	)
	Services.NetworkService:PushAll()

	task.delay(duration, function()
		if active and eventToken == token then
			self:_finish()
		end
	end)
	return true
end

function MegaCoreService:_create()
	local arena = workspace:WaitForChild("CoreRaidArena", 15)
	if not arena then
		warn("[MegaCoreService] Core raid arena missing")
		return
	end

	core = Instance.new("Part")
	core.Name = "MegaCore"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(18, 18, 18)
	core.Position = Services.GameConfig.Raid.ArenaCenter + Vector3.new(0, 13, 0)
	core.Anchored = true
	core.CanCollide = true
	core.Parent = arena

	local light = Instance.new("PointLight")
	light.Range = 38
	light.Brightness = 4
	light.Color = Color3.fromRGB(255, 73, 203)
	light.Parent = core

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(380, 110)
	gui.StudsOffset = Vector3.new(0, 13, 0)
	gui.AlwaysOnTop = true
	gui.Parent = core

	label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(32, 21, 48)
	label.BackgroundTransparency = 0.12
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 165, 226)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = label

	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "DRAIN MEGA CORE"
	prompt.ObjectText = "Championship Core"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = core
	prompt.Triggered:Connect(function(player)
		self:Drain(player)
	end)

	self:_updateVisual()
end

function MegaCoreService:Start()
	self:_create()

	task.spawn(function()
		local cfg = Services.GameConfig.Raid.MegaCore
		while true do
			task.wait(math.max(30, cfg.IntervalSeconds - cfg.WarningSeconds))
			if not active then
				Services.NetworkService:BannerAll(
					"MEGA CORE IN " .. cfg.WarningSeconds .. "s",
					"Get to the center hub. Weekly championship points are at stake!",
					5
				)
			end
			task.wait(cfg.WarningSeconds)
			if not active then
				self:Activate(cfg.DurationSeconds)
			end
		end
	end)
end

return MegaCoreService
