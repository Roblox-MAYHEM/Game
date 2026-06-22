# Bat Knockback Daze Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make bat knockback reliable through movement-owned knockback, and make windup/special bat launches daze victims when they hit walls.

**Architecture:** Server melee validation stays authoritative. Server sends a structured knockback packet after a valid hit; the target client movement controller enters `Knockback`, then optionally `Dazed` after wall impact. Normal bat hit uses the same mechanism without wall daze.

**Tech Stack:** Roblox Luau, custom client movement controller, server weapon modules, existing PowerShell contract tests.

---

## Files

- Create: `tests/bat_knockback_contract.ps1`
- Modify: `ServerScriptService/Weapon/Modules/Knockback.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Transitions.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/States/Dazed.luau`
- Modify: `ServerScriptService/Weapon/Weapons/BaseballBat.luau`
- Modify: `StarterPlayer/Weapon/Weapons/BaseballBat.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

## Task 1: Add Knockback Contract Test

**Files:**
- Create: `tests/bat_knockback_contract.ps1`

- [ ] **Step 1: Write the failing contract test**

Create `tests/bat_knockback_contract.ps1` with:

```powershell
$ErrorActionPreference = "Stop"

function Read-RepoFile {
	param([string]$Path)
	return Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "..\$Path")
}

function Assert-Contains {
	param(
		[string]$Content,
		[string]$Needle,
		[string]$Message
	)

	if (-not $Content.Contains($Needle)) {
		throw $Message
	}
}

$knockback = Read-RepoFile "ServerScriptService\Weapon\Modules\Knockback.luau"
$movement = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\Handler.luau"
$transitions = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\Transitions.luau"
$movementConfig = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\Data\Config.luau"
$batServer = Read-RepoFile "ServerScriptService\Weapon\Weapons\BaseballBat.luau"
$batClient = Read-RepoFile "StarterPlayer\Weapon\Weapons\BaseballBat.luau"
$weaponConfig = Read-RepoFile "ReplicatedStorage\Assets\Weapons\Data\Config.luau"

Assert-Contains $knockback "Velocity = velocity" "Knockback packet must send target velocity, not only raw impulse."
Assert-Contains $knockback "WallDaze = params.WALL_DAZE == true" "Knockback packet must carry wall-daze flag."
Assert-Contains $knockback "root:ApplyImpulse(velocity * root.AssemblyMass)" "NPC fallback must scale launch by mass."

Assert-Contains $movement "function Movement:ApplyKnockback(packet)" "Movement must expose ApplyKnockback for knockback packets."
Assert-Contains $movement 'Events.Knockback.OnClientEvent:Connect(function(packet)' "Knockback remote must route packet through Movement:ApplyKnockback."
Assert-Contains $movement 'self.StateMachine:Change("Knockback", data)' "Movement must enter Knockback state for remote knockback."

Assert-Contains $transitions "Knockback = { `"Locomotion`" }" "Knockback state must be part of locomotion parents."
Assert-Contains $transitions "Dazed = { `"Locomotion`" }" "Dazed state must be part of locomotion parents."
Assert-Contains $transitions "Knockback = {" "Transitions must define Knockback auto exits."
Assert-Contains $transitions "Dazed = {" "Transitions must define Dazed auto exits."

Assert-Contains $movementConfig "Knockback = {" "Movement config must define Knockback state."
Assert-Contains $movementConfig "Dazed = {" "Movement config must define Dazed state."

Assert-Contains $batServer "local charge = self.WindupVal" "Bat special must capture windup charge before cancelling windup."
Assert-Contains $batServer "WALL_DAZE = true" "Bat special knockback must enable wall daze."
Assert-Contains $batServer "self.AttackValidator:BeginAttack()" "Bat special must open server melee validation window."

Assert-Contains $batClient "self.SpecialInfo = self.Config.Special" "Bat client must cache special config."
Assert-Contains $batClient "self.Hitbox:HitStart(specialTime)" "Bat special must enable client hitbox during special window."
Assert-Contains $batClient "self.Hitbox:HitStop()" "Bat special must stop client hitbox after special window."

