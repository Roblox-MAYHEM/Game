local Lunge = {}
Lunge.__index = Lunge

function Lunge.new()
	return setmetatable({}, Lunge)
end

function Lunge:Start(movement, data)
	local config = data.Config or movement.Config.Actions.Lunge
	self.Name = "Lunge"
	self.EndsAt = time() + config.Duration
	self.SteeringScale = config.SteeringScale or 0
	movement.Humanoid.AutoRotate = false
	if config.Gain and config.MaxSpeed then
		movement:Boost(data.Direction, config.Gain, config.MaxSpeed)
	else
		movement:ApplyImpulse(data.Direction, config.Strength)
	end
end

function Lunge:Update(movement, _dt)
	movement:_OwnAir(self.SteeringScale)
	return time() < self.EndsAt
end

function Lunge:Stop(movement, _reason)
	movement.Humanoid.AutoRotate = true
end

return Lunge
