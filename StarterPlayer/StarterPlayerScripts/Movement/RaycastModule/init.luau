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
	VaultLength = 10,
	VaultCloseLength = 3,
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

local function blocksVault(inst)
	if not inst then return true end
	local root = obstacleRoot(inst)
	return CollectionService:HasTag(inst, "NoVault")
		or (root ~= inst and CollectionService:HasTag(root, "NoVault"))
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
	local direction = forwardDir or self.HRP.CFrame.LookVector
	local forward = Vector3.new(direction.X, 0, direction.Z)
	if forward.Magnitude <= 0.001 then return nil, "NoDirection" end
	forward = forward.Unit

	local up = Vector3.yAxis
	local bodyHit = self:_Cast(
		self.HRP.Position - up * 0.6,
		forward * self.VaultLength,
		false
	)
	if not bodyHit then return nil, "NoBodyHit" end
	if blocksVault(bodyHit.Instance) then
		return nil, "NoVault"
	end

	local headHit = self:_Cast(
		self.Head.Position + up,
		forward * self.VaultLength,
		false
	)
	if headHit then return nil, "HeadBlocked" end

	local closeHit = self:_Cast(
		self.HRP.Position + up * 0.1,
		forward * self.VaultCloseLength,
		false
	)

	return {
		Part = bodyHit.Instance,
		TooClose = closeHit ~= nil,
	}
end

function RaycastModule:Destroy()
	if self.Visualizer and self.Visualizer.Destroy then
		self.Visualizer:Destroy()
	end
end

return RaycastModule
