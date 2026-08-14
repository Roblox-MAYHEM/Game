local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
local ImpactService = require(Modules.ImpactService)
local MeleeValidator = require(Modules.MeleeValidator)
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
	self.ActiveContact = false
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
	return not self.ActiveContact
end

function Weapon:_SwingInfo(index: number)
	return self.AttackInfo.SWINGS[index]
end

function Weapon:_ConfigureValidator(info)
	local cfg = self.AttackValidator.Config
	cfg.Window = info.WINDOW or self.AttackInfo.WINDOW
	cfg.Range = info.RANGE or self.AttackInfo.RANGE
	cfg.Arc = info.ARC or self.AttackInfo.ARC
	cfg.Debounce = info.HIT_DEBOUNCE or self.AttackInfo.HIT_DEBOUNCE
	cfg.LOS = if info.LOS ~= nil then info.LOS else self.AttackInfo.LOS
end

function Weapon:AttackStart(swingIndex)
	local index = math.clamp(tonumber(swingIndex) or 1, 1, 3)
	local info = self:_SwingInfo(index)
	local attack = {}

	self.CurrentAttack = attack
	self.SwingIndex = index
	self.ActiveContact = true
	self:_ConfigureValidator(info)
	self.AttackValidator:BeginAttack()

	task.delay(info.HIT_TIME or self.AttackInfo.HIT_TIME, function()
		if self.CurrentAttack ~= attack then return end
		self.ActiveContact = false
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
	local attackerRoot = rootOf(self.Character)
	local targetRoot = rootOf(targetCharacter)
	local rawDirection = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis
	local direction = Vector3.new(rawDirection.X, 0, rawDirection.Z)
	if direction.Magnitude <= 0.001 then
		direction = attackerRoot and attackerRoot.CFrame.LookVector or Vector3.zAxis
	end

	ImpactService.ApplyHit(targetCharacter, self.Player, {
		Power = info.IMPACT_POWER or self.AttackInfo.IMPACT_POWER,
		Direction = direction,
		FinisherMultiplier = info.FINISHER_MULTIPLIER or self.AttackInfo.FINISHER_MULTIPLIER,
		UpwardVelocity = info.FINISHER_Y or self.AttackInfo.FINISHER_Y,
	})
	DamageHandler.DamageHumanoid(humanoid, self.Player, info.DMG or self.AttackInfo.DMG, false)

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip(force: boolean?)
	if not force and not self:CanUnequip() then return false end

	self.CurrentAttack = nil
	self.ActiveContact = false
	self.SwingIndex = 1
	self.AttackValidator:Cleanup()
	self:_Unequip()
	return true
end

return Weapon
