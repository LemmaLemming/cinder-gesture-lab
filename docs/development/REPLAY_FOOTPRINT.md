# Replay footprint projection

`scripts/combat/replay_footprint.gd` provides the isolated pure `CinderReplayFootprint` (`replay-footprint-1`). It projects original sealed [Sequence](REPLAY_SEQUENCE.md) attacks onto a supported immutable floor/LOS domain. The returned data is presentation data. It grants no capture custody, slot retirement, threat admission, dispatch, damage or portrait visibility approval. The conservative full-cone [Witness](REPLAY_WITNESS.md) remains unchanged.

The isolated native fixture passes **164 checks, 0 failures**, exit 0, on Godot `4.7.2.stable.official.ed1daf0bf`. The opt-in [projected Playback](PROJECTED_REPLAY.md) and [required cue](PROJECTED_CUE.md) consumers are separately tested; this leaf establishes no current-level, portrait-visibility or whole-encounter acceptance.

```gdscript
static floor_signature(world_root: Node3D, floor_regions: Array) -> Dictionary
static plan(scheduler: Node3D, sequence_snapshot: Dictionary,
    world_root: Node3D, floor_regions: Array, context: Dictionary) -> Dictionary
static projection_error(projection: Dictionary, scheduler: Node3D,
    sequence_snapshot: Dictionary, world_root: Node3D,
    floor_regions: Array, context: Dictionary) -> String
static current_world_error(projection: Dictionary, scheduler: Node3D,
    world_root: Node3D, floor_regions: Array) -> String
static floor_contains(projection: Dictionary, point: Vector3) -> bool
```

The Scheduler must use the exact live shared script in the same `World3D`; derivative scripts are conservatively unsupported so an overridden query cannot impersonate the native fingerprint seam. Only its `pure_collision_fingerprint(world_root)` is called. No wrapper diagnostics, clocks, reservations, pruning, actor properties or callbacks are changed, even on rejection. Both paused and running synchronous queries are supported; there is no wait or simulation advance.

`floor_regions` uses the existing `{collision: CollisionShape3D, safe_rect: Rect2}` bindings. The `safe_rect` union is the authored valid arena domain. It is contained in actual native floor Boxes; no convex hull bridges gaps, and overlapping rectangles do not duplicate fill. Membership is planar domain membership above the supported floor lower bound, not capsule support or a reachable landing proof.

The trusted parent records both guards at the original capture boundary:

```gdscript
var floors = CinderReplayFootprint.floor_signature(world_root, floor_regions)
var context = {
    "source_epoch": actual_epoch,
    "generation": actual_generation,
    "capture_collision_fingerprint": scheduler.pure_collision_fingerprint(world_root),
    "capture_floor_signature": floors.signature,
}
var projection = CinderReplayFootprint.plan(
    scheduler, sealed_sequence, world_root, floor_regions, context)
```

The parent must check `floors.accepted` and the nonempty capture fingerprint before arming. These caller-held historical guards do not authorize an arbitrary historical capture. The actual [capture retirement gate](REPLAY_CAPTURE_GATE.md) remains responsible for current live Player ownership, epoch and FIFO retirement. This new leaf validates immutable Sequence syntax/derivation and exact correspondence to the supplied original guards.

An accepted result is a closed finite JSON value with API/schema revision, original sequence ID/epoch/generation, a canonical exact-tagged Sequence SHA-256 digest, exact native collision fingerprint and floor signature, curve/boundary-grid/fill-inset declarations and original ordered events. Each event retains its original encoded record, ID, kind, slot ID, record sequence and scheduled time. It supplies:

- `triangle_vertices`: consecutive absolute `[x, floor_y, z]` triples; each three vertices form one filled triangle.
- `boundary_contours`: distinct closed rings, each with `hole: bool` and an explicitly repeated final first vertex. Their edges are outline mesh data; internal decomposition seams are omitted.
- `bounds`: `[min_x, min_z, max_x, max_z]`, or `[]` for an empty projection. `floor_y` is explicit.

The later cue adapter must stage all event fill/outlines and publish them atomically. It must retain original source/origin, event IDs and shared phase grammar, and validate the actual source, full footprint, hero and safe landing in the portrait view. Nothing here approves a speculative fit or substitutes a preferred route for the admitted witness.

`projection_error` freshly recomputes and exactly compares **all** data through the public ExactJson codec. A reordered event, changed raw geometry or one-bit guard/mesh change rejects. `current_world_error` checks only the current world/floor correspondence of an already authenticated projection; it does not authenticate arbitrary caller-created mesh data. `floor_contains` likewise requires a trusted, previously authenticated projection and current-world guard. It tests finite X/Z membership and rejects points below `floor_y - 0.02 m`; airborne points over that domain remain eligible for subsequent original height/LOS checks. This lower bound prevents using a projection whose LOS band does not cover a below-floor target. Future live damage must still use the original recorded range, disk/cone, vertical limit and native scenery LOS, plus the actual admitted actor and once-only dispatch receipt. Rendering chords are never damage geometry.

## Supported clipping and limits

