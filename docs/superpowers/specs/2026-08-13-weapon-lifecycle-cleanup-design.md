# Weapon lifecycle cleanup

## Goal

Remove `e` lifecycle bloat while keeping better combat timing. Weapon code should stay direct, local, and easy to extend in Roblox Studio.

## BaseWeapon

Client and server `BaseWeapon` load weapon data with the original generic data loader. This restores `Config`, `Animations`, `Sounds`, and `Info` as normal weapon fields. No config cache/reload API and no shared action-token API.

Client initialization order remains: clone/effects, load data, construct sound and animation controllers, initialize behaviours, install binds. `_Equip` runs only after initialization.

Server weapons retain their per-equipped-weapon `WeaponEvent` listener. `WeaponHandler` must not also dispatch `WeaponEvent`, otherwise every request runs twice. Config slot lookup uses the Config module directly.

## Timed melee

Keep `HIT_DELAY` and `HIT_TIME`: they align hitboxes and server validation with the impact part of each swing. Remove global `ActionGeneration` tokens.

Each delayed weapon action owns a private table reference. It continues only while that reference remains current. Unequip clears it. A later equip creates another reference, so an old coroutine cannot affect the new action. This state stays in the weapon that owns it; BaseWeapon has no action API.

## Ranged and other delayed actions

Restore normal ranged fire-delay behavior without tokens. Replace each remaining token use with its local weapon action reference where cancelling a delayed coroutine matters. Keep direct sound and animation calls; declared weapon assets are required and missing assets should fail visibly.

## Review scope

Review every remaining `e` hunk. Keep a hunk only when it removes duplication, fixes a concrete lifecycle issue, or improves combat timing without adding indirection. Remove or rewrite all other lifecycle/config/loading bloat. Preserve unrelated user changes.

## Verification

Run available Luau/static checks. In Studio, smoke-test equip/unequip, ranged fire delay, reload cancellation, normal melee, charged melee, and rapid re-equip while an action is delayed.
