local SmoothShiftLock = {}
SmoothShiftLock.__index = SmoothShiftLock

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Maid = require(script:WaitForChild("Maid"))
local Spring = require(script:WaitForChild("Spring"))

local LocalPlayer = Players.LocalPlayer
local PlayerMouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local Config = {
	MOBILE_SUPPORT = true,
	SMOOTH_CHARACTER_ROTATION = false,
	CHARACTER_ROTATION_SPEED = 3,
	TRANSITION_SPRING_DAMPER = 0.7,
	CAMERA_TRANSITION_IN_SPEED = 10,
	CAMERA_TRANSITION_OUT_SPEED = 14,
	LOCKED_CAMERA_OFFSET = Vector3.new(1.75, 0.25, 0),
	LOCKED_MOUSE_ICON = "rbxasset://textures/MouseLockedCursor.png",
	SHIFT_LOCK_KEYBINDS = {Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl}
}

function SmoothShiftLock.new()
	local self = setmetatable({}, SmoothShiftLock)
	self._runtimeMaid = Maid.new()
	self._shiftlockMaid = Maid.new()
	self._cameraOffsetSpring = Spring.new(Vector3.new(0,0,0))
	self._cameraOffsetSpring.Damper = Config.TRANSITION_SPRING_DAMPER
	self.Enabled = false
	self:Enable()
	return self
end

function SmoothShiftLock:Enable()
	self:_refreshCharacterVariables()

	self._runtimeMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
		self:_refreshCharacterVariables()
	end))

	ContextActionService:BindActionAtPriority("ShiftLockSwitchAction", function(_,State)
		if State == Enum.UserInputState.Begin then
			self:ToggleShiftLock()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, Config.MOBILE_SUPPORT, Enum.ContextActionPriority.Medium.Value, unpack(Config.SHIFT_LOCK_KEYBINDS))

	self._runtimeMaid:GiveTask(RunService.RenderStepped:Connect(function()
		if self.Head.LocalTransparencyModifier > 0.6 then return end
		local CameraCFrame = Camera.CoordinateFrame
		local Distance = (self.Head.Position - CameraCFrame.p).magnitude
		if Distance > 1 then
			Camera.CFrame = Camera.CFrame * CFrame.new(self._cameraOffsetSpring.Position)
			if self.Enabled and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				self:_updateMouseState()
			end
		end
	end))
end

function SmoothShiftLock:Disable()
	self._runtimeMaid:DoCleaning()
	self._shiftlockMaid:DoCleaning()
	ContextActionService:UnbindAction("ShiftLockSwitchAction")
end

function SmoothShiftLock:_refreshCharacterVariables()
	self.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	self.RootPart = self.Character:WaitForChild("HumanoidRootPart")
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.Head = self.Character:WaitForChild("Head")
end

function SmoothShiftLock:_updateMouseState()
	UserInputService.MouseBehavior = (self.Enabled and Enum.MouseBehavior.LockCenter) or Enum.MouseBehavior.Default
end

function SmoothShiftLock:_updateMouseIcon()
	PlayerMouse.Icon = (self.Enabled and Config.LOCKED_MOUSE_ICON) or ""
end

function SmoothShiftLock:_transitionLockOffset()
	if self.Enabled then
		self._cameraOffsetSpring.Speed = Config.CAMERA_TRANSITION_IN_SPEED
		self._cameraOffsetSpring.Target = Config.LOCKED_CAMERA_OFFSET
	else
		self._cameraOffsetSpring.Speed = Config.CAMERA_TRANSITION_OUT_SPEED
		self._cameraOffsetSpring.Target = Vector3.new(0,0,0)
	end
end

function SmoothShiftLock:IsEnabled()
	return self.Enabled
end

function SmoothShiftLock:ToggleShiftLock(Enable)
	if Enable ~= nil then
		self.Enabled = Enable
	else
		self.Enabled = not self.Enabled
	end

	self:_updateMouseState()
	self:_updateMouseIcon()
	self:_transitionLockOffset()

	if self.Enabled then
		self._shiftlockMaid:GiveTask(RunService.RenderStepped:Connect(function(Delta)
			if self.Humanoid and self.RootPart then
				self.Humanoid.AutoRotate = not self.Enabled
			end

			if self.Humanoid.Sit then return end

			local allowRotate = (self.Character:GetAttribute("ShiftRotate") ~= false)
			
			if not allowRotate then return end

				local _, y = Camera.CFrame:ToOrientation()
				if Config.SMOOTH_CHARACTER_ROTATION then
					self.RootPart.CFrame = self.RootPart.CFrame:Lerp(
						CFrame.new(self.RootPart.Position) * CFrame.Angles(0, y, 0),
						Delta * 5 * Config.CHARACTER_ROTATION_SPEED
					)
				else
					self.RootPart.CFrame = CFrame.new(self.RootPart.Position) * CFrame.Angles(0, y, 0)
				end
				--[[
								local _, y = Camera.CFrame:ToOrientation()
			local facing = Vector3.new(math.sin(y), 0, math.cos(y))
			local ControllerManager = self.Humanoid.Parent:FindFirstChild("ControllerManager")
			ControllerManager.FacingDirection = -facing
			self.Humanoid:SetAttribute("Rotating",true)
				]]
		end))
	else
		self.Humanoid.AutoRotate = true
		self._shiftlockMaid:DoCleaning()
	end
end

return SmoothShiftLock.new()
