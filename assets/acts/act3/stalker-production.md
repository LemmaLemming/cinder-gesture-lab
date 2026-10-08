# Sunbound Stalker — first Branchspell art source

Generated 8 October 2026 with the built-in `image_gen` tool in default mode and `transparent_background: true`. One generation, one source and one pose. The native PNG was copied byte-for-byte; no CLI fallback, resizing, cropping, raster editing, alpha rewriting or fabricated sprite atlas.

- Asset ID: `A3-E1-ART-BRANCHSPELL-01`; enemy catalogue identity remains `C50` / `A3-E1`.
- File: `assets/acts/act3/sunbound-stalker-branchspell.png`.
- Generation output: `/Users/howardchen/.codex/generated_images/01a11ae1-e453-7f40-bb05-cd7373153a0f/exec-840ba9b0-26d2-4664-85d5-8256ad720cdf.png`.
- SHA-256: `4b26a05de4d86848bb8d1d40d6567097bcc85f9b083d07c2ded110ac5836dcaa`.
- Native dimensions/mode: 1254 × 1254, RGBA; alpha range 0–255.
- Raw nonzero-alpha bounds: `[0, 54, 1228, 1254]` (right/bottom exclusive). Faint peripheral alpha is present.
- Visible silhouette bounds at alpha >=128: `[128, 244, 1141, 1051]`, approximately 1013 × 807 native pixels.
- Alpha counts: 1,219,263 fully transparent; 931 fully opaque; 352,322 partial. Of the partial pixels, 305,857 have alpha 192–254. Original alpha is preserved.
- Proposed feet pivot: `(635, 1051)` source texels, normalized approximately `(0.506, 0.838)`, a central baseline beneath the lowest visible planted foot. This is a proposed billboard placement pivot, not a verified actor collision/body centre. The actual camera view must establish floor contact. Proposed full-source Sprite3D offset if using that pivot: `(-8, 424)`; integration/owner decides the eventual scale and placement.
- Intended presentation: one three-quarter lower-right-facing braced idle/preparation pose. Glassy violet organic angular plates, hunched tapered head, four bent limbs with separated feet, dark head-side ridge/crest, one near pale ivory/lime low flank join.
- Readiness: native still candidate imported and reviewed by root in a noninteractive art harness at actual 339×736 portrait. Chosen candidate scale is 1.35 visible world-unit height, `pixel_size=1.35/807`, using offset `(-8,424)`. Collision clearance, moving/lateral contact, muted contrast and combat source/footprint/landing coexistence remain pending. Apparent source-grid size was a prompt target, not a measured pixel-perfect authored grid.
- Rendering candidate: nearest filtering, depth test and `ALPHA_CUT_DISCARD` at a tested threshold around 0.5. This could reject faint peripheral alpha without rewriting the PNG; no material or runtime implementation was added by this asset task.
- Collision role: no collider or damage shape is part of the PNG. The existing/shared enemy body and authoritative moving-lunge adapter must define collision, lane, reach, timings and damage. Visible head/limb length does not extend the hitbox.
- Reuse family: `A3-SUNBOUND-STALKER`; same `C50`/`A3-E1` role across A3-L1 and later documented main/optional placements. No new equipment, player ability, enemy role or boss.

## Source and adaptation record

Viewed the actual selected local boards before generation:

- `G12`, `docs/concept-art/act3/bosses/03-candidates-and-threats.png`, bottom-left invented regular threat study: glassy violet hide, long lowered head, angular living limbs and low reachable seam. Unselected candidate bosses and other threat families are separate references.
- `G18`, `docs/concept-art/act3/gameplay/01-twin-suns-gameplay.png`: angular dark/violet source over scarlet floor, restrained pale/lime anatomy detail and the close portrait 2.5D composition. Its drawn straight line is the written committed lunge lane, not a laser mechanic.

The generated compact crouch, plate arrangement and crest interpretation are original game-art adaptation. This creature is invented for Cinder, not a named person/species authenticated in Lindsay’s novel. The image contains no floor lane, ray, weapon, background, text, equipment marker or contact cue. The pale/lime flank join depicts anatomy only; it does not independently promise vulnerability or damage acceptance. The real vulnerability state remains owned by gameplay and its shared cues.

