# Minimal Knockback Redesign Implementation Plan

Goal: replace bloated knockback with small velocity API and clean bat wiring.

1. Update contract test for minimal API and regression checks.
2. Simplify `ServerScriptService/Weapon/Modules/Knockback.luau`.
3. Simplify client `Movement:ApplyKnockback` and `States/Knockback.luau`.
4. Clean bat server/client code and config.
5. Fix `MeleeValidator` debounce typo.
6. Run PowerShell contracts.
