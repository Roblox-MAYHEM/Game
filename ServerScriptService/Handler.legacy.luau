local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("Loader"))

Players.CharacterAutoLoads = false

local Properties = {
	Server = game:GetService("ServerStorage"),
	Shared = ReplicatedStorage
}

Loader.Load(script.Parent, Properties)
