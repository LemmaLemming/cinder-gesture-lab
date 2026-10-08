# Cinder difficulty design plan

**Status: proposed design, 8 October 2026.** Build difficulty through increasingly demanding encounter decisions and optional Assisted, Standard and Challenge settings. All preset values below are unplaytested starting points. Saving this plan does not implement difficulty settings or establish campaign balance.

The repeated decision stays **read a committed threat → swipe to a useful landing → aim a primary attack → choose whether to add the blast → read the next threat**. Players should improve on repeated attempts with the same equipment and statistics.

## Scope and shared rules

The [game concept](GAME_CONCEPT.md) owns confirmed controls and campaign direction. The [equipment guidelines](PLAYER_EQUIPMENT_GUIDELINES.md) and [design data](../data/design/player_equipment.json) own player statistics, permitted loadouts and abilities. The [style and motion guidelines](GAME_STYLE_GUIDELINES.md) own warning readability and timing requirements. This plan adds proposed encounter and difficulty settings within those constraints.

- Keep one shared player controller and base-stat definition across acts and difficulties. Preserve swipe-only ground movement, deliberate dash starts/stops, one buffered dash and exact aiming from the last swipe's final screen-space release point.
- The first tap immediately attempts the primary attack. A nearby second tap within the existing 280 ms window attempts one blast. Keep the recognizer, camera, collision body and input response consistent across presets.
- Every required encounter works with ordinary dashes and primary attacks, without a pickup or blast ammunition. Every permitted loadout retains an escape and attack opportunity.
- Preserve warning → lock → active → recovery. Show the attack source, footprint and a reachable safe landing together in the actual portrait camera. Commitment stops tracking; animations follow the action's timing.
- Keep baseline player power and equipment budgets consistent across acts. Difficulty selection does not grant permanent stat growth or require equipment farming.
- Reuse existing enemy, environment and effect families. Optional challenges primarily rearrange their parent kit, following the [asset reuse guide](ASSET_REUSE_GUIDE.md).

## Campaign difficulty curve

Author encounters around the skill they test, using the existing [Act 1](ACT1_CONCEPT.md), [Act 2](ACT2_CONCEPT.md) and [Act 3](ACT3_CONCEPT.md) designs. This sequence describes a learning rhythm; it is not a requirement to add five waves to every room.

| Stage | Encounter structure | Player skill |
| --- | --- | --- |
| Learn | One enemy or rule, generous landing space and a clear recovery opening | Recognise commitment, evade and punish |
| Apply | The familiar threat in another arrangement | Choose a landing that also sets up an attack |
| Combine | Two previously introduced roles or rules | Choose the first target and preserve a retreat |
| Pressure | A familiar crowd or hazard changes useful approaches | Manage space and commit at the right moment |
| Breathe | A checkpoint or quieter encounter | Recognise progress and prepare for the next challenge |

Increase pressure through enemy mixtures, approach angles, positioning and the ordering of known threats. Keep readable reaction and recovery windows. Act number alone does not justify faster attacks, greater enemy health or stronger player equipment.

The proposed Mushroom Caverns sequence is an example: learn swarm spacing, learn how hittable mushroom clusters repel living enemies, then decide when to spend a cluster while a spear guard pressures the approach. Spores create room; they do not damage the enemies. These are existing campaign proposals, not implemented lab encounters or new ability allocations.

## Proposed difficulty presets

Use Standard as the reference experience. Initially keep enemy health, attack footprints, approach speed and player statistics consistent across presets, so enemy identity and positioning remain learnable.

| Setting | Assisted | Standard | Challenge |
| --- | --- | --- | --- |
| Enemy raw damage | 0.70 × reference | 1.00 × reference | 1.00 × reference initially |
| Total pre-hit windup | 1.35 × reference | Validated reference timing | Same validated reference timing |
| Stationary recovery opening | Longer than reference | Validated reference timing | Same validated reference timing |
| Preparing attackers | Usually one; first test caps at one | Up to two, staggered | Up to two, coordinated and staggered |
| Encounter arrangement | Generous approaches and simple mixtures | Mixed roles and meaningful landing choices | More demanding target priority and positioning |

Assisted's damage multiplier applies once to the enemy's raw damage, before the existing armour calculation. It is an encounter setting, separate from equipment armour and its caps. Any future damaging environment uses the same assistance policy. The table does not introduce a hidden damage category.

Windup includes warning and lock. Resolve it as the greater of the role's windup multiplied by the preset and the validated minimum for that attack. Preserve a visibly locked phase and validate its duration; the multiplier is not permission to shorten that phase. The current lab commits direction at warning start, and longer preparation must preserve that commitment. Longer Assisted recovery must create a usable close-range opening. Challenge increases pressure through authored arrangements while retaining the validated timing floors and safe-space requirements. Coordinated threats must leave a feasible response to their combined footprints.

