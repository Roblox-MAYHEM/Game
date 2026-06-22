local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)
local Visuals = require(script.Parent.Visuals)

local Remotes = ReplicatedStorage.Events
local LocalPlayer = Players.LocalPlayer

local Projectile = {}
Projectile.Priority = 1
Projectile.Visuals = Visuals

local ActiveCasts = {}
local definitions = {}
local remoteConnection = nil
local initialized = false

local DEFAULTS = {
	Bullet = { Count = 0 },
	Dart = { Count = 12 },
	Rocket = { Count = 8 },
	RPGRocket = { Count = 8 },
	Cannonball = { Count = 8 },
	Medkit = { Count = 4 },
}

Projectile.ActiveCasts = ActiveCasts

local function getDefinition(projectileType: string)
	local definition = definitions[projectileType]
	if definition then return definition end

	local caster = FastCast.new()
	Visuals.Attach(caster)

	definition = {
		Caster = caster,
		Count = (DEFAULTS[projectileType] or { Count = 8 }).Count,
	}
	definitions[projectileType] = definition

	Projectile.RegisterCaster(caster)
	return definition
end

function Projectile.CreateId(): number
	return ProjectileUtils.CreateId()
end

function Projectile.RegisterCaster(caster)
	if caster._projectileRegistered then return end
	caster._projectileRegistered = true

	caster.CastTerminating:Connect(function(cast)
		local id = cast.UserData and cast.UserData.ProjectileId
		if id then ActiveCasts[id] = nil end
	end)
end

function Projectile.RegisterCast(id: number, cast, meta)
	if not id or not cast then return nil end

	local userData = cast.UserData or {}
	userData.ProjectileId = id
	if meta then
		if meta.Owner ~= nil then userData.Owner = meta.Owner end
		if meta.ProjectileType ~= nil then userData.ProjectileType = meta.ProjectileType end
		if meta.Deflectable ~= nil then userData.Deflectable = meta.Deflectable end
		if meta.Hitbox ~= nil then userData.Hitbox = meta.Hitbox end
	end
	userData.Origin = userData.Origin or cast:GetPosition()
	cast.UserData = userData

	ActiveCasts[id] = cast
	return cast
end

function Projectile.Get(id: number)
	return ActiveCasts[id]
end

function Projectile.ForEachActiveCast(callback)
	for id, cast in pairs(ActiveCasts) do
		callback(id, cast)
	end
end

function Projectile.RequestFire(packet)
	Remotes.ReplicateProjectile:FireServer("RequestFire", packet)
end

function Projectile.ApplyUpdate(id: number, position: Vector3?, velocity: Vector3?, owner: Player?)
	local cast = ActiveCasts[id]
	if not cast then return false end

	if position then pcall(function() cast:SetPosition(position) end) end
	if velocity then pcall(function() cast:SetVelocity(velocity) end) end
	if owner and cast.UserData then cast.UserData.Owner = owner end

	return true
end

function Projectile.RequestUpdate(id: number, position: Vector3?, velocity: Vector3?)
	Projectile.ApplyUpdate(id, position, velocity, LocalPlayer)
	Remotes.ReplicateProjectile:FireServer("RequestUpdate", id, position, velocity)
end

function Projectile.Terminate(id: number)
	local cast = ActiveCasts[id]
	if cast then ProjectileUtils.Terminate(cast) end
end

function Projectile.RequestTerminate(id: number)
	Projectile.Terminate(id)
	Remotes.ReplicateProjectile:FireServer("RequestTerminate", id)
end

local function fireCosmetic(owner: Player?, spawn)
	local direction = spawn.direction
	if not direction or direction.Magnitude <= 0 then return nil end

	local projectileType = spawn.projectileType or "Bullet"
	local definition = getDefinition(projectileType)
	local behavior = FastCast.newBehavior()
	behavior.MaxDistance = spawn.maxDistance or 1000
	behavior.Acceleration = spawn.acceleration or Vector3.zero
	behavior.RaycastParams = ProjectileUtils.DefaultRayParams(owner)
	local provider = Visuals.ApplyProvider(behavior, projectileType, definition.Count)

	local velocity = spawn.velocity or direction.Unit * ProjectileUtils.DEFAULT_VELOCITY
	local cast = definition.Caster:Fire(spawn.origin, direction.Unit, velocity, behavior)

	Visuals.Bind(cast, spawn.visualOrigin or spawn.origin, provider)
	Projectile.RegisterCast(spawn.id, cast, {
		Owner = owner,
		ProjectileType = projectileType,
		Deflectable = spawn.deflectable,
		Hitbox = spawn.hitbox,
	})

	return cast
end

local function receiveFire(owner: Player, packet)
	if owner == LocalPlayer then return end
	for _, spawn in ipairs(packet.spawns or {}) do
		fireCosmetic(owner, spawn)
	end
end

function Projectile:Init()
	if initialized then return end
	initialized = true

	remoteConnection = Remotes.ReplicateProjectile.OnClientEvent:Connect(function(action, ...)
		if action == "Fire" then
			receiveFire(...)
		elseif action == "Update" then
			Projectile.ApplyUpdate(...)
		elseif action == "Terminate" then
			Projectile.Terminate(...)
		else
			warn("[Projectile] unknown client replication call:", action)
		end
	end)
end

function Projectile:Destroy()
	if remoteConnection then
		remoteConnection:Disconnect()
		remoteConnection = nil
	end

	for id, cast in pairs(ActiveCasts) do
		ActiveCasts[id] = nil
		ProjectileUtils.Terminate(cast)
	end

	table.clear(definitions)
	Visuals.Reset()
	initialized = false
end

return Projectile
