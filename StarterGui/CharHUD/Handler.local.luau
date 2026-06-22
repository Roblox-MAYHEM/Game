local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")
local Player = game:GetService("Players").LocalPlayer
local Remotes = ReplicatedStorage.Events

local UIBootstrap = require(Client.Libraries.UIBootstrap)

UIBootstrap.Load(script, {
	BeforeReplicas = function(props)
		props.Trove:Connect(Remotes.PlayerKill.OnClientEvent, function(_killer, killed)
			if killed == Player then
				props.Trove:Destroy()
			end
		end)
		props.Trove:Add(props.UI)
	end,
})
