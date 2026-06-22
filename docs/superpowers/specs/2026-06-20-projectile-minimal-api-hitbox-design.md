# Projectile Minimal API And Hitbox Resolver Design

## Goal

Keep the projectile system lightweight and detached while trimming small API noise and preventing large projectile hitboxes from claiming unrelated graze hits before the center ray reaches the aimed target.

## Architecture

FastCast ownership remains explicit at call sites. Weapons and behaviors still create `FastCast.new()` themselves, register the caster with the projectile runtime, attach visuals, and set custom `CanPierceFunction` logic when needed.

`ProjectileUtils` should not wrap FastCast behavior creation. Call sites should create `FastCast.newBehavior()` directly because behavior is a FastCast-native object and only needs a few fields. `ProjectileUtils` keeps shared projectile helpers: IDs, default ray params, shoot points, cast termination, shape sweeps, and hitbox value construction.

## API Changes

Remove `ProjectileUtils.MakeCastBehavior`.

Add one small helper:

```luau
ProjectileUtils.MakeHitbox(info, owner)
```

It reads `PROJ_SHAPE`, `PROJ_SIZE`, and `PROJ_ACTIVE_HB` from a shoot/throw info table and returns:

```luau
{
	Runtime = runtimeHitbox,
	Packet = packetHitbox,
}
```

If no shape exists, both values are nil. This removes repeated hitbox table construction without hiding caster lifecycle or firing.

Add one small target helper:

```luau
ProjectileUtils.GetHumanoidHit(result)
```

It returns the hit model and humanoid for a `RaycastResult`, or nils. Hit policy stays with the caller.

## Ranged Hitbox Resolver

`Ranged` keeps the core FastCast ray as the authoritative path. Shape sweep results from `LengthChanged` become candidates, not immediate final hits.

Rules:

- Ray humanoid hit processes immediately.
- Ray non-humanoid/world hit terminates the projectile and clears any pending hitbox candidate.
- Hitbox sweep only considers humanoid candidates.
- Hitbox candidates defer briefly, default `PROJ_HITBOX_DEFER` or `0.035`.
- If no ray hit or world block happens during the defer, the candidate processes.
- If another candidate appears during defer, the closer candidate to the ray path wins.

This lets large hitboxes forgive near misses without stealing shots from the target under the center ray.

## Server ProjectileCaster

Server projectile casters should also create `FastCast.newBehavior()` directly. Server behavior still owns bounce/pierce callbacks for special projectiles like medkit.

## Verification

No Luau runner is available in the current shell. Verification should use static searches for removed helpers, updated call sites, and obvious syntax issues, then Roblox Studio playtesting for behavior.
