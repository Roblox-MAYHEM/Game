# Combat Lifecycle and Weapon Feel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate reset/death/round/knockback lifecycle and make Mayhem's core melee-mobility weapons responsive, readable, and useful in cross-weapon party-shooter combos.

**Architecture:** Keep current Round, Deploy, DamageHandler, ImpactService, Movement, Camera, and per-weapon modules. Establish one explicit cleanup path and one server weapon-event route, then let separate weapon files own small anticipation/active/recovery sequences. Existing Replica and config hot-reload systems remain transport boundaries.

**Tech Stack:** Roblox Luau, Replica, ControllerManager physics, existing CameraShaker, detached melee volumes, FastCast projectile runtime.

## Global Constraints

- Keep separate duplicate weapon files as future extension points.
- Do not create a generic ability or attack state-machine framework.
- Keep `confighotreload.luau` unchanged.
- Keep `Config.DISABLED = true`; sandbox combat works with scoring disabled.
- Use Replica only for persistent RoundState and PlayerData.
- Preserve current velocity across swaps/actions unless a weapon explicitly brakes it.
- Required assets are established once; do not add repeated defensive guards.
- No new test framework or broad numerical rebalance.
- Preserve unrelated dirty files and user changes.
- Do not retry unavailable commits.

---

### Task 1: Unify death, reset, Impact, deploy, and scoring lifecycle

**Files:**
- Modify: `ServerScriptService/Weapon/Modules/ImpactService.luau`
- Modify: `ServerScriptService/Weapon/Modules/DamageHandler.luau`
- Modify: `ServerScriptService/Round/DeploySystem.luau`
- Modify: `ServerScriptService/Round/Handler.luau`

**Interfaces:**
- Produces: `ImpactService.Clear(character: Model)`.
- Produces: `DamageHandler.SetScoringEnabled(enabled: boolean)`.
- Produces: `DamageHandler.ClearCharacter(character: Model)`.
- Consumes: existing `PlayerKilled`, `Assist`, `PlayerKill`, `EnableMenu`, deployed attributes, and Round phase transitions.

- [ ] **Step 1: Add explicit Impact cleanup**

`Clear` removes the internal state and resets `Impact`, `ImpactPrimed`, `ImpactPips`, and `ImpactProtected` attributes. Heartbeat still removes unparented characters as fallback.

- [ ] **Step 2: Restore real damage/death and separate scoring from death feedback**

Remove the temporary commented damage block. Mark `Dead`, clear Impact, set humanoid health/state, then publish `PlayerKill` once. Gate leaderboard/progression bindables and LevelSystem awards behind module-level scoring mode. Keep kill attribution logic unchanged for combat deaths.

- [ ] **Step 3: Route reset through lifecycle**

When deployed, reset kills through `DamageHandler` with self as forced killer. When not deployed, clear character combat state and fire `EnableMenu` without a kill/death-screen event. Already-dead characters return immediately.

- [ ] **Step 4: Make deploy cleanup canonical**

On humanoid death, clear both player and character `Deployed` attributes. At round end, mark undeployed, clear combat state, kill/remove the character without `PlayerKill`, then fire `EnableMenu`. Delete fake kill publication from `ResetAllPlayers`.

- [ ] **Step 5: Set scoring from Round phase**

Scoring is false in sandbox, idle, countdown, ended, catch, and finally paths; true only when phase enters `Round`.

