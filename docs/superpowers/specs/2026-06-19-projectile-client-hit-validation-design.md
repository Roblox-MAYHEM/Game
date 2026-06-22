# Projectile Client Hit Validation Design

## Goal

Projectile hit validation should prioritize gamefeel and performance for a casual FPS. The server should validate that the client's claimed hit position is plausible against rolled-back character hitboxes, instead of recasting from the server-approved shot direction and rejecting on small aiming, timing, or world-geometry mismatches.

## Current Behavior

`ProjectileValidator:RegisterShots` rewinds the shooter to the fire time, computes a server-approved muzzle origin and direction, and stores a `ShotInfo`.

`ProjectileValidator:ValidateHit` rewinds the target to the reported hit time, raycasts the stored shot direction through historical target hitboxes, then raycasts world geometry. This can reject valid-feeling hits as `MissedTarget` or `BlockedByWorld` when client/server projectile paths differ slightly or small map geometry clips the path.

## Chosen Approach

Use a client-hit plausibility fast path:

- Keep existing shot registration, shot lookup, timing, range, duplicate-hit, and target-history checks.
- Require a claimed hit position for projectile hit validation.
- Derive a client direction from the client-reported projectile velocity when present. If velocity is missing or invalid, derive direction from `shot.Origin` to the claimed hit position.
- Build a Roblox `Ray` from `shot.Origin` in that direction and use `ray:Distance(claimedHitPosition)` to verify that the claimed point is close enough to the claimed projectile path.
- Check that the claimed point is close enough to the rolled-back target hitboxes, preferring the client-reported hit part but falling back to the whole character.
- Accept hits using the claimed hit position in metadata.
- Disable world-geometry validation by default.

## Minimal Code Shape

Keep the architecture inside `ProjectileValidator`:

- Add optional config fields:
  - `ClientLineError`
  - `ClientHitPositionError`
  - `ValidateWorldGeometry`
- Add optional `ClientVelocity` to hit validation input.
- Add one main helper for validating claimed hits.
- Add small geometry helpers for point-to-oriented-box distance and world line-of-sight. The line-of-sight helper is present but disabled by default.
- Keep old straight and accelerated recast helpers in the module for rollback/debugging, but stop using them in the default path.

Weapon modules that already receive the velocity argument from the client should forward it to `ValidateHit`. Older call sites remain compatible because the new argument is optional.

## Tolerance Defaults

Defaults should be generous:

- Client line tolerance should include existing distance error, projectile radius, and a small constant.
- Target hit-position tolerance should include existing distance error, projectile radius, movement slack, and a larger minimum.
- Range should still be bounded by weapon range plus existing validation slack.
- Time validation remains unchanged.

## Future World Geometry

World checks stay off by default. A future optional line-of-sight check can reject only obvious blockers while tolerating small clips:

- ignore shooter, target, weapons, effects, bullet holes, and projectile caches
- ignore blockers very near the muzzle or very near the claimed hit position
- optionally ignore thin/decorative/clipping-prone parts by tag later

## Testing

There is no discovered test runner in this repository. Verification should use static review/search plus Roblox Studio playtesting. Code should preserve compatibility with every weapon module that calls `ValidateHit`.
