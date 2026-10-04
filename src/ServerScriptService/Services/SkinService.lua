local Players = game:GetService("Players")

local SkinService = {}

local Services

function SkinService:Init(services)
	Services = services
end

function SkinService:RefreshUnlocks(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	profile.UnlockedCoreSkins = profile.UnlockedCoreSkins or { Default = true }
	profile.UnlockedCoreSkins.Default = true

	if (profile.CoreLevel or 1) >= 5 then
		profile.UnlockedCoreSkins.Solar = true
	end
	if profile.Stats.CoreFragmentsStolen >= 5 then
		profile.UnlockedCoreSkins.Toxic = true
	end
	if (profile.CoreLevel or 1) >= 20 then
		profile.UnlockedCoreSkins.Void = true
	end
	if (profile.CoreLevel or 1) >= 50 then
		profile.UnlockedCoreSkins.Galaxy = true
	end

	if not profile.UnlockedCoreSkins[profile.CoreSkin or "Default"] then
		profile.CoreSkin = "Default"
	end
	return true
end

function SkinService:SetSkin(player, skinId)
	if type(skinId) ~= "string" or #skinId > 24 then
		return false
	end

	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return false
	end

	self:RefreshUnlocks(player)
	local skin = Services.GameConfig.GetCoreSkin(skinId)
	if not skin or skin.Id ~= skinId or not profile.UnlockedCoreSkins[skinId] then
		Services.NetworkService:Toast(player, "That Core skin is still locked.", "Warning")
		return false
	end

	profile.CoreSkin = skinId
	Services.BaseService:UpdateCoreVisual(player)
	Services.NetworkService:PushState(player)
	Services.NetworkService:Toast(player, skin.Name .. " equipped!", "Success")
	return true
end

function SkinService:GetClientState(player)
	local profile = Services.DataService:GetProfile(player)
	if not profile then
		return nil
	end
	self:RefreshUnlocks(player)

	local skins = {}
	for _, skin in ipairs(Services.GameConfig.Raid.CoreSkins) do
		table.insert(skins, {
			Id = skin.Id,
			Name = skin.Name,
			Requirement = skin.Requirement,
			Unlocked = profile.UnlockedCoreSkins[skin.Id] == true,
			Equipped = profile.CoreSkin == skin.Id,
		})
	end

	return {
		Selected = profile.CoreSkin or "Default",
		Skins = skins,
	}
end

function SkinService:Start()
	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			self:RefreshUnlocks(player)
			Services.BaseService:UpdateCoreVisual(player)
		end)
	end)
end

return SkinService
