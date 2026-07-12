local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules
local Remotes = ReplicatedStorage.Events

local ClientHitbox = require(Modules.ClientHitbox)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "Attack",
	},
}

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
		Equipped = false,
		Equipping = false,
		Attacking = false,
		Lunging = false,
	}

	self.AttackInfo = self.Config.Attack
	self.LungeInfo = self.Config.Lunge
	self.LastAttackTime = 0
	self.ActionToken = nil
	self.BaseGrip = CFrame.new()
	self.Hitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = self.AttackInfo.HITBOX_SHAPE,
		Size = self.AttackInfo.HITBOX_SIZE,
		Offset = self.AttackInfo.HITBOX_OFFSET,
		HitBoost = self.AttackInfo.HIT_BOOST,
		HitBoostCap = self.AttackInfo.HIT_BOOST_CAP,
	})
	self.Hitbox:OnHumHit(function(humanoid)
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	return self
end

function Weapon:_NewAction()
	local token = {}
	self.ActionToken = token
	return token
end

function Weapon:_SetGrip(offset: CFrame?)
	local grip = self.BaseGrip
	if offset then
		grip *= offset
	end

	if self.ViewModel and self.ViewModel.Joint then
		self.ViewModel.Joint.C1 = grip
	end

	local rightArm = self.Character and self.Character:FindFirstChild("Right Arm")
	local worldGrip = rightArm and rightArm:FindFirstChild("Grip")
	if worldGrip then
		worldGrip.C1 = grip
	end
end

function Weapon:Equip()
	if not self:_Equip() then return end
	self.Hitbox:Reconcile()

	self.BaseGrip = self.ViewModel and self.ViewModel.Joint and self.ViewModel.Joint.C1 or CFrame.new()
	self.States.Equipping = true
	self.States.Equipped = true

	if self.Animations.Equip then
		self.Animations.Equip:Play()
		self.Animations.Equip.Stopped:Wait()
	else
		task.wait(self.Config.Equip.TIME)
	end

	if not self.States.Equipping then return end
	self.States.Equipping = false
	if self.Animations.Idle then self.Animations.Idle:Play() end
end

function Weapon:_PlaySwing()
	if self.Animations.Slash then self.Animations.Slash:Play() end
	if self.Sounds and self.Sounds.Swing then self.Sounds.Swing:Play() end
end

function Weapon:_Slash()
	local token = self:_NewAction()
	self.States.Attacking = true
	self.Hitbox:HitStart(self.AttackInfo.TIME)
	Remotes.WeaponEvent:FireServer("AttackStart")
	self:_PlaySwing()

	task.wait(self.AttackInfo.TIME)
	if self.ActionToken ~= token then return end
	self.Hitbox:HitStop()
	self.States.Attacking = false
	task.wait(self.AttackInfo.COOLDOWN or 0)
	if self.ActionToken == token then
		self.ActionToken = nil
	end
end

function Weapon:Lunge()
	local token = self:_NewAction()
	self.States.Attacking = false
	self.States.Lunging = true
	self.Hitbox:HitStop()
	self:_SetGrip(self.LungeInfo.GRIP_OUT)

	self.Movement:ApplyImpulse(self.HRP.CFrame.LookVector, self.LungeInfo.FORWARD_VELOCITY or 0)
	local float = self.LungeInfo.FLOAT_VELOCITY or Vector3.zero
	if float.Magnitude > 0 then self.Movement:ApplyImpulse(float.Unit, float.Magnitude) end

	self.Hitbox:HitStart(self.LungeInfo.HIT_TIME or self.LungeInfo.TIME)
	Remotes.WeaponEvent:FireServer("Lunge")
	if self.Animations.Lunge then self.Animations.Lunge:Play() end

	task.wait(self.LungeInfo.HIT_TIME or self.LungeInfo.TIME)
	if self.ActionToken ~= token then return end
	self.Hitbox:HitStop()
	task.wait(math.max((self.LungeInfo.TIME or 0) - (self.LungeInfo.HIT_TIME or 0), 0))
	if self.ActionToken ~= token then return end

	self:_SetGrip()
	self.States.Lunging = false
	task.wait(self.LungeInfo.COOLDOWN or 0)
	if self.ActionToken == token then
		self.ActionToken = nil
	end
end

function Weapon:Attack()
	if self.States.Lunging or not self.States.Equipped then return end

	local now = tick()
	local shouldLunge = now - self.LastAttackTime <= (self.LungeInfo.COMBO_WINDOW or 0.25)
	if self.States.Attacking and not shouldLunge then return end

	self.LastAttackTime = now

	if shouldLunge then
		task.spawn(function()
			self:Lunge()
		end)
	else
		task.spawn(function()
			self:_Slash()
		end)
	end
end

function Weapon:Unequip()
	self:_Unequip()
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.Attacking = false
	self.States.Lunging = false
	self.ActionToken = nil
	self:_SetGrip()

	for _, anim in self.Animations do
		if anim.IsPlaying then anim:Stop() end
	end

	self.Hitbox:HitStop()
end

return Weapon
