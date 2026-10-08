# Sunbound Stalker — Branchspell rear-facing braced candidate

Generated 8 October 2026 with built-in `image_gen` in default edit mode, the existing Branchspell PNG as the sole `referenced_image_paths` edit target, and `transparent_background: true`. One edit, one selected output and one braced pose. Native PNG copied byte-for-byte; no CLI fallback, raster editing, resizing, cropping, alpha rewrite or fabricated atlas.

- Asset ID: `A3-E1-ART-BRANCHSPELL-BACK-01`.
- Enemy identity remains `C50` / `A3-E1`; reuse family remains `A3-SUNBOUND-STALKER`. This is candidate directional artwork, not a new enemy, organ, equipment type, ability or mechanic.
- File: `assets/acts/act3/sunbound-stalker-branchspell-back.png`.
- Exact edit identity source: [Branchspell braced PNG](sunbound-stalker-branchspell.png), SHA-256 `4b26a05de4d86848bb8d1d40d6567097bcc85f9b083d07c2ded110ac5836dcaa`; [its production record](stalker-production.md) owns original provenance.
- Generation output: `/Users/howardchen/.codex/generated_images/01a11ae1-57cb-79d2-8e89-eb9c0e75834b/exec-cc027353-9b99-4593-99f3-59c515997e37.png`.
- SHA-256: `52b11bd57dabbf3980b831291d48f9492cd186550219d257317dc62174ca0fa1`.
- Native size/mode: 1254 × 1254, RGBA; alpha range 0–255.
- Raw nonzero-alpha bounds: `[0,21,1245,1254]`; faint peripheral alpha persists.
- Visible alpha >=128 bounds: `[233,248,1192,1082]`, 959 × 834 native pixels, right/bottom exclusive.
- Alpha counts: 1,238,248 fully transparent; 717 fully opaque; 333,551 partial, including 291,874 at alpha 192–254. Generated alpha preserved.
- Proposed per-source baseline pivot: `(713,1082)`, normalized approximately `(0.569,0.863)`; full-source Sprite3D offset `(-86,455)`. X is rounded from visible-bounds centre 712.5; Y anchors the lowest visible foot baseline. This is a provisional art alignment reference, not a measured anatomical/collision centre or verified world floor contact.
- Common family pixel scale: `1.35/807 ≈ 0.001673` world units per native pixel, retained from preparation. New visible source height 834 yields approximately `1.395` world units at that common scale. Do not renormalize each direction independently to 1.35 height.
- Intended facing: upper-right away from the camera, rear three-quarter under the same approximately 45-degree fixed overhead interpretation; narrow Branchspell crest rather than Alppain fork.
- State coverage: one still braced preparation. No warning/lock/lunge/recovery sequence, opposite rear direction, hurt or defeated pose.
- Render proposal: nearest filtering, ordinary world depth and alpha discard near 0.5, subject to owner GPU review. No import/material/script consumer or engine job is supplied by this task.
- Collision/damage: none in the PNG. Actual source collider, floor support, lane, phase timing, damage and ordinary-primary recovery opening belong to the supported shared adapter and owned encounter.
- Readiness: natively inspected generated rear-facing candidate, with placement/anatomy drift documented below. Actual portrait facing, floor contact, projected pixel density and useful-flank legibility remain unverified. Not accepted as runtime animation or completed facing coverage.

## Native inspection and observed drift

Actually opened the exact local Branchspell PNG before editing and inspected the returned native image. It retains the recognizable violet/black-purple angular plate family, four bent limbs and separated clawed feet, restrained lavender facets and an ivory/muted-lime plate join. The angular far head/crest mass lies toward the upper-right of the torso and the nearer hind leg/back-side plate dominates the lower-left foreground, suggesting the requested rear-oblique stance. It retains a narrow pointed plate treatment rather than the Alppain fork. No additional tail, limb, organ, equipment, ground, contact shadow, footprint, arrow, glow outline, UI, text or atlas is visible.

This is a generatively redrawn viewpoint, not a pixel-identical rotation or measured turnaround. The nearer side/back plate and limb articulation differ from the front source, and head/crest alignment with an actual upper-right lane must be checked in portrait rather than certified from this still. The low seam remains visible on the newly presented flank; that visibility must not create an extra vulnerable side or damage rule.

The requested source placement was approximate x635/y1051, but the output shifted: its visible-bounds centre is 712.5 versus the original 634.5, and its lowest foot baseline is y1082 versus y1051, a 31-native-pixel difference. Visible height rises from 807 to 834 and width decreases from 1013 to 959, consistent with changed presentation/foreshortening but not proven exact anatomical scale. The proposed per-source pivot compensates bounding placement only. Using the original offset unchanged would introduce horizontal/baseline displacement. Conversely, the proposed new pivot does not prove the physical body's centre or eliminate a facing-swap pop; the owner must verify it on the actual stable floor.

The entire visible organism and feet remain within the canvas. No corrective crop, resize, alpha rewrite or other raster operation was used. Original front PNG remains unchanged.

## Directional coverage proposal and gameplay boundary

The [Act 3 concept](../../../docs/ACT3_CONCEPT.md#three-regular-enemy-roles) requires head crest aligned with the locked short lane, one lunge and a low recovery opening in either sun state. A static direction source adds no tracking, lock, motion, duration or hittability.

Root's coverage proposal is existing front lower-right plus this rear upper-right source, with engine horizontal mirroring as candidate coverage of the two other directions. No mirrored raster file, bin mapping or runtime renderer implementation was created here. The exact bin mapping is not implemented or accepted. Before using a mirror, verify that apparent crest/facing and low seam remain coherent with the world-space lane and preferred flank; anatomical asymmetry cannot silently change collider or recovery hitbox. [C50's research record](../../../docs/reference-library/act3/research/entities.json) retains the same recovery hitbox under both sun states.

