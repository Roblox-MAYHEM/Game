local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Events = ReplicatedStorage.Events
local Bindables = StarterPlayer.Bindables

local Signal = require(ReplicatedStorage.Packages.Signal)
local AnimationController = require(StarterPlayer.Libraries.AnimationController)
local Frame = require(script.Parent.Frame)
local Locomotion = require(script.Parent.Locomotion)
local Cast = require(script.Parent.RaycastModule)

local Data = script.Parent.Data
local ConfigModule = Data.Config
local Actions = {
	Vault = require(script.Parent.Actions.Vault),
	WallRun = require(script.Parent.Actions.WallRun),
	Knockback = require(script.Parent.Actions.Knockback),
	Lunge = require(script.Parent.Actions.Lunge),
	Stomp = require(script.Parent.Actions.Stomp),
}

local CONTROLLERS = {
	"GroundController",
	"AirController",
	"ClimbController",
	"WallRunSensor",
	"GroundSensor",
}

local Movement = {
	Priority = 1,
	Ready = false,
	Enabled = false,
	Weight = 1,
	CurrentSpread = 0,
	Landed = Signal.new("Landed"),
	SpreadChanged = Signal.new("SpreadChanged"),
	StompLanded = Signal.new("StompLanded"),
}

local function requireFresh(module)
	if not RunService:IsStudio() then return require(module) end
	local clone = module:Clone()
	clone.Name = module.Name .. "_HotReload"
	clone.Parent = module.Parent
	local result = require(clone)
	clone:Destroy()
	return result
end

local function assetId(id)
	local value = tostring(id)
	return value:match("^%d+$") and ("rbxassetid://" .. value) or value
end

local function loadPresentation(self, trove)
	self.Animations = {}
	for name, info in pairs(requireFresh(Data.Animations)) do
		if info.HumanoidState then
			self.Animations[name] = {
				Play = function() self.Humanoid:ChangeState(Enum.HumanoidStateType[info.HumanoidState]) end,
				Stop = function() end,
			}
		else
			local track = if #info == 3
				then AnimationController.new(info[1], info[2], info[3])
				else AnimationController.new(info[1], info[3], info[4], info[2])
			self.Animations[name] = trove:Add(track)
		end
	end

	self.Sounds = {}
	for name, info in pairs(requireFresh(Data.Sounds)) do
		local source = typeof(info) == "table" and info or { Id = info }
		local sound = trove:Add(Instance.new("Sound"))
		sound.Name = name
		sound.SoundId = assetId(source.Id or source[1])
		sound.Volume = source.Volume or source[2] or 1
		sound.Looped = source.Looped or false
		sound.Parent = self.Character
		self.Sounds[name] = sound
	end
end

function Movement:_GetControllers(cm)
	for _, name in ipairs(CONTROLLERS) do
		self[name] = cm:WaitForChild(name, 5)
		if not self[name] then return false end
	end
	return true
end

function Movement:_OwnAir(steeringScale)
	local scale = steeringScale or 0
	local air = self.AirController
	local force = self.Config.Air.Force.Max * scale
	self.CM.ActiveController = air
	self.CM.MovingDirection = scale > 0 and self.Frame.WorldWishDir or Vector3.zero
	self.CM.BaseMoveSpeed = scale > 0 and self.Config.Air.MoveSpeed or 0
	air.MaintainLinearMomentum = true
	air.MaintainAngularMomentum = false
	air.MoveMaxForce = force
	air.TurnMaxTorque = force * self.Config.Air.TorqueScale
end

function Movement:StartAction(name, data)
	local module = Actions[name]
	if not module or not self.Ready then return false end
	self:StopAction("Replaced")

	local action = module.new()
	self.ActiveAction = action
	action:Start(self, data or {})
	return true
end

function Movement:StopAction(reason)
	local action = self.ActiveAction
	if not action then return end
	self.ActiveAction = nil
	action:Stop(self, reason or "Finished")
end

function Movement:ApplyImpulse(direction: Vector3, strength: number)
	if not self.Ready or typeof(direction) ~= "Vector3" or direction.Magnitude <= 0.001 then return end
	if typeof(strength) ~= "number" or strength == 0 then return end
	self.HRP:ApplyImpulse(direction.Unit * strength * self.BaseMass)
end

