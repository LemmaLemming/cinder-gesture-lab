# A1-L4 — court art production plan

Status: proposed presentation production after the first functional component check; no court art has been implemented or tested by this plan. The level remains unaccepted. Follow [focused desktop acceptance](../../../../docs/development/LEVEL_ACCEPTANCE.md); a full playthrough is not an acceptance prerequisite.

## Evidence and immutable starting geometry

The owner-run curtain component at `88f0b405ddff944aaaa4b4b7dd4ae173710b8868` passed **152 checks / 0 failures**, with two real swipes and one ordinary primary, Hero HP100 and C32 HP24→4. Native phases, pause, unsupported-save refusal and cleanup were exercised. [Original result](../../../../docs/acts/act1/evidence/L4-curtain-component/native02/a1-l4-curtain-native-02-result.json) is preserved verbatim in the scoped portable evidence packet. The earlier native construction failure remains separate.

Portrait01 closed **46/1** after focus loss; the owner viewed its four actual 540×1170 images. Portrait02 closed **9/1** after focus loss before warning, with no captures. Preserve both [portrait01](../../../../docs/acts/act1/evidence/L4-curtain-component/portrait01/a1-l4-curtain-portrait-01-result.json) and [portrait02](../../../../docs/acts/act1/evidence/L4-curtain-component/portrait02/a1-l4-curtain-portrait-02-result.json) failures. They do not establish a complete visual pass. Do not repeat an unchanged engine run to seek a different result.

The [current wrapper](../../../../scripts/acts/act1/selenite_court_greybox.gd) and [scene](../../../../scenes/acts/act1/a1_l4_curtain_greybox.tscn) establish:

