# Main character and equipment design guidelines

The same protagonist uses the same core mechanics in all three acts and always wears a round astronaut-like helmet. All worn equipment must visually belong with that helmet. Jackets, pants, shoes, one carried weapon and temporary powerups change the effectiveness or conditions of existing actions. They create different tactical choices within a shared power budget. Acts change the enemies, situations and item presentation; act number never increases the character's base statistics.

**Status:** design specification with a bounded [Character Lab implementation](CHARACTER_LAB.md), 2026-10-08. The lab implements nine static clothing presets, four weapon profiles, armour, comparisons and queued weapon replacement. Perk-bearing clothing, conditional abilities, temporary powerups and campaign persistence remain proposed and unimplemented. The baseline table records the neutral playable kit. Every cap, budget, duration and bonus remains provisional tuning, not an established balanced value.

## Authority and instructions for AI use

- `REQ-*` rules express the user's requirements. `CTRL-*` preserve confirmed controls. Other rules specify the proposed design used for future implementation.
- `MUST` means a requirement of this specification. `SHOULD` means a default that may change with documented playtest evidence. `MAY` means an optional design choice.
- This file owns behavioural rules. [player_equipment.json](../data/design/player_equipment.json) owns numerical values, stable item and perk IDs, structured triggers, limits and example records. When changing a value, update JSON first and reconcile any repeated value here in the same change.
- [Equipment balance research](research/EQUIPMENT_BALANCE_RESEARCH.md) owns source evidence. Its `SRC-*` findings motivate rules; none supplies Cinder's tuning numbers.
- If these files disagree, an AI MUST report and resolve the disagreement before implementation. It MUST NOT silently invent a missing mechanic, change confirmed gestures or treat a proposal as implemented gameplay.
- IDs MUST remain stable when names or art change. A new mechanical variant receives a new ID. Formula strings in JSON are documentation, never code to execute with `eval`.
- Earlier statements about fixed baseline damage mean unchanged underlying statistics and no farmed permanent stat growth. Equipment modifiers are permitted by the user's newer requirement. This specification resolves earlier unspecified pickup duration and stacking questions.
- The permanent helmet and compatible clothing are confirmed appearance requirements. Older protagonist hat references are superseded. The Character Lab now implements the shared round helmet and compatible layered clothing; [the character asset record](CHARACTER_ASSETS.md) distinguishes its authored runtime cells from concept references and records remaining review limits.
- [Ability usage workflow](ABILITY_USAGE_WORKFLOW.md) governs campaign introductions, reservations and meaningful variants. Check and reserve an unused mechanical identity before placing an ability. Numeric tuning, names and art do not create novelty. Carried equipment and shared core actions remain available without another introduction.

The user confirmed that `3x combo` means three landed primary actions with a modest finisher, and that equipped clothing and weapon carry between acts within the same power budget. Triple total damage is a different, substantially stronger mechanic and is outside this specification.

## Character requirements across three acts

| Rule ID | Required behaviour |
| --- | --- |
| REQ-01 | Use one character controller, action vocabulary and base-stat definition in Acts 1, 2 and 3. |
| REQ-02 | Support exactly three clothing slots: jacket, pants and shoes. Armour is a statistic contributed by equipment, not a fourth clothing slot. |
| REQ-03 | Clothing and weapon pickups MAY change attack speed, reach, dash speed, dash distance, maximum health, damage and armour, and MAY supply bounded conditional abilities. |
| REQ-04 | Temporary powerups MAY differ by act. Equippable items remain within the same budgets across all acts; later availability is not a larger stat tier. |
| REQ-05 | Keep one carried weapon profile. Picking up another replaces it; there is no weapon-switching hotbar. |
| REQ-06 | Write new items with explicit triggers, units, scope, caps, durations, costs, stacking and reset rules. |
| REQ-07 | Carry equipped clothing and weapon across acts. Three-hit combo means three landed primary actions with a modest third-hit reward. |
| REQ-08 | The protagonist MUST wear a round astronaut-like helmet at all times, across all three acts, equipment combinations, facing directions, animation states and depictions in menus or cutscenes. Clothing and effects MUST NOT replace it with a hat, expose an unhelmeted head or transform it into different headgear. |
| REQ-09 | All equipment worn by the protagonist MUST visually suit the helmet. Jacket, pants and shoes MUST read as parts of one compatible expedition outfit, including when pieces from different acts are mixed. |
| ACT-01 | Required traversal and encounters MUST work with the standard loadout, no powerup and ordinary primary attacks. |
| ACT-02 | Every allowed equipment combination MUST retain a viable escape and attack opportunity. Test minimum legal speed and reach, slower recovery, and empty follow-up ammunition. |
| ACT-03 | Increase difficulty through readable combinations, positioning and enemy decisions. Equipment farming MUST NOT be required to advance. |

