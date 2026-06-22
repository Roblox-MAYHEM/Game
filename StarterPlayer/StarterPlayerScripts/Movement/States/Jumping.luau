local BaseState = require(script.Parent.Parent.BaseState)

local Jumping = setmetatable({}, BaseState)
Jumping.__index = Jumping

function Jumping.new(opts)
	local self = setmetatable(BaseState.new(opts), Jumping)
	self.CooldownUntil = 0
	self.MaxAirJumps = self.Config.DoubleJumps or 0
	self.AirJumps = 0
	self.JumpType = ""

	self.conn = self.fsm.Landed:Connect(function()
		self.AirJumps = 0
	end)

	return self
end

function Jumping:_ApplyVerticalJump(targetVerticalSpeed)
	local currentVertical = self.fsm.Frame.Velocity:Dot(self.fsm.CM.UpDirection)

	local deltaV = math.max(targetVerticalSpeed - currentVertical, 0)
	self.HRP:ApplyImpulse(self.fsm.CM.UpDirection * deltaV * self.HRP.AssemblyMass)
end

function Jumping:CanStart()
	local Config = self.Config
	local now = time()
	if now < self.CooldownUntil then return nil end

	local frame = self.fsm.Frame
	local lastGroundedAt = frame.LastGroundedAt or -math.huge

	if frame.Grounded then return {Type = "Ground"} end

	if (now - lastGroundedAt) <= Config.CoyoteTime then return {Type = "Coyote"} end

	if self.AirJumps < self.MaxAirJumps then return {Type = "Air"} end

	return nil
end

function Jumping:OnEnter(data)
	local Config = self.Config
	if data.Type == "Air" then self.AirJumps += 1 end

	self.fsm.WallRunLockUntil = time() + (data.WallRunLockSeconds or 0.10)

	if data.Velocity then
		local delta = data.Velocity - self.fsm.Frame.Velocity
		self.HRP:ApplyImpulse(delta * self.HRP.AssemblyMass)
	else
		self:_ApplyVerticalJump(Config.JumpStrength)
	end

	self.CooldownUntil = time() + Config.Cooldown
	self.fsm.CM.ActiveController = self.fsm.AirController
	self.fsm.CM.BaseMoveSpeed = (data.AirEntrySpeed or Config.AirEntrySpeed) / self.fsm.EquipLoad
end

function Jumping:OnExit()
end

return Jumping
