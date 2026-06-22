local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local Maps = ServerStorage:WaitForChild("Maps")
local Map = workspace:FindFirstChild("Map") or Instance.new("Folder", workspace)

-- Helper: set Lighting properties from a config folder using a name->property Map
local function applyLightingConfig(configFolder)
	if not configFolder then return end

	-- Keys are Value object names inside your Configuration; values are the Lighting property names.
	local Map = {
		Ambient                    = "Ambient",
		OutdoorAmbient             = "OutdoorAmbient",
		ExposureCompensation       = "ExposureCompensation",
		ClockTime                  = "ClockTime",
		Colorshift_Top             = "ColorShift_Top",
		Brightness                 = "Brightness",
		GeographicLatitude         = "GeographicLatitude",
		Colorshift_Bottom          = "ColorShift_Bottom",

		-- Handle common misspellings coming from content packs
		EnviromentDiffuseScale     = "EnvironmentDiffuseScale",
		EnviromentSpecularScale    = "EnvironmentSpecularScale",

		EnvironmentDiffuseScale    = "EnvironmentDiffuseScale",
		EnvironmentSpecularScale   = "EnvironmentSpecularScale",

		ShadowSoftness             = "ShadowSoftness",
		GlobalShadows              = "GlobalShadows",
		FogColor                   = "FogColor",
		FogStart                   = "FogStart",
		FogEnd                     = "FogEnd",
	}

	for valueName, lightingProp in pairs(Map) do
		local v = configFolder:FindFirstChild(valueName)
		if v and v:IsA("ValueBase") then
			Lighting[lightingProp] = v.Value
		end
	end
end

return function(MapName, includeClouds, includeTerrain)
	local src = Maps:FindFirstChild(MapName)
	if not src then
		warn("Map: " .. tostring(MapName) .. " does not exist!")
		return
	end

	-- Clear current Map container
	Map:ClearAllChildren()
	Lighting:ClearAllChildren()

	-- Work on a clone so ServerStorage stays pristine
	for _, child in ipairs(src:GetChildren()) do
		local clone = child:Clone()
		clone.Parent = Map
	end

	-- Reset any Clouds
	for _, child in ipairs(workspace.Terrain:GetChildren()) do
		if child:IsA("Clouds") then child:Destroy() end
	end
	if includeClouds == true then
		Instance.new("Clouds", workspace.Terrain)
	end

	-- Paste saved TerrainRegion (if present)
	if includeTerrain == true then
		local terrainFolder = Map:FindFirstChild("Terrain")
		local region = terrainFolder and terrainFolder:FindFirstChildOfClass("TerrainRegion")
		if region then
			workspace.Terrain:PasteRegion(region, workspace.Terrain.MaxExtents.Min, true)
		else
			warn("No terrain found or terrain could not be loaded.")
		end
	end

	-- Lighting: copy post-processing + apply scalar settings from Configuration
	local lightingConfig = Map:FindFirstChild("LightingConfig")
	if lightingConfig then
		-- Move any non-Configuration children (e.g., Atmosphere, BloomEffect, etc.) into Lighting
		for _, inst in ipairs(lightingConfig:GetChildren()) do
			if inst.Name ~= "Configuration" then
				inst.Parent = Lighting
			end
		end

		-- Apply numeric/color/bool settings from the Configuration values
		applyLightingConfig(lightingConfig:FindFirstChild("Configuration"))
	end
end