# Cinder Character Lab

**Implemented prototype, 8 October 2026.** This is the first shared player, starter equipment and bounded test area in Godot. It is separate from the campaign levels. The static clothing and weapon profiles below are playable; conditional perks, temporary powerups, campaign encounters, campaign checkpoints and disk persistence remain unimplemented. The numerical values remain provisional tuning, not established human balance.

The lab follows the [campaign concept](GAME_CONCEPT.md), [shared style and motion](GAME_STYLE_GUIDELINES.md), [equipment specification](PLAYER_EQUIPMENT_GUIDELINES.md), [canonical numerical data](../data/design/player_equipment.json) and [asset reuse guide](ASSET_REUSE_GUIDE.md). The same controller and base-stat definition are intended for all three acts.

## Start and controls

Open [project.godot](../project.godot) in Godot 4.7.2 and press Play, or use `Play.command` on this Mac. The first exercise has three calm practice targets on continuous ground. The view is 540 × 1170 portrait, with a nearest-filtered 270 × 585 3D viewport and a close fixed-angle orthographic camera of width 7.2 world units. Camera translation follows with a 0.16-second exponential time constant: fast when farther behind, slowing as it settles. Dash movement can briefly lead the camera; reset snaps it to the fresh player. The camera angle, width and aiming anchor remain fixed.

- **Swipe:** one any-angle ground dash. Diagonal travel is normalized. One subsequent swipe can be buffered during the start-to-start cooldown.
- **Tap:** immediately attempt a slash. Aim from the latest swipe's **final screen-space finger-release point** toward the tap. For example, release upper-left and tap near the centre to attack down-right. The player's position and camera follow do not move this anchor. Before the first swipe or after an exercise reset, the anchor is screen centre; a tap exactly on it retains facing.
- **Nearby second tap:** attempt one blast within 280 ms and strictly less than 90 virtual pixels from the first tap. The first slash has already happened. An empty-shell follow-up creates no attack and does not become another slash. A swipe clears tap pairing.
- **LOADOUT:** open the paused comparison screen. **RESUME** is at the top. UI taps are consumed before combat processing, and closing the screen clears any previous tap pairing.
- **RESET**, **TARGETS**, **ONE ENEMY** or **THREE ENEMIES:** begin a fresh exercise. This explicitly restores full HP and two shells, clears cooldowns/transient effects, restores targets and finite pickup supplies, and keeps the equipped IDs. This is a lab reset, not a campaign checkpoint/save implementation.

On desktop, mouse drag is a swipe and click is a tap. Voluntary movement remains swipe-only. In the safe target exercise, the small anchor cue helps explain the actual aiming origin. A screen-edge release can prevent an outward tap; an ordinary positioning swipe establishes a more useful anchor.

Opening LOADOUT, losing application focus or backgrounding pauses the scene tree. Player/enemy movement, action deadlines, reload, pickup state clocks and physical effects freeze together. Return remains paused until RESUME. Clothing comparison/equip is available when no live enemies remain; pausing an active encounter alone does not create a safe equipment boundary. The exercise buttons provide a clear way back to Targets.

## Starter and first catalogue

The shared starter is **CLOTH-J0 Standard Jacket, CLOTH-P0 Standard Pants, CLOTH-S0 Standard Shoes and WEAPON-01 Balanced Edge**. Clothing occupies exactly jacket, pants and shoes. Armour is a damage statistic. One weapon profile supplies both blade and short barrel-blast actions.

| Starter statistic | Resolved value |
| --- | ---: |
| HP / armour divisor | 100 / 1.0 |
| Slash damage / reach / cooldown | 20 HP / 2.0 units / 0.30 s |
| Blast damage / reach / cooldown | 42 HP / 3.1 units / 0.45 s |
| Shells / automatic reload | 2 / 1.15 s per shell |
| Successful living-enemy primary reload credit | 0.45 s once per action |
| Dash speed / distance / duration | 15 units/s / 2.7 units / 0.18 s |
| Dash cooldown / invulnerability | 0.34 s from start / 0.12 s |
| Hurt invulnerability | 0.80 s |

All nine static clothing presets and all four weapon profiles are accessible for testing without unlock grinding. The three perk-bearing clothing entries, all 14 perk definitions and all six powerups remain catalogue proposals. No campaign ability introduction is allocated by this lab.

