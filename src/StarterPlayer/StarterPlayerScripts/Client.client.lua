local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getState = remotes:WaitForChild("GetPlayerState")
local stateChanged = remotes:WaitForChild("StateChanged")
local toastEvent = remotes:WaitForChild("Toast")
local actionEvent = remotes:WaitForChild("Action")
local eventBanner = remotes:WaitForChild("EventBanner")

local currentState
local currentPanel
local followerParts = {}
local followerSignature = ""
local hoverboard

local successSound = Instance.new("Sound")
successSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
successSound.Volume = 0.35
successSound.Parent = SoundService

local buttonSound = Instance.new("Sound")
buttonSound.SoundId = "rbxasset://sounds/button.wav"
buttonSound.Volume = 0.25
buttonSound.Parent = SoundService

local gui = Instance.new("ScreenGui")
gui.Name = "PowerIslandsHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local uiScale = Instance.new("UIScale")
uiScale.Parent = gui

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	uiScale.Scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 650), 0.72, 1.15)
end
updateScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local function round(frame, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = frame
end

local function stroke(frame, transparency)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1.5
	uiStroke.Transparency = transparency or 0.65
	uiStroke.Color = Color3.new(1, 1, 1)
	uiStroke.Parent = frame
end

local function abbreviate(number)
	number = tonumber(number) or 0
	if number >= 1e9 then
		return string.format("%.1fB", number / 1e9)
	elseif number >= 1e6 then
		return string.format("%.1fM", number / 1e6)
	elseif number >= 1e3 then
		return string.format("%.1fK", number / 1e3)
	end
	return tostring(math.floor(number))
end

local topBar = Instance.new("Frame")
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.fromScale(0.5, 0.02)
topBar.Size = UDim2.new(0, 820, 0, 72)
topBar.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
topBar.BackgroundTransparency = 0.06
topBar.Parent = gui
round(topBar, 18)
stroke(topBar)

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.Padding = UDim.new(0, 8)
topLayout.Parent = topBar

local function statCard(name, icon, accent)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(195, 56)
	card.BackgroundColor3 = Color3.fromRGB(34, 43, 66)
	card.Parent = topBar
	round(card, 14)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.fromOffset(42, 56)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = accent
	iconLabel.Parent = card

	local value = Instance.new("TextLabel")
	value.Position = UDim2.fromOffset(45, 3)
	value.Size = UDim2.new(1, -50, 0, 30)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Font = Enum.Font.GothamBold
	value.TextScaled = true
	value.TextColor3 = Color3.new(1, 1, 1)
	value.Parent = card

	local caption = Instance.new("TextLabel")
	caption.Position = UDim2.fromOffset(45, 35)
	caption.Size = UDim2.new(1, -50, 0, 15)
	caption.BackgroundTransparency = 1
	caption.Text = name
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Font = Enum.Font.GothamMedium
	caption.TextScaled = true
	caption.TextColor3 = Color3.fromRGB(175, 187, 216)
	caption.Parent = card

	return value
end

local energyValue = statCard("ENERGY", "E", Color3.fromRGB(65, 225, 255))
local powerValue = statCard("POWER", "P", Color3.fromRGB(255, 188, 74))
local crystalsValue = statCard("CRYSTALS", "C", Color3.fromRGB(192, 116, 255))
local petsValue = statCard("PETS", "*", Color3.fromRGB(126, 255, 164))

local status = Instance.new("Frame")
status.Position = UDim2.fromOffset(18, 110)
status.Size = UDim2.fromOffset(270, 208)
status.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
status.BackgroundTransparency = 0.07
status.Parent = gui
round(status, 18)
stroke(status)

local statusTitle = Instance.new("TextLabel")
statusTitle.Position = UDim2.fromOffset(14, 10)
statusTitle.Size = UDim2.new(1, -28, 0, 26)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "POWER ISLANDS"
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextSize = 18
statusTitle.TextColor3 = Color3.fromRGB(95, 224, 255)
statusTitle.Parent = status

local statusText = Instance.new("TextLabel")
statusText.Position = UDim2.fromOffset(14, 43)
statusText.Size = UDim2.new(1, -28, 1, -53)
statusText.BackgroundTransparency = 1
statusText.Text = "Loading..."
statusText.TextWrapped = true
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Font = Enum.Font.GothamMedium
statusText.TextSize = 15
statusText.TextColor3 = Color3.fromRGB(225, 232, 249)
statusText.Parent = status

local menu = Instance.new("Frame")
menu.AnchorPoint = Vector2.new(1, 0.5)
menu.Position = UDim2.new(1, -18, 0.52, 0)
menu.Size = UDim2.fromOffset(150, 390)
menu.BackgroundTransparency = 1
menu.Parent = gui

local menuLayout = Instance.new("UIListLayout")
menuLayout.Padding = UDim.new(0, 8)
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.Parent = menu

local modal = Instance.new("Frame")
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.Size = UDim2.fromOffset(510, 430)
modal.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
modal.Visible = false
modal.ZIndex = 20
modal.Parent = gui
round(modal, 20)
stroke(modal, 0.35)

local modalTitle = Instance.new("TextLabel")
modalTitle.Position = UDim2.fromOffset(20, 12)
modalTitle.Size = UDim2.new(1, -80, 0, 40)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "MENU"
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.Font = Enum.Font.GothamBold
modalTitle.TextSize = 24
modalTitle.TextColor3 = Color3.new(1, 1, 1)
modalTitle.ZIndex = 21
modalTitle.Parent = modal

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -14, 0, 12)
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.BackgroundColor3 = Color3.fromRGB(55, 65, 88)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.ZIndex = 22
closeButton.Parent = modal
round(closeButton, 12)

