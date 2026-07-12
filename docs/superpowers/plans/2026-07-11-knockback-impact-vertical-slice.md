# Knockback Impact Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one playable Impact-to-Primed-to-ring-out loop using Pistol, Rocket Launcher, Baseball Bat, and Umbrella while keeping existing health and damage as prototype scaffolding.

**Architecture:** Add one direct `ImpactService` beside existing weapon modules. Weapons keep validating their own hits, call existing damage code, then call `ImpactService.ApplyHit` with explicit Impact Power and launch direction. `ImpactService` owns transient meter state and decides ordinary push versus Primed finisher; existing `Knockback` remains the movement actuator.

**Tech Stack:** Roblox Luau, current server weapon modules, character attributes, existing knockback remote and movement state, existing CharHUD/Fusion bootstrap.

## Global Constraints

- Favor direct calls and small modules. Do not add a combat resolver, formula layer, replica layer, saved Impact data, or generalized effect framework.
- Fit existing weapon-module and Loader patterns. Refactor only code touched by this vertical slice.
- Add explicit Impact Power. Never derive Impact from damage at runtime.
- Keep health, damage, health UI, kill feed, kill-cam, and deploy flow working as prototype scaffolding.
- Ordinary hits preserve aim and movement. Finishers briefly commit launch direction, then return control through normal air movement.
- Use one central tuning table inside `ImpactService`; expose only values that materially change feel.
- Keep untouched weapons on old behavior during this vertical slice.
- Do not add test-plan tasks, security work, or defensive abstraction unrelated to gameplay.

---

## File Structure

### Create

- `ServerScriptService/Weapon/Modules/ImpactService.luau` — transient Impact state, Primed lifecycle, decay, push/finisher decision, last-launch attribution.
- `StarterGui/CharHUD/ImpactDisplay.luau` — local Impact HUD plus always-visible character meters and Primed pips, loaded by existing CharHUD bootstrap.
- `ServerScriptService/Ringout.luau` — tagged void-zone detection routed into existing death and kill-cam flow.

### Modify

- `ServerScriptService/Weapon/Modules/Knockback.luau` — label packets as ordinary push or finisher launch.
- `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau` — apply ordinary push directly; route finishers to launch state.
- `StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau` — brief committed finisher phase, then end into normal Air movement.
- `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau` — retain only feel-critical finisher commitment configuration.
- `ReplicatedStorage/Assets/Weapons/Data/Config.luau` — explicit Impact Power and finisher shape for four weapons.
- `ServerScriptService/Weapon/Weapons/Pistol.luau` — apply distance-scaled Impact after validated projectile hit.
- `ServerScriptService/Weapon/Weapons/RocketLauncher.luau` — remove separate enemy launch and let explosion resolve Impact once.
- `ServerScriptService/Weapon/Weapons/BaseballBat.luau` — route normal and charged hits through Impact.
- `ServerScriptService/Weapon/Weapons/Umbrella.luau` — give lunge explicit Impact and gust-shaped launch.
- `ServerScriptService/Weapon/Modules/Explosion.luau` — use Impact for enemy push while preserving self-rocket movement and prototype damage.

---

### Task 1: Direct Impact State and Resolution

**Files:**

- Create: `ServerScriptService/Weapon/Modules/ImpactService.luau`

**Interface:**

```luau
export type ImpactHit = {
	Power: number,
	Direction: Vector3,
	FinisherMultiplier: number?,
	UpwardVelocity: number?,
}

ImpactService.ApplyHit(targetCharacter: Model, attacker: Player, hit: ImpactHit)
ImpactService.GetRecentAttacker(targetCharacter: Model): Player?
```

**Replicated character attributes:**

```text
Impact             current meter value
ImpactPrimed       whether finisher sequence is active
ImpactPips         remaining finisher opportunities
ImpactProtected    visible reason a finisher did not retrigger
```

- [ ] **Step 1: Create one state table keyed by character**

Store only transient fields needed for play: current Impact, last hit time, Primed expiry, remaining pips, next allowed finisher time, protection expiry, and last attacker. Create state lazily on first hit and remove it when character leaves; HUD treats missing attributes as zero.

- [ ] **Step 2: Put feel tuning in one local table**

Keep meter maximum, danger point, ordinary push scale, mild meter growth, Primed arming beat, Primed lifetime, pip count, spacing between finisher bursts, post-sequence protection, decay delay/rate, partial reset, and universal finisher force together at top of module. Use current design values only as starting feel, not permanent balance contracts.

- [ ] **Step 3: Implement `ApplyHit` as direct state transition**

Processing order:

