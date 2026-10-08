# Sunbound Stalker — Alppain rear braced candidate

Generated 8 October 2026 with built-in `image_gen`, `transparent_background: true`, one edit and one output. The rear Branchspell PNG was the exact edit target; the existing front Alppain sibling was supporting crest reference only. Both native inputs were opened before generation. The returned candidate was inspected and copied byte-for-byte into the assigned asset path. No CLI generation, crop, rescale, raster mirror, alpha rewrite or other pixel editing was used.

- Asset ID: `A3-E1-ART-ALPPAIN-BACK-01`.
- Identity/reuse: `C50` / `A3-E1`, `A3-SUNBOUND-STALKER`; same enemy and crest, no new equipment, ability, organ, loot or mechanic.
- File: [sunbound-stalker-alppain-back.png](sunbound-stalker-alppain-back.png).
- Exact edit target: [rear Branchspell](sunbound-stalker-branchspell-back.png), SHA-256 `52b11bd57dabbf3980b831291d48f9492cd186550219d257317dc62174ca0fa1`; original provenance and directional limitations are in [its production record](stalker-back-production.md).
- Supporting reference: [front Alppain](sunbound-stalker-alppain.png), SHA-256 `fc78c4b4c7513185e8f1628f72a267503a38de441b8f279790ff006c4b670249`; [its record](stalker-alppain-production.md) retains the earlier contour/portrait limitations. It was not an edit target.
- Generated source: `/Users/howardchen/.codex/generated_images/01a11ae1-6fd5-7ec0-beb2-7b6253c94dd6/exec-21e3696e-02b3-43ce-a3f2-2fe6a8436ea0.png`.
- Candidate SHA-256: `7c2a8297720f14ffbc7cacbe15f072ef7d2e4f9ea5effa9c64048a9eea79f03f`. The project PNG and generated source compare byte-identical.
- Native size/mode: **1254 × 1254, RGBA**, alpha range 0–255.
- Nonzero-alpha bounds: `[31,48,1232,1240]`; faint peripheral alpha persists.
- Visible alpha >=128 bounds: **`[233,266,1194,1083]`**, right/bottom exclusive; width961, height817 native pixels.
- Alpha counts: 1,221,137 transparent, 403 fully opaque, 350,976 partial; 296,338 at alpha192–254. Native alpha is preserved.
- Proposed visible-baseline pivot: `(714,1083)`, approximately normalized `(0.56938,0.86364)`; full-source Sprite3D offset **`(-87,456)`**. X rounds the bounds midpoint713.5, Y uses the lowest visible foot baseline. This is provisional bounding alignment, not a measured anatomical centre or verified floor contact.
- Keep the common family pixel size **`1.35/807`** world units per native pixel. The new visible height817 would be approximately 1.367 world units; do not independently renormalize this direction to 1.35.
- Coverage: one rear upper-right braced still with an Alppain fork candidate. No Alppain rear recovery, actual crest transition, hurt/death animation, atlas or accepted complete facing/state family is supplied.
- Render proposal: nearest filtering, normal world depth, alpha discard near .5, separate restrained floor contact disk; actual material/import/consumer changes belong to the owner. No `.import` or engine job was produced by this helper.
- Collision/occlusion: PNG has no collision, hitbox, interaction or occlusion authority. The existing source capsule, shared fixed corridor, actual lunge damage and ordinary-primary whole-body opening remain unchanged. No floor, contact shadow or warning geometry is baked in.
- Readiness: **native-inspected generated art prototype only**, awaiting actual portrait source/lane/landing, facing/pivot and sun-state review. It is not an accepted animation frame, encounter clear or balance result.

## Native inspection and drift

The upper-right crest now has an open angular notch and a substantial outer violet prong, a more visible contour difference than a tiny painted notch. The same rear-oblique body family, four bent limbs, clawed feet, limb gaps, violet/black-purple facets and ivory/muted-lime low seam remain recognizable. The silhouette is compact within the same head-side mass. No additional creature, independent appendage, scene, floor, shadow, marker, beam, UI or text is visible.

This is **not pixel-identical outside the crest edit**. Several body/limb facets were redrawn, and the top contour shortened. Relative to the rear Branchspell target, visible top moves from y248 to266 (+18); baseline y1082 to1083 (+1); bounds centre X712.5 to713.5 (+1); width959 to961 (+2); visible height834 to817 (−17). Using the old rounded pivot `(713,1082)` gives about one native pixel of baseline/centre drift. The proposed new pivot compensates bounds placement only. It does not certify feet-to-collider alignment or prevent a pose-swap pop.

The requested stance, apparent body scale and facing are visually similar, but generative redrawing prevents an exact unchanged-body guarantee. At common family pixel size, the height difference is about .0284 world units, primarily at the upper contour; the proposed baseline shift is about .00167 world units. Do not repair this with an undocumented crop/rescale or let art drift change the authoritative collider, travel, turn rate or timers.

