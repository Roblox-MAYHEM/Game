--[[
idk having an initializer here is basically useless meh
]]
local Player = game:GetService("Players").LocalPlayer

local Initializer = {}

function Initializer:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui})	
	local Humanoid	= Player.Character:WaitForChild("Humanoid")
	local UI = Properties.UI
	
	Humanoid.Died:Connect(function()
		Properties.Scope:doCleanup()
	end)
	table.insert(Properties.Scope, UI)
end

return Initializer
