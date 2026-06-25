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
	[Enum.UserInputState.End] = {
		[Enum.UserInputType.MouseButton1] = "StopAttack",
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
		TriggerHeld = false,
		SpecialCooldown = false,
	}
	self.ComboStep = 1
	self.QueuedAttack = false
	self.LastSwingTime = 0

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

function Weapon:_SwingInfo(index: number)
	local swings = self.AttackInfo.SWINGS
	return (swings and swings[index]) or self.AttackInfo
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

function Weapon:_PlayHeavyAnimation(index: number)
	local info = self:_SwingInfo(index)
	local anim = self.Animations[info.ANIM or `Swing{index}`]
	if anim then
		anim:SetDuration(info.TIME or self.AttackInfo.TIME)
		anim:Play()
	end
end

function Weapon:_Swing(index: number)
	local info = self:_SwingInfo(index)
	local totalTime = info.TIME or self.AttackInfo.TIME
	local hitDelay = info.HIT_DELAY or self.AttackInfo.HIT_DELAY or 0
	local hitTime = info.HIT_TIME or self.AttackInfo.HIT_TIME or totalTime

	self.States.HeavyAttacking = true
	Remotes.WeaponEvent:FireServer("AttackStart", index)
	self:_PlayHeavyAnimation(index)

	task.wait(hitDelay)
	self.Hitbox:HitStart(hitTime)
	task.wait(hitTime)
	self.Hitbox:HitStop()

	local remaining = totalTime - hitDelay - hitTime
	task.wait(math.max(remaining, 0))

	self.States.HeavyAttacking = false
	self.LastSwingTime = tick()
end

function Weapon:_AttackLoop(token)
	while self.AttackLoop == token
		and self.States.Equipped
		and not self.States.SpecialCooldown
		and (self.States.TriggerHeld or self.QueuedAttack)
	do
		if tick() - self.LastSwingTime > (self.AttackInfo.CHAIN_RESET or 1) then
			self.ComboStep = 1
		end

		local index = self.ComboStep
		self.QueuedAttack = false
		self:_Swing(index)

		if index >= 3 then
			self.ComboStep = 1
			self.QueuedAttack = false
			self.States.SpecialCooldown = true
			task.wait(self.AttackInfo.SPECIAL_COOLDOWN or 0)
			self.States.SpecialCooldown = false
		else
			self.ComboStep = index + 1
		end
	end

	if self.AttackLoop == token then
		self.AttackLoop = nil
	end
end

function Weapon:Attack()
	if self.States.SpecialCooldown or not self.States.Equipped then return end

	self.States.TriggerHeld = true
	self.QueuedAttack = true

	if not self.AttackLoop then
		local token = {}
		self.AttackLoop = token
		task.spawn(function()
			self:_AttackLoop(token)
		end)
	end
end

function Weapon:StopAttack()
	self.States.TriggerHeld = false
end

function Weapon:Unequip()
	if not self:CanUnequip() then return false end

	self:_Unequip()
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.TriggerHeld = false
	self.States.SpecialCooldown = false
	self.QueuedAttack = false
	self.AttackLoop = nil

	for _, anim in self.Animations do
		if anim.IsPlaying then anim:Stop() end
	end

	self.Hitbox:HitStop()
	return true
end

return Weapon
