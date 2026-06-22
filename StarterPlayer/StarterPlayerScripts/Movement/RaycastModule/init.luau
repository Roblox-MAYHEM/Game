local RayVisualizer = require(script:WaitForChild("CastVisuals"))

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local DebugVisualize = require(ReplicatedStorage.Utils.DebugVisualize)

local player = Players.LocalPlayer

local RaycastModule = {
	GroundLength = 3.5,
	EdgeLength = 10,
	WallLength = 3,
	BackLength = 6,
	WallHeights = { -1.0, -0.2, 0.8 },
	WallInset = 0.75,
	MaxPierces = 25,
	DebugWallRays = false,
}

local WALL_RAY_COLORS = {
	Left = Color3.fromRGB(255, 170, 0),
	Right = Color3.fromRGB(0, 200, 255),
	Hit = Color3.fromRGB(40, 255, 90),
	Miss = Color3.fromRGB(255, 70, 70),
	Normal = Color3.fromRGB(180, 255, 180),
}

local function obstacleRoot(inst)
	return inst and (inst:FindFirstAncestorOfClass("Model") or inst)
end

local function isVaultable(inst)
	if not inst then return false end

	if CollectionService:HasTag(inst, "Vaultable") then
		return true
	end

	local root = obstacleRoot(inst)
	return root ~= inst and CollectionService:HasTag(root, "Vaultable")
end

function RaycastModule:Init()
	self.Char = player.Character or player.CharacterAdded:Wait()
	self.HRP = self.Char:WaitForChild("HumanoidRootPart")
	self.Head = self.Char:WaitForChild("Head")
	self.Visualizer = nil

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.Char }
	params.RespectCanCollide = true
	params.IgnoreWater = true
	self.Params = params
end

function RaycastModule:_Visualize(origin, direction)
	if not self.Visualizer then
		self.Visualizer = RayVisualizer.new(Color3.fromRGB(0, 170, 255), Workspace)
	end
	self.Visualizer:Raycast(origin, direction, self.Params)
end

function RaycastModule:_DebugWallRay(side, origin, direction, result)
	if not self.DebugWallRays then return end

	local endPosition = result and result.Position or (origin + direction)
	local sideColor = WALL_RAY_COLORS[side] or Color3.fromRGB(255, 255, 255)
	local resultColor = result and WALL_RAY_COLORS.Hit or WALL_RAY_COLORS.Miss

	DebugVisualize.line(origin, endPosition, sideColor, 0.045, 0.12)
	DebugVisualize.point(origin, sideColor, 0.10)
	DebugVisualize.point(endPosition, resultColor, 0.14)

	if result then
		DebugVisualize.vector(result.Position, result.Normal, WALL_RAY_COLORS.Normal, 0.05)
	end
end

function RaycastModule:StepDebugVisuals()
	if self.DebugWallRays then
		DebugVisualize.step()
	end
end

