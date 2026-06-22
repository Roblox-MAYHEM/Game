local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
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
	self.CurrentAttack = nil
	self.LastHits = {}

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

	-- Apply damage
	DamageHandler.DamageHumanoid(humanoid, self.Player, self.AttackInfo.DMG, false)

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self:_Unequip()
end

function Weapon:HandleProjectileUpdate(id, position, velocity)
	local cast = self.Projectile.Get(id)
	if not cast or not cast.UserData or not cast.UserData.Deflectable then
		return
	end

	self.Projectile.ApplyUpdate(id, position, velocity, self.Player)
end

function Weapon:Deflect(id, newDir)
	local cast = self.Projectile.Get(id)
	if not cast then return end

	local speed = cast:GetVelocity().Magnitude
	self:HandleProjectileUpdate(id, nil, newDir * speed)
end

return Weapon
