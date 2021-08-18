
local modOverrides = {}

Ext.Require("Overrides/Fresnel__Base.lua")

local function SessionSetup()
	if isClient then
		if Mods.WeaponExpansion ~= nil and not modOverrides.WeaponExpansion then
			modOverrides.WeaponExpansion = Ext.Require("Overrides/Fresnel_WeaponExpansion.lua")
		end
	end
end

Ext.RegisterListener("SessionLoading", SessionSetup)
Ext.RegisterListener("SessionLoaded", SessionSetup)
SessionSetup()