function RaycastModule:_BuildParams(extraIgnore)
	local params = RaycastParams.new()
	params.FilterType = self.Params.FilterType
	params.FilterDescendantsInstances = table.clone(self.Params.FilterDescendantsInstances)
	params.RespectCanCollide = self.Params.RespectCanCollide
	params.IgnoreWater = self.Params.IgnoreWater
	params.CollisionGroup = self.Params.CollisionGroup

	if extraIgnore then
		for i = 1, #extraIgnore do
			params.FilterDescendantsInstances[#params.FilterDescendantsInstances + 1] = extraIgnore[i]
		end
	end

	return params
end

function RaycastModule:_IsIgnored(part)
	return not part
		or not part:IsA("BasePart")
		or not part.CanCollide
end

function RaycastModule:_Cast(origin, direction, visualize, extraIgnore)
	if visualize then
		self:_Visualize(origin, direction)
	end

	local params = if extraIgnore then self:_BuildParams(extraIgnore) else self.Params
	local ignore = if extraIgnore then params.FilterDescendantsInstances else nil
	local pos, ray = origin, direction

	for _ = 1, self.MaxPierces do
		local result = Workspace:Raycast(pos, ray, params)
		if not result then
			return nil
		end

		local hit = result.Instance
		if not self:_IsIgnored(hit) then
			return result
		end

		local left = ray.Magnitude - result.Distance
		if left <= 0 then
			return nil
		end

		if not ignore then
			params = self:_BuildParams(nil)
			ignore = params.FilterDescendantsInstances
		end

		local unit = ray.Unit
		ignore[#ignore + 1] = hit
		params.FilterDescendantsInstances = ignore
		pos = result.Position + unit * 0.01
		ray = unit * left
	end

	return nil
end

function RaycastModule:_CastInset(origin, direction, visualize, extraIgnore)
	local mag = direction.Magnitude
	if mag <= 0.001 then
		return nil
	end

	local unit = direction / mag
	return self:_Cast(origin - unit * self.WallInset, direction + unit * self.WallInset, visualize, extraIgnore)
end

function RaycastModule:_BestHit(origins, direction, visualize, extraIgnore)
	local best = nil
	for i = 1, #origins do
		local hit = self:_CastInset(origins[i], direction, visualize, extraIgnore)
		if hit and (not best or hit.Distance < best.Distance) then
			best = hit
		end
	end
	return best
end

function RaycastModule:_DirCheck(dir, visualize, length, debugSide)
	local mag = dir.Magnitude
	if mag <= 0.001 then
		return nil
	end

	local origin = self.HRP.Position
	local ray = dir / mag * (length or self.WallLength)
	local best = nil

	for i = 1, #self.WallHeights do
		local rayOrigin = origin + Vector3.new(0, self.WallHeights[i], 0)
		local hit = self:_CastInset(rayOrigin, ray, visualize)
		if debugSide then
			local unit = ray.Unit
			self:_DebugWallRay(debugSide, rayOrigin - unit * self.WallInset, ray + unit * self.WallInset, hit)
		end

		if hit and (not best or hit.Distance < best.Distance) then
			best = hit
		end
	end

	return best
end

function RaycastModule:GroundCheck(visualize, length)
	local cf = self.HRP.CFrame
	local down = Vector3.new(0, -(length or self.GroundLength), 0)
	local pos = cf.Position
	local right = cf.RightVector
	local look = cf.LookVector

	return self:_Cast(pos, down, visualize)
		or self:_Cast(pos - right + look, down, visualize)
		or self:_Cast(pos + right + look, down, visualize)
		or self:_Cast(pos - right - look, down, visualize)
		or self:_Cast(pos + right - look, down, visualize)
end

function RaycastModule:EdgeCheck(visualize, length)
	local cf = self.HRP.CFrame
	local origin = cf.Position + cf.LookVector * self.WallLength
	return self:_Cast(origin, Vector3.new(0, -(length or self.EdgeLength), 0), visualize) == nil
end

function RaycastModule:FrontCheck(visualize, length)
	return self:_DirCheck(self.HRP.CFrame.LookVector, visualize, length)
end

function RaycastModule:LeftSideCheck(visualize, length)
	return self:_DirCheck(-self.HRP.CFrame.RightVector, visualize, length, "Left")
end

function RaycastModule:RightSideCheck(visualize, length)
	return self:_DirCheck(self.HRP.CFrame.RightVector, visualize, length, "Right")
end

function RaycastModule:FrontTopCheck(visualize, length)
	return self:_Cast(self.Head.Position, self.HRP.CFrame.LookVector * (length or self.WallLength), visualize)
end

function RaycastModule:BackCheck(visualize, length)
	return self:_Cast(self.HRP.Position, -self.HRP.CFrame.LookVector * (length or self.BackLength), visualize)
end

function RaycastModule:VaultCheck(forwardDir)
	local forward = (forwardDir and forwardDir.Magnitude > 0.001)
		and forwardDir.Unit
		or self.HRP.CFrame.LookVector

	local groundHit = self:GroundCheck(false, self.GroundLength + 1.5)
	local groundY = groundHit and groundHit.Position.Y or (self.HRP.Position.Y - 3)

	local pos = self.HRP.Position
	local frontHit = self:_BestHit({
		Vector3.new(pos.X, groundY + 0.5, pos.Z),
		Vector3.new(pos.X, groundY + 1.75, pos.Z),
	}, forward * self.WallLength, false)

	if not frontHit then
		return nil, "NoFrontHit"
	end

	if not isVaultable(frontHit.Instance) then
		return nil, "NotVaultable"
	end

	local obstacle = obstacleRoot(frontHit.Instance)
	local inset = frontHit.Position - frontHit.Normal * 0.25
	local maxHeight = 12.5

	local topHit = self:_Cast(
		Vector3.new(inset.X, groundY + maxHeight + 2, inset.Z),
		-Vector3.yAxis * (maxHeight + 4),
		false
	)

	if not topHit then
		return nil, "NoTopHit"
	end

	if obstacleRoot(topHit.Instance) ~= obstacle then
		return nil, "TopMismatch"
	end

	local overHit = nil
	for distance = 2, 8 do
		local hit = self:_Cast(
			topHit.Position + Vector3.yAxis * 1.5 + forward * distance,
			-Vector3.yAxis * (maxHeight + self.GroundLength + 2),
			false
		)

		if hit and obstacleRoot(hit.Instance) ~= obstacle then
			overHit = hit
			break
		end
	end

	local delta = frontHit.Position - self.HRP.Position
	local forwardDistance = delta.X * forward.X + delta.Z * forward.Z
	local tooClose = forwardDistance > 0 and forwardDistance <= 3

	return {
		Part = frontHit.Instance,
		TopPosition = topHit.Position,
		OverHit = overHit,
		OverPosition = overHit and overHit.Position,
		HeightFromGround = topHit.Position.Y - groundY,
		TooClose = tooClose,
	}
end

function RaycastModule:Destroy()
	if self.Visualizer and self.Visualizer.Destroy then
		self.Visualizer:Destroy()
	end
end

return RaycastModule