The repeated decision is **read a committed threat → swipe to a useful landing → aim a tap to punish → choose whether to add the blast → read the next threat**. Equipment MUST change the payoff or positioning choice within this loop while preserving its inputs.

## Confirmed gesture contract

| Rule ID | Input and result |
| --- | --- |
| CTRL-01 | Any-angle swipe causes one ground-plane dash. Normalize direction so diagonal travel has equal distance. Keep one buffered dash. No stick, walking, jump or new combat button is introduced. |
| CTRL-02 | The first tap immediately attempts the primary attack. The nearby second tap within 280 ms attempts the blast follow-up. It does not add a second primary attack. |
| CTRL-03 | Aim from the latest completed swipe's final finger-release position toward the tap in screen space. Before the first swipe, use screen centre. An exactly zero direction retains the last facing. Camera movement does not move this anchor. |
| CTRL-04 | Keep exact aim, collision checks and line of sight. Equipment does not redirect inputs or silently aim at targets. |
| CTRL-05 | Menu, equipment and resume taps are consumed by the active UI before combat processing. Backgrounding freezes simulation and all effect timers. |

The current recognizer accepts the second tap within 280 ms and at a distance strictly below 90 virtual pixels from the first tap. A swipe resets that tap pairing. A recognized follow-up with no ammunition produces no attack; it does not fall back to a primary. Equipment MUST NOT alter those rules.

**Attack speed constraint:** the current primary cooldown is 300 ms, close to the 280 ms double-tap window. Faster nearby taps can become blasts instead of more primary attacks. Attack speed therefore scales action cooldowns and matching animation recovery, but `damage / cooldown` is only a throughput upper bound. For consecutive primary-only nearby taps, use `max(primary_cooldown, 0.280 s + 0.020 s input margin)` as a planning estimate. Actual input scheduling, accepted attacks and hit rate MUST be measured. Do not shrink the gesture window to make a speed item appear stronger. Speed can still affect slower weapons and follow-up opportunities.

## Existing prototype baseline

Values originate in the existing prototype and are now loaded from the [canonical JSON](../data/design/player_equipment.json) by [equipment.gd](../scripts/equipment.gd), then consumed by [player.gd](../scripts/player.gd). They do not come from the research games. Armour `1.0` is the neutral incoming-damage divisor; the lab applies equipment armour while retaining float HP.

| Statistic | Baseline |
| --- | ---: |
| Maximum health | 100 HP |
| Primary damage, reach, cooldown | 20 HP; 2.0 world units; 0.30 s |
| Follow-up damage, reach, cooldown | 42 HP; 3.1 world units; 0.45 s |
| Primary and follow-up cone thresholds | Facing dot product at least 0.05 and 0.50 respectively |
| Shell capacity and reload | 2 shells; 1.15 s per shell |
| Successful primary reload credit | 0.45 s once per action, regardless of target count |
| Dash speed and distance | 15 world units/s; 2.7 world units |
| Dash duration | 0.18 s, derived from distance / speed |
| Dash cooldown | 0.34 s measured from dash start |
| Dash and damage-hit invulnerability | 0.12 s and 0.80 s respectively |
| Armour multiplier | 1.0 incoming-damage divisor |

No act multiplier, character level or permanent attack-stat upgrade enters these values. The existing core collectible is a counter, not an implemented heal, currency or buff; do not assign it one of those roles implicitly.

## Stat formulas and stacking

`delta` is an additive fraction: `0.10` means ten percentage points of the base statistic. It is not a multiplier to apply repeatedly.

```text
gear_stat = clamp(1 + sum(weapon_and_clothing_deltas), gear_min, gear_max)
total_stat_for_action = clamp(gear_stat + sum(eligible_perk_and_powerup_deltas_for_action), total_min, total_max)

primary_damage = 20 * primary_damage_multiplier
followup_damage = 42 * followup_damage_multiplier
action_cooldown = base_action_cooldown / total_attack_speed
primary_reach = 2.0 * total_attack_range
followup_reach = min(3.1 * total_attack_range, 3.8 world units)
max_health = 100 * total_max_health

dash_speed = 15 * total_dash_speed
dash_distance = 2.7 * total_dash_distance
dash_duration = dash_distance / dash_speed

armour = total_armour
received_damage = raw_damage / armour
damage_reduction_fraction = 1 - 1 / armour
effective_health = max_health * armour
```

`STAT-01`: apply each source once, sum within a statistic and clamp once at each stage. Conditional damage is an additive delta in the damage bucket, not a new multiplicative layer. Two damage deltas `+0.10` and `+0.15` yield `1.25`, not `1.265`.

Resolve damage and reach separately for each action and, where specified, each target. Shared modifiers apply to both attacks; a `primary` scope applies only to the primary. Powerup `action_modifiers` enter the same total-stage sum before its single clamp. Thus Orbit Cut's -0.20 damage delta affects the primary only, and Settled Reach never lengthens a blast.

