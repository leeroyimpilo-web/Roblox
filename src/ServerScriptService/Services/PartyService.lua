local Players = game:GetService("Players")

local PartyService = {}
local Services

local parties = {}
local playerParty = {}
local pendingInvites = {}

local function online(userId)
	return Players:GetPlayerByUserId(tonumber(userId) or -1)
end

local function partyMembers(party)
	local result = {}
	for userId in pairs(party.Members) do
		local player = online(userId)
		if player then
			table.insert(result, { UserId = userId, Name = player.Name })
		end
	end
	table.sort(result, function(a, b)
		return a.Name < b.Name
	end)
	return result
end

function PartyService:Init(services)
	Services = services
end

function PartyService:_makeParty(player)
	local party = {
		LeaderId = player.UserId,
		Members = { [player.UserId] = true },
	}
	parties[player.UserId] = party
	playerParty[player.UserId] = player.UserId
	return party
end

function PartyService:_getParty(player)
	local leaderId = playerParty[player.UserId]
	return leaderId and parties[leaderId] or nil
end

function PartyService:GetMultiplier(player)
	local party = self:_getParty(player)
	if not party then
		return 1
	end
	local count = 0
	for _ in pairs(party.Members) do
		count += 1
	end
	return 1 + math.min(math.max(0, count - 1) * 0.05, 0.20)
end

function PartyService:GetClientState(player)
	local party = self:_getParty(player)
	local inviteFrom = pendingInvites[player.UserId]
	local inviter = inviteFrom and online(inviteFrom)

	return {
		InParty = party ~= nil,
		LeaderId = party and party.LeaderId or nil,
		Members = party and partyMembers(party) or {},
		Multiplier = self:GetMultiplier(player),
		PendingInviteFrom = inviter and { UserId = inviter.UserId, Name = inviter.Name } or nil,
	}
end

function PartyService:Invite(player, targetUserId)
	local target = online(targetUserId)
	if not target or target == player then
		return false
	end
	if playerParty[target.UserId] then
		Services.NetworkService:Toast(player, target.Name .. " is already in a party.", "Warning")
		return false
	end

	local party = self:_getParty(player) or self:_makeParty(player)
	pendingInvites[target.UserId] = party.LeaderId
	Services.NetworkService:Toast(target, player.Name .. " invited you to a party.", "Rare")
	Services.NetworkService:PushState(target)
	Services.NetworkService:PushState(player)
	return true
end

function PartyService:Accept(player)
	local leaderId = pendingInvites[player.UserId]
	local party = leaderId and parties[leaderId]
	if not party or playerParty[player.UserId] then
		pendingInvites[player.UserId] = nil
		return false
	end

	pendingInvites[player.UserId] = nil
	party.Members[player.UserId] = true
	playerParty[player.UserId] = leaderId
	Services.NetworkService:ToastAll(player.Name .. " joined a party.", "Info")
	Services.NetworkService:PushAll()
	return true
end

function PartyService:Leave(player)
	local leaderId = playerParty[player.UserId]
	local party = leaderId and parties[leaderId]
	if not party then
		return false
	end

	party.Members[player.UserId] = nil
	playerParty[player.UserId] = nil

	if party.LeaderId == player.UserId then
		local newLeader
		for userId in pairs(party.Members) do
			newLeader = userId
			break
		end

		parties[leaderId] = nil
		if newLeader then
			party.LeaderId = newLeader
			parties[newLeader] = party
			for userId in pairs(party.Members) do
				playerParty[userId] = newLeader
			end
		end
	end

	Services.NetworkService:PushAll()
	return true
end

function PartyService:GiftEnergy(player, targetUserId, amount)
	local target = online(targetUserId)
	amount = math.clamp(math.floor(tonumber(amount) or 0), 100, 1_000)
	if not target or target == player then
		return false
	end

	local party = self:_getParty(player)
	if not party or not party.Members[target.UserId] then
		Services.NetworkService:Toast(player, "Energy gifts are limited to your party.", "Warning")
		return false
	end

	if not Services.SecurityService:Allow(player, "GiftEnergy", 5) then
		return false
	end

	if not Services.EconomyService:SpendEnergy(player, amount, "PlayerGift") then
		Services.NetworkService:Toast(player, "Not enough Energy to gift.", "Warning")
		return false
	end

	Services.EconomyService:AddEnergy(target, amount, "PlayerGift")
	Services.AnalyticsService:Custom(player, "EnergyGiftSent", amount, "Party")
	Services.NetworkService:Toast(player, "Gift sent to " .. target.Name .. ".", "Success")
	Services.NetworkService:Toast(target, player.Name .. " gifted you " .. amount .. " Energy!", "Success")
	return true
end

function PartyService:Start()
	Players.PlayerRemoving:Connect(function(player)
		pendingInvites[player.UserId] = nil
		self:Leave(player)
	end)
end

return PartyService
