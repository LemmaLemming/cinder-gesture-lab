# Static hollow crescent geometry

This shared support resolves the geometry and required-cue portion of Act 3
A3-L2 dependency `01850690-be23-4471-aa08-27d12e3ac563`, submitted against
campaign-shared-22 `4de8b6008741bc9f155c83cbccb60629fac154a2`. The Living Forest
teaching beat explicitly requires a crescent. The general Root Latcher role's
strip alternative does not substitute for that confirmed beat. Level artwork,
placement, living HP/recovery opening, combined encounters and aggregate custody
remain act owned.

## Public geometry and transport dimensions

```gdscript
CinderThreatGeometry.crescent(origin: Vector3, direction: Vector3,
    inner_radius: float, outer_radius: float, min_dot: float) -> Dictionary
```

The canonical native dictionary has exactly six String keys: `kind="crescent"`,
`origin`, `direction`, `inner_radius`, `outer_radius`, `min_dot`. The constructor
retains the supplied values; `Geometry.error` validates them before use. The
origin and normalized planar direction are finite. Supported radii satisfy
`0.001 <= inner_radius < outer_radius <= 1e6` meters;
`0 <= min_dot < 1` describes a nonzero
full angle `2*acos(min_dot)` of at most 180 degrees. The relative band width
`(outer-inner)/outer` must be at least `1e-6`. Unknown/missing keys, StringName
keys, nonfinite values and unsupported dimensions reject. It is a distinct
shape, never a cone, full circle or zero-length lane. Transport encoders retain
these exact dimensions, encoding only the two Vector3 values as canonical
coordinate arrays; the scheduler/consumer integration owns that transport.

The thickness bound supports a finite, truthful native float32 mesh. Arbitrarily
thin bands could otherwise require unbounded circumscribed inner-arc chords or
fold after float32 rounding. Typical thin bands such as inner 2.999, outer 3
remain valid. This bound changes no collision epsilon.

The explicit minimum for both arcs `CRESCENT_MIN_RADIUS=0.001` bounds the native
presentation scale. Merely finite positive float64 dimensions can underflow
to zero when projected to mesh Vector3 components, and a nonzero subnormal
component alone does not guarantee useful circumscribed hollow triangles.
Those dimensions must not be admitted as apparently valid required fill.
The focused fixture checks native outline/fill at inner0.001/outer0.002 and
the practical narrow inner0.001/outer0.001001 band, and rejects zero, subnormal
and smaller-than-supported radii. This is an explicit shape-support bound,
not a contact epsilon change or an actor/loadout/tuning change.

The source is `origin`. The shape is static. The public cue refuses a changed
shape through lock/active/recovery; a new direction/position requires cancel
and a new exchange. No tracking, moving roots, scenery collider, living actor,
damage or player ability is introduced by this module.

## Authoritative contact and paths

`Geometry.segment_hits(shape, from, to, actor_radius)` tests a point (`from=to`)
or a swept planar capsule against the real hollow annular sector. It includes
both finite circular arcs and both finite radial ends. Endpoints inside the
annular sector contact immediately; otherwise analytic segment/arc and
segment/end distances resolve the capsule's round side/corner padding.
Circle intersections, endpoint projections and interior nearest candidates
cover crossings even when both path endpoints are outside the band.

The existing `Geometry.EPSILON=1e-5` applies to the final contact distance.
Local coordinates are calculated with scalar double arithmetic from the actual
stored Vector3 components; this avoids adding a float32 world-subtraction step.
Native Vector3 positions retain their existing precision. Malformed geometry,
points or actor padding fail closed. Vertical collision, floor support and
scenery LOS remain separate existing responsibilities.

`Geometry.timed_path_hits` uses this same analytic test over its existing clipped
active intervals. Existing scheduler union witnesses can therefore include the
shape through the same primitive. A safe inner landing alone is insufficient:
the complete live capsule path and the union with other preparing/active threats
still require proof. This module alone grants no reservation or fairness claim.

## Required meshes

`CinderCueMesh.canonical_geometry`, `anchor`, `boundary` and `geometry_mesh`
support the same shape. The boundary samples the outer arc forward and inner
arc backward, joining the actual radial ends. The active fill uses annular
quads split into triangles, never a source-centered triangle fan. Circumscribed
inner chords keep every filled triangle outside the real hollow disk. Outer
chords remain inside the outer disk. Tiny conservative relative presentation
insets account for native float32 vertex rounding; they never affect contact.

