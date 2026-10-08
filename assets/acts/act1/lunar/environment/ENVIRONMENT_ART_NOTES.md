# Small lunar theatre environment kit

Original pixels produced on 2026-10-08. **Runtime unbound and portrait unverified.**
This seven-texture kit dresses the existing A1-L2 scope. It does not constitute
a completed level, add enemy/equipment/ability identities, or change the actor,
camera, threat, timing, collision, checkpoint or contact-exit contracts.

## Inspected sources

The actual current **G09 celestial performers**, **G15 lunar/grotto/court kit**,
**G17 Crater Gardens/camp**, and **G24 crater gameplay board** were inspected.
G09 informs the human crescent performer and draped cloth; G15 supplies broad
painted rock streaks and organic grotto structure; G17 supplies low modular
scenery, the cloth camp and landed capsule; G24 informs keeping scenery outside
an open local floor. Their exact generation records remain in
`docs/concept-art/act1/generated-manifest.json`. Boards and captions are concepts,
not source pixels, measured level layouts or tested gameplay.

Supplemental inspection of **G14 Earth launch props** clarifies the existing
finless capsule and closed hatch. **F07 lunar landing**, **F08 celestial dream**
and **F09 grotto** establish jagged painted flats, the finless landed shell,
human celestial staging, sleeping blankets and an irregular scenic chamber.
Local Commons records label these film frames public domain and retain the
credit “screnshot made by divx”; this record preserves those declarations.
The monochrome game palette is a selected interpretation of the references.
All source-file and catalogue SHA-256 values are in the manifest.

Canonical identities stay intact: **E06/E07/P10/O34/O35** for lunar rock/ground,
**O09/O10/O36** for the same capsule and landed state, **E08/P11/O38** for the
sleeping expedition, **C16/O40** for the nonhostile crescent woman, and existing
**P12/O47/O48** structural vocabulary for the grotto edge. Anonymous sleepers
are scenic expedition performers; their faces are not authenticated likenesses.
The camp's canvas tent is a G17 game-concept adaptation, not an assertion that
the film contained these exact tents. The grotto threshold shape is a new
scenic arrangement of existing structure, not a Gothic gate or new mechanism.

## Texture contract

| File | Native grid | Pivot | Tentative pixel size | Role/state |
| --- | --- | --- | --- | --- |
| `rock_flat_low_a.png` | 96 × 56 | (48,56) | .024 | Low painted edge flat, static |
| `rock_flat_low_b.png` | 96 × 56 | (48,56) | .024 | Second distinct low edge flat, static |
| `floor_silver_tile.png` | 64 × 64 | (32,32) | .024 | Ground-plane overlay, quiet static |
| `capsule_landed_closed.png` | 128 × 88 | (64,88) | .028 | Squat finless landed shell, closed |
| `camp_sleeping_tableau.png` | 128 × 80 | (64,80) | .026 | Cloth tent and two sleeping travellers, static |
| `crescent_performer.png` | 64 × 112 | (32,112) | .026 | Seated human crescent performer, static scenery |
| `grotto_threshold_open.png` | 144 × 96 | (72,96) | .040 | Scalloped organic entrance, open |

All PNGs have transparent backgrounds, only alpha0/255, and original integer
pixel clusters. Nearest filtering is required. These scales are provisional,
deliberately giving environmental cloth/rock larger clusters than the .022
C30 actor. Root must check actual apparent scale and framing before binding.
Per-file exclusive opaque extents, pivot-relative art bounds, world quad size, role, state, reuse family,
canonical IDs and source hashes are recorded in `environment_manifest.json`.

Grounded images use a bottom-centre scenic anchor. A centred upright Sprite3D
can offset Y by half the native height to put that edge at the local anchor;
the owner must verify its actual billboard/floor convention. The crescent
performer is a hanging tableau: its bottom anchor is the robe edge, not a new
physical actor's feet. The floor tile uses a centre pivot and belongs flat on
the ground plane, not on a character billboard.

The floor is a **transparent-margin overlay on the owner's continuous base
floor**. Its four gray values112/115/119/123 have a narrow range; there are no
crater rings, bright rims, arrows, stars or threat marks. It is not a seamless
replacement floor atlas, an outlined slab grid or a claim about collision.
The two rock flats use broad white streaks and deep black creases with a few
hand-placed edge accents. They have distinct irregular silhouettes and are
low by design; tall walls and compulsory narrow routes are not supplied.

The capsule has a round rear closed door and broad cylindrical/tapering nose,
sparse rivets, painted metal bands and broad painted-rock supports. It has no fins,
landing flame, glowing hatch, equipment or contact cue. This 2D rendering
reuses the existing capsule identity; it does not replace the accepted L1
capsule's geometry or state implementation.

The camp has slouched canvas and blanket folds, brimmed hats and pale beards,
with closed eyes. There are no weapons, health pickups, bonuses, Z labels or
interaction icons. The crescent woman keeps a human face, extended arms and
long draped robe, distinct from an abstract crescent pickup. Both remain
nonhostile, outside immediate combat sightlines.

The threshold's organic scalloped mouth is fully transparent through the
floor baseline. Its baseline transparent span is pixel x[30,115) exclusive:
85 pixels, or 3.40 world units at tentative .040 scale. This is an art dimension only: the owner supplies and
tests the broad real contact/traversal area, without deriving a collision wall
from opaque pixels. No closed-door state, pulse, court column or hanging spore
cluster is introduced.

## Authority, reuse and checks

**Collision: none. Cues: none. Clocks/animation: none.** The sprites only draw
static scenery. Verified floor support, obstacle shapes, exit/contact state,
source footprints, gameplay clocks and shared cues remain separate owner work.
Use ordinary depth and review occlusion; do not draw scenic rocks or cloth in
front of mandatory landings, actor silhouettes or primary openings.

Rebuild with `python3 assets/acts/act1/lunar/environment/build_environment_cutouts.py`.
The generator uses existing Python/Pillow and writes only seven PNGs, manifest
and contact sheet in this directory. It never opens a reference image for
drawing, samples source pixels, crops/edits existing images or writes outside
its directory. The script verifies unique hashes, hard alpha and grayscale.
The nearest3× contact sheet and every native texture were inspected. These are
file/art checks, not gameplay, portrait, human-understanding or balance results.

Reuse lunar flats/ground and the existing capsule family across their documented
parent-kit locations. Camp/C16 scenery supports the existing quiet E08 beat.
The threshold marks the existing grotto-facing transition; no L3 encounter,
new spore art, court content or extra optional level is authored here.
