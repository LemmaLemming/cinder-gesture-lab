# A2-L4 London approaches scenery — authored revision 1

This is an original arrangement of Act 2 module families for the changed garden, dry flood margin, two villa arrangements and broad Putney approach. The floor and cosmetic helpers have been authored and checked statically. They have **not yet been imported, executed or reviewed in the native portrait view**. Nothing here establishes full-route, loadout, source-framing or campaign acceptance.

## Sources and adaptation

The following source boards were inspected as original images. They remain concept references rather than finished runtime assets.

| Source | Features carried into this authored kit |
| --- | --- |
| [G08 London approaches](../../concept-art/act2/environments/red-weed-london-approaches.png) — E19/E22/E23/E24/E25/T19/T20 | Rust-red branching fronds, quiet pale diseased weed, shuttered villas and sash windows, damaged brickwork, dry road through flood margins, lamps and urban bridge framing. |
| [G16 Martian technology and organisms](../../concept-art/act2/props/martian-technology.png) — T19/T20 | The separately owned weed helper distinguishes bulky crooked water-loving fronds from fine wall-attached creeper and static bleached decay. |
| [G17 Victorian survival props](../../concept-art/act2/props/victorian-survival-props.png) | Reused dogcart, luggage, field gun, brick/stone/iron construction, timber furniture and empty tins. These are scenery without collection or weapon actions. |
| [G01 principal human cast](../../concept-art/act2/characters/principal-human-cast.png) — C04 | Exhausted human artilleryman, muted olive uniform, dark cap/boots, subdued red collar, cross strap and satchel. The new two-pose pixel costume reuses the existing human feet grid; exact facial/costume fidelity remains to be reviewed at native size. |
| [G03 refugees and defenders](../../concept-art/act2/characters/refugees-and-defenders.png) | Existing nonhostile witness costume family is reused. This board's category and adaptation record were read; no new G03-specific anatomy or crowd animation has been produced or visually accepted in this scope. |

[Act 2 adaptation boundaries](../../concept-art/act2/README.md), [shared style](../../GAME_STYLE_GUIDELINES.md) and [reuse guide](../../ASSET_REUSE_GUIDE.md) govern these adaptations. The scheme follows [ACT2_CONCEPT](../../ACT2_CONCEPT.md): static ecology, broad dry alternatives, ordinary controls, two villa priorities and a short nonhostile artilleryman vignette. The level owner supplies actual encounters, contact checkpoints and exit. No equipment introduction, reward, boss, temporary hazard, digging task or conversation wait is implemented by this kit.

## Exact geometry and collision ownership

[`london_approaches_floor.gd`](../../../scripts/acts/act2/london_approaches_floor.gd) owns five axis-aligned Y=0 dry boxes, each X[-3.4,3.4]. Their Z ranges are garden [-8.8,3.6], flood [-19,-7.8], villa1 [-28,-18], villa2 [-38.5,-27] and Putney [-50,-37.5]. Overlaps preserve continuous dry support; `safe_rect` is the authored rectangle inset by exactly .002 m. Each .5 m thick support has its center at Y−.25 and a `DrySupport` collision child.

The stable root is `LondonApproachesDryGround`. Its only interior blockers are `GardenStemBlocker/GroundedBlocker` at (0,.4,−4.6), size (1.4,.8,.65), and `VillaLowWall/GroundedBlocker` at (0,.225,−22.6), size (1.5,.45,.45). The scenery's opaque bases match those boxes exactly; wall coping stays inside its .45 m height. Garden fronds above the fixed base are collisionless. Side boundaries center at X±3.65 and the end boundaries at Z3.9/−50.3, with `BankSolid` collision children. Bodies use layer 1/mask 0 and identity local bases. The level must retain an identity root; there are no animated supports.

[`london_approaches_kit.gd`](../../../scripts/acts/act2/london_approaches_kit.gd) supplies no CollisionObject3D, damage, groups, timers, signal listeners or process loop. Water is a lowered outboard picture at Y−.12; it neither supplies playable floor nor introduces swimming. Architecture, bridge piers/rails, carts and field gun are outboard. There is no span or overhead arch across the necessary floor. Only the two exact visible blocker bases sit within it. Thin floor dressing at Y .005/.008 communicates one continuous route rather than stepped platforms. The five cosmetic material strips meet without overlap at Z−8.3/−18.5/−27.5/−38 to avoid coplanar fighting over the independently overlapping support joins.

