# Vault Reference Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore reliable jump-triggered vaulting from the working reference while keeping bounded momentum physics.

**Architecture:** `Handler` buffers `JumpRequest` and chooses vault before jump. `RaycastModule` performs only the reference body-hit/head-clear/close checks. `Actions/Vault` owns bounded physical response and held-jump exit; no top geometry data crosses boundaries.

**Tech Stack:** Roblox Luau, `UserInputService`, workspace raycasts, ControllerManager movement.

## Global Constraints

- Cleanup only vault path and nearby handler/config code.
- Do not add a vault state, controller, tag requirement, or automatic vault trigger.
- Preserve incoming velocity and apply only missing velocity.
- Respect `NoVault` on hit part or ancestor model.
- No new automated test plan; use focused static contract checks.
- Leave unrelated dirty files untouched and do not retry unavailable commits.

---

### Task 1: Restore reference-style sensing

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/RaycastModule/init.luau`

**Interfaces:**
- Produces: `RaycastModule:VaultCheck(forwardDir: Vector3) -> { Part: BasePart, TooClose: boolean }?`.
- Consumes: character root/head, shared collision-aware ray parameters, `NoVault` tag helper.

- [ ] **Step 1: Replace top probing with three direct casts**

Use requested planar direction for all casts. Cast body from `HRP.Position + up * -0.6`, clearance from `Head.Position + up`, and close detection from `HRP.Position + up * 0.1`. Body and clearance use `RaycastModule.VaultLength`; close uses `RaycastModule.VaultCloseLength`. Return only `Part` and `TooClose` when body hits, clearance misses, and hit does not opt out.

- [ ] **Step 2: Remove vault-only dead helpers/data**

Delete `_BestHit` if no other caller remains. Keep shared `_Cast`, wall, ground, and debug helpers unchanged.

### Task 2: Simplify trigger and action data flow

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`

**Interfaces:**
- Consumes: `Cast:VaultCheck(direction)` returning `Part` and `TooClose`.
- Produces: `Movement:TryVault()` with no mode argument and `StartAction("Vault", { Direction, TooClose })`.

- [ ] **Step 1: Make vault manual and predictable**

Remove `mode`, auto-speed guard, height guard, `TopPosition`, and per-frame auto-vault call. Buffered jump tries `TryVault()` once before `TryJump()`.

- [ ] **Step 2: Capture jump through Roblox jump intent**

Replace filtered space `InputBegan` connection with:

```luau
trove:Connect(UserInputService.JumpRequest, function()
	self.SpaceBufferedUntil = time() + self.Config.Movement.JumpBufferTime
end)
```

Retain `UserInputService` for held-space vault exit.

- [ ] **Step 3: Remove unused vault config**

Delete `AutoMinSpeed`, `MaxHeight`, and lift-from-height fields. Add fixed `LiftSpeed`; keep forward gain/caps, close nudge, duration, cooldown, and jump-exit fields. Ray distances stay with the ray module instead of passing sensor configuration through the handler.

### Task 3: Make vault action independent of geometry topology

**Files:**
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Actions/Vault.luau`

**Interfaces:**
- Consumes: `{ Direction: Vector3, TooClose: boolean }`, `Movement:Boost`, and `Config.Actions.Vault.LiftSpeed`.

- [ ] **Step 1: Remove top-position lift math**

Delete square-root height calculation. Apply close nudge when requested, boost toward bounded forward speed, then apply only `max(LiftSpeed - currentUp, 0)` upward.

- [ ] **Step 2: Keep bounded held-jump exit**

Retain delayed held/buffered jump exit, normal jump cooldown, bounded forward boost, and only missing upward jump velocity.

### Task 4: Verify scoped contract

**Files:**
- Verify: four modified vault-adjacent files

- [ ] **Step 1: Run static assertions**

Confirm `JumpRequest` exists; raw jump `InputBegan`, auto-vault, `TopPosition`, `MaxHeight`, `AutoMinSpeed`, and top ray logic are absent; body/head/close casts and `NoVault` remain; action uses bounded boost and fixed missing lift.

- [ ] **Step 2: Check diff hygiene**

Run `git diff --check` and inspect only scoped diffs. Report that Studio runtime behavior still requires playtesting because no local Roblox runtime or Luau analyzer exists.
