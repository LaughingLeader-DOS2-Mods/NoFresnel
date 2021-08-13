Ext.Require("BootstrapShared.lua")
Ext.Require("Client/Overrides/Fresnel.lua")

---@class OptionalOverride
---@field Enable function
---@field Disable function

---@type OptionalOverride
local playerLight = Ext.Require("Client/Overrides/PlayerLight.lua")

local Settings = {
	DisablePlayerLight = true,
}

local function OnSettingsLoaded()
	local settings = GetSettings()
	if settings then
		if settings:FlagEquals("LLMATERIAL_DisablePlayerLight", true) then
			playerLight.Enable()
		else
			playerLight.Disable()
		end
	end
end

local function OnPlayerLightChanged(id, b, data, settings)
	if b then
		playerLight.Enable()
	else
		playerLight.Disable()
	end
end

Ext.RegisterListener("ModuleLoading", function()
	if Mods.LeaderLib then
		Mods.LeaderLib.RegisterListener("ModSettingsLoaded", OnSettingsLoaded)
		Mods.LeaderLib.RegisterListener("ModSettingsChanged", "LLMATERIAL_DisablePlayerLight", OnPlayerLightChanged)
	end
end)

Ext.RegisterListener("SessionLoaded", function()


end)