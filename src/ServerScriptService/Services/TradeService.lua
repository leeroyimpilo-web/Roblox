local Players = game:GetService("Players")

local TradeService = {}
local Services

local pending = {}
local sessions = {}

local function online(userId)
	return Players:GetPlayerByUserId(tonumber(userId) or -1)
end

local function findCompanion(profile, uid)
	for index, companion in ipairs(profile.Companions or {}) do
		if companion.Uid == uid then
			return index, companion
		end
	end
	return nil
end

local function removeEquipped(profile, uid)
	for index = #profile.EquippedCompanions, 1, -1 do
		if profile.EquippedCompanions[index] == uid then
			table.remove(profile.EquippedCompanions, index)
		end
	end
end

local function otherUser(session, userId)
	return session.A == userId and session.B or session.A
end

function TradeService:Init(services)
	Services = services
end

function TradeService:_session(player)
	return sessions[player.UserId]
end

function TradeService:GetClientState(player)
	local requestFrom = pending[player.UserId]
	local requester = requestFrom and online(requestFrom)
	local session = self:_session(player)

	if not session then
		return {
			Active = false,
			PendingFrom = requester and { UserId = requester.UserId, Name = requester.Name } or nil,
		}
	end

	local otherId = otherUser(session, player.UserId)
	local other = online(otherId)
	local yourOffer = session.Offers[player.UserId]
	local theirOffer = session.Offers[otherId]

	return {
		Active = true,
		OtherUserId = otherId,
		OtherName = other and other.Name or "Player",
		YourOffer = yourOffer,
		TheirOffer = theirOffer,
		YourConfirmed = session.Confirmed[player.UserId] == true,
		TheirConfirmed = session.Confirmed[otherId] == true,
	}
end

function TradeService:Request(player, targetUserId)
	local target = online(targetUserId)
	if not target or target == player or self:_session(player) or self:_session(target) then
		return false
	end
	pending[target.UserId] = player.UserId
	Services.NetworkService:Toast(target, player.Name .. " wants to trade companions.", "Rare")
	Services.NetworkService:PushState(target)
	return true
end

function TradeService:Accept(player)
	local requesterId = pending[player.UserId]
	local requester = requesterId and online(requesterId)
	if not requester or self:_session(player) or self:_session(requester) then
		pending[player.UserId] = nil
		return false
	end

	pending[player.UserId] = nil
	local session = {
		A = requester.UserId,
		B = player.UserId,
		Offers = {},
		Confirmed = {},
	}
	sessions[requester.UserId] = session
	sessions[player.UserId] = session
	Services.NetworkService:PushState(requester)
	Services.NetworkService:PushState(player)
	return true
end

function TradeService:Offer(player, uid)
	local session = self:_session(player)
	local profile = Services.DataService:GetProfile(player)
	if not session or type(uid) ~= "string" or not profile then
		return false
	end

	local _, companion = findCompanion(profile, uid)
	if not companion then
		return false
	end

	local definition
	for _, item in ipairs(Services.GameConfig.Companions.StarterEgg.Pool) do
		if item.Id == companion.Id then
			definition = item
			break
		end
	end

	session.Offers[player.UserId] = {
		Uid = companion.Uid,
		Id = companion.Id,
		Name = definition and definition.Name or companion.Id,
		Rarity = definition and definition.Rarity or "Unknown",
	}
	session.Confirmed[session.A] = false
	session.Confirmed[session.B] = false
	Services.NetworkService:PushState(online(session.A))
	Services.NetworkService:PushState(online(session.B))
	return true
end

function TradeService:_complete(session)
	local a = online(session.A)
	local b = online(session.B)
	if not a or not b then
		return false
	end

	local aProfile = Services.DataService:GetProfile(a)
	local bProfile = Services.DataService:GetProfile(b)
	local aOffer = session.Offers[session.A]
	local bOffer = session.Offers[session.B]
	if not aProfile or not bProfile or not aOffer or not bOffer then
		return false
	end

	local aIndex, aPet = findCompanion(aProfile, aOffer.Uid)
	local bIndex, bPet = findCompanion(bProfile, bOffer.Uid)
	if not aIndex or not bIndex then
		return false
	end

	removeEquipped(aProfile, aPet.Uid)
	removeEquipped(bProfile, bPet.Uid)
	table.remove(aProfile.Companions, aIndex)
	table.remove(bProfile.Companions, bIndex)
	table.insert(aProfile.Companions, bPet)
	table.insert(bProfile.Companions, aPet)

	if not Services.DataService:Save(a) or not Services.DataService:Save(b) then
		warn("[TradeService] Trade save reported a failure")
	end

	sessions[session.A] = nil
	sessions[session.B] = nil
	Services.AnalyticsService:Custom(a, "CompanionTradeCompleted", 1, aPet.Id)
	Services.AnalyticsService:Custom(b, "CompanionTradeCompleted", 1, bPet.Id)
	Services.NetworkService:Toast(a, "Trade complete with " .. b.Name .. ".", "Success")
	Services.NetworkService:Toast(b, "Trade complete with " .. a.Name .. ".", "Success")
	Services.NetworkService:PushState(a)
	Services.NetworkService:PushState(b)
	return true
end

function TradeService:Confirm(player)
	local session = self:_session(player)
	if not session or not session.Offers[session.A] or not session.Offers[session.B] then
		Services.NetworkService:Toast(player, "Both players must offer a companion first.", "Warning")
		return false
	end

	session.Confirmed[player.UserId] = true
	local other = online(otherUser(session, player.UserId))
	if other then
		Services.NetworkService:PushState(other)
	end
	Services.NetworkService:PushState(player)

	if session.Confirmed[session.A] and session.Confirmed[session.B] then
		return self:_complete(session)
	end
	return true
end

function TradeService:Cancel(player)
	local session = self:_session(player)
	if not session then
		return false
	end
	local other = online(otherUser(session, player.UserId))
	sessions[session.A] = nil
	sessions[session.B] = nil
	Services.NetworkService:Toast(player, "Trade cancelled.", "Info")
	if other then
		Services.NetworkService:Toast(other, "Trade cancelled.", "Info")
		Services.NetworkService:PushState(other)
	end
	Services.NetworkService:PushState(player)
	return true
end

function TradeService:Start()
	Players.PlayerRemoving:Connect(function(player)
		pending[player.UserId] = nil
		self:Cancel(player)
	end)
end

return TradeService
