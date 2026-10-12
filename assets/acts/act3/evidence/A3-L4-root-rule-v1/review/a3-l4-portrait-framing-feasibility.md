# A3-L4 proposed rule court: portrait framing feasibility

Read-only preparation, 9 October 2026, actual Shared42 dependencies. This supplements the frozen `a3-l4-rule-budget-proposal.md` (SHA256 `9edc24a52997976da3b9cde7fa4da2175d4b0281767dcb592f6faf32914a2f40`). No engine, native projection, scene, artwork, capture, admission or acceptance was produced. Coordinates below remain proposals. Root owns prototype implementation and focused native checks.

## Concrete width constraint

Do not require both opposite long-dash landing forecasts in one frame. That particular union cannot fit the current protected portrait width. This does **not** establish that a single selected full lateral response cannot fit.

Actual Game uses an orthogonal KEEP_WIDTH Camera3D, width7.2, fixed offset(0,18,13), and world viewport270×585 (`scripts/game.gd:47,102,124`). Actual HUD horizontal insets are22×factor pixels, factor=clamp(screen_width/540,.6,2) (`scripts/hud.gd:102–117`). At logical540 width, and also339 width while the proportional factor is unclamped, protected width is nominally7.2×496/540=6.613333m. Camera planning erodes this by .055m **per world-space edge**, then .001m numerical headroom per edge: nominal available projected span6.501333m. The .055/.02 margins are meters, not normalized screen fractions. Use native getters, not these rounded literals, in a test.

Actual shared Hero full billboard is48×64 pixels at native pixel_size set from .0225, offset to its feet; nominal width1.08m and height1.44m (`scripts/pixel_sprite.gd:12–13,93–100`). The common capsule is radius.32, height1.45, centerY.73; its actual contact-shadow mesh has radius.38. Camera APIs include all three. A capsule-only fit is insufficient.

| Proposed opposite forecasts | Hero-quad horizontal span alone | Consequence under the nominal current HUD |
| --- | --- | --- |
| LandingX±2.7 | 5.4+1.08=6.48m | Only .021333m total width remains after planning reserves; native complete source/cue/target bounds are still required. |
| LandingX±2.97 | 5.94+1.08=7.02m | Exceeds the protected planning span by about .518667m; translation cannot rescue width. Even actual current-containment reserve(.02m/edge) gives only6.573333m. |

These are necessary scalar span comparisons derived from actual policy; they are not an actual Camera3D projection or native accepted response. Fixed-angle camera right is worldX in this unrolled setup. Actual float32 getters/snapped standard Hero mesh corners must replace nominal dimensions. The long-union deficit is substantially greater than mesh rounding.

The published `docs/development/CAMERA_FRAMING.md` explicitly says all remote possible responses need not be visible simultaneously. Independently preview LEFT and RIGHT, then frame the exact selected proof plus **every actual current/held required source, cue, target and Hero**. Include the complete selected escape, standing landing and ordinary return/opening forecast before admission, and refresh for the player's actual alternative movement. A single long lateral start/landing pair occupies nominal4.05m of Hero-quad width; fixed roots/crescent/tether/art may widen that. Thus selected lateral remains a legitimate native candidate. Do not label it impossible solely because the unnecessary two-alternative superunion is impossible, restrict legal swipes, omit the actual Hero or retain a stale preferred path.

## Smaller first native candidate

Keep the original proposed floor14×12, Draw lane(-1,0,1.25)→(1,0,1.25), radius.28, true Enclose crescent(origin0,bearing+Z,inner.75,outer1.65,min_dot.5), tether(1,0,0), and initial Hero planar(0,1.25). Keep the actual physics-settled feetY, same source placements, timings, input meanings and primary reach. First try the following **separate** exact response previews:

| Escape direction | Baseline full landing(X,Z) | Long full landing(X,Z) | Ordinary return direction |
| --- | --- | --- | --- |
| FORWARD (−Z) | (0,−1.45) | (0,−1.72) | BACK (+Z) |
| BACK (+Z) | (0,3.95) | (0,4.22) | FORWARD (−Z) |

The directions above describe proposed ground responses, not imposed Hero endpoints. `LaneMechanism.preview_start("hero", context, actual_tether_position, bearing)` reads the actual bound Hero; if accepted, pass its unchanged result to `start("hero", context, actual_tether_position, bearing, preview)` without yielding. The first argument is the **bound public Hero ID string**, not a Hero Node. Read the resulting native witness and use its actual timings/positions. Failure remains meaningful; never replace it with the coordinates in this note.

Geometrically, both proposed Z landings are well outside the short horizontal lane's radius and the crescent's outer band; FORWARD lands on the rear angular opening and BACK lands beyond its outer edge. They cross the warning footprint before active, then return only through the actual supported recovery schedule. The full landing capsule is nominally inside the permanent floorZ±6 even at4.22+.32; these simple inequalities are **not** native body-sweep, continuous-support, held-union or timing proofs. The ordinary return restores the original proposed primary point, whose fixed tether distance remains1.600781m; actual aim/LOS and the short1.8m native reach still require real input and an accepted target hit. No shortened dash, forced wait, teleport, floor change or idle-hit shortcut is proposed.

This transfers travel into portrait height while preserving physical geometry. At the nominal fixed basis, groundZ projects onto camera-up with magnitude18/sqrt(493)≈.810679. Even the unnecessary pair of opposite long landing Hero quads spans nominal5.94×.810679+1.44≈6.255435m vertically, before other art/cue/body bounds. As an illustrative baseline only, logical540×1170 HUD with minimum45px objective, hidden telemetry and desktop controls leaves nominal11.141333m after planning reserves. **Actual wrapped objective/HUD height, native source/cue elevations, target art, depth and correction distance remain unmeasured**; this comparison does not license a future/current fit. Each selected Z path needs the actual complete union and current camera guard just like lateral.

