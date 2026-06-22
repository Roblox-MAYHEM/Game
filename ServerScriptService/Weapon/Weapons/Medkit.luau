local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local ApplyHeal	= require(Modules.Heal)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

local function init(self)
	local ThrowInfo = self.ThrowInfo
	local HealInfo = self.HealInfo

	local projectileConfig = {
		Velocity 		= ThrowInfo.PROJ_VELOCITY,
		Acceleration	= ThrowInfo.PROJ_ACCEL or Vector3.zero,
		Range 			= ThrowInfo.PROJ_RANGE,
		Name			= ThrowInfo.PROJ_NAME,
		Hitbox      	= { Active = ThrowInfo.PROJ_ACTIVE_HB ~= false, Shape = ThrowInfo.PROJ_SHAPE, Size = ThrowInfo.PROJ_SIZE },
	}

	local caster = FastCast.new()
	local hitbox = ProjectileUtils.MakeHitbox(projectileConfig.Hitbox, self.Player)
	local behavior = FastCast.newBehavior()
	behavior.MaxDistance = projectileConfig.Range or 1000
	behavior.Acceleration = projectileConfig.Acceleration or Vector3.zero
	behavior.RaycastParams = ProjectileUtils.DefaultRayParams(self.Player)

	behavior.CanPierceFunction = function(cast, result, velocity)
		if result.Normal.Y > 0.7 then
			return false
		end

		local reflect = velocity - (2 * velocity:Dot(result.Normal) * result.Normal)
		cast:SetVelocity(reflect * 0.5)
		cast:SetPosition(result.Position + result.Normal * 0.1)

		local userData = cast.UserData or {}
		local id = userData.ProjectileId
		if id then
			self.Projectile.ApplyUpdate(id, cast:GetPosition(), cast:GetVelocity(), nil)
		end

		return true
	end

	self.Projectile.RegisterCaster(caster)

	caster.CastTerminating:Connect(function(cast)
		local pos = cast:GetPosition()
		ApplyHeal(pos, self.Player, HealInfo)
	end)

	self.ProjectileCaster = caster
	self.ProjectileBehavior = behavior
	self.ProjectileHitbox = hitbox.Runtime
	self.ProjectilePacketHitbox = hitbox.Packet
end

function Weapon.new(WeaponModel, player)
	local self = BaseWeapon.new({
		Player = player,
		WeaponModel = WeaponModel,
		Name = WeaponModel.Name,
	})
	setmetatable(self, Weapon)

	self.ThrowInfo = self.Config.Throw
	self.HealInfo = self.Config.Heal

	init(self)

	return self
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self:_Unequip()
end

function Weapon:Shoot(packet)
	for _, spawn in ipairs(packet.spawns or {}) do
		local direction = spawn.direction
		if direction and direction.Magnitude > 0 then
			local cast = self.ProjectileCaster:Fire(spawn.origin, direction.Unit, spawn.velocity, self.ProjectileBehavior)
			self.Projectile.RegisterCast(spawn.id, cast, {
				Owner = self.Player,
				ProjectileType = spawn.projectileType or self.ThrowInfo.PROJ_NAME,
				Deflectable = spawn.deflectable,
				Hitbox = self.ProjectileHitbox,
			})
		end
	end

	self.Projectile.ApproveFire(self.Player, packet)
end

return Weapon