| Slot | Implemented IDs | Benefit and cost relative to standard |
| --- | --- | --- |
| Jacket | CLOTH-J0 Standard; CLOTH-J1 Padded; CLOTH-J2 Duelist | Standard is neutral. Padded adds 0.20 armour divisor and subtracts 0.05 attack-speed delta. Duelist adds 0.10 damage and subtracts 0.10 max-health delta. |
| Pants | CLOTH-P0 Standard; CLOTH-P1 Reach; CLOTH-P2 Cargo | Standard is neutral. Reach adds 0.05 reach and subtracts 0.05 attack-speed delta. Cargo adds 0.10 max health and subtracts 0.05 dash-speed delta. |
| Shoes | CLOTH-S0 Standard; CLOTH-S1 Burst; CLOTH-S2 Longstep | Standard is neutral. Burst adds 0.10 dash speed and subtracts 0.05 damage delta. Longstep adds 0.10 dash distance and subtracts 0.05 dash-speed delta. |

The weapon values below use otherwise standard clothing. Shared damage, speed and reach deltas affect both actions; shells and reload rules stay the same.

| Profile | Slash / blast damage | Slash / blast cooldown | Slash / blast reach |
| --- | ---: | ---: | ---: |
| WEAPON-01 Balanced Edge | 20 / 42 HP | 0.300 / 0.450 s | 2.00 / 3.10 units |
| WEAPON-02 Quick Edge | 17 / 35.7 HP | 0.261 / 0.391 s | 1.90 / 2.945 units |
| WEAPON-03 Heavy Edge | 24 / 50.4 HP | 0.375 / 0.563 s | 1.80 / 2.79 units |
| WEAPON-04 Long Edge | 19 / 39.9 HP | 0.333 / 0.500 s | 2.20 / 3.41 units |

LOADOUT previews resolved before/after damage, cooldowns, reach, dash speed/distance, max HP, actual damage reduction, armour divisor, capped bonuses and HP discarded on equip. Raising maximum HP does not heal; lowering it clamps current HP to the new capacity. Armour divides incoming damage: Padded's 1.20 divisor receives 16⅔ HP damage from a raw 20-HP hit. Float values are retained internally. Attack cooldown is not measured practical DPS; the unchanged double-tap grammar still constrains rapid primary-only taps.

## Exercises and finite pickups

**Targets** supplies three stationary, nonhostile practice props with visible HP and cleared states. They accept ordinary slash/blast hits and give action feedback. They are outside the enemy group, award no reload credit or core, and have no blocking body collision. RESET recreates them.

**One Enemy** uses one existing grunt. **Three Enemies** uses the existing grunt, armoured and hopper arena roles. These retain their prototype art and numerical variants; they are not implemented campaign Selenites, Martian machines or Tormance creatures. At most two enemies prepare attacks simultaneously. A cone outline and six countdown marks show the actual reach/dot footprint, the direction stays committed, a brief filled impact appears, then a pale marker and stationary 0.60-second recovery provide an opening. That recovery is an unplaytested lab tuning proposal. Core contact collection still increments a counter only.

Three marked stands in each exercise offer Quick, Heavy and Long Edge by contact within 0.70 ground-plane units. Each stand is available once, then shows TAKEN. Contact queues the newest weapon if a dash or held attack phase is still resolving; replacement commits when that phase finishes, before any remaining cooldown expires. Replacement preserves current shells, elapsed reload progress and running cooldown deadlines. Re-entering a taken stand does not equip again. Reset restores the stands; the lab does not spawn the discarded weapon or provide unlimited replenishment during one exercise.

Only accepted, nonzero direct damage to a living enemy earns base reload credit, once for the whole primary action. Credit is not stored while shells are full; it can complete at most one shell and discards the excess. Props and rejected damage overlaps do not earn that reward. Player attacks use exact facing, range/cone checks and scenery line of sight. A short floor outline now depicts their resolved reach/cone, with occluded sections opened at cover; the slash arc and muzzle burst remain decorative feedback. Dash speed/distance and attack values are snapshotted when their action begins. Enemy strikes also reject scenery-blocked hits; their warning and active ground footprints snapshot the same layer-1 scenery rays when windup begins, preserving their existing reach, damage and phase timings.

## Runtime assets and reuse records

The lab's new visuals are original Cinder code-authored shapes and pixel clusters. Full-frame concept boards supply reference vocabulary rather than cropped runtime assets. Every record here remains **implemented lab prototype**, with campaign production, human readability and device performance still to verify.

