local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")
local Root = HumanoidRootPart:WaitForChild("RootJoint")
local C1 = Root.C1

local Camera = workspace:WaitForChild("Camera")

local RayParams = RaycastParams.new()
RayParams.FilterDescendantsInstances = {Character}

local DB = false

Camera.CameraSubject = Character:WaitForChild("Head")