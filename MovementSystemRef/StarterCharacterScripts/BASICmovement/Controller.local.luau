local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:FindFirstChildOfClass('Humanoid') or Character:WaitForChild('Humanoid')
local HumanoidRootPart : BasePart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local MOVE_SPEED = 32
local Controller : ControllerManager = Character:WaitForChild("ControllerManager")

local AirController = Controller:FindFirstChildOfClass('AirController')
local GroundController = Controller:FindFirstChildOfClass('GroundController')

local moveVector = Vector3.new(0, 0, 0)

local Direction = require("./Utils/Direction")
local Variables = require("./Utils/Variables")

local Jump = require("./Movement/Jump")

Humanoid.EvaluateStateMachine = false

local WalkTrack = Humanoid:LoadAnimation(script.Walk)
local RunTrack = Humanoid:LoadAnimation(script.Run)

WalkTrack.Priority = Enum.AnimationPriority.Idle
RunTrack.Priority = Enum.AnimationPriority.Movement

local keysDown = {}
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.W then keysDown["W"] = true end
	if input.KeyCode == Enum.KeyCode.A then keysDown["A"] = true end
	if input.KeyCode == Enum.KeyCode.S then keysDown["S"] = true end
	if input.KeyCode == Enum.KeyCode.D then keysDown["D"] = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then keysDown["W"] = false end
	if input.KeyCode == Enum.KeyCode.A then keysDown["A"] = false end
	if input.KeyCode == Enum.KeyCode.S then keysDown["S"] = false end
	if input.KeyCode == Enum.KeyCode.D then keysDown["D"] = false end
end)

GroundController.AccelerationTime = 0
GroundController.DecelerationTime = 0

RunService.RenderStepped:Connect(function(dt)
	local isGrounded = Controller.GroundSensor.SensedPart ~= nil

	if isGrounded and Controller.ActiveController ~= GroundController then
		Controller.ActiveController = GroundController
	elseif not isGrounded and Controller.ActiveController ~= AirController then
		Controller.ActiveController = AirController
	end

	
	moveVector = Direction:updateMoveVector(keysDown,moveVector)
	local dir = Direction:getMoveDirection(HumanoidRootPart,moveVector)
	if dir.Magnitude > 0 then
		Controller.BaseMoveSpeed = math.clamp(Controller.BaseMoveSpeed + (Variables.AccelDtMultiplied * dt),0.9,MOVE_SPEED)
		if WalkTrack.IsPlaying == false then
			WalkTrack:Play()
			RunTrack:Play(nil,0)
		end
		RunTrack:AdjustWeight(Controller.BaseMoveSpeed / MOVE_SPEED)
	else
		Controller.BaseMoveSpeed = math.clamp(Controller.BaseMoveSpeed - (Variables.DeccelDtMultiplied * dt),0.9,MOVE_SPEED)
		WalkTrack:Stop()
		RunTrack:Stop()
	end
	if Controller.BaseMoveSpeed >= Variables.DeccelSpeed then
		GroundController.DecelerationTime = Variables.DeccelSpeed
	else
		GroundController.DecelerationTime = 0
	end
	Controller.MovingDirection = dir
	
	if not Humanoid:GetAttribute("Rotating") and Character:GetAttribute("ShiftRotate") then
		Controller.FacingDirection = dir
		print('wow')
	end

	GroundController.MoveSpeedFactor = 1
	AirController.MoveSpeedFactor = 1
	--print(Controller.BaseMoveSpeed)
	--print(Controller.BaseMoveSpeed / MOVE_SPEED )
	
	GroundController.Friction = 10
	GroundController.FrictionWeight = 9
	--HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + dir * MOVE_SPEED * dt
end)

game.UserInputService.InputBegan:Connect(function(Input,Process)
	if Input.KeyCode ~= Enum.KeyCode.Space then return end
	if Controller.ActiveController == AirController then return end
	Jump:Jump(Controller,HumanoidRootPart,Variables.JumpPower)
end)