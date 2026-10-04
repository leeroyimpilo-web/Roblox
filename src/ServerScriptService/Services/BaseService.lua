local Players = game:GetService("Players")

local BaseService = {}

local Services
local arenaFolder
local hub
local slotOwners = {}
local assignments = {}
local coreLabels = {}

local function formatNumber(value)
	value = tonumber(value) or 0
	if value >= 1e9 then
		return string.format("%.1fB", value / 1e9)
	elseif value >= 1e6 then
		return string.format("%.1fM", value / 1e6)
	elseif value >= 1e3 then
		return string.format("%.1fK", value / 1e3)
	end
	return tostring(math.floor(value))
end

local function newPart(parent, name, size, cframe, material, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color or Color3.new(1, 1, 1)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addBillboard(part, text, color, width, height)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 280, height or 84)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 23, 38)
	label.BackgroundTransparency = 0.18
	label.Text = text
	label.TextWrapped = true
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	return label
end

local function slotPosition(index)
	local cfg = Services.GameConfig.Raid
	local angle = ((index - 1) / cfg.MaxBases) * math.pi * 2
	local offset = Vector3.new(math.cos(angle) * cfg.RingRadius, 0, math.sin(angle) * cfg.RingRadius)
	return cfg.ArenaCenter + offset
end

local function firstFreeSlot()
	for index = 1, Services.GameConfig.Raid.MaxBases do
		if not slotOwners[index] then
			return index
		end
	end
	return nil
end

function BaseService:Init(services)
	Services = services
end

function BaseService:GetAssignment(player)
	return assignments[player]
end

function BaseService:GetCorePart(owner)
	local assignment = assignments[owner]
	return assignment and assignment.Core or nil
end

function BaseService:GetReserved(owner)
	return Services.RaidService:GetReservedForVictim(owner.UserId)
end

function BaseService:GetAvailableCharge(owner)
	local profile = Services.DataService:GetProfile(owner)
	if not profile then
		return 0
	end
	return math.max(0, math.floor(profile.CoreCharge - self:GetReserved(owner)))
end

function BaseService:IsNearCore(player, owner, distance)
	local core = self:GetCorePart(owner)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return core and root and (root.Position - core.Position).Magnitude <= (distance or 18)
end

