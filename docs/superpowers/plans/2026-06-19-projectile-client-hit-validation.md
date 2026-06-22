# Projectile Client Hit Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace projectile hit validation's default server recast with fast, generous validation of the client's claimed hit position against rolled-back target hitboxes.

**Architecture:** Keep the change inside `ProjectileValidator` with small helper functions and one default validation path. Weapon modules forward the already-sent client velocity where their `ProcessHit` signatures receive it. Old recast helpers remain available but are no longer the default path.

**Tech Stack:** Roblox Luau, `PositionHistory`, Roblox `Ray`, existing weapon server modules.

---

### Task 1: Add Client Claim Validation Helpers

**Files:**
- Modify: `ServerScriptService/Weapon/Modules/ProjectileValidator.luau`

- [ ] **Step 1: Extend exported types**

Add optional config fields:

```luau
	ClientLineError: number?,
	ClientHitPositionError: number?,
	ValidateWorldGeometry: boolean?,
```

Add optional input metadata:

```luau
	ClientVelocity: Vector3?,
```

- [ ] **Step 2: Add point-to-part distance helper**

Add a helper that computes distance from a world point to an oriented historical part box:

```luau
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
```

- [ ] **Step 3: Add best target point helper**

Add a helper that prefers the claimed hit part, then scans the historical target frame:

```luau
local function getClosestTargetPart(frame, point: Vector3, preferredPart: BasePart?)
	local bestPartFrame = nil
	local bestDistance = math.huge

	local function test(partFrame)
		local distance = distanceToPartFrame(point, partFrame)
		if distance < bestDistance then
			bestDistance = distance
			bestPartFrame = partFrame
		end
	end

	if preferredPart and frame.partMap[preferredPart] then
		test(frame.partMap[preferredPart])
		if bestDistance <= 0 then
			return bestPartFrame, bestDistance
		end
	end

	for _, partFrame in ipairs(frame.parts) do
		if partFrame.part ~= preferredPart then
			test(partFrame)
		end
	end

	return bestPartFrame, bestDistance
end
```

- [ ] **Step 4: Add world blocker helper, disabled by default**

Add a small helper that can be enabled later:

```luau
function ProjectileValidator:_isWorldLineObviouslyBlocked(origin: Vector3, hitPosition: Vector3, targetCharacter: Model): boolean
	local delta = hitPosition - origin
	if delta.Magnitude <= 1e-6 then
		return false
	end

	local result = workspace:Raycast(origin, delta, self.RaycastParams)
	return result ~= nil and not targetCharacter:IsAncestorOf(result.Instance)
end
```

### Task 2: Implement Client Claim Path

**Files:**
- Modify: `ServerScriptService/Weapon/Modules/ProjectileValidator.luau`

- [ ] **Step 1: Store generous config defaults**

Inside `ProjectileValidator.new`, add:

```luau
		ClientLineError = config.ClientLineError or 10,
		ClientHitPositionError = config.ClientHitPositionError or 12,
		ValidateWorldGeometry = config.ValidateWorldGeometry == true,
```

- [ ] **Step 2: Add client direction helper**

Add:

```luau
local function getClientHitDirection(shot: ShotInfo, claimedHitPosition: Vector3, clientVelocity: Vector3?): Vector3?
	if typeof(clientVelocity) == "Vector3" and clientVelocity.Magnitude > 1e-6 then
		return clientVelocity.Unit
	end

	local delta = claimedHitPosition - shot.Origin
	if delta.Magnitude <= 1e-6 then
		return nil
	end

	return delta.Unit
end
```

- [ ] **Step 3: Add `_validateClientClaimedHit`**

Add a method that validates line distance, range, target proximity, optional world blocker, and returns metadata:

