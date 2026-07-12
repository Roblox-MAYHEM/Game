# Mayhem Knockback Combat Game Design

## Purpose

Make Mayhem a casual, team-oriented FPS where combat builds toward readable Smash-style launch sequences. Players win space, remove enemies from objectives, and score ring-outs by increasing an Impact meter and converting it into powerful knockback.

The final combat model does not use health or damage. The current prototype keeps its health bar, damage values, and related systems only as scaffolding. They must not determine Impact, launch strength, weapon value, or future balance decisions.

## Core Promises

- Hits feel physical and tell a consistent story: a stronger-looking hit adds more Impact and pushes farther.
- Most combat remains stable enough to aim, move, and make weapon choices.
- Knockback creates positioning decisions and fight climaxes instead of constant helpless airtime.
- Every weapon can participate in building Impact, launching enemies, recovering, or creating follow-ups.
- Team objective play is the balance baseline. Free-for-all exists as a deliberately more chaotic variant.
- Ring-outs create quick, funny reversals without long elimination or spectating.

## Core Design Principles

### Meter raises danger, not helplessness

Rising Impact makes launches gradually stronger and warns that a finisher sequence is approaching. It must not cause escalating stun, aim interruption, or loss of basic control.

### Meter and physical reaction tell the same story

Impact gain and ordinary push come from the same primary concept: **Impact Power**. Large, difficult, or slow hits generally add more meter and move the victim farther. Small, frequent hits do both in smaller amounts.

Rare exceptions are allowed for obvious utility weapons, such as a wind tool whose main fantasy is pushing. Those exceptions must be visually self-explanatory.

### Position determines lethality

High Impact creates an opportunity; it does not guarantee a ring-out. Attacker position, hit direction, map geometry, victim recovery, and team interference determine whether a finisher removes someone from play.

### Displacement is the punishment

Being launched already costs objective presence, cover, formation, and time. The game should not routinely add long stuns, ragdolls, weapon locks, camera theft, or movement disables on top of that punishment.

### Base movement preserves agency; weapons create dramatic movement

Victims retain limited steering and weapon access after the brief committed portion of a launch. Recovery weapons and map routes create decisions. Universal movement should not erase a well-aimed finisher.

## Combat Loop

1. Players fight for objectives, advantageous angles, and control of launch lanes.
2. Hits add Impact and apply corresponding ordinary push.
3. Rising meter mildly increases ordinary knockback, making danger readable without destabilizing every exchange.
4. Reaching maximum Impact makes the victim **Primed**.
5. Primed creates a short finisher sequence in which several distinct hits can apply strong launch force.
6. Attackers chase, redirect, or deny recovery. Victims steer, shoot, use recovery tools, and seek safer geometry or team help.
7. The sequence ends in a ring-out, temporary exile from the objective, or successful recovery.
8. Impact drops partly rather than resetting completely. Escaping combat also causes slow meter decay.

The intended emotional rhythm is:

**Pressure -> warning -> launch sequence -> ring-out or escape -> reset into neutral**

## Impact and Ordinary Knockback

Each offensive hit has one primary strength concept: Impact Power.

- Impact Power determines how much the meter rises.
- Impact Power determines the hit's ordinary push.
- Current meter mildly increases that ordinary push.
- Weapon delivery determines direction, range, reliability, area, and hit frequency.

Impact Power does not need to produce mathematically identical meter gain and movement for every weapon. It must produce an intuitive correlation. A player should be able to watch a hit and understand why both the meter and movement changed.

This avoids hidden builder weapons that barely react physically but secretly fill a large portion of the meter. Weapon differences should come mainly from how they land hits and what launch geometry they create, not from contradictory meter rules.

## Primed Finisher Sequence

At maximum Impact, the meter visibly changes into a Primed state and displays a small set of finisher opportunities.

- Every weapon can convert Primed; no loadout needs a mandatory finisher category.
- A brief, obvious transition prevents the same attack that fills the meter from invisibly causing a major launch.
- Each distinct follow-up attack can consume one finisher opportunity and cause boosted knockback.
- Multi-pellet attacks count as one attack, not one finisher per pellet.
- Continuous attacks receive spaced conversion opportunities rather than producing a launch every simulation tick.
- The first bad-angle or accidental conversion does not waste the entire setup. Attackers can attempt follow-up launches.
- Follow-ups become naturally harder because the target is already moving away.
- Consuming the sequence drops Impact to a moderate level.
- Escaping until Primed expires leaves more Impact than a fully consumed sequence, but still rewards the escape with a partial reset.
- Brief post-sequence protection prevents an immediate return to Primed.

Primed should read as a short chase and recovery phase, not a stun state. The victim remains an active participant.