`STAT-02`: armour is a survivability multiplier. `A = 1.25` means 20% less incoming damage; it does **not** mean 25% less damage. At 100 HP it supplies 125 effective HP. There is no separate regenerating armour bar or wear system in this design. Armour applies to enemy and environmental damage; do not introduce a hidden bypass category.

`STAT-03`: speed and distance are independent. A 20% faster dash reaches the same landing in 0.15 s. A 20% longer dash at base speed lasts 0.216 s. Collision can shorten travel; it never refunds time or supplies another dash. Cooldown remains start-to-start, and invulnerability remains an absolute 0.12 s. Require `0.12 <= dash_duration < 0.34` for every allowed combination.

`STAT-04`: range changes linear reach only. It does not enlarge the cone, bypass scenery, create a projectile or change the aim anchor. A shape-changing powerup is an explicit exception to the cone rule. Its visual footprint MUST match its collision footprint.

`STAT-05`: take snapshots when actions begin. Buff expiry during a dash does not change its destination, speed or invulnerability. An attack keeps its snapshotted reach and damage. A cooldown already started keeps its deadline. Preserve floating-point health and damage; round only UI display values.

### Provisional multiplier limits

| Statistic | Gear only | Including perks and temporary pickups |
| --- | --- | --- |
| Damage | 0.75–1.30 | 0.75–1.75 |
| Attack speed | 0.70–1.20 | 0.70–1.35 |
| Attack range | 0.85–1.15 | 0.85–1.30; blast reach also capped at 3.8 units |
| Dash speed | 0.85–1.20 | 0.85–1.35 |
| Dash distance | 1.00–1.15 | 1.00–1.35 |
| Maximum health | 0.80–1.20 | 0.80–1.30 |
| Armour divisor | 1.00–1.35 | 1.00–1.50 |

Negative dash-distance modifiers are prohibited so required normal-dash paths remain reachable. At the broadest declared stat extremes, a dash lasts approximately 0.133–0.286 s, within the cooldown and invulnerability constraints. These limits do not make every future combination acceptable: aggregate checks below still apply.

## Clothing authoring and budgets

`ITEM-01`: jackets SHOULD focus on health, armour or a damage-risk tradeoff. Pants SHOULD focus on reach, cadence or reload utility. Shoes SHOULD focus on landing speed or distance. These are readable design identities, not hard bans on other statistics.

`ITEM-02`: a clothing item has at most two nonzero static modifiers and one perk. A perk item has at most one positive static modifier. Most items SHOULD express one benefit and one relevant cost. A neutral standard item has no modifiers and no perk. Do not fill items with unrelated small bonuses.

`ITEM-03`: use this provisional authoring screen. Each positive delta costs `(delta / step) * weight`. A negative delta earns half that amount, with a maximum total drawback credit of one point per item. A perk costs two points. Net cost MUST be at most three points per clothing item.

| Statistic | Step | Points per positive step |
| --- | ---: | ---: |
| Damage | 0.05 | 1.0 |
| Attack speed | 0.05 | 1.5 |
| Reach | 0.05 | 1.5 |
| Dash speed | 0.05 | 1.0 |
| Dash distance | 0.05 | 1.5 |
| Maximum health | 0.10 | 1.0 |
| Armour divisor | 0.10 | 1.5 |

Example: `+0.20 armour / -0.05 attack speed` costs `3.0 - 0.75 = 2.25` points. `+0.10 damage / +0.10 attack speed` costs five points and is rejected. A two-point combo perk with `-0.05 damage` costs 1.5 points.

`ITEM-04`: a penalty clamped away or irrelevant to the intended playstyle MUST NOT earn drawback credit. Recheck this within builds. Low-health risk also weakens when high armour makes staying injured safe. Budget scores are an authoring screen; neither equal scores nor a passed check proves equal gameplay value.

`ITEM-05`: use fixed, named presets for the first catalogue. Every act and rarity uses the same budget. Rarity MAY express a more specific trigger, unusual visual, or distinct tactical choice; it does not grant extra stat points. Set bonuses and random affix rolling remain outside this first design.

### Example clothing presets

| ID | Item | Benefit | Cost or condition |
| --- | --- | --- | --- |
| CLOTH-J1 | Padded Jacket | +0.20 armour | -0.05 attack speed |
| CLOTH-J2 | Duelist Jacket | +0.10 damage | -0.10 maximum health |
| CLOTH-J3 | Frayed Jacket | Last Thread | -0.10 maximum health; requires injury |
| CLOTH-P1 | Reach Pants | +0.05 reach | -0.05 attack speed |
| CLOTH-P2 | Cargo Pants | +0.10 maximum health | -0.05 dash speed |
| CLOTH-P3 | Cadence Pants | Triple Cadence | -0.05 damage; maintain landed actions |
| CLOTH-S1 | Burst Shoes | +0.10 dash speed | -0.05 damage |
| CLOTH-S2 | Longstep Shoes | +0.10 dash distance | -0.05 dash speed; longer commitment |
| CLOTH-S3 | Armoured Stride Shoes | +0.05 armour and Armoured Stride | -0.10 maximum health; needs armour investment |

