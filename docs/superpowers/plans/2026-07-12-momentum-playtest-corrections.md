# Momentum Playtest Corrections Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct the playtest regressions in momentum retention, hard landings, vaulting, melee boosts/debug drawing, viewmodel tilt, weapon weight, and DBShotgun output.

**Architecture:** Keep the existing action-based movement architecture. Add one bounded velocity API to `Movement`, keep hard landing as short-lived locomotion data rather than a state, and make vaulting a brief impulse action detected with the proven lower-ray/head-clearance pattern from the previous controller. Combat continues to consume movement only through the public movement API.

**Tech Stack:** Roblox Luau, ControllerManager physics, workspace overlap/raycast queries, existing `DebugVisualize` and viewmodel APIs.

## Global Constraints

- Preserve current velocity; add only missing velocity through mass-aware Roblox impulses.
- Keep the architecture minimal and avoid new movement states.
- Ordinary collidable ledges are vaultable; `NoVault` is the opt-out.
- A melee swing receives at most one movement boost even when it hits several targets.
- Use static contract checks only; no new test suite or test plan.
- Do not touch the user's `DamageHandler.luau`, deleted contract scripts, `gamedesign.md`, or FastCast compatibility edit.
- Repository commit creation is unavailable in this session, so changes remain in the working tree.

---

### Task 1: Restore momentum-oriented movement primitives

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Locomotion.luau`

**Interfaces:**
- Produces: `Movement:Boost(direction: Vector3, gain: number, maxSpeed: number)`.
- Produces: `LandingCarryUntil`, `LandingCarryDirection`, and `LandingControlScale` transient locomotion data.
- Consumes: existing `ApplyImpulse`, `Frame.Velocity`, `Frame.MoveVelocity`, and ControllerManager fields.

- [ ] **Step 1: Add compact feel configuration**

Add one global weight exaggeration value and a `Ground.HardLanding` table containing the downward-speed threshold, maximum response speed, horizontal bleed range, slide duration, slide steering scale, and buffered-jump reduction. Keep these together with the systems that consume them.

- [ ] **Step 2: Add bounded boost and exaggerated weight mapping**

Implement `Boost` by projecting assembly velocity onto `direction`, calculating `min(current + gain, maxSpeed) - current`, and sending only the positive missing amount through `ApplyImpulse`. Map authored weight with `1 + (weight - 1) * WeightExaggeration` before changing root density while retaining the authored `Movement.Weight` value.

- [ ] **Step 3: Restore viewmodel tilt directly in the handler**

Move the prior tilt calculation into `_UpdatePresentation`: compare input sign with camera-relative lateral velocity, derive the opposing-motion tilt, send a sign-change impulse, and call the existing `ViewModel:SetTilt(alpha, impulse)` method. Do not recreate the deleted runtime layer.

- [ ] **Step 4: Add hard-landing carry without a state**

Track peak downward velocity while airborne. On a hard landing, apply one bounded horizontal counter-impulse and set short-lived carry direction/control values; if jump is buffered, sharply reduce the response. Reset tracking after landing.

- [ ] **Step 5: Preserve full planar speed on ground**

Set grounded `BaseMoveSpeed` from total planar speed instead of only the component aligned with new input. During landing carry, blend input toward entry direction, reduce turning authority, and use low friction so the player visibly slides. Preserve ordinary counter-steering outside that window.

### Task 2: Repair vault sensing and impulse composition

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/RaycastModule/init.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Vault.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Reference: `MovementSystemRef/StarterCharacterScripts/Movement/Vault.local.luau`

**Interfaces:**
- Produces: `RaycastModule:VaultCheck(forwardDir)` returning `TopPosition`, `HeightFromGround`, and `TooClose` for ordinary collidable ledges.
- Consumes: `Movement:Boost`, jump buffer timing, and existing action lifecycle.

- [ ] **Step 1: Restore lower-hit/head-clear sensing**

Cast forward at lower/body height to find the ledge, reject objects tagged `NoVault`, then require a clear forward ray from head height. Find the ledge top with a downward ray and keep the existing maximum-height guard. Remove the `Vaultable` tag requirement and unused obstacle-top matching complexity.

- [ ] **Step 2: Make vault impulse additive**

Use `Movement:Boost` for forward velocity and apply only missing upward velocity. If the ledge is extremely close, add the small backward spacing impulse from the previous vault behavior before launching. Never add the player's current forward speed a second time.

- [ ] **Step 3: Preserve vault-jump chaining**

Allow a buffered jump during the late vault window to end the action with one bounded forward gain and upward gain. Consume the buffer and apply normal jump cooldown so the result composes with momentum instead of entering another state.

### Task 3: Stabilize melee movement and visualize detached volumes

**Files:**
- Modify: `StarterPlayer/Weapon/Modules/ClientHitbox.luau`
- Modify: `StarterPlayer/Weapon/Weapons/BaseballBat.luau`
- Modify: `StarterPlayer/Weapon/Weapons/ClassicSword.luau`
- Modify: `StarterPlayer/Weapon/Weapons/GreatSword.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Pan.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Rock.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Umbrella/init.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Boots.luau`
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- Consumes: `Movement:Boost(direction, gain, maxSpeed)` and `Settings.VisualizeDebug`.
- Produces: `HitBoostCap` client hitbox config.

- [ ] **Step 1: Bound boost once per swing**

Reset a `Boosted` flag in `HitStart`. On the first unique humanoid hit only, call `Movement:Boost` with camera forward, `HitBoost`, and `HitBoostCap`, then set the flag. Further targets still receive hit callbacks but cannot stack movement.

- [ ] **Step 2: Draw the sampled detached volume**

When debug visualization is enabled, recycle the preceding frame and draw every sampled block or sphere volume through the existing `DebugVisualize` helpers. Keep drawing colocated with `_Sample` so the visualization exactly matches collision queries.

- [ ] **Step 3: Retune melee gains and caps**

Replace the current raw impulse-sized `HIT_BOOST` values with modest velocity gains and add `HIT_BOOST_CAP` per melee attack. Pass the cap from each constructor into `ClientHitbox`; heavier attacks may have a slightly higher cap but must not cause a speed discontinuity.

### Task 4: Restore DBShotgun whole-shot output

**Files:**
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

**Interfaces:**
- Consumes: server ranged weapons' existing `configured value / pellet count` behavior.
- Produces: DBShotgun `DMG_TABLE` and `IMPACT_TABLE` values interpreted as totals for a full connected blast.

- [ ] **Step 1: Convert DBShotgun tables to whole-shot budgets**

Raise close/mid/far DBShotgun damage and impact curves from old per-pellet-scale numbers to meaningful full-blast totals. Leave the server's equal pellet distribution untouched so changing pellet count does not change total output.

### Task 5: Static verification and scope review

**Files:**
- Verify: all files above

- [ ] **Step 1: Check contracts and syntax-shaped mistakes**

Use `rg` to confirm all melee constructors pass `HitBoostCap`, raw melee `ApplyImpulse` is gone, `Vaultable` is no longer required, `NoVault` is recognized, tilt calls `SetTilt`, and DBShotgun remains divided by pellet count on the server.

- [ ] **Step 2: Check working-tree hygiene**

Run `git diff --check` and inspect scoped diffs. Confirm the user's unrelated dirty files and deletions remain unchanged by this pass. Runtime feel still requires Roblox Studio playtesting; do not claim runtime verification from static checks.
