local Players = game:GetService("Players")

local WorldService = {}

local DataService
local EconomyService
local UpgradeService
local CompanionService
local QuestService
local RebirthService
local NetworkService
local GameConfig
local playerNodeCooldowns = {}

local STARTER_CENTER = Vector3.new(0, 0, 0)
local JUNGLE_CENTER = Vector3.new(0, 0, 220)

local function newPart(parent, name, size, position, material, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color or Color3.new(1, 1, 1)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function playerNearPart(player, part, maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position - part.Position).Magnitude <= maxDistance
end

local function teleportPlayer(player, position)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(position))
	end
end

local function addBillboard(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 64)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextWrapped = true
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui
end

function WorldService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	UpgradeService = services.UpgradeService
	CompanionService = services.CompanionService
	QuestService = services.QuestService
	RebirthService = services.RebirthService
	NetworkService = services.NetworkService
	GameConfig = services.GameConfig
end

function WorldService:_createIsland(parent, name, center, grassColor, rockColor)
	local island = newPart(parent, name, Vector3.new(120, 4, 120), center, Enum.Material.Grass, grassColor)
	island.Shape = Enum.PartType.Cylinder
	island.Orientation = Vector3.new(0, 0, 90)

	local rock = newPart(parent, name .. "Rock", Vector3.new(108, 7, 108), center + Vector3.new(0, -4, 0), Enum.Material.Slate, rockColor)
	rock.Shape = Enum.PartType.Cylinder
	rock.Orientation = Vector3.new(0, 0, 90)
end

function WorldService:_createEnergyNode(parent, index, position, worldId)
	local node = Instance.new("Part")
	node.Name = worldId .. "_EnergyNode_" .. index
	node.Shape = Enum.PartType.Ball
	node.Size = Vector3.new(4, 4, 4)
	node.Position = position
	node.Anchored = true
	node.CanCollide = false
	node.Material = Enum.Material.Neon
	node.Color = worldId == "Jungle" and Color3.fromRGB(108, 255, 93) or Color3.fromRGB(0, 220, 255)
	node.Parent = parent

	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 2
	light.Color = node.Color
	light.Parent = node

	local worldInfo = GameConfig.GetWorld(worldId)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = worldId == "Jungle" and "Jungle Energy" or "Energy"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = GameConfig.EnergyNodes.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = node

	prompt.Triggered:Connect(function(player)
		if not DataService:IsLoaded(player) or not playerNearPart(player, node, GameConfig.EnergyNodes.InteractionDistance + 4) then
			return
		end

		local profile = DataService:GetProfile(player)
		if worldId ~= "Starter" and not profile.UnlockedWorlds[worldId] then
			NetworkService:Toast(player, "Unlock this world first.", "Warning")
			return
		end

		playerNodeCooldowns[player] = playerNodeCooldowns[player] or {}
		local now = os.clock()
		local last = playerNodeCooldowns[player][node] or 0
		if now - last < GameConfig.EnergyNodes.RespawnSeconds then
			return
		end
		playerNodeCooldowns[player][node] = now

		local petMultiplier = CompanionService:GetMultiplierFromProfile(profile)
		local reward = math.max(1, math.floor(
			GameConfig.EnergyNodes.BaseReward
				* profile.Power
				* (worldInfo and worldInfo.RewardMultiplier or 1)
				* petMultiplier
		))

		if EconomyService:AddEnergy(player, reward) then
			profile.Stats.EnergyNodesCollected += 1
			QuestService:Update(player, "collect_10", 1)
			NetworkService:Toast(player, string.format("+%s Energy", reward), "Energy")
		end
	end)
end

function WorldService:_createUpgradeStation(parent)
	local station = newPart(parent, "PowerUpgradeStation", Vector3.new(13, 1, 13), STARTER_CENTER + Vector3.new(-25, 3.2, -25), Enum.Material.Neon, Color3.fromRGB(255, 170, 0))
	addBillboard(station, "POWER STATION", Color3.fromRGB(255, 206, 92))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Upgrade Power"
	prompt.ObjectText = "Power Station"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = station

	prompt.Triggered:Connect(function(player)
		if playerNearPart(player, station, 18) then
			UpgradeService:BuyPowerUpgrade(player)
		end
	end)
end

function WorldService:_createEggStation(parent)
	local egg = newPart(parent, "StarterEgg", Vector3.new(8, 10, 8), STARTER_CENTER + Vector3.new(27, 7, -24), Enum.Material.Neon, Color3.fromRGB(193, 108, 255))
	egg.Shape = Enum.PartType.Ball
	addBillboard(egg, "STARTER EGG\n250 ENERGY", Color3.fromRGB(230, 181, 255))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hatch"
	prompt.ObjectText = "Starter Egg • 250 Energy"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg

	prompt.Triggered:Connect(function(player)
		if playerNearPart(player, egg, 18) then
			CompanionService:HatchStarterEgg(player)
		end
	end)
end

