--[[
idk having an initializer here is basically useless meh
]]

local Initializer = {}

function Initializer:Init(Properties)		
	local Player	= Properties.Player
	local Shared 	= Properties.Shared
	local Client	= Properties.Client
	local scope		= Properties.Fusion

	local Remotes 	= Shared.Events
	local Bindables = Client.Bindables

	local ClientLibraries 	= Client.Libraries
end

return Initializer
