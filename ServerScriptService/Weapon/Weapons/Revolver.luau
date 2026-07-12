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
local ImpactService = require(Modules.ImpactService)
local ProjectileValidator = require(Modules.ProjectileValidator)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

local function init(self)
	self.getDamageFalloff = DamageFalloff(self.ShootInfo.DMG_TABLE)
	self.getImpactFalloff = DamageFalloff(self.ShootInfo.IMPACT_TABLE)

	self.ProjectileValidator = ProjectileValidator.new(self.Character, {
		Velocity = self.ShootInfo.PROJ_VELOCITY,
		Acceleration = self.ShootInfo.PROJ_ACCEL or Vector3.zero,
		Range = self.ShootInfo.PROJ_RANGE,
		Hitbox = { Active = self.ShootInfo.PROJ_ACTIVE_HB ~= false, Shape = self.ShootInfo.PROJ_SHAPE, Size = self.ShootInfo.PROJ_SIZE },
		ShootPart = self.WeaponModel:FindFirstChild("Shoot", true),
	})
end

function Weapon.new(WeaponModel : Model, player : Player)
	local self = BaseWeapon.new({
		["Player"] 		= player,
		["WeaponModel"] 	= WeaponModel,
		["Name"]		= WeaponModel.Name,
	})

	setmetatable(self, Weapon)

	self.ShootInfo = self.Config.Shoot

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
	local ok, reason, approvedPacket = self.ProjectileValidator:RegisterShots(self.Player, packet)
	if not ok then warn("Rejected shoot:", reason) return end

	self.Projectile.ApproveFire(self.Player, approvedPacket or packet)
end

function Weapon:ProcessHit(id: number, HitHum: Humanoid, HitPart: BasePart, HitPos: Vector3, time: number, velocity: Vector3?)
	local ok, reason, hit = self.ProjectileValidator:ValidateHit(id, HitHum, HitPart, HitPos, time, velocity)
	if not ok then warn("Rejected hit:", reason) return end

	local HRP = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
	if not HRP then return end

	local distance = hit and hit.DistanceAlong or (HitPos - HRP.Position).Magnitude
	local damage = self.getDamageFalloff(distance)
	local targetCharacter = HitHum.Parent
	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	local direction = targetRoot and (targetRoot.Position - HRP.Position) or (HitPos - HRP.Position)

	ImpactService.ApplyHit(targetCharacter, self.Player, {
		Power = self.getImpactFalloff(distance),
		Direction = direction,
		FinisherMultiplier = self.ShootInfo.FINISHER_MULTIPLIER,
		UpwardVelocity = self.ShootInfo.FINISHER_Y,
	})
	DamageHandler.DamageHumanoid(HitHum, self.Player, damage, false)

	self.Projectile.Terminate(id)
end

return Weapon
