# Projectile Minimal API And Hitbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove unnecessary projectile API wrapping while fixing ranged large-hitbox graze priority.

**Architecture:** Keep FastCast caster and behavior ownership explicit at call sites. Add tiny value helpers to `ProjectileUtils`, then move ranged hitbox sweep through a local candidate/defer resolver.

**Tech Stack:** Roblox Luau, FastCastRedux, existing client/server projectile runtime.

---

### Task 1: Add Tiny ProjectileUtils Helpers

**Files:**
- Modify: `ReplicatedStorage/Utils/ProjectileUtils.luau`

- [ ] Add `ProjectileUtils.MakeHitbox(info, owner)` after `DefaultRayParams`.
- [ ] Add `ProjectileUtils.GetHumanoidHit(result)` near the sweep helpers.
- [ ] Remove `ProjectileUtils.MakeCastBehavior`.

### Task 2: Use Direct FastCast Behavior Creation

**Files:**
- Modify: `StarterPlayer/Weapon/Behaviors/Ranged.luau`
- Modify: `StarterPlayer/Weapon/Weapons/Medkit.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Projectile/Handler.luau`
- Modify: `ServerScriptService/Weapon/Modules/ProjectileCaster.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Medkit.luau`

- [ ] Replace each `ProjectileUtils.MakeCastBehavior(...)` call with `FastCast.newBehavior()`.
- [ ] Set `MaxDistance`, `Acceleration`, and `RaycastParams` directly.
- [ ] Keep existing custom `CanPierceFunction` callbacks direct on the behavior.
- [ ] Replace repeated runtime/packet hitbox construction with `ProjectileUtils.MakeHitbox(...)`.

### Task 3: Add Ranged Hitbox Candidate Resolver

**Files:**
- Modify: `StarterPlayer/Weapon/Behaviors/Ranged.luau`

- [ ] Add local helpers for pending hitbox candidates.
- [ ] On `RayHit` and `RayPierced`, process humanoids immediately.
- [ ] On ray world hit, mark hit processed, clear pending candidates, terminate projectile.
- [ ] On `LengthChanged`, sweep runtime hitbox and defer humanoid candidates briefly.
- [ ] Choose the candidate closest to the current ray segment when multiple candidates compete.

### Task 4: Verify

**Files:**
- Inspect all modified Luau files.

- [ ] Search for removed `MakeCastBehavior` references.
- [ ] Search for direct `FastCast.newBehavior()` usage in expected call sites.
- [ ] Search for `MakeHitbox` usage in expected call sites.
- [ ] Static-read modified files for syntax-obvious issues.
