--[[
self.new(Config) -- Initializes values
self:[_Behavior Name Here_]() -- Runs self
self:Unequip() -- When tool has been unequipped

selfs will perform certain self-specific moves.
Also fires events to server.
]]


local Player 			= game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")


local Remotes = ReplicatedStorage.Events
local Bindables = Client.Bindables

local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
local ProjectileUtils = require(ReplicatedStorage.Utils.ProjectileUtils)

local RangedBehavior = {}

local GOLDEN_ANGLE = math.pi * (3 - math.sqrt(5))

local function getCameraCenterDirection()
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.new(0, 0, -1)
	end

	local viewportSize = camera.ViewportSize
	if viewportSize.X > 0 and viewportSize.Y > 0 then
		local ray = camera:ViewportPointToRay(viewportSize.X * 0.5, viewportSize.Y * 0.5)
		return ray.Direction.Unit
	end

	return camera.CFrame.LookVector.Unit
end

local function processProjectileHit(self, cast, result, velocity)
	local userData = cast.UserData or {}
	if userData.HitProcessed then return end
	local _model, hitHum = ProjectileUtils.GetHumanoidHit(result)
	if userData.Deflectable and hitHum then
		userData.PendingVisual = true
		cast:SetPosition(result.Position)
		cast:Pause()
		return
	end
	userData.HitProcessed = true
	userData.PendingHitbox = nil

	local id = userData.ProjectileId
	local hitPart = result.Instance

	if hitHum then
		Remotes.WeaponEvent:FireServer(
			"ProcessHit",
			id,
			hitHum,
			hitPart,
			result.Position,
			workspace:GetServerTimeNow(),
			velocity,
			result.Normal
		)
	end

	if id then
		self.Projectile.Terminate(id)
	end
end

local function setupProjectileCaster(self)
	local shootInfo = self.ShootInfo
	local caster = FastCast.new()
	local hitbox = ProjectileUtils.MakeHitbox(shootInfo, self.Player)
	local behavior = FastCast.newBehavior()
	behavior.MaxDistance = shootInfo.PROJ_RANGE or 1000
	behavior.Acceleration = shootInfo.PROJ_ACCEL or Vector3.zero
	behavior.RaycastParams = ProjectileUtils.DefaultRayParams(self.Player)
	behavior.CanPierceFunction = function(cast, result)
		local userData = cast.UserData
		return userData ~= nil
			and userData.Deflectable == true
			and ProjectileUtils.GetHumanoidHit(result) ~= nil
	end
	local provider = self.Projectile.Visuals.ApplyProvider(behavior, shootInfo.PROJ_NAME or "Bullet", math.max(shootInfo.PELLETS or 1, 4))

	self.Projectile.RegisterCaster(caster)
	self.Projectile.Visuals.Attach(caster)
	ProjectileUtils.AttachHitboxResolver(caster, {
		Defer = shootInfo.PROJ_HITBOX_DEFER,
		Resolve = function(cast, result, velocity)
			processProjectileHit(self, cast, result, velocity)
		end,
	})

	self.ProjectileCaster = caster
	self.ProjectileBehavior = behavior
	self.ProjectileCosmeticProvider = provider
	self.ProjectileHitbox = hitbox.Runtime
	self.ProjectilePacketHitbox = hitbox.Packet
	self.ShootPoints = ProjectileUtils.GetShootPoints(self.ShootPart)
end


function RangedBehavior.__init(self)
	self.ShootInfo = self.Config.Shoot
	self.ReloadInfo = self.Config.Reload

	self.canShoot = false
	self.CAN_CANCEL_RELOAD = (self.ReloadInfo.CAN_CANCEL ~= nil) and self.ReloadInfo.CAN_CANCEL or true

	local ammoVal = self._trove:Construct(Instance, "IntValue")
	ammoVal.Name = "Ammo"
	ammoVal.Value = self.ShootInfo.MAX_AMMO
	ammoVal.Parent = self.wWeapon

	local magVal = self._trove:Construct(Instance, "IntValue")
	magVal.Name = "Mag"
	magVal.Value = self.ShootInfo.MAX_MAG
	magVal.Parent = self.wWeapon

	local spreadVal =  self._trove:Construct(Instance, "NumberValue")
	spreadVal.Name = "Spread"
	spreadVal.Value = self.ShootInfo.SPREAD or 0
	spreadVal.Parent = self.wWeapon

	self.Ammo = ammoVal
	self.Mag = magVal
	self.Spread = spreadVal

	self.ShootPart = self.WeaponModel[1]:FindFirstChild("Shoot")

	setupProjectileCaster(self)

	self._trove:Connect(self.Movement.SpreadChanged, function(value)
		self.MovementSpread = value
		self:UpdateSpread()
	end)

	self._BaseEquip = self._Equip -- very hacky way to extend the base equip function
	self._BaseUnequip = self._Unequip
