# Sunbound Stalker — Alppain braced art candidate

Generated 8 October 2026 with built-in `image_gen` in default edit mode, with the existing Branchspell PNG as the sole `referenced_image_paths` edit target and `transparent_background: true`. One edit, one candidate, one still pose. The selected native PNG is copied byte-for-byte; no raster editing, resizing, cropping, alpha rewrite, atlas fabrication or CLI fallback.

- Asset ID: `A3-E1-ART-ALPPAIN-01`.
- Enemy remains `C50` / `A3-E1`; reuse family remains `A3-SUNBOUND-STALKER`. This is an art configuration of the existing crest, not a new enemy, organ, equipment type or ability variant.
- File: `assets/acts/act3/sunbound-stalker-alppain.png`.
- Exact edit target: [Branchspell source](sunbound-stalker-branchspell.png), SHA-256 `4b26a05de4d86848bb8d1d40d6567097bcc85f9b083d07c2ded110ac5836dcaa`. Its [production record](stalker-production.md) preserves the original provenance.
- Generation output: `/Users/howardchen/.codex/generated_images/01a11ae1-57cb-79d2-8e89-eb9c0e75834b/exec-78d80f27-4287-4bc6-b3b7-98618435f926.png`.
- SHA-256: `fc78c4b4c7513185e8f1628f72a267503a38de441b8f279790ff006c4b670249`.
- Native dimensions/mode: 1254 × 1254, RGBA, alpha range 0–255.
- Raw nonzero-alpha bounds: `[17, 20, 1186, 1214]`; faint peripheral alpha persists.
- Visible bounds at alpha >=128: `[128, 282, 1142, 1051]`, 1014 × 769 native pixels, right/bottom exclusive.
- Alpha counts: 1,235,929 fully transparent; 1,197 fully opaque; 335,390 partial, including 299,307 at alpha 192–254. Original generated alpha is preserved.
- Feet pivot candidate: `(635,1051)`, normalized approximately `(0.506,0.838)`; full-source Sprite3D offset `(-8,424)`. This matches preparation's lowest visible baseline. It is art placement data, not an authoritative collision/body centre or verified floor contact.
- Common family pixel scale: `1.35 / 807 ≈ 0.001673` world units per source pixel. At that scale this candidate's visible height is approximately `1.286` world units, due to its lower upper contour; do not independently renormalize it to 1.35 visible height.
- Facing/pose: one braced preparation still, overhead three-quarter lower-right facing. No alternate facing, recovery, active-lunge, hurt or defeat sequence.
- Rendering exercised by the later root-owned still study: nearest filtering, ordinary world depth, alpha-discard threshold 0.5 and sprite floor lift 0.025 world units. The asset helper authored no import/material, script consumer, runtime enemy state or collision; root subsequently imported the PNG and used it in the decorative study described below.
- Readiness: native inspection plus root-owned static GPU study at actual 339 × 736, now beside the verified shared act3_traveller. Exact crest-only pixel invariance is not achieved; the fork reads as a small head notch and the low seam remains tiny. Shape-coded sun teaching, moving contact, both-sun contrast and held physical recovery readability remain unverified. Retained as a candidate, not accepted.

## Semantic boundary and contour choice

