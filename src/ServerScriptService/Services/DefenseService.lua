local Players = game:GetService("Players")

local DefenseService = {}

local Services
local defenses = {}
local trapCooldownUntil = {}

local function addBillboard(part, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(250, 70)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 108, 108)
	label.Parent = gui
	return label
end

local function playerFromPart(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character) or nil
end

function DefenseService:Init(services)
	Services = services
end

function DefenseService:GetClientState(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return nil
	end

	local level = profile.TrapLevel or 0
	return {
		TrapLevel = level,
		MaxTrapLevel = Services.GameConfig.Raid.Trap.MaxLevel,
		TrapUpgradeCost = level < Services.GameConfig.Raid.Trap.MaxLevel
			and Services.GameConfig.GetTrapUpgradeCost(level)
			or 0,
		SlowSeconds = level > 0 and Services.GameConfig.GetTrapSlowSeconds(level) or 0,
	}
end

function DefenseService:_update(player)
	local data = defenses[player]
	local profile = Services.DataService:GetProfile(player)
	if not data or not profile then
		return
	end

	local level = profile.TrapLevel or 0
	data.Zone.Transparency = level > 0 and 0.72 or 0.92
	data.Zone.Color = level > 0 and Color3.fromRGB(255, 73, 73) or Color3.fromRGB(90, 90, 100)
	data.Label.Text = level > 0
		and string.format("PULSE TRAP • LEVEL %s\nSlows intruders %.1fs", level, Services.GameConfig.GetTrapSlowSeconds(level))
		or "PULSE TRAP • OFFLINE\nUpgrade to activate"
end

function DefenseService:Upgrade(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	local level = profile.TrapLevel or 0
	if level >= Services.GameConfig.Raid.Trap.MaxLevel then
		Services.NetworkService:Toast(player, "Pulse Trap is already max level.", "Rare")
		return false
	end

	local cost = Services.GameConfig.GetTrapUpgradeCost(level)
	if not Services.EconomyService:SpendEnergy(player, cost, "TrapUpgrade") then
		Services.NetworkService:Toast(player, "You need " .. cost .. " Energy to upgrade the trap.", "Warning")
		return false
	end

	profile.TrapLevel = level + 1
	self:_update(player)
	Services.AnalyticsService:Custom(player, "TrapUpgraded", profile.TrapLevel)
	Services.NetworkService:PushState(player)
	Services.NetworkService:Toast(player, "Pulse Trap upgraded to Level " .. profile.TrapLevel .. "!", "Success")
	return true
end

function DefenseService:_trigger(owner, intruder)
	local profile = Services.DataService:GetProfile(owner)
	local humanoid = intruder.Character and intruder.Character:FindFirstChildOfClass("Humanoid")
	if not profile or not humanoid or (profile.TrapLevel or 0) <= 0 then
		return
	end

	local now = os.clock()
	if now < (trapCooldownUntil[owner.UserId] or 0) then
		return
	end
	trapCooldownUntil[owner.UserId] = now + Services.GameConfig.Raid.Trap.CooldownSeconds

	profile.Stats.TrapTriggers += 1
	local seconds = Services.GameConfig.GetTrapSlowSeconds(profile.TrapLevel)
	local original = humanoid.WalkSpeed
	humanoid.WalkSpeed = math.min(original, Services.GameConfig.Raid.Trap.SlowWalkSpeed)

	Services.NetworkService:Toast(intruder, owner.DisplayName .. "'s Pulse Trap slowed you!", "Warning")
	Services.NetworkService:Toast(owner, "Pulse Trap triggered on " .. intruder.DisplayName .. "!", "Success")

	task.delay(seconds, function()
		if humanoid.Parent and humanoid.Health > 0 then
			local intruderProfile = Services.DataService:GetProfile(intruder)
			local carrying = Services.RaidService:IsCarrying(intruder)
			if carrying then
				humanoid.WalkSpeed = 20
			elseif intruderProfile and intruderProfile.Entitlements and intruderProfile.Entitlements.Hoverboard then
				humanoid.WalkSpeed = 24
			else
				humanoid.WalkSpeed = 16
			end
		end
	end)
end

function DefenseService:_attach(player)
	for _ = 1, 50 do
		if Services.BaseService:GetAssignment(player) then
			break
		end
		task.wait(0.2)
	end

	local assignment = Services.BaseService:GetAssignment(player)
	if not assignment or defenses[player] then
		return
	end

	local center = assignment.Core.Position - Vector3.new(0, 8, 0)

	local zone = Instance.new("Part")
	zone.Name = "PulseTrapZone"
	zone.Size = Vector3.new(32, 1, 32)
	zone.Position = center + Vector3.new(0, 2.7, 0)
	zone.Anchored = true
	zone.CanCollide = false
	zone.CanTouch = true
	zone.Material = Enum.Material.Neon
	zone.Color = Color3.fromRGB(255, 73, 73)
	zone.Transparency = 0.85
	zone.Parent = assignment.Model

	local upgradePad = Instance.new("Part")
	upgradePad.Name = "TrapUpgradePad"
	upgradePad.Size = Vector3.new(12, 1, 12)
	upgradePad.Position = center + Vector3.new(-20, 3, -12)
	upgradePad.Anchored = true
	upgradePad.Material = Enum.Material.Neon
	upgradePad.Color = Color3.fromRGB(255, 73, 73)
	upgradePad.Parent = assignment.Model

	local label = addBillboard(upgradePad, "PULSE TRAP")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Upgrade Trap"
	prompt.ObjectText = "Island Defense"
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = upgradePad
	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player then
			self:Upgrade(player)
		end
	end)

	zone.Touched:Connect(function(hit)
		local intruder = playerFromPart(hit)
		if intruder and intruder ~= player then
			self:_trigger(player, intruder)
		end
	end)

	defenses[player] = {
		Zone = zone,
		UpgradePad = upgradePad,
		Label = label,
	}
	self:_update(player)
end

function DefenseService:Start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:_attach(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		defenses[player] = nil
		trapCooldownUntil[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_attach(player)
		end)
	end
end

return DefenseService