Adaptive angular tessellation uses at least 64 and at most 4096 segments.
Circular outlines are finite polygonal approximations with the existing cue
stroke width. The crescent keeps all nonzero finite outline edges; the older
footprint helper's short-edge cull would erase a finely sampled thin/narrow
band, so that helper remains used unchanged only for other shape kits. The
required source marker remains independently visible at the
actual origin. Warning/lock show the outline, active adds the annular fill, and
recovery removes danger meshes while retaining the source marker. Cues have no
autonomous clocks or damage and remain required under all cosmetic settings.

## Targeted evidence and limits

`tests/crescent_geometry_smoke.gd` checks closed dimensions and failure cases;
inner/outer/angular/corner tangencies; exterior-to-exterior crossings; time
clipping; translated native coordinates; a labelled pure crescent/lane union;
actual shared Player capsule/completed physics samples; actual mesh triangle
minimum radius; and actual public cue lock/active/recovery/pause behavior.
Circle/cone/lane regression checks remain in the focused fixture and existing
cue suite. Engine results and exact dependency hashes are recorded only after
the coordinated queue runs; the fixture does not establish an authored level's
portrait, combined encounter, ordinary-primary or campaign acceptance.

The first queued target completed 115 checks with one failure, preserved at
`.cinder/crescent-geometry-first.log`: analytic, actual capsule/path and hollow
fill checks passed, while the thin/narrow required outline disappeared because
of the existing short-edge cull. Exact first geometry, cue-mesh and fixture
sources were retained beside that log before the crescent-only edge correction.
Subsequent results are recorded separately; startup user-log permissions and
native macOS CA diagnostics are not gameplay assertions.

The corrected queued `python3 scripts/dev/dev.py test crescent_geometry` completed
115 checks, zero failures, exit 0 on Godot 4.7.2 `ed1daf0bf`. Its separate
`.cinder/crescent-geometry-second.log` has SHA256
`774d3856fecded92dcee7dff94713540c098fd046dd25b3072b4f7f3c0884bf7`
and contains no parse/script/runtime or startup diagnostics. The command used
the shared queue and a scoped sandbox escalation for Godot's native user logs.
Tested source identities were Geometry
`35f6ec4811872d58591639d7d14606172fdc49cb4003e79c72c500247593ff13`,
CueMesh `d63f5dfabbdae2dbd055e24013b0d822bca47ba71a457e1ab0d874e0ef22929d`,
fixture `48ceb265560c7d10628e5170ffc935b956c6b0eb0e53d8f796dde9512ac0e91c`,
Player `8e4dfeb2c285f1d786ec3268bdaf5efbc70b3b0f4b2473b2870e0566a88e4743`
and ThreatCue `f8d6bebb6c66ae1cf3fe6d90482b9dbb2bf6ce3274b01b6e2b6a6848fbcb7a48`.
This leaf preloads no Scheduler or LaneMechanism; their new codec/consumer
integration requires its own directly affected evidence.

The explicit 0.001-meter minimum for both arcs was then added, with the exact
115/0 geometry/cue/fixture sources preserved as `.cinder/*-second.gd.txt` before
that change. The final same queued target completed 124 checks, zero failures,
exit 0 with no diagnostics, including both actual native minimum-scale meshes
and subnormal rejection. Final geometry SHA256 is
`c82501198ea1a3b53c872caec35e52604bb7256d6e71fff2c9293b430e1d8f09`,
fixture `d65a19271925608745a34fe381592971f40de62fcb011908f6559f2dbc9868f2`,
and CueMesh retains `d63f5dfabbdae2dbd055e24013b0d822bca47ba71a457e1ab0d874e0ef22929d`.
The final `.cinder/crescent-geometry-min-radius.log` SHA256 is
`076d3f975df1d0aaf7989506a8eee3bb9cc7230b5456c9a03d6b42b2f072c71d`.
The older 115/0 evidence predates that support bound and is retained with its
original scope; no result is relabelled as authored Living Forest gameplay.
