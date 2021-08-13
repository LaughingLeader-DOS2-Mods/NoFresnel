---@return ModSettings
function GetSettings()
	if Mods.LeaderLib then
		return Mods.LeaderLib.SettingsManager.GetMod(ModuleUUID, false)
	end
end