| Stable asset / family | Source, native scale and pivot | Collision / occlusion role | States, timing and reuse |
| --- | --- | --- | --- |
| PLAYER-ASTRONOMER-W01–W04 / shared_astronomer_player | [player.tscn](../scenes/player.tscn), [pixel_sprite.gd](../scripts/pixel_sprite.gd), four 1536 × 384 atlases with 48 × 64 cells; 0.0225 units/source pixel, foot pivot (24, 64), 0.025-unit foot clearance. [Manifest](../assets/characters/manifest.json) records provenance and outfit reviews. | Same capsule radius 0.32 / height 1.45 and 1.08 × 1.44 world quad; billboard has world depth and floor shadow. Apparel does not change collision. | Permanent helmet; four artwork facings, six to eight frames/state. Idle 1.2 s, dash resolved duration, cosmetic landing 0.22 s, primary 0.28 / attack speed, blast 0.24 / attack speed, hurt 0.28 s. Longer settling never extends logical action deadlines. |
| LAB-ARENA-01 / shared_mechanics_lab | [lab_arena.tscn](../scenes/lab_arena.tscn); authored 3D primitives, native pixel grid not applicable, root at world floor origin. Floor 24 × 16 units; two 2.2 × 1.3 × 2.2 obstacles; 2.7-unit decorative dash ruler. | Floor, visible perimeter and obstacles use world collision layer 1. Neutral floor values keep the player readable; walls/obstacles have ordinary depth occlusion. | Static scenery; animation timing not applicable. One reusable test floor for Targets, One Enemy and Three Enemies. It is not a campaign environment kit. |
| LAB-TARGET-01 / shared_practice_target | [practice_target.tscn](../scenes/practice_target.tscn), [practice_target.gd](../scripts/practice_target.gd); original 3D boxes, pixel grid not applicable, root at floor contact. Base 0.9 × 0.12 × 0.8; face 0.72 × 0.70 × 0.15 units. | Attackable prop via ordinary player distance/cone/line-of-sight checks; no body collider or enemy reward. Ordinary world depth. | Available HP, 0.15-second cosmetic hit response and cleared state; reset restores 100 HP. Reuse as the safe direction/equipment test prop; campaign placements remain proposals. |
| LAB-WEAPON-STAND-01 / shared_weapon_candidate | [weapon_pickup.gd](../scripts/weapon_pickup.gd); original 3D boxes, pixel grid not applicable, floor-root pivot. Base 0.74 × 0.05 × 0.74; blade marker 0.10 × 0.66 × 0.06 units. | Nonblocking contact candidate with 0.70-unit planar collection radius; ordinary world depth. Finite instance-local supply. | Available local two-pose glint every 0.8 s, contact/pending replacement, TAKEN with blade removed. Reused for three weapon IDs in all lab exercises; reset restores availability. |
| LAB-THREAT-CONE-01 / shared_attack_footprint | [attack_footprint.gd](../scripts/attack_footprint.gd), [enemy.gd](../scripts/enemy.gd) and [effects.gd](../scripts/effects.gd); procedural floor mesh, pixel grid not applicable, action-source pivot. Enemy radius 2.0/dot 0.55; player radius/dot come from each action snapshot; shared 0.1-unit source disk and 0.045-unit edge width. | Feedback has no collider. Player outlines and committed enemy warning/active meshes use layer-1, 0.7-unit-high scenery rays matching ground-target hit checks; blocked arc sections stay open. Ordinary world depth. | Enemy warning, fixed final lock, shrinking pips, 0.12-second active feedback and 0.60-second recovery marker. Existing 0.55 / 0.80 / 0.42 s windups remain variant data. Player outlines fade over their action-pose duration. The helper is reusable lab geometry; campaign cue polish and authored enemy animation remain future work. |
| FX-SMOKE-CURL / shared_curling_smoke | [curling_smoke.gd](../scripts/curling_smoke.gd) and [effects.gd](../scripts/effects.gd); original procedural 80 × 32 cells, 16 frames, three grey bands, 0.045 units/source pixel across the trail; source texel (3, 16), attached 0.08 units above the player root and 0.12 behind dash direction. Long-axis scale follows actual projected dash travel. The user's smoke image informs shape, without image cropping. | Decorative, no collider or damage; normal depth, render priority -3. One connected node per accepted dash; physics samples actual travel and latches collision-shortened landings. Later movement cannot lengthen an old plume. | Attached source, connected growth, rolling curl, breakup and fade over 0.80 s. After landing, buoyant drift is 0.18 units/s up and 0.10 along the flow. Pause freezes clocks; shares the 48-transient cap. Same family for future acts. |
| FX-SLASH-ARC / shared_primary_sweep | [effects.gd](../scripts/effects.gd); restored original eight 0.28 × 0.07 × 0.10-unit box segments at radius 0.78, angles −1.1 through +1.1 radians; pivot at accepted slash source. Native raster grid not applicable. | Decorative, no collider or damage; ordinary world depth. The separate resolved range/cone/LOS footprint remains authoritative. | Original pale arc rotates 0.32 radians and expands/shrinks over a slower 0.28 s. One arc, no slash smoke. Pause-aware and bounded; shared primary attack reuse. |
| FX-SHOTGUN-FLARE / shared_shotgun_flare | [shotgun_flare.gd](../scripts/shotgun_flare.gd), [pixel_sprite.gd](../scripts/pixel_sprite.gd); original procedural 36 × 24 cells, 10 frames, 0.03 units/source pixel; source texel (2, 12) attaches at the actual rendered barrel-tip texel centre. White core, pale yellow/gold/orange fan and five short outward streaks. | Decorative, no projectile, collider or delayed damage; nearest filtered, ordinary depth, render priority 5 and 0.006-unit camera-normal offset. Exact accepted aim is continuously projected, independent of the four artwork facings. | Immediate barrel release, expanding fan, outward streaks and fade over 0.24 s. Holds a bright core for 0.048 s; follows barrel recoil for the first 0.04 s, then freezes the source. Pause-aware and bounded; shared blast across profiles and acts. |
| FX-TINY-BLOOD / shared_impact_flecks | [effects.gd](../scripts/effects.gd); original dark-red square primitives, 0.025–0.045 world units each, root at impact. Native raster grid not applicable. | Decorative, no collider, damage or physical explosion; ordinary depth. | Three flecks on hurt, five on defeat; short drift/fall/shrink over 0.40 s. Global cap 24 inside the shared transient budget. General scenery debris keeps its existing independent physics. |