end

function RangedBehavior:_Equip()
	if not self:_BaseEquip() then
		return false
	end

	task.delay(self.ShootInfo.FIRE_DELAY, function() self.canShoot = true end)
	return true
end

-- Handle the shooting logic
function RangedBehavior:_ShootBurst(): boolean?
	local burst = self.ShootInfo.BURST_FIRE
	if not burst then
		return self:_ShootOnce()
	end

	local count = type(burst) == "number" and burst or (burst.COUNT or 3)
	if count <= 1 then
		return self:_ShootOnce()
	end

	local delay = type(burst) == "table" and burst.DELAY or self.ShootInfo.FIRE_RATE
	delay = delay or self.ShootInfo.FIRE_RATE

	for i = 1, count do
		if not self:_ShootOnce(i < count and delay or nil) then
			return i > 1
		end
	end

	return true
end

function RangedBehavior:Shoot()
	if self.States.TriggerHeld then return end

	if not self.ShootInfo.AUTO_FIRE then
		self:_ShootOnce()
		return
	end

	self.States.TriggerHeld = true

	task.spawn(function()
		local pressedAt = os.clock()

		if not self:_ShootBurst() then
			self.States.TriggerHeld = false
			return
		end

		local burst = self.ShootInfo.BURST_FIRE
		if burst and (type(burst) ~= "table" or not burst.REPEAT_ON_HOLD) then
			return
		end

		while self.States.TriggerHeld and os.clock() - pressedAt < (self.ShootInfo.AUTO_DELAY or 0.25) do
			task.wait()
		end

		while self.States.TriggerHeld and self:_ShootBurst() do end
	end)
end

function RangedBehavior:_FireProjectileSpawns(origin: Vector3, direction: Vector3, packetSpawns: {})
	local projectileType = self.ShootInfo.PROJ_NAME or "Bullet"
	local speed = self.ShootInfo.PROJ_VELOCITY or ProjectileUtils.DEFAULT_VELOCITY
	local acceleration = self.ShootInfo.PROJ_ACCEL or Vector3.zero
	local range = self.ShootInfo.PROJ_RANGE or 1000
	local visualPart = self.ViewModel and self.ViewModel.Weapon and self.ViewModel.Weapon:FindFirstChild("Shoot")
	local visualOrigin = visualPart and visualPart.Position or origin

	local function fireOne(offset: Vector3, finalDirection: Vector3, shootPointIndex: number)
		if finalDirection.Magnitude <= 0 then
			return
		end

		finalDirection = finalDirection.Unit

		local id = self.Projectile.CreateId()
		local spawnOrigin = origin + offset
		local velocity = finalDirection * speed
		local spawn = {
			id = id,
			projectileType = projectileType,
			origin = spawnOrigin,
			clientOrigin = spawnOrigin,
			visualOrigin = visualOrigin,
			direction = finalDirection,
			velocity = velocity,
			acceleration = acceleration,
			maxDistance = range,
			shootPointIndex = shootPointIndex,
			hitbox = self.ProjectilePacketHitbox,
			deflectable = self.ShootInfo.PROJ_DEFLECTABLE == true,
		}

		local cast = self.ProjectileCaster:Fire(spawnOrigin, finalDirection, velocity, self.ProjectileBehavior)
		self.Projectile.Visuals.Bind(cast, visualOrigin, self.ProjectileCosmeticProvider)
		self.Projectile.RegisterCast(id, cast, {
			Owner = self.Player,
			ProjectileType = projectileType,
			Deflectable = spawn.deflectable,
			Hitbox = self.ProjectileHitbox,
		})

		table.insert(packetSpawns, spawn)
	end

	if #self.ShootPoints == 0 then
		fireOne(Vector3.zero, direction, 1)
		return
	end

	for shootPointIndex, shootPointCFrame in ipairs(self.ShootPoints) do
		local directionCF = CFrame.new(Vector3.zero, direction)
		local finalDirection = (directionCF * shootPointCFrame.Rotation).RightVector
		fireOne(shootPointCFrame.Position, finalDirection, shootPointIndex)
	end
