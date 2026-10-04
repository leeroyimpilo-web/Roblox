local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}

local profiles = {}
local store
local GameConfig
local NetworkService

local SESSION_TIMEOUT_SECONDS = 180
local LOAD_RETRIES = 5
local OFFLINE_CAP_SECONDS = 4 * 60 * 60
local OFFLINE_RATE_MULTIPLIER = 0.25
local SESSION_ID = game.JobId ~= "" and game.JobId or ("studio-" .. tostring(os.time()))

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

local function isForeignSessionActive(saved)
	if RunService:IsStudio() then
		return false
	end

	local session = type(saved) == "table" and saved._Session or nil
	if not session or not session.JobId or session.JobId == "" or session.JobId == SESSION_ID then
		return false
	end

	return os.time() - (tonumber(session.LastSeen) or 0) < SESSION_TIMEOUT_SECONDS
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

function DataService:_applyOfflineProgress(profile)
	local now = os.time()
	local lastSeen = tonumber(profile.LastSeen) or 0
	profile.LastSeen = now

	if lastSeen <= 0 or now <= lastSeen then
		return 0
	end

	local offlineSeconds = math.clamp(now - lastSeen, 0, OFFLINE_CAP_SECONDS)
	if offlineSeconds < 30 then
		return 0
	end

	local rate = GameConfig.GetCoreRate(profile.CoreLevel)
	local gain = math.floor(rate * offlineSeconds * OFFLINE_RATE_MULTIPLIER)
	local capacity = GameConfig.GetCoreCapacity(profile.CoreLevel)
	local before = tonumber(profile.CoreCharge) or 0
	profile.CoreCharge = math.min(capacity, before + gain)
	return math.max(0, math.floor(profile.CoreCharge - before))
end

function DataService:Load(player)
	if profiles[player] then
		return profiles[player]
	end

	local key = "player_" .. player.UserId
	local loadedProfile
	local acquired = false

	for attempt = 1, LOAD_RETRIES do
		acquired = false
		local ok, result = pcall(function()
			return store:UpdateAsync(key, function(saved)
				saved = type(saved) == "table" and saved or deepCopy(GameConfig.DefaultProfile)
				reconcile(saved, GameConfig.DefaultProfile)

				if isForeignSessionActive(saved) then
					return nil
				end

				saved._Session = {
					JobId = SESSION_ID,
					LastSeen = os.time(),
				}
				acquired = true
				return saved
			end)
		end)

		if ok and acquired and type(result) == "table" then
			loadedProfile = result
			break
		end

		if player.Parent ~= Players then
			return nil
		end
		task.wait(math.min(2 * attempt, 6))
	end

	if not loadedProfile then
		if RunService:IsStudio() then
			loadedProfile = deepCopy(GameConfig.DefaultProfile)
			loadedProfile._Session = {
				JobId = SESSION_ID,
				LastSeen = os.time(),
			}
			warn("[DataService] Studio fallback profile created for", player.UserId)
		else
			player:Kick("Your Power Islands data is active in another server or could not be loaded safely. Please rejoin in a moment.")
			return nil
		end
	end

	reconcile(loadedProfile, GameConfig.DefaultProfile)
	local offlineGain = self:_applyOfflineProgress(loadedProfile)
	loadedProfile._Session = {
		JobId = SESSION_ID,
		LastSeen = os.time(),
	}

	profiles[player] = loadedProfile

	if offlineGain > 0 and NetworkService then
		task.delay(2, function()
			if player.Parent == Players and profiles[player] then
				NetworkService:Toast(
					player,
					"Your Power Core generated +" .. offlineGain .. " Charge while you were away!",
					"Rare"
				)
				NetworkService:PushState(player)
			end
		end)
	end

	return loadedProfile
end

function DataService:Save(player, releaseSession)
	local profile = profiles[player]
	if not profile then
		return true
	end

	local now = os.time()
	profile.LastSeen = now

	local snapshot = deepCopy(profile)
	snapshot._Session = {
		JobId = releaseSession and "" or SESSION_ID,
		LastSeen = now,
	}

	local key = "player_" .. player.UserId
	local wrote = false

	local ok, err = pcall(function()
		store:UpdateAsync(key, function(current)
			if isForeignSessionActive(current) then
				return nil
			end
			wrote = true
			return snapshot
		end)
	end)

	if not ok or not wrote then
		warn("[DataService] Failed to save", player.UserId, err or "session ownership rejected")
		return false
	end

	profile._Session = snapshot._Session
	return true
end

function DataService:Release(player)
	self:Save(player, true)
	profiles[player] = nil
end

function DataService:Start()
	local function onPlayerAdded(player)
		local profile = self:Load(player)
		if profile and NetworkService then
			NetworkService:PushState(player)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)

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
					self:Save(player, false)
				end)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			for _, profile in pairs(profiles) do
				profile.PlaytimeSeconds += 1
				if profile._Session then
					profile._Session.LastSeen = os.time()
				end
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:Save(player, true)
		end
	end)
end

return DataService