- An identity-frame floor BOX **14×1×16**, centred at **(0,-.5,0)**, with actual top **Y=0**. Preserve its collision resource, native shape registration, support settings and original `Floor/QuietFloor` mesh/material.
- World X/Z safe rectangle **[-6.5,6.5] × [-7.5,7.5]**. Spawn feet **(0,.1,0)**; single stationary C32 source **(0,0,-2)**, stable ID `court-curtain-guard`. Art does not move any of these.
- C32 art is **80×80**, `.022` units/pixel, full quad **1.76×1.76**, feet pivot **(40,80)** and centred Sprite offset **(0,40)**. Reuse the [existing guard family](../../../../assets/acts/act1/grotto/selenite_manifest.json), including its native phase/facing selection. The full spear/headpiece quad and actual capsule remain required bounds; transparent margins are not removable proof space.
- Hero bounds come from actual native `BodyCollision`, complete `ActorSprite` billboard and `ContactShadow` through [Game's framing API](../../../../scripts/game.gd). Keep actual Hero bounds at current, committed dash endpoint, proved landing and ordinary-primary position. Do not substitute a historical player-sheet size, another actor, a proxy box or a narrower opaque-pixel mask. Retain source/Cue/full lane/landing/current-view guards. Numeric fit does not prove freedom from scenery occlusion.

## Inspected source vocabulary and limits

The author personally inspected these four actual image files for this plan. No reference pixels will be extracted or traced. G19/G15/G21 are generated planning boards; F10 is a film frame, not a measured floor or animation reference. Generated captions and schematic combat diagrams do not override the [written L4 design](../../../../docs/ACT1_CONCEPT.md).

| Source | Inspected contribution | SHA-256 |
| --- | --- | --- |
| [G19 court board](../../../../docs/concept-art/act1/environments/04-selenite-court.png) | Broad linked performance spaces, curling side panels, crescent columns, quiet/bright roundel proposal and drapery modules | `cc1bccf751d8dd21c7248287f01e9b02cf1fce33da52f1982bcdc162009e629d` |
| [G15 modular kit](../../../../docs/concept-art/act1/props/lunar-grotto-and-court-modular-kit.png) | Flat-and-column silhouettes, five-point-star radial ornament, rounded gathered curtain, shared painted lunar material family | `c8b61dc9115e2ed98546c05b65ca79f34e2fe998af191e82bf2b582cf225d53e` |
| [G21 King board](../../../../docs/concept-art/act1/bosses/01-selenite-king.png) | Comic masked royal figure, pale rib bands, projecting star crown, broad robe/gestures and compact throne vocabulary | `c9fd452ab3dffc2725fb3c9952250a20e215e1e7534e7260ed89532dba95d46b` |
| [F10 court frame](../../../../docs/reference-library/act1/film-stills/f10.jpg) | Royal area at the left side, low seat, upright banded performers, oversized spearheads, radiant ornament, crescents and rounded draped opening | `2af0136f438c066455ea39d766caa3fcb0c6b68e1954e731d19014af71a28c06` |

Some board tableaux centre the royal seat. The written **compact side-mounted throne** requirement governs. Preserve [source-specific style](../../../../docs/reference-library/act1/STYLE_GUIDE.md), [adaptation limits](../../../../docs/concept-art/act1/ADAPTATION_NOTES.md) and [asset reuse](../../../../docs/ASSET_REUSE_GUIDE.md): handmade moon-white/dusty-silver/charcoal theatre, broad painted clusters and black scenic gaps; no Gothic cathedral, dense procession or new enemy faction.

## Standalone court leaf

Proposed new owned `scripts/acts/act1/selenite_court_art.gd` and `assets/acts/act1/court/environment_manifest.json` are future work. Do not call the whole fungal art builder: its retained stalk/floor template is L3-specific. Reuse its drapery, crescent and curling-panel shapes/material patterns as a small independently bound leaf.

Proposed interface: `build_geometry_art(level, immutable_court_specs) -> Node3D`, `set_exit_open(bool)`, pure `binding_error()`, and pure named `landmark_world_corners(id)`. The visible direct `CourtArt` child retains an identity transform and `PROCESS_MODE_DISABLED`; construction validates all supplied actual anchors before adding art. No timers, tweens, camera/controller/HUD, physics bodies, gameplay signals, private clocks or effects authority. Supported setters change only retained scenic state and emit nothing. Wrapper-owned native mechanisms retain roundel timing and exit conditions.

| Module | Native frame/material proposal | Collision, states and occlusion role |
| --- | --- | --- |
| Quiet floor skin | Exact **14×16 PlaneMesh** at world **Y=.002**, unit frame; existing 64×64 [silver tile](../../../../assets/acts/act1/lunar/environment/floor_silver_tile.png), SHA `927971422809f26e5492ec6701a69d7b1ced7d1e6498c7d4736542e5b8831c64`; repeat period **1.536 units**, corresponding to `.024` units/texel | Static decoration only; original floor mesh/collider stay intact. Nearest/unshaded ordinary depth; retain alpha-scissor settings and native UV readback. No warning-shaped floor pattern. |
| Curling panels and crescents | Code-authored shallow flats, coarse grayscale curves/stars, pale crescent crowns, dark panel recesses; bases pivot at local **Y=0**, unit scale | Quiet/static. Begin placement studies outside the safe rectangle. Any actual grounded blocker must be separately authored by the wrapper with an aligned visible base; art never adds an invisible collider. |
| Drapery opening | Rounded rail/frame, visible low bases, broad gathered folds; ground-centred root pivot, shared retained geometry | `BlockedDrapery` / `OpenGatheredDrapery` only. Opening must visibly preserve the broad floor approach. Contact Area and progression are wrapper-owned; no attack interaction is added. |
| Shallow radial ornament | Low-contrast five-point star with broad radial rays; floor-centred pivot, proposed surface just above the skin | Quiet/static in the entrance. Future roundel brightening must be driven by actual native hazard state/Cue, with independent full footprint bounds; decorative size never defines damage radius or timing. No new pulse clock. |
| Compact side throne | Low base, crescent/radial back and curling side silhouette; ground-base pivot, unit frame | Quiet scenery to one side of the final court. Keep its body outside required dash/recovery lanes. King movement and occupancy state belong to the future actor/wrapper. |

For first placement studies only, side panels could begin around **X=±7.2**, with roughly **.8×2.8×.12** shallow envelopes; columns can reuse the existing **.30×3.6×.24** shape vocabulary. These are **unmeasured proposals**, not approved positions or new physical geometry. Court anchors, curtain width, roundel size and throne position must be recorded after the actual layout and portrait check. Do not enlarge camera bounds, filter required actors or shrink their art to accommodate scenery.

Retain each required node/tree/transform/visibility, exact mesh arrays and AABB, material/texture identity and renderer readback. Materials use nearest sampling, ordinary depth and no next-pass/custom shader. Alpha-scissor surfaces retain threshold, antialiasing, UV, blending and depth settings. Never mutate a shared material to change another court's state. Local curtain state is independent per instance.

## Later court and King production

The same module family supports **three broad linked courts**: curtain entrance; parallel→inward formation with the **same two retained C32 identities**; royal approach/side-throne arena. Five beats remain entrance, formation, roundel approach, King alone, then King plus **one finite visibly entering helper pair**. Defeated helpers remain defeated during that attempt; no replacement waves. Phase Retry restores the coherent phase start, and King defeat opens the contact curtain.

King B01/A1-B1 derives from C21/O52–O53; do not relabel the C32 leaf as King. Future original King cells need planted feet, masked/ribbed body, comic crown silhouette and readable idle/warning/lock/lunge/recovery/summon/defeat poses, with native state controlling presentation. A possible **80×96/.022** grid, full quad **1.76×2.112** and feet pivot **(40,96)** is a scale study only, unvalidated against any future King body. Ordinary-slash reach, collision, stats and phase timings remain gameplay data. No new equipment or ability introduction is selected here.

## Directly affected validation and readiness

1. Implement the leaf after owner review, preserving the tested floor/source/Hero and shared controls. Record exact native resources, provenance, module dimensions/pivots, quiet/open states and reuse family. New art begins **authored/unexecuted**.
2. Run only affected construction/material/visibility/resource guards and native entry/one-C32 admission checks. Verify full art/Cue/lane/Hero/landing corners and unchanged ordinary-primary proof. Negative substitutions must fail closed; no resource repair or proof backfill.
3. Resolve the concrete focus/capture issue before a changed-art portrait. Use brief representative warning/active/recovery/opening and blocked/open curtain views; inspect complete heads, spear tips, feet, source/Hero separation, full warning and landing under the actual HUD. Observe partial overlap honestly. Unobstructed capture procedures must preserve public pause/GUI Resume and native focus semantics; do not suppress focus guards.
4. Later formation/roundel/King additions get their directly affected checks and brief views. Reuse unchanged L3/C32 evidence without claiming it validates these new placements. Whole-level save/Continue/Retry/transition/cleanup need real production interfaces once authored; the component's explicit save refusal remains until then. Full-playthrough, every facing, all kit/profile combinations, human balance and performance remain untested unless separately measured; they are not blanket acceptance gates.

This file is a production plan, not runtime art, a portrait pass, a complete L4 implementation or a permission request. Root retains production ownership and chooses the next bounded implementation.
