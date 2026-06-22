# Bat Knockback and Wall Daze Design

## Goal

Make bat knockback a reliable movement mechanic instead of a raw impulse that ground friction can cancel. Windup/special bat hits should launch victims hard enough to matter, and if that launched victim hits a wall during the knockback window they should be briefly dazed.

## Current Findings

- `ServerScriptService/Weapon/Modules/Knockback.luau` sends a plain impulse to player targets through `Events.Knockback`.
- `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau` receives that remote and calls `HRP:ApplyImpulse(impulse)`.
- The custom movement controller sets high ground friction/control every frame, so small horizontal impulses can be cancelled immediately while grounded.
- `ServerScriptService/Weapon/Weapons/BaseballBat.luau` currently uses normal attack damage and knockback for all hits; special/windup scaling is present as commented code.
- Bat special release currently starts a `CurrentAttack`, but does not open the melee validator window, so a special animation does not have a clear validated hit window yet.

## Approach

Add movement-owned `Knockback` and `Dazed` states.

The server will send a structured knockback packet instead of only a vector. Normal bat hits can use the same mechanic with modest settings. Windup/special bat hits send stronger settings and enable `wallDaze`.

The client movement controller owns the launch while knockback is active:

- Temporarily reduce or bypass ground friction/control so grounded victims launch.
- Apply a target delta velocity based on the server-provided launch vector.
- Keep the state active for a short duration so movement input cannot immediately erase the launch.
- Raycast along the victim's travel direction during the active window.
- If `wallDaze` is enabled and a collidable wall is hit above the configured speed threshold, transition into `Dazed`.

`Dazed` briefly locks movement after wall impact, bleeds or zeros velocity, then returns to normal locomotion.

## Server Behavior

`Knockback.luau` will accept either existing simple params or expanded params:

- `IMPULSE` or `SPEED`: strength of launch.
- `Y` and `YMAX`: vertical lift controls.
- `DURATION`: how long client knockback state owns movement.
- `CONTROL_LOCK`: whether input is suppressed during knockback.
- `WALL_DAZE`: whether wall impact can trigger daze.
- `DAZE_DURATION`: duration of dazed state.
- `WALL_SPEED_MIN`: minimum impact speed for daze.
- `SOURCE`: source label such as `"BaseballBatSpecial"`.

For player targets, server fires the packet to the owning client. For NPCs, it keeps the current direct impulse fallback.

Baseball bat server behavior:

- Normal attack: validated by `AttackStart`, normal damage, normal knockback packet.
- Windup start: tracks charge from `Windup.MAX` and `Windup.RATE`.
- Special release: captures charge before cancelling windup, opens a special hit window, and marks `CurrentAttack.IsSpecial = true`.
- Special hit: uses special damage/knockback scaling and sends wall-daze knockback packet.

## Client Behavior

`Movement/Handler.luau` will route `Events.Knockback` into a method such as `Movement:ApplyKnockback(packet)`.

`Knockback` state:

- Stores launch direction, target velocity, start time, duration, and wall-daze config.
- Sets `CM.MovingDirection = Vector3.zero`.
- Uses `AirController` or low ground friction while active so launch is not killed by ground friction.
- Applies delta velocity once on enter, then preserves launch for the configured duration.
- Raycasts from previous root position to current root position, ignoring the character.
- Treats a wall as a collidable hit whose normal is mostly horizontal.
- On wall hit with sufficient speed and `wallDaze = true`, changes to `Dazed`.

`Dazed` state:

- Locks movement input/control for `duration`.
- Stops most horizontal velocity or bleeds it sharply.
- Restores normal controller settings on exit.
- Auto-transitions back to `Air`, `Idle`, or `Running` depending on grounded and movement state.

## Config

Add movement config entries for `Knockback` and `Dazed`, plus bat special tuning in weapon config.

Suggested initial values:

- Bat normal knockback speed around `35-45`.
- Bat special knockback speed around `70-90`, scaled by charge.
- Knockback duration around `0.25-0.4`.
- Wall daze duration around `0.8-1.2`.
- Wall speed threshold around `25`.
- Small upward lift, capped, so victims clear friction but do not fly straight up.

Exact numbers can be tuned after in-Studio playtest.

## Error Handling and Safety

- Invalid or missing target roots cause knockback to no-op.
- Zero direction falls back to attacker-to-target direction where possible.
- Daze only triggers for special/windup knockback packets, not normal wall touches.
- Raycasts ignore the victim character and respect `CanCollide`.
- Server keeps existing validation authority for melee hits; client only owns local movement response after server approval.

## Testing

Automated tests are limited because this repo is Roblox/Luau without an obvious local test runner for character controllers. Still, implementation should add pure helper functions where possible and test them if the existing PowerShell test pattern supports it.

Manual Studio verification:

- Normal bat hit moves grounded target horizontally.
- Normal bat hit does not daze on wall contact.
- Windup/special hit launches grounded target farther than normal hit.
- Windup/special target dazes when hitting a wall during knockback window.
- Daze expires and movement returns normally.
- No daze occurs when special target does not hit wall.
- Unequip/death/character cleanup does not leave movement locked.
