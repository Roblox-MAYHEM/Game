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
		HeavyAttacking = false,
	}

	self.AttackInfo = self.Config.Attack
	self.HitboxPart = self.wWeapon:WaitForChild("Hitbox")
	self.Hitbox = ClientHitbox.new(self.HitboxPart)
	self.Hitbox:OnHumHit(function(humanoid)
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	return self
end

function Weapon:CanUnequip()
	return not self.States.HeavyAttacking
end

function Weapon:Equip()
	if not self:_Equip() then return end
	self.Hitbox:Reconcile()

	self.States.Equipping = true
	if self.Animations.Equip then
		self.Animations.Equip:Play()
		self.Animations.Equip.Stopped:Wait()
	else
		task.wait(self.Config.Equip.TIME)
	end

	if not self.States.Equipping then return end
	self.States.Equipping = false
	self.States.Equipped = true
	if self.Animations.Idle then self.Animations.Idle:Play() end
end

function Weapon:_PlayHeavyAnimation()
	local names = { "Swing1", "Swing2", "Swing3" }
	local anim = self.Animations[names[math.random(1, #names)]]
	if anim then
		anim:SetDuration(self.AttackInfo.TIME)
		anim:Play()
	end
end

function Weapon:Attack()
	if self.States.HeavyAttacking or not self.States.Equipped then return end

	self.States.HeavyAttacking = true
	Remotes.WeaponEvent:FireServer("AttackStart")
	self:_PlayHeavyAnimation()

	task.wait(self.AttackInfo.HIT_DELAY or 0)
	self.Hitbox:HitStart(self.AttackInfo.HIT_TIME)
	task.wait(self.AttackInfo.HIT_TIME)
	self.Hitbox:HitStop()

	local remaining = self.AttackInfo.TIME - (self.AttackInfo.HIT_DELAY or 0) - self.AttackInfo.HIT_TIME
	task.wait(math.max(remaining, 0))
	self.States.HeavyAttacking = false
	task.wait(self.AttackInfo.COOLDOWN or 0)
end

function Weapon:Unequip()
	if not self:CanUnequip() then return false end

	self:_Unequip()
	self.States.Equipping = false
	self.States.Equipped = false

	for _, anim in self.Animations do
		if anim.IsPlaying then anim:Stop() end
	end

	self.Hitbox:HitStop()
	return true
end

return Weapon
