local Players = game:GetService("Players")

local WorldService = {}
local Services
local playerNodeCooldowns = {}

local WORLD_CENTERS = {
	Starter = Vector3.new(0, 0, 0),
	Jungle = Vector3.new(0, 0, 220),
	Ice = Vector3.new(220, 0, 220),
	Volcano = Vector3.new(440, 0, 220),
	Cyber = Vector3.new(440, 0, 0),
	Space = Vector3.new(220, 0, 0),
}

local WORLD_STYLE = {
	Starter = { Surface = Enum.Material.Grass, SurfaceColor = Color3.fromRGB(76, 180, 90), Rock = Color3.fromRGB(90, 92, 96), Node = Color3.fromRGB(0, 220, 255) },
	Jungle = { Surface = Enum.Material.Grass, SurfaceColor = Color3.fromRGB(48, 142, 70), Rock = Color3.fromRGB(66, 82, 69), Node = Color3.fromRGB(108, 255, 93) },
	Ice = { Surface = Enum.Material.Ice, SurfaceColor = Color3.fromRGB(177, 232, 255), Rock = Color3.fromRGB(90, 130, 155), Node = Color3.fromRGB(112, 224, 255) },
	Volcano = { Surface = Enum.Material.CrackedLava, SurfaceColor = Color3.fromRGB(128, 48, 32), Rock = Color3.fromRGB(52, 42, 42), Node = Color3.fromRGB(255, 93, 35) },
	Cyber = { Surface = Enum.Material.Metal, SurfaceColor = Color3.fromRGB(46, 57, 78), Rock = Color3.fromRGB(24, 29, 42), Node = Color3.fromRGB(255, 58, 229) },
	Space = { Surface = Enum.Material.Slate, SurfaceColor = Color3.fromRGB(43, 43, 66), Rock = Color3.fromRGB(19, 20, 33), Node = Color3.fromRGB(176, 109, 255) },
}

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

local function addBillboard(part, text, color, width)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 260, 72)
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

function WorldService:Init(services)
	Services = services
end

function WorldService:_createIsland(parent, worldInfo)
	local center = WORLD_CENTERS[worldInfo.Id]
	local style = WORLD_STYLE[worldInfo.Id]

	local island = newPart(parent, worldInfo.Id .. "Island", Vector3.new(120, 4, 120), center, style.Surface, style.SurfaceColor)
	island.Shape = Enum.PartType.Cylinder
	island.Orientation = Vector3.new(0, 0, 90)

	local rock = newPart(parent, worldInfo.Id .. "Rock", Vector3.new(108, 7, 108), center + Vector3.new(0, -4, 0), Enum.Material.Slate, style.Rock)
	rock.Shape = Enum.PartType.Cylinder
	rock.Orientation = Vector3.new(0, 0, 90)

	local marker = newPart(parent, worldInfo.Id .. "WorldMarker", Vector3.new(1, 1, 1), center + Vector3.new(0, 8, 0), Enum.Material.SmoothPlastic, style.Node)
	marker.Transparency = 1
	marker.CanCollide = false
	addBillboard(marker, string.format("%s\nx%s ENERGY", worldInfo.Name, worldInfo.RewardMultiplier), style.Node, 300)
end

function WorldService:_createEnergyNode(parent, index, position, worldId)
	local style = WORLD_STYLE[worldId]
	local node = Instance.new("Part")
	node.Name = worldId .. "_EnergyNode_" .. index
	node.Shape = Enum.PartType.Ball
	node.Size = Vector3.new(4, 4, 4)
	node.Position = position
	node.Anchored = true
	node.CanCollide = false
	node.Material = Enum.Material.Neon
	node.Color = style.Node
	node.Parent = parent

	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 2
	light.Color = node.Color
	light.Parent = node

	local worldInfo = Services.GameConfig.GetWorld(worldId)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = worldInfo.Name .. " Energy"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Services.GameConfig.EnergyNodes.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = node

	prompt.Triggered:Connect(function(player)
		if not Services.DataService:IsLoaded(player)
			or not playerNearPart(player, node, Services.GameConfig.EnergyNodes.InteractionDistance + 4) then
			return
		end

		local profile = Services.DataService:GetProfile(player)
		if worldId ~= "Starter" and not profile.UnlockedWorlds[worldId] then
			Services.NetworkService:Toast(player, "Unlock this world first.", "Warning")
			return
		end

		playerNodeCooldowns[player] = playerNodeCooldowns[player] or {}
		local now = os.clock()
		local last = playerNodeCooldowns[player][node] or 0
		if now - last < Services.GameConfig.EnergyNodes.RespawnSeconds then
			return
		end
		playerNodeCooldowns[player][node] = now

		profile.Stats.EnergyNodesCollected += 1

		local petMultiplier = Services.CompanionService:GetMultiplierFromProfile(profile)
		local crystalMultiplier = 1 + (profile.PowerCrystals * Services.GameConfig.Rebirth.CrystalEnergyBonus)
		local friendMultiplier = Services.SocialService:GetMultiplier(player)
		local partyMultiplier = Services.PartyService:GetMultiplier(player)
		local eventMultiplier = Services.LiveEventService:GetEnergyMultiplier()
		local paidMultiplier = Services.MonetizationService:GetEnergyMultiplier(player)

		local reward = math.max(1, math.floor(
			Services.GameConfig.EnergyNodes.BaseReward
				* profile.Power
				* worldInfo.RewardMultiplier
				* petMultiplier
				* crystalMultiplier
				* friendMultiplier
				* partyMultiplier
				* eventMultiplier
				* paidMultiplier
		))

		if Services.EconomyService:AddEnergy(player, reward, worldId .. "Node") then
			Services.QuestService:Update(player, "collect_10", 1)
			Services.AchievementService:Evaluate(player)
			Services.NetworkService:Toast(player, string.format("+%s Energy", formatNumber(reward)), "Energy")
		end
	end)