```luau
function ProjectileValidator:_validateClientClaimedHit(
	shot: ShotInfo,
	targetCharacter: Model,
	targetFrame,
	hitPart: BasePart?,
	claimedHitPosition: Vector3?,
	hitTime: number,
	flightTime: number,
	inflate: number,
	clientVelocity: Vector3?
): (boolean, string?, HitMetadata?)
	if not claimedHitPosition then
		return false, "MissingHitPosition", nil
	end

	local clientDirection = getClientHitDirection(shot, claimedHitPosition, clientVelocity)
	if not clientDirection then
		return false, "InvalidHitDirection", nil
	end

	local distanceAlong = (claimedHitPosition - shot.Origin):Dot(clientDirection)
	if distanceAlong < -self.OriginError then
		return false, "HitBehindOrigin", nil
	end

	local maxDistance = math.min((flightTime + self.TimeError) * self.Velocity, self.Range) + self.OriginError
	if distanceAlong > maxDistance then
		return false, "OutOfRange", nil
	end

	local ray = Ray.new(shot.Origin, clientDirection * math.max(maxDistance, 1))
	local lineError = ray:Distance(claimedHitPosition)
	local allowedLineError = self.ClientLineError + self.ProjectileRadius + self.DistError
	if lineError > allowedLineError then
		return false, "HitNotOnClientRay", nil
	end

	local partFrame, targetDistance = getClosestTargetPart(targetFrame, claimedHitPosition, hitPart)
	if not partFrame then
		return false, "MissedTarget", nil
	end

	local allowedTargetDistance = inflate + self.ClientHitPositionError
	if targetDistance > allowedTargetDistance then
		return false, "MissedTarget", nil
	end

	if self.ValidateWorldGeometry and self:_isWorldLineObviouslyBlocked(shot.Origin, claimedHitPosition, targetCharacter) then
		return false, "BlockedByWorld", nil
	end

	local hit = {
		Position = claimedHitPosition,
		Part = partFrame.part,
		PartName = partFrame.name,
		Distance = math.max(distanceAlong, 0),
	}

	return true, nil, buildHitMetadata(shot, hit, flightTime, hitTime, targetCharacter)
end
```

- [ ] **Step 4: Route `ValidateHit` through new path**

Change `ValidateHit` to accept the optional velocity argument and call `_validateClientClaimedHit` instead of `_validateStraightHit` / `_validateAcceleratedHit`.

### Task 3: Forward Client Velocity From Weapon Call Sites

**Files:**
- Modify: `ServerScriptService/Weapon/Weapons/Dartgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/DBShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/KBShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Pistol.luau`
- Modify: `ServerScriptService/Weapon/Weapons/PumpShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Revolver.luau`

- [ ] **Step 1: Pass velocity through**

Change:

```luau
function Weapon:ProcessHit(shotId, HitHum, HitPart, HitPos, time)
	local ok, reason, hit = self.ProjectileValidator:ValidateHit(shotId, HitHum, HitPart, HitPos, time)
end
```

to:

```luau
function Weapon:ProcessHit(shotId, HitHum, HitPart, HitPos, time, velocity: Vector3?)
	local ok, reason, hit = self.ProjectileValidator:ValidateHit(shotId, HitHum, HitPart, HitPos, time, velocity)
end
```

Apply this to every weapon that uses `ProjectileValidator` and receives projectile hits from `RangedBehavior`.

### Task 4: Verify

**Files:**
- Inspect: all modified files

- [ ] **Step 1: Search call sites**

Run:

```powershell
Select-String -Path ServerScriptService\Weapon\Weapons\*.luau -Pattern "ValidateHit"
```

Expected: all calls still type-compatible; `KBShotgun` forwards velocity.

- [ ] **Step 2: Search for placeholder/debug errors**

Run:

```powershell
Select-String -Path ServerScriptService\Weapon\Modules\ProjectileValidator.luau -Pattern "MissingHitPosition|HitNotOnClientRay|ValidateWorldGeometry"
```

Expected: new reasons/config exist exactly once where intended.

- [ ] **Step 3: Static review**

Run:

```powershell
Get-Content -Raw ServerScriptService\Weapon\Modules\ProjectileValidator.luau
```

Expected: no syntax-obvious issues, no stale `ok, reason, metadata` recast branch in default path.
