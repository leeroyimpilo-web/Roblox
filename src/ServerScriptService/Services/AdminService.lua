local Players = game:GetService("Players")

local AdminService = {}
local Services
local allowed = {}

local function splitWords(message)
	local result = {}
	for word in string.gmatch(message, "%S+") do
		table.insert(result, word)
	end
	return result
end

function AdminService:Init(services)
	Services = services
	for _, userId in ipairs(Services.GameConfig.AdminUserIds) do
		allowed[userId] = true
	end
end

function AdminService:IsAdmin(player)
	return allowed[player.UserId] == true
end

function AdminService:_execute(player, message)
	if not self:IsAdmin(player) or string.sub(message, 1, 1) ~= "/" then
		return
	end

	local args = splitWords(message)
	local command = string.lower(args[1] or "")

	if command == "/event" then
		local id = args[2] or "PowerSurge"
		if Services.LiveEventService:Activate(id, tonumber(args[3]) or 300) then
			Services.NetworkService:Toast(player, "Event started: " .. id, "Success")
		else
			Services.NetworkService:Toast(player, "Unknown event ID.", "Warning")
		end
	elseif command == "/giveenergy" then
		local amount = math.clamp(math.floor(tonumber(args[2]) or 0), 1, 10_000_000)
		Services.EconomyService:AddEnergy(player, amount, "AdminGrant")
	elseif command == "/announce" then
		local text = string.match(message, "^/announce%s+(.+)$")
		if text and #text <= 120 then
			Services.NetworkService:BannerAll("ANNOUNCEMENT", text, 6)
		end
	elseif command == "/boss" then
		Services.BossService:ForceRespawn()
	elseif command == "/megacore" then
		Services.MegaCoreService:Activate(tonumber(args[2]) or Services.GameConfig.Raid.MegaCore.DurationSeconds)
	elseif command == "/meltdown" then
		Services.LiveEventService:Activate("CoreMeltdown", tonumber(args[2]) or 180)
	elseif command == "/rebirth" then
		Services.RebirthService:Rebirth(player, true)
	end
end

function AdminService:_attach(player)
	player.Chatted:Connect(function(message)
		self:_execute(player, message)
	end)
end

function AdminService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:_attach(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_attach(player)
	end
end

return AdminService
