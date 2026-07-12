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
	self.JumpAt = time() + config.JumpExitDelay

	local currentForward = movement.Frame.MoveVelocity:Dot(self.Direction)
	local gain = math.max(config.MinForwardSpeed - currentForward, config.ForwardGain)
	local currentUp = movement.Frame.Velocity:Dot(movement.CM.UpDirection)

	movement.Humanoid.AutoRotate = false
	if data.TooClose then movement:ApplyImpulse(-self.Direction, config.CloseNudge) end
	movement:Boost(self.Direction, gain, config.MaxForwardSpeed)
	movement:ApplyImpulse(movement.CM.UpDirection, math.max(config.LiftSpeed - currentUp, 0))
end

function Vault:Update(movement, _dt)
	movement:_OwnAir(0)
	movement.CM.FacingDirection = self.Direction
	local wantsJump = movement.SpaceBufferedUntil >= time() or movement:IsJumpHeld()
	if time() >= self.JumpAt and wantsJump then
		local config = movement.Config.Actions.Vault
		movement.SpaceBufferedUntil = 0
		movement.JumpCooldownUntil = time() + movement.Config.Jump.Cooldown
		movement:Boost(self.Direction, config.JumpForwardGain, config.JumpForwardCap)
		local up = movement.CM.UpDirection
		local currentUp = movement.HRP.AssemblyLinearVelocity:Dot(up)
		movement:ApplyImpulse(up, math.max(movement.Config.Jump.Strength - currentUp, 0))
		return false
	end
	return time() < self.EndsAt
end

function Vault:Stop(movement, _reason)
	movement.Humanoid.AutoRotate = true
end

return Vault
