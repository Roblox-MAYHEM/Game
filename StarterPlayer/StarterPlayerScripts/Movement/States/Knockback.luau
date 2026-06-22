local BaseState = require(script.Parent.Parent.BaseState)

local Knockback = setmetatable({}, BaseState)
Knockback.__index = Knockback

local function flatSpeed(vector: Vector3, up: Vector3): number
	return (vector - up * vector:Dot(up)).Magnitude
end

local function isWall(result: RaycastResult, up: Vector3, maxDot: number): boolean
	return result.Instance
		and result.Instance:IsA("BasePart")
		and result.Instance.CanCollide
		and math.abs(result.Normal:Dot(up)) <= maxDot
end

function Knockback.new(opts)
	local self = setmetatable(BaseState.new(opts), Knockback)
	self.Time = 0
	self.Duration = 0
	self.WallDaze = false
	self.DazeDuration = 0
	self.WallSpeedMin = 0
	self.LastPosition = nil
	self.LastSpeed = 0
	self.RayParams = nil
	self.BlockParentInput = true
	return self
end

function Knockback:OnEnter(data)
	local config = self.Config
	local velocity = data.Velocity or Vector3.zero

	self.Time = 0
	self.Duration = data.Duration or config.Duration
	self.WallDaze = data.WallDaze == true
	self.DazeDuration = data.DazeDuration or config.DefaultDazeDuration
	self.WallSpeedMin = data.WallSpeedMin or config.MinWallSpeed
	self.LastPosition = self.HRP.Position
	self.LastSpeed = flatSpeed(velocity, self.fsm.CM.UpDirection)
	self.BlockParentInput = true

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.Character }
	params.RespectCanCollide = true
	params.IgnoreWater = true
	self.RayParams = params

	self:_OwnController()

	local deltaVelocity = velocity - self.HRP.AssemblyLinearVelocity
	self.HRP:ApplyImpulse(deltaVelocity * self.HRP.AssemblyMass)
end

function Knockback:_OwnController()
	self.fsm.CM.ActiveController = self.fsm.AirController
	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
	self.fsm.GroundController.Friction = 0
	self.fsm.AirController.MaintainLinearMomentum = true
	self.fsm.AirController.MaintainAngularMomentum = false
end

function Knockback:OnUpdate(dt)
	self.Time += dt
	self:_OwnController()

	local currentPosition = self.HRP.Position
	local lastPosition = self.LastPosition or currentPosition
	local displacement = currentPosition - lastPosition
	local segmentSpeed = displacement.Magnitude / math.max(dt, 1 / 240)

	if self.WallDaze and displacement.Magnitude > 0.05 then
		local result = workspace:Raycast(lastPosition, displacement, self.RayParams)
		if result and isWall(result, self.fsm.CM.UpDirection, self.Config.WallNormalDotMax) then
			if math.max(self.LastSpeed, segmentSpeed) >= self.WallSpeedMin then
				self.fsm.StateMachine:Change("Dazed", {
					Duration = self.DazeDuration,
					ImpactNormal = result.Normal,
				})
				return
			end
		end
	end

	self.LastPosition = currentPosition
	self.LastSpeed = self.fsm.Runtime:GetMoveVelocity().Magnitude
end

function Knockback:OnExit()
	self.fsm.GroundController.Friction = self.fsm.BaseFriction
	self.LastPosition = nil
	self.LastSpeed = 0
	self.RayParams = nil
	self.BlockParentInput = false
end

function Knockback:IsFinished()
	return self.Time >= self.Duration
end

return Knockback
