local BaseState = require(script.Parent.Parent.BaseState)

local Landed = setmetatable({}, BaseState)
Landed.__index = Landed

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function flatUnit(v: Vector3, fallback: Vector3): Vector3
	local f = flat(v)
	if f.Magnitude > 0.001 then
		return f.Unit
	end

	local fb = flat(fallback)
	if fb.Magnitude > 0.001 then
		return fb.Unit
	end

	return Vector3.new(0, 0, -1)
end

function Landed.new(opts)
	local self = setmetatable(BaseState.new(opts), Landed)
	self.Time = 0
	self.EntrySpeed = 0
	self.HasDrift = false
	self.DriftDir = Vector3.new(0, 0, -1)
	self.Duration = 0
	return self
end

function Landed:CanStart()
	return self.fsm.Frame.JustLanded
end

function Landed:OnEnter(_data)
	local Config = self.Config
	local frame = self.fsm.Frame
	local moveVelocity = self.fsm.Runtime:GetMoveVelocity()

	self.Time = 0
	self.Duration = Config.Duration
	self.EntrySpeed = moveVelocity.Magnitude
	self.HasDrift = self.EntrySpeed >= Config.MinEntrySpeed
	self.DriftDir = flatUnit(moveVelocity, self.fsm.CM.FacingDirection)

	if self.Animations.Landed then
		self.Animations.Landed:Play()
	end

	local landSpeed = math.max(0, -frame.Velocity:Dot(self.fsm.CM.UpDirection))
	if self.ViewModel then
		local a = math.log(1 + (Config.RollSteepness-1) * math.clamp(
			(landSpeed - Config.MinEntrySpeed) / (Config.MaxImpactSpeed - Config.MinEntrySpeed),
			0, 1
			)) / math.log(Config.RollSteepness)

		self.ViewModel:AdjustSpring("recoil", Vector3.new(
			Config.MaxPitch * a,
			0,
			-Config.MaxRoll * a
			))
	end

	if self.Sounds and self.Sounds.LandThump then
		self.Sounds.LandThump.Volume = math.clamp(landSpeed / Config.MaxImpactSpeed, 0.4, 4)
		self.Sounds.LandThump:Play()
	end

	if not self.HasDrift then return end

	self.fsm.CM.MovingDirection = self.DriftDir
	self.fsm.CM.FacingDirection = self.DriftDir
	self.fsm.CM.BaseMoveSpeed =
		math.max(self.EntrySpeed, Config.MinCarrySpeed) / self.fsm.EquipLoad
end

function Landed:OnUpdate(dt)
	local Config = self.Config
	self.Time += dt

	if not self.HasDrift then
		return
	end

	local inputDir = self.fsm.Frame.WorldWishDir

	if inputDir ~= Vector3.zero then
		local blended = self.DriftDir:Lerp(inputDir, math.clamp(dt * Config.TurnLerp, 0, 1))
		if blended.Magnitude > 0.001 then
			self.DriftDir = blended.Unit
		end
	end

	local carrySpeed = math.max(Config.MinCarrySpeed, self.EntrySpeed - Config.SpeedBleed * self.Time)

	self.fsm.CM.MovingDirection = self.DriftDir
	self.fsm.CM.FacingDirection = self.DriftDir
	self.fsm.CM.BaseMoveSpeed = carrySpeed / self.fsm.EquipLoad
end

function Landed:OnExit(_nextState)
	self.Time = 0
	self.EntrySpeed = 0
	self.HasDrift = false
	self.DriftDir = Vector3.new(0, 0, -1)
	self.Duration = 0
end

function Landed:IsFinished()
	return (not self.HasDrift) or self.Time >= self.Duration
end

return Landed
