local Players = game:GetService("Players")

local RaidService = {}

local Services
local carried = {}
local reservedByVictim = {}
local shieldUntil = {}
local raidCooldowns = {}

local function formatNumber(value)
	value = tonumber(value) or 0
	if value >= 1e6 then
		return string.format("%.1fM", value / 1e6)
	elseif value >= 1e3 then
		return string.format("%.1fK", value / 1e3)
	end
	return tostring(math.floor(value))
end

local function cooldownKey(thiefUserId, victimUserId)
	return tostring(thiefUserId) .. ":" .. tostring(victimUserId)
end

function RaidService:Init(services)
	Services = services
end

function RaidService:GetReservedForVictim(userId)
	return reservedByVictim[userId] or 0
end

function RaidService:IsCarrying(player)
	return carried[player] ~= nil
end

function RaidService:IsShielded(player)
	return (shieldUntil[player.UserId] or 0) > os.time()
end

function RaidService:SetShield(player, seconds)
	if not player then
		return
	end
	local expiry = os.time() + math.max(0, math.floor(seconds or 0))
	shieldUntil[player.UserId] = math.max(shieldUntil[player.UserId] or 0, expiry)
	Services.BaseService:SetShieldVisual(player, true)

	task.delay(math.max(0, expiry - os.time()) + 0.1, function()
		if player.Parent == Players and not self:IsShielded(player) then
			Services.BaseService:SetShieldVisual(player, false)
			Services.NetworkService:PushState(player)
		end
	end)

	Services.NetworkService:PushState(player)
end

function RaidService:_releaseReservation(record)
	if not record then
		return
	end
	local victimId = record.VictimUserId
	reservedByVictim[victimId] = math.max(0, (reservedByVictim[victimId] or 0) - record.Amount)
end

function RaidService:_removeFragment(record)
	if record and record.Visual then
		record.Visual:Destroy()
		record.Visual = nil
	end
end

function RaidService:_attachFragment(thief, victim, record)
	local character = thief.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return false
	end

	local fragment = Instance.new("Part")
	fragment.Name = "StolenPowerFragment"
	fragment.Size = Vector3.new(3.2, 3.2, 3.2)
	fragment.Shape = Enum.PartType.Ball
	fragment.Material = Enum.Material.Neon
	fragment.Color = Color3.fromRGB(255, 72, 199)
	fragment.CanCollide = false
	fragment.Massless = true
	fragment.CFrame = root.CFrame * CFrame.new(0, 2.7, 2.2)
	fragment.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = fragment
	weld.Parent = fragment

	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 2.5
	light.Color = fragment.Color
	light.Parent = fragment

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 68)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = fragment

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(42, 18, 50)
	label.BackgroundTransparency = 0.15
	label.Text = string.format("STOLEN CORE\n%s CHARGE", formatNumber(record.Amount))
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 169, 226)
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	local recoverPrompt = Instance.new("ProximityPrompt")
	recoverPrompt.ActionText = "RECOVER CORE"
	recoverPrompt.ObjectText = victim.DisplayName .. "'s Fragment"
	recoverPrompt.HoldDuration = 0.4
	recoverPrompt.MaxActivationDistance = 10
	recoverPrompt.RequiresLineOfSight = false
	recoverPrompt.Parent = fragment
	recoverPrompt.Triggered:Connect(function(defender)
		if defender == victim then
			self:Recover(victim, thief)
		end
	end)

	record.Visual = fragment
	record.PreviousWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = math.max(18, math.min(humanoid.WalkSpeed, 20))

	humanoid.Died:Once(function()
		self:CancelCarry(thief, "died")
	end)

	return true
end

function RaidService:TrySteal(thief, victim)
	if not thief or not victim or thief == victim then
		return false
	end
	if self:IsCarrying(thief) then
		Services.NetworkService:Toast(thief, "Bank your current fragment before stealing another.", "Warning")
		return false
	end
	if self:IsShielded(victim) then
		Services.NetworkService:Toast(thief, "That Core is shielded. Try another island.", "Warning")
		return false
	end
	if not Services.BaseService:IsNearCore(thief, victim, 18) then
		return false
	end

	local thiefProfile = Services.DataService:GetProfile(thief)
	local victimProfile = Services.DataService:GetProfile(victim)
	if not thiefProfile or not victimProfile then
		return false
	end

	local key = cooldownKey(thief.UserId, victim.UserId)
	local nextAllowed = raidCooldowns[key] or 0
	if os.time() < nextAllowed then
		Services.NetworkService:Toast(thief, "You recently raided this Core. Target another island.", "Warning")
		return false
	end

	local available = math.max(0, victimProfile.CoreCharge - self:GetReservedForVictim(victim.UserId))
	local cfg = Services.GameConfig.Raid.Steal
	if available < cfg.MinimumCharge then
		Services.NetworkService:Toast(thief, "This Core does not have enough Charge to steal yet.", "Warning")
		return false
	end

	local amount = math.floor(math.min(cfg.MaxAmount, math.max(cfg.MinimumCharge, available * cfg.Percent)))
	amount = math.min(amount, math.floor(available))
	if amount <= 0 then
		return false
	end

	reservedByVictim[victim.UserId] = self:GetReservedForVictim(victim.UserId) + amount
	raidCooldowns[key] = os.time() + cfg.TargetCooldownSeconds

	local record = {
		VictimUserId = victim.UserId,
		VictimName = victim.Name,
		Amount = amount,
		StartedAt = os.time(),
	}
	carried[thief] = record

	if not self:_attachFragment(thief, victim, record) then
		carried[thief] = nil
		self:_releaseReservation(record)
		return false
	end

	self:SetShield(victim, cfg.ShieldAfterTheftSeconds)
	Services.AnalyticsService:Custom(thief, "CoreFragmentStolen", amount)
	Services.NetworkService:Toast(thief, "ESCAPE! Get back to your island and bank the stolen Core!", "Rare")
	Services.NetworkService:BannerAll(
		"CORE THEFT!",
		thief.DisplayName .. " stole a fragment from " .. victim.DisplayName .. "!",
		4
	)
	Services.NetworkService:PushState(thief)
	Services.NetworkService:PushState(victim)
	return true
