local Terrain = game:GetService("Workspace").Terrain

local unusedPoints = {}
local usedPoints = {}

local unusedVectors = {}
local usedVectors = {}

local unusedCapsules = {}
local usedCapsules = {}

local DebugVisualize = {
	enabled = true,
}

local function popAdornmentOfClass(pool, className)
	for i = #pool, 1, -1 do
		local instance = pool[i]

		if instance:IsA(className) then
			table.remove(pool, i)
			return instance
		end
	end

	return nil
end

local function getSphere(radius, color, transparency)
	local sphere = popAdornmentOfClass(unusedCapsules, "SphereHandleAdornment")

	if not sphere then
		sphere = Instance.new("SphereHandleAdornment")
		sphere.Name = "Debug Sphere"
		sphere.AlwaysOnTop = true
		sphere.ZIndex = 2
		sphere.Adornee = Terrain
		sphere.Parent = Terrain
	end

	sphere.Radius = radius
	sphere.Color3 = color
	sphere.Transparency = transparency or 0.75
	sphere.Visible = true

	return sphere
end

local function getCylinder(length, radius, color, transparency)
	local cyl = popAdornmentOfClass(unusedCapsules, "CylinderHandleAdornment")

	if not cyl then
		cyl = Instance.new("CylinderHandleAdornment")
		cyl.Name = "Debug Cylinder"
		cyl.AlwaysOnTop = true
		cyl.ZIndex = 2
		cyl.Adornee = Terrain
		cyl.Parent = Terrain
	end

	cyl.Height = length
	cyl.Radius = radius
	cyl.Color3 = color
	cyl.Transparency = transparency or 0.75
	cyl.Visible = true

	return cyl
end

local function getBoxAdornment(transparency)
	local instance = table.remove(unusedVectors)

	if not instance then
		instance = Instance.new("BoxHandleAdornment")
		instance.Name = "Debug Box"
		instance.AlwaysOnTop = true
		instance.ZIndex = 2
		instance.Adornee = Terrain
		instance.Parent = Terrain
	end

	instance.Transparency = transparency or 0.25
	instance.Visible = true

	return instance
end

function DebugVisualize.sphere(position, radius, color, transparency)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(255, 255, 0)

	local sphere = getSphere(radius, color, transparency)
	sphere.CFrame = CFrame.new(position)

	table.insert(usedCapsules, sphere)
end

function DebugVisualize.point(position, color, radius)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(255, 0, 0)
	radius = radius or 0.12

	local instance = table.remove(unusedPoints)

	if not instance then
		instance = Instance.new("SphereHandleAdornment")
		instance.Name = "Debug Point"
		instance.ZIndex = 3
		instance.AlwaysOnTop = true
		instance.Adornee = Terrain
		instance.Parent = Terrain
	end

	instance.Radius = radius
	instance.CFrame = CFrame.new(position)
	instance.Color3 = color
	instance.Transparency = 0
	instance.Visible = true

	table.insert(usedPoints, instance)
end

function DebugVisualize.line(fromPosition, toPosition, color, thickness, transparency)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(255, 255, 255)
	thickness = thickness or 0.08

	local delta = toPosition - fromPosition
	local length = delta.Magnitude

	if length <= 0 then
		DebugVisualize.point(fromPosition, color, thickness)
		return
	end

	local instance = getBoxAdornment(transparency or 0.25)

	instance.Size = Vector3.new(thickness, thickness, length)
	instance.CFrame = CFrame.new(fromPosition, toPosition) * CFrame.new(0, 0, -length * 0.5)
	instance.Color3 = color

	table.insert(usedVectors, instance)
end

function DebugVisualize.vector(position, direction, color, thickness)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(0, 255, 0)
	thickness = thickness or 0.1

	local length = direction.Magnitude

	if length <= 0 then
		DebugVisualize.point(position, color)
		return
	end

	local instance = getBoxAdornment(0.25)

	instance.Size = Vector3.new(thickness, thickness, length)

	-- Orient along direction and shift forward so it starts at position.
	instance.CFrame = CFrame.new(position, position + direction) * CFrame.new(0, 0, -length * 0.5)
	instance.Color3 = color

	table.insert(usedVectors, instance)
end

