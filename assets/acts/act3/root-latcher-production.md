# Living Forest Root Latcher — original atlas production candidate

Generated 9 October 2026 with the built-in `image_gen` tool, `transparent_background: true`. One original generation; the output was copied byte-for-byte. No CLI fallback, bitmap cropping, resizing, alpha rewriting or fabricated additional frames. Pillow was used only to read native alpha/bounds.

- Asset: `root-latcher-atlas.png`, RGBA **1254 × 1254**; four exact **627 × 627** cells.
- Original output: `/Users/howardchen/.codex/generated_images/01a11ae1-e453-7f40-bb05-cd7373153a0f/exec-e2bd1381-f160-487d-a138-1cccd79c80c7.png`.
- SHA-256: `05bac37c0e5d03a0238651179e32106bd562ff5999bde36dcb83d3207a0bf810`.
- Alpha range 0–255: 1,096,387 fully transparent, 410 fully opaque, 475,719 partial pixels. Most visible content is partial alpha; native bytes are preserved. Faint nonzero pixels reach some cell edges, while **alpha >=128** silhouettes stay inside all cells. The consumer uses alpha scissor0.5 and nearest filtering.
- Readiness: **native-inspected original still candidate; no import/engine or actual portrait verification by this asset helper**. Parent owns subsequent native-projection, collision/contact and portrait checks.

## Native regions, pivots and common scale

All bounds below are local to the cell, with right/bottom exclusive. Pivots are manually proposed central rooted-contact anchors at the lowest visible root baseline. Cell-specific offsets align this same world anchor without editing pixels or rescaling poses.

| Pose | Native region x/y/w/h | Alpha>=128 bounds | Proposed local pivot | Sprite3D offset |
| --- | --- | --- | --- | --- |
| Closed | 0/0/627/627 | 82/262/592/584 | 333/584 | -19.5/270.5 |
| Raised/tightened | 627/0/627/627 | 57/163/544/584 | 310/584 | 3.5/270.5 |
| Exposed recovery | 0/627/627/627 | 82/198/606/501 | 338/501 | -24.5/187.5 |
| Spent | 627/627/627/627 | 59/207/551/504 | 310/504 | 3.5/190.5 |

One proposed comparison scale is **1.35/807 world units per native pixel**, the existing L1 Stalker relation. At that common scale, visible bounds heights are approximately closed0.539, raised0.704, exposed0.507 and spent0.497 world units; widths approximately0.853/0.815/0.877/0.823. Every complete cell quad is approximately1.049 world units square. These are native projections proposed for a low rooted bulb, not accepted gameplay radius/reach or final portrait scale. Recovery is only about0.032 world units lower than closed; the exposed knot, rather than exaggerated lowering, is the main contrast. Do not resize each pose independently.

The art component [root_latcher_art.gd](../../../scripts/acts/act3/root_latcher_art.gd) uses exact native `AtlasTexture` regions with zero margins and clipping enabled. It creates no collision body, HP, target/enemy group, controls, timer, geometry, sun effect, damage, reward or interaction. Root's actor owns its separately specified physical capsule. The filled dark contact disk is noncolliding decoration; it is not a target ring or danger marker.

## Pose identity and limits

Native inspection shows one low ribbed black/olive/violet bulb in every cell. Exactly two prominent ends fold, raise, retract or become two cut stubs. Small fingers of the fused planted base skirt remain visible; they are not additional expressive attack ends. No humanoid head/legs, foliage, floor, attack lane/crescent, labels, panel borders, UI or glowing cue appears. The recovery cell exposes a substantial pale low oval knot; other cells conceal/darken it.

The source is generated rather than pixel-perfect hand-authored. Core silhouette and ribbing have modest pose drift, pivots require actual portrait checking, and the spent body settles only slightly rather than collapsing dramatically. One front three-quarter view is supplied; no rear/opposite-direction coverage or animation atlas is claimed. The knot rim is anatomical solid contrast, not a mechanically authoritative vulnerable marker.