function Movement:Boost(direction: Vector3, gain: number, maxSpeed: number)
	if not self.Ready or typeof(direction) ~= "Vector3" or direction.Magnitude <= 0.001 then return 0 end
	gain = math.max(tonumber(gain) or 0, 0)
	maxSpeed = math.max(tonumber(maxSpeed) or math.huge, 0)
	local unit = direction.Unit
	local current = self.HRP.AssemblyLinearVelocity:Dot(unit)
	local effectiveWeight = self.EffectiveWeight or 1
	local strength = math.min(gain, math.max(maxSpeed - current, 0) * effectiveWeight)
	if strength > 0 then self:ApplyImpulse(unit, strength) end
	return strength / effectiveWeight
end

function Movement:SetWeight(weight)
	if not self.Ready then return end
	weight = math.max(tonumber(weight) or 1, 0.1)
	local p = self._basePhysProps
	local exaggeration = self.Config.Movement.WeightExaggeration or 1
	local effectiveWeight = math.max(1 + (weight - 1) * exaggeration, 0.1)
	local density = (self.BaseMass * effectiveWeight) / self.BaseVolume
	self.HRP.CustomPhysicalProperties = PhysicalProperties.new(
		density,
		p.Friction,
		p.Elasticity,
		p.FrictionWeight,
		p.ElasticityWeight
	)
	self.Weight = weight
	self.EffectiveWeight = effectiveWeight
end

function Movement:_HandleLanding()
	local landing = self.Config.Ground.HardLanding
	local downSpeed = self.PeakDownwardSpeed or 0
	self.PeakDownwardSpeed = 0
	if downSpeed < landing.MinDownSpeed then return end

	local alpha = math.clamp(
		(downSpeed - landing.MinDownSpeed) / math.max(landing.MaxDownSpeed - landing.MinDownSpeed, 0.01),
		0,
		1
	)
	local buffered = self.SpaceBufferedUntil >= time()
	local responseScale = buffered and landing.BufferedJumpScale or 1
	local shock = alpha * responseScale
	self.LandingShockStrength = shock
	self.LandingShockUntil = time() + landing.ShockDuration

	if shock > 0 then
		self.Camera:CameraShake(
			"ShakeOnce",
			landing.CameraMagnitude * shock,
			landing.CameraRoughness,
			0,
			landing.CameraFadeOut,
			Vector3.new(0.15, 0.7, 0.15),
			Vector3.new(0.65, 0.2, 0.35)
		)
		self.ViewModel:AdjustSpring("gunSpring", Vector3.new(0, -landing.ViewmodelKick * shock, 0))
	end

	local velocity = self.Frame.MoveVelocity
	local speed = velocity.Magnitude
	if speed > 0.1 then
		local bleed = math.lerp(landing.MinBleed, landing.MaxBleed, alpha) * responseScale
		self:ApplyImpulse(-velocity.Unit, speed * bleed)
		if not buffered then
			self.LandingCarryDirection = velocity.Unit
			self.LandingCarryUntil = time() + landing.SlideDuration * math.lerp(0.65, 1, alpha)
		end
	end
end

function Movement:GetLandingShock()
	local remaining = (self.LandingShockUntil or 0) - time()
	if remaining <= 0 then return 0 end
	local duration = self.Config.Ground.HardLanding.ShockDuration
	return (self.LandingShockStrength or 0) * math.clamp(remaining / math.max(duration, 0.01), 0, 1)
end

function Movement:TryVault()
	if self.ActiveAction or not self.Frame.Grounded or time() < (self.VaultCooldownUntil or 0) then return false end
	local direction = self.Frame.WorldWishDir
	if direction == Vector3.zero and self.Frame.MoveVelocity.Magnitude > 0.1 then
		direction = self.Frame.MoveVelocity.Unit
	end
	if direction == Vector3.zero then return false end

	local result = Cast:VaultCheck(direction)
	if not result then return false end
	self.VaultCooldownUntil = time() + self.Config.Actions.Vault.Cooldown
	return self:StartAction("Vault", {
		Direction = direction,
		TooClose = result.TooClose,
	})
end

function Movement:TryWallRun()
	if self.ActiveAction or self.Frame.Grounded or time() < (self.WallRunCooldownUntil or 0) then return false end
	if self.Frame.MoveVelocity.Magnitude < self.Config.Actions.WallRun.MinSpeed then return false end

	local side
	if self.Frame.WishDir.X < 0 and self.Frame.RayStates.LeftWall then
		side = "Left"
	elseif self.Frame.WishDir.X > 0 and self.Frame.RayStates.RightWall then
		side = "Right"
	end
	return side ~= nil and self:StartAction("WallRun", { Side = side })
end