local modalBody = Instance.new("ScrollingFrame")
modalBody.Position = UDim2.fromOffset(18, 62)
modalBody.Size = UDim2.new(1, -36, 1, -78)
modalBody.BackgroundTransparency = 1
modalBody.BorderSizePixel = 0
modalBody.ScrollBarThickness = 5
modalBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
modalBody.CanvasSize = UDim2.new()
modalBody.ZIndex = 21
modalBody.Parent = modal

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 8)
bodyLayout.Parent = modalBody

local objective = Instance.new("Frame")
objective.AnchorPoint = Vector2.new(0.5, 1)
objective.Position = UDim2.new(0.5, 0, 1, -18)
objective.Size = UDim2.fromOffset(760, 84)
objective.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
objective.BackgroundTransparency = 0.06
objective.Parent = gui
round(objective, 18)
stroke(objective)

local objectiveTitle = Instance.new("TextLabel")
objectiveTitle.Position = UDim2.fromOffset(16, 8)
objectiveTitle.Size = UDim2.new(1, -32, 0, 20)
objectiveTitle.BackgroundTransparency = 1
objectiveTitle.Text = "NEXT GOAL"
objectiveTitle.TextXAlignment = Enum.TextXAlignment.Left
objectiveTitle.Font = Enum.Font.GothamBold
objectiveTitle.TextSize = 14
objectiveTitle.TextColor3 = Color3.fromRGB(95, 224, 255)
objectiveTitle.Parent = objective

local objectiveText = Instance.new("TextLabel")
objectiveText.Position = UDim2.fromOffset(16, 30)
objectiveText.Size = UDim2.new(1, -32, 0, 46)
objectiveText.BackgroundTransparency = 1
objectiveText.Text = "Collect Energy and grow stronger."
objectiveText.TextWrapped = true
objectiveText.TextXAlignment = Enum.TextXAlignment.Left
objectiveText.Font = Enum.Font.GothamMedium
objectiveText.TextSize = 16
objectiveText.TextColor3 = Color3.new(1, 1, 1)
objectiveText.Parent = objective

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.77)
toast.Size = UDim2.fromOffset(500, 50)
toast.BackgroundColor3 = Color3.fromRGB(30, 38, 58)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextColor3 = Color3.new(1, 1, 1)
toast.ZIndex = 30
toast.Parent = gui
round(toast, 14)

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, -120)
banner.Size = UDim2.fromOffset(560, 92)
banner.BackgroundColor3 = Color3.fromRGB(35, 29, 65)
banner.ZIndex = 40
banner.Parent = gui
round(banner, 20)
stroke(banner, 0.3)

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Size = UDim2.new(1, 0, 0.55, 0)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Text = "LIVE EVENT"
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextSize = 26
bannerTitle.TextColor3 = Color3.fromRGB(219, 162, 255)
bannerTitle.ZIndex = 41
bannerTitle.Parent = banner

