local LiveEventService = {}

local NetworkService
local AnalyticsService
local GameConfig
local currentEvent
local eventToken = 0
local random = Random.new()

local function findEvent(id)
	for _, event in ipairs(GameConfig.LiveEvents.Pool) do
		if event.Id == id then
			return event
		end
	end
	return nil
end

function LiveEventService:Init(services)
	NetworkService = services.NetworkService
	AnalyticsService = services.AnalyticsService
	GameConfig = services.GameConfig
end

function LiveEventService:GetEnergyMultiplier()
	return currentEvent and currentEvent.EnergyMultiplier or 1
end

function LiveEventService:GetCoreMultiplier()
	return currentEvent and currentEvent.CoreMultiplier or 1
end

function LiveEventService:GetClientState()
	if not currentEvent then
		return {
			Active = false,
			Name = "No live event",
			EnergyMultiplier = 1,
			CoreMultiplier = 1,
			EndsAt = 0,
		}
	end

	return {
		Active = true,
		Id = currentEvent.Id,
		Name = currentEvent.Name,
		EnergyMultiplier = currentEvent.EnergyMultiplier,
		CoreMultiplier = currentEvent.CoreMultiplier,
		EndsAt = currentEvent.EndsAt,
	}
end

function LiveEventService:Activate(eventId, duration)
	local definition = findEvent(eventId)
	if not definition then
		return false
	end

	eventToken += 1
	local token = eventToken
	duration = math.max(30, math.floor(duration or GameConfig.LiveEvents.DurationSeconds))

	currentEvent = {
		Id = definition.Id,
		Name = definition.Name,
		EnergyMultiplier = definition.EnergyMultiplier or 1,
		CoreMultiplier = definition.CoreMultiplier or 1,
		EndsAt = os.time() + duration,
	}

	local subtitle
	if (definition.CoreMultiplier or 1) > 1 and (definition.EnergyMultiplier or 1) <= 1 then
		subtitle = string.format("All Power Cores generate x%.1f faster!", definition.CoreMultiplier)
	elseif (definition.CoreMultiplier or 1) > 1 then
		subtitle = string.format("Energy x%.1f • Core generation x%.1f!", definition.EnergyMultiplier, definition.CoreMultiplier)
	else
		subtitle = string.format("Energy rewards x%.1f!", definition.EnergyMultiplier)
	end
	NetworkService:BannerAll(definition.Name, subtitle, 5)
	NetworkService:PushAll()

	task.delay(duration, function()
		if token ~= eventToken then
			return
		end
		currentEvent = nil
		NetworkService:ToastAll("The live event has ended.", "Info")
		NetworkService:PushAll()
	end)

	return true
end

function LiveEventService:Start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.LiveEvents.IntervalSeconds)
			local pool = GameConfig.LiveEvents.Pool
			local chosen = pool[random:NextInteger(1, #pool)]
			self:Activate(chosen.Id, GameConfig.LiveEvents.DurationSeconds)
		end
	end)
end

return LiveEventService
