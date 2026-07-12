local Frame = require(script.Parent:WaitForChild("Frame"))

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(fsm)
	local self = {
		fsm = fsm,
		lastTiltSign = 0,
		moveSpeed = 0,
	}

	return setmetatable(self, Runtime)
end

function Runtime:UpdateFacing()
	local fsm = self.fsm
	if not fsm.Humanoid.AutoRotate then return end

	if fsm.Humanoid.MoveDirection.Magnitude > 0.1 and fsm.Frame.MoveVelocity.Magnitude > 0.1 then
		fsm.CM.FacingDirection = fsm.Frame.MoveVelocity.Unit
	else
		local look = workspace.CurrentCamera.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		fsm.CM.FacingDirection = flatLook.Magnitude > 0.1 and flatLook.Unit or look
	end
end

function Runtime:UpdateTilt()
	local fsm = self.fsm
	local camera = workspace.CurrentCamera
	if not camera or not fsm.ViewModel or not fsm.CM then return end

	local inputX = fsm.Frame.WishDir.X
	local sign = inputX > 0 and 1 or (inputX < 0 and -1 or 0)

	local right = Frame.projectOnPlane(camera.CFrame.RightVector, fsm.CM.UpDirection)
	right = right.Magnitude > 0.001 and right.Unit or Vector3.xAxis

	local lateralSpeed = fsm.Frame.MoveVelocity:Dot(right)
	local fullSpeed = math.max(fsm.CM.BaseMoveSpeed, fsm.Humanoid.WalkSpeed, 16)

	local alpha = 0
	if sign ~= 0 then
		local aligned = math.clamp((sign * lateralSpeed) / fullSpeed, -1, 1)
		local oppose = math.sqrt((1 - aligned) * 0.5)
		local amount = fsm.Config.TiltBase + oppose * fsm.Config.TiltOppose
		alpha = sign * math.clamp(amount, 0, 1)
	end

	local impulse = 0
	if sign ~= 0 and sign ~= self.lastTiltSign then
		impulse = sign * (fsm.Config.TiltSnap or 0.14)
	end

	fsm.ViewModel:SetTilt(alpha, impulse)
	self.lastTiltSign = sign
end

function Runtime:UpdateSpread()
	local fsm = self.fsm
	local spread = 0

	local state = fsm.States[fsm.state]
	if state and state.GetSpread then spread = state:GetSpread() end

	if math.abs(spread - fsm.CurrentSpread) > 0.001 then
		fsm.CurrentSpread = spread
		fsm.SpreadChanged:Fire(spread)
	end
end

function Runtime:GetMoveVelocity(): Vector3
	return Frame.projectOnPlane(self.fsm.HRP.AssemblyLinearVelocity, self.fsm.CM.UpDirection)
end

function Runtime:SnapMoveSpeed(speed: number)
	self.moveSpeed = math.max(self.moveSpeed, speed)
end

function Runtime:GetMoveSpeed(defaultSpeed: number, dir: Vector3?, dt: number): number
	local config = self.fsm.Config
	local target = defaultSpeed
	local bonus = config.MomentumBonus or 0
	local smoothing = config.MomentumSmoothing or 10

	if dir and dir ~= Vector3.zero then
		target = math.max(defaultSpeed, self:GetMoveVelocity():Dot(dir))
		target = math.min(target, defaultSpeed + bonus)
	end

	local current = math.max(defaultSpeed, self.moveSpeed > 0 and self.moveSpeed or defaultSpeed)
	local alpha = math.clamp(dt * smoothing, 0, 1)
	self.moveSpeed = current + (target - current) * alpha

	if math.abs(self.moveSpeed - defaultSpeed) < 0.05 then
		self.moveSpeed = defaultSpeed
	end

	return self.moveSpeed
end

function Runtime:SetWeight(weight)
	local fsm = self.fsm
	local p = fsm._basePhysProps
	if not p or not fsm.HRP or not fsm.BaseMass or not fsm.BaseVolume then return end

	weight = math.max(tonumber(weight) or 1, 0.1)
	local density = (fsm.BaseMass * weight) / fsm.BaseVolume

	fsm.HRP.CustomPhysicalProperties = PhysicalProperties.new(
		density,
		p.Friction,
		p.Elasticity,
		p.FrictionWeight,
		p.ElasticityWeight
	)

	fsm.Weight = weight
	-- Temporary bridge while old locomotion states are removed. Weight is now
	-- represented by assembly mass only, never by a second speed divisor.
	fsm.EquipLoad = 1
end

function Runtime:SetDoubleJumps(doubleJumps)
	if self.fsm.States.Jumping then
		self.fsm.States.Jumping.MaxAirJumps = doubleJumps
	end
end

return Runtime