- `clear`/`idle`: closed still.
- `warning`/`lock`/`active`: same raised/tightened **STILL**. No motion frames or strike timing are inferred.
- `recovery`: retracted ends and exposed low knot.
- Explicit `defeated`/`spent`: severed/spent still retained. Art does not infer death or remove an actor.
- The actor/shared consumer supply all phase transitions and cue geometry. Crescent versus strip remains an explicit parent design decision; this PNG decides neither.

Reuse family: owned Act3 rooted bulbs/organic segments. First consumer is A3-L2; later Quiet Root Circuit can reuse this family after parent acceptance. It is not a new equipment/ability or a new tree-monster roster.

## Native framing adapter and required checks

Public art entry points are `present(phase:String)->bool`, defensive `state()->Dictionary`, and pure `framing_points(shell:Node)->Dictionary` with `error`/`points`. The latter derives all four full rendered corners for each still from actual `Sprite3D.get_item_rect()` multiplied by the exact native pixel-size getter and the actual public camera basis, plus the actual shadow bounds. `generate_triangle_mesh()` checks the native quad shape only: Godot snaps those vertices to0.0001m, so its rounded edges cannot be used as complete unsnapped render bounds. It does not use a culling AABB, guessed opaque contour or capsule proxy for artwork.

The shared standard billboard helper intentionally rejects AtlasTextures. Root expressly authorized this narrow independently testable owned adapter. It supports only identity local/world bases, standard enabled Z billboards, unchanged regions/texture/pixel scale/offset, centred single frames, no flips, region mode, custom shaders, fixed sizing or depth bypass. Unsupported/drifted settings return error and no points. The native Sprite3D pixel-size getter is retained once and compared exactly thereafter, accounting for its real_t representation without a scalar tolerance; shadow dimensions compare as exact native vectors. Shared camera/planner owns translation and admission. Geometry returned here does not prove actual visibility or license damage.

Parent must verify native projected corners against actual camera projection for every pose, common planted pivot/contact, full-cell bounds and shadow, and exact rejection of changed region/margin/texture/scale/offset/flip/axis/transform/shader settings. Inspect actual339×736 warning/lock/active/recovery/spent beside the shared hero and authoritative footprint/landing/ordinary-primary opening, both sun states and both trunk approaches. Check real camera translation, alpha-cell edge bleed, muted contrast and paused retry. Native still inspection does not establish human recognition, full route balance or combat acceptance.

## Inspected reference and public evidence

All reference inputs were inspected through view_image before generation:

