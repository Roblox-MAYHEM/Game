local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules
local Remotes = ReplicatedStorage.Events

local Cooldown = require(ReplicatedStorage.Utils.Cooldown)
local ClientHitbox = require(Modules.ClientHitbox)

local BaseWeapon = require(WeaponSystem.BaseWeapon)
local Animate = require(script:WaitForChild("Animate"))

-- ── Weapon Class ─────────────────────────────────────────────────────
local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "Lunge",
		[Enum.UserInputType.MouseButton2] = "BeginGlide",
	},
	[Enum.UserInputState.End] = {
		[Enum.UserInputType.MouseButton2] = "EndGlide",
	},
}

-- ── Constructor ──────────────────────────────────────────────────────
function Weapon.new(opts)
	local self = BaseWeapon.new({
		Name = opts.Name,
		WeaponModel = opts.WeaponModel,
		Binds = Weapon.Binds,
		Context = opts.Context,
	})
	setmetatable(self, Weapon)
	self:_init()

	self.States = {
		Equipped  = false,
		Equipping = false,
		Gliding   = false,
		Lunging   = false,
	}

	self.LungeInfo = self.Config.Lunge
	self.GlideInfo = self.Config.Glide

	self.Open, self.Close, self.Reset = Animate(self.ViewModel)
	self._trove:Add(self.Reset)

	self.Hitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = self.LungeInfo.HITBOX_SHAPE,
		Size = self.LungeInfo.HITBOX_SIZE,
		Offset = self.LungeInfo.HITBOX_OFFSET,
		HitBoost = self.LungeInfo.HIT_BOOST,
		HitBoostCap = self.LungeInfo.HIT_BOOST_CAP,
	})
	self.Hitbox:OnHumHit(function(humanoid, firstHit)
		if firstHit then
			self.Movement:Boost(self.Movement.CM.UpDirection, self.LungeInfo.HIT_LIFT_GAIN, self.LungeInfo.HIT_LIFT_CAP)
			self.Camera:CameraShake("ShakeOnce", 0.8, 10, 0, 0.12)
			self.ViewModel:AdjustSpring("gunSpring", Vector3.new(0.096, -0.064, 0))
		end
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	self.Animations.Lunge:SetDuration(self.LungeInfo.ACTIVE_TIME + self.LungeInfo.OPEN_TIME)
	self.Animations.Open:SetDuration(0.17)

	self._trove:Connect(self.Animations.Open.Stopped, function()
		if self.States.Gliding then
			self.Animations.OpenIdle:Play()
		end
	end)
	
	self.Effects:Register("Held", function(weapon)
		weapon.Primary.Trail.Enabled = false
	end)
	
	self.Effects:Register("Lunge", function(weapon)
		weapon.Primary.Trail.Enabled = true
	end)
	
	self.Effects:Register("CancelLunge", function(weapon)
		weapon.Primary.Trail.Enabled = false
	end)

	-- Glide physics (populated by _setupGlideForces on equip)
	self._glideRoot           = nil
	self._glideDrag           = nil
	self._glideLift           = nil
	self._glideConnection     = nil
	self._glideLandedConnection = nil
	self._glideCurrentK       = self.GlideInfo.K_CLOSED
	self._glideTargetK        = self.GlideInfo.K_CLOSED

	return self
end

-- ── Glide physics ────────────────────────────────────────────────────
function Weapon:_setupGlideForces()
	if self._glideDrag and self._glideDrag.Parent then return end

	local root = self.Character.HumanoidRootPart

	self._glideRoot     = root
	self._glideCurrentK = self.GlideInfo.K_CLOSED
	self._glideTargetK  = self.GlideInfo.K_CLOSED

	local att = Instance.new("Attachment")
	att.Name   = "UmbrellaAttachment"
	att.Parent = root

	local function makeForce(name)
		local f = Instance.new("VectorForce")
		f.Name                = name
		f.Attachment0         = att
		f.RelativeTo          = Enum.ActuatorRelativeTo.World
		f.ApplyAtCenterOfMass = true
		f.Force               = Vector3.zero
		f.Parent              = root
		return f
	end

	self._glideDrag = makeForce("UmbrellaDrag")
	self._glideLift = makeForce("UmbrellaLift")

	self._trove:Add(att)
	self._trove:Add(self._glideDrag)
	self._trove:Add(self._glideLift)
end

function Weapon:_glideStep(dt)
	local root = self._glideRoot
	local drag = self._glideDrag
	local lift = self._glideLift

	if not root or not drag then return end

	local gi    = self.GlideInfo
	local tau   = self._glideTargetK > self._glideCurrentK and gi.OPEN_RAMP_TAU or gi.CLOSE_RAMP_TAU
	local alpha = 1 - math.exp(-dt / math.max(tau, 1e-4))
	self._glideCurrentK += (self._glideTargetK - self._glideCurrentK) * alpha

	local up = self.Movement.CM.UpDirection or Vector3.yAxis
	local v = root.AssemblyLinearVelocity
	local vertical = up * v:Dot(up)
	local horizontal = v - vertical
	local mass = root.AssemblyMass
	local horizontalExcess = math.max(horizontal.Magnitude - gi.HORIZONTAL_FREE_SPEED, 0)
	local verticalDrag = -mass * self._glideCurrentK * vertical.Magnitude * vertical
	local horizontalDrag = horizontalExcess > 0
		and (-mass * gi.HORIZONTAL_DRAG * horizontalExcess * horizontal)
		or Vector3.zero
	drag.Force = verticalDrag + horizontalDrag

	lift.Force = up * ((1 - gi.GRAVITY_SCALE_OPEN) * mass * workspace.Gravity)
end

-- ── Equip / Unequip ──────────────────────────────────────────────────
function Weapon:Equip()
	if not self:_Equip() then return end
	self:_setupGlideForces()

	self.States.Equipping = true
	self.Animations.Equip:Play()
	self.Animations.Equip.Stopped:Wait()

	self.Effects:Play("Held")

	if not self.States.Equipping then return end
	self.States.Equipping = false
	self.States.Equipped  = true
	self.Animations.Idle:Play()
end

function Weapon:Unequip()
	self:EndGlide(true)
	self:CancelLunge()
	self:_Unequip()

	self.States.Equipping       = false
	self.States.Equipped        = false
	self._glideConnection       = nil
	self._glideLandedConnection = nil
	self._glideCurrentK         = self.GlideInfo.K_CLOSED
	self._glideTargetK          = self.GlideInfo.K_CLOSED

	for _, anim in self.Animations do
		if anim.IsPlaying then anim:Stop() end
	end
	self.Reset()
end

-- ── Glide ────────────────────────────────────────────────────────────
function Weapon:BeginGlide()
	if self.States.Lunging then return end
	if Cooldown.get("Glide") then return end
	if self.Movement:IsGrounded() then return end

	Cooldown.set("Glide", self.GlideInfo.COOLDOWN)

	self.States.Gliding = true
	self._glideTargetK  = self.GlideInfo.K_OPEN

	local up = self.Movement.CM.UpDirection or Vector3.yAxis
	local fallingSpeed = math.max(-self._glideRoot.AssemblyLinearVelocity:Dot(up), 0)
	self.Movement:ApplyImpulse(up, math.min(fallingSpeed * self.GlideInfo.CATCH_RATIO, self.GlideInfo.CATCH_MAX))

	self._glideConnection = RunService.RenderStepped:Connect(function(dt)
		self:_glideStep(dt)
	end)

	self._glideLandedConnection = self.Movement.Landed:Once(function()
		self:EndGlide()
	end)

	self.Sounds.Open:Play()
	self.Animations.Open:Play()
	self.Open()
end

function Weapon:EndGlide(suppressAnim: boolean?)
	if not self.States.Gliding then return end

	if self._glideConnection then
		self._glideConnection:Disconnect()
		self._glideConnection = nil
	end

	if self._glideLandedConnection then
		self._glideLandedConnection:Disconnect()
		self._glideLandedConnection = nil
	end

	if self._glideDrag then self._glideDrag.Force = Vector3.zero end
	if self._glideLift then self._glideLift.Force = Vector3.zero end

	if not suppressAnim then
		self.Animations.Open:Stop()
		self.Animations.OpenIdle:Stop()
		self.Sounds.Close:Play()
		self.Close()
	end

	self.States.Gliding = false
	self._glideTargetK  = self.GlideInfo.K_CLOSED
end

-- ── Lunge ────────────────────────────────────────────────────────────
function Weapon:Lunge()
	if self.States.Lunging then return end
	if Cooldown.get("Lunge") then return end

	Cooldown.set("Lunge", self.LungeInfo.COOLDOWN)
	local token = self:NewActionToken()

	self.Animations.OpenIdle:Stop()
	if not self.States.Gliding then
		self.Open()
	end

	self.States.Lunging = true
	self.Animations.Lunge:Play()
	self.Sounds.Lunge:Play()
	self.Effects:Play("Lunge")

	self.Movement:StartLunge(workspace.CurrentCamera.CFrame.LookVector, {
		Duration = self.LungeInfo.ACTIVE_TIME + self.LungeInfo.OPEN_TIME,
		Gain = self.LungeInfo.FORWARD_GAIN,
		MaxSpeed = self.LungeInfo.FORWARD_CAP,
		SteeringScale = 0.1,
	})

	task.wait(self.LungeInfo.OPEN_TIME)
	if not self:IsActionCurrent(token) or not self.States.Lunging then return end

	Remotes.WeaponEvent:FireServer("Lunge")
	self.Hitbox:HitStart(self.LungeInfo.ACTIVE_TIME)

	task.wait(self.LungeInfo.ACTIVE_TIME)
	if self:IsActionCurrent(token) then
		self:CancelLunge()
	end
end

function Weapon:CancelLunge()
	if not self.States.Lunging then return end

	self.States.Lunging = false
	self.Animations.Lunge:Stop()
	if self.Movement.ActiveAction and self.Movement.ActiveAction.Name == "Lunge" then
		self.Movement:StopAction("Weapon cancelled")
	end
	self.Hitbox:HitStop()

	self.Effects:Play("CancelLunge")

	Remotes.WeaponEvent:FireServer("CancelLunge")

	if not self.States.Gliding then
		self.Close()
	else
		self.Animations.OpenIdle:Play()
	end
end

return Weapon