Assert-Contains $weaponConfig "KNOCKBACK_CHARGE_MULT" "Weapon config must expose special knockback charge scaling."
Assert-Contains $weaponConfig "DAZE_DURATION" "Weapon config must expose wall daze duration."

Write-Host "Bat knockback contract OK"
```

- [ ] **Step 2: Run the contract test and verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/bat_knockback_contract.ps1
```

Expected: FAIL, first error similar to `Knockback packet must send target velocity, not only raw impulse.`

## Task 2: Convert Server Knockback to Velocity Packets

**Files:**
- Modify: `ServerScriptService/Weapon/Modules/Knockback.luau`
- Test: `tests/bat_knockback_contract.ps1`

- [ ] **Step 1: Replace the knockback module**

Replace `ServerScriptService/Weapon/Modules/Knockback.luau` with:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Events

type KnockbackParams = {
	IMPULSE: number?,
	SPEED: number?,
	Y: number?,
	YMAX: number?,
	DURATION: number?,
	CONTROL_LOCK: boolean?,
	WALL_DAZE: boolean?,
	DAZE_DURATION: number?,
	WALL_SPEED_MIN: number?,
	SOURCE: string?,
}

local DEFAULT_DURATION = 0.28
local DEFAULT_DAZE_DURATION = 0.9
local DEFAULT_WALL_SPEED_MIN = 25

local function getLaunchDirection(direction: Vector3): Vector3
	if direction.Magnitude <= 0.001 then
		return Vector3.zero
	end

	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude > 0.001 then
		return flat.Unit
	end

	return direction.Unit
end

local function buildVelocity(direction: Vector3, params: KnockbackParams): Vector3
	local launchDir = getLaunchDirection(direction)
	if launchDir == Vector3.zero then
		return Vector3.zero
	end

	local speed = params.SPEED or params.IMPULSE or 0
	local velocity = launchDir * speed
	local y = params.Y or 0

	if params.YMAX then
		y = math.min(y, params.YMAX)
	end

	return Vector3.new(velocity.X, y, velocity.Z)
end

return function(targetCharacter: Model, direction: Vector3, params: KnockbackParams)
	local root = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local velocity = buildVelocity(direction, params)
	if velocity.Magnitude <= 0.001 then
		return
	end

	local packet = {
		Velocity = velocity,
		Duration = params.DURATION or DEFAULT_DURATION,
		ControlLock = params.CONTROL_LOCK ~= false,
		WallDaze = params.WALL_DAZE == true,
		DazeDuration = params.DAZE_DURATION or DEFAULT_DAZE_DURATION,
		WallSpeedMin = params.WALL_SPEED_MIN or DEFAULT_WALL_SPEED_MIN,
		Source = params.SOURCE,
	}

	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if targetPlayer then
		Remotes.Knockback:FireClient(targetPlayer, packet)
	else
		root:ApplyImpulse(velocity * root.AssemblyMass)
	end
end
```

- [ ] **Step 2: Run the contract test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/bat_knockback_contract.ps1
```

Expected: still FAIL, now at missing `Movement:ApplyKnockback`.

## Task 3: Add Movement Knockback and Dazed States

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Transitions.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/States/Dazed.luau`
- Test: `tests/bat_knockback_contract.ps1`

- [ ] **Step 1: Add `Movement:ApplyKnockback` and route remote packets**

In `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`, replace the existing remote listener:

```lua
trove:Connect(Events.Knockback.OnClientEvent, function(impulse)
	self.HRP:ApplyImpulse(impulse)
end)
```

with:

```lua
trove:Connect(Events.Knockback.OnClientEvent, function(packet)
	self:ApplyKnockback(packet)
end)
```

Then add this method before `function Movement:SetEnabled(enabled)`:

```lua
function Movement:ApplyKnockback(packet)
	if not self.Ready or not self.HRP or not self.StateMachine then return end

	local data = {}

	if typeof(packet) == "Vector3" then
		data.Velocity = packet / math.max(self.HRP.AssemblyMass, 0.001)
	elseif typeof(packet) == "table" then
		data.Velocity = packet.Velocity or (
			packet.Impulse and packet.Impulse / math.max(self.HRP.AssemblyMass, 0.001)
		) or Vector3.zero
		data.Duration = packet.Duration
		data.ControlLock = packet.ControlLock
		data.WallDaze = packet.WallDaze
		data.DazeDuration = packet.DazeDuration
		data.WallSpeedMin = packet.WallSpeedMin
		data.Source = packet.Source
	else
		return
	end

	if data.Velocity.Magnitude <= 0.001 then return end

	self.StateMachine:Change("Knockback", data)