Each slot also has a neutral standard item, `CLOTH-J0`, `CLOTH-P0` or `CLOTH-S0`. These examples are numerical templates; final act-specific art and names may differ while meeting the appearance rules below.

### Permanent helmet and compatible equipment appearance

`LOOK-01`: the round helmet is a permanent part of the shared character appearance, outside the three replaceable clothing slots. It is not a helmet pickup, additional equipment slot or independent source of armour/stat bonuses. Its presence does not introduce oxygen, pressure, helmet damage or removal mechanics.

`LOOK-02`: preserve a recognisable round shell and readable front/back/side cues at actual portrait gameplay scale. Default: use a visor opening, rim and small highlight to communicate facing. Jackets, hoods, shoulder padding and weapon poses MUST preserve the helmet silhouette and facing cues. Dash, attack, hurt and any future defeat poses keep it on.

`LOOK-03`: every standard, alternative and perk-bearing clothing asset MUST satisfy `REQ-09`. Default: combine the game's period expedition tailoring with simple protective panels, reinforced seams and restrained metal fittings that suit the astronaut-like helmet. The clothing need not become a modern uniform spacesuit. Use a shared collar/neck connection, material treatment and seam/trim vocabulary so any legal combination reads as one outfit.

| Clothing slot | Default visual treatment around the helmet | Preserve when replacing the item |
| --- | --- | --- |
| Jacket | A collar or compact neck ring beneath the shell; coat or padded panels with compatible cuffs and fittings | Clear helmet outline, readable facing and the shared neck connection; no hat or hood covering the helmet |
| Pants | Expedition trousers with reinforced knees, panel seams or restrained utility pockets matching the jacket/helmet fittings | Compatible waist and boot connections; visible leg separation in dash/landing poses |
| Shoes | Compact expedition boots or reinforced shoes with soles, ankle cuffs and trim matching the outfit | Clear feet and floor contact; the shared foot pivot and collision body |

`LOOK-04`: act palettes, wear, fabric, trim and item-specific details MAY vary within this shared appearance. Stat tradeoffs MAY be suggested through padding, panel weight or boot shape, but their numerical effects remain owned by the equipment data. More elaborate art does not grant a larger budget. Worn weapons MUST remain readable alongside the helmet without covering its facing cues.

`LOOK-05`: before accepting an equipment asset, inspect it on the helmeted shared body in every supported facing and action pose, at gameplay scale, with standard items and mixed-act items in the other slots. Record `helmet_compatibility`, `mixed_outfit_compatibility`, `facing_readability` and `state_coverage` in its asset review. Reject an asset that removes/covers the helmet, breaks the shared outfit connections, hides facing or changes the collision body through artwork.

## Weapon pickup rules

`WPN-R01`: one carried weapon **profile** governs both the primary close attack and the existing blast follow-up. The Character Lab depicts blade and short-barrel actions as one equipped profile; campaign weapon replacement MUST replace this profile as one loadout unit. It does not create an extra weapon slot or remove the confirmed blast input. Weapon art must make the two actions understandable.

`WPN-R02`: initial weapons use the shared damage, speed and reach modifiers for both actions. They keep two shells, automatic reload and once-per-primary-hit reload credit. A later weapon-specific exception requires explicit data, a tactical reason and a new validation case.

| ID | Profile | Damage delta | Attack-speed delta | Reach delta | Intended role |
| --- | --- | ---: | ---: | ---: | --- |
| WEAPON-01 | Balanced Edge | 0 | 0 | 0 | Neutral reference |
| WEAPON-02 | Quick Edge | -0.15 | +0.15 | -0.05 | Faster recovery, weaker and closer hits |
| WEAPON-03 | Heavy Edge | +0.20 | -0.20 | -0.10 | More damage in one opening, greater commitment |
| WEAPON-04 | Long Edge | -0.05 | -0.10 | +0.10 | Slightly safer approach, weaker and slower hits |

`WPN-R03`: neutral-loadout theoretical primary DPS MUST initially remain between 0.80 and 1.05 times the reference. These examples have ratios 1.0, 0.9775, 0.96 and 0.855 respectively. Reach, burst within a short opening, stagger and practical gesture cadence need separate tests; compensating range with lower nominal DPS is a hypothesis.

