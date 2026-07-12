# Combat Lifecycle and Weapon Feel Design

## Goal

Make Mayhem's reset, death, knockback, round, deploy, and weapon lifecycles behave as one system. Polish weapon feel for a casual party shooter where weapons create readable movement spikes, enemy displacement, and quick combinations rather than isolated animation sequences.

## Principles

- Game feel and clear weapon roles come before architecture cleanup.
- Base movement maintains flow; weapons create memorable direction changes and combat moments.
- Primary fire performs the weapon's core attack. Secondary fire provides its trick, mobility, or setup.
- Preserve Roblox velocity across weapon actions and swaps unless stopping momentum is the weapon's explicit niche.
- Keep separate weapon files, including current duplicates, as intentional extension points for future functionality.
- Move only true lifecycle and mechanical invariants into shared code.
- Prefer one strict asset/config contract over repeated nil guards and fallback behavior.
- Keep config iteration through the existing `confighotreload.luau` Studio plugin.
- Use Replica for persistent state, not transient combat events.
- Do not add a new automated test framework or spend this pass on broad numerical rebalancing.

## Scope

This pass covers:

- reset, death, scoring, deploy, round-end, respawn, Impact, knockback, and weapon cleanup;
- hard-landing control shock, ranged spread penalty, view/camera feedback;
- action timing and feedback conventions shared by weapons;
- role-focused rewrites of Umbrella, Baseball Bat, ClassicSword, and GreatSword;
- functional lifecycle audit of every remaining listed weapon;
- focused code cleanup that reduces repeated lifecycle work and hidden data loading.

This pass does not merge duplicate weapon files, replace Replica, replace the config plugin, create a generic ability framework, enable the currently disabled live round loop, or comprehensively rebalance every damage/cooldown value.

## Character and Round Lifecycle

`DamageHandler` remains the single authority for damage, death publication, reset death, killer/assist attribution, and scoring eligibility. Restore its real health/death path; remove the temporary damage-disable block.

Add one explicit scoring mode controlled by the Round handler. Only the active `Round` phase records leaderboard entries and awards progression. Countdown, ended, menu, and development sandbox play may still produce normal death feedback and redeploy without awarding round stats.

### Reset

- A deployed player reset goes through the normal death path with the player as killer.
- It clears Impact and pending movement/weapon activity, marks the character undeployed, shows the standard death screen, and permits the normal deploy flow when deployment is open.
- Reset remains a suicide even when another player recently pushed the victim.
- A non-deployed reset does not create a kill, death screen, assist, or progression event. It leaves or returns the player to menu state.
- Repeated reset/death requests against a character already marked `Dead` do nothing.

### Death and cleanup order

1. Mark the current character dead once.
2. Clear Impact state and attribution immediately.
3. Apply humanoid death and publish the transient `PlayerKill` event.
4. Publish scoring/assist bindables only when scoring is enabled.
5. The deploy death connection marks player and character undeployed.
6. Weapon systems tear down from undeploy/character removal; movement, camera, projectile, and client weapon work dies with the character Trove.
7. A later deploy creates a clean character with neutral Impact and new weapon instances.

`ImpactService.Clear(character)` removes the service state entry and resets Impact, pips, primed, and protection attributes. Character removal also clears stale state as a fallback.

### Round end

Round end uses one deploy cleanup operation. It closes deployment, marks players undeployed, clears combat state, removes the current character without publishing a fake kill, and opens the menu. Do not fire `PlayerKill` and `EnableMenu` back-to-back to simulate cleanup.

`Config.DISABLED` remains unchanged. Development sandbox mode keeps movement, weapons, combat deaths, and redeploy working while scoring stays disabled.

## Replica and Event Boundaries

Keep `RoundState` Replica as the client source for persistent round phase, movement permission, weapon permission, timers, scores, and leaderboard state. Keep `PlayerData` Replica as the hotbar/loadout source.

Do not replicate transient hit, knockback, camera shake, or kill-contact packets through Replica. Continue using the existing `Knockback` and `PlayerKill` remotes for those one-shot events. Server reset/deploy decisions remain authoritative even when the client observes the same round state.

Avoid new replicated fields unless an approved lifecycle state cannot be expressed by current `phase`, `movement`, `enabledPlrs`, and player/character `Deployed` attributes.

## Weapon Runtime Cleanup

### Data loading and hot reload

Keep `confighotreload.luau` unchanged. Client and server `BaseWeapon` explicitly load Config, Animations, and Info rather than scanning every child of the Data folder for every weapon instance.

