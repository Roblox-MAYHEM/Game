local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Settings = require(ReplicatedStorage.Settings)
local DebugVisualize = require(ReplicatedStorage.Utils.DebugVisualize)
local DEBUG_COLOR = Color3.fromRGB(0, 235, 255)

local ClientHitbox = {}
ClientHitbox.__index = ClientHitbox

local function humanoidFromPart(part)
	local model = part and part:FindFirstAncestorOfClass("Model")
	return model and model:FindFirstChildOfClass("Humanoid")
end

function ClientHitbox.new(config)
	assert(type(config) == "table", "ClientHitbox requires virtual hitbox config")
	local character = config.Character or LocalPlayer.Character
	local self = setmetatable({
		Character = character,
		Root = character and character:FindFirstChild("HumanoidRootPart"),
		Movement = config.Movement,
		Shape = config.Shape or "Block",
		Size = config.Size or Vector3.new(8, 7, 9),
		Offset = config.Offset or CFrame.new(0, 0, -4.5),
		HitBoost = config.HitBoost or 0,
		HitBoostCap = config.HitBoostCap or math.huge,
		Boosted = false,
		HitTargets = {},
		OtherHits = {},
		HumanoidCallbacks = {},
		OtherCallbacks = {},
	}, ClientHitbox)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = false
	self.Params = params
	return self
end

function ClientHitbox:_CFrame()
	local root = self.Root
	local camera = workspace.CurrentCamera
	if not root or not root.Parent or not camera then return nil end
	local look = camera.CFrame.LookVector
	return CFrame.lookAt(root.Position, root.Position + look, camera.CFrame.UpVector) * self.Offset
end

function ClientHitbox:_PartsAt(cframe)
	if self.Shape == "Sphere" then
		return workspace:GetPartBoundsInRadius(cframe.Position, self.Size.X * 0.5, self.Params)
	end
	return workspace:GetPartBoundsInBox(cframe, self.Size, self.Params)
end

function ClientHitbox:_Emit(part)
	local humanoid = humanoidFromPart(part)
	if humanoid then
		if self.HitTargets[humanoid] then return end
		self.HitTargets[humanoid] = true

		if not self.Boosted and self.Movement and self.HitBoost > 0 then
			local camera = workspace.CurrentCamera
			if camera then
				self.Movement:Boost(camera.CFrame.LookVector, self.HitBoost, self.HitBoostCap)
				self.Boosted = true
			end
		end
		for _, callback in ipairs(self.HumanoidCallbacks) do callback(humanoid, part, nil) end
		return
	end

	if self.OtherHits[part] then return end
	self.OtherHits[part] = true
	for _, callback in ipairs(self.OtherCallbacks) do callback(part, nil) end
end

function ClientHitbox:_Sample(cframe)
	if Settings.VisualizeDebug then
		if self.Shape == "Sphere" then
			DebugVisualize.spherecast(cframe.Position, self.Size.X * 0.5, Vector3.zero, DEBUG_COLOR)
		else
			DebugVisualize.blockcast(cframe, self.Size, Vector3.zero, DEBUG_COLOR)
		end
	end
	for _, part in ipairs(self:_PartsAt(cframe)) do self:_Emit(part) end
end

function ClientHitbox:_Step()
	if Settings.VisualizeDebug then DebugVisualize.step() end
	local current = self:_CFrame()
	if not current then
		self:HitStop()
		return
	end

	local previous = self.LastCFrame or current
	local distance = (current.Position - previous.Position).Magnitude
	local stepSize = math.max(math.min(self.Size.X, self.Size.Y, self.Size.Z) * 0.45, 1)
	local steps = math.clamp(math.ceil(distance / stepSize), 1, 5)
	for index = 1, steps do
		self:_Sample(previous:Lerp(current, index / steps))
	end
	self.LastCFrame = current
end

function ClientHitbox:HitStart(duration)
	self:HitStop()
	table.clear(self.HitTargets)
	table.clear(self.OtherHits)
	self.Boosted = false
	self.LastCFrame = self:_CFrame()
	self.Connection = RunService.RenderStepped:Connect(function() self:_Step() end)
	self:_Step()

	if duration and duration > 0 then
		local token = {}
		self.StopToken = token
		task.delay(duration, function()
			if self.StopToken == token then self:HitStop() end
		end)
	end
	return self
end

function ClientHitbox:HitStop()
	self.StopToken = nil
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	return self
end

function ClientHitbox:Reconcile()
	self.Character = LocalPlayer.Character or self.Character
	self.Root = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
	self.Params.FilterDescendantsInstances = { self.Character }
	self.LastCFrame = nil
	return self
end

function ClientHitbox:OnHumHit(callback)
	self.HumanoidCallbacks[#self.HumanoidCallbacks + 1] = callback
	return self
end

function ClientHitbox:OnOtherHit(callback)
	self.OtherCallbacks[#self.OtherCallbacks + 1] = callback
	return self
end

function ClientHitbox:ResetHits()
	table.clear(self.HitTargets)
end

function ClientHitbox:Destroy()
	self:HitStop()
	table.clear(self.HumanoidCallbacks)
	table.clear(self.OtherCallbacks)
end

return ClientHitbox
