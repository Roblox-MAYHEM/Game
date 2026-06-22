local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseState = require(script.Parent.Parent.BaseState)
local Cooldown = require(ReplicatedStorage.Utils.Cooldown)

local Vaulting = setmetatable({}, BaseState)
Vaulting.__index = Vaulting

local function flatUnit(v: Vector3): Vector3?
	local flat = Vector3.new(v.X, 0, v.Z)
	return flat.Magnitude > 0.001 and flat.Unit or nil
end

local function projectOnPlane(v: Vector3, normal: Vector3): Vector3
	return v - normal * v:Dot(normal)
end

local function getOrCreate(parent: Instance, className: string, name: string)
	local object = parent:FindFirstChild(name)
	if object then return object end

	object = Instance.new(className)
	object.Name = name
	object.Parent = parent
	return object
end

local function getAlign(self)
	if self.Align and self.Align.Parent == self.HRP then return self.Align end

	local attachment = getOrCreate(self.HRP, "Attachment", "VaultAssistAttachment")
	local align = getOrCreate(self.HRP, "AlignOrientation", "VaultFacing")
	align.Attachment0 = attachment
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.RigidityEnabled = true
	align.Responsiveness = 200
	align.MaxTorque = math.huge
	align.Enabled = false
	self.Align = align
	return align
end

local function unlockFacing(self)
	if self.Align then
		self.Align.Enabled = false
	end
end

function Vaulting.new(opts)
	local self = setmetatable(BaseState.new(opts), Vaulting)
	self.LastPart = nil
	self.Dir = nil
	self.SavedMoveSpeed = nil
	self.StartAt = 0
	self.FinishAt = 0
	self.SpeedFloor = 0
	self.Finished = false
	return self
end

function Vaulting:CanStart(mode)
	local config = self.Config
	local frame = self.fsm.Frame
	if Cooldown.get("VaultStart") or Cooldown.get("VaultSense") or not frame.Grounded then return false end

	local dir = flatUnit(frame.WorldWishDir)
		or flatUnit(frame.MoveVelocity)
		or flatUnit(self.fsm.CM.FacingDirection)
	if not dir or (mode == "Auto" and frame.Velocity.Magnitude < config.AutoMinSpeed) then return false end

	local hit = self.Cast:VaultCheck(dir)
	Cooldown.set("VaultSense", config.SenseCooldown)
	if not hit or (hit.Part == self.LastPart and Cooldown.get("VaultRepeat")) then return false end

	local maxHeight = mode == "Manual" and config.MaxHeight.Manual or config.MaxHeight.Auto
	if hit.HeightFromGround > maxHeight then return false end

	return {
		Dir = dir,
		Part = hit.Part,
		TopPosition = hit.TopPosition,
	}
end

function Vaulting:_rootOffset()
	return (self.fsm.GroundController and self.fsm.GroundController.GroundOffset) or 2
end

function Vaulting:_lockFacing()
	if not self.Dir then return end

	local up = self.fsm.CM.UpDirection
	local look = CFrame.lookAt(Vector3.zero, self.Dir, up)
	local align = getAlign(self)
	align.CFrame = look
	align.Enabled = true
	self.HRP.CFrame = CFrame.lookAt(self.HRP.Position, self.HRP.Position + self.Dir, up)
end

function Vaulting:_liftSpeed(data)
	local config = self.Config
	local top = data.TopPosition
	local targetY = top.Y + self:_rootOffset() + config.Clearance
	local height = math.max(targetY - self.HRP.Position.Y, 0)
	local speed = math.sqrt(2 * workspace.Gravity * height)
	return math.clamp(speed, config.MinLift, config.MaxLift)
end

function Vaulting:_applyVaultImpulse(data)
	local up = self.fsm.CM.UpDirection
	local current = self.HRP.AssemblyLinearVelocity
	local flatVelocity = projectOnPlane(current, up)
	local flatSpeed = flatVelocity.Magnitude
	local carrySpeed = math.max(flatSpeed, self.Config.MinCarrySpeed)
	local verticalSpeed = current:Dot(up)
	local liftSpeed = self:_liftSpeed(data)

	local targetFlatVelocity = self.Dir * carrySpeed
	local deltaVelocity =
		(targetFlatVelocity - flatVelocity)
		+ up * math.max(liftSpeed - verticalSpeed, 0)

	self.HRP:ApplyImpulse(deltaVelocity * self.HRP.AssemblyMass)
	return carrySpeed
end

function Vaulting:_restoreSpeed()
	if not self.Dir or self.SpeedFloor <= 0 then return end

	local flatVelocity = projectOnPlane(self.HRP.AssemblyLinearVelocity, self.fsm.CM.UpDirection)
	local missingSpeed = self.SpeedFloor - flatVelocity:Dot(self.Dir)
	if missingSpeed > 0 then
		self.HRP:ApplyImpulse(self.Dir * missingSpeed * self.HRP.AssemblyMass)
	end
end

function Vaulting:OnEnter(data)
	local config = self.Config
	local now = time()

	self.Dir = data.Dir
	self.LastPart = data.Part
	self.SavedMoveSpeed = self.fsm.CM.BaseMoveSpeed
	self.StartAt = now
	self.FinishAt = now + config.Duration
	self.SpeedFloor = 0
	self.Finished = false

	Cooldown.set("VaultStart", self.Config.Cooldown)
	self.Humanoid.AutoRotate = false
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	self.fsm.CM.ActiveController = self.fsm.AirController
	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.FacingDirection = self.Dir
	self.fsm.CM.BaseMoveSpeed = 0
	self.fsm.AirController.MaintainLinearMomentum = true
	self.fsm.AirController.MaintainAngularMomentum = false
	self:_lockFacing()
	self.SpeedFloor = self:_applyVaultImpulse(data)
	self.fsm.Runtime:SnapMoveSpeed(self.SpeedFloor)

	if self.Animations.Vaulting then
		if self.Animations.Vaulting.SetDuration then
			self.Animations.Vaulting:SetDuration(config.Duration)
		end
		self.Animations.Vaulting:Play()
	end
end

function Vaulting:OnUpdate(_dt: number)
	if not self.Dir or self.Finished then return end

	local now = time()

	self.fsm.CM.ActiveController = self.fsm.AirController
	self.fsm.CM.MovingDirection = self.Dir
	self.fsm.CM.FacingDirection = self.Dir
	self.fsm.CM.BaseMoveSpeed = self.SpeedFloor / self.fsm.EquipLoad
	self:_lockFacing()

	if now >= self.FinishAt then
		self.Finished = true
	end
end

function Vaulting:OnExit(_nextState)
	self:_restoreSpeed()
	self.fsm.Runtime:SnapMoveSpeed(self.SpeedFloor)
	self.Humanoid.AutoRotate = true
	self.fsm.CM.BaseMoveSpeed = self.SavedMoveSpeed
	Cooldown.set("VaultRepeat", self.Config.RepeatCooldown)
	unlockFacing(self)

	if self.Animations.Vaulting then self.Animations.Vaulting:Stop() end

	self.Dir = nil
	self.SavedMoveSpeed = nil
	self.StartAt = 0
	self.FinishAt = 0
	self.SpeedFloor = 0
	self.Finished = false
end

function Vaulting:IsFinished()
	return self.Finished
end

return Vaulting
