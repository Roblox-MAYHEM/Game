local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Function to create a small orb at a position
local function createOrb(position)
	local orb = Instance.new("Part")
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.5, 0.5, 0.5)
	orb.Position = position
	orb.Anchored = true
	orb.CanCollide = false
	orb.BrickColor = BrickColor.new("Bright red")
	orb.Parent = workspace

	game.Debris:AddItem(orb, 10)
end

RunService.PostSimulation:Connect(function()
	createOrb(hrp.Position)
end)