### Task 2: Add severity-based hard-landing shock

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Locomotion.luau`
- Modify: `StarterPlayer/Libraries/ViewmodelController/init.luau`

**Interfaces:**
- Produces: `Movement:GetLandingShock(): number` in `[0, 1]`.
- Consumes: `properties.Camera:CameraShake("ShakeOnce", ...)`, existing `SpreadChanged`, and `ViewModel:AdjustSpring`.

- [ ] **Step 1: Store one transient shock envelope**

On hard landing, save severity and recovery end time. Buffered jump multiplies severity by existing buffered response scale. Add compact config for recovery duration, spread penalty, steering/acceleration loss, and camera/viewmodel response.

- [ ] **Step 2: Feed shock into locomotion**

Blend ground `TurnSpeedFactor`, `AccelerationTime`, and landing carry control from shocked to normal using the decaying envelope. Preserve input and actions; do not create a stun/state.

- [ ] **Step 3: Feed shock into spread and presentation**

Add shock penalty to movement spread before firing `SpreadChanged`. On landing, invoke one severity-scaled camera `ShakeOnce` and add a downward viewmodel spring impulse. Buffered jumps receive only the reduced severity.

### Task 3: Flatten shared weapon data and remote lifecycle

**Files:**
- Modify: `StarterPlayer/Weapon/BaseWeapon.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Weapon.luau`
- Modify: `ServerScriptService/Weapon/BaseWeapon.luau`
- Modify: `ServerScriptService/Weapon/Handler.luau`

**Interfaces:**
- Produces: `BaseWeapon.ReloadConfig()` on client and server.
- Produces: `BaseWeapon:NewActionToken()` and `BaseWeapon:IsActionCurrent(token)` client-side.
- Consumes: `DevConfigRevision`, existing hotbar rebuild, and equipped weapon lookup.

- [ ] **Step 1: Replace per-instance Data folder scans**

Load Config explicitly through a revision snapshot and load Animations/Info through normal cached requires. `_init` indexes only the current weapon name. Keep model-derived optional audio behavior unchanged unless touched weapon assets establish required names.

- [ ] **Step 2: Refresh config once per revision**

Before client/server hotbar rebuild on `DevConfigRevision`, call `BaseWeapon.ReloadConfig()`. Do not edit the Studio plugin.

- [ ] **Step 3: Centralize server WeaponEvent routing**

Add one handler connection that routes non-projectile callbacks to the current equipped weapon after deployed/current-character checks. Remove remote connection creation/destruction from server BaseWeapon equip lifecycle.

- [ ] **Step 4: Add minimal client action invalidation**

Increment a lifecycle generation on unequip/destroy. Core rewritten weapons capture tokens and stop at phase boundaries when replaced. Do not migrate every weapon to a framework.

### Task 4: Integrate and polish Umbrella

**Files:**
- Modify: `StarterPlayer/Weapon/Weapons/Umbrella/init.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Umbrella.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Lunge.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- LMB calls `Lunge`; RMB begin/end calls `BeginGlide`/`EndGlide`.
- Lunge consumes bounded `Gain`, `MaxSpeed`, `Duration`, and `SteeringScale`.

- [ ] **Step 1: Swap controls and make lunge additive**

Use LMB for thrust and RMB hold for glide. Update Lunge action to call `Movement:Boost` when gain/cap exist; preserve existing strength fallback for other callers during migration.

- [ ] **Step 2: Make glide catch descent without erasing launch carry**

Apply drag mainly to vertical velocity, with only gentle extreme-horizontal drag. Replace unconditional pop with bounded downward-velocity catch. Release/swap zeros forces without writing assembly velocity.

- [ ] **Step 3: Align active window and cleanup**

Use one action token, open anticipation, then start local hitbox/server validator together. Reuse one attachment/force set per weapon lifetime. Lunge contact applies one small upward carry and strong short feedback. Unequip ends glide/lunge exactly once and restores collision group server-side.

### Task 5: Rebuild Baseball Bat charge and hit rhythm

