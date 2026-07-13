local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent

local Cooldown = require(ReplicatedStorage.Utils.Cooldown)
local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
	},
	[Enum.UserInputState.End] = {
		[Enum.UserInputType.MouseButton1] = "Throw", 
	},
}

local function setupProjectileCaster(self)
	self.ThrowInfo = self.Config.Throw

	local caster = FastCast.new()
	local hitbox = ProjectileUtils.MakeHitbox(self.ThrowInfo, self.Player)
	local behavior = FastCast.newBehavior()
	behavior.MaxDistance = self.ThrowInfo.PROJ_RANGE or 1000
	behavior.Acceleration = self.ThrowInfo.PROJ_ACCEL or Vector3.zero
	behavior.RaycastParams = ProjectileUtils.DefaultRayParams(self.Player)
	local provider = self.Projectile.Visuals.ApplyProvider(behavior, self.ThrowInfo.PROJ_NAME, 2)

	behavior.CanPierceFunction = function(cast, result, velocity)
		if result.Normal.Y > 0.7 then
			return false
		end

		local reflect = velocity - (2 * velocity:Dot(result.Normal) * result.Normal)
		cast:SetVelocity(reflect * 0.5)
		cast:SetPosition(result.Position + result.Normal * 0.1)
		return true
	end

	self.Projectile.RegisterCaster(caster)
	self.Projectile.Visuals.Attach(caster)

	self.ProjectileCaster = caster
	self.ProjectileBehavior = behavior
	self.ProjectileCosmeticProvider = provider
	self.ProjectileHitbox = hitbox.Runtime
	self.ProjectilePacketHitbox = hitbox.Packet
end

local function fireLocalThrow(self, origin: Vector3, direction: Vector3, velocity: Vector3)
	local projectileType = self.ThrowInfo.PROJ_NAME or "Medkit"
	local id = self.Projectile.CreateId()
	local spawn = {
		id = id,
		projectileType = projectileType,
		origin = origin,
		visualOrigin = origin,
		direction = direction.Unit,
		velocity = velocity,
		acceleration = self.ThrowInfo.PROJ_ACCEL or Vector3.zero,
		maxDistance = self.ThrowInfo.PROJ_RANGE,
		hitbox = self.ProjectilePacketHitbox,
		deflectable = self.ThrowInfo.PROJ_DEFLECTABLE == true,
	}

	local cast = self.ProjectileCaster:Fire(origin, spawn.direction, velocity, self.ProjectileBehavior)
	self.Projectile.Visuals.Bind(cast, origin, self.ProjectileCosmeticProvider)
	self.Projectile.RegisterCast(id, cast, {
		Owner = self.Player,
		ProjectileType = projectileType,
		Deflectable = spawn.deflectable,
		Hitbox = self.ProjectileHitbox,
	})

	return {
		weaponName = self.Name,
		firedAt = workspace:GetServerTimeNow(),
		spawns = { spawn },
	}
end



function Weapon.new(opts)
	local self = BaseWeapon.new({
		Name = opts.Name,
		WeaponModel = opts.WeaponModel,
		Binds = Weapon.Binds,
		Context = opts.Context,
	})
	setmetatable(self, Weapon)
	self:_init()

	self.States = {
		Equipped = false,
		Equipping = false,
		Throwing = false,
	}

	setupProjectileCaster(self)

	return self
end

function Weapon:_SetWeaponVis(visible : boolean)
	for _, p in ipairs(self.WeaponModel[1]:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

function Weapon:Equip()
	if not self:_Equip() then return end

	self.States.Equipping = true
	self.Animations.Equip:Play()
	self.Animations.Equip.Stopped:Wait()

	if not self.States.Equipping then return end

	self.States.Equipping = false
	self.States.Equipped = true
	self.Animations.Idle:Play()

	--set up the trajectory preview

end

function Weapon:Throw()
	if self.States.Throwing then return end
	if Cooldown.get("Throw") then return end

	self.States.Throwing = true
	local token = self:NewActionToken()
	self.Animations.Throw:Play()

	local shootPoint = self.WeaponModel[1].Primary:FindFirstChild("ShootPoint")
	local origin = shootPoint.WorldPosition
	local dir = workspace.CurrentCamera.CFrame.LookVector

	self:_SetWeaponVis(false)

	local velocity = dir * self.ThrowInfo.PROJ_VELOCITY + self.ThrowInfo.PROJ_VEL_INFLUENCE + self.HRP.AssemblyLinearVelocity
	local packet = fireLocalThrow(self, origin, dir, velocity)

	self.Projectile.RequestFire(packet)

	task.spawn(function()
		self.Animations.Throw.Stopped:Wait()
		if not self:IsActionCurrent(token) then return end
		self.States.Throwing = false
		Cooldown.set("Throw", self.ThrowInfo.COOLDOWN)
		self:_SetWeaponVis(true)
	end)
end

function Weapon:Unequip()
	self:_Unequip()
	self.States.Equipping = false
	self.States.Equipped = false

	for _, v in pairs(self.Animations) do
		if v.IsPlaying then
			v:Stop()
		end
	end

end

return Weapon
