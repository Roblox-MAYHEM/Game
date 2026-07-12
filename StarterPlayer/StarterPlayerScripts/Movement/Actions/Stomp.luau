local Stomp = {}
Stomp.__index = Stomp

function Stomp.new()
	return setmetatable({}, Stomp)
end

function Stomp:Start(movement, data)
	local config = data.Config or movement.Config.Actions.Stomp
	self.Name = "Stomp"
	self.Config = config
	self.FastestDownwardSpeed = 0

	local up = movement.CM.UpDirection
	local velocity = movement.HRP.AssemblyLinearVelocity
	local vertical = velocity:Dot(up)
	if vertical > 0 then
		movement.HRP.AssemblyLinearVelocity = velocity - up * vertical
	end
	movement:ApplyImpulse(-up, config.Strength)
end

function Stomp:Update(movement, _dt)
	local downward = math.max(-movement.Frame.Velocity:Dot(movement.CM.UpDirection), 0)
	self.FastestDownwardSpeed = math.max(self.FastestDownwardSpeed, downward)
	movement:_OwnAir(0)

	if movement.Frame.JustLanded then
		movement.StompLanded:Fire(self.FastestDownwardSpeed)
		return false
	end
	return true
end

function Stomp:Stop(_movement, _reason) end

return Stomp
