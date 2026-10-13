# Sunbound Stalker — rear recovery facing candidate

Generated 8 October 2026 with built-in `image_gen` edit mode, the existing recovery PNG as the sole `referenced_image_paths` target and `transparent_background: true`. Two built-in attempts; one selected source saved here. First output appeared mirror-like with the pointed leading plate toward lower left, so it was not selected. The targeted second prompt explicitly places the same lowered head toward upper right and the rear body toward the lower-left viewer. No CLI fallback or raster editing was used.

- Asset ID: `A3-E1-ART-RECOVERY-BACK-01`.
- Enemy: unchanged `C50` / `A3-E1`; reuse family `A3-SUNBOUND-STALKER`. Facing artwork is not a new enemy, organ, equipment type or ability.
- File: [sunbound-stalker-recovery-back.png](sunbound-stalker-recovery-back.png).
- Exact edit target: [existing recovery PNG](sunbound-stalker-recovery.png), SHA-256 `8aab2d8763885d4f198b2c346658987145bf585a7b72f31703b32207602c59ac`; [source production record](stalker-recovery-production.md). No separate braced image was passed as a supporting reference.
- Selected generation output: `/Users/howardchen/.codex/generated_images/01a11ae1-e453-7f40-bb05-cd7373153a0f/exec-14b04570-4e47-4ffe-aeca-5e0277da0fbe.png`.
- Output SHA-256: `5e57e50e3c3ac991bbb23d5399345d7e6f164cdd49e7a5bde3b23c6ab07b2f31`.
- Native dimensions/mode: **1254 × 1254, RGBA**, alpha range 0–255.
- Raw nonzero-alpha bounds: `[25,21,1240,1220]`, right/bottom exclusive; faint peripheral alpha persists.
- Visible alpha >=128 bounds: `[187,311,1147,1051]`, **960 × 740** native pixels.
- Alpha counts: 1,280,816 fully transparent; 843 fully opaque; 290,857 partial, including 265,210 at alpha 192–254. Alpha is preserved byte-for-byte.
- Proposed feet pivot: **(635,1051)**, normalized approximately (0.506,0.838), using the family horizontal reference and lowest visible foot baseline. Full-source Sprite3D offset proposal: **(-8,424)**. This is an art placement candidate, not a measured body centre or verified floor contact.
- Requested source baseline was y1060; actual visible baseline is y1051, **nine native pixels higher**. A source-specific pivot is required to try grounded contact without moving the gameplay body. Do not silently keep the source y1060 pivot or treat this image as registered animation.
- Common family pixel scale: **1.35 / 807 ≈ 0.00167286 world units per source pixel**, retained from the preparation candidate. At that scale, this candidate's 740-pixel visible height is about **1.238 world units**, versus front recovery's 644 pixels/about 1.077. Do not renormalize every facing to 1.35 visible height.
- Facing/view candidate: upper-right-facing, away from the viewer, rear three-quarter interpretation under the same approximately 45-degree fixed downward camera.
- State coverage: **one stationary settled recovery still only**. No phase clock/duration, warning/lock/active/hurt/defeat animation or full facing set.
- Rendering proposal: nearest filtering, normal world depth, alpha discard around 0.5; no alpha rewrite. Root must inspect at actual portrait scale.
- Collision/occlusion/primary reach: no collider, hitbox, active footprint, damage, vulnerability or reach is encoded. The eventual authoritative moving-source/cue adapter owns those. Occlusion and source/footprint/landing coexistence remain unverified.
- Readiness: selected raster inspected natively; original alpha copied unchanged. **Not imported, rendered in Godot, connected to runtime phases or accepted as animation/primary recovery coverage by this asset subtask.**

## Native inspection and identity limits

Opened the existing recovery source with `view_image` before editing and inspected both generated native outputs. The selected image retains the angular violet/lavender/black-purple plate family, bent planted clawed limbs and restrained ivory/muted-lime flank join. Its directional pointed head now reaches toward upper right; the near plated rear extends toward lower left. It has no floor, contact shadow, warning shape, arrow, weapon, equipment, text, duplicate organism or added target symbol. The seam remains physical anatomy, not a new organ or an independent attack cue.

The edit is not pixel-identical or a rotation of a rigged 3D model. Plates, contour, projected body length and limb placement were redrawn. The upper-right head extends farther upward than in the source; native visible height increases by 96 pixels and width decreases by 64 pixels. The nearest rear plate also has a pointed lower-left contour, so facing must be checked at small portrait scale rather than inferred from the requested prompt. Three clawed foot ends are clearly readable in the native image; the far fourth limb/foot is partly occluded or unresolved. Do not claim that all four whole feet are visibly preserved. The recovery remains a low bent-limb interpretation, but same body length/low posture and the exact camera angle are candidates, not measured invariants.

This is original Cinder game art for the invented C50 organism. It is necessary facing preparation for the one-Stalker Twin Suns room, not later-level production. Existing [G12/G18 source context](stalker-production.md) and front recovery provenance remain authoritative; this art adds no mechanics. Branchspell/Alppain crest mapping and easier approach are not defined by this facing.

## Root comparison still required

Compare front/rear recovery with the same 1.35/807 family pixel scale and authoritative feet/body/collider reference beside actual `act3_traveller`. Check whether the upper-right nose reads as facing away, the pointed rear plate does not impersonate a second head, the far foot occlusion is acceptable, and the nine-pixel baseline change avoids hovering or pose-swap pops. Inspect both sun palettes, muted/grayscale/low brightness, lateral motion, foreground occlusion, low seam and shared warning/source/footprint/safe landing together.

