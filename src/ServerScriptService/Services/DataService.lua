local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataService = {}

local profiles = {}
local store
local GameConfig
local NetworkService

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in pairs(value) do
		copy[key] = deepCopy(child)
	end
	return copy
end

local function reconcile(target, template)
	for key, defaultValue in pairs(template) do
		if target[key] == nil then
			target[key] = deepCopy(defaultValue)
		elseif type(defaultValue) == "table" and type(target[key]) == "table" then
			reconcile(target[key], defaultValue)
		end
	end
end

function DataService:Init(services)
	GameConfig = services.GameConfig
	NetworkService = services.NetworkService
	store = DataStoreService:GetDataStore("PowerIslands_PlayerData_v" .. GameConfig.DataVersion)
end

function DataService:GetProfile(player)
	return profiles[player]
end

function DataService:IsLoaded(player)
	return profiles[player] ~= nil
end

function DataService:Load(player)
	if profiles[player] then
		return profiles[player]
	end

	local key = "player_" .. player.UserId
	local profile = deepCopy(GameConfig.DefaultProfile)

	local ok, saved = pcall(function()
		return store:GetAsync(key)
	end)

	if ok and type(saved) == "table" then
		reconcile(saved, GameConfig.DefaultProfile)
		profile = saved
	elseif not ok then
		warn("[DataService] Failed to load", player.UserId, saved)
	end

	profiles[player] = profile
	return profile
end

function DataService:Save(player)
	local profile = profiles[player]
	if not profile then
		return true
	end

	local snapshot = deepCopy(profile)
	local key = "player_" .. player.UserId
	local ok, err = pcall(function()
		store:UpdateAsync(key, function()
			return snapshot
		end)
	end)

	if not ok then
		warn("[DataService] Failed to save", player.UserId, err)
	end
	return ok
end

function DataService:Release(player)
	self:Save(player)
	profiles[player] = nil
end

function DataService:Start()
	local function onPlayerAdded(player)
		self:Load(player)
		if NetworkService then
			NetworkService:PushState(player)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		self:Release(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while task.wait(GameConfig.AutoSaveSeconds) do
			for player in pairs(profiles) do
				task.spawn(function()
					self:Save(player)
				end)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			for _, profile in pairs(profiles) do
				profile.PlaytimeSeconds += 1
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:Save(player)
		end
	end)
end

return DataService
