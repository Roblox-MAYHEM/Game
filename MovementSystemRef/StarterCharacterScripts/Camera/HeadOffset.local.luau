local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace:WaitForChild("Camera")

local DB = false
local RSCUTSCENEEvent

RunService.RenderStepped:Connect(function()
	if not Character or not Humanoid or DB then return end

	local isFirstPerson = (Camera.CFrame.Position - Character.Head.Position).Magnitude < 1.4

	if not isFirstPerson then
		for _, accessory in Character:GetDescendants() do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle")
				if handle then
					handle.Transparency = 0
				end
			end
		end
		Character.Head.Transparency = 0
		Character.Torso.Transparency = 0
	else
		for _, accessory in Character:GetDescendants() do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle")
				if handle then
					handle.Transparency = 1
				end
			end
		end
		Character.Head.Transparency = 1
		Character.Torso.Transparency = 1
	end
end)

script.Parent.Cutscene.Changed:Connect(function(val)
	if val then
		DB = true
		Camera.CameraType = Enum.CameraType.Scriptable
		RSCUTSCENEEvent = RunService.RenderStepped:Connect(function()
			if script.Parent.LerpCutscene.Value then
				Camera.CFrame = Camera.CFrame:Lerp(Character.Head.CFrame,0.3)
			else
				Camera.CFrame = Character.Head.CFrame
			end
		end)

		for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
			track:Stop()
		end
		for _, track in ipairs(Humanoid:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()) do
			track:Stop()
		end
	else
		if RSCUTSCENEEvent then
			RSCUTSCENEEvent:Disconnect()
			RSCUTSCENEEvent = nil
		end
		task.wait()
		Camera.CameraType = Enum.CameraType.Custom
		DB = false
	end
end)

script.Parent.DontMove.Changed:Connect(function(val)
	if val then
		DB = true
		if RSCUTSCENEEvent then
			RSCUTSCENEEvent:Disconnect()
			RSCUTSCENEEvent = nil
		end
	else
		DB = false
	end
end)

game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('SetCutscene').OnClientEvent:Connect(function(FirstpersonDependent,Value,LerpCut)
	local isFirstPerson = (Camera.CFrame.Position - Character.Head.Position).Magnitude < 1.4
	
	if FirstpersonDependent then
		if not isFirstPerson then return end
	end
	
	script.Parent.LerpCutscene.Value = LerpCut
	script.Parent.Cutscene.Value = Value
end)