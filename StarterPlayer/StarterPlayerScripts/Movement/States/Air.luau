local BaseState = require(script.Parent.Parent.BaseState)
local Air = setmetatable({}, BaseState)
Air.__index = Air

function Air.new(opts)
	return setmetatable(BaseState.new(opts), Air)
end

function Air:OnEnter(_data)
	local Config = self.Config
	local ac = self.fsm.AirController
	ac.MaintainLinearMomentum = true
	ac.MaintainAngularMomentum = false

	self.fsm.CM.BaseMoveSpeed = Config.MaxSpeed / self.fsm.EquipLoad

	if self.Animations.Air then
		self.Animations.Air:Play()
	end
end

function Air:OnUpdate(dt)
	local frame = self.fsm.Frame
	local dir = frame.WorldWishDir
	local flatVel = self.fsm.Runtime:GetMoveVelocity()

	if dir == Vector3.zero then
		if flatVel.Magnitude < 0.5 then
			self.fsm.CM.MovingDirection = Vector3.zero
		else
			dir = flatVel.Unit
			self.fsm.CM.MovingDirection = dir
		end

		local speed = self.fsm.Runtime:GetMoveSpeed(self.Config.MaxSpeed, dir, dt)
		self.fsm.AirController.MoveMaxForce = self.Config.Force.Min / self.fsm.EquipLoad
		self.fsm.AirController.TurnMaxTorque = (self.Config.Force.Min * self.Config.TorqueScale) / self.fsm.EquipLoad
		self.fsm.CM.BaseMoveSpeed = speed / self.fsm.EquipLoad
		return
	end

	local speed = self.fsm.Runtime:GetMoveSpeed(self.Config.MaxSpeed, dir, dt)
	local projected = flatVel:Dot(dir)
	local headroom = math.max(speed - projected, 0)

	if flatVel.Magnitude > 0.1 and flatVel.Unit:Dot(dir) < 0 then
		headroom *= self.Config.ReversePenalty
	end

	local force = math.clamp(
		self.Config.Force.Min + headroom * self.Config.Force.PerSpeed,
		self.Config.Force.Min,
		self.Config.Force.Max
	) / self.fsm.EquipLoad

	self.fsm.AirController.MoveMaxForce = force
	self.fsm.AirController.TurnMaxTorque = force * self.Config.TorqueScale
	self.fsm.CM.MovingDirection = dir
	self.fsm.CM.BaseMoveSpeed = speed / self.fsm.EquipLoad
end

function Air:OnExit(_nextState)
	self.fsm.CM.MovingDirection = Vector3.zero
end

return Air