Normal Animations and Info modules use Roblox `require` caching. Config uses one snapshot per `DevConfigRevision` on each side. When the existing revision signal fires, refresh the Config snapshot once and rebuild hotbars. Every rebuilt weapon then sees the same revision.

### Remote routing

The server Weapon Handler owns one `WeaponEvent` connection and routes callbacks to the currently equipped weapon after the existing deployed/current-character checks. `BaseWeapon:_Equip` no longer creates one global remote connection per equipped weapon instance.

Projectile fire/update routing remains in the existing central Projectile/Weapon handlers.

### Action lifetime

Client and server base weapons expose a small lifecycle generation/token. Equip begins a generation; unequip, undeploy, character replacement, and destroy invalidate it. Delayed attack, reload, charge, flame, and animation work checks the generation at phase boundaries and exits without mutating a replaced weapon.

This is cancellation plumbing only. Weapon files still own their sequences and state. Do not create generic attack/state-machine classes.

### Strict contracts

Required weapon config, models, attachments, animations, and sounds are validated once during construction. After construction, action code calls required assets directly. Remove repeated animation/sound nil guards, fallback waits, dead imports, debug prints, and silent failure paths. Only features explicitly optional in config receive optional handling.

## Shared Weapon Feel Contract

Every attack has three explicit phases:

1. **Anticipation:** readable windup and input commitment; hitbox and server validator are inactive.
2. **Active:** client hit volume and server attack window begin together; trails and strongest motion feedback are active.
3. **Recovery:** hitbox/validator are closed; the player may regain steering or swap according to the weapon's intended commitment.

Gameplay timing drives animation duration. Action code does not wait indefinitely for animation completion. A weapon swap or lifecycle invalidation ends hitboxes, validators, trails, forces, and delayed callbacks exactly once.

On first confirmed local melee contact, provide exaggerated but short feedback:

- brief swing-animation hit-stop without freezing character movement;
- camera punch scaled by light/heavy contact;
- immediate impact sound and trail/emitter burst;
- existing hit marker/Impact feedback;
- one bounded attacker movement response.

Server damage and Impact remain authoritative. Local contact feedback never grants a second server hit or waits for server round-trip.

Light weapons may swap during recovery. GreatSword blocks swapping only through its active contact phase. Whiffs retain readable recovery but avoid long non-interactive lockouts.

## Weapon Roles

### Umbrella — momentum bridge

Inputs become LMB thrust/lunge and hold RMB glide.

Umbrella sets up another weapon rather than acting as an offhand passive or self-contained defense tool:

- thrust is short, bounded, and quickly swappable;
- thrust and lunge hits preserve resulting velocity after the action ends;
- a successful lunge adds a small upward carry for aerial follow-up;
- glide primarily controls descent and stabilizes steering;
- ordinary horizontal launch momentum receives little or no damping;
- extreme velocity may receive gentle drag only to keep the result readable;
- opening while descending catches downward velocity instead of granting an unconditional repeatable upward pop;
- shotgun, rocket, stomp rebound, vault, and enemy knockback momentum can flow into glide;
- releasing RMB or switching weapons closes the umbrella and removes its forces without rewriting current velocity.

The existing weapon may continue using local VectorForces. Those forces must express the behavior above and clean up through one glide lifetime. Umbrella does not continue gliding invisibly after a swap and does not allow another weapon to fire while it remains equipped.

### Baseball Bat — knockback setup and finisher

LMB performs a quick readable shove with modest damage and strong positional value. Hold RMB charges one homerun; releasing RMB swings.

- Charge uses elapsed time, not separate increment loops.
- Client and server derive the same bounded charge fraction from one start/release sequence.
- Normal swing and homerun each open their validator only during the visible active frames.
- Homerun scales Impact/launch much more than raw damage.
- A connected homerun receives the strongest short hit-stop/camera/audio response in this group.
- A missed homerun has meaningful recovery; a normal swing remains easy to use.
- Charge can coexist with ordinary movement but clearly communicates commitment.
- Bat excels at hazards, team setups, and consuming primed opponents rather than replacing ranged damage.

### ClassicSword — fast duelist and mobility bridge

LMB is a quick slash. RMB is an explicit lunge. Remove double-click timing.

- Slash is fast, forgiving, low commitment, and modest in damage/Impact.
- Lunge uses `Movement:StartLunge` and a lunge-specific detached hit volume/config.
- Lunge applies bounded missing velocity instead of stacking raw impulses.
- A lunge can carry into a quick weapon swap, shotgun shot, rocket shot, or Boots action.
- Server mode and validator change at the same time as the corresponding local active volume.
- Sword remains versatile stock-style equipment but is weaker at crowd control and raw launch than Bat/GreatSword.

