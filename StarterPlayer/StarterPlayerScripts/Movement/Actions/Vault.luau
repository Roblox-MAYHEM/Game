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
	self.JumpAt = time() + config.JumpDelay

	local currentForward = movement.Frame.MoveVelocity:Dot(self.Direction)
	local currentUp = movement.Frame.Velocity:Dot(movement.CM.UpDirection)

	movement.Humanoid.AutoRotate = false
	movement:Boost(self.Direction, config.Speed - currentForward, config.Speed)
	movement:ApplyImpulse(movement.CM.UpDirection, math.max(config.LiftSpeed - currentUp, 0))
	movement.Animations.Vaulting:SetDuration(config.Duration)
	movement.Animations.Vaulting:Play()
end

function Vault:Update(movement, _dt)
	movement:_OwnAir(0)
	movement.CM.FacingDirection = self.Direction
	local wantsJump = movement.SpaceBufferedUntil >= time() or movement:IsJumpHeld()
	if time() >= self.JumpAt and wantsJump then
		local config = movement.Config.Actions.Vault
		movement.SpaceBufferedUntil = 0
		movement.JumpCooldownUntil = time() + movement.Config.Jump.Cooldown
		local currentForward = movement.HRP.AssemblyLinearVelocity:Dot(self.Direction)
		movement:Boost(self.Direction, config.Speed - currentForward, config.Speed)
		local up = movement.CM.UpDirection
		local currentUp = movement.HRP.AssemblyLinearVelocity:Dot(up)
		movement:ApplyImpulse(up, math.max(movement.Config.Jump.Strength - currentUp, 0))
		return false
	end
	return time() < self.EndsAt
end

function Vault:Stop(movement, _reason)
	movement.Humanoid.AutoRotate = true
	movement.Animations.Vaulting:Stop()
end

return Vault
