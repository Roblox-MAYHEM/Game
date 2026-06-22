local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCache = require(ReplicatedStorage.Packages.PartCache)

local Assets = ReplicatedStorage:WaitForChild("Assets")

local Visuals = {}

local TRACER_LENGTH = 49
local caches = {}
local container: Folder? = nil

local function getContainer(): Folder
	if container and container.Parent then
		return container
	end

	local existing = workspace:FindFirstChild("ProjectileCache")
	if existing and existing:IsA("Folder") then
		container = existing
	else
		container = Instance.new("Folder")
		container.Name = "ProjectileCache"
		container.Parent = workspace
	end

	return container
end

local function findTemplate(projectileType: string): BasePart?
	local weaponProjectiles = Assets:FindFirstChild("Weapons") and Assets.Weapons:FindFirstChild("Projectiles")
	for _, folder in ipairs({ Assets:FindFirstChild("Projectiles"), weaponProjectiles }) do
		local template = folder and folder:FindFirstChild(projectileType)
		if template and template:IsA("BasePart") then
			return template
		end
	end

	return nil
end

local function makeFallbackTemplate(projectileType: string): BasePart?
	if projectileType == "Bullet" then return nil end

	local part = Instance.new("Part")
	part.Name = projectileType
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 245, 190)

	if projectileType == "Cannonball" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1.4, 1.4, 1.4)
	elseif projectileType == "Medkit" then
		part.Size = Vector3.new(1.6, 1.1, 1.1)
	else
		part.Size = Vector3.new(0.35, 0.35, 1.6)
	end

	return part
end

local function getProvider(projectileType: string, count: number?): PartCache.PartCache?
	local existing = caches[projectileType]
	if existing then return existing end

	local template = findTemplate(projectileType) or makeFallbackTemplate(projectileType)
	if not template then return nil end

	local folder = Instance.new("Folder")
	folder.Name = projectileType
	folder.Parent = getContainer()

	local cache = PartCache.new(template, math.max(count or 8, 1), folder)
	caches[projectileType] = cache

	if not template:IsDescendantOf(ReplicatedStorage) then
		template:Destroy()
	end

	return cache
end

local function spawnTracer(origin: Vector3, color: Color3?, width: number?)
	local model = Instance.new("Folder")
	model.Name = "Tracer"

	local startPart = Instance.new("Part")
	startPart.Name = "Start"
	startPart.Anchored = true
	startPart.CanCollide = false
	startPart.CanQuery = false
	startPart.CanTouch = false
	startPart.Transparency = 1
	startPart.Size = Vector3.new(0.1, 0.1, 0.1)
	startPart.CFrame = CFrame.new(origin)
	startPart.Parent = model

	local endPart = startPart:Clone()
	endPart.Name = "End"
	endPart.Parent = model

	local a0 = Instance.new("Attachment")
	a0.Parent = startPart

	local a1 = Instance.new("Attachment")
	a1.Parent = endPart

	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(color or Color3.fromRGB(255, 255, 255))
	beam.Width0 = width or 0.1
	beam.Width1 = width or 0.1
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Transparency = NumberSequence.new(0)
	beam.Parent = model

	model.Parent = workspace

	return {
		model = model,
		startPart = startPart,
		endPart = endPart,
		beam = beam,
		_finished = false,
	}
end

local function updateTracerModel(tracer, start: Vector3, tip: Vector3)
	if not tracer or not tracer.startPart or not tracer.endPart then return end
	if not tracer.startPart.Parent or not tracer.endPart.Parent then return end

	tracer.startPart.CFrame = CFrame.new(start)
	tracer.endPart.CFrame = CFrame.new(tip)
end

local function finishTracer(tracer, lingerTime: number?)
	if not tracer or tracer._finished then return end
	tracer._finished = true

	task.delay(lingerTime or 0.03, function()
		if tracer.beam and tracer.beam.Parent then
			tracer.beam.Enabled = false
		end
		if tracer.model and tracer.model.Parent then
			Debris:AddItem(tracer.model, 0.05)
		end
	end)
