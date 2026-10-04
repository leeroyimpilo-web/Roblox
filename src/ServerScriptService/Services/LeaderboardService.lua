local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local LeaderboardService = {}

local Services
local allTimeStore
local weeklyStore
local currentWeekKey
local weeklyTop = {}
local globalTop = {}
local nameCache = {}
local weeklyBoardLabel
local serverBoardLabel

local function getWeekKey()
	return os.date("!%Y-%W", os.time())
end

local function getName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = ok and name or ("User " .. tostring(userId))
	return nameCache[userId]
end

local function normalizePage(page)
	local result = {}
	for rank, item in ipairs(page or {}) do
		local userId = tonumber(item.key)
		if userId then
			table.insert(result, {
				Rank = rank,
				UserId = userId,
				Name = getName(userId),
				Score = tonumber(item.value) or 0,
			})
		end
	end
	return result
end

function LeaderboardService:Init(services)
	Services = services
	currentWeekKey = getWeekKey()
	allTimeStore = DataStoreService:GetOrderedDataStore("PowerIslands_AllTimeRaid_v1")
	weeklyStore = DataStoreService:GetOrderedDataStore("PowerIslands_WeeklyRaid_v1_" .. currentWeekKey)
end

function LeaderboardService:_ensureWeek(profile)
	local weekKey = getWeekKey()
	if weekKey ~= currentWeekKey then
		currentWeekKey = weekKey
		weeklyStore = DataStoreService:GetOrderedDataStore("PowerIslands_WeeklyRaid_v1_" .. currentWeekKey)
		weeklyTop = {}
	end

	if profile.WeeklyRaidKey ~= currentWeekKey then
		profile.WeeklyRaidKey = currentWeekKey
		profile.WeeklyRaidScore = 0
	end
end

function LeaderboardService:AddWeeklyScore(player, points)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	self:_ensureWeek(profile)
	points = math.max(1, math.floor(tonumber(points) or 1))
	profile.WeeklyRaidScore += points

	task.spawn(function()
		pcall(function()
			weeklyStore:SetAsync(tostring(player.UserId), profile.WeeklyRaidScore)
		end)
	end)

	Services.NetworkService:PushState(player)
	return true
end

function LeaderboardService:SyncAllTime(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return
	end

	task.spawn(function()
		pcall(function()
			allTimeStore:SetAsync(tostring(player.UserId), math.floor(profile.CoreRaidScore or 0))
		end)
	end)
end

function LeaderboardService:_refreshStore(store)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, Services.GameConfig.Raid.Leaderboard.TopCount)
	end)
	if not ok or not pages then
		return nil
	end

	local okPage, page = pcall(function()
		return pages:GetCurrentPage()
	end)
	if not okPage then
		return nil
	end
	return normalizePage(page)
end

local function formatRows(title, rows, scoreLabel)
	local lines = { title }
	if #rows == 0 then
		table.insert(lines, "Waiting for scores...")
	else
		for index, row in ipairs(rows) do
			table.insert(lines, string.format(
				"%s. %s  •  %s %s",
				index,
				row.Name,
				math.floor(row.Score or 0),
				scoreLabel or "PTS"
			))
		end
	end
	return table.concat(lines, "\n")
end

function LeaderboardService:_createBoards()
	local arena = workspace:WaitForChild("CoreRaidArena", 15)
	if not arena then
		return
	end

	local function board(name, offset, title)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.new(28, 18, 1)
		part.CFrame = CFrame.new(Services.GameConfig.Raid.ArenaCenter + offset)
		part.Anchored = true
		part.Material = Enum.Material.Metal
		part.Color = Color3.fromRGB(24, 30, 46)
		part.Parent = arena

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = part

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(18, 23, 38)
		label.Text = title
		label.TextWrapped = true
		label.TextScaled = false
		label.TextSize = 20
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.Parent = gui
		return label
	end

	weeklyBoardLabel = board(
		"WeeklyRaidBoard",
		Vector3.new(-34, 11, 35),
		"WEEKLY RAID CHAMPIONSHIP"
	)
	serverBoardLabel = board(
		"ServerRaidBoard",
		Vector3.new(34, 11, 35),
		"SERVER RAID LEADERS"
	)
end

function LeaderboardService:_updateBoards()
	if weeklyBoardLabel then
		weeklyBoardLabel.Text = formatRows("WEEKLY RAID CHAMPIONSHIP", weeklyTop, "PTS")
	end
	if serverBoardLabel then
		serverBoardLabel.Text = formatRows("SERVER RAID LEADERS", self:GetServerTop(), "RAID")
	end
end

function LeaderboardService:Refresh()
	local weekly = self:_refreshStore(weeklyStore)
	if weekly then
		weeklyTop = weekly
	end

	local global = self:_refreshStore(allTimeStore)
	if global then
		globalTop = global
	end

	self:_updateBoards()

	if Services.NetworkService then
		Services.NetworkService:PushAll()
	end
end

function LeaderboardService:GetServerTop()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Services.DataService:GetProfile(player)
		if profile then
			table.insert(rows, {
				UserId = player.UserId,
				Name = player.DisplayName,
				Score = math.floor(profile.CoreRaidScore or 0),
				CoreLevel = profile.CoreLevel or 1,
				Charge = math.floor(profile.CoreCharge or 0),
			})
		end
	end

	table.sort(rows, function(a, b)
		if a.Score == b.Score then
			return a.CoreLevel > b.CoreLevel
		end
		return a.Score > b.Score
	end)

	local max = math.min(#rows, Services.GameConfig.Raid.Leaderboard.TopCount)
	local top = {}
	for index = 1, max do
		rows[index].Rank = index
		table.insert(top, rows[index])
	end
	return top
end

function LeaderboardService:GetRichestServerCores()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Services.DataService:GetProfile(player)
		if profile then
			table.insert(rows, {
				UserId = player.UserId,
				Name = player.DisplayName,
				CoreLevel = profile.CoreLevel or 1,
				Charge = math.floor(profile.CoreCharge or 0),
			})
		end
	end

	table.sort(rows, function(a, b)
		if a.CoreLevel == b.CoreLevel then
			return a.Charge > b.Charge
		end
		return a.CoreLevel > b.CoreLevel
	end)

	local top = {}
	for index = 1, math.min(#rows, 5) do
		rows[index].Rank = index
		table.insert(top, rows[index])
	end
	return top
end

function LeaderboardService:GetClientState(player)
	local profile = Services.DataService:GetProfile(player)
	if profile then
		self:_ensureWeek(profile)
	end

	return {
		WeekKey = currentWeekKey,
		YourWeeklyScore = profile and profile.WeeklyRaidScore or 0,
		YourAllTimeScore = profile and profile.CoreRaidScore or 0,
		Server = self:GetServerTop(),
		RichestCores = self:GetRichestServerCores(),
		Weekly = weeklyTop,
		Global = globalTop,
	}
end

function LeaderboardService:Start()
	self:_createBoards()
	self:_updateBoards()

	task.spawn(function()
		task.wait(5)
		while true do
			self:Refresh()
			task.wait(Services.GameConfig.Raid.Leaderboard.RefreshSeconds)
		end
	end)
end

return LeaderboardService
