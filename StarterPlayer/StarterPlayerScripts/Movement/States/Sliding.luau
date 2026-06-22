-- DEFUNCT
local BaseState = require(script.Parent.Parent.BaseState)
local Client = game:GetService("StarterPlayer")

local Sliding = setmetatable({}, BaseState)
Sliding.__index = Sliding

local Config = {
	SLIDE_MIN_TIME = 0.2,
	SLIDE_CAM_SENS = 0.7,
	SLIDE_JUMP_ACC = 5,
}

local function projectOnPlane(v: Vector3, n: Vector3): Vector3
	local d = n:Dot(n)
	return (d < 1e-5) and v or (v - n * v:Dot(n) / d)
end

function Sliding.new(opts)
	local self = BaseState.new(opts)
	
	setmetatable(self, Sliding)
	
	local slidingAttachment = Instance.new("Attachment")
	slidingAttachment.Name = "SlidingAttachment"
	slidingAttachment.Parent = self.HRP
	self.SlidingAttachment = slidingAttachment
	self.trove:Add(slidingAttachment)

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Enabled = false
	alignOrientation.RigidityEnabled = true
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = slidingAttachment
	alignOrientation.Parent = self.HRP
	self.AlignOrientation = alignOrientation
	self.trove:Add(alignOrientation)
	
	return self
end

function Sliding:OnEnter()
	local floorNormal = self.fsm.RayStates.Ground.Normal
	local slope = projectOnPlane(self.HRP.CFrame.LookVector, floorNormal)

	self.Humanoid.AutoRotate = false
	if self.AlignOrientation then self.AlignOrientation.Enabled = true end
	self.Humanoid:ChangeState("Physics")

	self.fsm:DisableMovement()

	if self.Physics and self.Physics.Push and self.Physics.GetSpeedScalar then
		self.Physics:Push(slope.Unit, self.Physics:GetSpeedScalar() * (Config.SLIDE_ACC or 15))
	end
	if self.Animations and self.Animations.Slide then self.Animations.Slide:Play() end
	self.Humanoid.CameraOffset = Vector3.new(0, -2, 0)

	self.fsm.SlideTime = 0
end

function Sliding:OnUpdate(dt)
	self.fsm.SlideTime += dt

	if self.fsm.RayStates.Ground then
		local n = self.fsm.RayStates.Ground.Normal
		local tangVel = projectOnPlane(self.HRP.AssemblyLinearVelocity, n)
		local rotSpeed = self.Camerea:GetRotationSpeed() * (Config.SLIDE_CAM_SENS or 0.7)
		self.HRP.AssemblyLinearVelocity = CFrame.fromAxisAngle(n, rotSpeed * dt) * tangVel
	end

	if self.AlignOrientation then
		self.AlignOrientation.CFrame = CFrame.lookAt(Vector3.zero, self.HRP.AssemblyLinearVelocity)
	end

	if self.fsm.SlideTime >= (Config.SLIDE_MIN_TIME or 0.2) then
		local runSpeed = Config.RUN_SPEED or 25
		if self.Physics and self.Physics.GetCurrentSpeed and self.Physics:GetCurrentSpeed() < runSpeed then
			self.fsm:HandleStateChange("Idle")
			return
		end
	end
end

function Sliding:OnExit()
	if self.Animations and self.Animations.Slide then self.Animations.Slide:Stop() end
	self.Humanoid.HipHeight = 0
	self.Humanoid.CameraOffset = Vector3.zero

	self.fsm:EnableMovement()
	self.Animations.Running:Play()
	self.Humanoid.AutoRotate = true
	if self.AlignOrientation then self.AlignOrientation.Enabled = false end
end

return Sliding