## Universal Finishers and Weapon Identity

All weapons receive a universal minimum finisher launch. This guarantees that any loadout can convert good positioning into a ring-out near an edge.

Weapons differ in finisher quality through understandable properties:

- **Direction:** away from shooter, along swing direction, away from explosion center, upward, or downward.
- **Force:** easy and reliable attacks generally launch less; slow, precise, close-range, or risky attacks launch more.
- **Control:** some weapons offer precise launch angles, while others provide broad but less exact displacement.
- **Follow-up potential:** fire rate, travel time, recovery, and range affect ability to chase a launched target.
- **Recovery value:** some weapons trade offensive conversion strength for self-save or trajectory correction.

Examples of intended identity:

- Pistol: reliable small hits and a straightforward moderate finisher away from shooter.
- Flamethrower: frequent tiny pushes and accessible but weaker spaced finisher bursts.
- Rocket: radial push and strong angle control based on explosion placement.
- Bat: risky close-range contact with excellent horizontal sending power.
- Greatsword: committed strike with strong directional arc.
- Shotgun: range-dependent push with strongest conversion nearby.
- Umbrella: recovery utility and vertical or gust-shaped launch behavior.

Weapon swapping should improve conversions and create expressive combos, but it must never be required to make a loadout functional.

## Making Finishers Punishing

A finisher is substantially stronger than ordinary knockback. Its job is to convert accumulated pressure and good positioning into one of three punishments:

### Displacement

The victim loses the objective, high ground, cover, or proximity to teammates. This creates an immediate numbers advantage even without a ring-out.

### Recovery scramble

A central launch sends the victim beyond the main combat space and forces a return choice. Fast routes are exposed or mechanically demanding; safer routes take longer. The victim can still steer, shoot, and use recovery tools.

### Ring-out

A clean finisher near an edge should usually threaten the void. Correct launch direction, follow-up aim, victim resources, and recovery execution decide the outcome.

During the opening moment of a major launch, the victim cannot reverse its direction. Limited steering then allows bending the trajectory rather than canceling the attacker's choice. Horizontal and downward sends are generally more lethal; upward sends create longer exile and follow-up opportunities.

## Preventing Constant Knockback From Becoming Unfun

- Keep ordinary knockback modest even as it scales with meter.
- Never add routine hitstun, aim punch, ragdoll, or camera seizure to ordinary hits.
- Let players shoot during ordinary displacement and most recovery states.
- Make major launches a recognizable phase rather than a surprise attached to every high-meter hit.
- Limit how rapidly continuous or multi-hit weapons can trigger separate finisher bursts.
- Partly reset Impact and grant brief protection after the finisher sequence.
- Slowly decay meter after a player successfully leaves combat.
- Preserve limited air steering, but never enough to reverse a committed finisher.
- Use recovery weapons and map routes for counterplay instead of a universal escape button.
- Give players clear offscreen hit and launch-direction information.
- Keep respawns quick and protected.

The central rule is: **a hit may change a player's position, but it should rarely stop that player from playing.**

## Team Play

Team area-control modes are the primary balance environment.

- Launching an enemy off an objective is valuable even without a kill.
- Primed enemies become readable team callout targets.
- Teammates protect recovering allies through cover fire, body-blocking follow-ups, occupying launch lanes, and pressuring pursuers.
- Attackers combine pressure, angles, and follow-up shots without requiring formal class roles.
- Ring-out credit goes to the player responsible for the decisive launch.
- Recent contributors to the victim's Impact receive setup assists.
- Friendly attacks do not add Impact or launch allies in standard modes.

Objective progress remains the main win condition. Ring-outs support control of the objective rather than replacing it with deathmatch behavior.

## Free-for-All

Free-for-all treats ring-outs as the direct scoring objective and accepts more chaos than team modes.

Mode-specific tuning may slow Impact growth or strengthen post-sequence protection if dogpiling dominates. These changes should alter pacing, not teach different core rules. Players must still understand Impact, Primed, finishers, and recovery exactly as they do in team modes.

## Map Design

Maps decide whether knockback creates strategy or random deaths.

### Objective geometry

- Place objectives close enough to open space that strong, well-angled finishers matter.
- Give each contested area a small number of readable launch lanes.
- Use walls, cover, and inward-facing safe angles elsewhere so every hit is not a ring-out attempt.
- Let teams fight over the dangerous angles rather than surrounding each objective with equal void exposure.

### Recovery geometry

- A finisher from center should usually begin a recovery scramble rather than guarantee death.
- A finisher from an exposed edge should usually threaten a ring-out.
- Provide selected side routes or catch platforms that require steering and awareness.
- Do not place a giant safety floor beneath the entire arena.
- Keep the kill boundary close enough that falling feels urgent and readable.
- Make fast return routes risky and safe routes slower.