For the lab's first comparison, current timings can serve as the provisional reference. Human playtests must establish the final Standard values, including recognition time, remaining dash cooldown and escape travel for the slowest permitted loadout. Recovery must allow a useful positioning dash when needed and an ordinary primary attack with the shortest permitted reach and slowest recovery.

Allow selection from a paused menu and apply a changed preset when a fresh encounter begins. Keep the current encounter's profile fixed until retry or completion. In the lab, resetting or selecting an exercise is the corresponding fresh boundary. Save the preference with future campaign persistence, preserve campaign access and progress across presets, and use the same planned encounter/boss-phase checkpoint frequency for all three.

## Current lab and implementation plan

As observed on 8 October 2026, the [Character Lab](CHARACTER_LAB.md) provides safe targets, a one-enemy duel and a three-enemy arena. It has static equipment, paused comparison, explicit exercise resets, committed enemy warnings and visible stationary recovery. Difficulty presets, campaign checkpoints and saved difficulty preferences are unimplemented.

The current [enemy controller](../scripts/enemy.gd) caps enemies in warning/lock at two through `MAX_PREPARING_ATTACKERS`. Active attacks do not count toward that limit, and the cap does not validate combined footprints or safe landings. A preparation cap alone does not establish a fair attack schedule.

Implement in this order:

1. **Add a shared attack scheduler.** Enemies request permission to prepare. Track preparing and active threats, stagger commitments, and evaluate their combined footprints and feasible escape timing before accepting another threat. Use authoritative logical threat shapes and timing; the current [footprint helper](../scripts/attack_footprint.gd) builds visual geometry and does not provide a safe-path API. Reserve space and time through activation; release a reservation when an attack ends or is cancelled. Waiting enemies may approach visibly, while preserving usable movement space.
2. **Add one shared difficulty resource.** Store stable preset IDs, raw-damage and windup multipliers, recovery settings and attack-budget limits separately from equipment. Keep enemy-role base values in one place and resolve each multiplier once from those values. Reapplying a profile must not compound previous multipliers. A proposed destination is `data/design/difficulty_profiles.json`; it does not exist as part of this plan.
3. **Apply the profile at fresh boundaries.** Pass the selected profile from [game.gd](../scripts/game.gd) into enemy configuration and the scheduler. Keep the resolved profile fixed for the encounter. Use explicit per-preset encounter arrangements for authored campaign rooms.
4. **Add the paused selection and persistence.** Consume menu/resume taps before combat input. Freeze scheduling, warning, active and recovery clocks with the existing pause behaviour. Store the preference when campaign save support exists.
5. **Validate the arena before extending the campaign.** Use the bounded playtest below, then apply the same timing and safe-space checks to required fights and bosses. Reuse existing warnings, effects and enemy families.

God of War's combat designers describe a shared aggression-token pool, adjustable by difficulty, to control how many enemies become aggressive. That supports the scheduler approach; Cinder's budgets and timing values remain original proposals. See [Evolving God of War's Combat for a New Perspective, GDC 2019, slides 38–43](https://media.gdcvault.com/gdc2019/presentations/Sheth_Mihir_EvolvingCombat.pdf).

## First arena playtest

Use one short room in the actual portrait view with the existing grunt, hopper and armoured arena roles. These are lab roles, not finished campaign enemies. First teach each role alone, then compare one grunt, a grunt plus hopper, and all three roles in the same room. Keep the loadout fixed between attempts and introduce no pickups or new assets.

Compare the presets on the same encounter before changing its arrangement. Begin with one preparing attacker, then test two staggered attackers where the profile allows it. Keep enemy health and role statistics constant except for the explicitly selected damage, windup and recovery settings.

| Hypothesis | Evidence to observe |
| --- | --- |
| Players learn commitment rather than guessing | They deliberately leave the marked footprint and return during recovery |
| Mixed roles create useful target choices | Players change target order or landing based on the next threat |
| Assisted creates more time and forgiveness | Fewer timing failures while players still aim and choose landings |
| Challenge tests mastery with identical player stats | Experienced players solve tighter combinations through positioning and priority |
| Repeat attempts show learning | Players explain a mistake and change their next approach without acquiring stronger gear |

Record the reason for each hit or failure: missed warning, poor landing, wrong target priority, misunderstood gesture or an unavoidable combination. Observe accepted inputs separately from positioning errors. Record attempts, damage taken and clear time as context; completion alone does not show mastery. Repair unclear cues or impossible combinations before increasing pressure.

Before calling the implementation ready, verify fixed dash travel and exact aim across presets, immediate first-tap primary/one second-tap blast behaviour, coherent pause/retry state, scheduler reservation cleanup, unchanged enemy hit counts and ordinary-primary completion. Test the least favourable permitted loadouts with empty blast ammunition. Check warnings, active footprints and safe landings under finger occlusion, muted audio and the supported portrait framing. Desktop simulation and real mobile-device validation must be reported separately.

Future conditional-perk or temporary-powerup placements still follow the [ability usage workflow](ABILITY_USAGE_WORKFLOW.md). This plan allocates none and does not establish new ability identities.
