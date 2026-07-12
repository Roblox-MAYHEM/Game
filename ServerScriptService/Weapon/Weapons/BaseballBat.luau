local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
local ImpactService = require(Modules.ImpactService)
local MeleeValidator = require(Modules.MeleeValidator)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

function Weapon.new(WeaponModel, player)
	local self = BaseWeapon.new({
		Player = player,
		WeaponModel = WeaponModel,
		Name = WeaponModel.Name,
	})

	setmetatable(self, Weapon)

	self.AttackInfo = self.Config.Attack
	self.WindupInfo = self.Config.Windup
	self.SpecialInfo = self.Config.Special
	self.CurrentAttack = nil
	self.Winding = false
	self.WindupVal = 0
	self.WindupConnection = nil

	self.AttackValidator = MeleeValidator.new(self.Character, {
		Window = self.AttackInfo.WINDOW,
		Range = self.AttackInfo.RANGE,
		Arc = self.AttackInfo.ARC,
		Debounce = self.AttackInfo.HIT_DEBOUNCE,
		LOS = self.AttackInfo.LOS,
	})

	return self
end

function Weapon:AttackStart()
	self.CurrentAttack = nil
	self.AttackValidator:BeginAttack()
	return true
end

local function rootOf(character: Model): BasePart?
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root or nil
end

function Weapon:_GetHitContext(targetCharacter: Model)
	local attack = self.CurrentAttack
	local isSpecial = attack and attack.IsSpecial == true and time() <= attack.EndTime
	local charge = isSpecial and attack.Charge or 0
	local damage = self.AttackInfo.DMG
	local impactPower = self.AttackInfo.IMPACT_POWER
	local finisherMultiplier = self.AttackInfo.FINISHER_MULTIPLIER
	local finisherY = self.AttackInfo.FINISHER_Y

	if isSpecial then
		damage = (self.SpecialInfo.BASE_DMG or damage) + charge * (self.SpecialInfo.WIND_MULT or 0)
		impactPower = (self.SpecialInfo.BASE_IMPACT or impactPower) + charge * (self.SpecialInfo.IMPACT_CHARGE_MULT or 0)
		finisherMultiplier = self.SpecialInfo.FINISHER_MULTIPLIER or finisherMultiplier
		finisherY = self.SpecialInfo.FINISHER_Y or finisherY
	end

	local attackerRoot = rootOf(self.Character)
	local targetRoot = rootOf(targetCharacter)
	local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis

	return damage, direction, {
		Power = impactPower,
		Direction = direction,
		FinisherMultiplier = finisherMultiplier,
		UpwardVelocity = finisherY,
		Flat = true,
		Source = isSpecial and "BaseballBatSpecial" or "BaseballBat",
	}
end

function Weapon:ProcessHit(targetCharacter: Model)
	local ok = self.AttackValidator:ValidateHit(targetCharacter)
	if not ok then return false end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local damage, _direction, impactHit = self:_GetHitContext(targetCharacter)
	ImpactService.ApplyHit(targetCharacter, self.Player, impactHit)
	DamageHandler.DamageHumanoid(humanoid, self.Player, damage, false)

	return true
end

function Weapon:Windup()
	if self.Winding then return false end

	self.Winding = true
	self.WindupVal = 0
	self.WindupConnection = task.spawn(function()
		while self.Winding and self.WindupVal < self.WindupInfo.MAX do
			self.WindupVal += 1
			task.wait(self.WindupInfo.RATE)
		end
	end)

	return true
end

function Weapon:CancelWindup()
	if not self.Winding then return false end

	self.Winding = false
	self.WindupVal = 0

	if self.WindupConnection then
		task.cancel(self.WindupConnection)
		self.WindupConnection = nil
	end

	return true
end

function Weapon:Special()
	if not self.Winding then return false end

	local charge = self.WindupVal
	self:CancelWindup()

	local duration = self.SpecialInfo.HIT_TIME or self.SpecialInfo.DURATION or self.SpecialInfo.TIME or 1
	local attack = {
		EndTime = time() + duration,
		IsSpecial = true,
		Charge = charge,
	}

	self.CurrentAttack = attack
	self.AttackValidator:BeginAttack()

	task.delay(duration, function()
		if self.CurrentAttack == attack then
			self.CurrentAttack = nil
			self.AttackValidator:EndAttack()
		end
	end)

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self.CurrentAttack = nil
	self.AttackValidator:Cleanup()
	self:CancelWindup()
	self:_Unequip()
end

return Weapon
