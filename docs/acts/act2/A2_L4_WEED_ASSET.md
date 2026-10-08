# A2-L4 static red weed and red creeper

Current readiness: **authored original mesh prototype; static source/type/geometry review only**. No Godot import, engine execution, native portrait, gameplay or art acceptance has occurred for this asset. The level owner must check actual planted instances with the shared following camera, Hero, sources, warnings and dry landings before upgrading readiness. This note records the original authored revision `a2-red-weed-1`.

The only production file is [red_weed_visual.gd](../../../scripts/acts/act2/red_weed_visual.gd). It supplies static scenery, with no collider, damage, target/cue group, contact, pulse, growth, process/physics function, clock, random generator, shader or project-setting change. Dense vegetation cannot change during an exchange. Parent-authored floor and fixed blockers remain the sole collision/support authority.

## Inspected source and adaptation boundaries

Actual original board pixels inspected in this study:

- [G08 Red Weed and London approaches](../../concept-art/act2/environments/red-weed-london-approaches.png): irregular crimson branching banks, separate brittle pale decay, fine wall strands, weed-choked water and clear road silhouettes among Victorian doors/windows and brick ruins.
- [G16 Martian technology and organisms](../../concept-art/act2/props/martian-technology.png): bulky twisting living stems with narrower branching ends; a distinct drooping pale diseased study. These are shape/material references, not an extracted atlas.
- Context boards [G17 Victorian survival props](../../concept-art/act2/props/victorian-survival-props.png), [G01 principal human cast](../../concept-art/act2/characters/principal-human-cast.png) and [G03 refugees and defenders](../../concept-art/act2/characters/refugees-and-defenders.png) were viewed for period-world/costume scale. This script implements none of their props or people.