The player sheets show neutral clothing; the runtime rebuilds compatible clothing layers from equipped IDs around one permanent helmet. [Character assets](CHARACTER_ASSETS.md) records its native grid, separate cosmetic clocks and original generated visual model; the [effect manifest](../assets/effects/manifest.json) records the dash, slash and blast contracts. The new detail follows the user's astronaut reference, while the earlier hat boards remain historical references. Campaign enemy animation, scenery integration and foreground fade remain future work.

To inspect or adapt the Godot setup, open [player.tscn](../scenes/player.tscn) for the shared body/sprite, [lab_arena.tscn](../scenes/lab_arena.tscn) for editable floor/cover/ruler geometry, and [main.tscn](../scenes/main.tscn) for exported exercise mode, player start, target positions and weapon-stand positions. Stat changes belong in the canonical equipment JSON and its validator, rather than an act-specific player copy.

## Validation and limits

From the repository root, use the local engine:

```sh
./.tools/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
./.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/mechanics_smoke.gd
./.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/equipment_smoke.gd
./.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/character_lab_smoke.gd
./.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/visual_effects_smoke.gd
python3 scripts/design/validate_equipment.py
python3 scripts/design/ability_usage.py validate
```

Verified runs passed **78/78 mechanics checks, 50/50 equipment checks, 39/39 character-lab integration checks and 102/102 visual-effects checks**. The mechanics suite covers confirmed gestures, portrait framing, camera follow, collision, combat, reload and debris. Equipment checks cover static numerical resolution and budgets. Character-lab integration checks cover real player damage, safe clothing replacement, snapshotted dashes, queued weapon replacement, accepted-hit rewards, pause and consumed resume UI input. Visual checks cover one connected actual-path plume for eight dash directions, collision-shortened landings, slow-render physics ownership, buffered-dash latching, restored arc timing, exact barrel attachment, continuous flare aim, immediate unchanged damage/ammo, pause, bounds, cleanup and tiny-blood limits. Both Python design validators passed. The numerical equipment validator also screens proposed perk/power combinations, but does not implement or playtest them. The ability ledger records campaign introductions; this separate lab does not create one.

Actual 540 × 1170 Godot portrait captures inspect helmet/front/side/back artwork, feet contact, dash lead ahead of the camera and readable floor footprints beside smoke. `--fixed-fps 30 -- --capture-polish` records 120 rendered frames (four seconds) of real player physics and effects: one dash, the restored slower slash and right/left barrel-origin shots in the quiet Targets exercise. It also saves separate dash/arc/flare stills. These are engine frames rather than an interpolated mockup. Automated results and rendered Mac checks establish bounded prototype behaviour. They do not establish newcomer comprehension, full campaign completion, worst-loadout encounter fairness, physical-phone gesture cadence, low-brightness/finger-occlusion readability, iOS/Android packaging, or mobile performance. Campaign save/resume, boss phases, temporary-effect lifetime and perk state need their own implementation and tests.
