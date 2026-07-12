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
	self.SwingIndex = 1
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

function Weapon:_SwingInfo(index: number)
	local swings = self.AttackInfo.SWINGS
	return (swings and swings[index]) or self.AttackInfo
end

function Weapon:_ConfigureValidator(info)
	local cfg = self.AttackValidator.cfg
	cfg.Window = info.WINDOW or self.AttackInfo.WINDOW
	cfg.Range = info.RANGE or self.AttackInfo.RANGE
	cfg.Arc = info.ARC or self.AttackInfo.ARC
	cfg.Debounce = info.HIT_DEBOUNCE or self.AttackInfo.HIT_DEBOUNCE
	cfg.LOS = if info.LOS ~= nil then info.LOS else self.AttackInfo.LOS
end

function Weapon:AttackStart(swingIndex)
	local index = math.clamp(tonumber(swingIndex) or 1, 1, 3)
	local info = self:_SwingInfo(index)
	local token = {}

	self.AttackToken = token
	self.SwingIndex = index
	self.HeavyAttacking = true
	self:_ConfigureValidator(info)
	self.AttackValidator:BeginAttack()

	task.delay(info.TIME or self.AttackInfo.TIME, function()
		if self.AttackToken ~= token then return end
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

	local info = self:_SwingInfo(self.SwingIndex or 1)
	DamageHandler.DamageHumanoid(humanoid, self.Player, info.DMG or self.AttackInfo.DMG, false)

	local attackerRoot = rootOf(self.Character)
	local targetRoot = rootOf(targetCharacter)
	local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis
	ApplyKnockback(targetCharacter, direction, {
		FORCE = info.KNOCKBACK_FORCE or self.AttackInfo.KNOCKBACK_FORCE,
		Y = info.KNOCKBACK_Y or self.AttackInfo.KNOCKBACK_Y,
		YMAX = info.KNOCKBACK_YMAX or self.AttackInfo.KNOCKBACK_YMAX,
		DURATION = info.KNOCKBACK_DURATION or self.AttackInfo.KNOCKBACK_DURATION,
		FLAT = true,
	})

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	if not self:CanUnequip() then return false end

	self.AttackToken = nil
	self.SwingIndex = 1
	self.AttackValidator:Cleanup()
	self:_Unequip()
	return true
end

return Weapon
