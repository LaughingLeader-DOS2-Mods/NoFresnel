local isClient = Ext.IsClient()

---@return ModSettings
function GetSettings()
	if Mods.LeaderLib then
		return Mods.LeaderLib.SettingsManager.GetMod(ModuleUUID, false)
	end
end

---@class OptionalOverride
---@field Enable function
---@field Disable function


---@type OptionalOverride
local playerLight = Ext.Require("Overrides/PlayerLight.lua")

local modOverrides = {}

if isClient then
	Ext.Require("Overrides/Fresnel__Base.lua")
end

local function OnSettingsLoaded()
	local settings = GetSettings()
	if settings then
		if settings.Global:FlagEquals("LLMATERIAL_DisablePlayerLight", true) then
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

local registeredListeners = false
local function SessionSetup()
	if not registeredListeners then
		if Mods.LeaderLib then
			Mods.LeaderLib.RegisterListener("ModSettingsLoaded", OnSettingsLoaded)
			Mods.LeaderLib.RegisterListener("ModSettingsChanged", "LLMATERIAL_DisablePlayerLight", OnPlayerLightChanged)
			registeredListeners = true
		end
	end
	if isClient then
		if Mods.WeaponExpansion ~= nil and not modOverrides.WeaponExpansion then
			modOverrides.WeaponExpansion = Ext.Require("Overrides/Fresnel_WeaponExpansion.lua")
		end
	end
end

Ext.RegisterListener("SessionLoading", SessionSetup)
Ext.RegisterListener("SessionLoaded", SessionSetup)
SessionSetup()