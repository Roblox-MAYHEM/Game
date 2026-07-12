# Full-Roster Impact Migration Design

## Goal

Move every currently listed offensive weapon onto Mayhem's Impact, Primed, ordinary-push, and finisher rules without adding another combat abstraction.

## Scope

Migrate:

- DB Shotgun
- Pump Shotgun
- KB Shotgun
- RPG
- Hand Cannon
- Pan
- Rock
- Classic Sword
- Greatsword
- Revolver

Already migrated and unchanged except shared fixes:

- Pistol
- Rocket Launcher
- Baseball Bat
- Umbrella

Excluded:

- Medkit, because healing is not an offensive hit.
- Flamethrower and Dartgun, by explicit prototype scope choice.

## Architecture

Keep the existing direct API:

```luau
ImpactService.ApplyHit(targetCharacter, attacker, {
	Power = impactPower,
	Direction = direction,
	FinisherMultiplier = optionalMultiplier,
	UpwardVelocity = optionalUpwardVelocity,
})
```

Each weapon remains responsible for validation, range/attack selection, and intuitive hit direction. `ImpactService` remains responsible for meter state, ordinary push, Primed conversion, and finisher spacing. Do not add a `BaseWeapon` helper, combat resolver, damage hook, or new shared configuration layer.

Prototype damage stays alongside Impact but does not determine it.

## Weapon Families

### Single-projectile ranged weapons

Revolver uses an explicit Impact falloff table beside its damage falloff table. Direction points from attacker toward victim. Its deliberate shot receives stronger Impact and finisher quality than Pistol.

### Shotguns

DB Shotgun, Pump Shotgun, and KB Shotgun apply small Impact per validated pellet. A close, accurate blast therefore builds more total Impact and push than a partial hit.

Existing global finisher spacing ensures one shotgun blast cannot consume several Primed pips. Pellets arriving during that spacing may still contribute ordinary push, preserving shotgun physicality.

KB Shotgun removes its separate legacy knockback budget. Its stronger push identity comes from higher per-pellet Impact rather than a parallel force system.

### Explosive weapons

RPG and Hand Cannon add explicit explosion Impact falloff and use the existing shared `Explosion` module. Enemy launch comes from Impact exactly once per explosion.

Remove their direct enemy knockback so direct hits do not stack two incompatible launch systems. Preserve self-explosion movement without self-Impact.

### Simple melee weapons

Pan and Rock apply one Impact hit after melee validation. Direction points from attacker toward target. Pan receives stronger conversion identity; Rock remains a simpler moderate hit.

### Swords

Classic Sword applies Impact on both normal attack and lunge. Lunge retains stronger forward/upward conversion identity but no longer calls legacy knockback separately.

Greatsword assigns explicit Impact and finisher character to each swing through its existing swing config. Slower committed swings create stronger pushes and finishers. Remove direct legacy knockback after migration.

## Configuration Rules

- Use explicit `IMPACT_POWER` for fixed attacks.
- Use `IMPACT_TABLE` for range-based attacks.
- Use explosion `IMPACT_MAX` and `IMPACT_MIN` for radial falloff.
- Use `FINISHER_MULTIPLIER` only where weapon commitment or identity justifies a meaningful difference.
- Use `FINISHER_Y` only for clearly upward-biased attacks.
- Impact strength should broadly agree with visible hit force and attack commitment.
- Do not derive Impact from damage at runtime.

## Cleanup

- Remove migrated weapons' direct `Knockback` imports and calls.
- Remove KB Shotgun's old total-knockback tracking.
- Keep shared projectile and melee validation unchanged.
- Keep existing damage calls for current prototype behavior.
- Do not refactor excluded weapons or unrelated systems.

## Success Criteria

- Every in-scope offensive hit raises Impact and produces corresponding ordinary push.
- Every in-scope weapon can convert a Primed target.
- Shotgun blast behavior remains readable and consumes at most one Primed pip per spacing window.
- RPG and Hand Cannon explosions apply one enemy Impact response while preserving self movement.
- No migrated weapon also applies legacy enemy knockback.
- Existing health, damage, HUD, movement, and excluded weapons remain otherwise unchanged.
