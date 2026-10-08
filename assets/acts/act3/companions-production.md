# Compassion companions — nonhostile Twin Suns vignette source

Generated 8 October 2026 with built-in `image_gen` in default mode, `transparent_background: true`. One still source containing two figures, copied byte-for-byte into the registered Act 3 asset directory. No CLI fallback, atlas fabrication, raster editing, cropping, rescaling or alpha rewrite. Source dimensions/bounds below were read with Pillow; no derived image was saved.

- Asset ID: `A3-VIGNETTE-COMPASSION-01`.
- File: `assets/acts/act3/compassion-companions.png`.
- Source entities: `C14` Joiwind (left) and `C15` Panawe (right). They are separate from the player and invented combat enemies.
- Generation output: `/Users/howardchen/.codex/generated_images/01a11ae1-e453-7f40-bb05-cd7373153a0f/exec-ae2ec32e-0d06-47a0-8358-1e85665013f8.png`.
- SHA-256: `c2ae1c3c24b12a2c31baec14aed2733eba976c8d006dd86a5e4ffdb7068987bb`.
- Native raster: 1254 × 1254, RGBA, alpha range 0–255.
- Raw nonzero-alpha bounds: `[0, 20, 1230, 1254]`; faint peripheral alpha is present.
- Combined visible bounds, alpha >=128: `[219, 44, 1050, 1174]` (right/bottom exclusive).
- Joiwind visible bounds: `[219, 44, 594, 1174]`, 375 × 1130 native pixels. Panawe visible bounds: `[651, 57, 1050, 1174]`, 399 × 1117 native pixels. Bounds were measured by reading the alpha mask on the two sides of canvas centre; the source remains whole and unchanged.
- Shared feet-baseline pivot: `(635, 1174)`, normalized approximately `(0.506, 0.936)`. Both figures' lowest visible feet reach the same baseline. Full-image Sprite3D offset is `(-8, 547)`, consumed by the unfinished L1 scenery builder at 1.65 visible world-unit height.
- Optional individual placement reference pivots within the same source: Joiwind `(407, 1174)`, Panawe `(851, 1174)`; no individual files or atlas regions have been produced.
- Alpha counts: 916,022 fully transparent pixels, 600 fully opaque, 655,894 partial, of which 599,611 have alpha 192–254. Bright yellow/magenta peripheral fringes are visible against a dark native preview at very low alpha; there were zero such bright saturated pixels at alpha >=128 in a narrow color inspection. Original alpha preserved.
- Rendering: nearest billboard and depth-tested alpha discard 0.5, consumed without alpha processing. Actual portrait review shows no bright peripheral fringe.
- Readiness: native still candidate consumed by the unfinished L1 scenery. Pixel-grid dimensions were a prompt target rather than a measured authored grid. Actual portrait placement/floor baseline, both sun states and sampled lateral passes reviewed; small anatomy and combat occlusion remain unverified. This is not a sprite sheet or finished NPC family.
- Animation: one quiet three-quarter standing pose each in a combined source. No alternate facing, blink, movement, conversation, interaction, attack, hurt or defeat frames.
- Collision/occlusion: decorative nonhostile vignette; no collider, attack target, pickup or interaction implied. Place beside the clear-water alcove on retained firm floor, outside the required combat source/warning/safe-landing composition. The PNG contains no water or terrain; those belong to the level's separate scenery.
- Reuse family: `A3-TORMANCE-COMPASSION-VIGNETTES`; possible quiet established Twin Suns/compatible side-space dressing after owner review. No ability/equipment introduction, reward or combat novelty.

## Primary evidence and selected art

Read local `docs/reference-library/act3/research/entities.json` records C14 and C15, the source registry, and the actual G02 board `docs/concept-art/act3/characters/02-compassion-and-shore.png` before generation.

Primary passages inspected in David Lindsay's *A Voyage to Arcturus*:

