# Projectile / Position History Minimal Design

## Goal

Make `ProjectileValidator` and `PositionHistory` much shorter by deleting unused compatibility paths and legacy validation code, while preserving the current client-hit validation behavior.

## Scope

- Delete old server recast validation for straight and accelerated projectile hits.
- Delete optional debug/world-geometry validation hooks from `ProjectileValidator`.
- Delete unused exported projectile packet types and unused stored shot fields.
- Delete unused `PositionHistory` public helpers:
  - `RaycastCharacterAt`
  - `GetPartFrameAt`
  - `GetCharacterPositionAt`
  - `RegisterTrackable`
  - `UnregisterTrackable`
  - `TouchCharacter`
  - `MaxPositionHistory`
- Keep needed history behavior:
  - `Init`
  - `RegisterCharacter`
  - `UnregisterCharacter`
  - `GetFrameAt`
- Keep shot registration, muzzle rewind, duplicate-hit window, time validation, client ray distance validation, and rolled-back target proximity validation.

## Verification

Use repository search to prove removed APIs have no external callers. Use line counts before/after. No Luau compiler or test runner is available in this shell.