### GreatSword — deliberate crowd-control combo

Each LMB press queues one swing. Remove hold-to-auto repetition.

- A forgiving queue window accepts the next click during late active/recovery.
- First and second broad sweeps reposition groups with escalating Impact.
- Third swing is the clear heavy launcher and largest feedback event.
- Combo resets after a readable pause.
- Each server validator window matches that swing's actual active hit window.
- Swapping is blocked through active contact, then allowed during recovery.
- Heavy equip weight, anticipation, and whiff recovery provide weakness; controls remain responsive.
- GreatSword occupies its current large slot cost and does not copy Bat's hold-charge identity.

## Remaining Weapon Functional Audit

Keep every weapon module separate. Apply the shared lifecycle contract, then correct functional mismatches without redesigning already coherent roles.

- **Pistol, Revolver, HandCannon:** firing/reload cancellation, recoil/spread recovery, client/server hit parity, required Info entries.
- **DBShotgun, PumpShotgun, KBShotgun:** whole-shot damage and Impact semantics, consistent self-push, pellet feedback, distinct existing roles.
- **RocketLauncher, RPG:** projectile cleanup, explosion attribution, deflection ownership, and movement-launch carry.
- **Pan, Rock:** one boost per swing, responsive contact, readable deflection success, correct pending-projectile resolution.
- **Boots:** airborne equip/stomp lifetime, direct versus radial landing response, rebound chains, ordinary boot attack cleanup.
- **Flamethrower:** repair its missing `Shoot` attachment assumption; end flame/burn/update loops on swap, death, or reset.
- **Medkit:** throw/heal projectile lifetime and cleanup.

Audit the complete weapon list for client module, server module, Config, Info, required Animations/Sounds, and model attachment parity. Missing required data is fixed at the source rather than hidden behind guards.

## Hard-Landing Shock

Hard landing remains transient locomotion data, not a state or stun. Landing computes one severity value from peak downward speed.

Severity controls:

- current horizontal bleed and low-friction drift;
- a stronger brief reduction in steering/ground acceleration;
- smooth control recovery;
- an additive ranged spread penalty emitted through existing `Movement.SpreadChanged`;
- one short downward positional/rotational camera shake through the existing Camera module;
- a small viewmodel vertical kick.

A buffered landing jump heavily reduces all shock outputs: bleed, control loss, spread, camera shake, and viewmodel kick. The player can always shoot and act; hard landing affects handling rather than disabling input.

Movement calls the already-loaded Camera module directly. Do not add a landing bindable or replicate camera shake.

## Failure and Cleanup Rules

- Zero-length directions, missing current characters, and already-dead characters return without mutation.
- Required weapon assets fail once during construction with a concise contract error.
- Invalid server hits do nothing and close naturally with the current attack window.
- Unequip/destroy always invalidates action work before detaching models or clearing references.
- Round/deploy cleanup never publishes fake combat events.
- Impact state never survives its character.

## Verification

Use focused static checks rather than adding a test framework:

- every listed weapon has intended client/server/data presence;
- central remote routing has no per-weapon duplicate connection;
- death/reset/round-end paths publish the intended events once;
- Impact state has explicit cleanup calls;
- active hit windows align between client sequence and server validator;
- no stale action loop can survive unequip/destroy;
- no debug prints, dead imports, or repeated required-asset guards remain in touched code;
- `git diff --check` is clean.

Roblox Studio playtesting remains required for weapon feel, animation alignment, camera shake, hard-landing control loss, and cross-weapon momentum chains. The existing Config hot-reload plugin is the tuning loop.

## Success Criteria

- Reset works in sandbox and round flows, never hangs because damage is disabled, and never double-counts death.
- Round end cleanly returns players to menu without fake kills or stale Impact/weapons.
- Knockback/Impact state belongs only to the current deployed character.
- Umbrella turns launches into controlled aerial setups and hands momentum cleanly to the next weapon.
- Bat charge/release is readable, synchronized, and satisfying on hit or whiff.
- ClassicSword slash/lunge controls are explicit and its lunge composes with movement/weapon swaps.
- GreatSword combo responds to deliberate clicks, controls groups, and does not trap the player through unnecessary recovery.
- Hard landings create visible shock, handling loss, and spread without becoming a stun.
- Existing duplicate weapon files remain available for future divergence.
- Config changes continue applying through `confighotreload.luau` with one coherent Config revision per rebuild.