Floors are one to 32 coplanar, unscaled, identity-basis static Boxes with stable native paths, one enabled shape per floor body and unchanged scenery membership. All scenery under the canonical fingerprint is currently required to use unscaled identity-basis static Boxes. Moving, rotated, scaled, generated or other collision topology rejects conservatively, including an unsupported shape away from the event. This stricter leaf support limit does not narrow the Scheduler's existing collider fingerprint API.

Captured attack origins must be in the declared floor union within `0.02 m` of its exact common top. Coordinates and Box dimensions are bounded by `512 m`; reach is at most `32 m`. The leaf preserves the original CueMesh 64-segment cone arc and rear origin-disk arc, including independently aimed blast records. Those chords are the existing cosmetic curve approximation.

A relevant Box casts a shadow only when its vertical interval fully covers the supported LOS band from `floor_y - 0.02 + recorded_los_height` through `recorded_origin.y + max_vertical_distance + recorded_los_height`. Wholly disjoint short/overhead Boxes cast no shadow. Partial or boundary coverage rejects explicitly, rather than claiming a horizontal slice equals a potentially sloped native contact ray. Source positions in/on a relevant blocker also reject; no new `hit_from_inside` policy is invented.

For a supported Box, its two source tangent halfplanes and the near Box face halfplanes define the complete LOS shadow. Clipping that convex shadow to the finite record AABB keeps far floor behind a wall blocked; subtracting only the Box itself would be incorrect. No angular enumeration, physical ray sampling or convex floor hull approximates the shadow.

The fill is a bounded vertical planar arrangement. All edge endpoints and segment intersections split X slabs; edge order is fixed inside each slab. Crossing parity is maintained separately for the attack and each floor/shadow polygon, then evaluated as `attack && any_floor && !any_shadow`. Adjacent accepted bands merge. Their linear supporting boundaries form trapezoids, which are triangulated directly. No hole contour is triangle-filled. Neighboring slab interval differences provide exposed vertical edges; oriented upper/lower edges complete the true boundary rings, with opposite winding for holes.

Scalar intersections use native GDScript doubles. True boundary coordinates use a cosmetic `1e-8 m` joining grid; the maximum coordinate displacement is half that grid and these outlines never authorize damage or fill. Filled convex cells are offset inward by `0.00025 m` at every supporting edge before triangulation; their vertices are not snapped outward. That clearance exceeds the bounded native float32 coordinate-conversion error and keeps fill outside gaps, holes and LOS shadows. Extremely thin cells are omitted conservatively, leaving subpixel seams between decomposition cells; original closed boundary contours remain intact. Bounds include those original contours. Ambiguous coincident boundaries, collapsed/point-touch contours or nonclosed rings reject. Limits are 256 described scenery Boxes, 512 input edges, 131,072 edge-pair tests, 2,048 X events, 1,048,576 slab-edge tests, 32 relevant blockers and 16,384 combined encoded mesh vertices. ExactJson's independent structural/byte limits also apply. These bounds can reject otherwise valid large or extremely thin authored worlds. They are not a proof of unrestricted computational geometry or all-height contact equivalence.

## Targeted evidence

Executed isolated native fixture: actual completed Player capture and immutable Sequence; separately aimed primary/blast; one/two slots and real gear-only reach extremes; real overlapping/coplanar floors, a four-Box hole and disconnected physical floor; full-height wall shadow, tangent corners, open region, disjoint short/overhead and rejected partial-height Boxes; exact-tagged JSON recomputation and one-bit capture/current-world changes; moving/rotated/unsupported native shapes; unchanged HP/ammo/pose/velocity/clock, capture state, scheduler reservations/diagnostics and callbacks.

The native polygon API explicitly distinguishes outer boundaries and holes in Boolean results; calling single-contour triangulation on an outer ring does not preserve those holes. This implementation uses an arrangement instead of treating returned hole contours as independent filled polygons. [Official Godot Geometry2D documentation](https://docs.godotengine.org/en/stable/classes/class_geometry2d.html).

The canonical queued first run is preserved at `.cinder/replay-footprint-first.log`: **162 checks, 7 failures**, exit 1. All clipping/purity/world/transport cases passed; six clothing equip assertions were made outside the actual Player paused bench and the resulting range assertion used the wrong pants. The repair changed only fixture setup to an actual grounded paused bench. The repeat `.cinder/replay-footprint-second.log` passes **164/0**, exit 0, against the byte-identical leaf. Original five-file draft and source/dependency hashes remain under `.cinder/replay-footprint-original/`; the second source/dependency manifest is `.cinder/replay-footprint-second-manifest.json`. No saves, engine import, actor/shared-source edit, broad suite or unchanged suite ran. Both logs retain the sandbox macOS system-CA lookup startup diagnostic; the passing run contains no script/parse/fixture failure diagnostic.

Loaded shared dependencies were Scheduler `5e7ae27fc3f274fe8c49d266fd6611aca0300e5b975b4d1591c6839f45d83d7f`, Geometry `c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09`, CueMesh `d63f5dfabbdae2dbd055e24013b0d822bca47ba71a457e1ab0d874e0ef22929d`, and Player `8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743`. No shared23 publication or authored current-level claim is inferred from this separate future-support leaf.
