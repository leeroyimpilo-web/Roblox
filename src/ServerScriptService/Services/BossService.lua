local Players = game:GetService("Players")

local BossService = {}

local Services
local bossPart
local healthLabel
local attackPrompt
local health = 0
local alive = false
local respawnAt = 0
local damageByUser = {}

local function setVisual()
	if not bossPart then
		return
	end

	if alive then
		bossPart.Material = Enum.Material.Neon
		bossPart.Color = Color3.fromRGB(110, 255, 95)
		bossPart.Transparency = 0
		attackPrompt.Enabled = true
		healthLabel.Text = string.format("%s\n%s / %s HP", Services.GameConfig.Boss.Name, math.max(0, health), Services.GameConfig.Boss.MaxHealth)
	else
		bossPart.Material = Enum.Material.Slate
		bossPart.Color = Color3.fromRGB(70, 74, 78)
		bossPart.Transparency = 0.4
		attackPrompt.Enabled = false
		healthLabel.Text = string.format("%s\nRESPAWNING...", Services.GameConfig.Boss.Name)
	end
end

function BossService:Init(services)
	Services = services
end

function BossService:GetClientState()
	return {
		Name = Services.GameConfig.Boss.Name,
		Alive = alive,
		Health = health,
		MaxHealth = Services.GameConfig.Boss.MaxHealth,
		RespawnAt = respawnAt,
	}
end

function BossService:_respawn()
	health = Services.GameConfig.Boss.MaxHealth
	alive = true
	respawnAt = 0
	damageByUser = {}
	setVisual()
	Services.NetworkService:BannerAll("BOSS READY", Services.GameConfig.Boss.Name .. " has returned!", 4)
	Services.NetworkService:PushAll()
end

function BossService:ForceRespawn()
	if bossPart then
		self:_respawn()
	end
end

function BossService:_defeat(killer)
	alive = false
	respawnAt = os.time() + Services.GameConfig.Boss.RespawnSeconds
	setVisual()

	for userId in pairs(damageByUser) do
		local participant = Players:GetPlayerByUserId(userId)
		if participant and Services.DataService:GetProfile(participant) then
			local profile = Services.DataService:GetProfile(participant)
			profile.Stats.BossKills += 1
			Services.EconomyService:AddEnergy(participant, Services.GameConfig.Boss.BaseRewardEnergy, "BossReward")
			Services.AchievementService:Evaluate(participant)
			Services.AnalyticsService:Custom(participant, "BossDefeated", 1, Services.GameConfig.Boss.Name)
			Services.NetworkService:Toast(participant, "+5,000 Energy • Jungle Titan defeated!", "Rare")
		end
	end

	Services.NetworkService:BannerAll("TITAN DEFEATED", killer.Name .. " landed the final hit!", 5)
	Services.NetworkService:PushAll()

	task.delay(Services.GameConfig.Boss.RespawnSeconds, function()
		if not alive then
			self:_respawn()
		end
	end)
end

function BossService:Attack(player)
	if not alive or not bossPart or not Services.SecurityService:Allow(player, "BossAttack", Services.GameConfig.Boss.AttackCooldown) then
		return false
	end

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - bossPart.Position).Magnitude > 22 then
		return false
	end

	local profile = Services.DataService:GetProfile(player)
	if not profile or not profile.UnlockedWorlds.Jungle then
		return false
	end

	local petMultiplier = Services.CompanionService:GetMultiplierFromProfile(profile)
	local crystalMultiplier = 1 + (profile.PowerCrystals * Services.GameConfig.Rebirth.CrystalEnergyBonus)
	local damage = math.max(1, math.floor(profile.Power * petMultiplier * crystalMultiplier))

	damageByUser[player.UserId] = (damageByUser[player.UserId] or 0) + damage
	health = math.max(0, health - damage)
	setVisual()
	Services.NetworkService:PushAll()

	if health <= 0 then
		self:_defeat(player)
	end
	return true
end

function BossService:Start()
	local world = workspace:WaitForChild("PowerIslandsWorld", 10)
	local jungle = world and world:FindFirstChild("JungleIsland")
	if not jungle then
		warn("[BossService] Jungle Island not found")
		return
	end

	bossPart = Instance.new("Part")
	bossPart.Name = "JungleTitan"
	bossPart.Shape = Enum.PartType.Ball
	bossPart.Size = Vector3.new(18, 18, 18)
	bossPart.Position = jungle.Position + Vector3.new(0, 11, -18)
	bossPart.Anchored = true
	bossPart.CanCollide = true
	bossPart.Parent = world

	attackPrompt = Instance.new("ProximityPrompt")
	attackPrompt.ActionText = "Attack"
	attackPrompt.ObjectText = Services.GameConfig.Boss.Name
	attackPrompt.HoldDuration = 0
	attackPrompt.MaxActivationDistance = 18
	attackPrompt.RequiresLineOfSight = false
	attackPrompt.Parent = bossPart
	attackPrompt.Triggered:Connect(function(player)
		self:Attack(player)
	end)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(320, 86)
	gui.StudsOffset = Vector3.new(0, 12, 0)
	gui.AlwaysOnTop = true
	gui.Parent = bossPart

	healthLabel = Instance.new("TextLabel")
	healthLabel.Size = UDim2.fromScale(1, 1)
	healthLabel.BackgroundTransparency = 0.25
	healthLabel.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
	healthLabel.TextScaled = true
	healthLabel.TextWrapped = true
	healthLabel.Font = Enum.Font.GothamBold
	healthLabel.TextColor3 = Color3.new(1, 1, 1)
	healthLabel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = healthLabel

	self:_respawn()
end

return BossService