local bannerSub = Instance.new("TextLabel")
bannerSub.Position = UDim2.new(0, 0, 0.53, 0)
bannerSub.Size = UDim2.new(1, 0, 0.35, 0)
bannerSub.BackgroundTransparency = 1
bannerSub.Text = ""
bannerSub.Font = Enum.Font.GothamMedium
bannerSub.TextSize = 16
bannerSub.TextColor3 = Color3.new(1, 1, 1)
bannerSub.ZIndex = 41
bannerSub.Parent = banner

local function clearBody()
	for _, child in ipairs(modalBody:GetChildren()) do
		if child ~= bodyLayout then
			child:Destroy()
		end
	end
end

local function addText(text, accent)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 0, 46)
	label.BackgroundColor3 = Color3.fromRGB(31, 39, 60)
	label.BackgroundTransparency = 0.25
	label.Text = text
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.TextColor3 = accent or Color3.fromRGB(225, 232, 249)
	label.ZIndex = 22
	label.Parent = modalBody
	round(label, 12)
	return label
end

local function addButton(text, callback, accent)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -8, 0, 48)
	button.BackgroundColor3 = accent or Color3.fromRGB(48, 66, 99)
	button.Text = text
	button.TextWrapped = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.ZIndex = 22
	button.Parent = modalBody
	round(button, 12)
	button.Activated:Connect(callback)
	return button
end

local function addMenuButton(name, label)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(150, 54)
	button.BackgroundColor3 = Color3.fromRGB(34, 43, 66)
	button.Text = label
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = menu
	round(button, 14)
	stroke(button, 0.78)
	return button
end

local renderPanel

local function openPanel(name)
	buttonSound:Play()
	currentPanel = name
	modal.Visible = true
	if renderPanel then
		renderPanel(name)
	end
end

closeButton.Activated:Connect(function()
	modal.Visible = false
	currentPanel = nil
end)

addMenuButton("Pets", "PETS"):Activated:Connect(function() openPanel("Pets") end)
addMenuButton("Daily", "DAILY"):Activated:Connect(function() openPanel("Daily") end)
addMenuButton("Shop", "SHOP"):Activated:Connect(function() openPanel("Shop") end)
addMenuButton("Codes", "CODES"):Activated:Connect(function() openPanel("Codes") end)
addMenuButton("Achievements", "AWARDS"):Activated:Connect(function() openPanel("Achievements") end)\naddMenuButton("Social", "SOCIAL"):Activated:Connect(function() openPanel("Social") end)

