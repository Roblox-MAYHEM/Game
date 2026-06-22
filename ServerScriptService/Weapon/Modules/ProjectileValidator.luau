local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local PositionHistory = require(ServerStorage.Libraries.PositionHistory)

export type ProjectileValidatorConfig = {
	Velocity: number?,
	Acceleration: Vector3?,
	Range: number,
	Hitbox: any?,
	ShootPart: Instance?,
	TimeError: number?,
	DistError: number?,
	OriginError: number?,
	MaxClientOriginError: number?,
	ClientLineError: number?,
	ClientHitPositionError: number?,
	DuplicateHitWindow: number?,
	PendingShotWait: number?,
}

export type ShotInfo = {
	Id: any,
	Key: string,
	Player: Player,
	Origin: Vector3,
	FiredAt: number,
	ExpiresAt: number,
}

export type HitMetadata = {
	Shot: ShotInfo,
	HitPosition: Vector3,
	ClaimedHitPosition: Vector3?,
	ClaimedHitPart: BasePart?,
	HitPart: BasePart,
	HitPartName: string,
	DistanceAlong: number,
	FlightTime: number,
	HitTime: number,
	TargetCharacter: Model,
}

local EPSILON = 1e-6

local ProjectileValidator = {}
ProjectileValidator.__index = ProjectileValidator

