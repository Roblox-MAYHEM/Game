local BaseState = require(script.Parent.Parent.BaseState)
local TweenService = game:GetService("TweenService")

local WallRunning = setmetatable({}, BaseState)
WallRunning.__index = WallRunning

local function projectOnPlane(v: Vector3, normal: Vector3): Vector3
	return v - normal * v:Dot(normal)
end

function WallRunning.new(opts)
	local self = setmetatable(BaseState.new(opts), WallRunning)

	self.elapsed = 0
	self.verticalSpeed = 0
	self.LastExitTime = -math.huge
	self.CooldownUntil = -math.huge

	local attachment = Instance.new("Attachment")
	attachment.Name = "WallRunAttachment"
	attachment.Parent = self.HRP
	self.wallRunAttachment = attachment

	local lv = Instance.new("LinearVelocity")
	lv.Name = "WallRunVelocity"
	lv.Attachment0 = attachment
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = math.huge
	lv.Enabled = false
	lv.VectorVelocity = Vector3.zero
	lv.Parent = attachment.Parent
	self.wallRunVelocity = lv

	local align = Instance.new("AlignOrientation")
	align.Name = "WallRunFacing"
	align.Attachment0 = attachment
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.RigidityEnabled = true
	align.Responsiveness = 200
	align.MaxTorque = math.huge
	align.Enabled = false
	align.Parent = self.HRP
	self.wallRunFacing = align

	self.conn = self.fsm.Landed:Connect(function()
		self.CooldownUntil = -math.huge
	end)

	return self
end

function WallRunning:GetWallHit()
	local rays = self.fsm.Frame.RayStates
	local wishdir = self.fsm.Frame.WishDir

	if wishdir.x < 0 and rays.LeftWall then
		return rays.LeftWall, "Left"
	end

	if wishdir.x > 0 and rays.RightWall then
		return rays.RightWall, "Right"
	end
end
function WallRunning:CanStart()
	local Config = self.Config
	local fsm = self.fsm

	if time() < (fsm.WallRunLockUntil or -math.huge) then return false end

	if time() < self.CooldownUntil or fsm.Frame.Grounded then return false end

	local wall = self:GetWallHit()
	if not wall then return false end

	local up = fsm.CM.UpDirection
	local planarVelocity = fsm.Frame.Velocity - up * fsm.Frame.Velocity:Dot(up)

	return planarVelocity.Magnitude >= Config.MinSpeed
end

function WallRunning:CanContinue()
	local Config = self.Config
	local result = self.elapsed < Config.MaxDuration
		and not self.fsm.Frame.Grounded
		and self:GetWallHit() ~= nil
	if not result then
		print("duration", self.elapsed, Config.MaxDuration)
		print("grounded", self.fsm.Frame.Grounded)
		
		local rays = self.fsm.Frame.RayStates
		local wishdir = self.fsm.Frame.WishDir
		
		print("wall", self:GetWallHit())
		print(wishdir.x, rays.LeftWall, rays.RightWall)
	end
	return result
end

function WallRunning:_computeWallForward(wallNormal: Vector3): Vector3
	local fsm = self.fsm
	local up = fsm.CM.UpDirection
	local look = fsm.HRP.CFrame.LookVector

	local forward = look - wallNormal * look:Dot(wallNormal)
	if forward.Magnitude > 1e-4 then
		return forward.Unit
	end

	local tangent = wallNormal:Cross(up)
	if tangent.Magnitude <= 1e-4 then
		return Vector3.zero
	end

	tangent = tangent.Unit
	if look:Dot(tangent) < 0 then
		tangent = -tangent
	end

	return tangent
end

function WallRunning:_cameraFacingDirection(): Vector3?
	local up = self.fsm.CM.UpDirection
	local camera = workspace.CurrentCamera
	local look = camera and camera.CFrame.LookVector or self.fsm.CM.FacingDirection
	local flat = projectOnPlane(look, up)

	if flat.Magnitude > 0.001 then
		return flat.Unit
	end

	return nil
end

