--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Behaviors will perform certain weapon-specific moves.
Modularized for easier reuse and combination.
]]

local WeaponSystem 		= script.Parent.Parent
local Modules			= WeaponSystem.Modules

local DamageHandler = require(Modules.DamageHandler)
local DamageFalloff = require(Modules.DamageFalloff)
local ProjectileValidator = require(Modules.ProjectileValidator)
local ApplyKnockback = require(Modules.Knockback)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

local function init(self)

end

function Weapon.new(WeaponModel : Model, player : Player)
	local self = BaseWeapon.new({
		["Player"] 		= player,
		["WeaponModel"] 	= WeaponModel,
		["Name"]		= WeaponModel.Name,
	})

	setmetatable(self, Weapon)

	self.ShootInfo = self.Config.Shoot

	self.getDamageFalloff = DamageFalloff(self.ShootInfo.DMG_TABLE)

	self.totalKnockback = 0

	self.ProjectileValidator = ProjectileValidator.new(self.Character, {
		ShootPart = self.WeaponModel:FindFirstChild("Shoot", true),
		Velocity = self.ShootInfo.PROJ_VELOCITY,
		Acceleration = self.ShootInfo.PROJ_ACCEL or Vector3.zero,
		Range = self.ShootInfo.PROJ_RANGE,
		Hitbox = { Active = self.ShootInfo.PROJ_ACTIVE_HB ~= false, Shape = self.ShootInfo.PROJ_SHAPE, Size = self.ShootInfo.PROJ_SIZE },
	})

	return self
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self:_Unequip()
end


function Weapon:Shoot(packet)
	local ok, reason, approvedPacket = self.ProjectileValidator:RegisterShots(self.Player, packet)
	if not ok then warn("Rejected shoot:", reason) return end

	self.Projectile.ApproveFire(self.Player, approvedPacket or packet)

	self.totalKnockback = 0
end

function Weapon:ProcessHit(shotId: string, HitHum: Humanoid, HitPart: BasePart, HitPos: Vector3, time: number, velocity)
	local ok, reason, hit = self.ProjectileValidator:ValidateHit(shotId, HitHum, HitPart, HitPos, time, velocity)
	if not ok then warn("Rejected hit:", reason) return end

	local HRP = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then return end

	local distance = hit and hit.DistanceAlong or (HitPos - HRP.Position).Magnitude
	local damage = self.getDamageFalloff(distance)

	DamageHandler.DamageHumanoid(HitHum, self.Player, damage, false)

	local knockback = math.min(self.ShootInfo.BULLET_KB_TOTAL-self.totalKnockback, self.ShootInfo.BULLET_KB)
	self.totalKnockback += knockback

	ApplyKnockback(HitHum.Parent, velocity.Unit, {FORCE = knockback})
end

return Weapon
