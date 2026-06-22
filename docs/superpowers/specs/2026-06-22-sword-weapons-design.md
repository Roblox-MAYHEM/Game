# Sword Weapons Design

## Goal

Add two melee weapons that fit the current weapon system without adding a heavy framework.

- `ClassicSword`: fast classic sword with normal slash and lunge.
- `GreatSword`: oversized heavy weapon that consumes all three hotbar slots and locks the user into its heavy swing.

Keep implementation clean, minimal, and close to existing melee patterns. Use the current client hitbox plus server melee validator flow; do not add a broad anti-cheat or inventory rewrite.

## ClassicSword

`ClassicSword` uses the existing `StarterPlayer/Weapon/Weapons/ClassicSword.luau` shape and gets a matching server module.

Controls:

- M1 starts normal slash.
- A second M1 within the classic-sword timing window triggers lunge.

Normal slash:

- Plays `Slash`.
- Starts client hitbox for a short slash window.
- Server opens a normal melee window with slash damage.

Lunge:

- Plays `Lunge`.
- Temporarily moves the weapon grip forward so the blade sticks out slightly, matching the intent of `swordexample.luau`.
- Applies a small float/forward lift to the local player.
- Starts the same moving weapon hitbox for the lunge window, so sweeping the sword through players during the lunge can hit them.
- Server uses separate lunge damage, range, arc, and optional knockback config.

Unequip resets the grip, stops hitboxes, clears attack state, and stops animations.

## GreatSword

`GreatSword` is its own client and server weapon module.

Loadout:

- Add `SLOT_COST = 3` in weapon info/config.
- Server hotbar validation accepts `GreatSword` only when it is the only equipped weapon.
- Client loadout should treat `GreatSword` as occupying all three slots, not as three repeated weapon entries.

Attack:

- M1 starts one heavy swing.
- Heavy swing cannot be cancelled.
- While swinging, client ignores unequip/swap attempts and server rejects equip changes away from `GreatSword`.
- Swing uses one active hit window with large range/arc, high damage, and heavy knockback.
- Animation can use existing `Swing1`/`Swing2`/`Swing3` data, picking one cleanly rather than adding combo complexity.

Unequip only completes after the heavy swing state ends.

## Data

Add missing entries where needed:

- `ReplicatedStorage/Assets/Weapons/List.luau`
- `ReplicatedStorage/Assets/Weapons/Data/Info.luau`
- `ReplicatedStorage/Assets/Weapons/Data/Config.luau`
- server/client weapon modules

Use existing animation entries already present in `Animations.luau`.

## Testing

Add lightweight PowerShell contract tests similar to existing repo tests.

Checks:

- `ClassicSword` has client and server modules.
- `ClassicSword` config includes `Attack`, `Lunge`, grip offsets, and float/lunge timing.
- `GreatSword` has client and server modules.
- `GreatSword` config/info has slot cost 3.
- Server/client weapon code has lockout behavior for the heavy swing.
- Hotbar validation accepts slot-cost weapons without requiring exactly three unique entries.

Manual Studio checks:

- Classic sword slash damages.
- Quick second click lunges.
- Lunge makes sword stick forward and player float.
- Sweeping lunge hitbox hits players it passes through.
- Greatsword occupies the full hotbar.
- Greatsword heavy attack cannot be cancelled or swapped away from until finished.