function Movement:TryJump()
	local now = time()
	if now < (self.JumpCooldownUntil or 0) then return false end

	if self.ActiveAction and self.ActiveAction.Name == "WallRun" then
		local action = self.ActiveAction
		if action:Jump(self) then
			self:StopAction("Jumped")
			self.JumpCooldownUntil = now + self.Config.Jump.Cooldown
			return true
		end
		return false
	end
	if self.ActiveAction then return false end

	local grounded = self.Frame.Grounded or now - self.Frame.LastGroundedAt <= self.Config.Movement.CoyoteTime
	if not grounded and self.AirJumps >= self.MaxAirJumps then return false end
	if not grounded then self.AirJumps += 1 end

	self:ApplyImpulse(self.CM.UpDirection, self.Config.Jump.Strength)
	self.JumpCooldownUntil = now + self.Config.Jump.Cooldown
	return true
end

function Movement:IsJumpHeld()
	return UserInputService:IsKeyDown(Enum.KeyCode.Space)
end

function Movement:StartLunge(direction, config)
	return self:StartAction("Lunge", { Direction = direction, Config = config })
end

function Movement:StartStomp(config)
	if self.Frame.Grounded then return false end
	return self:StartAction("Stomp", { Config = config })
end

function Movement:ApplyKnockback(packet)
	if not self.Ready then return end
	local direction, strength, mode, data
	if typeof(packet) == "Vector3" then
		direction, strength, mode, data = packet.Unit, packet.Magnitude, "Finisher", {}
	elseif typeof(packet) == "table" then
		if typeof(packet.Direction) == "Vector3" and typeof(packet.Strength) == "number" then
			direction, strength = packet.Direction, packet.Strength
		elseif typeof(packet.Velocity) == "Vector3" then
			direction, strength = packet.Velocity.Unit, packet.Velocity.Magnitude
		elseif typeof(packet.Impulse) == "Vector3" then
			direction, strength = packet.Impulse.Unit, packet.Impulse.Magnitude / math.max(self.BaseMass, 0.001)
		else
			return
		end
		mode, data = packet.Mode or "Finisher", packet
	else
		return
	end
	if direction.Magnitude <= 0.001 or strength <= 0 then return end

	self:ApplyImpulse(direction, strength)
	if mode == "Push" then
		self.PushGripUntil = time() + (data.Duration or 0.14)
	else
		self:StartAction("Knockback", data)
	end
end

function Movement:_UpdateFacing()
	if not self.Humanoid.AutoRotate then return end
	local direction = self.Frame.WorldWishDir
	if direction == Vector3.zero and self.Frame.MoveVelocity.Magnitude > 0.1 then
		direction = self.Frame.MoveVelocity.Unit
	end
	if direction ~= Vector3.zero then self.CM.FacingDirection = direction end
end

function Movement:_UpdatePresentation()
	local ground = self.Config.Ground
	local spread = ground.BulletSpread * math.clamp(
		self.Frame.MoveVelocity.Magnitude / math.max(self.Config.Ground.MoveSpeed, 0.01),
		0,
		1
	)
	spread += ground.HardLanding.ShockSpread * self:GetLandingShock()
	if math.abs(spread - self.CurrentSpread) > 0.001 then
		self.CurrentSpread = spread
		self.SpreadChanged:Fire(spread)
	end

	if self.ViewModel and self.ViewModel.SetTilt then
		local inputX = self.Frame.WishDir.X
		local sign = if math.abs(inputX) > 0.05 then math.sign(inputX) else 0
		local alpha, impulse = 0, 0
		if sign ~= 0 then
			local up = self.CM.UpDirection
			local camera = workspace.CurrentCamera
			local right = camera and (camera.CFrame.RightVector - up * camera.CFrame.RightVector:Dot(up)) or Vector3.zero
			local lateral = right.Magnitude > 0.001 and self.Frame.MoveVelocity:Dot(right.Unit) or 0
			local fullSpeed = math.max(self.CM.BaseMoveSpeed, self.Humanoid.WalkSpeed, 16)
			local aligned = math.clamp(sign * lateral / fullSpeed, -1, 1)
			local oppose = math.sqrt((1 - aligned) * 0.5)
			alpha = sign * math.clamp(
				self.Config.Movement.TiltBase + oppose * self.Config.Movement.TiltOppose,
				0,
				1
			)
			if self.LastTiltSign ~= 0 and sign ~= self.LastTiltSign then
				impulse = sign * self.Config.Movement.TiltSnap
			end
		end
		self.LastTiltSign = sign
		self.ViewModel:SetTilt(alpha, impulse)
	end

	if self.ActiveAction then
		self.state = self.ActiveAction.Name
	elseif not self.Frame.Grounded then
		self.state = "Air"
	elseif self.Frame.WorldWishDir == Vector3.zero then
		self.state = "Idle"
	else
		self.state = "Running"
	end
