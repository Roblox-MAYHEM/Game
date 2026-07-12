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

local function makeValidator(character: Model, info)
	return MeleeValidator.new(character, {
		Window = info.WINDOW,
		Range = info.RANGE,
		Arc = info.ARC,
		Debounce = info.HIT_DEBOUNCE,
		LOS = info.LOS,
	})
end

function Weapon.new(WeaponModel, player)
	local self = BaseWeapon.new({
		Player = player,
		WeaponModel = WeaponModel,
		Name = WeaponModel.Name,
	})
	setmetatable(self, Weapon)

	self.AttackInfo = self.Config.Attack
	self.LungeInfo = self.Config.Lunge
	self.CurrentMode = "Attack"
	self.AttackValidator = makeValidator(self.Character, self.AttackInfo)
	self.LungeValidator = MeleeValidator.new(self.Character, {
		Window = self.LungeInfo.WINDOW,
		Range = self.LungeInfo.RANGE,
		Arc = self.LungeInfo.ARC,
		Debounce = self.LungeInfo.HIT_DEBOUNCE,
		LOS = self.LungeInfo.LOS,
	})

	return self
end

function Weapon:AttackStart()
	self.CurrentMode = "Attack"
	self.AttackValidator:BeginAttack()
	return true
end

function Weapon:Lunge()
	self.CurrentMode = "Lunge"
	self.LungeValidator:BeginAttack()
	return true
end

function Weapon:ProcessHit(targetCharacter: Model)
	local info = if self.CurrentMode == "Lunge" then self.LungeInfo else self.AttackInfo
	local validator = if self.CurrentMode == "Lunge" then self.LungeValidator else self.AttackValidator

	local ok = validator:ValidateHit(targetCharacter)
	if not ok then return false end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	DamageHandler.DamageHumanoid(humanoid, self.Player, info.DMG, false)

	if self.CurrentMode == "Lunge" then
		local attackerRoot = rootOf(self.Character)
		local targetRoot = rootOf(targetCharacter)
		local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis
		ApplyKnockback(targetCharacter, direction, {
			FORCE = info.KNOCKBACK_FORCE,
			Y = info.KNOCKBACK_Y,
			DURATION = info.KNOCKBACK_DURATION,
			FLAT = true,
		})
	end

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self.CurrentMode = "Attack"
	self.AttackValidator:Cleanup()
	self.LungeValidator:Cleanup()
	self:_Unequip()
end

return Weapon