end

function RangedBehavior:_ShootOnce(cooldownOverride: number?) : boolean?
	if not self.canShoot or self.Ammo.Value <= 0 or self.States.Shooting then return end
	if not self.ViewModel or not self.ViewModel:IsAlive() or not self.ViewModel.Weapon then return end

	if self.States.Reloading then
		if not self.CAN_CANCEL_RELOAD then return end
		self.Animations.Reload:Stop()
		self.States.Reloading = false
	end

	self.States.Shooting = true

	Bindables.Shoot:Fire()

	self:_PlayShootSound()
	self:_ApplyRecoil()
	self:_PlayShootAnimation()

	local origin, directions = self:_GetShotPattern()

	local firePacket = {
		weaponName = self.Name,
		firedAt = workspace:GetServerTimeNow(),
		spawns = {},
	}

	for _, dir in ipairs(directions) do
		self:_FireProjectileSpawns(origin, dir, firePacket.spawns)
	end

	if #firePacket.spawns > 0 then
		self.Projectile.RequestFire(firePacket)
	end

	self:_ApplyKnockback()

	if self.ShootInfo.MUZZLE_FLASH then
		-- Fixed: Access index 1 of the table for the direction
		local flashDir = type(directions) == "table" and directions[1] or directions
		self.PlayerEffects.PlayEffect("MuzzleFlash", self.ViewModel.Weapon.Shoot, flashDir)
	end

	self.Ammo.Value -= 1
	if self.Ammo.Value <= 0 then
		self:_HandleAutoReload()
		return
	end

	task.wait(cooldownOverride or self.ShootInfo.FIRE_RATE)

	self.States.Shooting = false
	return true
end

function RangedBehavior:StopShooting()
	self.States.TriggerHeld = false
end

function RangedBehavior:_ApplyKnockback()
	local knockback = self.ShootInfo.KNOCKBACK
	if not knockback then return end

	local dir = getCameraCenterDirection()
	local origin = self.Character.Head.Position
	local force = knockback
	local filter = { self.Character, self.ViewModel.ViewModel }

	if self.ShootInfo.KNOCK_HIT and self.ShootInfo.KNOCK_DIST then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = filter

		if #workspace:GetPartBoundsInRadius(origin, 2.5, params) > 0 then
			force += knockback * self.ShootInfo.KNOCK_HIT
		else
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = filter

			local hit = workspace:Spherecast(origin, 2.5, dir * self.ShootInfo.KNOCK_DIST, rayParams)
			if hit then
				force += knockback * self.ShootInfo.KNOCK_HIT
			end
		end
	end

	self.Movement:ApplyImpulse(-dir, force)
end

function RangedBehavior:_ApplyRecoil()
	self.ViewModel:AdjustSpring("gunSpring", self.ShootInfo.KICK)

	local recoil = self.ShootInfo.RECOIL / self.ShootInfo.RECOIL_DAMPENER
	self.ViewModel:AdjustSpring("recoil", recoil)
end

function RangedBehavior:_PlayShootSound()
	if self.Sounds.Shoot then
		self.Sounds.Shoot:Play()
	end
end

function RangedBehavior:_PlayShootAnimation()
	if self.States.Fanning and self.Animations.FanFire then
		self.Animations.FanFire:Play()
	elseif self.States.Aiming and self.Animations.ShootADS then
		self.Animations.ShootADS:Play() 
	elseif self.Animations.Shoot then 
		self.Animations.Shoot:Play() 
	end
end

