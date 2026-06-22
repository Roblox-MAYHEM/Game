local Initializer = {}
Initializer.Priority = 0

function Initializer:Init(Properties)
	local Server 	= Properties.Server

	local Libraries = Server.Libraries
	
	require(Libraries.PositionHistory):Init()
end

return Initializer
