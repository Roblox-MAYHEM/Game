local BaseState = require(script.Parent.Parent.BaseState)
local Running = setmetatable({}, BaseState)
Running.__index = Running

local WALL_NORMAL_DOT = 0.2

local function flatten(dir, up)
	local projected = dir - up * dir:Dot(up)
	return projected.Magnitude > 0.001 and projected.Unit or Vector3.zero
end

function Running.new(opts)
	return setmetatable(BaseState.new(opts), Running)
end

function Running:OnEnter(_data)
	if self.Animations.Running then
		self.Animations.Running:Play()
	end
end

function Running:OnUpdate(dt)
	local Config = self.Config
	local frame = self.fsm.Frame
	local gc = self.fsm.GroundController
	local inputDir = frame.WorldWishDir
	local dir = inputDir
	local speed = Config.MoveSpeed
	local frontWall = frame.RayStates.FrontWall
	local up = self.fsm.CM.UpDirection

	gc.AccelerationTime = Config.AccelerationTime
	gc.DecelerationTime = Config.DecelerationTime
	gc.Friction = Config.Friction
	gc.TurnSpeedFactor = Config.TurnSpeedFactor

	if
		frontWall
		and frontWall.Distance < 3.0
		and inputDir ~= Vector3.zero
		and frontWall.Normal:Dot(up) <= WALL_NORMAL_DOT
	then
		local n = flatten(frontWall.Normal, up)
		if n.Magnitude > 0.001 then
			local into = dir:Dot(-n)
			if into > 0 then
				dir = dir + n * into
				dir = dir.Magnitude > 0.001 and dir.Unit or Vector3.zero
			end
		end
	end

	if inputDir ~= Vector3.zero then
		speed = self.fsm.Runtime:GetMoveSpeed(Config.MoveSpeed, dir, dt)
	elseif frame.SlopeSliding then
		dir = flatten(frame.SlopeDownDir, up)
		speed = self.fsm.Runtime:GetMoveSpeed(self.fsm.Config.SlopeSlideSpeed or Config.MoveSpeed, dir, dt)
	else
		self.fsm.Runtime:GetMoveSpeed(Config.MoveSpeed, nil, dt)
	end

	self.fsm.CM.MovingDirection = dir
	self.fsm.CM.BaseMoveSpeed = speed / self.fsm.EquipLoad
end

function Running:OnExit(_nextState)
	if self.Animations.Running then
		self.Animations.Running:Stop()
	end
end

function Running:GetSpread()
	local Config = self.Config
	local speed = self.fsm.Runtime:GetMoveVelocity().Magnitude

	local maxSpeed = math.max(Config.MoveSpeed / self.fsm.EquipLoad, 0.01)
	local alpha = math.clamp(speed / maxSpeed, 0, 1)

	return Config.BulletSpread * alpha
end

return Running
