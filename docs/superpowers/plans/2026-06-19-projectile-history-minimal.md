# Projectile / Position History Minimal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shorten projectile validation and position history by removing unused legacy APIs and dead validation paths.

**Architecture:** Keep two existing modules. `ProjectileValidator` only validates client-claimed hit positions. `PositionHistory` only samples, stores, interpolates, and returns character frames.

**Tech Stack:** Roblox Luau, existing `PositionHistory`, Roblox `Ray`.

---

### Task 1: Prune `ProjectileValidator`

**Files:**
- Modify: `ServerScriptService/Weapon/Modules/ProjectileValidator.luau`

- [ ] Remove unused services/imports: `CollectionService`, `DebugVisualize`, `Settings`.
- [ ] Remove unused config fields: `RaycastParams`, `ValidateWorldGeometry`.
- [ ] Remove unused exported packet command types.
- [ ] Remove unused `ShotInfo` fields: `ClientOrigin`, `Direction`, `ShootPointIndex`.
- [ ] Remove old recast helpers: `getProjectilePos`, `raycastAlongQuadraticPath`, `_validateStraightHit`, `_validateAcceleratedHit`, `_isWorldLineObviouslyBlocked`.
- [ ] Remove old recast state: `HasAcceleration`, `RaycastParams`, `QuadraticStepTime`.
- [ ] Keep current `RegisterShots` packet approval and `_validateClientClaimedHit`.

### Task 2: Prune `PositionHistory`

**Files:**
- Modify: `ServerStorage/Libraries/PositionHistory.luau`

- [ ] Remove unused `HitResult` type.
- [ ] Remove `MaxPositionHistory`.
- [ ] Compact tracked hitbox names.
- [ ] Remove unused raycast helpers and APIs: `raycastPartFrame`, `RaycastCharacterAt`, `GetPartFrameAt`, `GetCharacterPositionAt`.
- [ ] Remove compatibility aliases: `RegisterTrackable`, `UnregisterTrackable`, `TouchCharacter`.
- [ ] Make capture helper internal if no external callers need `CaptureNow`.
- [ ] Keep frame capture/interpolation/extrapolation behavior.

### Task 3: Verify

**Files:**
- Inspect modified modules.

- [ ] Run `rg` for removed symbols.
- [ ] Run `rg` for remaining `PositionHistory` call sites.
- [ ] Count lines before/after.
- [ ] Check `git`, `luau`, `stylua` availability and run none if missing.