function WallRunning:_lockFacing()
	local dir = self:_cameraFacingDirection()
	if not dir then return end

	local up = self.fsm.CM.UpDirection
	local cframe = CFrame.lookAt(Vector3.zero, dir, up)
	self.wallRunFacing.CFrame = cframe
	self.wallRunFacing.Enabled = true
	self.fsm.CM.FacingDirection = dir
	self.HRP.CFrame = CFrame.lookAt(self.HRP.Position, self.HRP.Position + dir, up)
end

function WallRunning:_unlockFacing()
	self.wallRunFacing.Enabled = false
end

function WallRunning:CanJump()
	local Config = self.Config
	-- it's supposed to be like this to ensure the player can jump shortly after they've wall runned
	local rays = self.fsm.Frame.RayStates
	local wall = rays.LeftWall or rays.RightWall
	if not wall then return end

	if time() > self.LastExitTime + Config.JumpWindow then return end

	local up = self.fsm.CM.UpDirection
	local forward = self:_computeWallForward(wall.Normal)
	if forward == Vector3.zero then return end

	local velocity = self.fsm.Frame.Velocity
	local strength = Config.JumpStrength

	local targetOutSpeed = math.max(velocity:Dot(wall.Normal), strength)
	local targetUpSpeed = math.max(velocity:Dot(up), strength)
	local targetForwardSpeed = math.max(math.max(velocity:Dot(forward), 0), Config.MinSpeed)

	local velocity =
		(wall.Normal * targetOutSpeed)
		+ (up * targetUpSpeed)
		+ (forward * targetForwardSpeed)

	return {
		Kind = "Wall",
		Velocity = velocity,
		WallRunLockSeconds = 0.10,
	}
end

function WallRunning:OnEnter()
	print("enter")
	local Config = self.Config
	self.elapsed = 0
	self.LastExitTime = math.huge
	self.verticalSpeed = Config.InitialVerticalSpeed
	self.fsm.CM.BaseMoveSpeed = Config.BaseMoveSpeed
	self.fsm.Humanoid.AutoRotate = false
	self:_lockFacing()

	local lv = self.wallRunVelocity
	lv.VectorVelocity = Vector3.zero
	lv.Enabled = true

	if self.Sounds and self.Sounds.WallRun then
		self.Sounds.WallRun.Looped = true
		self.Sounds.WallRun:Play()
	end

	local wall, side = self:GetWallHit()

	if side == "Right" and self.Animations.WallRunR then
		self.Animations.WallRunR:Play()
	elseif side == "Left" and self.Animations.WallRunL then
		self.Animations.WallRunL:Play()
	end
end

function WallRunning:OnUpdate(dt: number)
	local Config = self.Config
	self.elapsed += dt

	local wall = self:GetWallHit()
	local lv = self.wallRunVelocity

	if not wall then
		lv.VectorVelocity = Vector3.zero
		return
	end

	local wallForward = self:_computeWallForward(wall.Normal)
	if wallForward == Vector3.zero then
		lv.VectorVelocity = Vector3.zero
		return
	end

	self:_lockFacing()

	self.verticalSpeed = math.max(
		self.verticalSpeed - Config.VerticalDecay * dt,
		Config.MinVerticalSpeed
	)

	lv.VectorVelocity =
		(wallForward * Config.RunSpeed)
		+ (self.fsm.CM.UpDirection * self.verticalSpeed)
		+ (-wall.Normal * Config.StimeSpeed)
end

function WallRunning:OnExit(_nextState)
	print("exit")
	local Config = self.Config
	self.LastExitTime = time()
	self.CooldownUntil = time() + Config.Cooldown

	local lv = self.wallRunVelocity
	lv.VectorVelocity = Vector3.zero
	lv.Enabled = false
	self:_unlockFacing()

	if self.Sounds and self.Sounds.WallRun then
		local sound = self.Sounds.WallRun
		local startVolume = sound.Volume

		local tween = TweenService:Create(
			sound,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Volume = 0}
		)

		tween:Play()
		tween.Completed:Once(function()
			sound:Stop()
			sound.Volume = startVolume
		end)
	end

	if self.Animations then
		self.Animations.WallRunL:Stop()
		self.Animations.WallRunR:Stop()
	end

	self.fsm.Humanoid.AutoRotate = true
end

return WallRunning