end

local function getVisualOrigin(userData, fallback: Vector3): Vector3
	return (userData and userData.VisualOrigin) or (userData and userData.Origin) or fallback
end

local function setEmitters(projectile: Instance?, enabled: boolean)
	if not projectile then return end
	for _, child in ipairs(projectile:GetDescendants()) do
		if child:IsA("Beam") or child:IsA("Trail") or child:IsA("ParticleEmitter") then
			child.Enabled = enabled
		end
	end
end

local function updateTracer(userData, point: Vector3, direction: Vector3)
	local tracer = userData and userData.Tracer
	if not tracer or direction.Magnitude <= 0 then return end

	direction = direction.Unit
	local origin = getVisualOrigin(userData, point)
	local start = point - direction * TRACER_LENGTH

	if (point - origin):Dot(direction) < TRACER_LENGTH then
		start = origin
	end

	updateTracerModel(tracer, start, point)
end

local function cleanupProjectile(userData, projectile: Instance?)
	if not projectile then return end
	setEmitters(projectile, false)

	local provider = userData and userData.CosmeticProvider
	if provider and pcall(function() provider:ReturnPart(projectile) end) then
		return
	end

	Debris:AddItem(projectile, 0)
end

function Visuals.ApplyProvider(behavior, projectileType: string?, count: number?)
	if not behavior or not projectileType then return nil end

	local provider = getProvider(projectileType, count)
	if provider then
		behavior.CosmeticBulletProvider = provider
	end

	return provider
end

function Visuals.Bind(cast, visualOrigin: Vector3?, provider)
	setEmitters(cast.RayInfo and cast.RayInfo.CosmeticBulletObject, true)

	local userData = cast.UserData or {}
	userData.Visual = true
	userData.VisualOrigin = visualOrigin
	userData.CosmeticProvider = provider
	cast.UserData = userData
end

function Visuals.Attach(caster)
	if caster._projectileVisualsAttached then return end
	caster._projectileVisualsAttached = true

	local function onHit(cast, rayResult, velocity)
		local userData = cast.UserData
		if not userData or not userData.Visual or not userData.Tracer then return end

		local delta = rayResult.Position - getVisualOrigin(userData, rayResult.Position)
		local hitDir = Vector3.zAxis
		if velocity.Magnitude > 0 then
			hitDir = velocity.Unit
		elseif delta.Magnitude > 0 then
			hitDir = delta.Unit
		end

		updateTracer(userData, rayResult.Position, hitDir)
		finishTracer(userData.Tracer, 0.03)
		userData.Tracer = nil
	end

	caster.RayHit:Connect(onHit)
	caster.RayPierced:Connect(onHit)

	caster.LengthChanged:Connect(function(cast, lastPoint, direction, displacement, _velocity, projectile)
		local userData = cast.UserData
		if not userData or not userData.Visual then return end

		userData.VisualFrames = (userData.VisualFrames or 0) + 1
		if projectile and projectile:IsA("BasePart") then
			local cf = CFrame.lookAt(lastPoint, lastPoint + direction)
			projectile.CFrame = if userData.VisualFrames > 2 then cf * CFrame.new(0, 0, -displacement * 0.5) else cf
		end

		if not userData.Tracer then
			userData.Tracer = spawnTracer(getVisualOrigin(userData, lastPoint))
		end

		updateTracer(userData, lastPoint + direction * displacement, direction)
	end)

	caster.CastTerminating:Connect(function(cast)
		local userData = cast.UserData
		local projectile = cast.RayInfo and cast.RayInfo.CosmeticBulletObject

		if userData and userData.Tracer then
			finishTracer(userData.Tracer, 0.04)
			userData.Tracer = nil
		end

		cleanupProjectile(userData, projectile)
	end)
end

function Visuals.Reset()
	for key, cache in pairs(caches) do
		cache:Dispose()
		caches[key] = nil
	end

	if container then
		container:Destroy()
		container = nil
	end
end

return Visuals
