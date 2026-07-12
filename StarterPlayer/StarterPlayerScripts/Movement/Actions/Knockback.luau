local Knockback = {}
Knockback.__index = Knockback

local function isWall(result, up, maxDot)
	return result
		and result.Instance
		and result.Instance:IsA("BasePart")
		and result.Instance.CanCollide
		and math.abs(result.Normal:Dot(up)) <= maxDot
end

function Knockback.new()
	return setmetatable({}, Knockback)
end

function Knockback:Start(movement, data)
	local config = movement.Config.Actions.Knockback
	self.Name = "Knockback"
	self.EndsAt = time() + (data.Duration or config.Duration)
	self.WallDaze = data.WallDaze == true
	self.WallSpeedMin = data.WallSpeedMin or config.MinWallSpeed
	self.DazeDuration = data.DazeDuration or config.DazeDuration
	self.LastPosition = movement.HRP.Position
	self.LastSpeed = movement.Frame.MoveVelocity.Magnitude
	self.DazedUntil = 0

	self.Params = RaycastParams.new()
	self.Params.FilterType = Enum.RaycastFilterType.Exclude
	self.Params.FilterDescendantsInstances = { movement.Character }
	self.Params.RespectCanCollide = true
	self.Params.IgnoreWater = true
end

function Knockback:Update(movement, _dt)
	local config = movement.Config.Actions.Knockback
	local now = time()
	if now >= self.EndsAt then return false end

	if now < self.DazedUntil then
		movement:_OwnAir(0)
		return true
	end

	movement:_OwnAir(config.SteeringScale)
	local position = movement.HRP.Position
	local displacement = position - self.LastPosition
	if self.WallDaze and displacement.Magnitude > 0.05 then
		local result = workspace:Raycast(self.LastPosition, displacement, self.Params)
		if isWall(result, movement.CM.UpDirection, config.WallNormalDotMax)
			and math.max(self.LastSpeed, movement.Frame.MoveVelocity.Magnitude) >= self.WallSpeedMin
		then
			local velocity = movement.HRP.AssemblyLinearVelocity
			movement.HRP.AssemblyLinearVelocity = Vector3.new(
				velocity.X * config.DazeHorizontalCarry,
				math.min(velocity.Y, 0),
				velocity.Z * config.DazeHorizontalCarry
			)
			self.DazedUntil = now + self.DazeDuration
			self.EndsAt = self.DazedUntil
		end
	end

	self.LastPosition = position
	self.LastSpeed = movement.Frame.MoveVelocity.Magnitude
	return true
end

function Knockback:Stop(_movement, _reason) end

return Knockback