Canonical Enclose asks for two broad open approaches, not specifically two full±X dashes. Keep both angular sides of the genuine shallow crescent visibly open. The forward/back responses are a small rule test, not proof that the later authored court communicates those two approaches. If actual portraits obscure that distinction, separately test symmetric rear diagonals through the left/right openings, using real normalized native directions and inverse returns; do not silently change the crescent, distance or camera. That is a subsequent candidate, not an accepted substitute here.

## Required native framing and limits

1. Build the actual compact source art/root ends, same fixed low target and actual meshes first. Obtain complete current and prospective native render corners, full cue stroke/fill/source-glyph AABBs and lane endcaps/crescent arcs. Hero forecast bounds must derive from its actual full native billboard/capsule/shadow, not guessed radii or opaque pixels. The B05 source/target art does not yet exist, so no complete all-source bound can be certified statically. The distant non-target likeness is scenic; do not invent damage entitlement or conceal required local source art inside an optional-background exclusion.
2. Respect the level hook's224-point limit and leaf256 maximum including automatic current Hero bounds. Existing Root Latcher `framing_points` combines130 crescent boundary points, body8, stroke/fill16, source glyph8, fixed point1, art/shadow24:187 points for its ordinary64-segment crescent. Naively concatenating that with multiple full B05 raw boundary arrays and historical Hero corners can exceed the limit. If needed, enclose **complete actual native groups** in conservative8-corner world AABBs as existing owned consumers do; do not drop arc/end/art corners or replace geometry with a body proxy. Check actual final point count and group custody before planning.
3. Let actual Game/Shell ordinary processing update the real HUD then apply `camera_framing_plan` to the level hook. `_update_camera` retains .16s normal follow and applies only an accepted boundedX/Z proposal; width, basis, focusY and swipe/tap anchor stay fixed. A plan can shift at most3.6m. A returned future focus is not the current camera: require `camera_framing_error` empty at admission/lock/active/recovery and the existing mechanism `set_presentation_guard` at the actual damage boundary. Hold/cancel with an honest visible reason when current presentation is unavailable. Do not privately set focus or pre-authorize damage on an accepted plan.
4. Run the smallest native Standard baseline first: Draw and Enclose separately, one actual full FORWARD escape/inverse return/ordinary primary, then BACK. Record exact public preview/witness, native current framing state, actual HUD-safe rect, camera dimensions/basis/position, complete required points/count and real action/source/Scheduler snapshots. Only then repeat short/slow/long and Assisted relevant cases; no full-route gate. Compare actual selected LEFT/RIGHT afterward if preserving the original lateral recipe is preferable. No numerical tolerance or existing mechanical assertion needs relaxation.
5. Brief real warning/locked/landing/recovery portraits must show both Draw roots or both Enclose arcs/open sides, full Hero, safe landing and reachable low tether together without required scenery occlusion. For phase2, repeat actual full held union with the existing removable C51, Sun preview and surviving/dead art. Current Root Latcher has no explicit native candidate-Camera/current-dead-art framing overload yet; the earlier L4 API note accurately records that owned integration requirement. A phase1 result cannot establish phase2 simultaneous framing.

Candidate restore must use actual restored Hero, native candidate Camera and actual laid-out canonical HUD via the published explicit-context APIs after quiet physical restoration, then independent live capture/current guard. No adapter alias, saved-pose projection, fake focus, source translation, zoom, crop, force_draw or synthetic pixel proof is proposed. Actual projection containment still does not prove visibility through scenery, contrast, cue readability or human recognition.

## Inspected actual pins (SHA256)

| Path | SHA256 |
| --- | --- |
| `scripts/game.gd` | `0b16d911409350a392f741a07bc163ad73c588d885ee7e1e64b951f97aa30d26` |
| `scripts/hud.gd` | `3a76c06a97da117b2fbd43824d88f3ef5150e6ad0045b5e27766b8d70542897b` |
| `scripts/presentation/camera_framing.gd` | `daf839d1e35497c88a59d4c1c2af7bb02194418e2c667aceb677242bd642c39b` |
| `scripts/pixel_sprite.gd` | `69a1846a55d251b1e8b44764b429546b814f97aba18379c7ee06b3267938747a` |
| `scripts/player.gd` | `8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743` |
| `scripts/combat/lane_mechanism.gd` | `873b1728019b40b229f2b7778a970cc5c8fa0001d50800cf50f2cdd50f502253` |
| `scripts/combat/threat_geometry.gd` | `c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09` |
| `scripts/cues/cue_mesh.gd` | `d63f5dfabbdae2dbd055e24013b0d822bca47ba71a457e1ab0d874e0ef22929d` |
| `scripts/acts/act3/root_latcher.gd` | `a809efbb34810077536fa48dc863620546ecb47c4179c31490230b526eb3011b` |
| `scripts/acts/act3/root_latcher_art.gd` | `09a05dfb267e47ef431af0fa5b0e96eaeb038fae46740030892000bb0e59391f` |
| `docs/development/CAMERA_FRAMING.md` | `c91094a1f519097212384f9605e264a0f1ec17f63de046294bb6994ef0fbaea4` |
| `docs/ACT3_CONCEPT.md` | `ea048ef41f956e425eec4400ac668368f577a4cba5c8f31d486811c8ab754bdd` |

No live runtime/source/earlier ignored draft changed. No new ability/equipment/reward, native acceptance, frame-rate or current portrait-readability claim follows.
