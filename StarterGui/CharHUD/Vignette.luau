local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client 			= game:GetService("StarterPlayer")
local TweenService      = game:GetService("TweenService")
local Player 			= game.Players.LocalPlayer

local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent, Out = Fusion.Children, Fusion.OnEvent, Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>

local Remotes = ReplicatedStorage:WaitForChild("Events")

local GOALTRANS = .3
local SPEED = 30
local DAMPING = 1

local module = {}

function module:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui})
	local scope = Properties.Scope:innerScope() :: Fusion.Scope
	local UI = Properties.UI

	local Vignette = UI:WaitForChild("VignetteFrame")

	local goalTransparency 	= scope:Value(1)
	local transparency    	= scope:Spring(goalTransparency, SPEED, DAMPING)
		
	Vignette.Image.ImageColor3 = Player.TeamColor.Color
	Vignette.Visible = true

	local root = scope:Hydrate(Vignette.Image) {
		ImageTransparency = scope:Computed(function(use)
			return use(transparency)
		end),
	}

	table.insert(scope, Remotes.EnterHill.OnClientEvent:Connect(function(enter : boolean)
		goalTransparency:set(enter and GOALTRANS or 1)
	end))
end

return module
