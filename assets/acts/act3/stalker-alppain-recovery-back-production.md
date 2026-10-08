# Sunbound Stalker — rear Alppain recovery candidate

Generated 8 October 2026 with built-in `image_gen`, `precise-object-edit`, two local `referenced_image_paths`, and `transparent_background: true`. One generation and one retained candidate. Generated native PNG copied byte-for-byte; no raster editing, cropping, resizing, alpha rewriting, CLI fallback, atlas fabrication or regeneration.

- Asset ID: `A3-E1-ART-ALPPAIN-RECOVERY-BACK-01`.
- Enemy identity remains `C50` / `A3-E1`; reuse family remains `A3-SUNBOUND-STALKER`. The crest configuration and rear recovery pose add no enemy, organ, equipment or ability type.
- New file: [sunbound-stalker-alppain-recovery-back.png](sunbound-stalker-alppain-recovery-back.png).
- Exact body/pose target: [existing rear settled recovery](sunbound-stalker-recovery-back.png), SHA-256 `5e57e50e3c3ac991bbb23d5399345d7e6f164cdd49e7a5bde3b23c6ab07b2f31`; [source production and occlusion limits](stalker-recovery-back-production.md).
- Crest-only support: [existing rear Alppain braced fork](sunbound-stalker-alppain-back.png), SHA-256 `7c2a8297720f14ffbc7cacbe15f072ef7d2e4f9ea5effa9c64048a9eea79f03f`; [its production record](stalker-alppain-back-production.md). Its taller braced body, limb placement and baseline were excluded from the edit request.
- Generated output: `/Users/howardchen/.codex/generated_images/01a11ae1-57cb-79d2-8e89-eb9c0e75834b/exec-3d5c1e96-7b22-40ab-aeeb-2ab76c003150.png`. Original retained.
- Candidate SHA-256: `746649632bbd2262cf06cdcc071758dc0c12cdf5d405243404c6c51d16344b56`; 559,286 bytes.
- Native dimensions/mode: 1254 × 1254, RGBA; alpha range 0–255.
- Nonzero-alpha bounds: `[27,39,1234,1235]`; faint peripheral alpha persists.
- Visible alpha >=128 bounds: `[187,306,1147,1051]`, 960 × 745 native pixels. Right/bottom bounds are exclusive.
- Alpha >=250 bounds: `[190,307,1146,1048]`.
- Alpha counts: 1,271,999 fully transparent; 470 fully opaque; 300,047 partial, including 275,172 at alpha 192–254. Generated alpha preserved.
- Proposed feet pivot remains `(635,1051)`, normalized `(0.506380,0.838118)`; full-source offset `(-8,424)`. The alpha-128 lowest-foot baseline matches the exact rear recovery target at y1051. This remains a provisional art anchor, not a measured anatomical centre or accepted floor-contact result.
- Common family pixel scale stays `1.35/807 = 0.0016728624535315986` world units per native pixel. The 745-pixel visible height would be approximately `1.246283` world units, versus the rear target's 740 pixels/about `1.237918`. Do not renormalize each pose/facing to 1.35 visible height.
- Coverage: one stationary rear recovery still, upper-right-facing away from the viewer, interpreted under the fixed overhead three-quarter camera. No complete animation sequence, extra facing, measured hold or atlas.
- Collision/geometry role: decorative whole-organism cutout only; no collider, damage receiver, hit region, contact disk, active footprint, cue or scenery. Visible head/limb extent does not redefine the actual source capsule, locked lane, turn limits, lunge geometry or ordinary-primary opening.
- Generation-time readiness: native-inspected candidate only. No import, engine, scene/script selection or gameplay/art acceptance is supplied by this asset task. Paired front/rear contact, facing, crest recognition and held recovery review remain pending.

## Source boundary and requested configuration