function DebugVisualize.spherecast(origin, radius, displacement, color)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(255, 255, 0)

	local length = displacement.Magnitude

	if length <= 0 then
		DebugVisualize.sphere(origin, radius, color)
		return
	end

	local dir = displacement.Unit
	local endPos = origin + displacement
	local midPos = origin + displacement * 0.5

	local cyl = getCylinder(length, radius, color, 0.75)
	cyl.CFrame = CFrame.new(midPos, midPos + dir)
	table.insert(usedCapsules, cyl)

	local s0 = getSphere(radius, color, 0.75)
	s0.CFrame = CFrame.new(origin)
	table.insert(usedCapsules, s0)

	local s1 = getSphere(radius, color, 0.75)
	s1.CFrame = CFrame.new(endPos)
	table.insert(usedCapsules, s1)
end

function DebugVisualize.blockcast(cf, size, displacement, color)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(0, 255, 255)

	local length = displacement.Magnitude

	local instance = getBoxAdornment(if length <= 0 then 0.75 else 0.25)

	if length <= 0 then
		instance.Size = size
		instance.CFrame = cf
		instance.Color3 = color

		table.insert(usedVectors, instance)
		return
	end

	-- This shows the swept volume assuming displacement is along the block's local Z direction.
	local midCf = cf + displacement * 0.5

	instance.Size = Vector3.new(size.X, size.Y, size.Z + length)
	instance.CFrame = midCf
	instance.Color3 = color

	table.insert(usedVectors, instance)
end

function DebugVisualize.trajectory(origin, v0, accel, endTime, stepTime, color, thickness)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(255, 255, 0)
	thickness = thickness or 0.06
	stepTime = math.max(stepTime or 0.03, 1 / 240)

	if endTime <= 0 then
		DebugVisualize.point(origin, color)
		return
	end

	local currentTime = 0
	local lastPos = origin

	while currentTime < endTime do
		local nextTime = math.min(currentTime + stepTime, endTime)
		local nextPos = origin + v0 * nextTime + 0.5 * accel * (nextTime * nextTime)

		DebugVisualize.line(lastPos, nextPos, color, thickness, 0.2)

		lastPos = nextPos
		currentTime = nextTime
	end
end

function DebugVisualize.projectileSample(origin, v0, accel, t, color)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(0, 255, 255)

	local pos = origin + v0 * t + 0.5 * accel * (t * t)

	DebugVisualize.point(pos, color, 0.18)

	return pos
end

function DebugVisualize.closestPoint(point, closestPoint, allowedRadius, color)
	if not DebugVisualize.enabled then
		return
	end

	color = color or Color3.fromRGB(255, 0, 0)

	DebugVisualize.point(point, Color3.fromRGB(255, 0, 255), 0.18)
	DebugVisualize.sphere(point, allowedRadius, Color3.fromRGB(255, 0, 255), 0.85)
	DebugVisualize.point(closestPoint, Color3.fromRGB(0, 255, 0), 0.18)
	DebugVisualize.line(closestPoint, point, color, 0.14, 0.1)
end

function DebugVisualize.step()
	while #unusedPoints > 0 do
		table.remove(unusedPoints):Destroy()
	end

	while #unusedVectors > 0 do
		table.remove(unusedVectors):Destroy()
	end

	while #unusedCapsules > 0 do
		table.remove(unusedCapsules):Destroy()
	end

	usedPoints, unusedPoints = unusedPoints, usedPoints
	usedVectors, unusedVectors = unusedVectors, usedVectors
	usedCapsules, unusedCapsules = unusedCapsules, usedCapsules
end

function DebugVisualize.clear()
	for _, instance in ipairs(usedPoints) do
		instance:Destroy()
	end

	for _, instance in ipairs(unusedPoints) do
		instance:Destroy()
	end

	for _, instance in ipairs(usedVectors) do
		instance:Destroy()
	end

	for _, instance in ipairs(unusedVectors) do
		instance:Destroy()
	end

	for _, instance in ipairs(usedCapsules) do
		instance:Destroy()
	end

	for _, instance in ipairs(unusedCapsules) do
		instance:Destroy()
	end

	table.clear(usedPoints)
	table.clear(unusedPoints)
	table.clear(usedVectors)
	table.clear(unusedVectors)
	table.clear(usedCapsules)
	table.clear(unusedCapsules)
end

return DebugVisualize