**Files:**
- Modify: `StarterPlayer/Weapon/Weapons/BaseballBat.luau`
- Modify: `ServerScriptService/Weapon/Weapons/BaseballBat.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- Remote callbacks: `AttackStart`, `ChargeStart`, `ChargeCancel`, `Special`, `ProcessHit`.
- Server derives charge from `ChargeStart` time; client never owns authoritative charge value.

- [ ] **Step 1: Make LMB one quick shove per press**

Remove hold-to-repeat loop. Start local hitbox and server validator together, play swing feedback, close active phase, then allow swap during short recovery.

- [ ] **Step 2: Replace charge loops with elapsed time**

RMB begin records client/server start time and plays windup. RMB release calculates client presentation alpha while server calculates bounded alpha from its own start time. Unequip/reset sends or performs cancellation without lingering tasks.

- [ ] **Step 3: Align homerun active window**

Play anticipation, wait configured hit delay, then send `Special` and open hitbox together. Scale server Impact/launch primarily, raw damage secondarily. Add strong confirmed-contact feedback and clear whiff recovery.

### Task 6: Make ClassicSword inputs explicit and lunge physical

**Files:**
- Modify: `StarterPlayer/Weapon/Weapons/ClassicSword.luau`
- Modify: `ServerScriptService/Weapon/Weapons/ClassicSword.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- LMB `Attack`, RMB `Lunge`.
- Separate `Hitbox` and `LungeHitbox`; server retains separate validators.

- [ ] **Step 1: Remove double-click mode selection**

LMB always slashes and RMB always lunges. Each action uses one token and clear active/recovery timing.

- [ ] **Step 2: Add lunge-specific detached volume**

Add lunge hitbox shape/size/offset/boost config and construct a separate local volume. Start its server validator with its local active window.

- [ ] **Step 3: Route lunge through Movement action**

Replace direct forward/float impulses with bounded `StartLunge` config. Preserve resulting velocity after action/swap and allow light-weapon recovery cancellation.

### Task 7: Make GreatSword combo deliberate

**Files:**
- Modify: `StarterPlayer/Weapon/Weapons/GreatSword.luau`
- Modify: `ServerScriptService/Weapon/Weapons/GreatSword.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- Each LMB begin queues one swing; no input-ended trigger state.
- Server `AttackStart(index)` opens validator for active duration only.

- [ ] **Step 1: Replace hold loop with click queue**

One click starts one swing. One later click may queue the next during the forgiving queue window. Combo advances only after completed swing and resets after chain timeout.

- [ ] **Step 2: Align each active window**

Wait local hit delay, then send `AttackStart(index)` and open detached volume together. Server closes after `HIT_TIME`, not full animation time.

- [ ] **Step 3: Restrict swap only during contact**

Track `HitActive` separately from anticipation/recovery. `CanUnequip` blocks only while active. Give first two sweeps controlled repositioning feedback and third swing strongest launcher feedback.

### Task 8: Functional audit remaining weapons

**Files:**
- Modify only where findings require: listed client/server weapon modules, `ReplicatedStorage/Assets/Weapons/Data/Info.luau`, and shared Ranged behavior.

- [ ] **Step 1: Repair known data/runtime mismatches**

Add missing RPG and HandCannon Info entries. Remove `print(filter)` from Ranged. Repair Flamethrower's `Shoot` lookup/update path and ensure flame loops end on lifecycle invalidation.

- [ ] **Step 2: Review every weapon pair**

Confirm projectile validators/cleanup, whole-shot pellet budgets, self-push, deflection ownership, Boots stomp cleanup, Medkit throw/heal cleanup, and current client/server/config/Info presence. Make only evidence-backed functional changes; do not merge duplicate files or redesign coherent roles.

### Task 9: Static verification and handoff

**Files:**
- Verify all touched files.

- [ ] **Step 1: Run lifecycle and architecture assertions**

Check real damage path exists, reset/round-end events are singular, scoring gates match phase, Impact Clear is called, one server WeaponEvent connection remains, config reload calls precede rebuild, and no core action tasks survive invalidation.

- [ ] **Step 2: Run weapon role assertions**

Check Umbrella/ClassicSword binds, separate sword lunge volume, Bat elapsed charge, GreatSword click queue/active lock, matching active-window remote timing, missing Info entries, and absence of known debug output.

- [ ] **Step 3: Check diff hygiene**

Run `git diff --check` and inspect scoped diffs. State clearly that Studio runtime playtesting remains required for feel and animation alignment because no local Roblox runtime/Luau analyzer is available.