### Spawn geometry

- Spawn players through protected routes with no immediate void exposure.
- Prevent direct firing into spawn exits.
- Make return travel short enough to preserve party-game pacing while still rewarding the team that earned the ring-out.

### Visual clarity

- Make lethal void, safe ground, catch routes, and launch lanes visually distinct.
- Avoid decorative geometry that looks safe but is not collidable.
- Keep likely launch trajectories readable from first-person view.

## Feedback and Readability

Impact must be legible without demanding constant HUD attention.

- Meter color and character effects intensify as Primed approaches.
- Primed has unmistakable victim, attacker, and nearby-player feedback.
- Remaining finisher opportunities appear as simple visible pips.
- Each finisher burst has stronger sound, hit pause, trail, and camera response than an ordinary hit.
- Launch direction is visible through trails and offscreen indicators.
- Ring-outs clearly credit decisive launcher and setup contributors.
- Recovery protection has subtle feedback so failed follow-ups do not look like bugs.

Feedback should sell force without obscuring aim or hiding the next interaction.

## Balance Framework

Balance around interaction quality before exact values.

### Healthy combat should produce

- Stable aiming during most neutral combat.
- Visible growth from safe positioning toward dangerous edge play.
- Major launch sequences as periodic fight climaxes, not the default state.
- Multiple possible outcomes after a finisher: displacement, recovery, follow-up, or ring-out.
- Weapon combinations that improve options without becoming mandatory recipes.
- Quick desire to re-enter play after a ring-out.

### Warning signs

- Players spend more time airborne than choosing attacks.
- Primed targets die regardless of position or launch direction.
- Recovery routinely succeeds regardless of finisher quality.
- One rapid-fire weapon builds and converts Impact more safely than the full roster.
- Heavy weapons feel pointless because easy weapons finish equally well from center.
- Players ignore objectives to chase Primed enemies across the map.
- FFA becomes repeated dogpiling of one visible target.
- Victims cannot explain why a hit launched them or why recovery failed.

### Tuning order

When playtests reveal a problem, tune in this order:

1. Map distance and launch lanes.
2. Ordinary knockback growth.
3. Primed conversion strength and direction.
4. Recovery steering and weapon options.
5. Primed duration, conversion spacing, and post-sequence protection.
6. Impact gain rate.

This order keeps the spatial game central. Avoid fixing bad map geometry by distorting every weapon.

## Prototype Plan

Keep health, damage, the health bar, and current knockback code intact while testing this direction. Treat them as observation aids only. A player reaching zero health must not be used as evidence that the future combat loop works.

Prototype the smallest useful slice:

- One team area-control map with clear safe sides and dangerous launch lanes.
- A small weapon set covering rapid, explosive, melee, and recovery behavior.
- Impact meter and ordinary push driven by the same weapon strength story.
- Primed feedback and several finisher opportunities.
- Void ring-outs, quick respawn, assist attribution, and basic recovery routes.
- No progression, contracts, random modifiers, or expanded content during core validation.

## Playtest Questions

Observe before explaining the design.

- Do players understand that stronger hits both fill meter and push farther?
- Do players notice when an enemy becomes Primed?
- Do attackers reposition for better launch angles?
- Do victims make meaningful recovery choices?
- Does a far launch feel punishing without feeling like dead time?
- Do teammates capitalize on temporary numbers advantages?
- Can victims explain why they were ringed out?
- Do players attempt weapon swaps and follow-ups without being instructed?
- Are ring-outs funny and exciting while ordinary aiming remains reliable?
- Do players want to respawn immediately?

Track the frequency and outcome of Primed sequences, time removed from objectives, recovery success by launch origin, ring-outs by weapon, repeated-launch complaints, and whether objective play improves after displacement. Use these observations to preserve the intended rhythm of a major launch climax roughly every twenty to thirty seconds of active fighting, rather than tuning for maximum spectacle.

## Non-Goals

- Recreating Smash frame data, shields, grabs, stocks, or platform-fighter controls.
- Making every ordinary hit dramatically displace its victim.
- Balancing the final system around health or damage.
- Requiring a specific finisher weapon in every loadout.
- Making ring-outs the primary win condition in team objective modes.
- Solving weak combat through progression, randomness, or content volume.
- Adding universal escape mechanics that cancel weapon identity and launch direction.

## Definition of Success

The design succeeds when players spend most combat time aiming, moving, and fighting for space; understand rising Impact without explanation; recognize Primed as a shared climax; and experience strong launches as interactive scrambles with clear causes. Ring-outs should reward pressure, positioning, and follow-up skill while keeping death brief, funny, and immediately replayable.
