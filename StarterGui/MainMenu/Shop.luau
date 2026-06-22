local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Client = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer
local UI = Player:WaitForChild("PlayerGui")
local ShopUI = UI:WaitForChild("MainMenu"):WaitForChild("ShopFrame")

local Events = ReplicatedStorage.Events
local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent, Out = Fusion.Children, Fusion.OnEvent, Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>

local Replica = require(Client.Packages.ReplicaClient)


local scope = scoped(Fusion)

local module = {
	Enabled = scope:Value(false)
}

function module.Enable()
	module.Enabled:set(true)
end

function module:Init(Properties)
	local replica = Properties.Replica

	ShopUI:WaitForChild("Exit").MouseButton1Click:Connect(function()
		module.Disable()
	end)
	
	local gui = scope:Hydrate(ShopUI) {
		Visible = module.Enabled,
	}
end


function module.Disable()
	module.Enabled:set(false)
	setState("MainMenu")
end

function module.SetStaticStateRef(ref)
	setState = ref
end

return module