1. Reject dead characters and normal-mode teammates.
2. If Primed and armed, consume at most one pip and send finisher launch.
3. If not converting, add explicit `hit.Power` to meter and send ordinary push derived from same power.
4. When meter reaches maximum, enter Primed, show full pips, and start brief arming beat.
5. Record attacker whenever their hit creates physical push; a later ring-out credits latest meaningful attacker.

Keep formula inside this function. Do not extract a calculator module.

- [ ] **Step 4: Update lifecycle on one heartbeat**

Heartbeat handles only three timed changes: delayed slow decay, Primed expiry, and protection expiry. Write character attributes only when displayed state changes. Escaping an unused Primed sequence leaves target in danger range; consuming sequence returns target to moderate Impact.

- [ ] **Step 5: Commit state foundation**

```bash
git add ServerScriptService/Weapon/Modules/ImpactService.luau
git commit -m "feat: add transient impact combat state"
```

---

### Task 2: Separate Ordinary Push From Finisher Launch

**Files:**

- Modify: `ServerScriptService/Weapon/Modules/Knockback.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Handler.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau`
- Modify: `StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau`

**Packet addition:**

```luau
Mode: "Push" | "Finisher"
```

Legacy calls without `Mode` remain finisher-style launches so untouched weapons do not silently change behavior.

- [ ] **Step 1: Add movement intent to knockback packet**

Extend `KnockbackParams` with `MODE`. Forward it as `packet.Mode`. Keep existing velocity calculation, NPC fallback, wall-daze fields, and source label.

- [ ] **Step 2: Apply ordinary push without entering movement state**

In `Movement:ApplyKnockback`, when `packet.Mode == "Push"`, apply delta velocity/impulse directly to `HumanoidRootPart` and return. Do not change state, zero input, alter friction, or block weapons.

- [ ] **Step 3: Make finisher commitment short**

Finisher packets continue entering `Knockback`. `Knockback:OnEnter` applies launch and owns controller during only the committed opening. When duration ends, existing transitions return player to `Air`, `Idle`, or `Running`; normal `Air` movement then supplies limited trajectory bending naturally because finisher momentum is much larger than air-control force.

- [ ] **Step 4: Remove wall daze from new Impact finishers**

Do not send wall-daze settings from `ImpactService`. Keep legacy fields working for untouched bat behavior until Baseball Bat migrates in Task 3. Finisher punishment comes from displacement and void threat, not added stun.

- [ ] **Step 5: Commit movement split**

```bash
git add ServerScriptService/Weapon/Modules/Knockback.luau StarterPlayer/StarterPlayerScripts/Movement/Handler.luau StarterPlayer/StarterPlayerScripts/Movement/States/Knockback.luau StarterPlayer/StarterPlayerScripts/Movement/Data/Config.luau
git commit -m "feat: split impact push from finisher launch"
```

---

### Task 3: Connect Four Representative Weapons

**Files:**

- Modify: `ReplicatedStorage/Assets/Weapons/Data/Config.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Pistol.luau`
- Modify: `ServerScriptService/Weapon/Weapons/RocketLauncher.luau`
- Modify: `ServerScriptService/Weapon/Weapons/BaseballBat.luau`
- Modify: `ServerScriptService/Weapon/Weapons/Umbrella.luau`
- Modify: `ServerScriptService/Weapon/Modules/Explosion.luau`

**Direct call shape:**

```luau
ImpactService.ApplyHit(targetCharacter, self.Player, {
	Power = impactPower,
	Direction = direction,
	FinisherMultiplier = finisherMultiplier,
	UpwardVelocity = upwardVelocity,
})
```

- [ ] **Step 1: Add explicit Impact config beside each attack**

Use `IMPACT_POWER` for fixed hits and `IMPACT_TABLE` where range falloff matters. Add only weapon-specific finisher multiplier/direction fields that communicate identity. Do not copy old knockback settings into a second parallel config.

- [ ] **Step 2: Pistol becomes baseline ranged feel**

After projectile validation and prototype damage, calculate Impact from `IMPACT_TABLE` using same distance already known by pistol. Direction points from shooter toward victim. Pistol has small per-hit push and dependable moderate finisher.

- [ ] **Step 3: Explosion becomes shared rocket Impact point**

For enemy victims, `Explosion.luau` calculates distance falloff, calls prototype damage, then calls `ImpactService` once with radial direction and distance-scaled Impact. Remove direct enemy `Knockback` from explosion.

For sender/self, preserve current direct rocket-jump knockback and self-damage without adding self Impact. This keeps movement utility independent from opponent meter rules.

- [ ] **Step 4: Remove Rocket Launcher's duplicate direct enemy knockback**

Keep direct-hit prototype damage. Let explosion own all enemy Impact and launch so one rocket produces one coherent physical response per target.