The [Act 3 concept](../../../docs/ACT3_CONCEPT.md#three-regular-enemy-roles) requires two Stalker crest silhouettes identifying the sun state and easier flank, with ordinary slash recovery in either state. [C50's entity record](../../../docs/reference-library/act3/research/entities.json) identifies the creature as an invented game proposal. The short fork is root-authored original art, not novel canon, a new organ, exclusive weak point or an independently implemented sun-bias mechanic.

Family context remains [G12's regular-threat study](../../../docs/concept-art/act3/bosses/03-candidates-and-threats.png) and [G18's Twin Suns gameplay board](../../../docs/concept-art/act3/gameplay/01-twin-suns-gameplay.png), carried through [the original Branchspell production record](stalker-production.md). Violet angular living plates, four-limb anatomy and a restrained ivory/muted-lime low flank join stay consistent. G18's line denotes the written lunge lane, not a laser.

Actually opened both native input PNGs immediately before generation, then the returned native PNG afterward. Rear settled recovery was the exact target; rear braced Alppain supplied only the fork configuration. The prompt preserved the low posture, current y1051 baseline, `(635,1051)` pivot, source scale and original far-limb occlusion. It asked for only a short substantial two-prong open head crest, with a widest gap ideally 60–90 native pixels.

## Native anatomy, gap and redraw limits

The candidate visibly retains the rear recovery body's broad angular plate arrangement, low settled bent-limb interpretation, upper-right leading head and lower-left nearer rear body, violet/lavender/black-purple palette and pale low flank join. Three clawed foot ends remain clearly visible in approximately the original places. The far fourth limb/foot is still partly occluded or unresolved; this output does not establish four independently visible complete limbs/feet or repair the source's anatomical coverage limit.

The leading head region has two broad angular plate prongs and an open transparent notch. There is no detached horn/organ, target gem, glow outline, equipment, floor, contact shadow, attack/cue shape, text or atlas. The pointed rear plate still projects toward the viewer; the same ambiguity between a leading head and pointed rear contour requires actual lane/facing review. At small scale the fork might read as a split head or layered plates instead of a clearly configured crest. Native inspection alone cannot settle that identity/readability issue.

Read-only alpha-128 inspection of head ROI `[820,310,1101,451]` finds the largest horizontally bounded transparent fork-mouth run to be **63 pixels**, x982→1045 at y335. The paired-prong region `[820,340,1101,426]` has a widest run of **59 pixels** at y340, with sampled rows y350/360/370/380/390/400 tapering through 54/48/44/37/33/28 pixels before closing. Thus the ideal 60–90-pixel widest opening is reached at the upper mouth only; it is not a sustained width through the whole fork. Do not treat the maximum as a guaranteed 60-pixel central opening.

At the earlier source-still horizontal scale of roughly 0.074–0.078 portrait pixels per native pixel, the 63-pixel mouth would be around 4.7–4.9 pixels, with the 48-pixel middle around 3.6–3.7. These are arithmetic estimates from earlier **front braced** source captures, not measured rear recovery GPU pixels. Camera placement, mirroring, material threshold and the bright prong planes still need actual comparison.

The result is not an exact crest-only pixel patch. Surface facets and some fine plate/foot edges were redrawn. Relative to the target's alpha-128 bounds `[187,311,1147,1051]`, visible left/right bounds and lowest-foot baseline are unchanged; the top extends five native pixels upward to y306, within the edited head-crest region. Visible height increases from 740 to 745 at the same family scale, about 0.008364 world units. The strongest alpha>=250 feet bound moves from 1050 to 1048 even though alpha>=128 remains y1051, so coverage near the foot edge is not invariant. No corrective processing was used, and common bounds do not certify rigged anatomy or contact continuity.

## Owner comparison and state limits

Compare this candidate with [rear Branchspell recovery](sunbound-stalker-recovery-back.png), [rear Alppain braced](sunbound-stalker-alppain-back.png), [the selected front fork trial](sunbound-stalker-alppain-readable.png) and [front Alppain recovery](sunbound-stalker-alppain-recovery.png) at unchanged family scale beside the actual [shared Act 3 traveller](../../characters/presentations/manifest.json). Retain source-specific anchors; matching pixel size does not justify sharing a feet offset across every facing. In particular, root selected the front Alppain recovery's actual y1062 baseline for its separate trial, while this rear source still uses y1051.

Check rear pose lowering, nose-to-lane direction, pointed rear ambiguity, far-foot occlusion, quiet/grayscale crest contrast, tiny seam, mirrored contact and pose swaps together with the real source, warning footprint and reachable landing. A still-body pair can support art selection, while physical lunge/recovery and ordinary-primary opportunity need their affected gameplay evidence.

The [owned visual component](../../../scripts/acts/act3/stalker_art.gd) is unchanged by this task. The art contains no phase timer, lock duration, travel, cooldown, damage, hitbox, signed useful-side lease or final C50 sun-bias acceptance. Both sun states retain the ordinary-primary whole-body recovery opening independently of the pixels.

Registered branch: `codex/campaign-act3`; generation/native inspection at adopted shared-8 HEAD `a7bcc4734aa13ef82f7120969336e7108f416c27`. Only this sibling PNG and dedicated record are created. No existing PNG, consumer, four durable records, mailbox/status, engine/import/test or commit changes are included. No repeated human decision or native/human external acceptance gate is introduced by this asset task.

## Exact edit prompt

```text
Use case: precise-object-edit.
Asset type: ONE transparent pixel 2.5D game-enemy cutout, Cinder Act 3 Sunbound Stalker C50 / A3-E1, REAR ALPPAIN SETTLED RECOVERY candidate.

Input 1, sunbound-stalker-recovery-back.png, is the EXACT EDIT TARGET and authoritative body identity, LOW settled rear recovery pose, view, native scale, palette, canvas placement and feet reference.
Input 2, sunbound-stalker-alppain-back.png, is SUPPORT ONLY for the existing Alppain SHORT BROAD TWO-PRONG OPEN HEAD CREST configuration in a rear view. Do not copy its taller braced body, different leg arrangement, upper contour or foot baseline.

Primary request: preserve Input 1's whole settled rear creature and change ONLY its EXISTING directional HEAD CREST near the UPPER-RIGHT-facing leading head into the same short broad angular two-prong fork configuration as Input 2. The two substantial prongs must bound one clear genuinely transparent open V/U-shaped gap, ideally around 60–90 native pixels wide at its widest part on this 1254-square canvas. Use broad simple violet prong planes and a clearly open contour, not a painted notch, a fine dark stripe or microglints. Keep it SHORT and broad, pointing with the existing head upper-right and away from the camera. Reshape the same crest; do not add a horn, antenna, organ, crown, eye, target gem, symbol or equipment. Preserve the lowered head, jaw and nose identity beneath the crest and keep dorsal/back plates unchanged.

Strict pose/anatomy invariants: preserve Input 1's LOW, SETTLED, STATIONARY recovery body, compact elongated proportions, deeply bent planted limbs, nearer rear haunches and pointed rear plates toward lower-left, and the existing restrained ivory/muted-lime flank plate join. The creature still faces upper-right away from the viewer in exactly the same rear three-quarter interpretation. Do not rotate, mirror or turn it into a front view. Do not raise its torso into the supporting reference's braced stance, redraw its limbs, move feet, widen the body, shift the seam or add any body part.
Keep the FOUR-LIMB anatomical family and the existing three clearly visible clawed foot ends; the source's far fourth limb/foot is partly occluded. Preserve that original occlusion and limb gaps rather than inventing an extra visible leg or changing the body to reveal it. Keep all currently visible feet complete.

Canvas/pivot/scale: preserve the 1254-by-1254 square transparent canvas, full organism scale, placement and margins. Keep the original visible lowest-foot baseline at y1051 and the proposed family pivot (635,1051), source offset (-8,424). Preserve the approximate upper contour near y311 except for the local crest reshaping. No crop, zoom, resize, rotation, recentering or height normalization. Common family scale remains 1.35/807 world units per native pixel; recovery stays low at that unchanged scale.

Style/material: preserve crisp stepped pixel 2.5D contours, overhead orthographic approximately 45-degree fixed downward view, violet/lavender/black-purple glassy organic plate vocabulary, broad flat dark facets and a few restrained highlights. No new sparkly microglints, smooth 3D rendering, painterly texture, neon fringe, outline, bloom or glow. The pale low join remains anatomy, not an attack cue.

Background: genuinely transparent alpha only, preserve transparency. No floor, ground, contact shadow, contact disk, scenery, geometry or backdrop.

Constraints: exactly ONE whole existing creature and ONE settled recovery still, no duplicate, atlas, frame strip, additional facing, active motion, attack, lunge, projectile, beam, laser, trail, warning lane, attack footprint, arrow, equipment, weapon, pickup, UI, text, labels, watermark or extra organs. Same C50/A3-E1 enemy and Alppain crest configuration, original game art rather than novel canon. Artwork defines no hitbox, collision, timing, damage, exclusive flank, vulnerability, new enemy/ability or mechanic. Change only the existing upper-right head crest to the supported short broad open fork while preserving the low rear recovery identity, pose, placement and occlusion.
```



## Matching consumer import

Root selected this source for the held-sun1 low-recovery trial at rear(-8,424), anchor(635,1051), common1.35/807 scale. `.cinder/stalker-signed-flank-recoveries-import.log` exited0 with no script/resource errors after both new PNGs and owned actorAPI2 were present. No generated bytes were changed. Actual moving encounter portrait, facing/contact and crest teaching remain pending.
