local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Loader = require(ReplicatedStorage.Utils.Loader)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(StarterPlayer.Packages.Fusion)
local Replica = require(StarterPlayer.Packages.ReplicaClient)

local Player = Players.LocalPlayer

local UIBootstrap = {}

local function observeReplicas()
	local playerReplica = nil
	local roundReplica = nil

	Replica.OnNew("PlayerData", function(rep)
		if rep.Tags.UserId == Player.UserId then
			playerReplica = rep
		end
	end)

	Replica.OnNew("RoundState", function(rep)
		roundReplica = rep
	end)

	return function()
		while not playerReplica or not roundReplica do
			task.wait()
		end

		return playerReplica, roundReplica
	end
end

function UIBootstrap.Load(rootScript, options)
	options = options or {}

	local ui = rootScript.Parent
	local trove = Trove.new()
	local scope = Fusion.scoped(Fusion)
	local getReplicas = observeReplicas()

	local baseProps = {
		Player = Player,
		Shared = ReplicatedStorage,
		Client = StarterPlayer,
		UI = ui,
		Scope = scope,
		Fusion = scope,
		Trove = trove,
		trove = trove,
	}

	if options.BeforeReplicas then
		options.BeforeReplicas(baseProps)
	end

	Replica.RequestData()

	local props = table.clone(baseProps)
	props.Replica, props.RoundReplica = getReplicas()

	if options.BeforeLoad then
		options.BeforeLoad(props)
	end

	Loader.Load(ui, props)

	return props
end

return UIBootstrap
