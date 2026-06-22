local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Events = ReplicatedStorage.Events
local Packages = ReplicatedStorage.Packages
local Utils = ReplicatedStorage.Utils

local Spring = require(Utils:WaitForChild("Spring"))
local CreateRig = require(script:WaitForChild("CreateRig"))
local Trove = require(Packages.Trove)

local ViewModelController = {}
ViewModelController.__index = ViewModelController

local ACTION_SWAY = "ACTION_SWAY"

local DEFAULT_CONFIG = {
	SCALE = 1,
	CAMERA_OFFSET = CFrame.new(),
	JOINT_C0 = CFrame.new(0, -0.5, 0),

	CAN_AIM = false,
	BOB_MOD = 1,

	TILT = 8.0, --max tilt in degrees
	TILT_CAMERA_RATIO = 0.5,
	TILT_AIM_MULTIPLIER = 0.8,
}

local function createJoint(viewModel)
	local joint = Instance.new("Motor6D")
	joint.Part0 = viewModel["Right Arm"]
	joint.Parent = viewModel["Right Arm"]
	joint.C0 = CFrame.new(0, -0.5, 0)
	return joint
end

local function setCollisionGroupRecursive(model, group)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end
end

local function mergeConfig(config)
	local merged = table.clone(DEFAULT_CONFIG)
	for key, value in pairs(config or {}) do
		merged[key] = value
	end
	return merged
end

function ViewModelController.new(character)
	local humanoid = character:WaitForChild("Humanoid")
	local viewModel = CreateRig(character)
	local vAnimator = viewModel.Humanoid:WaitForChild("Animator")

	local self = setmetatable({
		Character = character,
		Humanoid = humanoid,
		ViewModel = viewModel,
		vAnimator = vAnimator,

		Weapon = nil,
		Config = table.clone(DEFAULT_CONFIG),
		Joint = nil,

		Equipped = false,
		Destroyed = false,
		isAiming = false,
		_swayBound = false,
		_trove = Trove.new(),

		Springs = {
			aimLerp = Spring.new(0, 0, 0, 20, 1),
			armTilt = Spring.new(0, 0, 0, 10, 1),
			cameraTilt = Spring.new(0, 0, 0, 12, 1),
			sway = Spring.new(Vector3.zero, Vector3.zero, Vector3.zero, 15, 1),
			recoil = Spring.new(Vector3.zero, Vector3.zero, Vector3.zero, 20, 1),
			gunSpring = Spring.new(Vector3.zero, Vector3.zero, Vector3.zero, 15, 0.4),
			bobbing = Spring.new(Vector3.zero, Vector3.zero, Vector3.zero, 50, 1),
		},
		
		Tilt = {
			Alpha = 0,
			Impulse = 0,
		},

		aimCFrame = CFrame.new(),
		_lastRecoilCF = CFrame.new(),

	}, ViewModelController)

	self._trove:Add(self.ViewModel)
	self._trove:Add(self.vAnimator)

	self.Joint = self._trove:Add(createJoint(self.ViewModel))
	self:SetSwayState(true)

	self._trove:Connect(RunService.RenderStepped, function(dt)
		self:updateClient(dt)
	end)
	
	self._trove:Connect(Events.Knockback.OnClientEvent, function(velocity)
		--TODO
	end)

	setCollisionGroupRecursive(self.ViewModel, "ViewModel")
	return self
end

function ViewModelController:IsAlive()
	return self.Destroyed ~= true and self.ViewModel ~= nil and self.Joint ~= nil
end

function ViewModelController:SetSwayState(enabled)
	if self.Destroyed then return end

	if enabled and not self._swayBound then
		ContextActionService:BindAction(
			ACTION_SWAY,
			function(_, inputState, inputObject)
				self:swayBind(inputState, inputObject)
			end,
			false,
			Enum.UserInputType.MouseMovement,
			Enum.KeyCode.Thumbstick2
		)
		self._swayBound = true
	elseif not enabled and self._swayBound then
		ContextActionService:UnbindAction(ACTION_SWAY)
		self._swayBound = false
	end
end

function ViewModelController:swayBind(inputState, inputObject)
	if inputState ~= Enum.UserInputState.Change then
		return
	end

	local delta = inputObject.Delta

	if inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
		local theta = math.atan2(inputObject.Position.Y, inputObject.Position.X)
		delta = CFrame.fromAxisAngle(Vector3.zAxis, theta)
			* Vector3.new(25 * inputObject.Position.Magnitude, 0, 0)
	end

	self:updateSway(delta.X * 0.1, delta.Y * 0.1)
end

function ViewModelController:updateSway(x, y)
	self.Springs.sway.target = Vector3.new(math.rad(x), math.rad(y), 0)
end

function ViewModelController:SetTilt(alpha, impulse)
	self.Tilt.Alpha = math.clamp(alpha or 0, -1, 1)
	self.Tilt.Impulse = math.clamp((self.Tilt.Impulse or 0) + (impulse or 0), -1, 1)
end

function ViewModelController:GetTilt()
	return self.Tilt.Alpha, self.Tilt.Impulse
end

function ViewModelController:ApplyTilt()
	local info = self.Tilt
	
	local aimMultiplier = self.isAiming and (self.Config.TILT_AIM_MULTIPLIER or 1) or 1
	local armTilt = math.rad((self.Config.TILT or 0) * aimMultiplier)
	local cameraTilt = armTilt * (self.Config.TILT_CAMERA_RATIO or 0)

	self.Springs.armTilt.target = armTilt * (info.Alpha or 0)
	self.Springs.cameraTilt.target = cameraTilt * (info.Alpha or 0)

	local impulse = info.Impulse or 0
	if impulse ~= 0 then
		self.Springs.armTilt.v += armTilt * impulse
		self.Springs.cameraTilt.v += cameraTilt * impulse
		info.Impulse = 0
	end