A single rear still is not an animation set or proof of ordinary-primary reach. Root later GPU comparison, physical encounter timing and moving-lunge/recovery opportunity tests remain pending. Common scale does not prove body identity or reaction budgets. Cosmetic pose changes must preserve simulation clocks, lunge distance, locked geometry and damage timing.

Registered checkout `codex/campaign-act3`; current recorded merge HEAD `7faea752a785f2d0d941be7e67654aba99f49ae4` / adopted `campaign-shared-3`. This subtask creates only this new PNG and production record, with no overwrite, manifest/durable docs/code/tests/import/engine/ledger/commit changes.

## Exact selected edit prompt

```text
Use case: identity-preserve.
Asset type: ONE transparent rear-three-quarter recovery still for Cinder Act 3 Sunbound Stalker C50 / A3-E1.
Input image: supplied sunbound-stalker-recovery.png is the EXACT EDIT TARGET. Preserve its same settled violet angular four-limbed creature, recovery posture, material, anatomical low seam, approximate body scale and alpha canvas.
Required change: ROTATE the creature in 3D to face UPPER RIGHT / northeast in the image, AWAY from the viewer. The camera looks DOWN at its BACK and rear haunches from about 45 degrees. This must be a REAR view, not a left-right mirror of the supplied front-facing sprite.
Facing anatomy must be unmistakable: the SAME long lowered pointed HEAD is the farthest FRONT of the body, toward the UPPER-RIGHT quadrant. Its nose tip points northeast, near the upper-right outline. Its dark head crest also points upper right. The BACK/rear end of its plated torso sits nearest the LOWER-LEFT viewer. The dorsal plates lead from the low-left rear body toward the far upper-right head. Do NOT put the pointed face/nose at the lower-left or lower-right edge. Do NOT leave a large pointed face plate pointing toward the viewer. Do NOT turn it into a tail or swap front and rear anatomy.
Keep all four bent angular planted legs and complete clawed feet, viewed from behind: rear legs are nearest at lower left/lower centre, front legs reach toward the farther upper-right head. Torso stays LOW and settled, stationary, with deeply bent recovery limbs. No raised standing/preparation pose. Preserve original compact elongated body proportions and the same violet/lavender/black-purple organic plate family. The existing ivory/muted-lime flank plate-join is anatomy and may be partly hidden from this rear view; no new target organ, duplicated seam, eye, gem or appendage.
Composition: one whole creature only, square transparent canvas, same approximate family pixel scale and body length, planted-foot baseline around y1060 of a 1254-style source and horizontal feet-centre around x635. Clear margins and whole feet. Do not zoom, crop or fill the canvas; common comparison pixel scale will be 1.35/807 world units per source pixel.
Style: exact source pixel 2.5D look, overhead orthographic fixed camera, crisp stepped contours and dark flat violet planes with a few restrained broad glassy highlights. No smooth 3D rendering, painterly texture, blur, microglitter, neon outline or glow.
Background: genuinely transparent alpha, no floor, ground, contact shadow, scenery, arrows, attack footprint, warning lane, trails, text, labels, frame, UI or watermark.
One still and one facing only; no atlas, duplicate, new enemy, new organs, tail, equipment, pickup or action effects. This is an art direction candidate, not animation, collision, damage, vulnerability timing or primary reach acceptance.
```

## Scoped portrait study on the adopted shared-4 baseline

Root imported only the new resources through `python3 scripts/dev/dev.py import` (`.cinder/act3-back-facing-import.log`, exit 0/no script-resource errors), then ran `python3 scripts/dev/dev.py engine --path . --script res://tests/acts/act3/stalker_art_capture.gd -- --back-facing-only` (`.cinder/stalker-art-back-facing.log`, exit 0/no errors). Four actual 339 × 736 Apple M3 GPU portraits show rear braced/recovery and their engine horizontal mirrors (captures 14–17 under `captures/act3/twin-suns/`), beside the actual shared `act3_traveller` in the existing stable-floor room. Baseline is shared commit `1ebd6b59265897d6ef49a29461473c52426b8fe6` / shared-4, adopted merge `e24ba4ed31d0c400f3f76a3b46ee585f32776f49` plus the owned art-study edit.

The study retains common `1.35/807` pixel scale and source-specific offsets; mirrored sources invert offset.x to keep the proposed pivot over the same ground anchor. Root inspected all four: recovery lowers the rear silhouette by roughly five portrait pixels, with no gross hovering or contact-baseline displacement in this still view. The rear phase height contrast is smaller than the front pair, and the head/crest direction remains ambiguous without an authoritative lane. The seam remains tiny. These are decorative placement/facing candidates, not accepted animation, live enemy phases, source/footprint/landing composition, mixed-equipment readability or gameplay. No collider, target, damage or timer was added by the study.

### Current L1 consumer readiness

Earlier generation/study readiness and native drift above retain their historical scopes. The [current L1 art and exact selected results](../../../data/campaign/act3/levels/A3-L1.md#current-shared-21-carried-route-and-production-checks), [scenery consumer record](scenery-production.md) and [portable evidence index](evidence/A3-L1/index.json) supersede unqualified pending consumer labels for this asset. Current reviewed L1 poses/scenery are suitable in the actual portrait scope; this is a tested candidate READY for autonomous HANDOFF, not integration acceptance, every-facing animation or human pacing/balance evidence. Native bytes, pivots, render-only/collision roles and anatomy/crest limits are unchanged.
