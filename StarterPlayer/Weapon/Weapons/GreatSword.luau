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
		ActiveContact = false,
		SpecialCooldown = false,
	}
	self.ComboStep = 1
	self.QueuedAttack = false
	self.LastSwingTime = 0

	self.AttackInfo = self.Config.Attack
	self.Hitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = self.AttackInfo.HITBOX_SHAPE,
		Size = self.AttackInfo.HITBOX_SIZE,
		Offset = self.AttackInfo.HITBOX_OFFSET,
		HitBoost = self.AttackInfo.HIT_BOOST,
		HitBoostCap = self.AttackInfo.HIT_BOOST_CAP,
	})
	self.Hitbox:OnHumHit(function(humanoid, firstHit)
		if firstHit then
			local info = self:_SwingInfo(self.ComboStep)
			local strength = info.SPECIAL and 1.7 or 1.1
			self.Camera:CameraShake("ShakeOnce", strength, 10, 0, 0.12)
			self.ViewModel:AdjustSpring("gunSpring", Vector3.new(0.12, -0.08, 0) * strength)
		end
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	return self
end

function Weapon:CanUnequip()
	return not self.States.ActiveContact
end

function Weapon:_SwingInfo(index: number)
	return self.AttackInfo.SWINGS[index]
end

function Weapon:Equip()
	if not self:_Equip() then return end
	self.Hitbox:Reconcile()

	self.States.Equipping = true
	self.Animations.Equip:Play()
	self.Animations.Equip.Stopped:Wait()

	if not self.States.Equipping then return end
	self.States.Equipping = false
	self.States.Equipped = true
	self.Animations.Idle:Play()
end

function Weapon:_Swing(index: number, action)
	local info = self:_SwingInfo(index)
	local totalTime = info.TIME or self.AttackInfo.TIME
	local hitDelay = info.HIT_DELAY or self.AttackInfo.HIT_DELAY or 0
	local hitTime = info.HIT_TIME or self.AttackInfo.HIT_TIME or totalTime

	local animation = self.Animations[info.ANIM]
	animation:SetDuration(totalTime)
	animation:Play()

	task.wait(hitDelay)
	if self.AttackLoop ~= action then return false end
	self.States.ActiveContact = true
	Remotes.WeaponEvent:FireServer("AttackStart", index)
	self.Hitbox:HitStart(hitTime)
	task.wait(hitTime)
	if self.AttackLoop ~= action then return false end
	self.Hitbox:HitStop()
	self.States.ActiveContact = false

	local remaining = totalTime - hitDelay - hitTime
	task.wait(math.max(remaining, 0))
	if self.AttackLoop ~= action then return false end

	self.LastSwingTime = tick()
	return true
end

function Weapon:_AttackLoop(action)
	while self.AttackLoop == action
		and self.States.Equipped
		and not self.States.SpecialCooldown
		and self.QueuedAttack
	do
		if tick() - self.LastSwingTime > (self.AttackInfo.CHAIN_RESET or 1) then
			self.ComboStep = 1
		end

		local index = self.ComboStep
		self.QueuedAttack = false
		if not self:_Swing(index, action) then break end

		if index >= 3 then
			self.ComboStep = 1
			self.QueuedAttack = false
			self.States.SpecialCooldown = true
			task.wait(self.AttackInfo.SPECIAL_COOLDOWN or 0)
			if self.AttackLoop ~= action then break end
			self.States.SpecialCooldown = false
		else
			self.ComboStep = index + 1
		end
	end

	if self.AttackLoop == action then
		self.AttackLoop = nil
	end
end

function Weapon:Attack()
	if self.States.SpecialCooldown or not self.States.Equipped then return end

	self.QueuedAttack = true

	if not self.AttackLoop then
		local action = {}
		self.AttackLoop = action
		task.spawn(function()
			self:_AttackLoop(action)
		end)
	end
end

function Weapon:Unequip(force: boolean?)
	if not force and not self:CanUnequip() then return false end

	self:_Unequip()
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.ActiveContact = false
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