end

function WorldService:_createUpgradeStation(parent)
	local center = WORLD_CENTERS.Starter
	local station = newPart(parent, "PowerUpgradeStation", Vector3.new(13, 1, 13), center + Vector3.new(-25, 3.2, -25), Enum.Material.Neon, Color3.fromRGB(255, 170, 0))
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
			Services.UpgradeService:BuyPowerUpgrade(player)
		end
	end)
end

function WorldService:_createEggStation(parent)
	local center = WORLD_CENTERS.Starter
	local egg = newPart(parent, "StarterEgg", Vector3.new(8, 10, 8), center + Vector3.new(27, 7, -24), Enum.Material.Neon, Color3.fromRGB(193, 108, 255))
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
			Services.CompanionService:HatchStarterEgg(player)
		end
	end)
end

function WorldService:_createRebirthStation(parent)
	local center = WORLD_CENTERS.Starter
	local station = newPart(parent, "RebirthStation", Vector3.new(14, 1, 14), center + Vector3.new(0, 3.2, 40), Enum.Material.Neon, Color3.fromRGB(255, 82, 153))
	addBillboard(station, "REBIRTH ALTAR\nPERMANENT CRYSTAL BOOST", Color3.fromRGB(255, 155, 198), 320)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Altar"
	prompt.HoldDuration = 0.75
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = station

	prompt.Triggered:Connect(function(player)
		if playerNearPart(player, station, 18) and Services.RebirthService:Rebirth(player) then
			teleportPlayer(player, WORLD_CENTERS.Starter + Vector3.new(0, 7, 22))
		end
	end)
end

function WorldService:_createPortal(parent, fromInfo, toInfo, direction)
	local fromCenter = WORLD_CENTERS[fromInfo.Id]
	local toCenter = WORLD_CENTERS[toInfo.Id]
	local style = WORLD_STYLE[toInfo.Id]
	local offset = direction == "Forward" and Vector3.new(0, 10, -52) or Vector3.new(0, 10, 52)
	local portal = newPart(parent, fromInfo.Id .. "_To_" .. toInfo.Id, Vector3.new(14, 18, 3), fromCenter + offset, Enum.Material.Neon, style.Node)

	local text
	if toInfo.UnlockCost > 0 then
		text = string.format("%s\n%s ENERGY", toInfo.Name, formatNumber(toInfo.UnlockCost))
	else
		text = toInfo.Name
	end
	addBillboard(portal, text, style.Node, 300)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = unlockCost > 0 and "Unlock / Travel" or "Travel"
	prompt.ObjectText = toInfo.Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = portal

	prompt.Triggered:Connect(function(player)
		if not playerNearPart(player, portal, 19) then
			return
		end

		local profile = Services.DataService:GetProfile(player)
		if not profile then
			return
		end

		if unlockCost > 0 and not profile.UnlockedWorlds[toInfo.Id] then
			if not Services.EconomyService:SpendEnergy(player, unlockCost, "Unlock_" .. toInfo.Id) then
				Services.NetworkService:Toast(player, "You need " .. formatNumber(unlockCost) .. " Energy.", "Warning")
				return
			end

			profile.UnlockedWorlds[toInfo.Id] = true
			profile.Stats.WorldsUnlocked += 1
			Services.AchievementService:Evaluate(player)
			Services.AnalyticsService:Custom(player, "WorldUnlocked", 1, toInfo.Id)
			Services.NetworkService:PushState(player)
			Services.NetworkService:BannerAll(toInfo.Name .. " UNLOCKED", player.Name .. " reached a new world!", 4)
		end

		teleportPlayer(player, toCenter + Vector3.new(0, 7, direction == "Forward" and 36 or -36))
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

	for _, worldInfo in ipairs(Services.GameConfig.Worlds) do
		self:_createIsland(world, worldInfo)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StarterSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = WORLD_CENTERS.Starter + Vector3.new(0, 3.2, 24)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(105, 255, 145)
	spawn.Parent = world

	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "EnergyNodes"
	nodesFolder.Parent = world

	for _, worldInfo in ipairs(Services.GameConfig.Worlds) do
		local center = WORLD_CENTERS[worldInfo.Id]
		for index = 1, Services.GameConfig.EnergyNodes.Count do
			local angle = (index / Services.GameConfig.EnergyNodes.Count) * math.pi * 2
			local radius = index % 2 == 0 and 38 or 48
			self:_createEnergyNode(nodesFolder, index, center + Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * radius), worldInfo.Id)
		end
	end

	for index = 1, #Services.GameConfig.Worlds - 1 do
		local fromInfo = Services.GameConfig.Worlds[index]
		local toInfo = Services.GameConfig.Worlds[index + 1]
		self:_createPortal(world, fromInfo, toInfo, "Forward")
		self:_createPortal(world, toInfo, fromInfo, "Back")
	end

	self:_createUpgradeStation(world)
	self:_createEggStation(world)
	self:_createRebirthStation(world)

	local welcome = newPart(world, "WelcomeSign", Vector3.new(28, 11, 1), WORLD_CENTERS.Starter + Vector3.new(0, 9, 47), Enum.Material.SmoothPlastic, Color3.fromRGB(35, 42, 60))
	addBillboard(welcome, "POWER ISLANDS\nCOLLECT • HATCH • EXPLORE • REBIRTH", Color3.new(1, 1, 1), 420)

	Players.PlayerRemoving:Connect(function(player)
		playerNodeCooldowns[player] = nil
	end)
end

return WorldService
