local Players = game:GetService("Players")

local WorldService = {}

local DataService
local EconomyService
local UpgradeService
local NetworkService
local GameConfig
local playerNodeCooldowns = {}

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

function WorldService:Init(services)
	DataService = services.DataService
	EconomyService = services.EconomyService
	UpgradeService = services.UpgradeService
	NetworkService = services.NetworkService
	GameConfig = services.GameConfig
end

function WorldService:_createEnergyNode(parent, index, position)
	local node = Instance.new("Part")
	node.Name = "EnergyNode_" .. index
	node.Shape = Enum.PartType.Ball
	node.Size = Vector3.new(4, 4, 4)
	node.Position = position
	node.Anchored = true
	node.CanCollide = false
	node.Material = Enum.Material.Neon
	node.Color = Color3.fromRGB(0, 220, 255)
	node.Parent = parent

	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 2
	light.Parent = node

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = "Energy"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = GameConfig.EnergyNodes.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = node

	prompt.Triggered:Connect(function(player)
		if not DataService:IsLoaded(player) or not playerNearPart(player, node, GameConfig.EnergyNodes.InteractionDistance + 4) then
			return
		end

		playerNodeCooldowns[player] = playerNodeCooldowns[player] or {}
		local now = os.clock()
		local last = playerNodeCooldowns[player][node] or 0
		if now - last < GameConfig.EnergyNodes.RespawnSeconds then
			return
		end
		playerNodeCooldowns[player][node] = now

		local profile = DataService:GetProfile(player)
		local reward = GameConfig.EnergyNodes.BaseReward * profile.Power
		if EconomyService:AddEnergy(player, reward) then
			profile.Stats.EnergyNodesCollected += 1
			NetworkService:Toast(player, string.format("+%s Energy", reward), "Energy")
		end
	end)
end

function WorldService:_createUpgradeStation(parent)
	local station = newPart(parent, "PowerUpgradeStation", Vector3.new(13, 1, 13), Vector3.new(0, 3.2, -28), Enum.Material.Neon, Color3.fromRGB(255, 170, 0))
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

function WorldService:Start()
	local old = workspace:FindFirstChild("PowerIslandsWorld")
	if old then
		old:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "PowerIslandsWorld"
	world.Parent = workspace

	local island = newPart(world, "StarterIsland", Vector3.new(120, 4, 120), Vector3.new(0, 0, 0), Enum.Material.Grass, Color3.fromRGB(76, 180, 90))
	island.Shape = Enum.PartType.Cylinder
	island.Orientation = Vector3.new(0, 0, 90)

	newPart(world, "IslandRock", Vector3.new(108, 7, 108), Vector3.new(0, -4, 0), Enum.Material.Slate, Color3.fromRGB(90, 92, 96)).Shape = Enum.PartType.Cylinder
	world.IslandRock.Orientation = Vector3.new(0, 0, 90)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StarterSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 3.2, 24)
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
		local position = Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * radius)
		self:_createEnergyNode(nodesFolder, index, position)
	end

	self:_createUpgradeStation(world)

	local sign = newPart(world, "WelcomeSign", Vector3.new(28, 11, 1), Vector3.new(0, 9, 47), Enum.Material.SmoothPlastic, Color3.fromRGB(35, 42, 60))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "POWER ISLANDS\nCollect Energy • Upgrade Power"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = surface

	Players.PlayerRemoving:Connect(function(player)
		playerNodeCooldowns[player] = nil
	end)
end

return WorldService
