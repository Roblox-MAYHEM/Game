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
	behavior.CanPierceFunction = function(cast, result)
		local userData = cast.UserData
		return userData ~= nil
			and userData.Deflectable == true
			and ProjectileUtils.GetHumanoidHit(result) ~= nil
	end

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

	local function resolveHit(cast, result, velocity, projectile, terminate)
		local userData = cast.UserData or {}
		if userData.HitProcessed then
			return false
		end
		userData.HitProcessed = true
		userData.PendingContact = nil

		if self.Callbacks.Hit then
			self.Callbacks.Hit(cast, result, velocity, projectile)
		end

		if terminate then
			local id = userData.ProjectileId
			if id then
				self.Projectile.Terminate(id)
			end
		end
		return true
	end

	local function beginPendingContact(cast, result, velocity, projectile)
		local userData = cast.UserData or {}
		if userData.PendingContact or userData.HitProcessed or not userData.Deflectable then return false end
		local target, humanoid = ProjectileUtils.GetHumanoidHit(result)
		if not humanoid then return false end

		local token = {}
		local pending = {
			Token = token,
			Position = result.Position,
			Velocity = velocity,
			Target = target,
		}
		userData.PendingContact = pending
		cast.UserData = userData
		cast:SetPosition(result.Position)
		cast:Pause()

		local id = userData.ProjectileId
		if id then self.Projectile.Pause(id, result.Position) end

		task.delay(config.DeflectGrace or 0.18, function()
			if not cast.UserData or cast.UserData.PendingContact ~= pending then return end
			cast.UserData.PendingContact = nil
			resolveHit(cast, result, velocity, projectile, true)
		end)
		return true
	end

	local function hit(cast, result, velocity, projectile, terminate)
		if beginPendingContact(cast, result, velocity, projectile) then return end
		resolveHit(cast, result, velocity, projectile, terminate)
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
		if cast.UserData then cast.UserData.PendingContact = nil end
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
