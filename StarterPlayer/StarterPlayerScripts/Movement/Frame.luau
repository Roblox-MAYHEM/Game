local Frame = {}
Frame.__index = Frame

function Frame.projectOnPlane(vec: Vector3, normal: Vector3): Vector3
	local unit = normal.Unit
	return vec - vec:Dot(unit) * unit
end

function Frame.new(fsm, controls, cast)
	local self = {
		fsm = fsm,
		Controls = controls,
		Cast = cast,

		Data = {
			WishDir = Vector3.zero,
			WorldWishDir = Vector3.zero,

			Velocity = Vector3.zero,
			MoveVelocity = Vector3.zero,

			Grounded = false,
			GroundNormal = Vector3.yAxis,
			SlopeAngle = 0,
			SlopeDownDir = Vector3.zero,
			SlopeSliding = false,
			WasGrounded = false,
			JustLanded = false,
			JustLeftGround = false,

			LastGroundedAt = -math.huge,

			RayStates = {},
		},
	}

	return setmetatable(self, Frame)
end

function Frame:Update(_dt: number)
	local fsm = self.fsm
	local frame = self.Data
	local up = fsm.CM.UpDirection

	frame.WasGrounded = frame.Grounded
	frame.WishDir = self.Controls:GetMoveVector()

	local worldWish = Frame.projectOnPlane(workspace.CurrentCamera.CFrame:VectorToWorldSpace(frame.WishDir), up)
	frame.WorldWishDir = worldWish.Magnitude > 0.1 and worldWish.Unit or Vector3.zero

	frame.Velocity = fsm.HRP.AssemblyLinearVelocity
	frame.MoveVelocity = Frame.projectOnPlane(frame.Velocity, up)

	local rays = frame.RayStates
	table.clear(rays)
	if self.Cast.StepDebugVisuals then
		self.Cast:StepDebugVisuals()
	end

	rays.Ground = self.Cast:GroundCheck()

	if fsm.state == "Running" and frame.WorldWishDir ~= Vector3.zero then
		rays.FrontWall = self.Cast:FrontCheck()
	elseif fsm.state == "Air" or fsm.state == "WallRunning" then
		rays.LeftWall = self.Cast:LeftSideCheck()
		rays.RightWall = self.Cast:RightSideCheck()
	end

	local ground = rays.Ground
	frame.Grounded = ground ~= nil
	frame.JustLanded = not frame.WasGrounded and frame.Grounded
	frame.JustLeftGround = frame.WasGrounded and not frame.Grounded

	if ground then
		local downhill = Frame.projectOnPlane(-up, ground.Normal)

		frame.GroundNormal = ground.Normal
		frame.SlopeAngle = math.deg(math.acos(math.clamp(ground.Normal:Dot(up), -1, 1)))
		frame.SlopeDownDir = downhill.Magnitude > 0.001 and downhill.Unit or Vector3.zero
		frame.SlopeSliding = frame.SlopeAngle >= (fsm.Config.SlopeSlideAngle or 43) and frame.SlopeDownDir ~= Vector3.zero

		fsm.GroundSensor.SensedPart = ground.Instance
		fsm.GroundSensor.HitNormal = ground.Normal
		fsm.GroundSensor.HitFrame = CFrame.new(ground.Position)
		fsm.CM.ActiveController = fsm.GroundController

		frame.LastGroundedAt = time()

		if frame.JustLanded then fsm.Landed:Fire() end
	else
		frame.GroundNormal = up
		frame.SlopeAngle = 0
		frame.SlopeDownDir = Vector3.zero
		frame.SlopeSliding = false

		fsm.GroundSensor.SensedPart = nil
		fsm.CM.ActiveController = fsm.AirController
	end
end

return Frame