- [ ] **Step 5: Baseball Bat uses explicit normal and charged Impact**

Refactor `_GetHitContext` to return prototype damage plus one Impact description. Normal swing uses strong flat horizontal identity. Charged swing increases Impact Power and finisher multiplier through existing charge, but no longer sends separate legacy knockback or wall daze.

- [ ] **Step 6: Umbrella lunge gains readable utility Impact**

After validated lunge and prototype damage, apply Impact away from attacker with upward influence. Keep its offensive finisher weaker than bat because umbrella already provides recovery utility.

- [ ] **Step 7: Commit playable weapon slice**

```bash
git add ReplicatedStorage/Assets/Weapons/Data/Config.luau ServerScriptService/Weapon/Weapons/Pistol.luau ServerScriptService/Weapon/Weapons/RocketLauncher.luau ServerScriptService/Weapon/Weapons/BaseballBat.luau ServerScriptService/Weapon/Weapons/Umbrella.luau ServerScriptService/Weapon/Modules/Explosion.luau
git commit -m "feat: connect core weapons to impact combat"
```

---

### Task 4: Always-Visible Impact Readability

**Files:**

- Create: `StarterGui/CharHUD/ImpactDisplay.luau`

**Consumes:** Character attributes `Impact`, `ImpactPrimed`, `ImpactPips`, `ImpactProtected`.

- [ ] **Step 1: Create local player's Impact HUD**

Clone/reuse the existing `UI.HealthBar` presentation so Impact matches current CharHUD style, then bind fill and number to local character attributes. Place it beside health without replacing health UI. Let existing `UIBootstrap` rebuild the module with each character HUD.

- [ ] **Step 2: Create overhead meter for every character**

For each non-local character, attach one `BillboardGui` to head/root. Show meter fill and number at all times while deployed. Use team-aware colors and keep size stable with distance enough to avoid unreadable screen-filling bars.

- [ ] **Step 3: Show Primed sequence without extra panels**

When `ImpactPrimed` is true, intensify meter color, add character outline/pulse, and render remaining pips in same overhead widget. `ImpactProtected` briefly softens Primed treatment rather than adding explanatory text.

- [ ] **Step 4: Keep cleanup local and direct**

Use CharHUD's Fusion scope for character, attribute, billboard, and cloned-UI cleanup. Do not create a separate StarterPlayer handler, shared UI model, or new remotes; attributes already carry all required state.

- [ ] **Step 5: Commit Impact display**

```bash
git add StarterGui/CharHUD/ImpactDisplay.luau
git commit -m "feat: show impact and primed state"
```

---

### Task 5: Void Ring-Out Through Existing Kill-Cam

**Files:**

- Create: `ServerScriptService/Ringout.luau`
- Optional Studio map change: tag authored void trigger part(s) with `RingoutZone`

**Consumes:** `ImpactService.GetRecentAttacker(character)` and existing `DamageHandler.KillHumanoid`.

- [ ] **Step 1: Bind tagged void zones**

As a top-level ModuleScript, `Ringout.luau` is loaded by existing server Loader. Its `Init` binds current and future `CollectionService` instances tagged `RingoutZone`. On touch, find living player character once and ignore repeated contact while death resolves. If a map has no authored zone, generate one below its bounds for immediate prototype use.

- [ ] **Step 2: Credit latest meaningful attacker**

Ask `ImpactService.GetRecentAttacker(character)`. Kill through existing `DamageHandler.KillHumanoid`; use victim as fallback when no attacker exists. This preserves current `PlayerKilled`, kill feed, leaderboard, ragdoll, death screen, click-to-respawn, and kill-cam path.

- [ ] **Step 3: Make current map void explicit**

Prefer tagging an authored void volume. Until one exists, use the generated zone below map bounds rather than global Y polling. Keep zone close enough to playable underside that falling creates urgent recovery and predictable ring-out timing.

- [ ] **Step 4: Commit ring-out integration**

```bash
git add ServerScriptService/Ringout.luau
git commit -m "feat: route void ringouts through existing death flow"
```

---

## Implementation Order and Feel Gates

1. Impact state must read correctly before weapon tuning.
2. Ordinary push must preserve aim and movement before connecting rapid weapons.
3. Pistol establishes weakest readable push; bat establishes strongest directional finisher.
4. Rocket and umbrella fill radial and recovery-oriented middle cases.
5. UI makes meter and Primed sequence understandable without explanation.
6. Ring-out closes loop through current respawn flow.

Numbers stay centralized and provisional. Tune only when they answer a feel question: whether neutral stays aimable, whether Primed feels threatening, whether finishers preserve attacker direction, and whether recovery remains possible from center but difficult near edge.
