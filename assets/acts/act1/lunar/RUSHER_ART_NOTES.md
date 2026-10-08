# C30 Rush Selenite pixel kit

Produced original pixels on 2026-10-08. **Bound to the retained C30 actor and
validated in the small prototype's front-facing portrait sequence:** 46 headless
and 53 scripted graphical checks, zero failures, on campaign-shared-18. See
[runtime binding](rusher_runtime_binding.json) and its evidence index. The
generated manifest retains the historical pre-binding production check values.
Dynamic side/back views and full Crater Gardens remain untested. This kit contains one existing enemy, C30 / A1-E1; it
introduces no weapon, swarm, attack, input, equipment or enemy type.

The twelve transparent cells use an upright masked stage performer, a fitted
black costume with painted/sewn pale rib and limb bands, and a fan of five
projecting headpiece rods. The angular mask has round eye openings and a simple
mouth; it has no skull teeth. Broad fabric highlights and asymmetrical fold
clusters replace uniform surface noise. These are original integer polygon
designs, not crops, pixel edits or traced samples from a reference image.

## Inspected references and provenance

- **G10**, `docs/concept-art/act1/characters/selenite-costumes-and-roles.png`:
  front/side/back costume studies, headpiece fan, two-leg Rush preparation and
  visibly off-balance recovery. Contemporary generated game concept; its
  source manifest and prompts stay in `docs/concept-art/act1/generated-manifest.json`.
  This full board is a reference, never an atlas.
- **F10**, `docs/reference-library/act1/film-stills/f10.jpg`: the film court's
  upright human-performing costumes, pale torso bands and projecting headgear.
  The local Commons record labels the source public domain and credits
  “screnshot made by divx”; those recorded declarations are preserved rather
  than replaced with a new historical or rights claim.
- **F11**, `docs/reference-library/act1/film-stills/f11.jpg`: bright stage puff
  and dark theatrical scenery context. No puff pixels are in this kit, and
  this still establishes neither a rusher pose nor an animation duration.
- **C30**, the record in `docs/reference-library/act1/research/entities.json`:
  canonical invented Rush Selenite, design A1-E1, first introduced in A1-L2.
  Attack roles and timings are game adaptations, not observed film mechanics.

SHA-256 hashes of the actual inspected files, the canonical C30 record, each
output PNG and the palette source are recorded in `rusher_manifest.json`.
Moon-white/silver/ink is the project's selected monochrome interpretation;
it does not describe every historical colour print. The seven opaque palette
entries exactly reuse `assets/acts/act1/launch/build_cutouts.py`.

## Files and binding contract

Each facing owns four distinct files:

| Facing | Standing | Warning/lock | Committed active | Stopped recovery |
| --- | --- | --- | --- | --- |
| Front | `rusher_front_standing.png` | `rusher_front_crouch.png` | `rusher_front_rush.png` | `rusher_front_recovery.png` |
| Side, toward screen right | `rusher_side_standing.png` | `rusher_side_crouch.png` | `rusher_side_rush.png` | `rusher_side_recovery.png` |
| Back | `rusher_back_standing.png` | `rusher_back_crouch.png` | `rusher_back_rush.png` | `rusher_back_recovery.png` |

All cells are **48 × 80 RGBA**, with only alpha 0 or 255 and no antialiasing.
The feet pivot is bottom centre **(24, 80)**; both toes meet row 79 in every
pose. The pivot is fixed even when an asymmetrical costume leans around it.
At the bound `pixel_size = 0.022`, the full quad is **1.056 × 1.76 world units**.
A centred Sprite3D can use image offset **(0, 40)** to put that bottom-centre
edge at the actor's existing foot origin. The actual native billboard and six portrait captures verify this foot-origin
binding in the small prototype; full-level scenery occlusion is still pending.

Use nearest filtering and the existing actor's ordinary depth/occlusion. Each
frame's exclusive alpha bounds and tentative bounds relative to the feet are
in the manifest; these actual extents should feed the camera framing guard.
The headpiece is cosmetic and can extend above the retained body capsule.
**Collision: none.** Keep the existing C30 capsule, attack samples, damage and
foot position; do not fit physics to opaque pixels. No shadow, floor, threat
footprint, timer bar, warning glow, hit puff or private cue is baked into art.
The shared cue and any separately implemented effects retain their authority.

Side art faces screen right. Screen-left presentation may reflect that same
side texture horizontally about the fixed centre pivot, without changing
physics or forcing discrete movement. Front and back are explicitly authored,
not reflected or inferred. The frame selection follows continuous public
facing relative to the camera; it does not quantize the committed lane.

The owner selects these static poses solely from existing public state:
standing for idle, crouch for warning and lock, rush for active, recovery for
the stopped recovery. Crouch bends the knees on two feet; rush leans and
separates the limbs; recovery plants both feet and splays the arms. This kit
supplies one pose for each state, **no animation clock or motion profile**.
It does not supply a hit/defeat pose; the owner must retain the existing
accepted-hit and defeat presentation rules without inventing new timing.

## Rebuild and checks

Run `python3 assets/acts/act1/lunar/build_rusher_cutouts.py` from the project
root (or `python3 build_rusher_cutouts.py` here). It writes only the twelve
frames, manifest and preview in this directory. Python/Pillow is sufficient;
there are no Node dependencies, source image imports into drawing functions,
random seeds, engine jobs or outside output paths.

The generator verifies twelve unique hashes, fixed native dimensions, a
transparent margin, row-79 feet, hard alpha and grayscale. The review contact
sheet is a labelled nearest-neighbour 4× enlargement on two grayscale grounds;
its labels/background never enter runtime cells. Native frames and the sheet
were inspected as pixels. These checks establish file/pivot consistency,
not art acceptance, human recognition, equipment fairness or performance.

Reuse family: `act1_selenite_C30_rusher`, starting with A1-L2 and its documented
parent-kit reuse. Future Selenite types may share costume vocabulary; this
kit does not claim to produce their size, weapon or attack states. Lunar
environment, camp, capsule and extra enemy art remain outside this task.
