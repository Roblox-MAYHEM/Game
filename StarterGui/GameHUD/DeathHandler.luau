local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Client = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer
local UI = Player:WaitForChild("PlayerGui")

local Fusion = require(Client.Packages.Fusion)
local scoped = Fusion.scoped
local Children = Fusion.Children

local HUD = UI:WaitForChild("GameHUD") :: ScreenGui
local DeathScreen = HUD:WaitForChild("DeathScreen") :: Frame

local Camera = workspace.CurrentCamera

local Libraries = Client.Libraries
local Bindables = Client.Bindables

local Events = ReplicatedStorage.Events

local module = {}
local activeToken = 0
local clickConnection = nil

local Config = {
	RESPAWN_TIME = 5
}

local scope = scoped(Fusion)
local death = scope:Value("")
local count = scope:Value(5)

scope:Hydrate(DeathScreen.Box) {
	[Children] = {
		scope:Hydrate(DeathScreen.Box.Text) {
			Text = scope:Computed(function(use)
				return `You were killed by {use(death)} \n`
			end)
		},
		scope:Hydrate(DeathScreen.Box.Prompt) {
			Text = scope:Computed(function(use)
				return `(Click anywhere to respawn. Otherwise, you'll respawn in {tostring(use(count))}s)`
			end)
		}
	}
}

local function disconnectClick()
	if clickConnection then
		clickConnection:Disconnect()
		clickConnection = nil
	end
end

local function handleMouseClick(input : InputObject, gp : boolean)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local success = Events.DeployRequest:InvokeServer()
		if success then
			module.Disable()
		end
	end
end

function module.Enable(Killer : Player)
	activeToken += 1
	local token = activeToken
	disconnectClick()

	DeathScreen.Visible = true
	
	--TODO: if error, change to just manually set the zoom amount.
	Bindables.SetCamState:Fire("ShiftLock")
	if Killer and Killer ~= Player and Killer.Character then
		local humanoid = Killer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			Camera.CameraSubject = humanoid
		end
	else
		Camera.CameraType = Enum.CameraType.Fixed
	end
		
	death:set(Killer and Killer.Name or "Unknown")
	
	clickConnection = UIS.InputBegan:Connect(handleMouseClick)

	for i = Config.RESPAWN_TIME, 1, -1 do
		if token ~= activeToken or not DeathScreen.Visible then return end
		count:set(i)
		task.wait(1)
	end
	if token ~= activeToken or not DeathScreen.Visible then return end
	local success = Events.DeployRequest:InvokeServer()
	if success then
		module.Disable()
	end
end

function module.Disable()
	activeToken += 1
	disconnectClick()
	DeathScreen.Visible = false
end

function module:Init(Properties)	
	local trove = Properties.Trove or Properties.trove
	
	DeathScreen.Visible = false
	
	trove:Connect(Events.PlayerKill.OnClientEvent, function(Killer : Player, plrKilled : Player)
		if plrKilled == Player then module.Enable(Killer) end
	end)
	
	trove:Connect(Events.EnableMenu.OnClientEvent, module.Disable)
	
	trove:Connect(DeathScreen.ReturnButton.MouseButton1Click, function()
		module.Disable()
		Bindables.EnableMenu:Fire()
	end)
end

return module