function BaseService:IsNearDeposit(player, distance)
	local assignment = assignments[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return assignment and root and (root.Position - assignment.Deposit.Position).Magnitude <= (distance or 18)
end

function BaseService:SetShieldVisual(owner, active)
	local assignment = assignments[owner]
	if not assignment or not assignment.Shield then
		return
	end
	assignment.Shield.Transparency = active and 0.72 or 1
	assignment.Shield.Material = Enum.Material.ForceField
end

function BaseService:UpdateCoreVisual(owner)
	local assignment = assignments[owner]
	local profile = Services.DataService:GetProfile(owner)
	if not assignment or not profile then
		return
	end

	local label = coreLabels[owner]
	if label then
		local capacity = Services.GameConfig.GetCoreCapacity(profile.CoreLevel)
		label.Text = string.format(
			"%s\nLEVEL %s\n%s / %s CHARGE",
			Services.GameConfig.GetCoreName(profile.CoreLevel),
			profile.CoreLevel,
			formatNumber(profile.CoreCharge),
			formatNumber(capacity)
		)
	end

	local level = profile.CoreLevel
	if level >= 35 then
		assignment.Core.Color = Color3.fromRGB(118, 69, 255)
	elseif level >= 20 then
		assignment.Core.Color = Color3.fromRGB(255, 72, 95)
	elseif level >= 10 then
		assignment.Core.Color = Color3.fromRGB(255, 72, 223)
	elseif level >= 5 then
		assignment.Core.Color = Color3.fromRGB(255, 174, 54)
	else
		assignment.Core.Color = Color3.fromRGB(62, 224, 255)
	end
end

function BaseService:ClaimCore(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	local amount = self:GetAvailableCharge(player)
	if amount <= 0 then
		Services.NetworkService:Toast(player, "Your Core has no unreserved Charge to claim.", "Warning")
		return false
	end

	profile.CoreCharge -= amount
	profile.Stats.CoreEnergyClaimed += amount
	Services.EconomyService:AddEnergy(player, amount, "CoreClaim")
	Services.AnalyticsService:Custom(player, "CoreClaimed", amount)
	self:UpdateCoreVisual(player)
	Services.NetworkService:Toast(player, "+" .. formatNumber(amount) .. " Energy banked from your Core!", "Energy")
	return true
end

function BaseService:UpgradeCore(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	if profile.CoreLevel >= Services.GameConfig.Raid.Core.MaxLevel then
		Services.NetworkService:Toast(player, "Your Core has reached maximum evolution.", "Rare")
		return false
	end

	local cost = Services.GameConfig.GetCoreUpgradeCost(profile.CoreLevel)
	if not Services.EconomyService:SpendEnergy(player, cost, "CoreUpgrade") then
		Services.NetworkService:Toast(player, "You need " .. formatNumber(cost) .. " Energy to evolve your Core.", "Warning")
		return false
	end

	profile.CoreLevel += 1
	Services.AchievementService:Evaluate(player)
	Services.AnalyticsService:Custom(player, "CoreUpgraded", profile.CoreLevel)
	self:UpdateCoreVisual(player)
	Services.NetworkService:PushState(player)
	Services.NetworkService:BannerAll(
		Services.GameConfig.GetCoreName(profile.CoreLevel) .. " EVOLVED",
		player.Name .. "'s Power Core reached Level " .. profile.CoreLevel .. "!",
		4
	)
	return true
end

function BaseService:TeleportHome(player)
	if Services.RaidService:IsCarrying(player) then
		Services.NetworkService:Toast(player, "You cannot teleport while carrying a stolen fragment. Escape on foot!", "Warning")
		return false
	end

	local assignment = assignments[player]
	local character = player.Character
	if assignment and character then
		character:PivotTo(CFrame.new(assignment.SpawnPosition))
		return true
	end
	return false
end

function BaseService:_createBridge(parent, islandPosition)
	local cfg = Services.GameConfig.Raid
	local hubPosition = cfg.ArenaCenter
	local direction = hubPosition - islandPosition
	local distance = direction.Magnitude
	local bridgeLength = math.max(20, distance - (cfg.IslandSize / 2) - (cfg.HubSize / 2))
	local unit = direction.Unit
	local start = islandPosition + unit * (cfg.IslandSize / 2)
	local finish = hubPosition - unit * (cfg.HubSize / 2)
	local midpoint = (start + finish) / 2

	local bridge = newPart(
		parent,
		"RaidBridge",
		Vector3.new(10, 2, bridgeLength),
		CFrame.lookAt(midpoint, finish),
		Enum.Material.Metal,
		Color3.fromRGB(58, 71, 91)
	)
	return bridge
end

function BaseService:_createPlayerBase(player, slot)
	local cfg = Services.GameConfig.Raid
	local center = slotPosition(slot)

	local model = Instance.new("Model")
	model.Name = "Base_" .. player.UserId
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = arenaFolder

	local platform = newPart(
		model,
		"Island",
		Vector3.new(cfg.IslandSize, 4, cfg.IslandSize),
		CFrame.new(center),
		Enum.Material.SmoothPlastic,
		Color3.fromRGB(36, 49, 69)
	)

	local trim = newPart(
		model,
		"IslandTrim",
		Vector3.new(cfg.IslandSize + 4, 1, cfg.IslandSize + 4),
		CFrame.new(center - Vector3.new(0, 2.5, 0)),
		Enum.Material.Neon,
		Color3.fromRGB(55, 211, 255)
	)

	local core = newPart(
		model,
		"PowerCore",
		Vector3.new(8, 12, 8),
		CFrame.new(center + Vector3.new(0, 8, 0)),
		Enum.Material.Neon,
		Color3.fromRGB(62, 224, 255)
	)
	core.Shape = Enum.PartType.Ball

	local coreLight = Instance.new("PointLight")
	coreLight.Range = 28
	coreLight.Brightness = 3
	coreLight.Color = core.Color
	coreLight.Parent = core

	coreLabels[player] = addBillboard(core, "POWER CORE", core.Color, 320, 100)

	local claimPrompt = Instance.new("ProximityPrompt")
	claimPrompt.Name = "ClaimCorePrompt"
	claimPrompt.ActionText = "Claim Charge"
	claimPrompt.ObjectText = "Your Power Core"
	claimPrompt.HoldDuration = 0.2
	claimPrompt.MaxActivationDistance = 14
	claimPrompt.RequiresLineOfSight = false
	claimPrompt.Parent = core
	claimPrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player and self:IsNearCore(triggeringPlayer, player, 18) then
			self:ClaimCore(player)
		end
	end)

	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.Name = "StealCorePrompt"
	stealPrompt.ActionText = "STEAL FRAGMENT"
	stealPrompt.ObjectText = player.DisplayName .. "'s Power Core"
	stealPrompt.HoldDuration = cfg.Steal.HoldDuration
	stealPrompt.MaxActivationDistance = 14
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.Parent = core
	stealPrompt.Triggered:Connect(function(thief)
		if thief ~= player then
			Services.RaidService:TrySteal(thief, player)
		end
	end)

	local upgradePad = newPart(
		model,
		"CoreUpgradePad",
		Vector3.new(12, 1, 12),
		CFrame.new(center + Vector3.new(-20, 3, 12)),
		Enum.Material.Neon,
		Color3.fromRGB(255, 174, 54)
	)
	addBillboard(upgradePad, "EVOLVE CORE", Color3.fromRGB(255, 211, 119), 220, 60)

	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.ActionText = "Upgrade Core"
	upgradePrompt.ObjectText = "Core Evolution"
	upgradePrompt.HoldDuration = 0.35
	upgradePrompt.MaxActivationDistance = 13
	upgradePrompt.RequiresLineOfSight = false
	upgradePrompt.Parent = upgradePad
	upgradePrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player then
			self:UpgradeCore(player)
		end
	end)

	local deposit = newPart(
		model,
		"DepositPad",
		Vector3.new(14, 1, 14),
		CFrame.new(center + Vector3.new(20, 3, 12)),
		Enum.Material.Neon,
		Color3.fromRGB(119, 255, 136)
	)
	addBillboard(deposit, "BANK STOLEN CORE", Color3.fromRGB(151, 255, 164), 250, 60)

	local depositPrompt = Instance.new("ProximityPrompt")
	depositPrompt.ActionText = "Bank Fragment"
	depositPrompt.ObjectText = "Secure Vault"
	depositPrompt.HoldDuration = 0.25
	depositPrompt.MaxActivationDistance = 14
	depositPrompt.RequiresLineOfSight = false
	depositPrompt.Parent = deposit
	depositPrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player then
			Services.RaidService:Deposit(player)
		end
	end)

	local shield = Instance.new("Part")
	shield.Name = "CoreShield"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(24, 24, 24)
	shield.CFrame = core.CFrame
	shield.Anchored = true
	shield.CanCollide = false
	shield.CanTouch = false
	shield.CanQuery = false
	shield.Material = Enum.Material.ForceField
	shield.Color = Color3.fromRGB(93, 194, 255)
	shield.Transparency = 1
	shield.Parent = model

	local ownerMarker = newPart(
		model,
		"OwnerMarker",
		Vector3.new(1, 1, 1),
		CFrame.new(center + Vector3.new(0, 5, 27)),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1)
	)
	ownerMarker.Transparency = 1
	ownerMarker.CanCollide = false
	addBillboard(ownerMarker, player.DisplayName .. "'S ISLAND", Color3.new(1, 1, 1), 300, 70)

	assignments[player] = {
		Model = model,
		Slot = slot,
		Core = core,
		Deposit = deposit,
		Shield = shield,
		SpawnPosition = center + Vector3.new(0, 6, 25),
	}

	self:_createBridge(model, center)
	self:UpdateCoreVisual(player)

	Services.RaidService:SetShield(player, cfg.Steal.ShieldOnJoinSeconds)
