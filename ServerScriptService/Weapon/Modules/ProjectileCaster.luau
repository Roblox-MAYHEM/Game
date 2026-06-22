local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)

local ProjectileCaster = {}
ProjectileCaster.__index = ProjectileCaster

function ProjectileCaster.new(owner: Player, config, callbacks, projectile)
	assert(projectile, "ProjectileCaster requires a Projectile runtime")

	local caster = FastCast.new()
	local hitbox = ProjectileUtils.MakeHitbox(config.Hitbox, owner)
	local behavior = FastCast.newBehavior()
	behavior.MaxDistance = config.Range or 1000
	behavior.Acceleration = config.Acceleration or Vector3.zero
	behavior.RaycastParams = config.Params or ProjectileUtils.DefaultRayParams(owner)

	local self = setmetatable({
		Owner = owner,
		Config = config,
		Callbacks = callbacks or {},
		Projectile = projectile,
		Caster = caster,
		Behavior = behavior,
		Hitbox = hitbox.Runtime,
		PacketHitbox = hitbox.Packet,
	}, ProjectileCaster)

	projectile.RegisterCaster(caster)

	local function hit(cast, result, velocity, projectile, terminate)
		local userData = cast.UserData or {}
		if userData.HitProcessed then
			return
		end
		userData.HitProcessed = true

		if self.Callbacks.Hit then
			self.Callbacks.Hit(cast, result, velocity, projectile)
		end

		if terminate then
			local id = userData.ProjectileId
			if id then
				self.Projectile.Terminate(id)
			end
		end
	end

	caster.RayHit:Connect(function(cast, result, velocity, projectile)
		hit(cast, result, velocity, projectile, false)
	end)

	caster.RayPierced:Connect(function(cast, result, velocity, projectile)
		hit(cast, result, velocity, projectile, false)
	end)

	caster.LengthChanged:Connect(function(cast, lastPoint, direction, displacement, velocity, projectile)
		local userData = cast.UserData or {}
		if userData.HitProcessed then
			return
		end

		local result = ProjectileUtils.Sweep(lastPoint, direction, displacement, userData.Hitbox, velocity)
		if result then
			hit(cast, result, velocity, projectile, true)
		end
	end)

	caster.CastTerminating:Connect(function(cast)
		if self.Callbacks.Terminated then
			self.Callbacks.Terminated(cast)
		end
	end)

	return self
end

function ProjectileCaster:FireSpawn(spawn)
	local direction = spawn.direction
	if not direction or direction.Magnitude <= 0 then
		return nil
	end

	local velocity = spawn.velocity or direction.Unit * (self.Config.Velocity or ProjectileUtils.DEFAULT_VELOCITY)
	local cast = self.Caster:Fire(spawn.origin, direction.Unit, velocity, self.Behavior)

	self.Projectile.RegisterCast(spawn.id, cast, {
		Owner = self.Owner,
		ProjectileType = spawn.projectileType or self.Config.Name,
		Deflectable = spawn.deflectable,
		Hitbox = self.Hitbox,
	})

	return cast
end

return ProjectileCaster