function WorldService:_createRebirthStation(parent)
	local station = newPart(parent, "RebirthStation", Vector3.new(14, 1, 14), STARTER_CENTER + Vector3.new(0, 3.2, 40), Enum.Material.Neon, Color3.fromRGB(255, 82, 153))
	addBillboard(station, "REBIRTH ALTAR\nPermanent Power Crystals", Color3.fromRGB(255, 155, 198))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Altar"
	prompt.HoldDuration = 0.75
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = station

	prompt.Triggered:Connect(function(player)
		if playerNearPart(player, station, 18) and RebirthService:Rebirth(player) then
			teleportPlayer(player, STARTER_CENTER + Vector3.new(0, 7, 22))
		end
	end)
end

function WorldService:_createJunglePortals(parent)
	local jungleInfo = GameConfig.GetWorld("Jungle")
	local starterPortal = newPart(parent, "JunglePortal", Vector3.new(14, 18, 3), STARTER_CENTER + Vector3.new(0, 10, -52), Enum.Material.Neon, Color3.fromRGB(57, 232, 111))
	addBillboard(starterPortal, "JUNGLE ISLAND\n5,000 ENERGY", Color3.fromRGB(135, 255, 166))

	local starterPrompt = Instance.new("ProximityPrompt")
	starterPrompt.ActionText = "Unlock / Travel"
	starterPrompt.ObjectText = "Jungle Portal"
	starterPrompt.HoldDuration = 0.4
	starterPrompt.MaxActivationDistance = 15
	starterPrompt.RequiresLineOfSight = false
	starterPrompt.Parent = starterPortal

	starterPrompt.Triggered:Connect(function(player)
		if not playerNearPart(player, starterPortal, 19) then
			return
		end
		local profile = DataService:GetProfile(player)
		if not profile then
			return
		end

		if not profile.UnlockedWorlds.Jungle then
			if not EconomyService:SpendEnergy(player, jungleInfo.UnlockCost) then
				NetworkService:Toast(player, "You need 5,000 Energy to unlock Jungle Island.", "Warning")
				return
			end
			profile.UnlockedWorlds.Jungle = true
			profile.Stats.WorldsUnlocked += 1
			NetworkService:PushState(player)
			NetworkService:Toast(player, "Jungle Island unlocked!", "Success")
		end

		teleportPlayer(player, JUNGLE_CENTER + Vector3.new(0, 7, 38))
	end)

	local returnPortal = newPart(parent, "StarterReturnPortal", Vector3.new(14, 18, 3), JUNGLE_CENTER + Vector3.new(0, 10, 52), Enum.Material.Neon, Color3.fromRGB(83, 187, 255))
	addBillboard(returnPortal, "RETURN TO\nSTARTER ISLAND", Color3.fromRGB(165, 220, 255))

	local returnPrompt = Instance.new("ProximityPrompt")
	returnPrompt.ActionText = "Travel"
	returnPrompt.ObjectText = "Starter Island"
	returnPrompt.HoldDuration = 0.25
	returnPrompt.MaxActivationDistance = 15
	returnPrompt.RequiresLineOfSight = false
	returnPrompt.Parent = returnPortal

	returnPrompt.Triggered:Connect(function(player)
		if playerNearPart(player, returnPortal, 19) then
			teleportPlayer(player, STARTER_CENTER + Vector3.new(0, 7, -35))
		end
	end)
end

function WorldService:Start()
	local old = workspace:FindFirstChild("PowerIslandsWorld")
	if old then
		old:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "PowerIslandsWorld"
	world.Parent = workspace

	self:_createIsland(world, "StarterIsland", STARTER_CENTER, Color3.fromRGB(76, 180, 90), Color3.fromRGB(90, 92, 96))
	self:_createIsland(world, "JungleIsland", JUNGLE_CENTER, Color3.fromRGB(48, 142, 70), Color3.fromRGB(66, 82, 69))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StarterSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = STARTER_CENTER + Vector3.new(0, 3.2, 24)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(105, 255, 145)
	spawn.Parent = world

	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "EnergyNodes"
	nodesFolder.Parent = world

	for index = 1, GameConfig.EnergyNodes.Count do
		local angle = (index / GameConfig.EnergyNodes.Count) * math.pi * 2
		local radius = index % 2 == 0 and 38 or 48
		self:_createEnergyNode(nodesFolder, index, STARTER_CENTER + Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * radius), "Starter")
		self:_createEnergyNode(nodesFolder, index, JUNGLE_CENTER + Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * radius), "Jungle")
	end

	self:_createUpgradeStation(world)
	self:_createEggStation(world)
	self:_createRebirthStation(world)
	self:_createJunglePortals(world)

	local sign = newPart(world, "WelcomeSign", Vector3.new(28, 11, 1), STARTER_CENTER + Vector3.new(0, 9, 47), Enum.Material.SmoothPlastic, Color3.fromRGB(35, 42, 60))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "POWER ISLANDS\nCollect • Upgrade • Hatch • Explore"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = surface

	Players.PlayerRemoving:Connect(function(player)
		playerNodeCooldowns[player] = nil
	end)
end

return WorldService
