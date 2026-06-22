local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
local MeleeValidator = require(Modules.MeleeValidator)
local ApplyKnockback = require(Modules.Knockback)
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
	local knockback = self.AttackInfo

	if isSpecial then
		damage = (self.SpecialInfo.BASE_DMG or damage) + charge * (self.SpecialInfo.WIND_MULT or 0)
		knockback = self.SpecialInfo
	end

	local force = knockback.KNOCKBACK_FORCE or self.AttackInfo.KNOCKBACK_FORCE or 0
	if isSpecial then
		force += charge * (self.SpecialInfo.KNOCKBACK_CHARGE_MULT or 0)
	end

	local attackerRoot = rootOf(self.Character)
	local targetRoot = rootOf(targetCharacter)
	local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis

	return damage, direction, {
		FORCE = force,
		Y = knockback.KNOCKBACK_Y or self.AttackInfo.KNOCKBACK_Y,
		YMAX = knockback.KNOCKBACK_YMAX or self.AttackInfo.KNOCKBACK_YMAX,
		DURATION = knockback.KNOCKBACK_DURATION or self.AttackInfo.KNOCKBACK_DURATION,
		FLAT = true,
		WALL_DAZE = isSpecial,
		DAZE_DURATION = self.SpecialInfo.DAZE_DURATION,
		WALL_SPEED_MIN = self.SpecialInfo.WALL_SPEED_MIN,
		SOURCE = isSpecial and "BaseballBatSpecial" or "BaseballBat",
	}
end

function Weapon:ProcessHit(targetCharacter: Model)
	local ok = self.AttackValidator:ValidateHit(targetCharacter)
	if not ok then return false end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local damage, direction, knockbackParams = self:_GetHitContext(targetCharacter)
	DamageHandler.DamageHumanoid(humanoid, self.Player, damage, false)
	ApplyKnockback(targetCharacter, direction, knockbackParams)

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
