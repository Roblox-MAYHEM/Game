local StarterGui = game:GetService("StarterGui")

local Initializer = {}
Initializer.Priority = 0

function Initializer:Init(Properties)	
	local Client = Properties.Client
	local ClientLibraries = Client.Libraries

	local AnimationController = require(ClientLibraries.AnimationController)
	
	AnimationController:Init(Properties.ViewModel)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end

return Initializer
