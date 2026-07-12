--!strict
-- Manual Studio helper for source Config iteration.
-- Edit source, Apply for runtime testing, Save to keep it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")

local PLUGIN_ID = "ConfigHotReloadPlugin_v4"
local CONFIG_REVISION_ATTRIBUTE = "DevConfigRevision"
local CONFIG_UPDATED_AT_ATTRIBUTE = "DevConfigUpdatedAt"
local POLL_SECONDS = 0.2

type Target = {
	Key: string,
	Name: string,
	SourceRoot: () -> Instance?,
	SourcePath: { string },
	RuntimeRoot: () -> Instance?,
	RuntimePath: { string },
	RuntimeApplies: () -> boolean,
}

local function isRuntime(): boolean
	return RunService:IsRunning() and (RunService:IsServer() or RunService:IsClient())
end

local Targets: { Target } = {
	{
		Key = "WeaponConfig",
		Name = "Weapon",
		SourceRoot = function()
			return ReplicatedStorage
		end,
		SourcePath = { "Assets", "Weapons", "Data", "Config" },
		RuntimeRoot = function()
			return ReplicatedStorage
		end,
		RuntimePath = { "Assets", "Weapons", "Data", "Config" },
		RuntimeApplies = function()
			return isRuntime()
		end,
	},

	{
		Key = "MovementConfig",
		Name = "Movement",
		SourceRoot = function()
			return StarterPlayer
		end,
		SourcePath = { "StarterPlayerScripts", "Movement", "Data", "Config"},
		RuntimeRoot = function()
			local player = Players.LocalPlayer
			return player and player:FindFirstChild("PlayerScripts") or nil
		end,
		RuntimePath = { "Movement", "Data", "Config" },
		RuntimeApplies = function()
			return RunService:IsRunning() and RunService:IsClient()
		end,
	},
}

local SETTING_NAMES = {
	ApplySource = "ApplySource",
	ApplyVersion = "ApplyVersion",
	SavedSource = "SavedSource",
	SnapshotRequest = "SnapshotRequest",
	OpenRequest = "OpenRequest",
	ApplyRequest = "ApplyRequest",
	SaveRequest = "SaveRequest",
	RestoreRequest = "RestoreRequest",
}

local toolbar = plugin:CreateToolbar("Balance")

local widget = plugin:CreateDockWidgetPluginGui(
	PLUGIN_ID,
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 360, 190, 300, 160)
)
widget.Title = "Config"
widget.Enabled = false

local function new(className: string, props: { [string]: any }, parent: Instance?): Instance
	local object = Instance.new(className)
	for key, value in props do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

local root = new("Frame", {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	BorderSizePixel = 0,
}, widget)

new("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, root)

new("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
}, root)

local statusLabel = new("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(235, 235, 235),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	Font = Enum.Font.SourceSans,
	TextSize = 16,
	TextWrapped = true,
	Text = "Status: loading Config",
	Size = UDim2.new(1, 0, 0, 70),
}, root) :: TextLabel

local function button(text: string): TextButton
	return new("TextButton", {
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		BorderSizePixel = 0,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.SourceSansBold,
		TextSize = 16,
		Text = text,
		Size = UDim2.new(1, 0, 0, 32),
		AutoButtonColor = true,
	}, root) :: TextButton
end

local applyButton = button("Apply Changes")
local saveButton = button("Save Changes")

local activeTarget: Target = Targets[1] :: Target
local seen: { [string]: { [string]: string? } } = {}

local function status(target: Target, text: string)
	statusLabel.Text = ("Status: %s %s"):format(target.Name, text)
end

local function setting(target: Target, name: string): string
	return ("%s%s_v4"):format(target.Key, name)
end

local function nextVersion(): string
	return ("%d:%.6f:%d"):format(os.time(), os.clock(), math.random(1, 1000000000))
end

local function getSetting(target: Target, name: string): string?
	local ok, value = pcall(function()
		return plugin:GetSetting(setting(target, name))
	end)
	return if ok and typeof(value) == "string" and value ~= "" then value else nil
end