- G06: [Living Forest](../../../docs/concept-art/act3/environments/02-living-forest.png), visible red ribbed trunks/low rooted vocabulary; no scenery painting copied.
- G12: [threat studies](../../../docs/concept-art/act3/bosses/03-candidates-and-threats.png), bottom panel8 material/tell/recovery inspiration. Its humanoid walking body and fan diagram were deliberately superseded by the written fixed-bulb/two-end rule.
- Existing original [L1 Stalker](sunbound-stalker-branchspell.png), pixel-cluster rendering reference only.
- [Canonical concept](../../../docs/ACT3_CONCEPT.md#three-regular-enemy-roles), [A3-L2 research](../../../docs/reference-library/act3/research/levels.json), [adaptation notes](../../../docs/concept-art/act3/ADAPTATION_NOTES.md), [shared style](../../../docs/GAME_STYLE_GUIDELINES.md), [reuse](../../../docs/ASSET_REUSE_GUIDE.md).
- Official Godot4.7 [AtlasTexture](https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html), region/margin/filter_clip; [Sprite3D](https://docs.godotengine.org/en/4.7/classes/class_sprite3d.html), native texture/frame/region API; [TriangleMesh](https://docs.godotengine.org/en/4.7/classes/class_trianglemesh.html), get_faces.
- Exact [Godot4.7.2 Sprite3D source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/sprite_3d.cpp#L431-L477), native generated quad; lines894–917 get_item_rect and929–947 public method bindings. See [shared camera limits](../../../docs/development/CAMERA_FRAMING.md#shared-shell-and-level-integration).
- Exact [TriangleMesh::create source](https://github.com/godotengine/godot/blob/4.7.2-stable/core/math/triangle_mesh.cpp#L125-L133), native0.0001m face snapping; [Vector3 native snapping](https://github.com/godotengine/godot/blob/4.7.2-stable/core/math/vector3.cpp#L44-L65), matching per-component step; [Camera3D constructor](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/camera_3d.cpp#L816-L824), default scale suppression. These were inspected to diagnose the first118/9 adapter fixture.
- [Godot4.7 material guide](https://docs.godotengine.org/en/4.7/tutorials/3d/standard_material_3d.html), Transparency/Depth Draw/Billboard/Render priority: scissor avoids blended sorting, but opaque pixels still occlude. No renderer trick replaces actual portrait composition.

## Exact generation prompt

```text
Use case: stylized-concept.
Asset type: original transparent runtime sprite atlas for Cinder Act 3 Living Forest, four decisive poses of ONE fixed Root Latcher organism.
Input images: Image 1 is G06 forest bark/material vocabulary only; Image 2 is G12 Root Latcher material and low recovery inspiration only, do NOT copy its humanoid walking silhouette or fan diagram; Image 3 is the existing Stalker pixel-cluster rendering reference only, do not copy its body or crest.
Primary request: create ONE square transparent PNG containing a clean regular 2 by 2 atlas with four equal cells, exactly one complete isolated pose per cell. No visible cell lines, labels, numbers, floor, shadows or background. Same organism identity, same fixed bulb size, same view, same base placement and native scale in all four cells. Each cell has generous transparent margins and no sprite crosses a cell boundary.
Subject: a compact immobile black-green rooted bulb, low wider-than-tall bark shell, a single broad fused planted root skirt, and EXACTLY TWO thick expressive root ends emerging from the same left/right attachment points. It has no legs, feet, head, eyes, face, humanoid torso, branches, foliage or extra tentacles. Never a mobile tree monster. The two root ends have simple blunt tapered tips, not claws. Only the two ends move; the rooted central shell stays at precisely the same size and position.
Four cells in reading order:
TOP LEFT closed/resting: two ends folded low across the front of the shell, fully concealing the low knot. Compact grounded quiet pose.
TOP RIGHT raised/tightened: the same two ends lift into a short tense inward-curving arch above the shell, clearly separated as TWO ends, showing a decisive braced tell. The shell remains low and planted. Knot concealed. This is one held still for warning, lock and active, not an animation sequence.
BOTTOM LEFT exposed recovery: same shell at same planted base, both ends retract outward/down behind the shell, leaving one large plainly visible low oval knot at the front just above the rooted base. The knot is muted ivory/olive against dark bark, a solid anatomical patch with a clean stepped rim, NOT a glow, ring, icon or extra organ. Make its projected silhouette useful at small portrait scale. A visibly lowered quiet recovery.
BOTTOM RIGHT spent: same original organism flattened/settled at that very same planted base, the two original ends visibly broken into TWO short severed stubs. The shell is dark and collapsed; knot dark/closed, no glowing opening. Readable ordinary spent silhouette, no gore, fragments or extra sprouts.
Composition: orthographic fixed downward approximately 45-degree portrait-game view, front three-quarter oriented slightly toward lower-right, all four views identical. All base ground contacts use local cell centre X50 percent / Y82 percent. Central rooted shell width and horizontal attachment points stay consistent across cells. Raised pose may extend higher, recovery/spent may lower naturally; do not rescale each pose to fill its cell.
Style: crisp stepped nearest-pixel 2.5D game sprites, deliberate broad dark/light clusters with sparse ribbing, apparent coarse source-grid detail approximately 64 pixels per organism, enlarged cleanly. Match the supplied Stalker’s crisp cluster language while being simpler, lower, matte and unmistakably botanical. Nearly black olive core, muted forest green/violet planes, restrained desaturated olive rib highlights. No neon, glass, photorealistic lighting, smooth gradients or tiny noisy bark.
Constraints: truly transparent RGBA canvas including gutters; no crescent, strip, lane, floor/contact shadow, attack arc, warning outline, arrow, target ring, UI, text or watermark baked into the PNG. Exactly four complete poses of the same rooted two-ended source; no other figures or props.
```