end
```

- [ ] **Step 2: Add movement config**

In `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`, inside `States = { ... }`, add after `Landed = { ... },`:

```lua
		Knockback = {
			Duration = 0.30,
			WallNormalDotMax = 0.35,
			MinWallSpeed = 25,
			DefaultDazeDuration = 0.9,
			CarryMultiplier = 0.85,
		},

		Dazed = {
			Duration = 0.9,
			HorizontalVelocityMultiplier = 0.08,
		},
```

- [ ] **Step 3: Add transitions**

In `StarterPlayer/StarterPlayerScripts/Movement/Transitions.luau`, add to `Transitions.Parents`:

```lua
	Knockback = { "Locomotion" },
	Dazed = { "Locomotion" },
```

Add empty key entries near other state key entries:

```lua
	Knockback = { OnBegan = {}, OnEnded = {} },
	Dazed = { OnBegan = {}, OnEnded = {} },
```

Add auto transitions inside `Transitions.Auto`:

```lua
	Knockback = {
		{ to = "Air", when = function(fsm) return fsm.States.Knockback:IsFinished() and not fsm.Frame.Grounded end },
		{ to = "Idle", when = function(fsm) return fsm.States.Knockback:IsFinished() and fsm.Frame.Grounded and fsm:IsIdle() end },
		{ to = "Running", when = function(fsm) return fsm.States.Knockback:IsFinished() and fsm.Frame.Grounded and not fsm:IsIdle() end },
	},

	Dazed = {
		{ to = "Air", when = function(fsm) return fsm.States.Dazed:IsFinished() and not fsm.Frame.Grounded end },
		{ to = "Idle", when = function(fsm) return fsm.States.Dazed:IsFinished() and fsm.Frame.Grounded and fsm:IsIdle() end },
		{ to = "Running", when = function(fsm) return fsm.States.Dazed:IsFinished() and fsm.Frame.Grounded and not fsm:IsIdle() end },
	},
```

- [ ] **Step 4: Create `Knockback` state**

Create `StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau`:

```lua
local BaseState = require(script.Parent.Parent.BaseState)

local Knockback = setmetatable({}, BaseState)
Knockback.__index = Knockback

local function isWallHit(result: RaycastResult, up: Vector3, maxDot: number): boolean
	return result.Instance
		and result.Instance:IsA("BasePart")
		and result.Instance.CanCollide
		and math.abs(result.Normal:Dot(up)) <= maxDot
end

function Knockback.new(opts)
	local self = setmetatable(BaseState.new(opts), Knockback)
	self.Time = 0
	self.Duration = 0
	self.Velocity = Vector3.zero
	self.WallDaze = false
	self.DazeDuration = 0
	self.WallSpeedMin = 0
	self.LastPosition = nil
	self.RayParams = nil
	return self
end

function Knockback:OnEnter(data)
	local Config = self.Config

	self.Time = 0
	self.Duration = data.Duration or Config.Duration
	self.Velocity = data.Velocity or Vector3.zero
	self.WallDaze = data.WallDaze == true
	self.DazeDuration = data.DazeDuration or Config.DefaultDazeDuration
	self.WallSpeedMin = data.WallSpeedMin or Config.MinWallSpeed
	self.LastPosition = self.HRP.Position

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.Character }
	params.RespectCanCollide = true
	params.IgnoreWater = true
	self.RayParams = params

	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
	self.fsm.CM.ActiveController = self.fsm.AirController
	self.fsm.GroundController.Friction = 0
	self.fsm.AirController.MaintainLinearMomentum = true
	self.fsm.AirController.MaintainAngularMomentum = false

	local currentVelocity = self.HRP.AssemblyLinearVelocity
	local deltaVelocity = self.Velocity - currentVelocity
	self.HRP:ApplyImpulse(deltaVelocity * self.HRP.AssemblyMass)