Consulted Act 3 concept/art README/adaptation notes, shared style/motion/reuse guides and the equipment guidelines/numerical data. Registered owner branch: `codex/campaign-act3`; reviewed baseline `ff34f58e1c29f44b17958f59107e19c99cc91d86`, shared API publication `campaign-shared-1`.

## Pose/frame coverage and explicit limits

This source covers one braced pose. A separate [recovery candidate](stalker-recovery-production.md) now exists at the same family pixel scale. There are no complete warning/lock/lunge/hurt/defeated/opposite-facing sequences, measured holds or Alppain crest variant. The back plate ridge is pronounced; actual portrait review finds crest/seam details small. Do not claim full state or facing coverage from these two stills, or substitute a tint for the specified two distinct crest shapes.

Supported sun-state presentation and any additional pose/facing production remain later work. This file is independent of the moving-lunge adapter. Art frame count must never choose tracking cutoff, lock duration, lunge travel, damage interval, recovery or vulnerability. No hit damage, motion, contact damage, knockback or stats can be inferred from the image.

Root's queued `stalker_art_capture.gd` run in `.cinder/stalker-art-recovery.log` saved three still-art studies, exit 0 and no script/resource errors. The 1.1-world-unit candidate was too small; 1.35 retains the angular violet body/facing and a visible lowering into recovery. The low seam is still a tiny pale fleck, and the independent contact disk needs moving/lateral review. No living source, damage receiver or timed attack was added.

Before acceptance, inspect both relevant sun presentations beside the selected shared player and full source/lane/safe-landing exchange. Verify muted/grayscale contrast, moving feet contact, crest facing, ordinary-primary reach and warning contrast. The asset helper ran no engine jobs; root performed the subsequent art study. Still inspection cannot establish human reaction time, balance or gameplay correctness.

## Exact generation prompt

```text
Use case: stylized-concept.
Asset type: ONE original transparent pixel game enemy cutout, Sunbound Stalker for Cinder Act 3 Twin Suns, initial Branchspell presentation source.
Primary request: one compact low asymmetric alien creature, hunched and braced on four long bent angular limbs with separately readable planted feet. A hunched narrow torso of violet glassy overlapping organic plates, a lowered tapered head, and one short dark crest aimed toward the lower-right side make its facing readable. The nearest low flank has one restrained pale ivory and muted lime seam, located near the feet, with no surrounding glow. The seam is a physical plate join, not a symbol or equipment marker. Preserve the G12 threat idea: violet glassy hide, short committed-lunge creature, reachable low seam. Do not turn it into a humanoid, machine, boss or laser emitter.
Scene/backdrop: genuinely transparent alpha, no backdrop, ground plane, contact shadow or environment.
Style/medium: crisp deliberate pixel 2.5D sprite, broad dark/value clusters, stepped edges, restrained angular specular facets, no smooth 3D render or painterly brush detail. Apparent coarse source sprite about 80 pixels high, enlarged with nearest-neighbor; compact readable detail suitable for a close low-resolution portrait camera. Black-purple core, violet/lavender plate facets, one small low ivory/lime seam. Glassy means a few angular highlights, not transparent see-through limbs.
Composition/framing: exactly one whole isolated creature centered in a square canvas with at least 10 percent clear transparent margin at every side; all feet fully visible. Orthographic fixed-angle overhead 2.5D view looking down about 45 degrees, showing hunched upper back, nearer flank and planted limbs. Three-quarter facing lower-right. Width slightly greater than height. Clearly separated bent limbs and dark negative-space gaps, low body with a short directional crest; no tall antlers or huge vertical horns. Feet share one stable floor plane, central foot-pivot around x50 percent/y85 percent of the canvas.
Pose: ONE quiet braced idle/preparation illustration. No actual movement, no implied projectile or active attack. Angular living creature, familiar threat outline against scarlet/violet floor, distinct from trees, rock spines, roots and harmless reflections.
Constraints: transparent background, one object and one pose only. No text, labels, board layout, grid, frame, watermark, weapon, clothing, equipment cue, pickup, health bar, target marker, ground lane, laser, ray, warning shape, arrows, motion trail, contact glow or extra variants. No new mechanics or attack timing are encoded by this image.
```
