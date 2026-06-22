# Minimal Knockback Redesign

## Goal

Make knockback feel strong and predictable again with a small API. Bat launches should work on grounded players, explosions should keep vertical force, and wall daze should stay a bat special mechanic.

## Design

Use one server helper:

`Knockback(character, direction, params)`

Supported params:

- `FORCE` or `IMPULSE`: launch speed.
- `Y`: optional upward velocity added after direction force.
- `YMAX`: cap final upward velocity only.
- `FLAT`: flatten direction only for weapons that want horizontal launch, such as bat.
- `DURATION`: client knockback state duration.
- `WALL_DAZE`, `DAZE_DURATION`, `WALL_SPEED_MIN`: optional wall daze settings.

Default direction preserves Y. Explosion passes raw explosion-to-target direction, so vertical blast works. Bat passes attacker-to-target direction with `FLAT = true`, plus a Y pop.

Client movement keeps a simple knockback state: apply velocity once, force AirController/low friction while active, block input, raycast movement segment for wall daze, then restore friction.

## Cleanup

- Remove debug print/visuals from server knockback.
- Remove `ControlLock` complexity.
- Fix melee debounce typo.
- Add bat M1 release bind.
- Keep bat server/client special logic small and guarded against stale waits.

## Verification

- `tests/bat_knockback_contract.ps1`
- `tests/data_replica_contract.ps1`
- Studio playtest: normal bat launches grounded target, special launches farther, special wall hit dazes, explosion knockback has vertical lift.