The [collection boundaries](../../concept-art/act2/README.md), [environment category](../../concept-art/act2/environments/README.md), [props category](../../concept-art/act2/props/README.md), [generation manifest G08/G16](../../concept-art/act2/generated-manifest.json), [research T19/T20/E22/E23](../../reference-library/act2/research/entities.json), [L4 level record](../../reference-library/act2/research/levels.json), [L4 concept](../../ACT2_CONCEPT.md#a2-l4-red-weed-and-the-london-approaches--another-earth), [shared style](../../GAME_STYLE_GUIDELINES.md), [reuse guide](../../ASSET_REUSE_GUIDE.md) and player presentation/equipment constraints govern this production. No gear identity, stats, Hero body, headwear, control or ability is changed or allocated.

Primary novel inspected: [Book II.6, The Work of Fifteen Days (Lit2Go)](https://etc.usf.edu/lit2go/135/the-war-of-the-worlds/2480/book-twothe-earth-under-the-martians-chapter-6-the-work-of-fifteen-days/), cross-checked against [Project Gutenberg's primary text, Book II.5–6](https://www.gutenberg.org/cache/epub/36/pg36-images.html). Water-loving weed chokes rivers and floods meadows; its fronds later bleach, shrivel and turn brittle under disease believed bacterial. Drier approaches retain ordinary/intact places and much less weed. T19's bulky cactus-like/water fronds and T20's fine climbing red creeper remain separately identified. No intelligence, attacks, poison, collectible upgrade or thermal/chemical plant mechanic is inferred. G08's generated fungus/spore captions are graphic embellishments; this implementation makes no fungal/spore claim.

Production technique source inspected: [official Godot StandardMaterial3D transparency guidance](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html#transparency), which distinguishes hard alpha-scissor foliage from potentially mis-sorted blended transparency. This revision instead uses opaque stepped branch meshes, without alpha cards, particles or a new global rendering policy. Parent-derived temporary cutaway is a separate existing presentation seam; its native overlap/sorting still requires review.

## Native assets and scale

All variants share a native **Y0 grounded feet pivot at local `[0,0,0]`**, unit root scale and +Y growth. Tilted root rings are flattened to Y0; final triangle normals derive from those flattened vertices. The branch templates are intentionally asymmetric, with six-sided tapering segments and short readable forks instead of spheres, leaf fans or uniform petal arrangements. Low structural stalks remain visible; individual plant roots are decorative and have no hidden blocking shape.

| Asset ID / variant | Native candidate envelope, metres | Authored topology and role | States / reuse / limitations |
| --- | --- | --- | --- |
| `a2-red-weed-sparse` / `sparse` | Conservative top ≤1.524; XZ radius ≤1.027. Eight seed rotations alter the exact X/Z bounds | Three rooted crooked fronds, 36 tapered segments, nominal 2,592 vertices / 864 triangles; two opaque mesh batches | Static living sparse weed; changed gardens and dry road margins. Side forks can merge at actual portrait resolution; keep the structural base and required dry edges unobscured |
| `a2-red-weed-dense` / `dense` | Conservative top ≤2.024; XZ radius ≤1.265 | Five rooted fronds, 60 segments, nominal 4,320 vertices / 1,440 triangles; taller asymmetrical crowns | Static living water-loving banks. **Outboard placement only**, beyond required landings/attack/camera requirements. Compact native scale adapts enormous source growth; full frond visibility is not promised |
| `a2-red-weed-bleached` / `bleached` | Conservative top ≤1.365; XZ radius ≤1.320 | Five shorter/splayed brittle stalks with downward secondary ends; same 60-segment topology and nominal 4,320 vertices / 1,440 triangles | Static dying phenotype, warm ash/brown grey with no pure-white glow. Not a live colour transition or player-spent resource. Outboard framing and safe quiet glimpses; no debris/break interaction |
| `a2-red-creeper` / `creeper` | Conservative top ≤1.625; XZ radius ≤0.763. Across all eight forms X≈±0.759, Z≈0.017…0.084 | Four thin wall-facing climbing stems and hooked side filaments; 40 segments, nominal 2,880 vertices / 960 triangles | Static fine T20 creeper, distinct from water-frond growth. Local +Z is the display/front of its XY wall-facing habit. Position alongside an existing facade/tree; this asset creates no wall. Thin strands may disappear or merge at portrait scale |

The envelopes/counts above are **static analytical calculations across all eight forms using Python doubles**, not measured Godot/native test results. Small native representation differences remain possible; the returned root records actual Godot vertex-derived local bounds, radius and counts at construction. The native metadata is the authoritative inspection aid after import. Every variant has two direct MeshInstance3D children and one triangle surface per child; shared geometry caches are bounded to four variants × eight seed forms. No instance-building loop advances simulation or an encounter.

Original 32×32 nearest-filtered deterministic textures use clustered maroon/rust/brown tones, dull warm ash decay and restrained fine red creeper. Textures have opaque alpha, roughness0.94 and no emission or action cue. Geometry and texture resources are immutable shared caches; materials are independently duplicated for **each mesh of each root**, so changing one cutaway override cannot recolour another mesh/plant. New instances allocate only their local roots/leaves/material overrides after the selected form is cached.

## Exact parent interface and native inspection

`extends RefCounted`, with the only public production entry point:

```gdscript
static func build(parent: Node3D, variant: String, seed: int = 0) -> Node3D
```

Supported strings are exactly `sparse`, `dense`, `bleached`, `creeper`. Seed is an integer mapped with `posmod(seed,8)` to a deterministic cached form; it is not a world RNG or independent animated state. An invalid/retiring parent or unsupported variant returns null with a clear error, before partial construction. A valid call creates one local root under the supplied parent; the parent owns translation/yaw, placement, retirement and any native camera protection. Root is initially at identity transform. Preserve unit native scale unless the owner separately checks changed geometry/readability.

Direct named leaves are `StructuralFronds` and `BranchTips` for the three weed variants, or `ClimbingStems` and `ClimbingFilaments` for creeper. Both leaves carry `weybridge_cutaway_candidate=true`. Root `optional_cutaway_paths` is an Array of **strings relative to the returned weed root**; an enclosing kit must prefix each path with its own relative path to that root. These are eligibility paths, not saved fade bits or hazard geometry. StandardMaterial3D overrides exist before eligibility is exposed, and the parent may reconstruct temporary cutaway from actual native camera/protected points.

Root inspection metadata:

- `asset_id`, `art_revision`, `source_ids`, `variant`, `seed_form`, `scenery_only`, `collision_role`, `outboard_only`, `geometry_shared_immutable`.
- `grounded_feet_pivot: Vector3.ZERO`.
- `visual_bounds_local: AABB`, `visual_footprint_xz: Rect2`, `structural_base_bounds_local: AABB` (union of actual grounded structural ring vertices).
- `native_geometry: Dictionary` containing `bounds_local`, `footprint_xz`, `top_y`, `minimum_y`, `max_radius_xz`, `segment_count`, `vertex_count`, `triangle_count`, `mesh_count`, `native_scale` and the explicit no-clock description.

Metadata is local native geometry, not a promise of world collision, camera inclusion or a safe dash. Kit-level floors/blockers and shared consumer proofs remain independent. No collider may be silently inferred from fine fronds. An actual blocking trunk/wall must have separately authored visible collision correspondence.

## Reuse and pending validation

Family: original Act2 ecological branches, compatible with existing Heath/Weybridge/RuinedHouse material/feet/cutaway conventions. Proposed reuse is L4's transformed garden/flood/villa margins, later L5's dying/whitening surroundings and documented A2-O3 Bleached Canal parent reuse. This file does not implement either later level, its rewards, route signs or any gameplay.

Native source-readability review remains pending for all four variants: inspect branch volume/ground contact, maroon versus danger outlines, warm pale decay versus warning glyphs, overlapping canopy/Hero/source/landing readability, fine creeper loss, current/settled following-camera framing, per-instance cutaway isolation and complete local-root cleanup. Thick dense banks should frame the floor while the continuous navigable dry route stays visually clear. No screen-space dimensions, whole-board reproduction, seamless atlas extraction, human recognition/balance, mobile/performance or all-pose acceptance is claimed.
