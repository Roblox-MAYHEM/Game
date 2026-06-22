--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Weapons will perform certain weapon-specific moves.
Also fires events to server.
]]

local RunService        = game:GetService("RunService")
local Client = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local WeaponSystem 		= script.Parent.Parent
local Modules = WeaponSystem.Modules
local Libraries  = Client.Libraries
local Remotes    = ReplicatedStorage.Events
local Bindables  = Client.Bindables

local Cooldown      = require(ReplicatedStorage.Utils.Cooldown)
local ClientHitbox  = require(Modules.ClientHitbox)

local BaseWeapon = require(WeaponSystem.BaseWeapon)
local Animate    = require(script:WaitForChild("Animate"))

-- ── Weapon Class ─────────────────────────────────────────────────────
local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "BeginGlide",
		[Enum.UserInputType.MouseButton2] = "Lunge",
	},
	[Enum.UserInputState.End] = {
		[Enum.UserInputType.MouseButton1] = "EndGlide",
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

	self.HitboxPart = self.wWeapon:WaitForChild("Hitbox")

	self.Animations.Lunge:SetDuration(self.LungeInfo.ACTIVE_TIME + self.LungeInfo.OPEN_TIME)
	self.Animations.Open:SetDuration(0.17)

	self._trove:Connect(self.Animations.Open.Ended, function()
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
	local character = Players.LocalPlayer.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

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

	local v    = root.AssemblyLinearVelocity
	local mass = root.AssemblyMass

	drag.Force = v.Magnitude > 1e-3
		and (-mass * self._glideCurrentK * v.Magnitude * v)
		or Vector3.zero

	lift.Force = Vector3.new(0, (1 - gi.GRAVITY_SCALE_OPEN) * mass * workspace.Gravity, 0)
end

-- ── Equip / Unequip ──────────────────────────────────────────────────
function Weapon:Equip()
	if not self:_Equip() then return end
	self:_setupGlideForces()

	self.Hitbox = ClientHitbox.new(self.HitboxPart)
	self.Hitbox:OnHumHit(function(humanoid)
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	self.States.Equipping = true
	if self.Animations.Equip then
		self.Animations.Equip:Play()
		self.Animations.Equip.Stopped:Wait()
	else
		task.wait(self.Config.Equip.TIME)
	end

	self.Effects:Play("Held")

	if not self.States.Equipping then return end
	self.States.Equipping = false
	self.States.Equipped  = true
	self.Animations.Idle:Play()
end

function Weapon:Unequip()
	self:_Unequip()
	self:EndGlide(true)
	self:CancelLunge()

	self.States.Equipping       = false
	self.States.Equipped        = false
	self._glideRoot             = nil
	self._glideDrag             = nil
	self._glideLift             = nil
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
	if not self.Movement.States.Air then return end

	Cooldown.set("Glide", self.GlideInfo.COOLDOWN)

	self.States.Gliding = true
	self._glideTargetK  = self.GlideInfo.K_OPEN

	self._glideRoot:ApplyImpulse(
		Vector3.new(0, self._glideRoot.AssemblyMass * self.GlideInfo.POP_SPEED, 0)
	)

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

	self.Animations.OpenIdle:Stop()
	if not self.States.Gliding then
		self.Open()
	end

	self.States.Lunging = true
	self.Hitbox:HitStart(self.LungeInfo.ACTIVE_TIME)
	Remotes.WeaponEvent:FireServer("Lunge")

	self.Animations.Lunge:Play()
	self.Sounds.Lunge:Play()
	self.Effects:Play("Lunge")

	self.Movement:HandleStateChange("Lunging")

	local cnx
	cnx = Bindables.EndLunge.Event:Once(function()
		self:CancelLunge()
		cnx = nil
	end)

	task.wait(self.LungeInfo.ACTIVE_TIME + self.LungeInfo.OPEN_TIME)

	if cnx then
		self:CancelLunge()
		cnx:Disconnect()
	end
end

function Weapon:CancelLunge()
	if not self.States.Lunging then return end

	self.States.Lunging = false
	self.Animations.Lunge:Stop()
	self.Movement:HandleStateChange("Air")
	self.Hitbox:HitStop()

	self.Effects:Play("CancelLunge")

	Remotes.WeaponEvent:FireServer("CancelLunge")

	if not self.States.Gliding then
		task.wait(0.1)
		self.Close()
	else
		self.Animations.OpenIdle:Play()
	end
end

return Weapon
