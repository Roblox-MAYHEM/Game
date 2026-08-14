local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Remotes = ReplicatedStorage.Events
local Bindables = StarterPlayer.Bindables

local Loader = require(ReplicatedStorage.Utils.Loader)
local Trove = require(Packages:WaitForChild("Trove"))
local Replica = require(StarterPlayer.Packages.ReplicaClient)
local ViewModelController = require(StarterPlayer.Libraries.ViewmodelController)

local Config = {
	DEPLOYED_ATTRIBUTE = "Deployed",
}

local currentCleanup = nil
local killedCharacter = nil

local roundReplica = nil
local playerReplica = nil

Replica.OnNew("RoundState", function(rep)
	roundReplica = rep
end)

Replica.OnNew("PlayerData", function(rep)
	if rep.Tags.UserId == Player.UserId then
		playerReplica = rep
	end
end)

Replica.RequestData()

local function getPlayerReplica()
	while not playerReplica do task.wait() end
	return playerReplica
end

local function getRoundReplica()
	while not roundReplica do task.wait() end
	return roundReplica
end

local function setupResetButton()
	local resetBindable = Bindables:WaitForChild("ResetCharacter")

	resetBindable.Event:Connect(function()
		Remotes.ResetCharacter:FireServer()
	end)

	task.spawn(function()
		while true do
			local success = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", resetBindable)
			if success then return end
			RunService.Heartbeat:Wait()
		end
	end)
end

local function cleanupCurrent(reason: string)
	if currentCleanup then
		currentCleanup(reason)
	end
end

Remotes.EnableMenu.OnClientEvent:Connect(function()
	cleanupCurrent("Returned to menu")
end)

Remotes.PlayerKill.OnClientEvent:Connect(function(killer: Player, killed: Player)
	if killed ~= Player then return end

	killedCharacter = Player.Character
	cleanupCurrent("Killed by player")
end)

local function waitUntilReady(character: Model)
	while character == Player.Character and character:IsDescendantOf(game) do
		if character == killedCharacter then return false end
		if character:GetAttribute(Config.DEPLOYED_ATTRIBUTE) == true then return true end
		task.wait()
	end

	return false
end

local function initForCharacter(character: Model)
	local trove = Trove.new()
	local cleaned = false

	local function cleanup(reason: string)
		if cleaned then return end
		cleaned = true

		print("Character cleanup:", reason)

		trove:Destroy()

		if currentCleanup == cleanup then
			currentCleanup = nil
		end
	end

	currentCleanup = cleanup

	if character == killedCharacter then
		cleanup("Killed before init completed")
		return cleanup
	end

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local viewModel = trove:Add(ViewModelController.new(character))

	trove:Connect(character.AncestryChanged, function(_, parent)
		if not parent then cleanup("Character removed") end
	end)

	trove:Connect(humanoid.Died, function()
		warn("Humanoid.Died fired as fallback")
		cleanup("Humanoid.Died")
	end)

	Loader.Load(script.Parent, {
		Player = Player,
		Character = character,
		ViewModel = viewModel,
		Shared = ReplicatedStorage,
		Client = StarterPlayer,
		Trove = trove,
		Replica = getPlayerReplica(),
		RoundReplica = getRoundReplica(),
	})

	return cleanup
end

local function onCharacterAdded(character: Model)
	if not character:IsDescendantOf(game) then
		character.AncestryChanged:Wait()
	end

	if not waitUntilReady(character) then return end

	cleanupCurrent("Replaced by CharacterAdded")
	killedCharacter = nil

	initForCharacter(character)
end

setupResetButton()

Player.CharacterAdded:Connect(onCharacterAdded)

if Player.Character then
	task.spawn(onCharacterAdded, Player.Character)
end