end

function BaseService:_assign(player)
	if assignments[player] then
		return
	end

	for _ = 1, 40 do
		if Services.DataService:GetProfile(player) then
			break
		end
		task.wait(0.25)
	end
	if not Services.DataService:GetProfile(player) then
		return
	end

	local slot = firstFreeSlot()
	if not slot then
		Services.NetworkService:Toast(player, "Raid arena is full in this server.", "Warning")
		return
	end

	slotOwners[slot] = player
	self:_createPlayerBase(player, slot)

	local function onCharacter(character)
		task.wait(0.75)
		if assignments[player] and character.Parent then
			character:PivotTo(CFrame.new(assignments[player].SpawnPosition))
			Services.RaidService:SetShield(player, 15)
		end
	end

	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	Services.NetworkService:PushState(player)
end

function BaseService:_release(player)
	local assignment = assignments[player]
	if not assignment then
		return
	end
	slotOwners[assignment.Slot] = nil
	if assignment.Model then
		assignment.Model:Destroy()
	end
	assignments[player] = nil
	coreLabels[player] = nil
end

function BaseService:_createArena()
	local old = workspace:FindFirstChild("CoreRaidArena")
	if old then
		old:Destroy()
	end

	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "CoreRaidArena"
	arenaFolder.Parent = workspace

	local cfg = Services.GameConfig.Raid
	hub = newPart(
		arenaFolder,
		"RaidHub",
		Vector3.new(cfg.HubSize, 4, cfg.HubSize),
		CFrame.new(cfg.ArenaCenter),
		Enum.Material.Metal,
		Color3.fromRGB(27, 34, 52)
	)

	local hubMarker = newPart(
		arenaFolder,
		"HubMarker",
		Vector3.new(1, 1, 1),
		CFrame.new(cfg.ArenaCenter + Vector3.new(0, 8, 0)),
		Enum.Material.SmoothPlastic,
		Color3.new(1, 1, 1)
	)
	hubMarker.Transparency = 1
	hubMarker.CanCollide = false
	addBillboard(hubMarker, "CORE RAID HUB\nSTEAL • ESCAPE • BANK", Color3.fromRGB(255, 112, 203), 420, 90)

	local adventurePortal = newPart(
		arenaFolder,
		"AdventurePortal",
		Vector3.new(16, 18, 3),
		CFrame.new(cfg.ArenaCenter + Vector3.new(0, 10, -38)),
		Enum.Material.Neon,
		Color3.fromRGB(111, 114, 255)
	)
	addBillboard(adventurePortal, "ADVENTURE WORLDS", Color3.fromRGB(175, 177, 255), 280, 60)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Travel"
	prompt.ObjectText = "Adventure Portal"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = adventurePortal
	prompt.Triggered:Connect(function(player)
		if Services.RaidService:IsCarrying(player) then
			Services.NetworkService:Toast(player, "Bank or lose the stolen fragment before leaving the raid arena.", "Warning")
			return
		end
		local character = player.Character
		if character then
			character:PivotTo(CFrame.new(0, 7, 24))
		end
	end)

	local world = workspace:WaitForChild("PowerIslandsWorld", 10)
	if world then
		local returnPortal = newPart(
			world,
			"ReturnToCoreArena",
			Vector3.new(14, 18, 3),
			CFrame.new(Vector3.new(48, 10, 0)),
			Enum.Material.Neon,
			Color3.fromRGB(255, 112, 203)
		)
		addBillboard(returnPortal, "RETURN TO\nYOUR POWER CORE", Color3.fromRGB(255, 170, 220), 300, 75)
		local returnPrompt = Instance.new("ProximityPrompt")
		returnPrompt.ActionText = "Return Home"
		returnPrompt.ObjectText = "Core Raid Arena"
		returnPrompt.HoldDuration = 0.25
		returnPrompt.MaxActivationDistance = 15
		returnPrompt.RequiresLineOfSight = false
		returnPrompt.Parent = returnPortal
		returnPrompt.Triggered:Connect(function(player)
			self:TeleportHome(player)
		end)
	end
