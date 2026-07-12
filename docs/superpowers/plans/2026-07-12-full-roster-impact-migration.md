# Full-Roster Impact Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every in-scope offensive weapon onto the existing direct Impact API.

**Architecture:** Each weapon validates its own hit and directly calls `ImpactService.ApplyHit`. Range weapons use explicit Impact falloff; explosions use the existing shared explosion path; melee variants select Impact from their current attack config. No new helper or resolver.

**Tech Stack:** Roblox Luau, existing projectile/melee validators, current weapon config, `ImpactService`.

## Global Constraints

- Migrate DB Shotgun, Pump Shotgun, KB Shotgun, RPG, Hand Cannon, Pan, Rock, Classic Sword, Greatsword, and Revolver.
- Skip Medkit, Flamethrower, and Dartgun.
- Preserve self-explosion movement without self-Impact.
- Keep prototype damage calls.
- Remove direct legacy enemy knockback from migrated weapons.
- Preserve current unrelated workspace edits.
- No new combat abstraction or automated test plan.

---

### Task 1: Add Explicit Full-Roster Impact Config

**Files:**
- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`

- [x] Add `IMPACT_TABLE` to DB Shotgun, Pump Shotgun, and Revolver.
- [x] Add per-pellet `IMPACT_POWER` to KB Shotgun.
- [x] Add explosion `IMPACT_MAX`, `IMPACT_MIN`, and optional finisher multiplier to RPG and Hand Cannon.
- [x] Add `IMPACT_POWER` and finisher fields to Pan, Rock, Classic Sword attack/lunge, and each Greatsword swing.

### Task 2: Migrate Ranged Direct-Hit Weapons

**Files:**
- Modify: `ServerScriptService/Weapon/Weapons/DBShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/PumpShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/KBShotgun.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Revolver.luau`

- [x] Require `ImpactService` directly.
- [x] Calculate explicit Impact at the already-known hit distance.
- [x] Send attacker-to-target or projectile direction after validation.
- [x] Remove KB Shotgun legacy knockback budget and direct knockback call.

### Task 3: Migrate Explosive Weapons

**Files:**
- Modify: `ServerScriptService/Weapon/Weapons/RPG.luau`
- Modify: `ServerScriptService/Weapon/Weapons/HandCannon.luau`

- [x] Let shared `Explosion` apply enemy Impact using new explosion config.
- [x] Remove direct-hit enemy knockback from both weapons.
- [x] Preserve direct-hit prototype damage and existing self-explosion movement.

### Task 4: Migrate Melee Weapons

**Files:**
- Modify: `ServerScriptService/Weapon/Weapons/Pan.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Rock.luau`
- Modify: `ServerScriptService/Weapon/Weapons/ClassicSword.luau`
- Modify: `ServerScriptService/Weapon/Weapons/GreatSword.luau`

- [x] Apply direct attacker-to-target Impact after melee validation.
- [x] Select Classic Sword attack/lunge and Greatsword swing-specific Impact config.
- [x] Flatten sword launch direction where its identity is horizontal.
- [x] Remove sword legacy knockback imports and calls.

### Task 5: Review Full-Roster Coverage

- [x] Confirm every in-scope server weapon calls `ImpactService` directly or uses configured shared explosion Impact.
- [x] Confirm migrated weapons contain no direct legacy enemy knockback.
- [x] Confirm excluded weapons and user-owned dirty files remain untouched.
- [x] Commit only migration files and this plan.
