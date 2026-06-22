-- // ProjectileHitbox.lua
-- Sphere-shaped theoretical hitbox that only detects FastCast projectiles.
-- Supports projectile hitboxes (Sphere / Block) via cast.UserData.Hitbox.

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal            = require(Packages:WaitForChild("Signal"))
local Settings			= require(ReplicatedStorage.Settings)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)

local ProjectileHitbox = {}
ProjectileHitbox.__index = ProjectileHitbox

ProjectileHitbox.VISUALIZE = Settings.VisualizeDebug

local function getCameraCFrame()
	local cam = Workspace.CurrentCamera
	return cam and cam.CFrame or CFrame.new()
end

-----------------------------------------------------
-- Visualization
-----------------------------------------------------

local function createVisualSphere(self)
	if self._visualPart or not ProjectileHitbox.VISUALIZE then
		return
	end

	local part = Instance.new("Part")
	part.Name = "ProjectileHitboxSpherePart"
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Locked = true
	part.Parent = Workspace

	local sphere = Instance.new("SphereHandleAdornment")
	sphere.Name = "ProjectileHitboxSphere"
	sphere.Radius = self.Radius
	sphere.Transparency = 0.65
	sphere.AlwaysOnTop = true
	sphere.Color3 = Color3.fromRGB(255, 80, 80)
	sphere.ZIndex = 2
	sphere.Adornee = part
	sphere.Visible = true
	sphere.Parent = part

	self._visualPart = part
	self._visualSphere = sphere
end

local function updateVisualSphere(self, center)
	if not ProjectileHitbox.VISUALIZE then
		return
	end

	if not self._visualPart or not self._visualSphere then
		createVisualSphere(self)
		if not self._visualPart or not self._visualSphere then
			return
		end
	end

	self._visualSphere.Radius = self.Radius
	self._visualPart.CFrame = CFrame.new(center)
end

-----------------------------------------------------
-- Auto-stop
-----------------------------------------------------

local function scheduleAutoStop(self, durationSeconds)
	if not durationSeconds or durationSeconds <= 0 then
		return
	end

	local token = {}
	self._autoStopTok = token

	task.delay(durationSeconds, function()
		if self._autoStopTok == token then
			self:HitStop()
		end
	end)
end

-----------------------------------------------------
-- Class
-----------------------------------------------------

function ProjectileHitbox.new(player, radius, offset, projectile)
	assert(projectile, "ProjectileHitbox requires a Projectile runtime")

	local self = setmetatable({}, ProjectileHitbox)

	self.Player = player
	self.Radius = radius
	self.Offset = offset or CFrame.new()
	self.Projectile = projectile

	self.Hit = Signal.new()

	self._running     = false
	self._conn        = nil
	self._hitIds      = {}
	self._autoStopTok = nil

	self._visualPart   = nil
	self._visualSphere = nil

	local character = player.Character
	self.root = character and character:FindFirstChild("HumanoidRootPart")

	return self
end

-----------------------------------------------------
-- Step
-----------------------------------------------------

function ProjectileHitbox:_step()
	local radius = self.Radius
	if radius <= 0 then
		return
	end

	local root = self.root
	if not root or not root.Parent then
		self:HitStop()
		return
	end

	-- camera-oriented offset around the player
	local rootPos = root.Position
	local camCF = getCameraCFrame()
	local oriented = CFrame.lookAt(
		rootPos,
		rootPos + camCF.LookVector
	) * self.Offset

	local center = oriented.Position

	if ProjectileHitbox.VISUALIZE then
		updateVisualSphere(self, center)
	end

	local hitIds = self._hitIds

	local projectile = self.Projectile
	if not projectile then
		return
	end

	projectile.ForEachActiveCast(function(castId, cast)
		if hitIds[castId] then
			return
		end

		local userData = cast.UserData
		if not userData or not userData.Deflectable then
			return
		end

		if not cast:GetPosition() then
			return
		end

		if ProjectileUtils.PointInHitbox(center, radius, cast) then
			hitIds[castId] = true
			self.Hit:Fire(cast)
		end
	end)
end

function ProjectileHitbox:HitStart(durationSeconds)
	if self._running then
		scheduleAutoStop(self, durationSeconds)
		return
	end

	self._running = true
	self._hitIds = {}

	if ProjectileHitbox.VISUALIZE then
		createVisualSphere(self)
	end

	self._conn = RunService.RenderStepped:Connect(function()
		self:_step()
	end)

	scheduleAutoStop(self, durationSeconds)
end

function ProjectileHitbox:HitStop()
	if not self._running then
		return
	end

	self._running = false
	self._autoStopTok = nil

	local conn = self._conn
	if conn then
		self._conn = nil
		conn:Disconnect()
	end
end

function ProjectileHitbox:Destroy()
	self:HitStop()

	local hitSignal = self.Hit
	if hitSignal then
		self.Hit = nil
		hitSignal:Destroy()
	end

	if self._visualSphere then self._visualSphere:Destroy() end
	if self._visualPart then self._visualPart:Destroy() end

	self.Player = nil
	self.Projectile = nil
	self.Radius = nil
	self.Offset = nil
	self._hitIds = nil
end

return ProjectileHitbox