local function setSetting(target: Target, name: string, value: string)
	pcall(function()
		plugin:SetSetting(setting(target, name), value)
	end)
end

local function poke(target: Target, name: string)
	setSetting(target, name, nextVersion())
end

local function findModule(root: Instance?, path: { string }): ModuleScript?
	local current: Instance? = root
	for _, name in path do
		current = current and current:FindFirstChild(name) or nil
	end
	return if current and current:IsA("ModuleScript") then current else nil
end

local function getSourceConfig(target: Target): ModuleScript?
	return findModule(target.SourceRoot(), target.SourcePath)
end

local function getRuntimeConfig(target: Target): ModuleScript?
	if not target.RuntimeApplies() then
		return nil
	end
	return findModule(target.RuntimeRoot(), target.RuntimePath)
end

local function readSource(scriptObject: ModuleScript): string?
	local ok, source = pcall(function()
		return ScriptEditorService:GetEditorSource(scriptObject)
	end)
	if ok and typeof(source) == "string" then
		return source
	end

	ok, source = pcall(function()
		return scriptObject.Source
	end)
	return if ok and typeof(source) == "string" then source else nil
end

local function writeSource(scriptObject: ModuleScript, source: string): boolean
	local ok = pcall(function()
		ScriptEditorService:UpdateSourceAsync(scriptObject, function()
			return source
		end)
	end)
	return ok
end

local function targetSeen(target: Target): { [string]: string? }
	if not seen[target.Key] then
		seen[target.Key] = {}
	end
	return seen[target.Key]
end

local function consumeRequest(target: Target, name: string): boolean
	local value = getSetting(target, name)
	if not value or value == targetSeen(target)[name] then
		return false
	end

	targetSeen(target)[name] = value
	return true
end

local function selectTarget(target: Target, showWidget: boolean?)
	activeTarget = target
	widget.Title = target.Name .. " Config"
	if showWidget then
		widget.Enabled = true
	end
end