end

function Movement:Update(dt)
	if not self.Ready or not self.Enabled then return end
	self.FrameTracker:Update(dt)

	if not self.Frame.Grounded then
		local downSpeed = -self.Frame.Velocity:Dot(self.CM.UpDirection)
		self.PeakDownwardSpeed = math.max(self.PeakDownwardSpeed or 0, downSpeed)
	end

	if self.Frame.JustLanded then
		self.AirJumps = 0
		self.WallRunCooldownUntil = 0
		self:_HandleLanding()
		self.Landed:Fire()
	end

	if self.ActiveAction and not self.ActiveAction:Update(self, dt) then
		self:StopAction("Finished")
	end

	if self.SpaceBufferedUntil >= time() then
		local consumed = not self.ActiveAction and self.Frame.Grounded and self:TryVault() or false
		if not consumed then consumed = self:TryJump() end
		if consumed then self.SpaceBufferedUntil = 0 end
	end

	if not self.ActiveAction then
		self:TryWallRun()
	end

	if not self.ActiveAction then self.Locomotion:Update(dt) end
	self:_UpdateFacing()
	self:_UpdatePresentation()
end

function Movement:SetEnabled(enabled)
	self.Enabled = enabled == true
	if not self.Ready then return end
	if not self.Enabled then
		self:StopAction("Disabled")
		self.CM.MovingDirection = Vector3.zero
		self.CM.BaseMoveSpeed = 0
	end
end

function Movement:SetDoubleJumps(count)
	self.MaxAirJumps = math.max(tonumber(count) or 0, 0)
end

function Movement:IsGrounded()
	return self.Ready and self.Frame.Grounded
end

function Movement:GetSpread()
	return self.CurrentSpread
end

function Movement:Init(props)
	local trove = props.Trove:Extend()
	self.trove = trove
	self.Ready = false
	self.Config = requireFresh(ConfigModule)

	local character = props.Character or Player.Character or Player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local cm = character:WaitForChild("ControllerManager", 10)
	if not humanoid or not hrp or not cm then
		warn("[Movement] character controllers missing")
		return
	end

	self.Character = character
	self.Humanoid = humanoid
	self.HRP = hrp
	self.CM = cm
	self.ViewModel = props.ViewModel
	self.Camera = props.Camera
	if not self:_GetControllers(cm) then
		warn("[Movement] controller children missing")
		return
	end

	Cast:Init()
	self.FrameTracker = Frame.new(self, require(Player.PlayerScripts.PlayerModule):GetControls(), Cast)
	self.Frame = self.FrameTracker.Data
	self.Locomotion = Locomotion.new(self)
	self.ActiveAction = nil

	local physical = hrp.CurrentPhysicalProperties
	self._basePhysProps = physical
	self.BaseMass = hrp.AssemblyMass
	self.BaseVolume = hrp.Mass / physical.Density
	self.Weight = 1
	self.EffectiveWeight = 1
	self.MaxAirJumps = self.Config.Jump.DoubleJumps
	self.AirJumps = 0
	self.SpaceBufferedUntil = 0
	self.JumpCooldownUntil = 0
	self.VaultCooldownUntil = 0
	self.WallRunCooldownUntil = 0
	self.PushGripUntil = 0
	self.LandingCarryUntil = 0
	self.LandingCarryDirection = Vector3.zero
	self.LandingShockStrength = 0
	self.LandingShockUntil = 0
	self.PeakDownwardSpeed = 0
	self.LastTiltSign = 0
	self.CurrentSpread = 0
	self.state = "Idle"

	self.GroundController.FrictionWeight = 100
	self.GroundController.GroundOffset = 2
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	loadPresentation(self, trove)

	trove:Connect(RunService.RenderStepped, function(dt) self:Update(dt) end)
	trove:Connect(UserInputService.JumpRequest, function()
		self.SpaceBufferedUntil = time() + self.Config.Movement.JumpBufferTime
	end)
	trove:Connect(Events.Knockback.OnClientEvent, function(packet) self:ApplyKnockback(packet) end)
	trove:Add(props.RoundReplica:OnSet({ "movement" }, function(enabled) self:SetEnabled(enabled) end))
	trove:Connect(Bindables.TimeChanged.Event, function() workspace.Gravity = self.BaseGravity or workspace.Gravity end)

	self.BaseGravity = workspace.Gravity
	self.Ready = true
	self:SetEnabled(props.RoundReplica.Data.movement)
end

function Movement:Destroy()
	self:StopAction("Destroyed")
	if self.trove then self.trove:Destroy() end
	Cast:Destroy()
	self.Ready = false
end

return Movement