`WPN-R04`: a contact pickup queues replacement until the current resolved dash or attack phase ends; it does not wait for or alter cooldown expiry. Only one replacement is pending. Preserve shell count, elapsed reload progress and outstanding cooldown deadlines. Clear the old weapon's combo/armed attack perks. Replacement does not heal, refill shells or let the player repeat an attack immediately. Re-entering a dropped weapon's footprint must not repeatedly equip it.

`WPN-R05`: primary-only completion stays possible with every profile. Do not make a weapon into a mandatory key for armour, a boss or a required traversal route. Knockback bonuses do not displace bosses or suppress repeated boss attack patterns; any boss stagger system needs its own finite vulnerability and immunity rules.

## Conditional ability catalogue

All 14 abilities below are original Cinder proposals. Their structured definitions live under `perks` in JSON. Only `PERK-01`, `PERK-02` and `PERK-03` are assigned to the initial clothing examples. Other abilities are authoring candidates, not extra passives silently granted to the character.

| ID | Ability and exact payoff | Limit and required clothing cost |
| --- | --- | --- |
| PERK-01 | **Triple Cadence:** after two landed primary actions, the third primary action gains +0.30 damage delta. | At most 1.2 s between landed actions. Reset on miss, hurt, timeout, weapon replacement or encounter end. -0.05 static damage. |
| PERK-02 | **Last Thread:** damage delta is `0.20 * clamp((0.60 - HP/max_HP) / 0.25, 0, 1)`. | Starts below 60% HP and reaches +0.20 at or below 35%. Snapshot before attacking. -0.10 max health. |
| PERK-03 | **Armoured Stride:** dash-speed delta is `min(0.12, 0.50 * (gear_armour - 1) / gear_health_multiplier)`. | Use static gear armour and maximum health, excluding temporary buffs and this perk's output. Distance unchanged. -0.10 max health. |
| PERK-04 | **Counterstep:** start a dash inside a locked threat footprint and end outside before activation without taking its hit; next primary gains +0.15 damage delta. | Ends after 1 s or next primary, even on miss; 3 s cooldown. Absorbing a hit through invulnerability does not qualify. -0.05 damage. |
| PERK-05 | **Settled Reach:** remain stationary 0.35 s after a dash; next primary gains +0.12 reach delta. | Arms once per completed dash, expires after 1 s; dash or hurt clears it. -0.05 attack speed. |
| PERK-06 | **Sweep Economy:** hit at least three distinct living enemies with one primary; add 0.20 s reload progress. | Once per action, 1.5 s cooldown; total reload credit cap 0.65 s. -0.05 damage. |
| PERK-07 | **Empty Chamber:** a primary hit started with zero shells adds 0.15 s reload progress. | 1.15 s cooldown, no instant refill; total credit cap 0.65 s. -0.05 damage. |
| PERK-08 | **Backtrack:** finish a dash within 1 s of the previous one, with direction dot product at most -0.85; next primary gains +0.12 knockback delta. | One armed attack, expires after 0.6 s; 2 s cooldown; no boss displacement. -0.05 dash speed. |
| PERK-09 | **Followthrough:** the immediate blast hits a target struck by its preceding primary; that target receives +0.10 knockback delta. | At most 0.28 s between actions; no damage bonus or boss displacement. -0.05 reach. |
| PERK-10 | **Recovery Seam:** primary hits an enemy already in explicit recovery; gain +0.10 damage delta against that target. | Once per action, 2 s cooldown. Does not create vulnerability. -0.05 damage. |
| PERK-11 | **Reserve Stitch:** an accepted enemy/environment hit crosses HP below 40% and leaves the player alive; gain +0.15 armour for future hits. | 2 s, once per encounter; no heal, refresh or protection from the triggering hit. -0.10 max health. |
| PERK-12 | **Release Valve:** a primary miss arms +0.10 speed delta on the next dash. | One dash, 0.6 s expiry, 4 s cooldown; repeated misses do not refresh it. -0.05 damage. |
| PERK-13 | **Precision Feed:** primary hits exactly one living enemy; add 0.10 s reload progress. | 0.6 s cooldown; props do not qualify; total credit cap 0.65 s. -0.05 reach. |
| PERK-14 | **First Opening:** a primary hits an enemy that has taken no prior direct player hit this encounter; gain +0.15 damage delta. | Once per enemy, once per boss phase. -0.05 attack speed. |

`PERK-01`'s ideal three-hit bonus adds 10% average base damage over the cycle, before its clothing penalty and misses. It is not three times total damage. Quick tap sequences still follow the existing primary/blast grammar; three taps are not a new special gesture.

`PERK-03`'s denominator uses **maximum** health, never current HP. Taking damage cannot make the ratio explode or secretly change dash travel distance. Armour 1.25 with max-health multiplier 0.90 reaches its +0.12 speed ceiling. Armour 1.0 grants no speed bonus.

### Shared event and proc rules