The rear head's long plate and unequal prongs may still read as plate layering or an added horn at small projected size. The candidate needs owner comparison against the front Alppain fork and rear Branchspell narrow crest in the actual fixed-angle portrait. Native inspection does not establish that the crest identifies the sun state at 50–60 screen pixels, or that the low seam reads as a recovery opening. No lower-prong weakness, side-only hitbox or damage rule follows from its shape.

## Owner acceptance boundary

Compare all relevant sources at unchanged family pixel scale beside the shared Act3 traveller and actual source capsule, with the required source marker, finite locked corridor and reachable landing visible together. Inspect both scenic lights, muted/grayscale readability, upper-right facing, engine mirroring/bin boundaries, moving floor contact and exact still swaps. The shared player's maximum quad height is not its measured visible body height.

The [canonical role](../../../docs/ACT3_CONCEPT.md#three-regular-enemy-roles) requires two crest shapes while retaining ordinary slashable recovery in both suns. The new fork must communicate that presentation without competing with common actionable cues. Sun changes remain harmless, fixed safe floor/collision remains stable, and this asset adds no laser, target gem, weak-point key or new mechanic.

This helper changed only the new PNG and this dedicated record. Existing source PNGs remain unchanged. Registered checkout/branch: `codex/campaign-act3`; generation-time HEAD `b1ebaba2c73fef5b450e44b9e6003b8cc4e705aa`, adopted `campaign-shared-5`. No engine/import, script, scene, test, other production record, ledger or commit was changed for this image task.

## Exact built-in edit prompt

```text
Use case: precise-object-edit.
Asset type: ONE transparent pixel 2.5D game-enemy cutout, Cinder Act 3 Sunbound Stalker C50 / A3-E1, Alppain REAR-facing braced candidate.
Input image 1 is the EXACT EDIT TARGET: sunbound-stalker-branchspell-back.png. Input image 2 is SUPPORT ONLY: sunbound-stalker-alppain.png, showing the short broad fork crest shape. Do not copy image 2's front-facing body or stance.
Primary request: edit ONLY the directional HEAD CREST at the UPPER-RIGHT of the rear-facing creature in image 1. Change its narrow pointed ridge to a compact SHORT BROAD FORK, matching the angular two-prong crest configuration in image 2. Make two substantial short angular prongs with a clearly open V/U notch, large enough to distinguish the silhouette at a total creature height of 50–60 screen pixels, yet compact and within the same head/crest region.
The crest is the same violet organic plate in another configuration, not an added horn, extra limb, antenna, crown, gem, organ or weapon. Retain the long lowered upper-right head and its away-from-camera rear three-quarter facing. Do not change the dorsal plates, hind plate, ivory/muted-lime low seam or appendages.
Invariants: keep the entire body outside the local crest edit as exactly unchanged as possible: all FOUR bent limbs and clawed feet, separated limb gaps, same braced stance, same rear-facing upper-right orientation, exact object placement, same angular violet/lavender/black-purple flat facets, pixel contour treatment and native pixel scale. Keep the 1254×1254 square source composition and original visible lowest foot baseline at native y1082, with provisional central feet pivot x713/y1082. Do not shift, enlarge, shrink, crop, mirror, rotate or redraw the rest of the creature. Preserve all transparent margins and whole feet.
Scene/backdrop: genuinely transparent alpha background. No floor, contact shadow, scenery, environment or backdrop.
Constraints: exactly ONE creature and ONE braced still; no additional view, atlas, duplicate, animation, recovery pose, beam, laser, projectile, warning footprint, target marker, UI, text or watermark. No mechanics, collider or hitbox changes. Only the existing upper-right head crest becomes a short broad fork; preserve everything else.
```

## Owner import and candidate consumer

Root queued `python3 scripts/dev/dev.py import` after adopting shared-6 as HEAD `63dcf99de1bcfa9bb86c1bde41acd7db31207dc2`; `.cinder/act3-shared6-alppain-back-import.log` exited 0 without script/resource errors. The new PNG remains byte-unchanged. The owned [still-art component](../../../scripts/acts/act3/stalker_art.gd) now selects this rear braced source for Alppain, with the native offset above. Root derives harmless light presentation from the existing scenic sun state; collider, deadlines, route and ordinary body hit remain independent. Shared low recovery art is still used in both suns; forked recovery art remains pending.

The current source-only room portraits exercise the **front** Branchspell/Alppain sources and actual rightward hero dash, not this rear texture. They do not establish this candidate's rear crest readability, moving contact, active corridor or primary recovery acceptance. Native source inspection and the earlier rear Branchspell/recovery studies retain their separate limited scope.