end

function BaseService:GetClientState(player)
	local profile = Services.DataService:GetProfile(player)
	local assignment = assignments[player]
	if not profile then
		return nil
	end

	return {
		Assigned = assignment ~= nil,
		Slot = assignment and assignment.Slot or 0,
		Level = profile.CoreLevel,
		Name = Services.GameConfig.GetCoreName(profile.CoreLevel),
		Charge = math.floor(profile.CoreCharge),
		AvailableCharge = self:GetAvailableCharge(player),
		Capacity = Services.GameConfig.GetCoreCapacity(profile.CoreLevel),
		RatePerSecond = Services.GameConfig.GetCoreRate(profile.CoreLevel),
		UpgradeCost = profile.CoreLevel < Services.GameConfig.Raid.Core.MaxLevel
			and Services.GameConfig.GetCoreUpgradeCost(profile.CoreLevel)
			or 0,
	}
end

function BaseService:Start()
	self:_createArena()

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:_assign(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_release(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_assign(player)
		end)
	end

	task.spawn(function()
		local tickCount = 0
		while task.wait(1) do
			tickCount += 1
			for player, assignment in pairs(assignments) do
				local profile = Services.DataService:GetProfile(player)
				if profile then
					local capacity = Services.GameConfig.GetCoreCapacity(profile.CoreLevel)
					local rate = Services.GameConfig.GetCoreRate(profile.CoreLevel)
					profile.CoreCharge = math.min(capacity, profile.CoreCharge + rate)
					self:UpdateCoreVisual(player)
					if tickCount % 5 == 0 then
						Services.NetworkService:PushState(player)
					end
				end
			end
		end
	end)
end

return BaseService