`PROC-01`: count one action, not one target or shotgun pellet. A 360-degree primary hitting eight enemies advances a combo once and earns base reload progress once. Props, corpses, harmless reflections and proc-generated hits do not advance enemy-hit perks. A lethal direct hit on an enemy alive at action start qualifies.

A successful enemy hit means accepted, nonzero direct HP damage to a target alive when the action began. Mere overlap, calling `take_damage`, an immune target or a closed weak point does not qualify. The damage interface MUST return an accepted/rejected result, HP damage, target ID and alive-before-hit state. The Character Lab now uses this result for living-enemy reload rewards; practice props do not qualify. Future conditional perks still require the pre-action snapshots and state commits below. A primary miss means an executed primary with zero accepted live-enemy damage results, even if it struck scenery.

`PROC-02`: all clothing-trigger eligibility comes from a direct player action or an explicit accepted damage event. Generated effects do not trigger any other generated effect. Repeated copies of one ability use one instance with the highest authored bonus, not additional stacks. Each equipped piece supplies at most one perk, for at most three active clothing perks.

Internal cooldowns begin at the first eligible trigger event. Compute all qualifying targets from one pre-action snapshot and apply the folded bonus to each; commit perk counters/cooldowns once after resolving the action so iteration order cannot change its result. First Opening additionally stores target-specific use markers; its boss marker resets at a new phase. Counterstep requires threat IDs and locked footprint data, with no threat collision even if invulnerability would block its damage; it cannot be inferred from a visual near miss alone.

`PROC-03`: damage bonuses for recovery, first hit or a ready combo are computed from pre-hit state and folded into that direct hit. They do not create a second damage event. The third-action combo is ready when the pre-action counter is two; a miss consumes and clears that attempted finisher. Reset after a landed finisher.

`PROC-04`: choose the highest eligible **extra** reload credit, then add the base 0.45 s, capped at 0.65 s per action. Do not sum Sweep Economy, Empty Chamber and Precision Feed. Credit earns no stored advantage when shells are full; it may complete at most one shell reload and discards excess beyond that shell's completion. Never process the same action twice after a save or resume.

Action resolution order MUST be: recognize input → validate cooldown/ammo/life state → snapshot gear, active effects, pre-action health and target states → reserve ammo, charges and cooldown deadlines → compute action/target bonuses → resolve direct hits → update combo and once-per-action credits → resolve future eligible effects without recursion → finish expiry and state commits. Invalid actions spend no resources and trigger no perk; they retain the recognizer's existing tap-pair behaviour.

New abilities MUST state what the player sees, the decision being rewarded, the triggering event, the effect's scope, and the ending condition. Do not introduce lifesteal, repeated invulnerability or automatic damage loops without a separate review of their interactions with high speed, swarms and boss recovery.

## Temporary powerup rules

`PWR-R01`: allow two active groups, **mobility** and **combat**, with one effect in each. A different pickup in the same group replaces the old effect. The same pickup resets remaining duration or charges to its initial amount; it does not add duration, strength or stacks. Predetermined finite supplies prevent farming refreshes indefinitely.

| ID | Group | Effect | Lifetime |
| --- | --- | --- | --- |
| POWER-01 Fleet Spark | Mobility | +0.15 dash speed | 12 active-simulation seconds |
| POWER-02 Long Arc | Mobility | +0.15 dash distance | 12 active-simulation seconds |
| POWER-03 Keen Spark | Combat | +0.15 damage | 10 active-simulation seconds |
| POWER-04 Quick Spark | Combat | +0.15 attack speed | 10 active-simulation seconds |
| POWER-05 Guard Spark | Combat | +0.15 armour | 10 active-simulation seconds |
| POWER-06 Orbit Cut | Combat | Replace primary cone with 360 degrees; -0.20 primary-only damage delta | Next 3 executed primaries, including misses |

`PWR-R02`: all powerups also expire at encounter end or death. Active timers freeze during pause, equipment comparison and backgrounding. Store remaining simulation duration, not a real-world expiry time. Act transition clears temporary effects. Taking a pickup never increases current HP merely because capacity increases.

`PWR-R03`: Orbit Cut changes only primary shape. It keeps reach, line of sight and exact world positioning, receives no additional targets-through-walls privilege, and does not alter the blast. A valid primary consumes a charge even when it misses; rejected inputs consume none. Crowd damage and reload rewards require dedicated tests despite per-target DPS caps.

`PWR-R04`: act themes MAY rename or reskin these profiles without altering numbers. Act 1 can emphasise Fleet Spark and Orbit Cut; Act 2 Guard and Keen Spark; Act 3 Long Arc and Quick Spark. These are suggested drop emphases, not exclusive mechanics or stronger act tiers. Required routes and enemy vulnerabilities never depend on a specific pickup.

## Replacement and persistence