The [Act 3 concept](../../../docs/ACT3_CONCEPT.md#three-regular-enemy-roles) requires two crest silhouettes that identify the sun state and easier flank; it does not prescribe exact contours or a left/right mapping. Root selected a broad short fork for Alppain as a routine original game-art contour choice. This is not novel canon. [C50's research record](../../../docs/reference-library/act3/research/entities.json) preserves the same recovery hitbox under both suns. The easier approach must not become an exclusive attack side, armour key or permission to attack only in one state.

This source does not define flank mapping, lock geometry, timing, tracking, movement, damage or vulnerability. The physical source and shared cue/adapter determine warning → lock → active → recovery. The bright line in G18 remains a committed lunge lane, not a laser. White shadows remain scenery.

## Native visual inspection and drift

Actually opened the existing Branchspell cutout before editing, then inspected the returned native output. The candidate retains the same recognizable violet/black-purple angular organism, four bent limbs, separated clawed feet, lower-right tapered-head direction, near ivory/muted-lime seam and braced stance. The head-side crest is reshaped into a broader pair of violet plate prongs with a pronounced open notch, providing a clear native contour contrast with the original pointed ridge. No additional creature, floor, contact shadow, background, text, equipment, attack footprint or glow outline is present.

The generative edit is not pixel-identical outside the intended crest region. In particular, the upper dorsal plate contour also shortens: visible top changes from source y244 to y282, while the lowest visible feet baseline remains y1051. Overall visible width changes by one native pixel, 1013 to 1014. Some native facet pixels were redrawn. Thus body identity and stance are visually consistent, but this candidate must not be described as an exact crest-only patch or a finished registered animation frame. No corrective raster processing was used.

## Root-owned static GPU study — 8 October 2026

Root queued `python3 scripts/dev/dev.py engine --path . --script res://tests/acts/act3/stalker_art_capture.gd` after importing the new candidate. Root reports exit 0; [the saved log](../../../.cinder/stalker-art-shared3-alppain.log) ends with “Stalker art scale study: complete” and contains no script/resource errors. The run used Godot 4.7.2, Apple M3/OpenGL Compatibility, at adopted shared-3 HEAD `7faea752a785f2d0d941be7e67654aba99f49ae4`.

The helper actually opened these updated images and verified each saved header is 339 × 736:

- [07 — Branchspell braced, 1.35 world-unit source height](../../../captures/act3/twin-suns/07-stalker-art-scale-135.png).
- [09 — settled recovery, unchanged family pixel scale](../../../captures/act3/twin-suns/09-stalker-art-recovery.png).
- [13 — Alppain fork candidate, unchanged family pixel scale](../../../captures/act3/twin-suns/13-stalker-art-alppain.png).

[The root-owned harness](../../../tests/acts/act3/stalker_art_capture.gd) explicitly checks actual `hero.presentation_id == "act3_traveller"` and ray-checks the authored safe floor. Its decorative study sits 2.3 world units ahead of the player, uses `1.35/807` world units per native pixel, preparation/Alppain offset `(-8,424)` and recovery offset `(-8,433)`, and retains the separate contact disk radius 0.34. It creates no target group, collider, damage receiver, enemy/cue phase or runtime Stalker in either level. Four stills including the smaller 06 scale comparison were produced; this review covers 07/09/13.

### Portrait observations and limits

The selected traveller now visibly has short uncovered dark hair, ivory split coat and separate black boots. In these images the braced Stalker's projected height is slightly below the standing human's, while its spread is much wider. This is a screen-space observation with the study source 2.3 world units ahead; it is not a measurement equating the player's visible body with the 1.44-world-unit maximum quad.

The Stalker family, lower-right facing, broad foot spread and baseline remain consistent through the still changes. Recovery clearly lowers the top of the body with nearly unchanged width. Alppain's fork is visible only as a small head-side notch at this scale; it does not yet read as a strong independent whole-silhouette state shape. The slight upper-back shortening persists. The pale/lime low seam remains a tiny detail in all three views. Native crest contrast therefore does not establish reliable sun-state recognition, a readable useful flank or a held opening in gameplay. Do not claim shape-coded sun teaching or accepted recovery visibility from this study.

No neon fringe is apparent in these static portraits under the exercised cutout material. The small contact disk is restrained, but its dark centre still appears below the sprite's central body; moving/lateral floor contact and pivot alignment remain pending. The harness swaps artwork, not an authoritative source through warning/lock/lunge/recovery. In particular, 13 names the Alppain crest asset but does not explicitly switch the scenic sun clock to Alppain; these captures do not establish both-light-state contrast or a sun transition. No source/footprint/safe-landing composition, moving lunge, recovery duration, ordinary-primary reach, legal-loadout combat, pause/retry or human reading test is supplied here.

## Owner comparison before acceptance

Compare this source and Branchspell using the same family pixel scale, pivot, contact disk and actual [shared Act 3 traveller](../../characters/presentations/manifest.json). The shared player's 1.44-world-unit value is its maximum sprite quad, not measured visible human height.

At actual portrait scale, inspect whether the fork's notch remains a broad readable silhouette distinction rather than collapsing into two microglints; check grayscale/muted contrast, head-to-lane direction, retained four-limb gaps and ordinary-primary opening. Inspect moving feet/contact and pose swaps, not only a still. Crest art must not silently change the authoritative source collider or recovery hitbox, and it must remain separate from available/attack/contact cue symbols.

No Alppain recovery pose or full state/facing family exists in this file. A later accepted mapping must preserve ordinary slash recovery in both states and communicate the useful approach without adding an exclusive weak point. Art frame count cannot change tracking cutoff, lock, lunge travel, active damage or recovery duration.

Registered checkout/branch: `codex/campaign-act3`; reviewed HEAD `7faea752a785f2d0d941be7e67654aba99f49ae4` after adopted `campaign-shared-3` publication. The initial asset subtask created only this new PNG and production record. This subsequent helper evidence update changes only this record and runs affected link/hash checks; it changes no PNG, engine/import job, script, scene consumer, test, ledger, other source record or commit. Root-owned import and GPU execution are separately attributed above.

## Exact edit prompt

```text
Use case: precise-object-edit.
Asset type: ONE transparent pixel 2.5D game-enemy cutout, Cinder Act 3 Sunbound Stalker C50 / A3-E1, Alppain braced presentation candidate.
Input image: supplied sunbound-stalker-branchspell.png is the exact EDIT TARGET and identity reference.
Primary request: change ONLY the HEAD CREST from its existing narrow pointed configuration into a BROAD, SHORT SPLIT/FORK silhouette. Keep the existing creature and braced pose otherwise unchanged.
Crest edit: reshape the existing directional head crest/ridge at the lowered head toward the lower-right into two short substantial angular prongs, separated by one clear open V/U-shaped notch. The new crest must read as a broad short fork at a total creature height of about 50–60 screen pixels, visibly different in silhouette from the original narrow point. It remains the SAME physical crest in a different configuration, not an added horn, antenna, organ, crown or equipment. Keep it violet/black-purple with restrained flat lavender planes, without glow. Preserve the long lowered head and its facing; do not replace the creature's dorsal/back plates.
Invariants: preserve exact body family, violet/lavender/black-purple palette, pale ivory/muted-lime low flank seam, angular organic plate arrangement outside the small crest edit, all FOUR bent limbs, every clawed foot, limb gaps, original braced preparation stance, overhead orthographic three-quarter lower-right facing, apparent pixel scale and object placement. Preserve the square 1254-style canvas composition and approximate lowest visible feet baseline at y1051/1254 (84 percent), with central feet pivot around x635/1254. Preserve whole organism, all feet and transparent margins.
Style: retain the edit target's crisp stepped pixel contours, broad flat violet facets and glassy organic plate material. No smooth shaded 3D, painterly texture, additional microglints or a new decorative outline.
Scene/backdrop: genuinely transparent alpha background, preserve transparency. No ground, floor, contact shadow, scenery, geometry, environment or backdrop.
Constraints: exactly ONE whole creature and ONE braced pose, no duplicate, atlas, opposite-facing pose, recovery pose, action motion, beam, laser, projectile, warning lane, attack footprint, target gem, weapon, equipment, pickup, UI, labels, text, frame or watermark. This is root-authored game-art contour choice rather than novel canon. It defines no extra enemy/type, hitbox change, exclusive weak point, ability, damage, timing or mechanic. Change only the existing head crest; preserve everything else.
```
