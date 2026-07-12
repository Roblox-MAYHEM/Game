# Momentum Combat and Movement Design

## Goal

Make Mayhem's movement and close-range combat fast, physical, forgiving, and easy to extend without adding more behavior on top of the current conflicting movement state system.

## Principles

- Prefer Roblox character controllers, assembly mass, and `ApplyImpulse` over custom trajectory simulation.
- Preserve earned velocity when equipping a weapon. Weight changes future response, not current velocity.
- Give each physical property one owner per frame.
- Keep public APIs direct and small. Weapons never edit controller state, friction, or root velocity.
- Delete obsolete indirection after callers migrate; do not retain parallel old and new architectures.
- Tune for readable feel rather than exposing many numeric knobs.
- Preserve unrelated workspace edits, including current FastCast and damage-prototype changes.
- Migrate movement cautiously because it is foundational. Once movement APIs are stable, move quickly and directly on melee, ranged budgets, deflection, and Boots.

## Scope

- Replace the conflicting movement FSM with a small locomotion core and temporary physical actions.
- Make equipped weapon weight affect acceleration, steering, recoil, jumps, and incoming knockback through real assembly mass.
- Replace weapon-attached melee hitboxes with large virtual camera-directed hit volumes.
- Give melee hits immediate attacker propulsion.
- Treat ranged damage and Impact config as whole-shot budgets distributed among pellets.
- Add a Boots weapon whose airborne equip starts a stomp.
- Allow deflectable physical projectiles to be deflected briefly after apparent player contact.

No new progression, security hardening, generic ability framework, custom physics integrator, or intentional slide feature belongs in this work.

## Movement Architecture

Keep the existing `ControllerManager`, sensors, `Frame` snapshot, configuration data, sounds, and animations. Replace `Runtime`, `StateMachine`, `Transitions`, and peer locomotion states with one normal locomotion owner and at most one temporary action.

Target structure:

```text
Movement/
|-- Handler.luau
|-- Frame.luau
|-- Locomotion.luau
|-- RaycastModule/
`-- Actions/
    |-- WallRun.luau
    |-- Vault.luau
    |-- Knockback.luau
    |-- Lunge.luau
    `-- Stomp.luau
```

`Handler` owns lifecycle, input, the update loop, presentation hooks, and the public API. `Frame` is read-only observation. `Locomotion` exclusively writes ordinary ground and air controller properties. Action modules exist only for multi-frame behavior that temporarily borrows movement control.

Each frame reads input and physics once, updates the active action if one exists, otherwise updates locomotion, then updates presentation. Nothing restores an artificial speed floor or writes controller properties afterward.

### Public Movement API

```luau
Movement:SetWeight(weight: number)
Movement:ApplyImpulse(direction: Vector3, strength: number)
Movement:StartLunge(direction: Vector3, config: {})
Movement:StartStomp(config: {})
Movement:IsGrounded(): boolean
```

Jump, vault, and wall-run attempts remain internal input operations. `ApplyImpulse` converts a base-character strength into a Roblox impulse using the character's original mass rather than current weighted mass. The same authored impulse therefore changes a heavy player's velocity less.

`SetWeight` changes root density without rewriting velocity and without also dividing speed and controller force. Unequipping returns weight to neutral.

### Ordinary Locomotion

- At low and normal ground speed, braking and counter-steering provide precise landings.
- At high speed, grip falls enough to carry momentum and bend turns instead of snapping them.
- Opposite input intentionally arrests drift so small platforms remain usable.
- Air input applies bounded steering force. With no air input, the controller adds no force and Roblox momentum continues.
- Landing is an event for feedback and grip selection, not a timed drift state.
- Jump is one physical impulse followed immediately by ordinary locomotion.

### Temporary Actions

- Vault applies a physical lift/forward impulse with brief facing guidance. It never restores missing speed on exit.
- Wall-run uses wall-relative force and retained entry momentum, not infinite-force exact velocity.
- Ordinary pushes are impulses and create no action. Major knockback can briefly reduce steering and watch for wall daze.
- Lunge uses velocity/impulse, not per-frame root `CFrame` teleportation.
- Stomp owns vertical movement until contact.
- The defunct Sliding state is removed. A deliberate slide can be designed separately only if normal high-speed grip is insufficient.