end

function Knockback:OnUpdate(dt)
	local Config = self.Config
	self.Time += dt

	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0

	local currentPosition = self.HRP.Position
	local lastPosition = self.LastPosition or currentPosition
	local displacement = currentPosition - lastPosition

	if self.WallDaze and displacement.Magnitude > 0.05 then
		local result = workspace:Raycast(lastPosition, displacement, self.RayParams)
		local speed = self.fsm.Runtime:GetMoveVelocity().Magnitude

		if result and isWallHit(result, self.fsm.CM.UpDirection, Config.WallNormalDotMax) and speed >= self.WallSpeedMin then
			self.fsm.StateMachine:Change("Dazed", {
				Duration = self.DazeDuration,
				ImpactNormal = result.Normal,
			})
			return
		end
	end

	self.LastPosition = currentPosition
end

function Knockback:OnExit()
	self.fsm.GroundController.Friction = self.fsm.BaseFriction
	self.LastPosition = nil
	self.RayParams = nil

	local current = self.HRP.AssemblyLinearVelocity
	local carry = self.Config.CarryMultiplier or 1
	self.HRP.AssemblyLinearVelocity = Vector3.new(current.X * carry, current.Y, current.Z * carry)
end

function Knockback:IsFinished()
	return self.Time >= self.Duration
end

return Knockback
```

- [ ] **Step 5: Create `Dazed` state**

Create `StarterPlayer/StarterPlayerScripts/Movement/States/Dazed.luau`:

```lua
local BaseState = require(script.Parent.Parent.BaseState)

local Dazed = setmetatable({}, BaseState)
Dazed.__index = Dazed

function Dazed.new(opts)
	local self = setmetatable(BaseState.new(opts), Dazed)
	self.Time = 0
	self.Duration = 0
	return self
end

function Dazed:OnEnter(data)
	local Config = self.Config
	self.Time = 0
	self.Duration = data.Duration or Config.Duration

	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
	self.fsm.GroundController.Friction = self.fsm.BaseFriction
	self.Humanoid.AutoRotate = false

	local current = self.HRP.AssemblyLinearVelocity
	local mult = Config.HorizontalVelocityMultiplier
	self.HRP.AssemblyLinearVelocity = Vector3.new(current.X * mult, math.min(current.Y, 0), current.Z * mult)
end

function Dazed:OnUpdate(dt)
	self.Time += dt
	self.fsm.CM.MovingDirection = Vector3.zero
	self.fsm.CM.BaseMoveSpeed = 0
end

function Dazed:OnExit()
	self.Time = 0
	self.Duration = 0
	self.Humanoid.AutoRotate = true
end

function Dazed:IsFinished()
	return self.Time >= self.Duration
end

return Dazed
```

- [ ] **Step 6: Run contract test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/bat_knockback_contract.ps1
```

Expected: still FAIL, now at bat special/config assertions.

## Task 4: Wire Bat Normal Knockback, Special Launch, and Wall Daze

**Files:**
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`
- Modify: `ServerScriptService/Weapon/Weapons/BaseballBat.luau`
- Modify: `StarterPlayer/Weapon/Weapons/BaseballBat.luau`
- Test: `tests/bat_knockback_contract.ps1`

- [ ] **Step 1: Tune bat config**

In `ReplicatedStorage/Assets/Weapons/Data/Config.luau`, inside `["BaseballBat"]`, update the bat `Attack` and `Special` blocks to include these fields:

```lua
		["Attack"] = {
			TIME = .6,
			COOLDOWN = .6,
			DMG = 80,
			KNOCKBACK_FORCE = 42,
			KNOCKBACK_Y = 12,
			KNOCKBACK_YMAX = 12,
			KNOCKBACK_DURATION = 0.28,
			WINDOW = 3,
			RANGE = 50,
			ARC = 160,
			HIT_DEBOUNCE = 0.10,
			LOS = true,
		},