`SAVE-01`: equip clothing in a paused comparison menu at a checkpoint or safe encounter boundary. Collected clothing during combat becomes a pending choice for that boundary. One pending candidate per clothing slot is enough for the first prototype. Never silently auto-equip a penalty item during a dash.

`SAVE-02`: for a living character, clothing replacement uses `new_HP = min(old_HP, new_max_HP)`. Raising capacity does not heal. Lowering capacity may discard HP above the new maximum; preview that result before equip. Replacing pieces repeatedly cannot accumulate health. Only an explicitly named heal or checkpoint heal changes current HP upward.

`SAVE-03`: gear changes clear armed conditional attack rewards and combo state. Perk cooldowns and once-per-encounter uses are encounter state indexed by perk ID, and MUST survive unequipping and re-equipping during that encounter. A swap does not restore a consumed powerup, shell, dropped-item supply or spent enemy reward.

`SAVE-04`: carry the equipped loadout between acts and levels. Keep a neutral standard loadout available at checkpoints. Optional replays may offer alternate presets and cosmetics, but no repeated permanent damage, health or armour growth. Equipment catalogue access is persistent; current equipment, HP, ammo and temporary effects belong to the attempt.

`SAVE-05`: retry restores one coherent checkpoint snapshot: equipped IDs, health, shells, elapsed reload, cooldown deadlines relative to simulation time, active powerups/charges, perk counters/cooldowns, RNG state if used, collected/drop IDs, enemies and environmental supplies. Checkpoint healing MUST be explicit and identical across retry and resume. Do not combine an old enemy state with newly refreshed loot.

## Player feedback and equipment comparisons

`UI-01`: show current/max HP, shells, each active powerup's group and remaining seconds or charges. Describe armour as actual damage reduction in the player-facing tooltip; keep the divisor available in the detailed stat view. Neither colour nor sound alone conveys an effect.

`UI-02`: an equipment comparison shows resolved before/after damage, action cooldown, reach, dash speed, dash distance, maximum health, armour and perk. Show capped values and the health discarded by an equip. Do not label attack-speed percentage as measured DPS. A weapon replacement visibly names the new profile and preserves displayed ammunition.

`UI-03`: Triple Cadence uses two progress marks and a distinct ready-finisher indicator; a miss/hurt visibly clears them. Last Thread shows its current bounded damage bonus alongside the low-health warning. Armoured Stride shows the resolved speed gain without implying a longer dash. Armed next-action perks, remaining internal cooldowns and consumed once-per-encounter effects use consistent icons.

`UI-04`: Orbit Cut previews the actual circular reach; warnings and enemy commitment silhouettes remain above decorative clothing/pickup effects. Equipment art MUST NOT alter the collision body or hide the protagonist's facing.

## Combined loadout acceptance gates

The provisional gates are safeguards for item authors, not proof of balance. Every allowed combination MUST pass them. Prefer revising an outlier over adding hidden item incompatibilities. Stat caps MUST appear in comparison UI so discarded bonuses are visible.

| Gate | Maximum or required value |
| --- | --- |
| Gear-only primary damage × rate proxy | 1.35 times reference |
| Gear with peak conditional bonuses, no temporary buff | 1.60 times reference |
| Gear, peak conditional bonuses and legal temporary buffs | 1.85 times reference |
| Primary per-hit damage | 1.75 times base, including all bonuses |
| Gear-only effective health | 140 HP, or 1.40 times reference |
| Effective health with temporary/conditional defence | 160 HP, or 1.60 times reference |
| Shortest legal primary reach | 1.7 world units |
| Shortest legal dash | 2.7 world units |
| Dash timing | Invulnerability ≤ duration < start-to-start cooldown |

Test both average output and conditional peaks. A short boss opening can favour one large hit even when sustained DPS is lower. Max-health and armour multipliers interact: 120 HP with armour 1.35 supplies 162 effective HP and fails the gear-only gate despite passing both individual stat caps.

For every new item, compare at least: one single enemy; a swarm; an ordinary enemy in recovery; a short boss opening; a minimum-range approach; a slow-dash escape; and a section with no powerup or shells. Measure accepted primary/follow-up actions, direct damage, incoming hits, successful landings, opening opportunities and reasons for failure. Separate input errors from positioning errors.

Crystalman's finite replay MUST snapshot resolved movement paths, attack shapes and relevant equipment-modified timings. A recorded 360-degree attack must have a safe, visible escape. Enemy replay does not collect pickups, heal itself or trigger the player's clothing perks. Buff expiry or a weapon swap cannot change a previewed replay footprint.

## AI authoring procedure and item template

1. Read this specification and its JSON data. State which rule and tactic the item serves.
   For level placement, read the ability ledger and reserve the mechanical identity first using the [usage workflow](ABILITY_USAGE_WORKFLOW.md). Catalogue eligibility in an act is not a record that an ability has already appeared there.
