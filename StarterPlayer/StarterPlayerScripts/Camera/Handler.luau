-- Camera Controller
-- 1. Handles camera shake
-- 2. Handles FOV spring
-- 3. Handles camera states / cycling

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Client = StarterPlayer
local Bindables = Client:WaitForChild("Bindables")
local Utils = ReplicatedStorage:WaitForChild("Utils")

local Spring = require(Utils:WaitForChild("Spring"))
local CameraShakeController = require(script.Parent:WaitForChild("CameraShaker"))

local CameraController = {
	ShakePriority = Enum.RenderPriority.Camera.Value + 1,
	CAMSTATESIDX = {"FirstPerson", "ShiftLock", "FreeCam"},
	CAMSTATES = {
		Default = {
			MinZoom = 30,
			MaxZoom = 400,
			MouseBehavior = Enum.MouseBehavior.Default,
			ShowMouse = true,
		},
		FirstPerson = {
			MinZoom = 0.5,
			MaxZoom = 0.5,
			MouseBehavior = Enum.MouseBehavior.LockCenter,
			ShowMouse = false,
		},
		ShiftLock = {
			MinZoom = 15,
			MaxZoom = 15,
			MouseBehavior = Enum.MouseBehavior.LockCenter,
			ShowMouse = false,
		},
		FreeCam = {
			MinZoom = 0.5,
			MaxZoom = 400,
			MouseBehavior = Enum.MouseBehavior.Default,
			ShowMouse = true,
		},
	},
}
CameraController.Priority = 1

local function UpdateShake(shakeCF)
	Camera.CFrame *= shakeCF
end

function CameraController:_setZoomInstant(distance: number)
	Player.CameraMode = Enum.CameraMode.Classic
	Player.CameraMinZoomDistance = distance
	Player.CameraMaxZoomDistance = distance
end

function CameraController:SetCamState(stateName: string)
	local stateData = self.CAMSTATES[stateName]
	assert(stateData, (`%s is not a valid camera state`):format(stateName))

	local idx = table.find(self.CAMSTATESIDX, stateName)
	if idx then
		self.StateIndex = idx
	end

	self.CurrentCamState = stateName
	
	if stateName == "FirstPerson" then
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		self:_setZoomInstant(stateData.MinZoom)
	end
	Player.CameraMinZoomDistance = stateData.MinZoom
	Player.CameraMaxZoomDistance = stateData.MaxZoom

	UserInputService.MouseBehavior = stateData.MouseBehavior
	UserInputService.MouseIconEnabled = stateData.ShowMouse

	if Bindables:FindFirstChild("ChangeCamState") then
		Bindables.ChangeCamState:Fire(stateName)
	end
end

function CameraController:CycleCamState(dir : number)
	self.StateIndex = ((self.StateIndex + dir - 1) % #self.CAMSTATESIDX) + 1
	local nextState = self.CAMSTATESIDX[self.StateIndex]
	self:SetCamState(nextState)
end

function CameraController:_onCycleCamera(actionName, inputState, inputObject : InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	self:CycleCamState(inputObject.KeyCode == Enum.KeyCode.O and 1 or -1)

	return Enum.ContextActionResult.Sink
end

function CameraController:Init(Properties)
	self.Properties = Properties
	self.Trove = Properties.Trove:Extend()

	self.CameraShaker = CameraShakeController.new(self.ShakePriority, UpdateShake)
	self.BaseFOV = Camera.FieldOfView
	self.CurrentFOV = Camera.FieldOfView
	self.CameraDirection = Vector3.new()
	self.CurrentCamState = nil
	self.RotationDisabled = true
	self.StateIndex = 1

	self.FOVSpring = Spring.new(self.BaseFOV, 0, self.BaseFOV, 20, 1)

	self.CameraShaker:Start()

	local oldCF = Camera.CFrame
	self.Connection = RunService.RenderStepped:Connect(function(dt)
		self.FOVSpring:update(dt)
		Camera.FieldOfView = self.FOVSpring.p

		self.RotationSpeed = oldCF.RightVector:Angle(Camera.CFrame.RightVector, Vector3.yAxis) / dt
		oldCF = Camera.CFrame
	end)

	ContextActionService:BindActionAtPriority(
		"Camera_Cycle",
		function(actionName, inputState, inputObject)
			return self:_onCycleCamera(actionName, inputState, inputObject)
		end,
		false,
		Enum.ContextActionPriority.High.Value + 1000,
		Enum.KeyCode.P, Enum.KeyCode.I
	)
	
	if Bindables:FindFirstChild("SetCamState") then
		self.Trove:Connect(Bindables.SetCamState.Event, function(newState)
			self:SetCamState(newState)
		end)
	end

	self:SetCamState("FirstPerson")
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = Properties.Character:WaitForChild("Humanoid")
end

function CameraController:GetRotationSpeed()
	return self.RotationSpeed
end

function CameraController:DisableRotation()
	self.RotationDisabled = true
	self._savedCamType = Camera.CameraType
	Camera.CameraType = Enum.CameraType.Scriptable
end

function CameraController:EnableRotation()
	self.RotationDisabled = false
	Camera.CameraType = self._savedCamType or Enum.CameraType.Custom
end

function CameraController:SetFOVZoom(FOV: number)
	self.FOVSpring.target = FOV
end

function CameraController:CreatePivot(endCF: CFrame, tweenInfo: TweenInfo)
	return TweenService:Create(Camera, tweenInfo, {CFrame = endCF})
end

function CameraController:CameraShake(callbackName: string, ...)
	self.CameraShaker[callbackName](self.CameraShaker, ...)
end

function CameraController:Destroy()
	ContextActionService:UnbindAction("Camera_Cycle")
	Player.CameraMode = Enum.CameraMode.Classic
	self:SetCamState("Default")
	
	if self.Connection then
		self.Connection:Disconnect()
	end

	if self.Trove then
		self.Trove:Destroy()
	end
end

return CameraController
