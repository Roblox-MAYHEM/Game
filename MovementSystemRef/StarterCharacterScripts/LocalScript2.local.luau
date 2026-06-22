local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RideZiplineEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RideZipline")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

Player.CharacterAdded:Connect(function(char)
	Character = char
end)

local function getNearestZipline()
	for _, charPart in ipairs(Character:GetDescendants()) do
		if charPart:IsA("BasePart") then
			for _, touchingPart in ipairs(workspace:GetPartsInPart(charPart)) do
				local parent = touchingPart.Parent
				if parent and game.CollectionService:HasTag(parent, "ZIPLINE") then
					return parent
				end
			end
		end
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then 
		if Player:GetAttribute("Ziplining") then return end
		if getNearestZipline() ~= nil then
			RideZiplineEvent:FireServer(getNearestZipline())
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if Player:GetAttribute("Ziplining") then
		RideZiplineEvent:FireServer()
		return 
	end
end)