This file supplies neither a rear recovery nor Alppain rear pose. It cannot establish a complete two-sun four-direction family by itself. Art state/facing changes must not change authoritative travel, tracking cutoff, lock, active damage or recovery. The short line is a lunge footprint, never a laser.

## Required owner review

Compare front/rear at unchanged family pixel scale beside the actual [shared Act 3 traveller](../../characters/presentations/manifest.json); the player's 1.44-world-unit maximum quad is not its measured visible body height. Inspect upper-right direction, dark limb separation, head crest silhouette and low seam at the actual 50–60-pixel range under both sun presentations, including muted/grayscale view.

Verify the proposed baseline pivot and separate small contact disk during facing swaps and actual movement; ensure sprite-centre displacement does not move the authoritative collider or make ordinary primary reach misleading. Check any horizontal mirroring/bin boundary under the fixed camera and compare source/whole lane/safe landing together. Native inspection does not establish shape-coded sun teaching, ordinary-primary reach, human reaction time or balanced phase durations. No engine/import, portrait capture or gameplay test was run by this asset helper.

Registered branch/checkout: `codex/campaign-act3`; observed generation-time HEAD `e24ba4ed31d0c400f3f76a3b46ee585f32776f49`. This task creates only this new sibling PNG and its dedicated record. No existing PNG, other document, engine/import job, runtime code, ledger or commit changed.

## Exact edit prompt

```text
Use case: precise-object-edit.
Asset type: ONE transparent pixel 2.5D game-enemy cutout, Cinder Act 3 Sunbound Stalker C50 / A3-E1, Branchspell rear-facing braced candidate.
Input image: supplied sunbound-stalker-branchspell.png is the exact EDIT TARGET and body-identity reference.
Primary request: change ONLY the creature's view/facing to a REAR THREE-QUARTER BRACED VIEW, aiming toward the UPPER-RIGHT, away from the camera. Rotate the same organism within the same fixed overhead camera view; do not rotate the flat source image or move the camera.
View/facing: retain the approximately 45-degree fixed overhead orthographic viewpoint. Show the same creature's back and near rear flank; its lowered tapered head and existing short narrow pointed Branchspell crest are on the far upper-right side, visibly aligned toward upper-right. The nearer lower-left side presents the back/hind body, not a frontal face. Keep a coherent three-quarter rear view with four braced feet. Do not substitute the Alppain fork.
Identity invariants: exactly the same compact violet/black-purple/lavender glassy angular organic plate organism, ridge/back-plate arrangement, tapered lowered head, short Branchspell crest, FOUR bent angular living limbs with clawed feet, same proportions and same quiet preparation stance. Preserve the existing pale ivory/muted-lime low plate-join anatomy where naturally visible from the rear view; do not invent an additional seam or force a front-only detail through the back. No extra limbs, tail, wings, head, horn, eye, organ or equipment.
Scale/placement: preserve the source's apparent native pixel scale and approximate anatomical size, square 1254-style transparent canvas, centred body around x635/1254, and approximate lowest planted foot baseline at y1051/1254 (84 percent). Whole creature, all four feet and their separating gaps visible, with clear transparent margins. Perspective foreshortening is natural, but no rescaling or redesigned body.
Style/medium: match the existing crisp stepped pixel outline, broad flat violet facets, black-purple limb gaps and restrained lavender angular highlights. Keep the coarse pixel material family; no smooth shaded 3D render, painterly softness, extra microglints or glow outline.
Scene/backdrop: genuinely transparent alpha background; preserve transparency. No floor, ground, contact shadow, environment or backdrop.
Constraints: ONE organism, ONE rear three-quarter braced still, no duplicates, atlas, arrow, facing glyph, labels, text, UI, frame, watermark, attack lane, footprint, beam, laser, weapon, pickup, action trail, motion, recovery pose or active attack. This is candidate directional artwork of the same C50 creature, not a new type, ability or mechanic. No hitbox, damage or timing is defined. Preserve the exact family while changing only view/facing.
```

## Scoped portrait study on the adopted shared-4 baseline

Root imported only the new resources through `python3 scripts/dev/dev.py import` (`.cinder/act3-back-facing-import.log`, exit 0/no script-resource errors), then ran `python3 scripts/dev/dev.py engine --path . --script res://tests/acts/act3/stalker_art_capture.gd -- --back-facing-only` (`.cinder/stalker-art-back-facing.log`, exit 0/no errors). Four actual 339 × 736 Apple M3 GPU portraits show rear braced/recovery and their engine horizontal mirrors (captures 14–17 under `captures/act3/twin-suns/`), beside the actual shared `act3_traveller` in the existing stable-floor room. Baseline is shared commit `1ebd6b59265897d6ef49a29461473c52426b8fe6` / shared-4, adopted merge `e24ba4ed31d0c400f3f76a3b46ee585f32776f49` plus the owned art-study edit.

The study retains common `1.35/807` pixel scale and source-specific offsets; mirrored sources invert offset.x to keep the proposed pivot over the same ground anchor. Root inspected all four: recovery lowers the rear silhouette by roughly five portrait pixels, with no gross hovering or contact-baseline displacement in this still view. The rear phase height contrast is smaller than the front pair, and the head/crest direction remains ambiguous without an authoritative lane. The seam remains tiny. These are decorative placement/facing candidates, not accepted animation, live enemy phases, source/footprint/landing composition, mixed-equipment readability or gameplay. No collider, target, damage or timer was added by the study.