function RangedBehavior:_GetShotPattern(): (Vector3, {Vector3})
	local shootPart = self.ViewModel.Weapon.Shoot
	local origin = shootPart.Position
	local headPos = self.Character.Head.Position

	-- 1. Wall-clip check (reuse your existing logic)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.Character, self.ViewModel.ViewModel }
	print(filter)


	if workspace:Raycast(headPos, origin - headPos, params) then
		origin = headPos
	end

	local baseDirection = getCameraCenterDirection()
	local pelletDirections = {}

	local pelletCount = self.ShootInfo.PELLETS or 1
	local spreadDegrees = self:UpdateSpread()
	local spreadRad = math.rad(spreadDegrees)

	-- 2. Generate the Conic Pattern
	-- If only 1 pellet, just fire straight
	if pelletCount <= 1 then
		table.insert(pelletDirections, baseDirection)
		return origin, pelletDirections
	end

	local lookCF = CFrame.lookAt(Vector3.zero, baseDirection)

	for i = 1, pelletCount do
		-- This creates a uniform spiral distribution
		local radius = math.sqrt(i / pelletCount) 
		local angle = i * GOLDEN_ANGLE

		local x = radius * math.cos(angle)
		local y = radius * math.sin(angle)

		-- Apply the spread scale
		local pitch = y * spreadRad
		local yaw = x * spreadRad

		local spreadCF = lookCF * CFrame.Angles(pitch, yaw, 0)
		table.insert(pelletDirections, spreadCF.LookVector)
	end

	return origin, pelletDirections
end

function RangedBehavior:UpdateSpread()
	local spread = self.ShootInfo.SPREAD or 0

	spread += self.MovementSpread or 0
	spread += self.ShotBloom or 0

	if self.States.Fanning then
		spread += self.ShootInfo.FAN_SPREAD or 0
	end

	if self.States.Aiming then
		spread *= (self.Config.AimDownSights.SPREAD_MULTIPLIER or 0.6)
	end

	self.Spread.Value = spread
	return spread
end

-- Helper: Handle automatic reloading
function RangedBehavior:_HandleAutoReload()
	if self.Mag.Value <= 0 then
		self.canShoot = false
	end

	self.States.Shooting = false
	self:Reload()
end

function RangedBehavior:_CanReload()
	return self.Mag.Value > 0 and self.Ammo.Value < self.ShootInfo.MAX_AMMO
end

function RangedBehavior:_CancelReload()
	self.States.Reloading = false
	if self.Sounds.Reload then self.Sounds.Reload:Stop() end
end

function RangedBehavior:_ReloadOnce()
	if self.States.Reloading or not self:_CanReload() then return end
	self.States.Reloading = true

	if self.Sounds.Reload then
		self.Sounds.Reload:Play()
	end

	if self.Animations.Reload then
		self.Animations.Reload:Play()
		self.Animations.Reload.Stopped:Wait()
	else
		task.wait(self.ReloadInfo.TIME or 0)
	end

	if not self.States.Reloading then return end

	-- how much to reload
	local max_ammo = self.ShootInfo.MAX_AMMO
	local ammo = self.Ammo.Value
	local mag = self.Mag.Value
	local need = max_ammo - ammo

	if need > 0 and mag > 0 then
		local take
		if self.ReloadInfo.CONTINUOUS_LOAD then
			take = math.clamp(self.ReloadInfo.LOAD_SIZE or 1, 0, math.min(need, mag))
		else
			take = math.clamp(need, 0, mag)
		end

		self.Mag.Value = mag - take
		self.Ammo.Value = ammo + take
	end

	-- cooldown between reload steps
	task.wait(self.ReloadInfo.DELAY or 0)
end

function RangedBehavior:Reload()
	if not self:_CanReload() then return end

	if not self.ReloadInfo.CONTINUOUS_LOAD then
		self:_ReloadOnce()
		self.States.Reloading = false
		return
	end

	while self:_CanReload() do
		self:_ReloadOnce()

		if not self.States.Reloading and self.ReloadInfo.CAN_CANCEL then break end
		self.States.Reloading = false
	end
end


function RangedBehavior:EnterADS()
	self.States.Aiming = true
	self.Camera:SetFOVZoom(self.Config.AimDownSights.FOV)
	self.ViewModel:aimDownSights(true)

	self:UpdateSpread()

	self.Animations.EnterADS:Play()
	self.ADSConnection = self.Animations.EnterADS.Stopped:Once(function()
		self.Animations.ADS:Play()
	end)
end

function RangedBehavior:ExitADS()
	self.States.Aiming = false
	self.Camera:SetFOVZoom(self.Config.Equip.FOV or self.Camera.BaseFOV)
	self.ViewModel:aimDownSights(false)

	self:UpdateSpread()

	if self.ADSConnection then self.ADSConnection:Disconnect() end
	self.Animations.EnterADS:Stop()
	self.Animations.ADS:Stop()
end

function RangedBehavior:_Unequip()
	self:_BaseUnequip()

	self:_CancelReload()
end

return RangedBehavior