- [Chapter 6, Joiwind](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0006): Maskull's initial examination of forehead/under-ear/chest organs and the subsequent paragraphs introducing Joiwind's pale green drapery, opalescent skin and long flaxen plait.
- [Chapter 7, Panawe](https://www.gutenberg.org/cache/epub/1329/pg1329-images.html#link2HCH0007): opening appearance paragraphs establish white clothing, beardless young face, white nape-length hair, pale skin and dark quiet eyes. The scene with Joiwind also establishes his magn.

The G02 board supplies the quiet dignified costume/anatomy treatment and distinction from Maskull/other cast. Exact robe cut, hems, shoes, posture, pastel opalescent pixels and this two-person still composition are original art adaptations, not a literal source reconstruction. The paired ear organs and forehead concavity are simplified by this pose/source resolution; the nearer bud is visible on each figure and the far side is less exposed. Source prose is not imported as dialogue.

## Visual review and limits

Native inspection shows a flaxen long plait and pale green drapery at left, white nape-length hair and white drapery at right; both are fully clothed with visible feet, quiet faces and restrained forehead/ear/chest anatomy. No background, weapon, UI, label, attack/contact marking, light ray, action pose or blood-exchange scene. No sparkle/glow effect, behaviour or timed pulse exists.

This source defines no controller, interaction, dialogue, healing, escort, blood exchange, sensory power, route counsel, inventory, collection, vulnerability or quest objective. Their source relationships and nonviolence do not automatically add a game mechanic. Any later animation or interaction requires its own authorized specification and runtime evidence.

Root queued `python3 scripts/dev/dev.py engine --path . --script res://tests/acts/act3/twin_suns_portrait_capture.gd` after new-resource import. `.cinder/twin-suns-cast-portrait.log` reports six captures and exit 0, with no script/resource errors. First review showed quiet separate figures but feet overlapping the pool. The pair now stands at (-4.7,0,29.7), beyond the far edge of the faceted alcove centred at (-4.7,0,32).

The focused command adds `-- --companion-only`. Its lateral/passed route revealed decorative spines hiding the actor; raised perimeter dressing was moved entirely outside the playable floor. `.cinder/twin-suns-companion-bank-occlusion-fixed.log` reports four actual 339×736 portraits (08/10/11/12), exit 0 and no script/resource errors. Root reviewed both naturally reached sun presentations and accepted ordinary dashes beside and past the pair: pale green/white silhouettes remain separate, feet rest on scarlet dry bank, and the player body remains fully visible. Silhouettes touch in the lateral pass but retain actor identity. No neon alpha fringe or interaction symbol is visible. Source anatomy is too small for full assessment.

Before acceptance, inspect eventual actual source/warning/safe-landing composition. These sampled stills do not establish all-angle occlusion, anatomy fidelity at scale, human balance or mobile performance. The asset helper performed no engine/shared-system work; root performed the subsequent owned scenery integration and graphical checks described above. No interaction mechanic was added.

## Exact generation prompt

```text
Use case: stylized-concept.
Asset type: ONE transparent pixel 2.5D companion-duo vignette source for Cinder Act 3 Twin Suns, a quiet nonhostile clear-water alcove.
Primary request: two respectful fully clothed standing adult companions, Joiwind on the left and Panawe on the right, standing quietly beside each other with a clear gap, entire bodies and planted feet on the same horizontal baseline. No third person. These are distinct nonhostile source figures, never the player character or enemies.
Source identity: Joiwind is tall and slender, very long loosely plaited flaxen hair hanging down her back/near shoulder, delicate pale opalescent skin with subtle pastel value shifts, thoughtful kindly eyes, wearing one flowing pale green classically draped modest ankle-length robe. Panawe is a young adult, beardless, white nape-length hair and snowy pale skin, dark quiet eyes and contemplative expression, plain white modest draped clothing. Neither has a hat, elf ears, armor, weapon or staff.
Distinctive restrained anatomy: both have a small soft rounded forehead breve organ with a central concavity (NOT a third eye, jewel or glowing mark), a small paired sensory bud at the neck just below each ear, and one thin supple non-glowing chest magn appendage emerging neatly above the fully covered robe and resting in a gentle curve along the upper cloth. The organs are quiet anatomical forms, not jewelry, injury, battle appendages or magic effects. Keep them readable through silhouette and value but restrained, preserving humanlike calm faces.
Scene/backdrop: genuinely transparent alpha background. No water, ground, rock, plants, reflection, environment, painted shadow, architecture, light rays or backdrop. The clear-water alcove is the future placement, not part of this PNG.
Style/medium: crisp deliberate pixel sprite art, broad controlled color clusters and stepped edges, shared coarse pixel scale, no soft painterly brushwork or photoreal texture. Draw as if each person is approximately 80 source pixels high and enlarge with nearest-neighbor. Restrained ivory/soft pale green/lavender-gray shadows, flaxen blond and white hair, dark calm eyes. Avoid glowing outlines or overly detailed textile noise. Respect the dignity of the G02 compassion companion board without copying its board layout or other cast.
Composition/framing: exactly two whole figures centered in a square canvas, a visible transparent gap at the middle and ample clear margins at every side. Feet both at about 85 percent canvas height. Orthographic fixed-angle close overhead 2.5D view looking downward about 45 degrees; show head tops/shoulders and fully visible grounded feet. Both face slightly toward the viewer and gently inward toward each other. Quiet relaxed hands and natural upright poses, no reaching gesture, no handholding, no entangled appendages, no dramatic action. Full robes cover shoulders, torso and legs; feet visible beneath hems.
Constraints: one still candidate only, no extra poses/facings, atlas, frame, grid, labels, typography, nameplates, watermark, inventory/equipment cues, contact icon, glint, halo, UI, health bar, weapons, pickups or attack warning. No controller, interaction, dialogue, healing, blood exchange, escort or new mechanic is defined or illustrated.
```

### Current L1 consumer readiness

Earlier generation/study readiness and native drift above retain their historical scopes. The [current L1 art and exact selected results](../../../data/campaign/act3/levels/A3-L1.md#current-shared-21-carried-route-and-production-checks), [scenery consumer record](scenery-production.md) and [portable evidence index](evidence/A3-L1/index.json) supersede unqualified pending consumer labels for this asset. Current reviewed L1 poses/scenery are suitable in the actual portrait scope; this is a tested candidate READY for autonomous HANDOFF, not integration acceptance, every-facing animation or human pacing/balance evidence. Native bytes, pivots, render-only/collision roles and anatomy/crest limits are unchanged.
