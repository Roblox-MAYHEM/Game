local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
local ImpactService = require(Modules.ImpactService)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local MeleeValidator = require(Modules.MeleeValidator)

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

	self.AttackValidator = MeleeValidator.new(self.Character, { -- Settings
		Window = self.AttackInfo.WINDOW,
		Range = self.AttackInfo.RANGE,
		Arc = self.AttackInfo.ARC,
		Debounce = self.AttackInfo.HIT_DEBOUNCE,
		LOS = self.AttackInfo.LOS,
		IgnoreInstance = function(inst)
			return inst:IsDescendantOf(workspace:FindFirstChild("Effects") or Instance.new("Folder"))
		end,
	})

	return self
end

function Weapon:AttackStart()
	self.AttackValidator:BeginAttack()
	return true
end

function Weapon:ProcessHit(targetChar)
	if typeof(targetChar) ~= "Instance" or not targetChar:IsA("Model") then
		return false
	end

	local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local ok, reason = self.AttackValidator:ValidateHit(targetChar)
	if not ok then return false end

	local attackerRoot = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis

	ImpactService.ApplyHit(targetChar, self.Player, {
		Power = self.AttackInfo.IMPACT_POWER,
		Direction = direction,
		FinisherMultiplier = self.AttackInfo.FINISHER_MULTIPLIER,
		UpwardVelocity = self.AttackInfo.FINISHER_Y,
	})
	DamageHandler.DamageHumanoid(humanoid, self.Player, self.AttackInfo.DMG, false)

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self:_Unequip()
end

function Weapon:HandleProjectileUpdate(id, _position, velocity)
	if typeof(velocity) ~= "Vector3" or velocity.Magnitude <= 0.001 then return end
	self.Projectile.Deflect(id, self.Player, velocity.Unit)
end

return Weapon
