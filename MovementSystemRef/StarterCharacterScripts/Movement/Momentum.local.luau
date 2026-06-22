local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:WaitForChild("Humanoid")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BaseSpeed = 8
local MaxSpeed = 45
local AccelerationRate = 25
local DecelerationRate = 20
local CurrentSpeed = BaseSpeed
local Moving = false
local Camera = workspace.CurrentCamera

local WalkTrack = Humanoid:LoadAnimation(script.Walk)
local RunTrack = Humanoid:LoadAnimation(script.Run)

local BaseFOV = 70
local MaxFOV = 90
local CurrentFOV = BaseFOV

RunService.RenderStepped:Connect(function(dt)
	local moveDirection = Humanoid.MoveDirection
	local onGround = Humanoid.FloorMaterial ~= Enum.Material.Air
	local camera = workspace.CurrentCamera
	local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
	local moveDir = Vector3.new(moveDirection.X, 0, moveDirection.Z)
	local dot = moveDir:Dot(forward)
	local movingBackward = dot < -0.3

	if moveDirection.Magnitude > 0 and onGround then
		CurrentSpeed = math.clamp(CurrentSpeed + AccelerationRate * dt, BaseSpeed, MaxSpeed)
	elseif moveDirection.Magnitude == 0 and onGround then
		CurrentSpeed = math.clamp(CurrentSpeed - DecelerationRate * dt, BaseSpeed, MaxSpeed)
	end

	Humanoid.WalkSpeed = CurrentSpeed

	if moveDirection.Magnitude > 0 and onGround then
		if not Moving then
			Moving = true
			WalkTrack:Play()
			RunTrack:Play()
			RunTrack:AdjustWeight(0)
		end
	else
		if Moving and (not onGround or moveDirection.Magnitude == 0) then
			Moving = false
			WalkTrack:Stop()
			RunTrack:Stop()
		end
	end

	local blend = (CurrentSpeed - BaseSpeed) / (MaxSpeed - BaseSpeed)
	blend = math.clamp(blend, 0, 1)
	RunTrack:AdjustWeight(blend)
	WalkTrack:AdjustWeight(1 - blend)

	if Moving then
		local speedDir = movingBackward and -1 or 1
		WalkTrack:AdjustSpeed(speedDir)
		RunTrack:AdjustSpeed(speedDir)
	end

	local targetFOV = BaseFOV + (MaxFOV - BaseFOV) * blend
	if math.abs(Camera.FieldOfView - targetFOV) > 0.1 then
		TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = targetFOV}):Play()
	end
end)
