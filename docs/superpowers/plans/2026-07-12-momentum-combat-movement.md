# Momentum Combat and Movement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace conflicting movement ownership with a minimal Roblox-physics core, then add detached melee, whole-shot pellet budgets, post-contact projectile deflection, and Boots stomp behavior.

**Architecture:** Keep current Roblox `ControllerManager`, sensors, and character setup. Introduce one locomotion writer plus one optional physical action; migrate movement callers cautiously, then move combat systems directly to the final APIs without compatibility layers.

**Tech Stack:** Roblox Luau, ControllerManager/GroundController/AirController, FastCastRedux, existing weapon/projectile/Impact modules.

## Global Constraints

- Preserve current velocity when weapon weight changes.
- Weight uses root assembly mass and base-mass-calibrated Roblox impulses; do not also divide speed or force by weight.
- Movement migration is staged and cautious; melee, ranged, deflection, and Boots move directly once APIs exist.
- One owner writes ordinary controller properties each frame.
- No generic state inheritance, transition matrix, ability framework, security expansion, or custom physics integrator.
- Preserve unrelated dirty files and user changes.
- No automated test-plan work; use focused static checks and Studio-facing diagnostics only.

---

### Task 1: Establish Final Movement API Without Changing Special Moves

**Files:**
- Create: `StarterPlayer/StarterPlayerScripts/Movement/Locomotion.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/Weapon/BaseWeapon.luau`
- Modify: `StarterPlayer/Weapon/Behaviors/Ranged.luau`
- Modify: `ServerScriptService/Weapon/Modules/Knockback.luau`

**Interfaces:**
- Produce `Movement:SetWeight(weight)`, `Movement:ApplyImpulse(direction, strength)`, `Movement:IsGrounded()`.
- `ApplyImpulse` applies `direction.Unit * strength * BaseMass`, never current `AssemblyMass`.

- [ ] Add neutral/base mass capture and direct weight-density update that preserves velocity.
- [ ] Route ordinary ground and air control through `Locomotion:Update(dt)` with speed-dependent grip and bounded air steering.
- [ ] Keep current special moves callable during migration, but prevent normal locomotion states from writing after `Locomotion`.
- [ ] Change weapon equip/unequip to `SetWeight`, including neutral reset.
- [ ] Route ranged recoil and remote knockback through base-mass impulse semantics.
- [ ] Commit movement API seam.

### Task 2: Replace Movement FSM With Direct Actions

