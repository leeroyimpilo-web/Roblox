local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local getState = remotes:WaitForChild("GetPlayerState")
local stateChanged = remotes:WaitForChild("StateChanged")
local toastEvent = remotes:WaitForChild("Toast")

local gui = Instance.new("ScreenGui")
gui.Name = "PowerIslandsHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

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

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.fromScale(0.5, 0.025)
topBar.Size = UDim2.new(0.92, 0, 0, 74)
topBar.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
topBar.BackgroundTransparency = 0.08
topBar.Parent = gui
round(topBar, 18)
stroke(topBar)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = topBar

local function statCard(name, icon, accent)
	local card = Instance.new("Frame")
	card.Name = name .. "Card"
	card.Size = UDim2.new(0.31, 0, 0, 56)
	card.BackgroundColor3 = Color3.fromRGB(34, 43, 66)
	card.Parent = topBar
	round(card, 14)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 40, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = accent
	iconLabel.Parent = card

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Position = UDim2.new(0, 42, 0, 3)
	value.Size = UDim2.new(1, -47, 0.55, 0)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Font = Enum.Font.GothamBold
	value.TextScaled = true
	value.TextColor3 = Color3.new(1, 1, 1)
	value.Parent = card

	local caption = Instance.new("TextLabel")
	caption.Position = UDim2.new(0, 42, 0.58, 0)
	caption.Size = UDim2.new(1, -47, 0.27, 0)
	caption.BackgroundTransparency = 1
	caption.Text = name
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Font = Enum.Font.GothamMedium
	caption.TextScaled = true
	caption.TextColor3 = Color3.fromRGB(175, 187, 216)
	caption.Parent = card

	return value
end

local energyValue = statCard("Energy", "⚡", Color3.fromRGB(65, 225, 255))
local powerValue = statCard("Power", "✦", Color3.fromRGB(255, 188, 74))
local crystalsValue = statCard("Crystals", "◆", Color3.fromRGB(192, 116, 255))

local objective = Instance.new("Frame")
objective.AnchorPoint = Vector2.new(0.5, 1)
objective.Position = UDim2.new(0.5, 0, 0.96, 0)
objective.Size = UDim2.new(0.9, 0, 0, 82)
objective.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
objective.BackgroundTransparency = 0.08
objective.Parent = gui
round(objective, 18)
stroke(objective)

local objectiveTitle = Instance.new("TextLabel")
objectiveTitle.Position = UDim2.new(0, 16, 0, 10)
objectiveTitle.Size = UDim2.new(1, -32, 0, 24)
objectiveTitle.BackgroundTransparency = 1
objectiveTitle.Text = "NEXT GOAL"
objectiveTitle.TextXAlignment = Enum.TextXAlignment.Left
objectiveTitle.Font = Enum.Font.GothamBold
objectiveTitle.TextSize = 15
objectiveTitle.TextColor3 = Color3.fromRGB(95, 224, 255)
objectiveTitle.Parent = objective

local objectiveText = Instance.new("TextLabel")
objectiveText.Position = UDim2.new(0, 16, 0, 36)
objectiveText.Size = UDim2.new(1, -32, 0, 34)
objectiveText.BackgroundTransparency = 1
objectiveText.Text = "Collect Energy and upgrade your Power"
objectiveText.TextWrapped = true
objectiveText.TextXAlignment = Enum.TextXAlignment.Left
objectiveText.Font = Enum.Font.GothamMedium
objectiveText.TextSize = 17
objectiveText.TextColor3 = Color3.new(1, 1, 1)
objectiveText.Parent = objective

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.76)
toast.Size = UDim2.new(0.72, 0, 0, 48)
toast.BackgroundColor3 = Color3.fromRGB(30, 38, 58)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextColor3 = Color3.new(1, 1, 1)
toast.Parent = gui
round(toast, 14)

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

local function render(state)
	if not state then
		return
	end
	energyValue.Text = abbreviate(state.Energy)
	powerValue.Text = "x" .. abbreviate(state.Power)
	crystalsValue.Text = abbreviate(state.PowerCrystals)
	objectiveText.Text = string.format("Upgrade Power for %s Energy • Current x%s", abbreviate(state.NextPowerCost), abbreviate(state.Power))
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
	else
		toast.TextColor3 = Color3.new(1, 1, 1)
	end

	TweenService:Create(toast, TweenInfo.new(0.15), { BackgroundTransparency = 0.08, TextTransparency = 0 }):Play()
	task.delay(1.15, function()
		if toastToken == token then
			TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		end
	end)
end

stateChanged.OnClientEvent:Connect(render)
toastEvent.OnClientEvent:Connect(showToast)

for attempt = 1, 20 do
	local ok, state = pcall(function()
		return getState:InvokeServer()
	end)
	if ok and state then
		render(state)
		break
	end
	task.wait(0.25)
end

print(string.format("[Power Islands] Mobile HUD started for %s", player.Name))