end

function RaidService:_restoreMovement(player, record)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and record and record.PreviousWalkSpeed then
		local profile = Services.DataService:GetProfile(player)
		local hoverboard = profile and profile.Entitlements and profile.Entitlements.Hoverboard
		humanoid.WalkSpeed = hoverboard and 24 or 16
	end
end

function RaidService:CancelCarry(thief, reason)
	local record = carried[thief]
	if not record then
		return false
	end

	carried[thief] = nil
	self:_releaseReservation(record)
	self:_removeFragment(record)
	self:_restoreMovement(thief, record)

	if thief.Parent == Players and reason == "died" then
		Services.NetworkService:Toast(thief, "You dropped the stolen fragment!", "Warning")
	end

	local victim = Players:GetPlayerByUserId(record.VictimUserId)
	if victim and victim.Parent == Players then
		Services.NetworkService:Toast(victim, "Your stolen Core fragment was recovered.", "Success")
		Services.NetworkService:PushState(victim)
	end
	if thief.Parent == Players then
		Services.NetworkService:PushState(thief)
	end
	return true
end

function RaidService:Recover(defender, thief)
	local record = carried[thief]
	if not record or record.VictimUserId ~= defender.UserId then
		return false
	end

	local profile = Services.DataService:GetProfile(defender)
	if profile then
		profile.Stats.RaidDefenses += 1
	end

	self:CancelCarry(thief, "recovered")
	Services.AnalyticsService:Custom(defender, "CoreRaidDefended", record.Amount)
	Services.NetworkService:BannerAll(
		"CORE RECOVERED!",
		defender.DisplayName .. " caught " .. thief.DisplayName .. " before they escaped!",
		4
	)
	return true
end

function RaidService:Deposit(thief)
	local record = carried[thief]
	if not record then
		Services.NetworkService:Toast(thief, "You are not carrying a stolen fragment.", "Warning")
		return false
	end
	if not Services.BaseService:IsNearDeposit(thief, 18) then
		return false
	end

	local victim = Players:GetPlayerByUserId(record.VictimUserId)
	local thiefProfile = Services.DataService:GetProfile(thief)
	local victimProfile = victim and Services.DataService:GetProfile(victim)
	if not thiefProfile or not victimProfile then
		self:CancelCarry(thief, "victim_left")
		Services.NetworkService:Toast(thief, "The target left the server. The raid was cancelled.", "Warning")
		return false
	end

	local amount = math.min(record.Amount, math.floor(victimProfile.CoreCharge))
	if amount <= 0 then
		self:CancelCarry(thief, "empty")
		return false
	end

	victimProfile.CoreCharge -= amount
	victimProfile.Stats.CoreFragmentsLost += 1
	thiefProfile.Stats.CoreFragmentsStolen += 1
	thiefProfile.CoreRaidScore += amount

	local payout = math.max(1, math.floor(amount * Services.GameConfig.Raid.Steal.BankMultiplier))

	carried[thief] = nil
	self:_releaseReservation(record)
	self:_removeFragment(record)
	self:_restoreMovement(thief, record)

	Services.EconomyService:AddEnergy(thief, payout, "CoreRaid")
	Services.AnalyticsService:Custom(thief, "CoreRaidBanked", payout)
	Services.BaseService:UpdateCoreVisual(victim)
	Services.NetworkService:PushState(victim)
	Services.NetworkService:PushState(thief)
	Services.NetworkService:Toast(thief, "+" .. formatNumber(payout) .. " Energy banked from the stolen Core!", "Rare")
	Services.NetworkService:Toast(victim, thief.DisplayName .. " escaped with part of your Core Charge.", "Warning")
	Services.NetworkService:BannerAll(
		"HEIST COMPLETE!",
		thief.DisplayName .. " escaped with " .. formatNumber(amount) .. " Core Charge!",
		5
	)
	return true
end

function RaidService:GetClientState(player)
	local record = carried[player]
	return {
		Carrying = record ~= nil,
		Amount = record and record.Amount or 0,
		VictimName = record and record.VictimName or nil,
		ShieldEndsAt = shieldUntil[player.UserId] or 0,
		Shielded = self:IsShielded(player),
	}
end

function RaidService:Start()
	Players.PlayerRemoving:Connect(function(player)
		if carried[player] then
			self:CancelCarry(player, "left")
		end

		local victimId = player.UserId
		local toCancel = {}
		for thief, record in pairs(carried) do
			if record.VictimUserId == victimId then
				table.insert(toCancel, thief)
			end
		end
		for _, thief in ipairs(toCancel) do
			self:CancelCarry(thief, "victim_left")
			if thief.Parent == Players then
				Services.NetworkService:Toast(thief, "The target left. Your stolen fragment vanished.", "Warning")
			end
		end

		shieldUntil[victimId] = nil
	end)
end

return RaidService
