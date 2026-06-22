local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")
local Client = game:GetService("StarterPlayer")

local Remotes = ReplicatedStorage:WaitForChild("Events")


local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local scoped = Fusion.scoped

local DmgMarker = require(Client.Components.DmgMarker)

local module = {}

function module:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui})
	local scope = Properties.Scope:innerScope({DmgMarker = DmgMarker}) :: Fusion.Scope
	local UI = Properties.UI
	
	table.insert(scope, Remotes.PlayerDamaged.OnClientEvent:Connect(function(dmg, pos)
		local marker = scope:DmgMarker {
			origin = pos,
		}
		marker.Parent = UI
	end))
end

return module