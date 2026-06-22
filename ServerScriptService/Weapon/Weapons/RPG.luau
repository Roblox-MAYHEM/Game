--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Behaviors will perform certain weapon-specific moves.
Modularized for easier reuse and combination.
]]

local WeaponSystem 		= script.Parent.Parent
local Modules			= WeaponSystem.Modules

local DamageHandler		= require(Modules.DamageHandler)
local ApplyExplosion	= require(Modules.Explosion)
local Knockback = require(Modules.Knockback)
local ProjectileCaster = require(Modules.ProjectileCaster)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

local function init(self)
	local ShootInfo = self.ShootInfo
	local ExplosionInfo = self.ExplosionInfo

	local projectileConfig = {
		Velocity 		= ShootInfo.PROJ_VELOCITY,
		Acceleration	= ShootInfo.PROJ_ACCEL or Vector3.zero,
		Range 			= ShootInfo.PROJ_RANGE,
		Name			= ShootInfo.PROJ_NAME,
		Hitbox      	= { Active = false, Shape = ShootInfo.PROJ_SHAPE, Size = ShootInfo.PROJ_SIZE },
		Count			= 5,
	}

	self.ProjectileCaster = ProjectileCaster.new(self.Player, projectileConfig, {
		Hit = function(cast, result: RaycastResult, vel: Vector3)
			local owner = cast.UserData.Owner
			local position = result.Position

			local hit = result.Instance
			local humanoid = hit and hit.Parent:FindFirstChildOfClass("Humanoid")

			if humanoid then
				DamageHandler.DamageHumanoid(humanoid, owner, ShootInfo.PROJ_DMG, false)
				Knockback(humanoid.Parent, vel.Unit, {
					FORCE = vel.Magnitude*.3
				})
			end

			ApplyExplosion(position, owner, ExplosionInfo)
		end,
	}, self.Projectile)
end

function Weapon.new(WeaponModel : Model, player : Player)
	local self = BaseWeapon.new({
		["Player"] 		= player,
		["WeaponModel"] 	= WeaponModel,
		["Name"]		= WeaponModel.Name,
	})

	setmetatable(self, Weapon)

	self.ShootInfo = self.Config.Shoot
	self.ExplosionInfo = self.Config.Explosion

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
		self.ProjectileCaster:FireSpawn(spawn)
	end

	self.Projectile.ApproveFire(self.Player, packet)
end

return Weapon