## Native scale, pivots and occlusion

All kit roots use native scale (1,1,1), meters and grounded local pivots. The reused material family uses nearest-filtered 64-pixel texture modules at 1.44 world meters per repeat. Villa walls, sash divisions, side shutters, lintels, chimneys and ruined crowns are assembled anew; no whole L1, L2 or L3 layout is instantiated. Intact facades top at 2.54 m; outboard placement keeps their nearest eave beyond X4.15. Dense weed is rooted at |X|≥4.70 and bleached weed at |X|4.85; the helper's conservative all-form radii (1.265 m dense / 1.320 m bleached) keep these entire crowns outside X±3.4; exact weed vertex/bounds metadata comes from the separately owned [`red_weed_visual.gd`](../../../scripts/acts/act2/red_weed_visual.gd). Fine creeper is attached to an outboard wall, and sparse Putney patches retain quieter late-level dressing. The central sparse garden crown starts at the fixed base's Y .8 and has no extra collider.

Humans use the existing 48×64 grid, .0225 m per pixel, billboard nearest filtering, offset (0,32) and alpha scissor, with their feet at the Node3D origin. Garden witness centers are |X|4.05; parent-supplied retreat moves farther outboard by at most .7 m. The artilleryman's fixed feet origin is (4.15,.025,−47); his full 1.08 m sprite rectangle starts beyond the dry edge. He remains nonhostile and has no cue, contact reward, health or movement control. Native camera cropping, large weed overlap, the fixed stem crown's obstruction and the soldier's small facial details remain untested.

The kit root's `optional_cutaway_paths` lists actual descendant MeshInstance3D paths. Every eligible leaf has a unique StandardMaterial3D override; immutable texture and mesh caches are reused. Weed paths are prefixed from each helper root into the kit root. The level derives temporary opacity from actual camera-to-hero/source/footprint/landing visibility, including before its presentation guard and after restore. Ground planes remain opaque. No opacity is saved; no fade moves a collider, actor, source or clock. Architecture, ironwork, furniture and weed can be temporarily cut away. Actual native review must verify full required cue rims, source glyphs, hero face/torso/feet, and useful landing pockets across the legal route.

## Public protocol and quiet states

- `Floor.SPECS` contains `{id, rect}`; `Floor.BLOCKERS` contains `{id, at, size}`. `Floor.build(parent)` returns `{id, rect, body, collision, safe_rect}` entries.
- `Kit.build(parent)` returns `{root, witnesses, artilleryman}` and starts with a hidden artilleryman and quiet visible garden witnesses.
- `Kit.set_departure_tableau(kit, active, progress=0)` accepts the parent's finite normalized progress, clamps it and reconstructs all positions, visibility and textures directly. Inactive reconstructs witnesses at their homes and hides the soldier. Active retreats witnesses outboard, hides them at progress 1, and shows the soldier's rest/satchel pose. The soldier's feet never move. No elapsed time, autonomous tween or input wait is sampled.
- The level reconstructs those derived states after its actual sequence/clock restore. This cosmetic helper emits no events and owns no saved state.

The reusable families are road/earth/paving, outboard flood water, brick/stone villas, sash/shutter details, iron lamps/rails, period furniture/cart/gun, quiet human witnesses and four static weed states. A2-O3 can reuse these families in a smaller court; A2-L5 can reuse quieter paving, damaged terraces and bleached weed with only its own required additions. These are reuse possibilities, not implemented optional or L5 content. The shared player, camera, cue grammar, original smoke tails and ordinary primary controls remain level/integration owned.

## Checks and remaining work

Static checks verify the three new file scopes, resource links, exact rectangles and node contracts, continuous support coverage, blocker dimensions, absence of autonomous processing and new collisions in the scenery helper, and per-instance cutaway registration. Root must import the new scripts, run the actual level's component/route/lifecycle checks and inspect native 540×1170 portraits. Mechanical clearance, source fidelity at runtime, all permitted loadouts and campaign transport are not established by this document. No human/mobile/export gate is introduced.