## Detached Melee

`ClientHitbox` becomes a virtual hit-volume module configured by shape, size, and camera-relative offset. It does not accept or follow a weapon Part.

During an attack, the volume follows camera aim in front of the character. It sweeps between previous and current transforms to prevent tunneling during fast movement. Each humanoid is emitted once per swing. Existing server-side attack-window, range, arc, and team validation remains, with duplicated or unused options removed.

On first local contact with a target, the weapon calls `Movement:ApplyImpulse` along camera/swing direction using its configured hit boost. This is immediate for feel. Server damage and Impact validation remain independent. One target cannot grant repeated boosts during the same swing.

## Ranged Shot Budgets

`DMG_TABLE` and `IMPACT_TABLE` describe a complete trigger pull. The ranged hit path divides each falloff result by `PELLETS` before applying it to one validated projectile hit. Single-projectile weapons divide by one.

This fixes the DB Shotgun root cause: its configured close damage and Impact are currently applied independently for each of sixteen pellets. Full contact should approximate the configured shot budget; partial contact should scale with pellet coverage.

## Projectile Deflection

Only physical projectiles marked `PROJ_DEFLECTABLE` receive contact grace. Hitscan-style pellets remain immediate.

When a deflectable projectile reaches a player, its FastCast pauses at contact instead of resolving and terminating immediately. A pending-contact record retains cast, result, incoming velocity, owner, and the original resolution callback. A short visible hit-stop and spark communicate the opportunity.

During the grace window, a deflect melee volume may select either a live nearby projectile or the defender's paused contact. Successful deflection:

- cancels the pending damage, Impact, or explosion;
- transfers owner to the defender;
- preserves projectile speed while replacing direction with camera aim;
- moves the cast just outside the defender, updates its ignore filter, clears processed-contact state, and resumes it;
- replicates the same position, velocity, and owner to clients.

If the window expires, the stored hit callback resolves exactly once and the projectile terminates normally. World hits resolve immediately. This behavior belongs in the shared projectile caster/runtime; FastCast package source is not forked for gameplay behavior.

## Boots Weapon

Boots uses a minimal invisible/placeholder held model when no authored model exists, so gameplay implementation does not wait for art.

Equipping Boots while airborne calls `Movement:StartStomp`. Stomp preserves horizontal velocity, replaces upward motion with strong downward motion, and ends on first ground or player contact.

Landing emits a detached radial hit centered on the contact point. Actual downward speed controls its strength within a broad feel-oriented range. A direct player landing gets a stronger center response and gives the attacker a small upward rebound for chaining. Ground contact produces the radial hit without a large rebound. Staying equipped permits a simple close-range boot attack using the same detached melee API.

Boots is added to weapon list, info, config, client/server weapon modules, and stock inventory flow. It uses existing generic presentation when custom animation or model assets are absent.

## Data Flow

### Melee hit

Client virtual volume finds target, immediately applies local hit boost, and sends target plus swing direction. Server validator accepts the target, then applies weapon damage and Impact.

### Weighted knockback

Server produces a base-mass impulse description. Target client routes it through `Movement:ApplyImpulse`. The method multiplies by original character mass, while Roblox divides by current weighted mass during simulation.

### Deflectable projectile contact

Projectile caster pauses and records contact. Defender swing requests deflection. Server resumes the same cast with new owner/direction or resolves original contact after grace expiry. Clients mirror pause/update/resume presentation.

### Stomp

Airborne equip starts local Stomp action and tells server the weapon is active through existing equip flow. Contact sends landing position, target if direct, and downward speed. Server validates the Boots attack window and applies radial/direct damage and Impact; client action handles immediate rebound.

## Failure Handling

- Missing movement/controller dependencies leave movement disabled with one concise warning.
- An invalid or expired projectile deflection does nothing; original contact resolves once.
- Missing Boots art uses the placeholder model and generic presentation.
- A zero-length direction or missing target/root returns without changing physics.
- Action replacement always calls the old action's stop cleanup before starting the new action.

## Migration