local function getRootPart(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	return if root and root:IsA("BasePart") then root else nil
end

local function getShootPoints(shootPart: Instance?): { CFrame }
	local points = {}
	if shootPart then
		for _, child in ipairs(shootPart:GetChildren()) do
			if child:IsA("Attachment") and child.Name == "ShootPoint" then
				points[#points + 1] = child.CFrame
			end
		end
	end
	return if #points > 0 then points else { CFrame.identity }
end

local function getProjectileRadius(hitbox): number
	if not hitbox or hitbox.Active == false then return 0 end

	local size = hitbox.Size
	if typeof(size) == "number" then
		return size * 0.5
	elseif typeof(size) == "Vector3" then
		if hitbox.Shape == "Block" then
			return size.Magnitude * 0.5
		end
		return math.max(size.X, size.Y, size.Z) * 0.5
	end
	return 0
end

local function getPing(player: Player): number
	return math.max(player:GetNetworkPing() or 0, 0)
end

local function getShotKey(player: Player, shotId: any): string
	return tostring(player.UserId) .. ":" .. tostring(shotId)
end

local function cleanupShot(self, key: string)
	local shot = self._shots[key]
	if shot and self._shotLookup[tostring(shot.Id)] == key then
		self._shotLookup[tostring(shot.Id)] = nil
	end
	self._shots[key] = nil
	self._recentHits[key] = nil
end

local function cleanupExpiredShots(self, now: number)
	for key, shot in pairs(self._shots) do
		if shot.ExpiresAt <= now then
			cleanupShot(self, key)
		end
	end
end

local function getLiveShot(self, shotId: any, now: number): ShotInfo?
	local lookupKey = tostring(shotId)
	local key = self._shotLookup[lookupKey]
	local shot = key and self._shots[key]
	if not shot then
		self._shotLookup[lookupKey] = nil
		return nil
	end
	if shot.ExpiresAt <= now then
		cleanupShot(self, key)
		return nil
	end
	return shot
end

local function waitForLiveShot(self, shotId: any, now: number): ShotInfo?
	local shot = getLiveShot(self, shotId, now)
	if shot or self.PendingShotWait <= 0 then return shot end

	local deadline = os.clock() + self.PendingShotWait
	while os.clock() < deadline do
		RunService.Heartbeat:Wait()
		shot = getLiveShot(self, shotId, workspace:GetServerTimeNow())
		if shot then return shot end
	end
	return nil
end

local function packetShell(packet)
	local approved = table.clone(packet)
	approved.spawns = {}
	return approved
end

local function getMuzzleCFrame(self, frame, direction: Vector3, shootPointIndex: number): CFrame
	local shootPoint = self.ShootPoints[shootPointIndex] or self.ShootPoints[1] or CFrame.identity
	if self.ShootRootOffset then
		return frame.rootCFrame * self.ShootRootOffset * shootPoint
	end

	local head = frame.nameMap.Head
	local origin = if head then head.cframe.Position else frame.rootPos + Vector3.new(0, 1.5, 0)
	return CFrame.lookAt(origin, origin + direction) * shootPoint
end

local function updateShootRootOffset(self, character: Model)
	if not self.ShootPart or not self.ShootPart:IsDescendantOf(character) then return end

	local root = getRootPart(character)
	if root then
		self.ShootRootOffset = root.CFrame:ToObjectSpace(self.ShootPart.CFrame)
	end
end

local function computeFireTime(self, player: Player, clientFireTime: any, now: number): number
	local oneWayPing = getPing(player) * 0.5
	local estimate = now - oneWayPing
	if typeof(clientFireTime) ~= "number" then return estimate end

	local earliest = now - PositionHistory.MaxRewindSeconds
	local latest = now + math.min(self.TimeError, PositionHistory.MaxExtrapolation)
	if clientFireTime < earliest or clientFireTime > latest then return estimate end
	if math.abs(clientFireTime - estimate) <= math.max(self.TimeError, oneWayPing + 0.05) then
		return clientFireTime
	end
	return estimate
end

local function distanceToPartFrame(point: Vector3, partFrame): number
	local localPoint = partFrame.cframe:PointToObjectSpace(point)
	local half = partFrame.size * 0.5
	local clamped = Vector3.new(
		math.clamp(localPoint.X, -half.X, half.X),
		math.clamp(localPoint.Y, -half.Y, half.Y),
		math.clamp(localPoint.Z, -half.Z, half.Z)
	)
	return (localPoint - clamped).Magnitude
end

local function getClosestTargetPart(frame, point: Vector3, preferredPart: BasePart?)
	local bestPartFrame, bestDistance = nil, math.huge
	local function test(partFrame)
		local distance = distanceToPartFrame(point, partFrame)
		if distance < bestDistance then
			bestPartFrame, bestDistance = partFrame, distance
		end
	end

	if preferredPart and frame.partMap[preferredPart] then
		test(frame.partMap[preferredPart])
		if bestDistance <= 0 then return bestPartFrame, bestDistance end
	end
	for _, partFrame in ipairs(frame.parts) do
		if partFrame.part ~= preferredPart then test(partFrame) end
	end
	return bestPartFrame, bestDistance
end

local function getClientDirection(shot: ShotInfo, hitPosition: Vector3, clientVelocity: Vector3?): Vector3?
	if typeof(clientVelocity) == "Vector3" and clientVelocity.Magnitude > EPSILON then
		return clientVelocity.Unit
	end

	local delta = hitPosition - shot.Origin
	return if delta.Magnitude > EPSILON then delta.Unit else nil
end

local function buildHitMetadata(shot: ShotInfo, hit, flightTime: number, hitTime: number, targetCharacter: Model): HitMetadata
	return {
		Shot = shot,
		HitPosition = hit.Position,
		ClaimedHitPosition = nil,
		ClaimedHitPart = nil,
		HitPart = hit.Part,
		HitPartName = hit.PartName,
		DistanceAlong = hit.Distance,
		FlightTime = flightTime,
		HitTime = hitTime,
		TargetCharacter = targetCharacter,
	}
end

function ProjectileValidator.new(character: Model, config: ProjectileValidatorConfig)
	local velocity = math.max(config.Velocity or 1500, EPSILON)
	local shootPoints = getShootPoints(config.ShootPart)
	local root = getRootPart(character)
	local shootPart = if config.ShootPart and config.ShootPart:IsA("BasePart") then config.ShootPart else nil
	local shootRootOffset = if root and shootPart and shootPart:IsDescendantOf(character)
		then root.CFrame:ToObjectSpace(shootPart.CFrame)
		else nil

	local maxShootPointOffset = 0
	for _, shootPoint in ipairs(shootPoints) do
		maxShootPointOffset = math.max(maxShootPointOffset, shootPoint.Position.Magnitude)
	end

	local self = {
		Velocity = velocity,
		Acceleration = config.Acceleration or Vector3.zero,
		Range = config.Range or 1000,
		ProjectileRadius = getProjectileRadius(config.Hitbox),
		ShootPart = shootPart,
		ShootPoints = shootPoints,
		ShootRootOffset = shootRootOffset,
		MaxShootPointOffset = maxShootPointOffset,
		TimeError = config.TimeError or 2.0,
		DistError = (config.DistError or 0) + 1.5,
		OriginError = (config.OriginError or 0) + 8,
		MaxClientOriginError = config.MaxClientOriginError or 96,
		ClientLineError = config.ClientLineError or 10,
		ClientHitPositionError = config.ClientHitPositionError or 12,
		DuplicateHitWindow = config.DuplicateHitWindow or 0.2,
		PendingShotWait = config.PendingShotWait or 0.08,
		MaxFlightTime = ((config.Range or 1000) / velocity) + (config.TimeError or 2.0),
		_shots = {},
		_shotLookup = {},
		_recentHits = {},
		_nextShotCleanup = 0,
	}

	PositionHistory.RegisterCharacter(character)
	return setmetatable(self, ProjectileValidator)
end

function ProjectileValidator:RegisterShots(player: Player, packetOrShots: any, clientFireTime: number?): (boolean, string?, any?)
	local packet = packetOrShots
	if type(packetOrShots) == "table" and packetOrShots.spawns == nil then
		packet = { spawns = packetOrShots, firedAt = clientFireTime }
	end
	if not player or type(packet) ~= "table" or type(packet.spawns) ~= "table" or #packet.spawns == 0 then
		return false, "InvalidShot", nil
	end

	local character = player.Character
	if not character then return false, "NoCharacter", nil end

	local now = workspace:GetServerTimeNow()
	if now >= self._nextShotCleanup then
		cleanupExpiredShots(self, now)
		self._nextShotCleanup = now + 0.5
	end

	local fireTime = computeFireTime(self, player, packet.firedAt, now)
	local frame = PositionHistory.GetFrameAt(character, fireTime)
	if not frame then return false, "NoHistoryForOrigin", nil end
	updateShootRootOffset(self, character)

	local approvedPacket = packetShell(packet)
	approvedPacket.firedAt = fireTime
	local pendingShots, pendingKeys = {}, {}

	for _, spawn in ipairs(packet.spawns) do
		if spawn.id == nil or typeof(spawn.direction) ~= "Vector3" or spawn.direction.Magnitude <= EPSILON then
			return false, "InvalidShot", nil
		end

		local key = getShotKey(player, spawn.id)
		if self._shots[key] or pendingKeys[key] then return false, "DuplicateShotId", nil end
		pendingKeys[key] = true

		local direction = spawn.direction.Unit
		local shootPointIndex = math.clamp(tonumber(spawn.shootPointIndex) or 1, 1, #self.ShootPoints)
		local origin = getMuzzleCFrame(self, frame, direction, shootPointIndex).Position
		local clientOrigin = if typeof(spawn.origin) == "Vector3" then spawn.origin else nil

		if clientOrigin then
			local originError = self.MaxClientOriginError
				+ self.MaxShootPointOffset
				+ math.min(frame.rootVel.Magnitude * self.TimeError, self.MaxClientOriginError)
			if (clientOrigin - origin).Magnitude > originError then
				return false, "OriginImpossible", nil
			end
		end

		local approvedSpawn = table.clone(spawn)
		approvedSpawn.clientOrigin = clientOrigin
		approvedSpawn.clientVisualOrigin = if typeof(spawn.visualOrigin) == "Vector3" then spawn.visualOrigin else nil
		approvedSpawn.origin = origin
		approvedSpawn.visualOrigin = origin
		approvedSpawn.direction = direction
		approvedSpawn.velocity = direction * self.Velocity
		approvedSpawn.acceleration = self.Acceleration
		approvedSpawn.shootPointIndex = shootPointIndex
		approvedPacket.spawns[#approvedPacket.spawns + 1] = approvedSpawn

		pendingShots[#pendingShots + 1] = {
			key = key,
			shot = {
				Id = spawn.id,
				Key = key,
				Player = player,
				Origin = origin,
				FiredAt = fireTime,
				ExpiresAt = fireTime + self.MaxFlightTime,
			},
		}
	end

	for _, pending in ipairs(pendingShots) do
		self._shots[pending.key] = pending.shot
		self._shotLookup[tostring(pending.shot.Id)] = pending.key
	end

	return true, nil, approvedPacket
end

function ProjectileValidator:_validateClientHit(
	shot: ShotInfo,
	targetCharacter: Model,
	targetFrame,
	hitPart: BasePart?,
	hitPosition: Vector3?,
	hitTime: number,
	flightTime: number,
	inflate: number,
	clientVelocity: Vector3?
): (boolean, string?, HitMetadata?)
	if not hitPosition then return false, "MissingHitPosition", nil end

	local direction = getClientDirection(shot, hitPosition, clientVelocity)
	if not direction then return false, "InvalidHitDirection", nil end

	local distanceAlong = (hitPosition - shot.Origin):Dot(direction)
	if distanceAlong < -self.OriginError then return false, "HitBehindOrigin", nil end

	local maxDistance = math.min((flightTime + self.TimeError) * self.Velocity, self.Range) + self.OriginError
	if distanceAlong > maxDistance then return false, "OutOfRange", nil end

	local allowedLineError = self.ClientLineError + self.ProjectileRadius + self.DistError
	if Ray.new(shot.Origin, direction * math.max(maxDistance, 1)):Distance(hitPosition) > allowedLineError then
		return false, "HitNotOnClientRay", nil
	end

	local partFrame, targetDistance = getClosestTargetPart(targetFrame, hitPosition, hitPart)
	if not partFrame or targetDistance > inflate + self.ClientHitPositionError then
		return false, "MissedTarget", nil
	end

	return true, nil, buildHitMetadata(shot, {
		Position = hitPosition,
		Part = partFrame.part,
		PartName = partFrame.name,
		Distance = math.max(distanceAlong, 0),
	}, flightTime, hitTime, targetCharacter)
end

function ProjectileValidator:ValidateHit(
	shotId: any,
	targetHumanoid: Humanoid,
	hitPartOrPos: any,
	hitPosOrTime: any,
	hitTimeOrNil: any?,
	clientVelocityOrNil: Vector3?
): (boolean, string?, HitMetadata?)
	local hitPart, hitPosition, hitTime, clientVelocity = nil, nil, nil, nil
	if typeof(hitPartOrPos) == "Instance" then
		hitPart = if hitPartOrPos:IsA("BasePart") then hitPartOrPos else nil
		hitPosition = if typeof(hitPosOrTime) == "Vector3" then hitPosOrTime else nil
		hitTime = hitTimeOrNil
		clientVelocity = if typeof(clientVelocityOrNil) == "Vector3" then clientVelocityOrNil else nil
	else
		hitPosition = if typeof(hitPartOrPos) == "Vector3" then hitPartOrPos else nil
		hitTime = hitPosOrTime
		clientVelocity = if typeof(hitTimeOrNil) == "Vector3" then hitTimeOrNil else clientVelocityOrNil
	end

	if typeof(hitTime) ~= "number" then return false, "InvalidHitTime", nil end
	if shotId == nil then return false, "UnknownShot", nil end

	local now = workspace:GetServerTimeNow()
	local shot = waitForLiveShot(self, shotId, now)
	if not shot then return false, "UnknownShot", nil end
	now = workspace:GetServerTimeNow()

	local shooter = shot.Player
	if not shooter or not shooter.Parent then return false, "ShooterNotValid", nil end
	if not targetHumanoid or not targetHumanoid.Parent then return false, "InvalidTarget", nil end

	local targetCharacter = targetHumanoid.Parent :: Model
	if hitPart and not targetCharacter:IsAncestorOf(hitPart) then
		return false, "InvalidHitPart", nil
	end

	local shotHits = self._recentHits[shot.Key]
	if not shotHits then
		shotHits = {}
		self._recentHits[shot.Key] = shotHits
	elseif shotHits[targetHumanoid] and shotHits[targetHumanoid] > now then
		return false, "DuplicateHit", nil
	end

	local oneWayPing = getPing(shooter) * 0.5
	local maxTimeDrift = math.max(self.TimeError, oneWayPing + 0.05)
	local futureSlack = math.min(self.TimeError, PositionHistory.MaxExtrapolation)
	if hitTime > now + futureSlack
		or hitTime < now - PositionHistory.MaxRewindSeconds - self.TimeError
		or math.abs(hitTime - (now - oneWayPing)) > maxTimeDrift
	then
		return false, "HitTimeOutOfSync", nil
	end

	local flightTime = hitTime - shot.FiredAt
	if flightTime < -self.TimeError then return false, "HitBeforeShot", nil end
	flightTime = math.max(flightTime, 0)
	if flightTime > self.MaxFlightTime then return false, "OutOfRange", nil end

	local targetFrame = PositionHistory.GetFrameAt(targetCharacter, hitTime)
	if not targetFrame then return false, "NoHistoryForTarget", nil end

	local inflate = self.ProjectileRadius
		+ self.DistError
		+ math.min(targetFrame.rootVel.Magnitude * self.TimeError, self.DistError)
	local ok, reason, metadata = self:_validateClientHit(
		shot,
		targetCharacter,
		targetFrame,
		hitPart,
		hitPosition,
		hitTime,
		flightTime,
		inflate,
		clientVelocity
	)
	if not ok then return false, reason, nil end

	metadata.ClaimedHitPosition = hitPosition
	metadata.ClaimedHitPart = hitPart
	shotHits[targetHumanoid] = now + self.DuplicateHitWindow
	return true, nil, metadata
end

return ProjectileValidator
