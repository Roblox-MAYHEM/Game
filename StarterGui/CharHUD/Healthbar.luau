local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")
local Player = game:GetService("Players").LocalPlayer

local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local module = {}

function module:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui})
	local scope = Properties.Scope:innerScope()
	local UI = Properties.UI
	local Hum = Player.Character:WaitForChild("Humanoid")
	
	local HealthBar = UI.HealthBar
	local HealthDisplay = HealthBar:WaitForChild("HealthDisplay"):WaitForChild("Health") :: Frame
	local Diamond = HealthBar:WaitForChild("Diamond")
	local HealthCount = HealthBar:WaitForChild("HealthCount")
	
	local health = scope:Value(Hum.Health)
	
	local team = Player.Team

	table.insert(scope, Hum.HealthChanged:Connect(function(newhealth : number)
		health:set(newhealth)
	end))
	
	local root = scope:Hydrate(HealthBar) {
		[Children] = {
			scope:Hydrate(HealthCount) {
				Text = scope:Computed(function(use) return math.round(use(health)) end)
			}
		}
	}
	
	local hb = scope:Hydrate(HealthDisplay) {
		BackgroundColor3 = (team and team.TeamColor.Color) or Color3.fromRGB(255, 255, 255),
		
		Size = scope:Computed(function(use)
			return UDim2.new(use(health) / Hum.MaxHealth, 0, 1, 0)
		end)
	}
end

return module
