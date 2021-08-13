local function Enable()
	Ext.Print("[MaterialTweaks] Disabling player light.")
	Ext.AddPathOverride("Public/MaterialTweaks_0c56bb29-a167-4136-a89b-44e0525a0139/RootTemplates/Player_Light_3faa1c66-5d35-4e87-868e-d124168b660f.lsf", "Public/MaterialTweaks_0c56bb29-a167-4136-a89b-44e0525a0139/Overrides_Manual/Player_Light_Disabled_3faa1c66-5d35-4e87-868e-d124168b660f.lsf")
end

local function Disable()
	Ext.Print("[MaterialTweaks] Re-enabling player light.")
	Ext.AddPathOverride("Public/MaterialTweaks_0c56bb29-a167-4136-a89b-44e0525a0139/RootTemplates/Player_Light_3faa1c66-5d35-4e87-868e-d124168b660f.lsf", "Public/MaterialTweaks_0c56bb29-a167-4136-a89b-44e0525a0139/RootTemplates/Player_Light_3faa1c66-5d35-4e87-868e-d124168b660f.lsf")
end

return {
	Enable = Enable,
	Disable = Disable
}