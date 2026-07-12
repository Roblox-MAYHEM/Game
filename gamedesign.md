# OUTLINE

## Short Game Summary:

## Objectives:

* ### **Creative, wacky weapon gameplay:**

  * Unorthodox but intentional weapon ideas  
    * *semitruck*  
  * "Simple but deep" abilities, projectiles, conditions  
    * *So like simple movements which can be used in complicated ways? (ex; a simple movement boosting the player up)*  
  * Versatility, utility, and range  
  * Simple, highly aesthetic models  
    * *Honestly ill just leave this part to hilson at this point* 

    

* ### **Well-polished movement system**

  * HIGH synergy between all moves  
  * "Simple but complex" move combos  
    * *Kind of like parkour reborn?*  
    * *Ensure that is as intuitive as possible*  
  * Responsiveness, satisfying fx  
    * *We need to make it combat warriors level addicting*  
  * Beginner friendly, high skill ceiling	

* ### **Enjoyable scaleable core gameplay loop**

  * Encourage experimentation  
    * *We should also write down how we’re gonna do so*  
  * Uncompetitive friendly atmosphere  
    * More randomness we add less competitive it’ll be (liike people are sweaty asf on smash even though its not themed to be competitive)  
  * Progression gives more tools, rather than making you better  
    * **PLEASE MAKE SURE TOOLS DO NOT GET BETTER THROUGH PROGRESSION (combat warriors, elemental battlegrounds, pixel gun  3D did these and fell off. It works for a while but eventually theres too many people with those weapons and its just too hard for new players)**  
  * Skill-based matchmaking  
    * Skill measured by performance in matches? (1st, 2nd, 3rd?)  
      * Works against smurfs

* ### **Sustainable Community**

  * Foster friendly ~~ecosystem~~ community  
  * Reduce elitism  
    * *randomness*  
  * Encourage community creations, put into game  
    * *Remind me to implement credits into loadout later*  
  * High responsiveness b/w devs \-\> playerbase  
    * *I agree we just gotta make sure we dont get tossed around by them*

* ### **Fun Casual Matches**

  * Easy to jump into at any point  
  * Random element  
    * *Stuff like modifiers, natual disasters*  
  * Competitive, skill-based interactions  
    * *We have modes which are competitive and modes which are just trolling*  
  * Unrepetitive \+ dynamic map  
  * Makes every life count (ie, no spawn-killing, camping, etc)  
    * *Give weapons a long time to kill?*   
    * *Penalize standing still?*

    

* ### **Long-term sustainability**

  * Regular / semi-regular, major updates  
  * Regular events  
    * *Raining tacos*  
    *   
  * Community input

# How We’re Actually Going to Do it:

* ### **Creative, wacky weapon gameplay: \- Create a catalogue to keep track of weapons**

  * Discord Forum (Channel type) to bounce ideas  
    * Idea (Wouldn’t it be funny if we added….) (Rough balancing)  
    * Balancing Stage \#1 (Rough Balancing) — Developers take idea and remodel until it is feasible  
    * Concept Art \* – Role: Artist  
      * \*This stage can be skipped if the modeler came up with the idea  
    * Modelers pick it up  –Role: Modeller (Hilson / ~~Varun~~ / Wenbo)  
    * 4 which can be done interchangably  
      * VFX  
      * SFX \- just pull sounds off of online?  
      * Scripting –Scripters: Alex  
      * Animations –Animators:  
    * Balancing Stage \#2 –Developers  
      * Stat Balancing (less dramatic changes, can just be minor changes in damage or range or recoil, etc)  
    * Implementation  
  * Restrictions on weapons  
    * Try specifically to NOT make guns  
      * Think of wackier concepts (ie. broomsticks)  
    * Feasible to create  
      * New mechanics need to be easy to implement  
    * Each weapon feels distinct  
      * Ex: having multiple snipers which only kill to the head is redundant, or unique abilities  
    * Every weapon has a “niche”  
      * a strength with a weakness to compensate  
      * Ex \- bfg 50, accurate sniper which one shots to body all ranges but has only one bullet chambered and a lengthy reload  
      * Refer to bottom for some example niche types  
    * Weapon abilities *should* have multiple uses  
      * Ex \- a sword lunge being used for damage and mobility  
    * **Weapons have intentional weaknesses to force synergy with other weapons**  
      * **VERSATILITY COMES FROM COMBINATIONS OF WEAPONS, NOT INDIVIDUAL WEAPONS THEMSELVES**   
      * Except for the stock weapons, still give them slight weaknesses and strengths  
    * **Don’t oversaturate one type of weapon (pretty broad; guns, melees)**  
  * Simple, highly aesthetic models

