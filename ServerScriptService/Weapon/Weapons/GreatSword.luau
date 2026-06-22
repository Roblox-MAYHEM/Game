local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
local MeleeValidator = require(Modules.MeleeValidator)
local ApplyKnockback = require(Modules.Knockback)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

local function rootOf(character: Model): BasePart?
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root or nil
end

function Weapon.new(WeaponModel, player)
	local self = BaseWeapon.new({
		Player = player,
		WeaponModel = WeaponModel,
		Name = WeaponModel.Name,
	})
	setmetatable(self, Weapon)

	self.AttackInfo = self.Config.Attack
	self.HeavyAttacking = false
	self.AttackValidator = MeleeValidator.new(self.Character, {
		Window = self.AttackInfo.WINDOW,
		Range = self.AttackInfo.RANGE,
		Arc = self.AttackInfo.ARC,
		Debounce = self.AttackInfo.HIT_DEBOUNCE,
		LOS = self.AttackInfo.LOS,
	})

	return self
end

function Weapon:CanUnequip()
	return not self.HeavyAttacking
end

function Weapon:AttackStart()
	if self.HeavyAttacking then return false end

	self.HeavyAttacking = true
	self.AttackValidator:BeginAttack()

	task.delay(self.AttackInfo.TIME, function()
		self.HeavyAttacking = false
		self.AttackValidator:EndAttack()
	end)

	return true
end

function Weapon:ProcessHit(targetCharacter: Model)
	local ok = self.AttackValidator:ValidateHit(targetCharacter)
	if not ok then return false end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	DamageHandler.DamageHumanoid(humanoid, self.Player, self.AttackInfo.DMG, false)

	local attackerRoot = rootOf(self.Character)
	local targetRoot = rootOf(targetCharacter)
	local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis
	ApplyKnockback(targetCharacter, direction, {
		FORCE = self.AttackInfo.KNOCKBACK_FORCE,
		Y = self.AttackInfo.KNOCKBACK_Y,
		YMAX = self.AttackInfo.KNOCKBACK_YMAX,
		DURATION = self.AttackInfo.KNOCKBACK_DURATION,
		FLAT = true,
		SOURCE = "GreatSword",
	})

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	if not self:CanUnequip() then return false end

	self.AttackValidator:Cleanup()
	self:_Unequip()
	return true
end

return Weapon
