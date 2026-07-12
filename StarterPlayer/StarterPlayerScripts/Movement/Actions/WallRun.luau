local WallRun = {}
WallRun.__index = WallRun

local function tangent(normal: Vector3, up: Vector3, velocity: Vector3): Vector3
	local direction = normal:Cross(up)
	if direction:Dot(velocity) < 0 then direction = -direction end
	return direction.Unit
end

function WallRun.new()
	return setmetatable({}, WallRun)
end

function WallRun:Start(movement, data)
	local config = movement.Config.Actions.WallRun
	self.Name = "WallRun"
	self.Side = data.Side
	self.EndsAt = time() + config.MaxDuration
	self.VerticalSpeed = math.max(movement.Frame.Velocity:Dot(movement.CM.UpDirection), config.LiftStrength)
	movement.Humanoid.AutoRotate = false

	if movement.Sounds.WallRun then
		movement.Sounds.WallRun.Looped = true
		movement.Sounds.WallRun:Play()
	end
end

function WallRun:GetWall(movement)
	return if self.Side == "Left" then movement.Frame.RayStates.LeftWall else movement.Frame.RayStates.RightWall
end

function WallRun:Jump(movement)
	local wall = self:GetWall(movement)
	if not wall then return false end

	local config = movement.Config.Actions.WallRun
	movement:ApplyImpulse(wall.Normal, config.JumpStrength)
	movement:ApplyImpulse(movement.CM.UpDirection, config.JumpStrength)
	return true
end

function WallRun:Update(movement, dt)
	local wall = self:GetWall(movement)
	if not wall or movement.Frame.Grounded or time() >= self.EndsAt then return false end

	local config = movement.Config.Actions.WallRun
	local direction = tangent(wall.Normal, movement.CM.UpDirection, movement.Frame.MoveVelocity)
	local desired = direction * config.RunSpeed
	local missing = desired - movement.Frame.MoveVelocity
	if missing.Magnitude > 0.01 then
		movement:ApplyImpulse(missing.Unit, math.min(missing.Magnitude, config.RunSpeed) * dt * 8)
	end

	self.VerticalSpeed = math.max(self.VerticalSpeed - config.VerticalDecay * dt, config.MinVerticalSpeed)
	local currentVertical = movement.Frame.Velocity:Dot(movement.CM.UpDirection)
	if self.VerticalSpeed > currentVertical then
		movement:ApplyImpulse(movement.CM.UpDirection, (self.VerticalSpeed - currentVertical) * dt * 5)
	end
	movement:ApplyImpulse(-wall.Normal, config.AdhesionStrength * dt)
	movement:_OwnAir(0)
	movement.CM.FacingDirection = direction
	return true
end

function WallRun:Stop(movement, _reason)
	movement.Humanoid.AutoRotate = true
	movement.WallRunCooldownUntil = time() + movement.Config.Actions.WallRun.Cooldown
	if movement.Sounds.WallRun then movement.Sounds.WallRun:Stop() end
end

return WallRun
