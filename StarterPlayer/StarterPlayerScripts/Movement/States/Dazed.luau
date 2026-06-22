local BaseState = require(script.Parent.Parent.BaseState)

local Dazed = setmetatable({}, BaseState)
Dazed.__index = Dazed

function Dazed.new(opts)
	local self = setmetatable(BaseState.new(opts), Dazed)
	self.Time = 0
	self.Duration = 0
	self.BlockParentInput = true
	return self
end

function Dazed:OnEnter(data)
	local Config = self.Config
	self.Time = 0
	self.Duration = data.Duration or Config.Duration
	self.BlockParentInput = true

	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
	self.fsm.GroundController.Friction = self.fsm.BaseFriction
	self.Humanoid.AutoRotate = false

	local current = self.HRP.AssemblyLinearVelocity
	local mult = Config.HorizontalVelocityMultiplier
	self.HRP.AssemblyLinearVelocity = Vector3.new(current.X * mult, math.min(current.Y, 0), current.Z * mult)
end

function Dazed:OnUpdate(dt)
	self.Time += dt
	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
end

function Dazed:OnExit()
	self.Time = 0
	self.Duration = 0
	self.BlockParentInput = false
	self.Humanoid.AutoRotate = true
end

function Dazed:IsFinished()
	return self.Time >= self.Duration
end

return Dazed
