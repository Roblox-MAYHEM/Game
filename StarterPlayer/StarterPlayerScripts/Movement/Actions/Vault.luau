local Vault = {}
Vault.__index = Vault

function Vault.new()
	return setmetatable({}, Vault)
end

function Vault:Start(movement, data)
	local config = movement.Config.Actions.Vault
	self.Name = "Vault"
	self.Direction = data.Direction
	self.EndsAt = time() + config.Duration

	local height = math.max(data.TopPosition.Y - movement.HRP.Position.Y, 0)
	local lift = math.clamp(
		math.sqrt(2 * workspace.Gravity * height),
		config.MinLiftStrength,
		config.MaxLiftStrength
	)
	local forward = math.max(config.MinForwardStrength, movement.Frame.MoveVelocity:Dot(self.Direction))

	movement.Humanoid.AutoRotate = false
	movement:ApplyImpulse(self.Direction, forward)
	movement:ApplyImpulse(movement.CM.UpDirection, lift)
end

function Vault:Update(movement, _dt)
	movement:_OwnAir(0)
	movement.CM.FacingDirection = self.Direction
	return time() < self.EndsAt
end

function Vault:Stop(movement, _reason)
	movement.Humanoid.AutoRotate = true
end

return Vault