1. Add the new movement API and sole locomotion owner while preserving current sensors/controllers.
2. Move jump, landing, vault, wall-run, knockback, and lunge one at a time; then delete the old FSM/runtime files.
3. Move melee weapons directly to detached virtual volumes and hit boosts; do not maintain attached-volume compatibility.
4. Correct ranged pellet budget semantics in one pass.
5. Add pending projectile contact and route Pan deflection through it without a second projectile abstraction.
6. Add Boots directly on the finished movement and melee APIs.

No old/new compatibility framework remains after migration. Temporary bridges stay local to the migration commit that removes their final caller.

## Success Criteria

- Normal movement is precise at ordinary speed and momentum-preserving at high speed.
- Weapon swaps never rewrite current velocity; heavy weapons visibly reduce steering and physical impulse response.
- Movement modules have one writer for ordinary controller properties and no generic state inheritance or transition table.
- Melee reliably hits with large camera-directed volumes regardless of weapon model animation.
- Valid melee contacts provide immediate, significant forward propulsion once per target per swing.
- Full shotgun contact approximates configured whole-shot damage and Impact instead of multiplying config by pellet count.
- A player can deflect a physical projectile during approach or briefly after visible contact without taking the canceled hit.
- Airborne Boots equip causes an immediate readable stomp, radial landing response, and direct-hit rebound.

## Playtest Correction Pass

The first implementation exposed several incorrect motion semantics. Correct them without restoring the removed FSM.

### Momentum and Landing

Ground locomotion preserves total horizontal speed while turning. It must not reduce preserved speed to the velocity projected onto current input. Normal controller input bends momentum with speed-dependent authority.

Track peak downward speed while airborne. An ordinary landing has no penalty. A hard landing applies one small horizontal speed bleed, then briefly favors the entry direction with reduced steering so the player slides rather than stops. A buffered landing jump cancels most landing bleed and the control penalty, creating a timing-based momentum chain. Landing never becomes an exclusive state.

Vaulting follows the older reference behavior while retaining Roblox impulses:

- `UserInputService.JumpRequest` feeds the shared jump buffer. Do not depend on filtered raw `InputBegan` for jump or vault activation.
- A forward body ray from slightly below the root must hit an ordinary collidable obstacle.
- A forward clearance ray from above the head must miss.
- A short root-height ray detects obstacles close enough to need a backward clearance nudge.
- `Vaultable` tags are not required; `NoVault` may opt specific geometry out.
- Vaulting is jump-triggered and predictable. Do not auto-vault merely from running into geometry.
- No top-surface ray, obstacle-top matching, or height calculation gates action start. The body-hit/head-clear gap is the height filter, matching the working reference.
- Incoming horizontal speed is preserved.
- Vault applies only missing forward and vertical velocity rather than adding current velocity again.
- Holding or buffering jump through the vault produces a bounded forward/up vault-jump exit.

Keep this path small: `Handler` owns jump buffering and action selection, `RaycastModule` answers whether reference-style clearance exists, and `Actions/Vault` owns the short physical response. Remove `mode`, `TopPosition`, auto-speed, maximum-height, and lift-from-height fields made unused by this contract. Do not move raycasting into `Handler` or create a vault state/controller.

### Bounded Combat Boosts

Raw melee impulses are replaced by `Movement:Boost(direction, gain, maxSpeed)`. Boost reads current velocity along the requested direction, adds only the bounded missing amount, preserves lateral and vertical velocity, and routes the result through the weight-aware impulse path. A melee volume may trigger one boost total per swing, regardless of how many targets overlap it.

### Weight

One movement-level multiplier slightly exaggerates deviation from neutral weight. Values above one become heavier; values below one become lighter. No weapon-specific duplicate scaling is added.

### Presentation and Debugging

Restore viewmodel movement tilt directly in the movement presentation update, including direction-change snap. Do not restore `Runtime` or another presentation state object.

When `Settings.VisualizeDebug` is enabled, each active virtual melee sample draws its block or sphere through `DebugVisualize`. Debug frames are recycled while the volume runs so visualization does not accumulate adornments.

### DB Shotgun

Keep whole-shot budget semantics. Convert DB Shotgun's old per-pellet-era config to meaningful full-shot damage and Impact totals before division. Do not remove pellet division or add a DB-specific damage path.