**Files:**
- Create: `StarterPlayer/StarterPlayerScripts/Movement/Actions/WallRun.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Vault.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Knockback.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Lunge.luau`
- Create: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Stomp.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Frame.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Umbrella/init.luau`
- Delete: `StarterPlayer/StarterPlayerScripts/Movement/Runtime.luau`
- Delete: `StarterPlayer/StarterPlayerScripts/Movement/StateMachine.luau`
- Delete: `StarterPlayer/StarterPlayerScripts/Movement/Transitions.luau`
- Delete: `StarterPlayer/StarterPlayerScripts/Movement/BaseState.luau`
- Delete: `StarterPlayer/StarterPlayerScripts/Movement/States/*.luau`

**Interfaces:**
- Produce `Movement:StartAction(action, data)`, internal action cleanup, `Movement:StartLunge(direction, config)`, and `Movement:StartStomp(config)`.
- Each action exposes `Start(movement, data)`, `Update(movement, dt): boolean`, and `Stop(movement, reason)` without inheritance.

- [ ] Move jump to one input-triggered impulse with coyote time, buffering, and current double-jump count.
- [ ] Make landing a signal/feedback event rather than a timed movement state.
- [ ] Convert vault to physical lift/forward impulse without exit speed restoration.
- [ ] Convert wall-run to wall-relative force preserving entry momentum.
- [ ] Convert knockback and wall daze to actions only for major launches.
- [ ] Convert Umbrella lunge from CFrame teleporting to physical action.
- [ ] Add Stomp action contract for Boots.
- [ ] Remove old FSM/runtime/state files and all callers.
- [ ] Commit minimal movement core.

### Task 3: Replace Attached Melee Hitboxes

**Files:**
- Replace: `StarterPlayer/Weapon/Modules/ClientHitbox.luau`
- Modify: `StarterPlayer/Weapon/Weapons/BaseballBat.luau`
- Modify: `StarterPlayer/Weapon/Weapons/ClassicSword.luau`
- Modify: `StarterPlayer/Weapon/Weapons/GreatSword.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Pan.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Rock.luau`
- Modify: `ServerScriptService/Weapon/Modules/MeleeValidator.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- `ClientHitbox.new({ Character, Shape, Size, Offset })` creates a virtual camera-relative volume.
- `HitStart(duration)`, `HitStop()`, `OnHumHit(callback)`, and `Reconcile()` remain direct weapon-facing calls.

- [ ] Implement virtual block/sphere overlap plus previous-to-current sweep with per-swing target dedupe.
- [ ] Remove all weapon-model `Hitbox` dependencies.
- [ ] Add explicit `HITBOX_SHAPE`, `HITBOX_SIZE`, `HITBOX_OFFSET`, and `HIT_BOOST` config per melee attack.
- [ ] Apply immediate camera-directed movement impulse on first target contact.
- [ ] Keep server attack-window/range/arc validation and remove unused validator indirection.
- [ ] Commit detached melee conversion.

### Task 4: Make Ranged Config Whole-Shot Budgets

**Files:**
- Modify: `ServerScriptService/Weapon/Weapons/DBShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/PumpShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/KBShotgun.luau`

**Interfaces:**
- Consume `Shoot.PELLETS`, `DMG_TABLE`, and either `IMPACT_TABLE` or fixed Impact power.
- Each validated pellet applies `falloff / max(PELLETS, 1)`.

- [ ] Divide DB Shotgun damage and Impact falloff by configured pellet count.
- [ ] Apply identical whole-shot semantics to Pump and KB Shotguns.
- [ ] Keep single-projectile paths unchanged.
- [ ] Commit ranged budget correction.

### Task 5: Add Pending Projectile Contact and Deflection

**Files:**
- Modify: `ServerScriptService/Weapon/Modules/ProjectileCaster.luau`
- Modify: `ServerScriptService/Projectile.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Projectile/Handler.luau`
- Modify: `ReplicatedStorage/Packages/ProjectileHitbox.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Pan.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Pan.luau`

**Interfaces:**
- `Projectile:Deflect(id, owner, direction)` handles live or paused casts.
- Deflectable player contact stores one `PendingContact` on cast user data and pauses until deflect or expiry.

- [ ] Route deflectable humanoid hits through pending contact; resolve world hits immediately.
- [ ] Pause cast and preserve the original hit callback/result/velocity during grace.
- [ ] On deflect, cancel pending hit, transfer owner, update filter/position/velocity, and resume.
- [ ] On expiry, resolve stored hit exactly once and terminate.
- [ ] Let Pan detect paused contact as well as approaching live casts.
- [ ] Mirror pause/update/resume visuals to clients without editing FastCast package gameplay code.
- [ ] Commit projectile deflection.

### Task 6: Add Boots Stomp Weapon

**Files:**
- Create: `StarterPlayer/Weapon/Weapons/Boots.luau`
- Create: `ServerScriptService/Weapon/Weapons/Boots.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/List.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Info.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Animations.luau`
- Modify: `ServerScriptService/Weapon/Handler.luau`

**Interfaces:**
- Airborne equip calls `Movement:StartStomp(config.Stomp)`.
- Server `Boots:Stomp(position, target, downwardSpeed)` applies radial/direct damage and Impact after current weapon validation.

- [ ] Add Boots data and stock-inventory visibility.
- [ ] Provide a minimal invisible model fallback when authored Boots model is absent.
- [ ] Start downward action immediately on airborne equip while preserving horizontal velocity.
- [ ] Detect first ground/player contact and send landing information.
- [ ] Apply radial landing damage/Impact, stronger direct response, and local direct-hit rebound.
- [ ] Add simple detached close-range boot attack while staying equipped.
- [ ] Commit Boots weapon.

### Task 7: Remove Migration Debris and Review Final Ownership

**Files:**
- Modify only files already touched above.

- [ ] Remove temporary movement bridges, obsolete config names, debug prints, and unused requires.
- [ ] Confirm no weapon edits movement controller properties or root velocity directly.
- [ ] Confirm no melee weapon reads an attached `Hitbox` part.
- [ ] Confirm old movement FSM/runtime symbols have no callers.
- [ ] Run `git diff --check` and focused `rg` ownership searches.
- [ ] Commit final cleanup.