2. Choose a slot or powerup group, stable ID and bounded effect. Reuse the existing stat/trigger vocabulary.
3. Add explicit units, penalty, duration, consumption, cooldown, stacking and reset behaviour. State `not_applicable` where a field has no role.
4. Check individual budget, relevant penalty, all legal loadouts and peak simultaneous effects. Do not estimate safety solely from expected perk uptime.
5. Run the numerical validator and add a meaningful fixture for a new formula. Then test the actual gesture controller and representative encounters before promoting tuning status.
6. Update JSON, this document and any affected act encounter notes together. Keep source facts separate from original proposed rules.

```json
{
  "id": "CLOTH-P3",
  "name": "Cadence Pants",
  "kind": "clothing",
  "slot": "pants",
  "status": "proposed_unplaytested",
  "acts": [1, 2, 3],
  "modifiers": {"damage": -0.05},
  "perk_id": "PERK-01",
  "role": "maintain three landed primary actions",
  "tradeoff": "weaker opening hits; misses or damage break sequence"
}
```

The referenced perk record supplies the trigger, numerical payoff, scope, reset and cooldown fields. New records MUST reference an existing defined perk or define that perk in the same change; vague text such as “sometimes attacks faster” is invalid.

## Validation and implementation sequence

Run `python3 scripts/design/validate_equipment.py` from the repository root. It checks the numerical example catalogue and fixtures; it does not execute Godot, simulate touch timing or establish human balance. Unassigned ability candidates need additional checks when put on real items.

| Acceptance ID | Required observable result |
| --- | --- |
| TEST-01 | Identical input trace and loadout produce identical action meanings/stats in all three acts. |
| TEST-02 | At each speed tier, the first tap is immediate, the second nearby tap remains a blast, and rejected actions do not create combos or spend charges. Measure primary cadence on real mobile hardware. |
| TEST-03 | Increasing dash speed alone keeps destination distance fixed; increasing distance alone changes duration. Collisions and pause do not duplicate dashes. |
| TEST-04 | Raw damage 20 against armour 1.25 removes exactly 16 HP. Swapping from 70 HP to max HP 120 retains 70 HP. |
| TEST-05 | An eight-target primary grants one combo advance and one base reload credit. The third finisher resets; a miss/hurt breaks it. |
| TEST-06 | Weapon replacements never refill shells or shorten running deadlines. Clothing swaps cannot restore once-per-encounter effects. |
| TEST-07 | Pause/resume and retry restore coherent remaining durations, charges, supplies and item IDs; there is no duplicate loot/reward. |
| TEST-08 | All required encounters are winnable with the standard kit and with each legal loadout's worst movement/reach/recovery case, without temporary pickups or follow-up ammo. |
| TEST-09 | Low-health/armour/speed combinations do not remove threat, and bosses retain meaningful readable patterns. |
| TEST-10 | Orbit Cut and equipment-modified Crystalman replays keep attack origin, footprint and reachable escape visible in portrait view. |

Implement in bounded stages: shared stat resolver → armour and clothing comparisons → safe weapon replacement → the three assigned perks → two powerup groups → remaining perks only when their decisions test well. The Character Lab implements the first three stages for the static subset, with safe targets and existing arena enemies. The assigned perks, swarm/boss-like campaign tests and powerup stages remain future work; validate before expanding all campaign levels.

## Research principles adopted

- Explicit additive buckets and incompatible-effect groups are motivated by Supergiant's documented Hades stacking changes (`SRC-01`). [Developer patch notes](https://www.supergiantgames.com/blog/hades-the-high-speed-update-patch-notes/).
- Gear must preserve utility choices and meaningful boss patterns, reflecting GGG's discussion of multiplicative damage crowding out utility (`SRC-02`). [Developer manifesto](https://www.pathofexile.com/forum/view-thread/3147157).
- Per-hit rewards, speed, commitment and crowd control need combined checks, following GGG's attack-speed and stun analysis (`SRC-03`). [Harvest manifesto](https://www.pathofexile.com/forum/view-thread/2873295).
- Conditional synergies need deliberate setup and recovery effects need explicit lifetime, informed by Dead Cells' item and Tonic changes (`SRC-04`). [Update of Plenty](https://deadcells.com/patchnotes/19).
- Low-health rewards and combo length require finite limits, informed by Dead Cells' bounded combo and taunt designs (`SRC-05`). [Boss Rush update](https://deadcells.com/patchnotes/31).
- Defensive conversion effects require bounded investment, informed by GGG's defense/recovery proposals (`SRC-06`). [Core Defences and Recovery](https://www.pathofexile.com/forum/view-thread/3185101).

These are original applications of historical developer evidence. All Cinder-specific numbers remain tuning hypotheses until the acceptance tests support them.