renderPanel = function(name)
	if not currentState then
		return
	end
	clearBody()

	if name == "Pets" then
		modalTitle.Text = "COMPANIONS"
		local pets = currentState.Companions
		addText(string.format("Equipped %s/%s • Total boost x%.2f", pets.EquippedCount, pets.MaxEquipped, pets.Multiplier), Color3.fromRGB(126, 255, 164))
		if #pets.Owned == 0 then
			addText("Hatch your first companion at the Starter Egg.")
		end
		for _, pet in ipairs(pets.Owned) do
			local uid = pet.Uid
			local marker = pet.Equipped and "[EQUIPPED] " or ""
			addButton(
				string.format("%s%s • %s • x%.2f", marker, pet.Name, pet.Rarity, pet.Multiplier),
				function()
					actionEvent:FireServer("ToggleCompanion", uid)
				end,
				pet.Equipped and Color3.fromRGB(45, 111, 78) or Color3.fromRGB(48, 66, 99)
			)
		end
	elseif name == "Daily" then
		modalTitle.Text = "DAILY REWARDS"
		local daily = currentState.Daily
		addText(string.format("Current streak: %s days", daily.Streak))
		addText(string.format("Next reward: %s Energy + %s Crystals", abbreviate(daily.Energy), daily.Crystals), Color3.fromRGB(255, 213, 111))
		addButton(
			daily.CanClaim and "CLAIM TODAY'S REWARD" or "ALREADY CLAIMED TODAY",
			function()
				if daily.CanClaim then
					actionEvent:FireServer("ClaimDaily")
				end
			end,
			daily.CanClaim and Color3.fromRGB(44, 133, 77) or Color3.fromRGB(65, 70, 82)
		)
	elseif name == "Shop" then
		modalTitle.Text = "POWER SHOP"
		addText("Permanent passes", Color3.fromRGB(219, 162, 255))
		local passDescriptions = {
			VIP = "VIP • +20% Energy",
			DoubleEnergy = "Double Energy • x2 rewards",
			ExtraCompanionSlots = "Extra Pet Slots • +2 equipped",
			Hoverboard = "Hoverboard • cosmetic/movement entitlement",
		}
		for _, passName in ipairs({ "VIP", "DoubleEnergy", "ExtraCompanionSlots", "Hoverboard" }) do
			local data = currentState.Monetization.Passes[passName]
			local text = passDescriptions[passName]
			if data.Owned then
				text ..= " • OWNED"
			elseif not data.Configured then
				text ..= " • SET ID"
			end
			addButton(text, function()
				actionEvent:FireServer("PromptPass", passName)
			end, data.Owned and Color3.fromRGB(47, 116, 78) or Color3.fromRGB(83, 55, 116))
		end

		addText("Repeatable products", Color3.fromRGB(95, 224, 255))
		for _, productName in ipairs({ "Energy5K", "Energy50K", "ServerBoost", "InstantRebirth" }) do
			local labels = {
				Energy5K = "5,000 Energy",
				Energy50K = "50,000 Energy",
				ServerBoost = "10-minute server x2 Energy boost",
				InstantRebirth = "Instant Rebirth",
			}
			local data = currentState.Monetization.Products[productName]
			local text = labels[productName] .. (data.Configured and "" or " • SET ID")
			addButton(text, function()
				actionEvent:FireServer("PromptProduct", productName)
			end)
		end
		if currentState.Monetization.SubscriptionConfigured then
			addButton(
				currentState.Monetization.SubscriptionOwned and "VIP CLUB SUBSCRIPTION • ACTIVE" or "VIP CLUB SUBSCRIPTION • +10% ENERGY",
				function()
					actionEvent:FireServer("PromptSubscription")
				end,
				Color3.fromRGB(116, 76, 136)
			)
		else
			addText("VIP Club subscription • SET SUBSCRIPTION ID", Color3.fromRGB(180, 160, 196))
		end
	elseif name == "Codes" then
		modalTitle.Text = "PROMO CODES"
		addText("Enter an official Power Islands code.")

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -8, 0, 54)
		box.BackgroundColor3 = Color3.fromRGB(31, 39, 60)
		box.PlaceholderText = "ENTER CODE"
		box.Text = ""
		box.ClearTextOnFocus = false
		box.Font = Enum.Font.GothamBold
		box.TextSize = 18
		box.TextColor3 = Color3.new(1, 1, 1)
		box.PlaceholderColor3 = Color3.fromRGB(142, 151, 174)
		box.ZIndex = 22
		box.Parent = modalBody
		round(box, 12)

		addButton("REDEEM", function()
			actionEvent:FireServer("RedeemCode", box.Text)
		end, Color3.fromRGB(54, 112, 153))

		addText("Launch codes: LAUNCH • JUNGLE • POWERUP", Color3.fromRGB(126, 255, 164))
	elseif name == "Social" then
		modalTitle.Text = "SOCIAL HUB"
		local party = currentState.Party
		local trade = currentState.Trade

		if party.PendingInviteFrom then
			addText("Party invite from " .. party.PendingInviteFrom.Name, Color3.fromRGB(219, 162, 255))
			addButton("ACCEPT PARTY INVITE", function()
				actionEvent:FireServer("PartyAccept")
			end, Color3.fromRGB(47, 116, 78))
		end

		if party.InParty then
			addText(string.format("Party boost x%.2f • %s members", party.Multiplier, #party.Members), Color3.fromRGB(126, 255, 164))
			for _, member in ipairs(party.Members) do
				if member.UserId ~= player.UserId then
					addButton("GIFT 100 ENERGY TO " .. member.Name, function()
						actionEvent:FireServer("GiftEnergy", { UserId = member.UserId, Amount = 100 })
					end, Color3.fromRGB(54, 112, 153))
				end
			end
			addButton("LEAVE PARTY", function()
				actionEvent:FireServer("PartyLeave")
			end, Color3.fromRGB(110, 57, 63))
		else
			addText("Create a party for up to +20% Energy from co-play.")
		end

		if trade.PendingFrom then
			addText("Trade request from " .. trade.PendingFrom.Name, Color3.fromRGB(255, 213, 111))
			addButton("ACCEPT TRADE", function()
				actionEvent:FireServer("TradeAccept")
			end, Color3.fromRGB(47, 116, 78))
		end

		if trade.Active then
			addText("Trading with " .. trade.OtherName, Color3.fromRGB(255, 213, 111))
			addText("Your offer: " .. (trade.YourOffer and trade.YourOffer.Name or "None"))
			addText("Their offer: " .. (trade.TheirOffer and trade.TheirOffer.Name or "None"))
			for _, pet in ipairs(currentState.Companions.Owned) do
				local uid = pet.Uid
				addButton("OFFER " .. pet.Name .. " [" .. pet.Rarity .. "]", function()
					actionEvent:FireServer("TradeOffer", uid)
				end)
			end
			addButton(
				trade.YourConfirmed and "WAITING FOR OTHER PLAYER..." or "CONFIRM TRADE",
				function()
					if not trade.YourConfirmed then
						actionEvent:FireServer("TradeConfirm")
					end
				end,
				Color3.fromRGB(47, 116, 78)
			)
			addButton("CANCEL TRADE", function()
				actionEvent:FireServer("TradeCancel")
			end, Color3.fromRGB(110, 57, 63))
		else
			addText("Players in this server", Color3.fromRGB(95, 224, 255))
			if #currentState.ServerPlayers == 0 then
				addText("No other players are in this server yet.")
			end
			for _, other in ipairs(currentState.ServerPlayers) do
				local userId = other.UserId
				addButton("PARTY INVITE • " .. other.Name, function()
					actionEvent:FireServer("PartyInvite", userId)
				end, Color3.fromRGB(47, 91, 78))
				addButton("TRADE REQUEST • " .. other.Name, function()
					actionEvent:FireServer("TradeRequest", userId)
				end, Color3.fromRGB(83, 55, 116))
			end
		end
	elseif name == "Achievements" then
		modalTitle.Text = "ACHIEVEMENTS"
		for _, achievement in ipairs(currentState.Achievements) do
			local marker = achievement.Completed and "[DONE] " or ""
			addText(
				string.format("%s%s • %s • +%s Crystals", marker, achievement.Name, achievement.Description, achievement.RewardCrystals),
				achievement.Completed and Color3.fromRGB(126, 255, 164) or nil
			)
		end
	end
end

local rarityColors = {
	Common = Color3.fromRGB(200, 210, 220),
	Rare = Color3.fromRGB(75, 165, 255),
	Epic = Color3.fromRGB(187, 91, 255),
	Legendary = Color3.fromRGB(255, 187, 71),
	Mythic = Color3.fromRGB(255, 77, 153),
}

local function clearFollowers()
	for _, part in ipairs(followerParts) do
		part:Destroy()
	end
	followerParts = {}
end

local function rebuildFollowers(companions)
	local equipped = {}
	for _, pet in ipairs(companions.Owned or {}) do
		if pet.Equipped then
			table.insert(equipped, pet)
		end
	end

	local sig = ""
	for _, pet in ipairs(equipped) do
		sig ..= pet.Uid
	end
	if sig == followerSignature then
		return
	end
	followerSignature = sig
	clearFollowers()

	for _, pet in ipairs(equipped) do
		local part = Instance.new("Part")
		part.Name = "LocalPet_" .. pet.Id
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2.5, 2.5, 2.5)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Material = Enum.Material.Neon
		part.Color = rarityColors[pet.Rarity] or Color3.new(1, 1, 1)
		part.Parent = workspace

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(130, 36)
		bb.StudsOffset = Vector3.new(0, 2.4, 0)
		bb.AlwaysOnTop = true
		bb.Parent = part

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = pet.Name
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = part.Color
		label.Parent = bb

		table.insert(followerParts, part)
	end
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if hoverboard then
		hoverboard.CFrame = root.CFrame * CFrame.new(0, -2.7, 0)
	end

	for index, part in ipairs(followerParts) do
		local side = (index - (#followerParts + 1) / 2) * 3
		local bob = math.sin(os.clock() * 3 + index) * 0.35
		local target = root.CFrame * CFrame.new(side, 1.7 + bob, 4.5 + math.abs(side) * 0.15)
		part.CFrame = part.CFrame:Lerp(CFrame.new(target.Position), 0.18)
	end
end)

local function updateHoverboard(state)
	local owned = state.Monetization
		and state.Monetization.Passes
		and state.Monetization.Passes.Hoverboard
		and state.Monetization.Passes.Hoverboard.Owned

	if owned and not hoverboard then
		hoverboard = Instance.new("Part")
		hoverboard.Name = "LocalHoverboard"
		hoverboard.Size = Vector3.new(4.8, 0.35, 2.2)
		hoverboard.Anchored = true
		hoverboard.CanCollide = false
		hoverboard.CanTouch = false
		hoverboard.CanQuery = false
		hoverboard.Material = Enum.Material.Neon
		hoverboard.Color = Color3.fromRGB(90, 215, 255)
		hoverboard.Parent = workspace
	elseif not owned and hoverboard then
		hoverboard:Destroy()
		hoverboard = nil
	end
end

local function render(state)
	if not state then
		return
	end
	currentState = state
	updateHoverboard(state)

	energyValue.Text = abbreviate(state.Energy)
	powerValue.Text = "x" .. abbreviate(state.Power)
	crystalsValue.Text = abbreviate(state.PowerCrystals)
	petsValue.Text = string.format("%s/%s", state.Companions.EquippedCount, state.Companions.MaxEquipped)

	local eventLine = state.Event.Active
		and string.format("%s x%.1f", state.Event.Name, state.Event.EnergyMultiplier)
		or "No live event"
	local bossLine = state.Boss.Alive
		and string.format("%s: %s/%s HP", state.Boss.Name, state.Boss.Health, state.Boss.MaxHealth)
		or "Jungle Titan respawning"
	local worldLine = string.format("Worlds: %s/%s", state.Worlds.UnlockedCount, state.Worlds.Total)
	local socialLine = string.format("Friends: %s • x%.2f bonus", state.Social.FriendsInServer, state.Social.Multiplier)
	local partyLine = string.format("Party boost x%.2f", state.Party.Multiplier)
	local boostLine = string.format("Pet boost x%.2f • Crystal x%.2f", state.Companions.Multiplier, state.Rebirth.CrystalMultiplier)

	statusText.Text = table.concat({
		worldLine,
		socialLine,
		partyLine,
		boostLine,
		eventLine,
		bossLine,
	}, "\n")

	if state.Worlds.NextId then
		objectiveText.Text = string.format(
			"Next world: %s for %s Energy • Power upgrade: %s Energy",
			state.Worlds.NextName,
			abbreviate(state.Worlds.NextCost),
			abbreviate(state.NextPowerCost)
		)
	else
		objectiveText.Text = string.format(
			"All worlds unlocked • Rebirth needs %s Energy + Power %s • Reward %s Crystals",
			abbreviate(state.Rebirth.RequiredEnergy),
			state.Rebirth.RequiredPower,
			state.Rebirth.RewardCrystals
		)
	end

	rebuildFollowers(state.Companions)

	if modal.Visible and currentPanel then
		renderPanel(currentPanel)
	end
end

local toastToken = 0
local function showToast(message, tone)
	toastToken += 1
	local token = toastToken
	toast.Text = message

	if tone == "Success" then
		toast.TextColor3 = Color3.fromRGB(126, 255, 164)
	elseif tone == "Warning" then
		toast.TextColor3 = Color3.fromRGB(255, 199, 93)
	elseif tone == "Energy" then
		toast.TextColor3 = Color3.fromRGB(85, 225, 255)
	elseif tone == "Rare" then
		toast.TextColor3 = Color3.fromRGB(224, 151, 255)
	else
		toast.TextColor3 = Color3.new(1, 1, 1)
	end

	if tone == "Success" or tone == "Rare" or tone == "Energy" then
		successSound:Play()
	end
	TweenService:Create(toast, TweenInfo.new(0.15), { BackgroundTransparency = 0.08, TextTransparency = 0 }):Play()
	task.delay(1.4, function()
		if toastToken == token then
			TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		end
	end)
end

local bannerToken = 0
local function showBanner(title, subtitle, duration)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerSub.Text = subtitle
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0, 90),
	}):Play()

	task.delay(duration or 4, function()
		if token == bannerToken then
			TweenService:Create(banner, TweenInfo.new(0.3), {
				Position = UDim2.new(0.5, 0, 0, -120),
			}):Play()
		end
	end)
end

stateChanged.OnClientEvent:Connect(render)
toastEvent.OnClientEvent:Connect(showToast)
eventBanner.OnClientEvent:Connect(showBanner)

for _ = 1, 30 do
	local ok, state = pcall(function()
		return getState:InvokeServer()
	end)
	if ok and state then
		render(state)
		break
	end
	task.wait(0.25)
end

print(string.format("[Power Islands] Full mobile client started for %s", player.Name))
