local Locomotion = {}
Locomotion.__index = Locomotion

local function flat(vector: Vector3, up: Vector3): Vector3
	return vector - up * vector:Dot(up)
end

function Locomotion.new(movement)
	return setmetatable({ Movement = movement }, Locomotion)
end

function Locomotion:Update(dt: number)
	local movement = self.Movement
	local frame = movement.Frame
	local config = movement.Config
	local up = movement.CM.UpDirection
	local wish = frame.WorldWishDir
	local velocity = flat(frame.Velocity, up)
	local speed = velocity.Magnitude

	if frame.Grounded then
		local ground = movement.GroundController
		local running = config.Ground
		movement.CM.ActiveController = ground
		ground.AccelerationTime = running.Acceleration
		ground.DecelerationTime = running.Acceleration
		ground.TurnSpeedFactor = 1
		ground.Friction = running.Grip

		local carrying = time() < movement.LandingCarryUntil
		if carrying and wish == Vector3.zero then
			wish = movement.LandingDirection
		end

		movement.CM.MovingDirection = wish
		movement.CM.BaseMoveSpeed = math.max(running.Speed, carrying and movement.LandingSpeed or 0)
		return
	end

	local air = movement.AirController
	local airConfig = config.Air
	movement.CM.ActiveController = air
	air.MaintainLinearMomentum = true
	air.MaintainAngularMomentum = false

	if wish == Vector3.zero then
		movement.CM.MovingDirection = Vector3.zero
		movement.CM.BaseMoveSpeed = 0
		air.MoveMaxForce = 0
		air.TurnMaxTorque = 0
		return
	end

	local projected = velocity:Dot(wish)
	local headroom = math.max(airConfig.MoveSpeed - projected, 0)
	local force = math.clamp(
		airConfig.Force.Min + headroom * airConfig.Force.PerSpeed,
		airConfig.Force.Min,
		airConfig.Force.Max
	)

	movement.CM.MovingDirection = wish
	movement.CM.BaseMoveSpeed = math.max(airConfig.MoveSpeed, projected)
	air.MoveMaxForce = force
	air.TurnMaxTorque = force * airConfig.TorqueScale
end

return Locomotion