end

function ViewModelController:AdjustSpring(name, value)
	local spring = self.Springs[name]
	if spring then
		spring.v += value
	end
end

function ViewModelController:SetAiming(isAiming)
	if self.Destroyed or not self.Equipped then
		return
	end

	self.isAiming = isAiming
	self.Springs.aimLerp.target = isAiming and 1 or 0
end

ViewModelController.aimDownSights = ViewModelController.SetAiming

function ViewModelController:updateClient(dt)
	if self.Destroyed or not self.Equipped then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	if self.ViewModel.Parent ~= camera then
		local ok = pcall(function()
			self.ViewModel.Parent = camera
		end)
		if not ok then return end
	end

	local moveDirection = self.Humanoid.MoveDirection
	local isMoving = moveDirection:Dot(moveDirection) > 0
	local bobMod = (self.isAiming and self.Config.BOB_MOD or 1) * 0.05
	local speed = self.Humanoid.WalkSpeed / 16
	local swayMod = self.isAiming and (1 / 3) or 1

	self.Springs.bobbing.target = isMoving
		and Vector3.new(
			math.sin(tick() * 5 * speed) * bobMod,
			math.sin(tick() * 10 * speed) * bobMod,
			0
		)
		or Vector3.zero

	self:ApplyTilt()

	dt *= (_G.TimeMult or 1)
	for _, spring in pairs(self.Springs) do
		spring:update(dt)
	end

	if self.Config.CAN_AIM then
		self.aimCFrame = CFrame.new():Lerp(
			self.Weapon.Aim.CFrame:Inverse() * self.ViewModel.Head.CFrame,
			self.Springs.aimLerp.p
		)
	else
		self.aimCFrame = CFrame.new()
	end

	local recoil    = self.Springs.recoil.p
	local sway      = self.Springs.sway.p
	local gunSpring = self.Springs.gunSpring.p
	
	local recoilCF = CFrame.Angles(math.rad(recoil.X), math.rad(recoil.Y), math.rad(recoil.Z))
	local tiltCF = CFrame.Angles(0, 0, self.Springs.cameraTilt.p)

	camera.CFrame = camera.CFrame * self._lastRecoilCF:Inverse() * recoilCF * tiltCF
	self._lastRecoilCF = recoilCF

	self.ViewModel:PivotTo(
		camera.CFrame
			* self.aimCFrame
			* self.Config.CAMERA_OFFSET
			* CFrame.Angles(
				sway.Y * swayMod,
				sway.X * swayMod,
				0
			)
			* CFrame.new(self.Springs.bobbing.p)
			* CFrame.Angles(gunSpring.Y, gunSpring.Z, 0)
			* CFrame.new(0, 0, gunSpring.X * 5)
			* CFrame.fromEulerAnglesYXZ(0, 0, self.Springs.armTilt.p)
	)
end

function ViewModelController:Equip(vWeapon, config)
	if self.Destroyed or not self:IsAlive() then
		return false
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end

	if not vWeapon then
		self:Unequip()
		return false
	end

	if self.Equipped then
		self:Unequip()
	end

	self.Weapon = vWeapon
	self.Config = mergeConfig(config)
	local scaled, scaleErr = pcall(function()
		self.Weapon:ScaleTo(self.Config.SCALE)
	end)
	if not scaled then
		warn("[ViewModel] Equip failed:", scaleErr)
		self.Weapon = nil
		return false
	end

	local primaryPart = self.Weapon:FindFirstChild("Handle") or self.Weapon:FindFirstChild("Primary")
	if not primaryPart then
		warn("[ViewModel] Equip failed: weapon has no Handle or Primary part")
		self.Weapon = nil
		return false
	end

	local handleAttachment = primaryPart:FindFirstChild("HandleAttachment")

	self.aimCFrame = CFrame.new()
	self.Joint.C0 = self.Config.JOINT_C0
	self.Joint.C1 = self.Config.JOINT_C1 or (handleAttachment and handleAttachment.CFrame) or CFrame.new()
	self.Joint.Part1 = primaryPart

	setCollisionGroupRecursive(vWeapon, "ViewModel")

	local ok, err = pcall(function()
		self.Weapon.Parent = self.ViewModel
		self.ViewModel.Parent = camera
	end)

	if not ok then
		warn("[ViewModel] Equip failed:", err)
		self.Weapon = nil
		self.Joint.Part1 = nil
		return false
	end

	self.Equipped = true
	return true
end

function ViewModelController:Unequip()
	if self.Destroyed then return end

	self:SetAiming(false)
	
	if self.Tilt then
		self.Tilt.Alpha = 0
		self.Tilt.Impulse = 0
	end
	
	self._lastRecoilCF = CFrame.new()

	self.Equipped = false
	self.Weapon = nil

	if self.ViewModel then
		pcall(function()
			self.ViewModel.Parent = nil
		end)
	end

	if self.Joint then
		self.Joint.Part1 = nil
		self.Joint.C1 = CFrame.new()
	end
end

function ViewModelController:Destroy()
	if self.Destroyed then return end

	self:Unequip()
	self:SetSwayState(false)
	self.Destroyed = true
	self._trove:Destroy()
end

return ViewModelController
