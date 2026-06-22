local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Remotes = ReplicatedStorage.Events
local module = {}

local NO_COLLIDE_GROUP = "NoCollision"
local DEFAULT_PLAYER_GROUP = "Players"

-- Helper to set the group for all parts in a character
local function setCharacterCollisionGroup(character: Model, groupName: string)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

function module:Init()
	-- 1. Setup Groups (Keeping your existing setup)
	pcall(function() PhysicsService:RegisterCollisionGroup("ViewModel") end)
	PhysicsService:CollisionGroupSetCollidable("ViewModel", "Default", false)

	pcall(function() PhysicsService:RegisterCollisionGroup(DEFAULT_PLAYER_GROUP) end)
	PhysicsService:CollisionGroupSetCollidable(DEFAULT_PLAYER_GROUP, "ViewModel", false)
	PhysicsService:CollisionGroupSetCollidable(DEFAULT_PLAYER_GROUP, DEFAULT_PLAYER_GROUP, false)


	pcall(function() PhysicsService:RegisterCollisionGroup(NO_COLLIDE_GROUP) end)
	-- This makes NoCollision group ignore both ViewModels and normal Players
	PhysicsService:CollisionGroupSetCollidable(NO_COLLIDE_GROUP, "ViewModel", false)
	PhysicsService:CollisionGroupSetCollidable(NO_COLLIDE_GROUP, NO_COLLIDE_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(NO_COLLIDE_GROUP, DEFAULT_PLAYER_GROUP, false)

	for _, dummy in CollectionService:GetTagged("Dummy") do
		setCharacterCollisionGroup(dummy, DEFAULT_PLAYER_GROUP)
	end

	CollectionService:GetInstanceAddedSignal("Dummy"):Connect(function(dummy)
		setCharacterCollisionGroup(dummy, DEFAULT_PLAYER_GROUP)
	end)

	-- 2. Handle the Toggle Request
	Remotes.NoCollideRequest.OnServerEvent:Connect(function(plr: Player, state: boolean)
		local character = plr.Character
		if not character then return end

		if state == true then
			-- Switch to Ghost Mode
			setCharacterCollisionGroup(character, NO_COLLIDE_GROUP)
		else
			-- Switch back to Normal
			setCharacterCollisionGroup(character, DEFAULT_PLAYER_GROUP)
		end
	end)
end

return module
