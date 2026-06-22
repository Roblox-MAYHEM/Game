local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)

local Remotes = ReplicatedStorage.Events

local Projectile = {}
Projectile.Priority = 1

local ActiveCasts = {}
local remoteConnection = nil
local initialized = false

Projectile.ActiveCasts = ActiveCasts
Projectile.FireRequested = Signal.new()
Projectile.UpdateRequested = Signal.new()
Projectile.TerminateRequested = Signal.new()

function Projectile.CreateId(): number
	return ProjectileUtils.CreateId()
end

function Projectile.RegisterCaster(caster)
	if caster._projectileRegistered then return end
	caster._projectileRegistered = true

	caster.CastTerminating:Connect(function(cast)
		local id = cast.UserData and cast.UserData.ProjectileId
		if id then
			ActiveCasts[id] = nil
			Remotes.ReplicateProjectile:FireAllClients("Terminate", id)
		end
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

local function replicateToClients(exceptPlayer: Player?, action: string, ...)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= exceptPlayer then
			Remotes.ReplicateProjectile:FireClient(player, action, ...)
		end
	end
end

function Projectile.ApproveFire(player: Player, packet, includeOwner: boolean?)
	replicateToClients(if includeOwner then nil else player, "Fire", player, packet)
end

function Projectile.ApplyUpdate(id: number, position: Vector3?, velocity: Vector3?, owner: Player?)
	local cast = ActiveCasts[id]
	if not cast then return false end

	if position then pcall(function() cast:SetPosition(position) end) end
	if velocity then pcall(function() cast:SetVelocity(velocity) end) end
	if owner and cast.UserData then cast.UserData.Owner = owner end

	replicateToClients(owner, "Update", id, position, velocity, owner)
	return true
end

function Projectile.Terminate(id: number)
	local cast = ActiveCasts[id]
	if cast then
		ProjectileUtils.Terminate(cast)
	else
		Remotes.ReplicateProjectile:FireAllClients("Terminate", id)
	end
end

function Projectile:Init()
	if initialized then return end
	initialized = true

	remoteConnection = Remotes.ReplicateProjectile.OnServerEvent:Connect(function(player, action, ...)
		if action == "RequestFire" then
			Projectile.FireRequested:Fire(player, ...)
		elseif action == "RequestUpdate" then
			Projectile.UpdateRequested:Fire(player, ...)
		elseif action == "RequestTerminate" then
			Projectile.TerminateRequested:Fire(player, ...)
		else
			warn("[Projectile] unknown server replication call:", action)
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

	initialized = false
end

return Projectile