```

```lua
		["Special"] = {
			BASE_DMG = 80,
			DURATION = 1,
			COOLDOWN = 5,
			WIND_MULT = 0.5,
			TIME = 2,
			HIT_TIME = 0.75,
			KNOCKBACK = true,
			KNOCKBACK_FORCE = 78,
			KNOCKBACK_CHARGE_MULT = 0.35,
			KNOCKBACK_Y = 16,
			KNOCKBACK_YMAX = 18,
			KNOCKBACK_DURATION = 0.36,
			DAZE_DURATION = 1.0,
			WALL_SPEED_MIN = 24,
		}
```

- [ ] **Step 2: Update bat server hit processing**

In `ServerScriptService/Weapon/Weapons/BaseballBat.luau`, replace `ProcessHit` with:

```lua
function Weapon:ProcessHit(targetCharacter : Model, lookDir : Vector3)
	if typeof(targetCharacter) ~= "Instance" or not targetCharacter:IsA("Model") then
		return false
	end

	local ok, reason = self.AttackValidator:ValidateHit(targetCharacter)
	print(ok, reason)
	if not ok then return false end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local now = time()
	local currentAttack = self.CurrentAttack
	local isSpecial = currentAttack
		and currentAttack.IsSpecial == true
		and now <= currentAttack.EndTime

	local charge = if isSpecial then currentAttack.Charge or 0 else 0
	local damage = if isSpecial
		then (self.SpecialInfo.BASE_DMG or self.AttackInfo.DMG) + charge * (self.SpecialInfo.WIND_MULT or 0)
		else self.AttackInfo.DMG

	DamageHandler.DamageHumanoid(humanoid, self.Player, damage, false)

	local direction = lookDir
	if typeof(direction) ~= "Vector3" or direction.Magnitude <= 0.001 then
		local attackerRoot = self.Character and self.Character:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if attackerRoot and targetRoot then
			direction = targetRoot.Position - attackerRoot.Position
		else
			direction = Vector3.new(0, 0, -1)
		end
	end

	local knockbackForce = self.AttackInfo.KNOCKBACK_FORCE
	local knockbackParams = {
		IMPULSE = knockbackForce,
		Y = self.AttackInfo.KNOCKBACK_Y,
		YMAX = self.AttackInfo.KNOCKBACK_YMAX,
		DURATION = self.AttackInfo.KNOCKBACK_DURATION,
		SOURCE = "BaseballBat",
	}

	if isSpecial then
		knockbackParams.IMPULSE = (self.SpecialInfo.KNOCKBACK_FORCE or knockbackForce)
			+ charge * (self.SpecialInfo.KNOCKBACK_CHARGE_MULT or 0)
		knockbackParams.Y = self.SpecialInfo.KNOCKBACK_Y or self.AttackInfo.KNOCKBACK_Y
		knockbackParams.YMAX = self.SpecialInfo.KNOCKBACK_YMAX or self.AttackInfo.KNOCKBACK_YMAX
		knockbackParams.DURATION = self.SpecialInfo.KNOCKBACK_DURATION or self.AttackInfo.KNOCKBACK_DURATION
		knockbackParams.WALL_DAZE = true
		knockbackParams.DAZE_DURATION = self.SpecialInfo.DAZE_DURATION
		knockbackParams.WALL_SPEED_MIN = self.SpecialInfo.WALL_SPEED_MIN
		knockbackParams.SOURCE = "BaseballBatSpecial"
	end

	ApplyKnockback(targetCharacter, direction, knockbackParams)

	return true