* ### **Well-polished movement system \- I love dopamine\!\!\!\!**

  * Create intuitive (easy to learn) controls  
    * UI and tutorial will definitely help.  
      * Have a pop up show whenever you try and use a movement mechanic which is restricted (wallrun while being nowhere near a wall)  
    * Model after preexisting games (parkour, titanfall, ultrakill, other fps movements)  
      * Research them\!  
    * No clashing controls  
      * C to crouch and c to activate ability is a no-go  
      * Follow-through – when you do something, what you expect to happen will happen  
  * Simple, intuitive conditions  
    * Every movement action can be performed with enough momentum (none of that bs “you can only wallrun once in the air, etc. etc)  
    * Give a “combo system” where as you preserve momentum cooldowns are decreased, velocity is increased, etc  
  * Easy to chain actions  
    * Preserves momentum  
    * Lots of space (ie. grace time) in between actions in order to transition from one to another  
    * Forgiving debounce times  
  * **Game indicators**  
    * **Subtle cues to show whether you can or can’t do something**  
    * **Maybe a little icon pops up whenever you can or can’t do something?**  
  * Immediately provides response to successful action  
    * *You can TELL that you just used a move (provide stimuli0*  
      * *Ex \- little UI effect,*   
      * *SFX and VFX are HUGE for this*  
      * *This isn’t that related but the keystroke indicator might help*  
    * *Realistic camera movements*  
    * *Particle effects on ground and stuff*  
    * *Little trail on gloves like in parkour?*  
  * Reinforce usage of movement mechanics  
    * Creating specific routes that encourage certain move mechanics  
    * Make large gaps between places

* ### **Enjoyable scaleable core gameplay loop**

  * Contracts with odd requirements  
    * Get 10 kills with the double barrel while being above your opponent (requires double barrel and something to boost the player)  
    * Gives xp  
  * Progression through experimentation  
    * You progress significantly faster (exponentially) through trying new weapons more  
      * Each weapon has its own level – as you level it up, you will gain xp, which will progress you  
      * Gains base amount of xp per kill, plus bonus for every headshot, killstreak increase, etc. etc.  
    * Exponentially less value as you play the same weapon  
  * A diverse arsenal of weapons   
    * Having many, unique weapons, which you can only play a small portion of  
    * Rather than a single meta, you learn to create your own playstyle  
    * Try to have balanced weapons / niches  
  * Randomized progression route (novelty)  
    * Crates (gambling\!\!\!\!\!\!)   
      * Gives 1 random weapon  
      * Given every level-up  
    * Tokens every couple levels to unlock a weapon of your choice  
      * Gives the illusion of choice  
      * Players may choose a “favorite” weapon of theirs  
  * Skill-based matchmaking  
    * Skill measured by performance in matches? (1st, 2nd, 3rd?)  
      * Elo, calculated by relative placement to others in match \+ their elos  
      * Works against smurfs  
    * Encourage new players to play by pitting them against players of similar skill level  
      * Beginner lobbies  
      * Probably no   
        I’ll put that into stuff which didn’t fit

* ### **Sustainable Community**

  * Public discord server w/ lots of feedback  
    * Specific bug-report channels, feedback channels, community creations, weapon suggestions, weapon creations  
      * Always respond\! Even if we don’t agree, explain why  
    * Developer sneak-peeks, etc.  
    * Regular polls  
  * Reduce elitism  
    * Randomness (during matches, with weapons, etc.)  
      * Be unserious  
    * DON’T award players for being significantly better  
  * Encourage community creations, put into game  
    * Regular community maps in-game with every update   
      * Add community weapons, etc.  
    * *Dev weapons or money (make weapons intentionally garbage, just funny like boxy buster in pf) like how we pay community creations (can also do ingame currency?)*

* ### **Fun Casual Matches**

  * Randomizer elements during matches (in non competitive gamemodes)  
    * VIP servers where players are given control  
      * Owners given mostly unrestricted controls  
        * Slightly restricted, but you can pay for a premium version? (see what the strongest battlegrounds does)  
      * Makes it very fun to hop on w friends, to play with  
      * Make VIP servers free? (With premium option?)  
  * Little punishment in death   
    * Quick respawn (click space) –punish maybe 2-3 second  
  * Certain randomizer gamemodes (casual)  
    * *Having stuff like ToH modifiers and natural disaster weather machine would be amazing*  
    * *Also play DTS and use rescinded odds*  
    * *Bunny hops, stat buffs, natural disasters, idk*  
  * Penalize camping  
    * Good map design (no blind spots or crazy vantage points) \+ robust movement  
    * Open maps

**Core Promises**

* Constant experimentation with diverse variety of weapons  
* Make unique / cool combos that feel cool  
* Fun low stakes party game with friends \-\> ability to goof around / make fun social interaction

Experiment, diversity, combos, social interaction

[Cursed Problem](https://m.youtube.com/watch?v=8uE6-vIi1rQ) (avoid): Social, high skill competitive multiplayer without politicking

**Party game ([Source](https://alexiamandeville.medium.com/game-design-breakdown-party-games-5c2bd301cb96))**

Key Pillars

* Reduce player cognitive load on mechanics / extrinsic systems  
* Expand diversity through variation — give players the tools to create variety in their results  
* Encourage sharing — give players every opportunity to easily share their finest moments

Potential Considerations

* De-emphasize extrinsic scores/metrics  
* Make scores reward experimentation / social interaction  
* Add inherent randomness/unpredictability to games (reduce skill emphasis and thus competition)  
* Humor / sabatoge  
* Maps have interesting points of interaction (big red button effect)  
  * **Emergent gameplay**  
* Progression \- weapons further along progression are harder to use and more chaotic (get more unique)  
* Extremely low friction going from the moment you press play to actual gameplay.  
* Don’t overwhelm the player with too many options once you join (default loadout)

Replayability

* Unlocking weapons gives sense of progression  
  * Each weapon is potential for a unique approach/experience with the game, not better dmg, etc  
* Underlying motivation is intrinsic \- the promise that the game gives a good experience each round when you interact

Ik “emergent gameplay” sounds kinda pretentious and grandiose, but I genuinely think the existing structures/ideas for this game are already built around this idea and we have the structures to execute on it.

You need to stop asking “what feature would fix it?” and start asking “which layer is failing?”

From your notes, there are four plausible failure points:

1. Moment-to-moment feel is weak  
    Shooting, moving, landing hits, getting launched, and chaining actions may simply not feel satisfying.  
2. The combat problem is not intrinsically fun  
    You said it well yourself: “the core challenge is shooting a moving enemy while you are moving.” That sounds exciting on paper, but in practice it can become low-consistency, low-readability, low-agency chaos.  
3. The game promise and the actual dominant behavior are mismatched  
    You want party experimentation, but the systems may still push players into sweaty optimization, evasive movement, and frustrating whiff-heavy fights.  
4. The fun exists only in edge cases  
    Cool combos may be memorable, but if the average 20 seconds of play is weak, the game will still feel bad overall.

The right way to investigate this is with targeted tests, not broader ideation.

The main methods to investigate it

1\. Split “fun” into layers and test them separately

Do not test the full game first. Test these in isolation:

A. Raw movement test  
 No combat. One map. Just movement tools, routes, jumps, launches, recovery.  
 Question: is moving around pleasurable on its own for 5 to 10 minutes?

If this is not fun, your foundation is bad.

B. Target practice combat test  
 Use bots or stationary/mildly moving targets. Test only weapon satisfaction.  
 Question: do the weapons feel good to fire, hit with, and combo, even before real PvP chaos?

If not, the weapon verbs are weak.

C. Duel box test  
 Small controlled arena, 1v1 or 2v2, very few variables.  
 Question: when both players understand the tools, is the interaction tense and readable, or just messy and random?

If it becomes annoying here, the combat problem itself may be flawed.

D. Party chaos test  
 Only after the above. 6–10 players, goofy map interactions, random modifiers.  
 Question: does chaos amplify already-fun systems, or merely mask weak ones?

A party layer should multiply fun, not substitute for it.

2\. Identify whether the problem is “feel,” “clarity,” or “agency”

After every playtest, ask players only a few forced questions:

* “Did you usually understand why you died?”  
* “Did you feel in control of your movement?”  
* “Did your weapon choices lead to memorable situations?”  
* “Were you excited to try again immediately after dying?”  
* “Did fights feel earned, random, or exhausting?”  
* “Did you have fun during the average life, not just rare highlight moments?”

This matters because players often say “it’s not fun” when they actually mean one of these:

* “I can’t read what’s happening.”  
* “I miss too often for reasons I can’t parse.”  
* “Movement makes aiming feel worse, not better.”  
* “Combos are cool in theory but too rare in practice.”  
* “I spend too much time setting up instead of cashing out.”  
* “Every fight feels similar despite many weapons.”

Those are different diseases.

3\. Instrument the game and correlate metrics with enjoyment

You already listed some good ones. Expand that into a proper diagnosis set.

Track per life:

* average life length  
* average time before first engagement  
* shots fired / shots hit  
* direct hit rate by weapon  
* airborne time  
* time spent grounded but idle  
* distance traveled before death  
* number of weapon swaps  
* number of kills involving more than one weapon  
* number of self-propelled launches  
* number of deaths within 3 seconds of spawn  
* number of fights where both players dealt damage  
* kill source: direct aim / splash / environmental / melee / combo follow-up

Then compare that to player sentiment.

Example interpretations:

* Low hit rate \+ low enjoyment  
   Likely a readability/prediction problem, not just “skill issue.”  
* High airtime \+ low enjoyment  
   Airtime itself is not the fun; maybe players are floating uselessly instead of making meaningful plays.  
* Low multi-weapon kill rate  
   Your synergy fantasy is not actually occurring.  
* High time-to-engagement  
   Movement may be traversal, not gameplay.  
* High spawn death rate / short average lives  
   No room for experimentation.  
* High kill variance from randomness  
   Party chaos may be undermining agency.

4\. Run falsification tests against your favorite assumptions

Some of your assumptions sound plausible but need to be attacked directly.

Assumption: “More randomness reduces competitiveness and increases fun.”

Test three builds:

* no randomness  
* light randomness  
* heavy randomness

Then measure:

* rematch desire  
* perceived fairness  
* funniest moments  
* frustration

Often, randomness helps spectating and highlights, but too much destroys ownership and combo satisfaction.

Assumption: “Weapon diversity creates replayability.”

Test with:

* 3 highly polished weapons  
* 10 decent weapons  
* 20 rough weapons

If 3 polished weapons outperform the larger set, your problem is not content quantity.

Assumption: “Movement-focus makes fights better.”

Test:

* current movement  
* reduced movement build  
* same movement, but larger hitboxes / larger projectiles / more forgiving combat

If reduced movement is more fun, your movement may be overwhelming the shooting.

Assumption: “Synergy between weapons is the core differentiator.”

Track how often players intentionally swap into combos.  
 If most kills come from single-weapon spam, the fantasy is not realized.

5\. Test the game at different skill pairings

Your game can fail for opposite reasons at different levels.

Run tests with:

* total newcomers  
* mid-skill Roblox shooter players  
* very strong movement/FPS players  
* friend groups who naturally joke around

Watch for these patterns:

New players:  
 “Too much is happening, I can’t tell what works.”

Mid-skill players:  
 “This is cool, but inconsistent.”

High-skill players:  
 “There’s one dominant route/loadout/pattern.”

Friend groups:  
 “We laugh in custom moments, but the actual fighting isn’t that compelling.”

That last one is especially important. Social fun can camouflage weak gameplay.

6\. Do “silent observation” sessions

Do not explain the design vision before the test. Just let players play.

Watch:

* what they naturally gravitate toward  
* what they ignore  
* whether they invent routes on their own  
* whether they laugh during gameplay or only after accidental moments  
* whether they keep changing loadouts or settle into one safe option  
* whether they chase fights or avoid them

If players do not spontaneously engage with the thing you claim is core, that thing is not truly core yet.

For your game, the main observation targets should be:

* do players intentionally use movement to create combat openings?  
* do they recognize weapon niches quickly?  
* do they improvise combos without prompting?  
* do they tell stories after lives?

If not, the systems may be too abstract, too subtle, or too execution-heavy.

7\. Use “fun per life” analysis, not just “fun per match”

A lot of multiplayer games look good at match scale but feel bad at life scale.

After each life, ask:

* Was that life interesting?  
* Did I make a meaningful choice?  
* Did I get to attempt something cool?  
* Did I understand the outcome?  
* Did I want to spawn back in immediately?

For a party shooter, each life should create at least one of:

* a setup  
* a scramble  
* a joke  
* a combo attempt  
* a near-miss  
* a satisfying hit  
* a surprising interaction

If many lives contain none of those, the core loop is dead.

8\. Build “minimum fun” prototypes instead of feature-complete ones

Do not test progression, contracts, crates, events, community systems, ranked ideas, or social ecosystem stuff right now.

Make tiny prototypes to answer one question each.

Examples:

Prototype 1: Is grounded TF2-like projectile combat with launch initiation fun?

* rocket launcher  
* double barrel  
* pistol  
* one open map  
* no progression  
* no randomness

Prototype 2: Are weapon combo kills actually happening?

* three deliberately synergistic weapons only  
* UI that clearly surfaces combo states

Prototype 3: Is party sabotage fun or just noise?

* same combat, but with map button / hazard / physics gimmick

The goal is to find the minimum set of elements that is already fun.

9\. Diagnose the FPS-specific risk in your concept

You are blending:

* movement shooter  
* party game  
* weapon-combo sandbox  
* social goofing  
* possible smash-like knockback

That is a dangerous combination because FPS aiming demands readability and consistency, while party systems and knockback systems increase instability.

There are a few common failure modes here:

A. Too much evasiveness  
 Targets are hard to track, so aiming feels futile.

B. Too little commitment  
 Everyone is always escaping, redirecting, or resetting.

C. Too little damage clarity  
 Knockback, projectiles, and movement all distort fight outcomes.

D. Spectacular but low-frequency highs  
 Cool clips happen rarely; average combat feels mushy.

E. Expression is backloaded  
 Players need too much game knowledge before the game becomes fun.

So one very important investigation method is:

10\. Test “readability under motion”

Record fights and review them.

For each death, ask:

* Could the victim plausibly understand what happened in real time?  
* Was the winning play legible?  
* Did the weapon identity read clearly?  
* Could the loser imagine a counterplay?

If the answer is often no, the game may be producing unreadable spectacle, not satisfying combat.

A concrete investigation plan for you

Over 1–2 weeks, run these 6 tests:

Test 1: Movement-only

Question: is traversal alone enjoyable?

Test 2: Weapon-only, low movement

Question: are weapons satisfying on their own?

Test 3: Current full build

Question: where does sentiment drop versus isolated tests?

Test 4: Reduced movement build

Question: does combat improve when targets are more readable?

Test 5: Forgiving projectile build

Increase projectile size/speed modestly.  
 Question: does combat become more satisfying without losing skill?

Test 6: Social/friend-group session

Question: are people having fun because of the systems, or because friends can make anything funny?

For every session, collect:

* 3 words describing the match  
* favorite moment  
* most frustrating moment  
* whether they would queue again immediately  
* whether they felt clever at least once

My current hypothesis from your notes

The most likely issue is:

Your intended fun comes from combo-expression and movement-enabled creativity, but the actual second-to-second experience may be too inconsistent and too hard to read for that fantasy to pay off often enough.

More specifically:

* movement may be making aim harder faster than it makes interactions cooler  
* cool weapon synergy may be too infrequent relative to ordinary gunfights  
* the average life may not contain enough reliable payoff  
* “party” ideas may be compensating for weak core combat rather than enhancing strong core combat

That would explain why the concept sounds strong while the FPS itself “just does not feel fun.”

The most valuable question to answer first

Is the game fun when stripped down to one map, three weapons, no progression, no randomness, and no social gimmicks?

If yes, you have a foundation problem solved.  
 If no, stop expanding and keep cutting until you find the smallest fun version.

The fastest way forward is probably for me to turn your notes into a playtest diagnosis framework with:

* hypotheses  
* test builds  
* survey questions  
* metrics  
* interpretation rules

so you can use it with your team immediately.

Yes— I think projectile-only is a major part of the issue, but the sharper diagnosis is: projectile-only + mostly single-shot + preserved momentum + airborne targets means nearly every duel is asking for the hardest possible aiming task in an FPS: lead a moving target while you are also moving, with very little chance to correct after the initial click. The movement shooters I checked generally do not make every weapon solve that exact problem the same way. (Team Fortress Wiki)
What other FPS games tend to do is split the aiming burden across different weapon types. In TF2, Soldier’s rocket launcher is a slow, straight, no-gravity projectile with splash, knockback, and rocket jumping, but the game also has a large set of hitscan weapons, including shotguns, pistols, miniguns, SMGs, and sniper rifles. TF2’s stock shotgun also guarantees at least one pellet straight down the crosshair, and with fixed spread enabled it uses a deterministic pellet pattern rather than pure randomness. (Team Fortress Wiki)
That pattern matters a lot for you. TF2 does not ask every class to win neutral with a single travel-time prediction shot. Some weapons are for big predictive plays; others are for cleanup, pressure, or continuous correction. Tribes does the same thing in a much faster movement environment: the current Steam page pitches it around jetpacks and skiing, and the patch notes show the devs repeatedly tuning projectile speed, projectile arc, spread, projectile size, knockback, explosion radius, hitboxes/collision volumes, and even projectile inheritance settings, while also keeping weapons like chainguns and shotguns in the mix. (Steam Store)
So the first big takeaway is: you probably need at least one “continuous correction” weapon class. It does not have to be hitscan, but it should let players adjust over time instead of requiring one perfect lead. Other games get this through automatics, burst weapons, shotguns with anchored spread, beams, splash, or very fast projectiles. Right now your list is mostly “commit to one prediction and hope it was right.” That is exciting for a few weapons; it is exhausting as the whole sandbox.
The second big takeaway is that successful games usually tune forgiveness holistically, not by only inflating hitboxes. Overwatch 2 is a strong example: in Season 9 Blizzard increased projectile sizes globally, with larger increases for slower travel-time projectiles, and at the same time increased hero health pools by 15–25% to keep overall kill time in line while making damage feel more consistent. They also explicitly adjusted Pharah toward more horizontal movement and “brief moments of downtime” in the air. (news.blizzard.com)
That matters because it explains why “huge projectile hitboxes” alone is not fixing your feel problem. If you only enlarge the hit volume, shots can start feeling fake instead of satisfying. The games above usually change multiple variables together: projectile speed, projectile size, spread pattern, splash radius, hitbox volume, target health, movement commitment, and engagement range. Tribes’ patch notes are almost a perfect case study in that: they do not just nudge one number, they retune the entire contact model. (Steam Store)
A third pattern is aim truth. TF2’s hitscan page is very explicit that hitscan attacks fire down the crosshair from the attacker’s eye level, not literally from wherever the viewmodel seems to be. That is an important design lesson even if your game stays projectile-only: the player’s mental model has to be “what the crosshair says is what the shot means.” If the visual projectile, camera aim, server hit validation, and actual origin/direction are even slightly disagreeing, players describe that as exactly what you said: whiffs that should hit and hits that feel unexplained. (Team Fortress Wiki)
And on Roblox specifically, that technical layer is very real. Roblox’s server-authority docs say fast-paced experiences rely on client prediction plus latency compensation, and Roblox now exposes a Misprediction event specifically to inspect where predicted and authoritative state diverge. So I would treat your current problem as potentially two separate failures at once: a design problem where every weapon asks for hard travel-time prediction, and a netcode/simulation problem where client and server may not fully agree about what happened. (Creator Hub)
What I would do for Mayhem, without betraying your direction, is this:
First, keep projectile-only if you want, but stop making almost every weapon a single-shot prediction test. Your Pistol is the obvious candidate to become the sandbox’s stabilizer. I would try one of these:
very fast low-damage projectile with a high fire rate,
a 3-round burst with fast projectiles,
a nailgun/SMG-like stream that is still projectile-based but easy to correct with.
That gives players a way to track and confirm, not just predict.
Second, I would change the Double-Barrel if its pellets are true slow-ish projectiles. That is one of the worst possible combinations for airborne combat feel. The most promising fixes are:
a fixed spread pattern rather than random spread,
an anchored center pellet or center slug so the shot has a stable core,
much faster pellet speed at short range,
or repositioning it as a very close-range movement/finisher tool rather than a general neutral weapon.
TF2’s shotgun design is a useful reference here: it keeps a pellet straight down the crosshair and can use fixed spread. (Team Fortress Wiki)
Third, I would keep Rocket Launcher as one of the hard-prediction weapons, because that fantasy is already honest: slow travel, readable path, splash, movement utility. In games like TF2, that kind of weapon works because it is not the only way players are allowed to solve combat. (Team Fortress Wiki)
Fourth, I would make your roster taxonomy more explicit:
Initiators: Rocket Launcher, Double-Barrel
Manipulators: Umbrella
Converters / punishers: Bat, Pan
Stabilizers / trackers: Pistol, and probably one future automatic or burst projectile weapon
Anti-air / denial: future flak, net, wide burst, or tug tool
That structure fits your weapon-first philosophy much better than making every slot try to do everything.
Fifth, I would audit three technical things before touching balance again:
crosshair truth — does the projectile actually go where the crosshair implies?
inheritance — while moving fast, does projectile velocity inherit enough of player momentum to feel intuitive? Tribes explicitly tunes this. (Steam Store)
client/server disagreement — are the visible projectile, authoritative hit, and feedback all describing the same event? Roblox’s prediction/misprediction tooling exists because this is a common fast-game failure mode. (Creator Hub)
So my blunt answer is: yes, all-projectile is probably part of the issue — but not because projectiles are bad. It is because your current roster seems to be making every weapon behave like a high-commitment prediction weapon, which means there is no reliable “correction” layer to make fights feel earned over time. The fix is probably not “add abilities” and probably not “make everything hitscan.” It is more likely:
keep a few expressive predictive weapons,
add one or two projectile weapons that let players correct continuously,
make spread and projectile behavior more deterministic,
and verify that the technical hit story is truthful.
The single highest-value prototype would be: leave movement alone, keep Rocket Launcher/Umbrella/Bat as-is, but turn Pistol into a fast-correcting projectile weapon and make Double-Barrel deterministic instead of random. That will tell you very quickly whether the core issue is “all-projectile” or “all-projectile with no stabilizer layer.”

The strongest direction is to make base movement about momentum maintenance, correction, and routing, not about giving every player a bunch of extra escape verbs. Your notes already point there: preserve launch velocity, keep air control soft, allow wall interaction, avoid a universal dash/slide, and let the main mobility spikes come from weapons/items.
So for a Roblox FPS sitting between TF2 and Smash, I would make base movement stronger in these ways:
1. Make running and jumping feel “momentum-honest”
The player should feel like speed is a thing they own, not something the game constantly deletes.
Use:
fast acceleration to a moderate top speed
strong jump buffering and coyote time
preserve most horizontal velocity on jump
only gradually bleed speed on landing, not instantly
That gives you a continuous shooter feel without adding more buttons. It also makes rocket jumps, shotgun jumps, umbrella redirects, and knockback plays feel like extensions of the same physics language instead of separate minigames.
One very specific call: do not require holding W to “keep” momentum. Momentum should persist by default. Requiring a movement key to not lose speed feels gamey and adds unnecessary parse load.
2. Use soft air steer, not strong air control
You do not want Quake-style full air authority if your combat fantasy is readable projectile prediction. But zero air influence feels dead.
A good middle ground:
let players bend their trajectory a little
let them preserve or slightly reshape a launch
do not let them sharply reverse, zigzag, or nullify prediction
Think of it as:
weapons create the big path
the player can massage that path a bit
That matches your “item-driven mobility with light player-side influence” stance very well.
3. Prefer wall skim / wall-run lite over a full parkour system
Walls are the biggest thing that can kill flow in a momentum shooter. So base movement should solve walls elegantly.
I would make wall interaction:
speed-gated
angle-gated
brief
readable
Best version:
if you hit a wall at a shallow angle with enough speed, you can “skim” or short wall-run
it preserves some forward motion
it slightly stabilizes your path
jumping off gives a consistent kick away from the wall
That is much better than a universal dash because it is contextual, map-readable, and route-oriented. It helps movement continue, but it does not become an all-purpose duel bailout.
4. Add landing drift, not a generic slide
You likely want some grounded follow-through after airtime, but not a big flashy slide button that takes over fights.
So instead of “press key to slide,” use:
a brief low-friction drift after fast landings
limited turning during that drift
no invulnerability / no burst acceleration
This does three useful things:
makes landings feel good
keeps momentum chains alive
gives players a small recovery window after launch tools
It stays supportive rather than dominant.
5. Make low obstacles and ledges less sticky
A momentum game dies when the player loses a chain to tiny geometry.
So use:
forgiving step-up on small lips
auto-vault / ledge pop for low obstacles
late edge-jump grace
consistent slope handling
This is not “exciting” on paper, but it massively improves the feel ceiling. A lot of “good movement” is really just not getting robbed by the map.
6. Let players shoot during almost all base movement states
Because your core challenge is “shooting a moving enemy while you are moving,” base movement should almost never hard-lock combat.
That means:
wall-run should still allow aiming/firing
vaults should be quick and minimally cinematic
landing drift should not lock the gun
movement states should change handling, not remove agency
If movement disables fighting too often, the game becomes “movement phase, then combat phase,” which weakens the fantasy.
7. Make the base kit solve only three problems
To avoid overload, every base movement action should answer one of these:
Maintain speed — run/jump/landing drift
Correct path — soft air steer / wall skim
Handle geometry — ledge hop / low vault
That is enough.
Do not let base movement also handle:
burst escape
extreme vertical gain
major displacement
target denial
Those should stay with the weapons.
That is the cleanest split:
base movement = continuity
weapons = spikes, tricks, swing moments
8. Use feedback to make movement feel stronger without adding complexity
A lot of “engaging movement” is presentation, not mechanics. Your notes are right to stress responsiveness, camera, SFX/VFX, and indicators.
For this style of game, the highest-value feedback is:
landing thump when preserving speed
wall-scrape audio on a valid skim
small camera tilt on hard lateral movement
subtle speed lines only above key thresholds
clean crosshair/reticle behavior while airborne
quick invalid-action cues when a move condition is not met
These increase satisfaction without increasing mental load.

What I would not add to base movement
Given your goals, I would avoid:
universal dash
universal slide as a free neutral reset
bhop as a dominant optimization layer
multiple cooldown-gated parkour abilities
strong air braking / air reversing
movement states that dramatically change silhouette every second
Those all risk making combat harder to read and making weapon mobility less special. That lines up with the concerns in your convo notes and with the diagnosis doc’s warning that movement can make aiming less fun if it adds instability faster than it adds cool interactions.

A good “Mayhem base movement” package
If I were scoping one prototype, I’d do this:
Always on
sprint-speed run with satisfying accel
buffered jump + coyote time
strong horizontal velocity preservation
Air
soft air steer only
no bhop gain
no air reverse nonsense
Geometry
brief wall skim / short wall-run with strict conditions
ledge pop / forgiving vault
good slope handling
Landing
short landing drift on fast touchdowns
No
dash
free slide
extra movement buttons beyond the basics
That gives you a movement layer that feels alive and chainable, but still leaves the rocket launcher, double barrel, umbrella, bat, and other tools as the stars.

The design rule I’d keep in front of the team
Base movement should make players think:
“I can keep this sequence going.”
Weapons should make players think:
“I can turn this sequence into something crazy.”
If base movement starts creating the crazy moments by itself, it will overshadow the arsenal.
If it does not support sequences at all, the arsenal will feel disconnected and gimmicky.
The sweet spot is a base kit that creates continuous, readable flow, while weapons provide the memorable direction changes, launches, confirms, and counters.
I can turn this into a concrete movement spec next, with exact mechanics, conditions, and rough tuning values.