local function saveSourceSnapshot(target: Target, message: string?)
	local config = getSourceConfig(target)
	local source = config and readSource(config) or nil
	if not source then
		status(target, "source not ready")
		return
	end

	setSetting(target, SETTING_NAMES.SavedSource, source)
	if message then
		status(target, ("%s (%d bytes)"):format(message, #source))
	end
end

local function publishRuntimeSource(target: Target, source: string)
	local version = nextVersion()
	targetSeen(target)[SETTING_NAMES.ApplyVersion] = version
	setSetting(target, SETTING_NAMES.ApplySource, source)
	setSetting(target, SETTING_NAMES.ApplyVersion, version)
end

local function bumpRuntimeRevision(target: Target, config: ModuleScript, message: string)
	local revision = (tonumber(config:GetAttribute(CONFIG_REVISION_ATTRIBUTE)) or 0) + 1
	config:SetAttribute(CONFIG_REVISION_ATTRIBUTE, revision)
	config:SetAttribute(CONFIG_UPDATED_AT_ATTRIBUTE, os.time())
	status(target, ("%s; revision %d"):format(message, revision))
end

local function applyRuntimeSource(target: Target, source: string): boolean
	local config = getRuntimeConfig(target)
	if config and writeSource(config, source) then
		bumpRuntimeRevision(target, config, "applied source draft to runtime")
		return true
	end
	return false
end

local function openSourceConfig(target: Target)
	local config = getSourceConfig(target)
	if not config then
		status(target, "source not found")
		return
	end

	selectTarget(target, true)
	Selection:Set({ config })
	ScriptEditorService:OpenScriptDocumentAsync(config, {})
	status(target, "source opened")
end

local function applyFromSource(target: Target)
	local config = getSourceConfig(target)
	local source = config and readSource(config) or nil
	if not source then
		status(target, "source not ready")
		return
	end

	publishRuntimeSource(target, source)
	status(target, "runtime apply published")
end

local function saveFromSource(target: Target)
	local config = getSourceConfig(target)
	local source = config and readSource(config) or nil
	if not config or not source then
		status(target, "source not ready")
		return
	end

	setSetting(target, SETTING_NAMES.SavedSource, source)
	writeSource(config, source)
	status(target, ("source saved (%d bytes)"):format(#source))
end

local function restoreSavedSource(target: Target)
	local config = getSourceConfig(target)
	local source = getSetting(target, SETTING_NAMES.SavedSource)
	local currentSource = config and readSource(config) or nil

	if not config or not source or not currentSource then
		status(target, "source not ready")
		return
	end

	if currentSource == source then
		status(target, "source already restored")
	elseif writeSource(config, source) then
		status(target, "source restored")
	end
end

local function handleOpen(target: Target)
	selectTarget(target, true)
	if isRuntime() then
		poke(target, SETTING_NAMES.OpenRequest)
		status(target, "source open requested")
	else
		openSourceConfig(target)
	end
end

local function handleApply(target: Target)
	if isRuntime() then
		poke(target, SETTING_NAMES.ApplyRequest)
		status(target, "source apply requested")
	else
		applyFromSource(target)
	end
end

local function handleSave(target: Target)
	if isRuntime() then
		poke(target, SETTING_NAMES.SaveRequest)
		status(target, "source save requested")
	else
		saveFromSource(target)
	end
end

for _, target in Targets do
	seen[target.Key] = {
		[SETTING_NAMES.ApplyVersion] = getSetting(target, SETTING_NAMES.ApplyVersion),
		[SETTING_NAMES.SnapshotRequest] = getSetting(target, SETTING_NAMES.SnapshotRequest),
		[SETTING_NAMES.OpenRequest] = getSetting(target, SETTING_NAMES.OpenRequest),
		[SETTING_NAMES.ApplyRequest] = getSetting(target, SETTING_NAMES.ApplyRequest),
		[SETTING_NAMES.SaveRequest] = getSetting(target, SETTING_NAMES.SaveRequest),
		[SETTING_NAMES.RestoreRequest] = getSetting(target, SETTING_NAMES.RestoreRequest),
	}

	local toolbarButton = toolbar:CreateButton(target.Name .. " Config", "Open source " .. target.Name .. " Config", "")
	toolbarButton.ClickableWhenViewportHidden = true
	toolbarButton.Click:Connect(function()
		handleOpen(target)
	end)
end

if isRuntime() then
	for _, target in Targets do
		poke(target, SETTING_NAMES.SnapshotRequest)
	end

	plugin.Unloading:Connect(function()
		for _, target in Targets do
			poke(target, SETTING_NAMES.RestoreRequest)
		end
	end)
else
	for _, target in Targets do
		saveSourceSnapshot(target, "source baseline saved")
	end
end

selectTarget(activeTarget, false)
applyButton.MouseButton1Click:Connect(function()
	handleApply(activeTarget)
end)
saveButton.MouseButton1Click:Connect(function()
	handleSave(activeTarget)
end)

task.spawn(function()
	while true do
		if isRuntime() then
			for _, target in Targets do
				if target.RuntimeApplies() then
					local applyVersion = getSetting(target, SETTING_NAMES.ApplyVersion)
					if applyVersion and applyVersion ~= targetSeen(target)[SETTING_NAMES.ApplyVersion] then
						local source = getSetting(target, SETTING_NAMES.ApplySource)
						if source and applyRuntimeSource(target, source) then
							targetSeen(target)[SETTING_NAMES.ApplyVersion] = applyVersion
						end
					end
				end
			end
		else
			for _, target in Targets do
				if consumeRequest(target, SETTING_NAMES.SnapshotRequest) then
					saveSourceSnapshot(target, "source baseline saved")
				end

				if consumeRequest(target, SETTING_NAMES.OpenRequest) then
					openSourceConfig(target)
				end

				if consumeRequest(target, SETTING_NAMES.ApplyRequest) then
					applyFromSource(target)
				end

				if consumeRequest(target, SETTING_NAMES.SaveRequest) then
					saveFromSource(target)
				end

				if consumeRequest(target, SETTING_NAMES.RestoreRequest) then
					restoreSavedSource(target)
				end
			end
		end

		task.wait(POLL_SECONDS)
	end
end)
