local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Turn = 0

local Lerp = function(a, b, t)
	return a + (b - a) * t
end;

RunService:BindToRenderStep("CameraSway", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	local MouseDelta = UserInputService:GetMouseDelta()

	Turn = Lerp(Turn, math.clamp(MouseDelta.X, -6, 6), (6 * deltaTime))
	
	Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad(Turn))
end)

local Camera = workspace.CurrentCamera

local rad = math.rad
local Rot = CFrame.new()

local function GetRollAngle()
	local Character = LocalPlayer.Character

	if not Character then
		return
	end

	local Cf = Camera.CFrame

	return -Cf.RightVector:Dot(Character.Humanoid.MoveDirection)
end

RunService:BindToRenderStep("RotateCameraInDirectionPlayerIsGoing", Enum.RenderPriority.Camera.Value + 1, function()
	local Roll = GetRollAngle() * 2
	Rot = Rot:Lerp(CFrame.Angles(0, 0, rad(Roll)),0.075)

	Camera.CFrame *= Rot
end)