end
```

- [ ] **Step 3: Update bat server special release**

In `ServerScriptService/Weapon/Weapons/BaseballBat.luau`, replace `Special` with:

```lua
function Weapon:Special()
	if not self.Winding then return false end

	local charge = self.WindupVal
	self:CancelWindup()

	local now = time()
	local duration = self.SpecialInfo.HIT_TIME or self.SpecialInfo.DURATION or self.SpecialInfo.TIME or 1

	self.AttackValidator:BeginAttack()

	local attack = {
		StartTime = now,
		EndTime = now + duration,
		Duration = duration,
		IsSpecial = true,
		Charge = charge,
	}

	self.CurrentAttack = attack

	task.delay(duration, function()
		if self.CurrentAttack == attack then
			self.CurrentAttack = nil
			self.AttackValidator:EndAttack()
		end
	end)

	return true
end
```

- [ ] **Step 4: Update bat client special hitbox**

In `StarterPlayer/Weapon/Weapons/BaseballBat.luau`, after `self.AttackInfo = self.Config.Attack`, add:

```lua
	self.SpecialInfo = self.Config.Special
```

Replace `Special` with:

```lua
function Weapon:Special()
	if not self.States.Windup then return end

	self.States.Windup = false
	self.Animations.Windup:Stop()

	self.States.Special = true
	Remotes.WeaponEvent:FireServer("Special")

	self.Animations.Special:Play()
	if self.Sounds.Swing then
		self.Sounds.Swing:Play()
	end

	local totalTime = self.SpecialInfo and self.SpecialInfo.TIME or 1
	local specialTime = self.SpecialInfo and (self.SpecialInfo.HIT_TIME or self.SpecialInfo.DURATION or self.SpecialInfo.TIME) or 1

	self.Hitbox:HitStart(specialTime)
	task.wait(specialTime)
	self.Hitbox:HitStop()

	local remaining = totalTime - specialTime
	if remaining > 0 then
		task.wait(remaining)
	end

	self.States.Special = false
end
```

- [ ] **Step 5: Run contract test and verify green**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/bat_knockback_contract.ps1
```

Expected: PASS with `Bat knockback contract OK`.

## Task 5: Regression and Manual Verification

**Files:**
- Test: `tests/bat_knockback_contract.ps1`
- Test: `tests/data_replica_contract.ps1`

- [ ] **Step 1: Run new contract test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/bat_knockback_contract.ps1
```

Expected: PASS with `Bat knockback contract OK`.

- [ ] **Step 2: Run existing contract test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests/data_replica_contract.ps1
```

Expected: PASS with `Player data replica contract OK`.

- [ ] **Step 3: Perform Studio playtest checks**

In Roblox Studio with two players:

```text
1. Equip baseball bat.
2. Hit target with normal left-click while target stands on ground.
3. Confirm target moves horizontally and is not dazed after touching wall.
4. Hold right-click until windup has charge, release near target.
5. Confirm target launches farther than normal hit.
6. Repeat special hit with wall behind target.
7. Confirm target enters brief daze on wall impact, then movement returns.
8. Kill or respawn target during/after daze.
9. Confirm movement is not left locked after character cleanup.
```

Expected: all checks pass. If a physics number feels weak or excessive, tune only values in `ReplicatedStorage/Assets/Weapons/Data/Config.luau` and rerun checks.

## Commit Note

This shell currently cannot find `git` through `git status` or `where.exe git`. If `git` becomes available, commit after Task 5 with:

```powershell
git add tests/bat_knockback_contract.ps1 ServerScriptService/Weapon/Modules/Knockback.luau StarterPlayer/StarterPlayerScripts/Movement/Handler.luau StarterPlayer/StarterPlayerScripts/Movement/Transitions.luau StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau StarterPlayer/StarterPlayerScripts/Movement/States/Dazed.luau ServerScriptService/Weapon/Weapons/BaseballBat.luau StarterPlayer/Weapon/Weapons/BaseballBat.luau ReplicatedStorage/Assets/Weapons/Data/Config.luau docs/superpowers/specs/2026-06-20-bat-knockback-daze-design.md docs/superpowers/plans/2026-06-20-bat-knockback-daze.md
git commit -m "feat: add bat knockback wall daze"
```

If `git` remains unavailable, do not claim a commit was made.
