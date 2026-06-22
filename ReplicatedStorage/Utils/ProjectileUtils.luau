local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DebugVisualize = require(ReplicatedStorage.Utils.DebugVisualize)
local Settings = require(ReplicatedStorage.Settings)

local ProjectileUtils = {}

ProjectileUtils.DEFAULT_VELOCITY = 1500
ProjectileUtils.VisualizeSweep = Settings.VisualizeDebug
local TRAVEL_EPSILON = 0.05

local function getSphereRadius(size: number | Vector3): number
	if typeof(size) == "number" then
		return size * 0.5
	end

	return size.X * 0.5
end

local function getBlockSize(size: number | Vector3): Vector3
	if typeof(size) == "number" then
		return Vector3.new(size, size, size)
	end

	return size
end

function ProjectileUtils.CreateId(): number
	return math.floor(workspace:GetServerTimeNow() * 1e6) + math.random(1, 999999)
end

function ProjectileUtils.GetShootPoints(shootPart: Instance?): { CFrame }
	local points = {}
	if not shootPart then return points end

	for _, child in ipairs(shootPart:GetChildren()) do
		if child:IsA("Attachment") and child.Name == "ShootPoint" then
			points[#points + 1] = child.CFrame
		end
	end

	return points
end

function ProjectileUtils.DefaultRayParams(player: Player?): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local filter = {}
	if player and player.Character then filter[#filter + 1] = player.Character end

	for _, weapon in ipairs(CollectionService:GetTagged("Weapon")) do
		filter[#filter + 1] = weapon
	end

	for _, name in ipairs({ "Effects", "BulletHoleFolder", "ProjectileCache" }) do
		local container = workspace:FindFirstChild(name)
		if container then filter[#filter + 1] = container end
	end

	params.FilterDescendantsInstances = filter
	return params
end

local function packetHitbox(hitbox)
	if not hitbox then return nil end
	return {
		Active = hitbox.Active,
		Shape = hitbox.Shape,
		Size = hitbox.Size,
	}
end

local function runtimeHitbox(hitbox, owner: Player?)
	if not hitbox or hitbox.Active == false then
		return hitbox
	end

	local params = ProjectileUtils.DefaultRayParams(owner)
	params.CollisionGroup = "SpecialHitbox"

	return {
		Active = hitbox.Active,
		Shape = hitbox.Shape,
		Size = hitbox.Size,
		Params = params,
	}
end

function ProjectileUtils.MakeHitbox(info, owner: Player?)
	local shape = info and (info.PROJ_SHAPE or info.Shape)
	if not shape then
		return {
			Runtime = nil,
			Packet = nil,
		}
	end

	local active = info.PROJ_ACTIVE_HB
	if active == nil then active = info.Active end

	local hitbox = {
		Active = active ~= false,
		Shape = shape,
		Size = info.PROJ_SIZE or info.Size,
	}
	local runtime = runtimeHitbox(hitbox, owner)

	return {
		Runtime = runtime,
		Packet = packetHitbox(runtime),
	}
end

function ProjectileUtils.Terminate(cast)
	if not cast or not cast.Terminate then return end
	if cast.RayInfo then cast.RayInfo.MaxDistance = 0 end

	RunService.Heartbeat:Once(function()
		pcall(function()
			if cast and cast.Terminate then cast:Terminate() end
		end)
	end)
end

function ProjectileUtils.Sweep(
	lastPoint: Vector3,
	direction: Vector3,
	displacement: number,
	hitbox,
	_velocity: Vector3?
): RaycastResult?
	if not hitbox or hitbox.Active == false or direction.Magnitude <= 0 or displacement <= 0 then
		return nil
	end

	local travel = direction.Unit * displacement
	local result = nil

	if hitbox.Shape == "Sphere" then
		local radius = getSphereRadius(hitbox.Size)
		if ProjectileUtils.VisualizeSweep then
			DebugVisualize.spherecast(lastPoint, radius, travel)
		end

		result = workspace:Spherecast(lastPoint, radius, travel, hitbox.Params)
	elseif hitbox.Shape == "Block" then
		local size = getBlockSize(hitbox.Size)
		local cf = CFrame.new(lastPoint, lastPoint + direction)
		if ProjectileUtils.VisualizeSweep then
			DebugVisualize.blockcast(cf, size, travel)
		end

		result = workspace:Blockcast(cf, size, travel, hitbox.Params)
	end

	if result and ProjectileUtils.VisualizeSweep then
		DebugVisualize.point(result.Position, Color3.fromRGB(0, 255, 0))
	end

	return result
end

function ProjectileUtils.GetHumanoidHit(result: RaycastResult?): (Model?, Humanoid?)
	local hitPart = result and result.Instance
	local model = hitPart and hitPart:FindFirstAncestorWhichIsA("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return model, humanoid
end

local function getCastTravel(cast): number
	return (cast.StateInfo and cast.StateInfo.DistanceCovered) or math.huge
end

local function scoreHitboxCandidate(
	cast,
	point: Vector3,
	lastPoint: Vector3,
	direction: Vector3,
	displacement: number
): (number, number)
	if direction.Magnitude <= 0 or displacement <= 0 then
		return math.huge, getCastTravel(cast)
	end

	local unit = direction.Unit
	local along = math.clamp((point - lastPoint):Dot(unit), 0, displacement)
	local closest = lastPoint + unit * along
	local baseTravel = (cast.StateInfo and cast.StateInfo.DistanceCovered) or 0

	return (point - closest).Magnitude, baseTravel + along
end

local function clearPendingHitbox(cast)
	local userData = cast.UserData
	if not userData then return end

	userData.PendingHitbox = nil
	userData.HitboxToken = (userData.HitboxToken or 0) + 1
end

local function popPendingHitbox(cast, maxTravel: number?)
	local userData = cast.UserData
	local pending = userData and userData.PendingHitbox
	if not pending then return nil end

	if maxTravel and pending.Travel > maxTravel + TRAVEL_EPSILON then
		return nil
	end

	userData.PendingHitbox = nil
	userData.HitboxToken = (userData.HitboxToken or 0) + 1
	return pending
end

local function queueHitboxCandidate(
	options,
	cast,
	result: RaycastResult,
	velocity: Vector3,
	lastPoint: Vector3,
	direction: Vector3,
	displacement: number
)
	local userData = cast.UserData or {}
	if userData.HitProcessed then return end

	local _model, humanoid = ProjectileUtils.GetHumanoidHit(result)
	if not humanoid then return end

	local score, travel = scoreHitboxCandidate(cast, result.Position, lastPoint, direction, displacement)
	local pending = userData.PendingHitbox
	if pending and pending.Score <= score then
		return
	end

	local token = pending and pending.Token or ((userData.HitboxToken or 0) + 1)
	if not pending then
		userData.HitboxToken = token
	end

	userData.PendingHitbox = {
		Result = result,
		Velocity = velocity,
		Score = score,
		Travel = travel,
		Token = token,
	}
	cast.UserData = userData

	if pending then return end

	task.delay(options.Defer or 0.035, function()
		local currentData = cast.UserData
		if not currentData or currentData.HitProcessed or currentData.HitboxToken ~= token then
			return
		end

		local candidate = currentData.PendingHitbox
		if not candidate then return end

		currentData.PendingHitbox = nil
		options.Resolve(cast, candidate.Result, candidate.Velocity)
	end)
end

function ProjectileUtils.AttachHitboxResolver(caster, options)
	assert(options and options.Resolve, "AttachHitboxResolver requires Resolve")

	caster.RayHit:Connect(function(cast, result, velocity)
		local _model, humanoid = ProjectileUtils.GetHumanoidHit(result)
		if humanoid then
			clearPendingHitbox(cast)
			options.Resolve(cast, result, velocity)
			return
		end

		local pending = popPendingHitbox(cast, getCastTravel(cast))
		if pending then
			options.Resolve(cast, pending.Result, pending.Velocity)
			return
		end

		options.Resolve(cast, result, velocity)
	end)

	caster.RayPierced:Connect(function(cast, result, velocity)
		local _model, humanoid = ProjectileUtils.GetHumanoidHit(result)
		if humanoid then
			clearPendingHitbox(cast)
			options.Resolve(cast, result, velocity)
		end
	end)

	caster.LengthChanged:Connect(function(cast, lastPoint, direction, displacement, velocity)
		local userData = cast.UserData or {}
		if userData.HitProcessed then return end

		local result = ProjectileUtils.Sweep(lastPoint, direction, displacement, userData.Hitbox, velocity)
		if result then
			queueHitboxCandidate(options, cast, result, velocity, lastPoint, direction, displacement)
		end
	end)
end

function ProjectileUtils.PointInHitbox(center: Vector3, radius: number, cast): boolean
	local userData = cast.UserData
	local hitbox = userData and userData.Hitbox
	local pos = cast:GetPosition()

	if not hitbox then
		local offset = pos - center
		return offset:Dot(offset) <= radius * radius
	end

	if hitbox.Shape == "Sphere" then
		local projRadius = getSphereRadius(hitbox.Size)
		local sum = radius + projRadius
		local offset = pos - center
		return offset:Dot(offset) <= sum * sum
	elseif hitbox.Shape == "Block" then
		local size = getBlockSize(hitbox.Size)
		local half = size * 0.5
		local localPos = center - pos
		local clamped = Vector3.new(
			math.clamp(localPos.X, -half.X, half.X),
			math.clamp(localPos.Y, -half.Y, half.Y),
			math.clamp(localPos.Z, -half.Z, half.Z)
		)

		local offset = (pos + clamped) - center
		return offset:Dot(offset) <= radius * radius
	end

	local offset = pos - center
	return offset:Dot(offset) <= radius * radius
end

return ProjectileUtils
