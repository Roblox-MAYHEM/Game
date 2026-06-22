local BaseState = require(script.Parent.Parent.BaseState)
local Lunging = setmetatable({}, BaseState)
Lunging.__index = Lunging

local Events = game:GetService("ReplicatedStorage").Events

function Lunging.new(opts)
	return setmetatable(BaseState.new(opts), Lunging)
end

function Lunging:OnEnter()
	local Config = self.Config
	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
	self.Humanoid.AutoRotate = false

	self._epsilon = 0
	self._startCF = self.fsm.HRP.CFrame
	self._params = RaycastParams.new()
	self._params.CollisionGroup = "NoCollision"

	self.fsm.GroundController.Friction = 0

	local cam = workspace.CurrentCamera.CFrame.LookVector
	local horiz = Vector3.new(cam.X, 0, cam.Z)
	local downBias = math.min(cam.Y, 0)
	if self.fsm.Frame.Grounded then
		downBias = math.max(cam.Y, 0)
	end
	self._dir = (horiz + Vector3.new(0, downBias, 0)).Unit

	if Config.PHASE_THROUGH_PLAYERS then
		Events.NoCollideRequest:FireServer(true)
	end
end

function Lunging:OnUpdate(dt)
	local Config = self.Config
	self._epsilon += dt

	local progress = (self._epsilon / Config.TIME) ^ Config.EASE
	local targetPos = self._startCF.Position + self._dir * (progress * Config.DISTANCE)
	local displacement = targetPos - self.fsm.HRP.Position

	local result = workspace:Raycast(
		self.fsm.HRP.Position,
		displacement.Unit * displacement.Magnitude,
		self._params
	)

	if result then
		self.fsm.HRP.CFrame = CFrame.new(
			result.Position - self._dir * 2,
			result.Position + self._dir
		)
	else
		self.fsm.HRP.CFrame = CFrame.new(targetPos, targetPos + self._dir)
	end
end

function Lunging:OnExit()
	local Config = self.Config
	local cur = self.fsm.HRP.AssemblyLinearVelocity
	self.fsm.HRP.AssemblyLinearVelocity = Vector3.new(cur.X * Config.CARRY, math.max(cur.Y, 1), cur.Z * Config.CARRY)

	self.fsm.GroundController.Friction = self.fsm.BaseFriction

	self._epsilon = 0
	self._dir = nil
	self.Humanoid.AutoRotate = true

	if Config.PHASE_THROUGH_PLAYERS then
		Events.NoCollideRequest:FireServer(false)
	end
end

function Lunging:IsFinished()
	local Config = self.Config
	return self._epsilon >= Config.TIME
end

return Lunging
